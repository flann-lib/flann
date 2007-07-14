
/************************************************************************
Project: aggnn

Module: kdtree.d (approximate nearest-neighbor matching)
Author: David Lowe (2006)
Conversion to D: Marius Muja

nn.c:
  This module finds the nearest-neighbors of vectors in high dimensional
      spaces using a search of multiple randomized k-d trees.

  The following routines are the interface to this module:

  Default constructor: this(ubyte **vecs, int vcount, int veclen, int numTrees_)
    This routine creates an Index data structure containing the k-d trees
    and other information used to find neighbors to the given set of vectors.
        vecs: array of pointers to the vectors to be indexed. 
        vcount: number of vectors in vecs.
        veclen: the length of each vector.
        numTrees_: the number of randomized trees to build.

  Destructor ~this()
    Frees all memory for the given index.

  FindNeighbors(int *result, int numNN, float *vec, int maxCheck)
  Find the numNN nearest neighbors to vec and store their indices in the
  "result" vector, which must have length numNN.  The returned indices
  refer to position in the original vecs used to create the index.
  Seach a maximum of maxCheck tree nodes for the result (this is what
  determines the amount of computation).


 *************************************************************************/

import std.c.stdlib;
import std.stdio;
import std.c.math;
import std.c.string;

import std.gc;

import util;
import heap;
import nnindex;
import features;
import resultset;



mixin ModuleConstructor!(KDTree);

/* Contains the k-d trees and other information for indexing a set of points
   for nearest-neighbor matching.
 */

class KDTree : NNIndex{

	static const NAME = "kdtree";

	int numTrees_;       /* Number of randomized trees that are used. */
	int checkCount;     /* Number of neighbors checked so far in this lookup. */
	float searchDistSq; /* Distance cutoff for searching (not used yet). */
	int vcount;         /* Number of vectors stored in this index. */
	int veclen;         /* Length of each vector. */
//	int vsize; 			/* Space allocated for vector storage (vecs) and index (vind) */
	float[][] vecs;      /* Float vecs.  */
	int *vind;          /* Array of indices to vecs.  When doing
						   lookup, this is used instead to mark checkID. */
	
	int* freeInd;		/* Array of indices to free locations in vecs */
	int freeIndCount;	/* Count of elements in freeInd */
	int freeIndSize;	/* The size of freeInd */
	
	int checkID;        /* A unique ID for each lookup. */
//	int ncount;         /* Number of neighbors so far in result. */
//	float *dsqs;        /* Squared distances to current results. */
//	int dsqlen;         /* Length of space allocated for dsqs. */
	TreeSt **trees;  /* Array of k-d trees used to find neighbors. */
	Heap!(BranchSt) heap;
	
	Pool pool;          /* Memory pool that holds all data for this index. */


	
	/*--------------------------- Constants -----------------------------*/
	
	/* When creating random trees, the dimension on which to subdivide is
		selected at random from among the top RandDim dimensions with the
		highest variance.  A value of 5 works well.
	*/
	const int RandDim=5;
	
	/* To improve efficiency, only SampleMean random values are used to
		compute the mean and variance at each level when building a tree.
		A value of 100 seems to perform as well as using all values.
	*/
	const int SampleMean = 100;
	
	
	/*--------------------- Internal Data Structures --------------------------*/
	
	/* This is a node of the binary k-d tree.  All nodes that have 
		vec[divfeat] < divval are placed in the child1 subtree, else child2.
		A leaf node is indicated if both children are NULL.
	*/
	struct TreeSt {
		int divfeat;    /* Index of the vector feature used for subdivision.
							If this is a leaf node (both children are NULL) then
							this holds vector index for this leaf. */
		float divval;   /* The value used for subdivision. */
		TreeSt* child1, child2;  /* Child nodes. */
	};
	alias TreeSt* Tree;
	
	/* This record represents a branch point when finding neighbors in
		the tree.  It contains a record of the minimum distance to the query
		point, as well as the node at which the search resumes.
	*/
	struct BranchSt {
		Tree node;           /* Tree node at which search resumes */
		float mindistsq;     /* Minimum distance to query for all nodes below. */
		
		int opCmp(BranchSt rhs) 
		{ 
			if (mindistsq < rhs.mindistsq) {
				return -1;
			} if (mindistsq > rhs.mindistsq) {
				return 1;
			} else {
				return 0;
			}
		}
		
		static BranchSt opCall(Tree aNode, float dist) 
		{
			BranchSt s;
			s.node = aNode;
			s.mindistsq = dist;
			
			return s;
		}
		
	}; 
	alias BranchSt* Branch;
	
	
	private this()
	{
	}

	
	/*------------------------ Build k-d tree index ---------------------------*/
	
	/* Build and return the k-d tree index used to find nearest neighbors to
		a set of vectors. 
	vecs: array of pointers to the vectors to be indexed.
	vcount: number of vectors in vecs.
	veclen: the length of each vector.
	numTrees_: the number of randomized trees to build.
	*/
	public this(Features inputData, Params params)
	{
		//std.gc.disable();
		pool = new Pool();    /* All data for the index goes into this pool. */
		this.numTrees_ = params.numTrees;
		this.vcount = inputData.count;
		this.veclen = inputData.veclen;
		this.vecs = inputData.vecs;
		this.trees = pool.malloc!(Tree)(numTrees_);
		this.heap = new Heap!(BranchSt)(vecs.length);
		this.checkID = -1000;
		
		this.freeIndSize = 0;
		this.freeIndCount = 0;
	
		/* Create a permutable array of indices to the input vectors. */
		this.vind = pool.malloc!(int)(vcount);
		for (int i = 0; i < vcount; i++) {
			this.vind[i] = i;
		}
	}
	
	
	public void buildIndex() 
	{
		/* Construct the randomized trees. */
		for (int i = 0; i < numTrees_; i++) {
	
			/* Randomize the order of vectors to allow for unbiased sampling. */
			for (int j = 0; j < vcount; j++) {
				int rand = cast(int) (drand48() * vcount);  
				//rand = random(vcount)%vcount;  
				assert(rand >=0 && rand < vcount);
				swap(this.vind[j], this.vind[rand]);
			}
			this.trees[i] = null;
			DivideTree(& this.trees[i], 0, vcount - 1);
		}
		
		writef("Mean cluster variance for %d top level clusters: %f\n",20,meanClusterVariance(20));
	}
	
	
	/* Free all memory used to create this this.
	*/
	public ~this()
	{
		delete this.pool;
	}
	
	
	public int size() 
	{
		return vcount;
	}
	
	public int numTrees()
	{
		return numTrees_;
	}
	
	
	/* Create a tree node that subdivides the list of vecs from vind[first]
		to vind[last].  The routine is called recursively on each sublist.
		Place a pointer to this new tree node in the location pTree. 
	*/
	private void DivideTree(Tree* pTree, int first, int last)
	{
		Tree node;
	
		node = this.pool.malloc!(TreeSt)();
//		node = cast(TreeSt*) .malloc(TreeSt.sizeof);
//		node = new TreeSt();
		
		*pTree = node;
	
		/* If only one exemplar remains, then make this a leaf node. */
		if (first == last) {
			node.child1 = node.child2 = null;    /* Mark as leaf node. */
			node.divfeat = this.vind[first];    /* Store index of this vec. */
		} else {
			ChooseDivision(node, first, last);
			Subdivide(node, first, last);
		}
	}
	
	
	/* Choose which feature to use in order to subdivide this set of vectors.
		Make a random choice among those with the highest variance, and use
		its variance as the threshold value.
	*/
	private void ChooseDivision(Tree node, int first, int last)
	{
		static float[] mean, var;	
		if (mean==null) {
			mean = new float[this.veclen];
			var = new float[this.veclen];
		}
		// Simpler D-specific initialization
		mean[] = 0.0;
		var[] = 0.0;
		/*
		for (i = 0; i < this.veclen; i++) {
			mean[i] = 0.0;
			var[i] = 0.0;
		}*/
		
		/* Compute mean values.  Only the first SampleMean values need to be
			sampled to get a good estimate.
		*/
		int end = MIN(first + SampleMean, last);
		int ind, count = 0;
		for (int j = first; j <= end; j++) {
			count++;
			ind = this.vind[j];
			for (int i = 0; i < this.veclen; i++)
				mean[i] += this.vecs[ind][i];
		}
		for (int i = 0; i < this.veclen; i++)
			mean[i] /= count;
	
		/* Compute variances (no need to divide by count). */
		for (int j = first; j <= end; j++) {
			ind = this.vind[j];
			for (int i = 0; i < this.veclen; i++) {
				float val = this.vecs[ind][i];
				float dist = val - mean[i];
				var[i] += dist * dist;
			}
		}
		/* Select one of the highest variance indices at random. */
		node.divfeat = SelectDiv(var);
		node.divval = mean[node.divfeat];
	}
	
	
	/* Select the top RandDim largest values from v and return the index of
		one of these selected at random.
	*/
	private int SelectDiv(float[] v)
	{
		int i, j, rand, num = 0;
		int topind[RandDim];
	
		/* Create a list of the indices of the top RandDim values. */
		for (i = 0; i < v.length; i++) {
			if (num < RandDim  ||  v[i] > v[topind[num-1]]) {
				/* Put this element at end of topind. */
				if (num < RandDim)
					topind[num++] = i;            /* Add to list. */
				else topind[num-1] = i;         /* Replace last element. */
				/* Bubble end value down to right location by repeated swapping. */
				j = num - 1;
				while (j > 0  &&  v[topind[j]] > v[topind[j-1]]) {				
					swap(topind[j], topind[j-1]);
					j--;
				}
			}
		}
		/* Select a random integer in range [0,num-1], and return that index. */
		//rand = random(num)%num;
		rand = cast(int) (drand48() * num);
		assert(rand >=0 && rand < num);
		return topind[rand];
	}
	
	
	/* Subdivide the list of exemplars using the feature and division
		value given in this node.  Call DivideTree recursively on each list.
	*/
	private void Subdivide(Tree node, int first, int last)
	{
		int i, j, ind;
		float val;
	
		/* Move vector indices for left subtree to front of list. */
		i = first;
		j = last;
		while (i <= j) {
			ind = this.vind[i];
			val = this.vecs[ind][node.divfeat];
			if (val < node.divval) {
				i++;
			} else {
				/* Move to end of list by swapping vind i and j. */
				swap(this.vind[i], this.vind[j]);
				j--;
			}
		}
		/* If either list is empty, it means we have hit the unlikely case
			in which all remaining features are identical.  We move one
			vector to the empty list to avoid need for special case.
		*/
		if (i == first)
			i++;
		if (i == last + 1)
			i--;
	
		DivideTree(& node.child1, first, i - 1);
		DivideTree(& node.child2, i, last);
	}
	
	
	
	/*----------------------- Insert and remove operations ------------------------*/
	
	/* Allocates more space in case the InsertElement method needs it
	 */
	private void IncreaseVecStorage()
	{
//		int old_size = this.vsize;
		int new_size = vecs.length*2;
		
		vecs.length = new_size;
		/+
		int* old_vind = this.vind;
		float** old_vecs = this.vecs;
		
		//allocate new memory
		this.vind = this.pool.malloc!(int)(new_size);
		this.vecs = this.pool.malloc!(float*)(new_size);
		
		// copy old vector values
		for (int i=0;i<this.vcount;++i) {
			this.vind[i] = old_vind[i];
			this.vecs[i] = old_vecs[i];
		}
		
		this.vsize = new_size;
		+/
	}
	
	
	/* Inserts a new element into the kd-tree 
	*/
	public int InsertElement(float[] vec)
	{
		int ind = -1;
		
		//  Check first for "holes" in the array of vectors
		if (this.freeIndCount>0) {
			ind = this.freeInd[--this.freeIndCount];
			this.vcount++;
		} else {
			if (this.vcount==this.vecs.length) {
				IncreaseVecStorage();
			}
			ind = this.vcount++;
		}
		// add the new vector to the array
		this.vecs[ind] = vec;
		this.vind[ind] = ind;
		
		// update all the trees
		for (int t = 0; t < this.numTrees_; ++t ) {
			InsertIntoTree(this.trees[t],ind);
		}
		
		return ind;
	}
	
	private void InsertIntoTree(Tree node, int ind)
	{
		float[] vec = this.vecs[ind];
		if (node.child1==null && node.child2==null) {
			// insert element
			
			node.child1 = this.pool.malloc!(TreeSt)();
			node.child2 = this.pool.malloc!(TreeSt)();
			
			node.child1.divfeat = ind;
			node.child2.divfeat = node.divfeat;
			
			// find dimension with greatest variance
			float var = -1;
			int feat = -1;
			for (int i=0; i<this.veclen; ++i ) {
				float tmp = ABS(vec[i]-this.vecs[node.divfeat][i]);
				if (tmp>var) {
					var = tmp;
					feat = i;
				}
			}
			
			if (vec[feat] > this.vecs[node.divfeat][feat]) {
				swap(node.child1, node.child2);
			}
			
			node.divval = (vec[feat] + this.vecs[node.divfeat][feat])/2;		
			node.divfeat = feat;
		} 
		else {
			
			if (vec[node.divfeat]< node.divval) {
				InsertIntoTree(node.child1, ind);
			} else {
				InsertIntoTree(node.child2, ind);
			}
		}
	}
	
	
	private void IncreaseFreeInd() 
	{
		int old_size = this.freeIndSize;
		int new_size = (old_size==0?8:old_size*2);
		
		int* old_freeInd = this.freeInd;
		
		//allocate new memory
		this.freeInd = this.pool.malloc!(int)(new_size);
		
		// copy old vector values
		for (int i=0;i<this.freeIndCount;++i) {
			this.freeInd[i] = old_freeInd[i];
		}
		
		this.freeIndSize = new_size;
	}
	
	/* Removes an element from the kd-trees
	*/
	public bool RemoveElement(int ind) 
	{
		if (this.freeIndCount==this.freeIndSize) {
			IncreaseFreeInd();
		}
		// mark vector space as free
		this.freeInd[this.freeIndCount++] = ind;
		
		
		bool removed = true;
	
		// update all the trees
		for (int t = 0; t < this.numTrees_; ++t ) {
			Tree node = this.trees[t];
			
			if (node.child1==null && node.child2==null && node.divfeat==ind) {
				this.trees[t] = null;
			}
			else {
					if (!RemoveFromTree(node,null,ind)) {
						removed = false;
					}
			}
		}
		
		this.vcount--;
		
		return removed;
	}
	
	
	
	private bool RemoveFromTree(Tree node,Tree parent, int ind)
	{
		float[] vec = this.vecs[ind];
		
		if (node.child1==null && node.child2==null && node.divfeat==ind) {
			// remove element
			Tree otherChild;
			if (parent.child1==node) {
				otherChild = parent.child2;
			}
			else {
				otherChild = parent.child1;
			}
			
			// remove node from tree
			parent.divfeat = otherChild.divfeat;
			parent.divval = otherChild.divval;
			parent.child1 = otherChild.child1;
			parent.child2 = otherChild.child2;
			
			return true;
		}
		else if (node.child1!=null && node.child2!=null) {
			if (vec[node.divfeat]<node.divval) {
				return RemoveFromTree(node.child1,node,ind);
			} else {
				return RemoveFromTree(node.child2,node,ind);
			}
		}
		else {
			return false;
		}
		
	}
	
	
	/*----------------------- Nearest Neighbor Lookup ------------------------*/
	
	
	/* Find set of numNN nearest neighbors to vec, and place their indices
		(location in original vector given to BuildIndex) in result.
	*/
	public void findNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
		GetNeighbors(result, vec, maxCheck);
	}
	
	private void GetNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
		int i;
		BranchSt branch;
	
//		this.ncount = 0;
		this.checkCount = 0;
		this.heap.init();
		this.checkID -= 1;  /* Set a different unique ID for each search. */
	
		/* Make sure this.dsqs is long enough to hold numNN values. */
/+		if (result.length > this.dsqlen) {
			this.dsqs = this.pool.malloc!(float)(result.length);
			this.dsqlen = result.length;
		}+/
	
		/* Search once through each tree down to root. */
		for (i = 0; i < this.numTrees_; i++) {
			SearchLevel(result, vec, this.trees[i], 0.0, maxCheck);
		}
	
		/* Keep searching other branches from heap until finished. */
		while ( this.heap.popMin(branch) 
			&& (this.checkCount < maxCheck || !result.full )) {
			SearchLevel(result, vec, branch.node,
					branch.mindistsq, maxCheck);
		}
		assert(result.full);
	}
	
	
	/* Search starting from a given node of the tree.  Based on any mismatches at
		higher levels, all exemplars below this level must have a distance of
		at least "mindistsq". 
	*/
	private void SearchLevel(ResultSet result, float[] vec, 
			Tree node, float mindistsq, int maxCheck)
	{
		float val, diff;
		Tree bestChild, otherChild;
	
		/* If this is a leaf node, then do check and return. */
		if (node.child1 == null  &&  node.child2 == null) {
		
			this.checkCount += 1;
		
			/* Do not check same node more than once when searching multiple trees.
				Once a vector is checked, we set its location in this.vind to the
				current this.checkID.
			*/
			if (this.vind[node.divfeat] == this.checkID)
				return;
			this.vind[node.divfeat] = this.checkID;
		
			result.addPoint(vecs[node.divfeat],node.divfeat);
			//CheckNeighbor(result, node.divfeat, vec);
			return;
		}
	
		/* Which child branch should be taken first? */
		val = vec[node.divfeat];
		diff = val - node.divval;
		bestChild = (diff < 0) ? node.child1 : node.child2;
		otherChild = (diff < 0) ? node.child2 : node.child1;
	
		/* Create a branch record for the branch not taken.  Add distance
			of this feature boundary (we don't attempt to correct for any
			use of this feature in a parent node, which is unlikely to
			happen and would have only a small effect).  Don't bother
			adding more branches to heap after halfway point, as cost of
			adding exceeds their value.
		*/
		if (2 * this.checkCount < maxCheck  ||  !result.full) {
			this.heap.insert( BranchSt(otherChild, cast(int)(mindistsq + diff * diff)) );
		}
	
		/* Call recursively to search next level down. */
		SearchLevel(result, vec, bestChild, mindistsq, maxCheck);
	}
	
	
	float[][] getClusterPoints(Tree node)
	{
		float[][] points = new float[][10];
		int size = 0;
		getClusterPoints_Helper(node,points,size);
		
		return points[0..size];
	}
	
	void getClusterPoints_Helper(Tree node, inout float[][] points, inout int size) 
	{
		if (node.child1 == null && node.child2 == null) {
			if (size==points.length) {
				points.length = points.length*2;
			}
			points[size++] = this.vecs[node.divfeat];
		}
		else {
			getClusterPoints_Helper(node.child1,points,size);
			getClusterPoints_Helper(node.child2,points,size);
		}
	}
	
	
	public float meanClusterVariance(int numClusters)
	{
		Queue!(Tree) q = new Queue!(Tree)(numClusters);
		
		q.push(this.trees[0]);

		while(!q.full) {
			Tree t;
			q.pop(t);
			if (t.child1==null && t.child2==null) {
				q.push(t);
			}
			else {
				q.push(t.child1);
				q.push(t.child2);
			}
		}
			
		float variances[] = new float[q.size];
		int clusterSize[] = new int[q.size];
		
		for (int i=0;i<q.size;++i) {
			float[][] clusterPoints = getClusterPoints(q[i]);
			variances[i] = computeVariance(clusterPoints);
			clusterSize[i] = clusterPoints.length;
		}
		
		float meanVariance = 0;
		int sum = 0;
		for (int i=0;i<variances.length;++i) {
			meanVariance += variances[i]*clusterSize[i];
			sum += clusterSize[i];
		}
		meanVariance/=sum;
		
		return meanVariance;		
	}
	
	
	void describe(T)(T ar)
	{
	}		
	
	void save(string file)
	{
		Serializer s = new Serializer(file, FileMode.Out);
		s.describe(this);
	}
}
