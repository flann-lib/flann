
/************************************************************************
Project: nn

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

module algo.kdtree;

// import std.c.stdlib;
// import std.c.math;
// import std.c.string;
// import std.gc;

import util.utils;
import util.random;
import util.heap;
import dataset.features;
import util.resultset;
import util.logger;
import algo.nnindex;
import util.allocator;
import util.registry;



/* Contains the k-d trees and other information for indexing a set of points
   for nearest-neighbor matching.
 */

class KDTree(T) : NNIndex{

	static const NAME = "kdtree";

	int numTrees_;       /* Number of randomized trees that are used. */
	int checkCount;     /* Number of neighbors checked so far in this lookup. */
	float searchDistSq; /* Distance cutoff for searching (not used yet). */
	int vcount;         /* Number of vectors stored in this index. */
	int veclen;         /* Length of each vector. */
	T[][] vecs;      /* Float vecs.  */
	int []vind;          /* Array of indices to vecs.  When doing
						   lookup, this is used instead to mark checkID. */
	
	int checkID;        /* A unique ID for each lookup. */
	Tree []trees;  /* Array of k-d trees used to find neighbors. */
	
	alias BranchStruct!(Tree) BranchSt;
	alias BranchSt* Branch;

	Heap!(BranchSt) heap;
	


	
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
	

	
	
	
	private this()
	{
	}

	
	/*------------------------ Build k-d tree index ---------------------------*/
	
	/* Build and return the k-d tree index used to find nearest neighbors to
		a set of vectors. 
	*/
	public this(Features!(T) inputData, Params params)
	{
		numTrees_ = params["trees"].get!(uint);
		vcount = inputData.count;
		veclen = inputData.veclen;
		vecs = inputData.vecs;
		trees = new Tree[numTrees_];
		heap = new Heap!(BranchSt)(vecs.length);
		checkID = -1000;
		
	
		/* Create a permutable array of indices to the input vectors. */
		vind = new int[vcount];
		for (int i = 0; i < vcount; i++) {
			vind[i] = i;
		}
	}
	
	
	public void buildIndex() 
	{
		/* Construct the randomized trees. */
		for (int i = 0; i < numTrees_; i++) {
			/* Randomize the order of vectors to allow for unbiased sampling. */
			for (int j = 0; j < vcount; j++) {
				int rand = cast(int) (drand48() * vcount);  
				assert(rand >=0 && rand < vcount);
				swap(vind[j], vind[rand]);
			}
			trees[i] = null;
			DivideTree(& trees[i], 0, vcount - 1);
		}
		
		//Logger.log(Logger.INFO,"Mean cluster variance for %d top level clusters: %f\n",20,meanClusterVariance(20));
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
	
		node = new TreeSt();//allocate!(TreeSt)();
		*pTree = node;
	
		/* If only one exemplar remains, then make this a leaf node. */
		if (first == last) {
			node.child1 = node.child2 = null;    /* Mark as leaf node. */
			node.divfeat = vind[first];    /* Store index of this vec. */
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
		mixin(allocate_static("float[veclen] mean;"));
		mixin(allocate_static("float[veclen] var;"));
		
		mean[] = 0.0;
		var[] = 0.0;
		
		/* Compute mean values.  Only the first SampleMean values need to be
			sampled to get a good estimate.
		*/
		int end = MIN(first + SampleMean, last);
		int ind, count = 0;
		for (int j = first; j <= end; ++j) {
			count++;
			ind = vind[j];
			for (int i = 0; i < veclen; ++i)
				mean[i] += vecs[ind][i];
		}
		for (int i = 0; i < veclen; ++i)
			mean[i] /= count;
	
		/* Compute variances (no need to divide by count). */
		for (int j = first; j <= end; ++j) {
			ind = vind[j];
			for (int i = 0; i < veclen; ++i) {
				float val = vecs[ind][i];
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
			ind = vind[i];
			val = vecs[ind][node.divfeat];
			if (val < node.divval) {
				i++;
			} else {
				/* Move to end of list by swapping vind i and j. */
				swap(vind[i], vind[j]);
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
	
	
	/*----------------------- Nearest Neighbor Lookup ------------------------*/
	
	
	/* Find set of numNN nearest neighbors to vec, and place their indices
		(location in original vector given to BuildIndex) in result.
	*/
	public void findNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
		if (maxCheck==-1) {
			GetExactNeighbors(result, vec);
		} else {
			GetNeighbors(result, vec, maxCheck);
		}
	}
	
	private void GetExactNeighbors(ResultSet result, float[] vec)
	{
		int i;
		BranchSt branch;
	
		checkID -= 1;  /* Set a different unique ID for each search. */
	
		leafs = 0;
	
		/* Search once through each tree down to root. */
		for (i = 0; i < numTrees_; i++) {
			SearchLevelExact(result, vec, trees[i], 0.0);
		}
		assert(result.full);
	}
	
	private void GetNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
	
		int i;
		BranchSt branch;
	
		checkCount = 0;
		heap.init();
		checkID -= 1;  /* Set a different unique ID for each search. */
	
		/* Search once through each tree down to root. */
		for (i = 0; i < numTrees_; i++) {
			SearchLevel(result, vec, trees[i], 0.0, maxCheck);
		}
	
		/* Keep searching other branches from heap until finished. */
		while ( heap.popMin(branch) 
			&& (checkCount++ < maxCheck || !result.full )) {
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
	
// 		if (mindistsq > result.worstDist) {
// 			return;
// 		}

	
		/* If this is a leaf node, then do check and return. */
		if (node.child1 == null  &&  node.child2 == null) {
		
		//	checkCount += 1;
		
			/* Do not check same node more than once when searching multiple trees.
				Once a vector is checked, we set its location in vind to the
				current checkID.
			*/
			if (vind[node.divfeat] == checkID) {
				return;
			}
			vind[node.divfeat] = checkID;
		
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
		if (2 * checkCount < maxCheck  ||  !result.full) {
			heap.insert( BranchSt(otherChild, mindistsq + diff * diff) );
		}
	
		/* Call recursively to search next level down. */
		SearchLevel(result, vec, bestChild, mindistsq, maxCheck);
	}
	
	int leafs = 0;
	
	private void SearchLevelExact(ResultSet result, float[] vec, Tree node, float mindistsq)
	{
		float val, diff;
		Tree bestChild, otherChild;
	
/+		if (mindistsq > result.worstDist) {
			return;
		}+/
	
	
		/* If this is a leaf node, then do check and return. */
		if (node.child1 == null  &&  node.child2 == null) {
		
			/* Do not check same node more than once when searching multiple trees.
				Once a vector is checked, we set its location in vind to the
				current checkID.
			*/
			if (vind[node.divfeat] == checkID)
				return;
			vind[node.divfeat] = checkID;
		
			result.addPoint(vecs[node.divfeat],node.divfeat);
			//CheckNeighbor(result, node.divfeat, vec);
			return;
		}
	
		/* Which child branch should be taken first? */
		val = vec[node.divfeat];
		diff = val - node.divval;
		bestChild = (diff < 0) ? node.child1 : node.child2;
		otherChild = (diff < 0) ? node.child2 : node.child1;
	
	
		/* Call recursively to search next level down. */
		SearchLevelExact(result, vec, bestChild, mindistsq);
		SearchLevelExact(result, vec, otherChild, mindistsq+diff * diff);
	}
	
	
	
	T[][] getClusterPoints(Tree node)
	{
		void getClusterPoints_Helper(Tree node, inout T[][] points, inout int size) 
		{
			if (node.child1 == null && node.child2 == null) {
				points[size++] = vecs[node.divfeat];
			}
			else {
				getClusterPoints_Helper(node.child1,points,size);
				getClusterPoints_Helper(node.child2,points,size);
			}
		}
		
		static T[][] points;
		if (points==null) {
			points = new T[][vcount];
		}
		int size = 0;
		getClusterPoints_Helper(node,points,size);
		
		return points[0..size];
	}
	
	
	
	public float meanClusterVariance(int numClusters)
	{
		Queue!(Tree) q = new Queue!(Tree)(numClusters);
		
		q.push(trees[0]);

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
			T[][] clusterPoints = getClusterPoints(q[i]);
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
	
}

mixin AlgorithmRegistry!(KDTree!(float),float);
mixin AlgorithmRegistry!(KDTree!(ubyte),ubyte);
