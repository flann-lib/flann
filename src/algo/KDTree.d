/************************************************************************
 * KDTree approximate nearest neighbor search
 * 
 * This module finds the nearest-neighbors of vectors in high dimensional 
 * spaces using a search of multiple randomized k-d trees.
 * 
 * Authors: David Lowe, initial implementation
 * 			Marius Muja, conversion to D and further changes
 * 
 * Version: 0.9
 * 
 * History:
 * 
 * License:
 * 
 *************************************************************************/

module algo.KDTree;

import dataset.Dataset;
import algo.NNIndex;
import util.Allocator;
import util.Utils;
import util.Random;
import util.Heap;
import util.Logger;

/**
 * Randomized kd-tree index
 * 
 * Contains the k-d trees and other information for indexing a set of points
 * for nearest-neighbor matching.
 */
class KDTree(T) : NNIndex{

	/**
	 * Index name.
	 * 
	 * Used by the AlgorithmRegistry template for registering a new algorithm with
	 * the application. 
	 */
	static const NAME = "kdtree";

	/**
	 * To improve efficiency, only SAMPLE_MEAN random values are used to
	 * compute the mean and variance at each level when building a tree.
	 * A value of 100 seems to perform as well as using all values.
	 */
	const int SAMPLE_MEAN = 100;
	
	/**
	 * Top random dimensions to consider
	 * 
	 * When creating random trees, the dimension on which to subdivide is
	 * selected at random from among the top RAND_DIM dimensions with the
	 * highest variance.  A value of 5 works well.
	 */
	const int RAND_DIM=5;
	
	
	/**
	 * Number of randomized trees that are used
	 */
	private int numTrees_;       	

	/**
	 * Number of neighbors checked in one lookup phase
	 */
	private int checkCount;

	/**
	 * The dataset containing the vectors.
	 */
	private T[][] vecs;

	/**
	 * Number of vectors stored in this index.
	 */
	private int vcount;
	
	/**
	 * Length of each vector.
	 */
	private int veclen;
	
	/**
	 *  Array of indices to vecs.  When doing lookup, 
	 *  this is used instead to mark checkID.
	 */
	private int[] vind;
	
	/**
	 * An unique ID for each lookup.
	 */
	private int checkID;
	

	/**
	 * Array of k-d trees used to find neighbors.
	 */
	private Tree[] trees;
	
	
	alias BranchStruct!(Tree) BranchSt;
	alias BranchSt* Branch;
	/**
	 * Priority queue storing intermediate branches in the best-bin-first search
	 */
	private Heap!(BranchSt) heap;
	

	/*--------------------- Internal Data Structures --------------------------*/
	
	/**
	 * A node of the binary k-d tree.
	 * 
	 *  This is   All nodes that have vec[divfeat] < divval are placed in the
	 *   child1 subtree, else child2., A leaf node is indicated if both children are NULL.
	 */
	struct TreeSt {
		/**
		 * Index of the vector feature used for subdivision.
		 * If this is a leaf node (both children are NULL) then
		 * this holds vector index for this leaf. 
		 */
		int divfeat;
		/**
		 * The value used for subdivision.
		 */
		float divval;
		/**
		 * The child nodes.
		 */
		Tree child1, child2;
	};
	alias TreeSt* Tree;
	
	
	/**
	 * Pooled memory allocator.
	 * 
	 * Using a pooled memory allocator is more efficient
	 * than allocating memory directly when there is a large
	 * number small of memory allocations.
	 */
	private	PooledAllocator pool;
	
	
	/**
	 * KDTree constructor
	 *
	 * Params:
	 * 		inputData = dataset with the input features
	 * 		params = parameters passed to the kdtree algorithm
	 */
	public this(Dataset!(T) inputData, Params params)
	{
		pool = new PooledAllocator();
	
		// get the parameters
		numTrees_ = params["trees"].get!(uint);
		
		vcount = inputData.rows;
		veclen = inputData.cols;
		vecs = inputData.vecs;
		trees = pool.allocate!(Tree[])(numTrees_);
		heap = new Heap!(BranchSt)(vecs.length);
		checkID = -1000;
			
		// Create a permutable array of indices to the input vectors.
		vind = allocate!(int[])(vcount);
		for (int i = 0; i < vcount; i++) {
			vind[i] = i;
		}
	}
	
	/**
	 * Standard destructor
	 */
	public ~this()
	{
		debug {
			logger.info(sprint("KDTree used memory: {} KB", pool.usedMemory/1000));
			logger.info(sprint("KDTree wasted memory: {} KB", pool.wastedMemory/1000));
			logger.info(sprint("KDTree total memory: {} KB", pool.usedMemory/1000+pool.wastedMemory/1000));
		}
		free(vind);
		delete pool;
	}
	
	
	/**
	 * Builds the index
	 */
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
			divideTree(&trees[i], 0, vcount - 1);
		}
		
		//Logger.log(Logger.INFO,"Mean cluster variance for %d top level clusters: %f\n",20,meanClusterVariance(20));
	}
	
	/**
	 * Size of the index
	 * Returns: number of points in the index
	 */
	public int size() 
	{
		return vcount;
	}
	
	/**
	 * 
	 * Returns: length of each vector(point) in the index
	 */
	public int length()
	{
		return veclen;
	}
	
	/**
	 * 
	 * Returns: number of random trees in the index
	 */
	public int numTrees()
	{
		return numTrees_;
	}
	
	
	/**
	 * Computes the inde memory usage
	 * Returns: memory used by the index
	 */
	public int usedMemory()
	{
		return  pool.usedMemory+pool.wastedMemory+vind.length*int.sizeof;
	}
	
	/* Create a tree node that subdivides the list of vecs from vind[first]
		to vind[last].  The routine is called recursively on each sublist.
		Place a pointer to this new tree node in the location pTree. 
	*/
	private void divideTree(Tree* pTree, int first, int last)
	{
		Tree node;
	
		node = pool.allocate!(TreeSt);//allocate!(TreeSt)();
		*pTree = node;
	
		/* If only one exemplar remains, then make this a leaf node. */
		if (first == last) {
			node.child1 = node.child2 = null;    /* Mark as leaf node. */
			node.divfeat = vind[first];    /* Store index of this vec. */
		} else {
			chooseDivision(node, first, last);
			subdivide(node, first, last);
		}
	}
	
	
	/* Choose which feature to use in order to subdivide this set of vectors.
		Make a random choice among those with the highest variance, and use
		its variance as the threshold value.
	*/
	private void chooseDivision(Tree node, int first, int last)
	{
// 		scope float[] mean = new float[veclen];
// 		scope float[] var = new float[veclen];
/+		float[] mean = (cast(float*)alloca(veclen*float.sizeof))[0..veclen];
		float[] var = (cast(float*)alloca(veclen*float.sizeof))[0..veclen];+/
		
		float[] mean =  allocate!(float[])(veclen);
		scope(exit) free(mean);
		float[] var =  allocate!(float[])(veclen);
		scope(exit) free(var);
		
		mean[] = 0.0;
		var[] = 0.0;
		
		/* Compute mean values.  Only the first SAMPLE_MEAN values need to be
			sampled to get a good estimate.
		*/
		int end = MIN(first + SAMPLE_MEAN, last);
		int count = end - first + 1;
		for (int j = first; j <= end; ++j) {
			T[] v = vecs[vind[j]];
			mean.add(v);
		}
		foreach (ref elem; mean) {
			elem /= count;
		}
	
		/* Compute variances (no need to divide by count). */
		for (int j = first; j <= end; ++j) {
			T[] v = vecs[vind[j]];
			foreach (i, ref elem; v) {
				float dist = elem - mean[i];
				var[i] += dist * dist;
			}
		}
		/* Select one of the highest variance indices at random. */
		node.divfeat = selectDivision(var);
		node.divval = mean[node.divfeat];		
	}
	
	
	/* Select the top RAND_DIM largest values from v and return the index of
		one of these selected at random.
	*/
	private int selectDivision(float[] v)
	{
		int num = 0;
		int topind[RAND_DIM];
	
		/* Create a list of the indices of the top RAND_DIM values. */
		for (int i = 0; i < v.length; ++i) {
			if (num < RAND_DIM  ||  v[i] > v[topind[num-1]]) {
				/* Put this element at end of topind. */
				if (num < RAND_DIM) {
					topind[num++] = i;            /* Add to list. */
				}
				else {
					topind[num-1] = i;         /* Replace last element. */
				}
				/* Bubble end value down to right location by repeated swapping. */
				int j = num - 1;
				while (j > 0  &&  v[topind[j]] > v[topind[j-1]]) {				
					swap(topind[j], topind[j-1]);
					--j;
				}
			}
		}
		/* Select a random integer in range [0,num-1], and return that index. */
		int rand = cast(int) (drand48() * num);
		assert(rand >=0 && rand < num);
		return topind[rand];
	}
	
	
	/* subdivide the list of exemplars using the feature and division
		value given in this node.  Call divideTree recursively on each list.
	*/
	private void subdivide(Tree node, int first, int last)
	{	
		/* Move vector indices for left subtree to front of list. */
		int i = first;
		int j = last;
		while (i <= j) {
			int ind = vind[i];
			float val = vecs[ind][node.divfeat];
			if (val < node.divval) {
				++i;
			} else {
				/* Move to end of list by swapping vind i and j. */
				swap(vind[i], vind[j]);
				--j;
			}
		}
		/* If either list is empty, it means we have hit the unlikely case
			in which all remaining features are identical.  We move one
			vector to the empty list to avoid need for special case.
		*/
		if (i == first) {
			++i;
		}
		if (i == last + 1) {
			--i;
		}
		
		divideTree(& node.child1, first, i - 1);
		divideTree(& node.child2, i, last);
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
		checkID -= 1;  /* Set a different unique ID for each search. */
	
		if (numTrees_ > 1) {
			logger.info("Doesn't make any sense to use more than one tree for exact search");
		}
		if (numTrees_>0) {
			SearchLevelExact(result, vec, trees[0], 0.0);		
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
		for (i = 0; i < numTrees_; ++i) {
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
	
	private void SearchLevelExact(ResultSet result, float[] vec, Tree node, float mindistsq)
	{
		float val, diff;
		Tree bestChild, otherChild;
	
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
	
	
	
	private float meanClusterVariance(int numClusters)
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
}

mixin AlgorithmRegistry!(KDTree!(float),float);
mixin AlgorithmRegistry!(KDTree!(ubyte),ubyte);
