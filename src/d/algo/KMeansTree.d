/************************************************************************
 * Hierarchical KMeans approximate nearest neighbor search
 * 
 * This module finds the nearest-neighbors of vectors in high dimensional 
 * spaces using a search of a kmeans tree.
 * 
 * Authors: Marius Muja, mariusm@cs.ubc.ca
 * 
 * Version: 1.0
 * 
 * History:
 * 
 * License: LGPL
 * 
 *************************************************************************/
module algo.KMeansTree;

import util.defines;
import algo.NNIndex;
import algo.dist;
import dataset.Dataset;
import util.Logger;
import util.Random;
import util.Allocator;
import util.Utils;
import util.Heap;

import tango.math.Math;
import tango.io.Stdout;

/**
 * Hierarchical kmeans index
 * 
 * Contains a tree constructed through a hierarchical kmeans clustering 
 * and other information for indexing a set of points for nearest-neighbor matching.
 */
class KMeansTree(T) : NNIndex
{
	/**
	 * Index name.
	 * 
	 * Used by the AlgorithmRegistry template for registering a new algorithm with
	 * the application. 
	 */
	static const NAME = "kmeans";

	/**
	 * Alias definition for a nicer syntax.
	 */
	alias BranchStruct!(KMeansNode) BranchSt;
	/** ditto */
	alias Heap!(BranchSt) BranchHeap; 


	/**
	 * The branching factor used in the hierarchical k-means clustering
	 */
	private uint branching;
	
	/**
	 * Maximum number of iterations to use when performing k-means 
	 * clustering
	 */
	private uint max_iter;
	
	/**
	 * Cluster border index. This is used in the tree search phase when determining
	 * the closest cluster to explore next. A zero value takes into account only
	 * the cluster centers, a value greater then zero also take into account the size
	 * of the cluster.
	 */
	public float cb_index;
	
	/**
	 * The dataset used by this index
	 */
	Dataset!(T) dataset;
	
	/**
	 * Priority queue storing intermediate branches in the best-bin-first search
	 */
	private BranchHeap heap;	
	
	/**
	 * Struture representing a node in the hierarchical k-means tree. 
	 */
	struct KMeansNodeSt	{
		/**
		 * The cluster center.
		 */
		float[] pivot;
		/**
		 * The cluster radius.
		 */
		float radius;
		/**
		 * The cluster mean radius.
		 */
		float mean_radius;
		/**
		 * The cluster variance.
		 */
		float variance;
		/**
		 * The cluster size (number of points in the cluster)
		 */
		int size;
		/**
		 * Child nodes (only for non-terminal nodes)
		 */
		KMeansNode[] childs;
		/**
		 * Node points (only for terminal nodes)
		 */
		int[] indices;
		/**
		 * Level
		 */
		int level;
	}
	alias KMeansNodeSt* KMeansNode;
	

	/**
	 * The root node in the tree.
	 */
	public KMeansNode root;
	
	/**
	 *  Array of indices to vectors in the dataset. 
	 */
	private int[] indices;
	
	/**
	 * Pooled memory allocator.
	 * 
	 * Using a pooled memory allocator is more efficient
	 * than allocating memory directly when there is a large
	 * number small of memory allocations.
	 */
	private	PooledAllocator pool;
	
	/**
	 * Memory occupied by the index.
	 */
	private int memoryCounter;
	
	
	/**
	 * Array with distances to the kmeans domains of a node.
	 * Used during search phase.
	 */
	private float[] domain_distances;
	
	
	
	alias T[][] function(int k, T[][] vecs, int[] indices) centersAlgFunction;
	/**
	 * Associative array with functions to use for choosing the cluster centers. 
	 */
	static centersAlgFunction[string] centerAlgs;
	/**
	 * Static initializer. Performs initialization befor the program starts.
	 */
	static this() {
		centerAlgs["random"] = &chooseCentersRandom;
		centerAlgs["gonzales"] = &chooseCentersGonzales;		
		centerAlgs["kmeanspp"] = &chooseCentersKMeanspp;
	}
	
	/**
	 * The function used for choosing the cluster centers. 
	 */
	private centersAlgFunction chooseCenters;
	
	
	/**
	 * Index constructor
	 * 
	 * Params:
	 * 		inputData = dataset with the input features
	 * 		params = parameters passed to the hierarchical k-means algorithm
	 */
	public this(Dataset!(T) inputData, Params params)
	{
 		pool = new PooledAllocator();
		memoryCounter = 0;
	
		// get algorithm parameters
		this.branching = params["branching"].get!(uint);		
		if (branching<2) {
			throw new FLANNException("Branching factor must be at least 2");
		}
		int iterations = params["max-iterations"].get!(int);
		if (iterations<0) {
			iterations = int.max;
		}
		this.max_iter = iterations;
		
		string centersInit = params["centers-init"].get!(string);
		if (centersInit in centerAlgs) {
			chooseCenters = centerAlgs[centersInit];
		}
		else {
			throw new FLANNException("Unknown algorithm for choosing initial centers.");
		}
		cb_index = 0.5;
		
		domain_distances = allocate!(float[])(branching);
		this.dataset = inputData;	
 		heap = new BranchHeap(inputData.rows);
		root = null;
	}
	
	
	/**
	 * Index destructor.
	 * 
	 * Release the memory used by the index.
	 */
	public ~this()
	{
		void free_centers(KMeansNode node) {
 			free(node.pivot);
			if (node.childs.length!=0) {
				foreach (child;node.childs) {
					free_centers(child);
				}
			}
		}
		
		if (root !is null) {
			free_centers(root);
		}
 		debug {
			logger.info(sprint("KMeansTree used memory: {} KB", (pool.usedMemory+memoryCounter)/1000));
			logger.info(sprint("KMeansTree wasted memory: {} KB", pool.wastedMemory/1000));
			logger.info(sprint("KMeansTree total memory: {} KB", (memoryCounter+pool.usedMemory+pool.wastedMemory)/1000));
 		}
		delete pool;
		delete heap;
		delete indices;
		free(domain_distances);
	}

	/**
	 * Size of the index
	 * Returns: number of points in the index
	 */	
	public int size() 
	{
		return vecs.length;
	}
	
	/**
	 * 
	 * Returns: length of each vector(point) in the index
	 */
	public int veclen() 
	{
		return dataset.cols;
	}
	
	/**
	 * 
	 * Returns: number of trees in the index
	 */
	public int numTrees()
	{
		return 1;
	}
	
	/**
	 * Computes the inde memory usage
	 * Returns: memory used by the index
	 */
	public int usedMemory()
	{
		return  pool.usedMemory+pool.wastedMemory+memoryCounter;
	}



	
	/**
	 * 
	 * Returns: vectors in the dataset
	 */
	public T[][] vecs()
	{
		return dataset.vecs;
	}
	

	/**
	 * Chooses the initial centers in the k-means clustering in a random manner. 
	 * 
	 * Params:
	 *     k = number of centers 
	 *     vecs = the dataset of points
	 *     indices = indices in the dataset
	 * Returns:
	 */
	private static T[][] chooseCentersRandom(int k, T[][] vecs, int[] indices)
	{
		DistinctRandom r = new DistinctRandom(indices.length);
		scope(exit) delete r;
		
		static T[][] centers;
		if (centers is null || centers.length!=k) centers = new T[][k];
		int index;
		for (index=0;index<k;++index) {
			bool duplicate = true;
			int rnd;
			while (duplicate) {
				duplicate = false;
				rnd = r.nextRandom();
				if (rnd==-1) {
					return centers[0..index-1];
				}
				
				centers[index] = vecs[indices[rnd]];
				
				for (int j=0;j<index;++j) {
					float sq = squaredDist(centers[index],centers[j]);
					if (sq<1e-16) {
						duplicate = true;
					}
				}
			}
		}
		
		return centers[0..index];
	}

	/**
	 * Chooses the initial centers in the k-means using Gonzales' algorithm 
	 * so that the centers are spaced apart from each other. 
	 * 
	 * Params:
	 *     k = number of centers 
	 *     vecs = the dataset of points
	 *     indices = indices in the dataset
	 * Returns:
	 */
	private static T[][] chooseCentersGonzales(int k, T[][] vecs, int[] indices)
	{
		int n = indices.length;
		
		static T[][] centers;
		if (centers is null || centers.length!=k) centers = new T[][k];
		
// 		int rand = cast(int) (drand48() * n);  
		int rand = next_random(n);  
		assert(rand >=0 && rand < n);
		
		centers[0] = vecs[indices[rand]];
		
		int index;
		for (index=1; index<k; ++index) {
			
			int best_index = -1;
			float best_val = 0;
			for (int j=0;j<n;++j) {
				float dist = squaredDist(centers[0],vecs[indices[j]]);
				for (int i=1;i<index;++i) {
						float tmp_dist = squaredDist(centers[i],vecs[indices[j]]);
					if (tmp_dist<dist) {
						dist = tmp_dist;
					}
				}
				if (dist>best_val) {
					best_val = dist;
					best_index = j;
				}
			}
			if (best_index!=-1) {
				centers[index] = vecs[indices[best_index]];
			} 
			else {
				break;
			}
		}
		return centers[0..index];
	}


	/**
	 * Chooses the initial centers in the k-means using the algorithm 
	 * proposed in the KMeans++ paper:
	 * Arthur, David; Vassilvitskii, Sergei - k-means++: The Advantages of Careful Seeding
     *   
	 * Implementation of this function was converted from the one provided in Arthur's code.
     *     
	 * Params:
	 *     k = number of centers 
	 *     vecs = the dataset of points
	 *     indices = indices in the dataset
	 * Returns:
	 */
	private static T[][] chooseCentersKMeanspp(int k, T[][] vecs, int[] indices)
	{
		int n = indices.length;
		
		double currentPot = 0;
		static T[][] centers;
		static double[] closestDistSq;
		if (centers is null || centers.length!=k) {
			centers = new T[][k];
			closestDistSq = new double[n];
		}

		// Choose one random center and set the closestDistSq values
// 		int index = cast(int) (drand48() * n);  
		int index = next_random(n);  
		assert(index >=0 && index < n);
		centers[0] = vecs[indices[index]];
		
		for (int i = 0; i < n; i++) {
			closestDistSq[i] = squaredDist(vecs[indices[i]], vecs[indices[index]]);
			currentPot += closestDistSq[i];
		}


	const int numLocalTries = 1;

	// Choose each center
	int centerCount;
	for (centerCount = 1; centerCount < k; centerCount++) {

        // Repeat several trials
        double bestNewPot = -1;
        int bestNewIndex; 
        for (int localTrial = 0; localTrial < numLocalTries; localTrial++) {
		
    		// Choose our center - have to be slightly careful to return a valid answer even accounting
			// for possible rounding errors
// 		    double randVal = drand48() * currentPot;
		    double randVal = next_random() * currentPot;
            for (index = 0; index < n-1; index++) {
                if (randVal <= closestDistSq[index])
                    break;
                else
                    randVal -= closestDistSq[index];
            }

    		// Compute the new potential
            double newPot = 0;
		    for (int i = 0; i < n; i++)
                newPot += min( squaredDist(vecs[indices[i]], vecs[indices[index]]), closestDistSq[i] );

            // Store the best result
            if (bestNewPot < 0 || newPot < bestNewPot) {
                bestNewPot = newPot;
                bestNewIndex = index;
            }
		}

        // Add the appropriate center
        centers[centerCount] = vecs[indices[bestNewIndex]];
        currentPot = bestNewPot;
        for (int i = 0; i < n; i++)
            closestDistSq[i] = min( squaredDist(vecs[indices[i]], vecs[indices[bestNewIndex]]), closestDistSq[i] );
	}

		
		return centers[0..centerCount];
	}

	
	/**
	 * Builds the index
	 */
	public void buildIndex() 
	{	
		indices = new int[vecs.length];
		for (int i=0;i<vecs.length;++i) {
			indices[i] = i;
		}
		
		root = pool.allocate!(KMeansNodeSt);
		computeNodeStatistics(root, indices);
		computeClustering(root, indices, branching,0);
	}
	

	/**
	 * Computes the statistics of a node (mean, radius, variance).
	 * 
	 * Params:
	 *     node = the node to use 
	 *     indices = the indices of the points belonging to the node
	 */
	private void computeNodeStatistics(KMeansNode node, int[] indices) {
	
		float radius = 0;
		float variance = 0;
		float[] mean = allocate!(float[])(veclen);
		memoryCounter += veclen*float.sizeof;
		
		mean[] = 0;
		
		for (int i=0;i<indices.length;++i) {
			T[] vec = vecs[indices[i]];
			mean.add(vec);
			variance += squaredDist(vec);
		}
		for (int j=0;j<mean.length;++j) {
			mean[j] /= indices.length;
		}
		variance /= indices.length;
		variance -= squaredDist(mean);
		
		float tmp = 0;
		for (int i=0;i<indices.length;++i) {
			tmp = squaredDist(mean, vecs[indices[i]]);
			if (tmp>radius) {
				radius = tmp;
			}
		}
		
		node.variance = variance;
		node.radius = radius;
		node.pivot = mean;
	}
	

	/**
	 * The method responsible with actually doing the recursive hierarchical
	 * clustering
	 * 
	 * Params:
	 *     node = the node to cluster 
	 *     indices = indices of the points belonging to the current node
	 *     branching = the branching factor to use in the clustering
	 *     
	 * TODO: for 1-sized clusters don't store a cluster center (it's the same as the single cluster point)
	 */
	private void computeClustering(KMeansNode node, int[] indices, int branching, int level)
	{
		int n = indices.length;
		node.size = n;
		node.level = level;
		
		if (indices.length < branching) {
			node.indices = indices.sort;
            (cast(byte*)&node.childs)[0..node.childs.sizeof] = 0;
			return;
		}
		
		T[][] initial_centers;
		initial_centers = chooseCenters(branching, vecs, indices); 
		
		if (initial_centers.length<branching) {
		    node.indices = indices.sort;
            (cast(byte*)&node.childs)[0..node.childs.sizeof] = 0;
			return;
		}
		
 		double[][] dcenters = allocate!(double[][])(branching,veclen);
		
		mat_copy(dcenters,initial_centers);
		
	 	float[] radiuses = new float[branching];
		int[] count = new int[branching];
		
		// assign points to clusters
		int[] belongs_to = new int[n];
		for (int i=0;i<n;++i) {

			float sq_dist = squaredDist(vecs[indices[i]],dcenters[0]); 
			belongs_to[i] = 0;
			for (int j=1;j<branching;++j) {
				float new_sq_dist = squaredDist(vecs[indices[i]],dcenters[j]);
				if (sq_dist>new_sq_dist) {
					belongs_to[i] = j;
					sq_dist = new_sq_dist;
				}
			}
			count[belongs_to[i]]++;
		}
		
		bool converged = false;
		int iteration = 0;		
		while (!converged && iteration<max_iter) {
			converged = true;
			iteration++;
			
			// compute the new cluster centers
			for (int i=0;i<branching;++i) {
				dcenters[i][] = 0.0;
			}
			foreach (i,index; indices) {
				auto vec = vecs[index];
				auto center = dcenters[belongs_to[i]];
				for (int k=0;k<vec.length;++k) {
					center[k] += vec[k];
 				}
			}
			foreach (i,center;dcenters) {
				foreach(ref value;center) {
					value /= count[i];
				}
			}
						
			radiuses[] = 0;
			// reassign points to clusters
			for (int i=0;i<n;++i) {
				float sq_dist = squaredDist(vecs[indices[i]],dcenters[0]); 
				int new_centroid = 0;
				for (int j=1;j<branching;++j) {
					float new_sq_dist = squaredDist(vecs[indices[i]],dcenters[j]);
					if (sq_dist>new_sq_dist) {
						new_centroid = j;
						sq_dist = new_sq_dist;
					}
				}
				if (sq_dist>radiuses[new_centroid]) {
					radiuses[new_centroid] = sq_dist;
				}
				if (new_centroid != belongs_to[i]) {
					count[belongs_to[i]]--;
					count[new_centroid]++;
					belongs_to[i] = new_centroid;
					
					converged = false;
				}
			}
			
			for (int i=0;i<branching;++i) {
				// if one cluster converges to an empty cluster,
				// move an element into that cluster
				if (count[i]==0) {
					int j = (i+1)%branching;
					while (count[j]<=1) {
						j = (j+1)%branching;
					}					
					
					for (int k=0;k<n;++k) {
						if (belongs_to[k]==j) {
							belongs_to[k] = i;
							count[j]--;
							count[i]++;
							break;
						}
					}
					converged = false;
				}
			}

		}
	
 		float[][] centers = new float[][branching];
 		foreach (ref c;centers) {
 			c = allocate!(float[])(veclen);
 			memoryCounter += veclen*float.sizeof;
 		}	
//  		pool.allocate!(float[][])(branching,veclen);
 		mat_copy(centers,dcenters);
		free(dcenters);
	
		// compute kmeans clustering for each of the resulting clusters
		node.childs = pool.allocate!(KMeansNode[])(branching);
		int start = 0;
		int end = start;
		for (int c=0;c<branching;++c) {
			int s = count[c];
			
			float variance = 0;
			float mean_radius =0;
			for (int i=0;i<n;++i) {
				if (belongs_to[i]==c) {
					float d = squaredDist(vecs[indices[i]]);
					variance += d;
					mean_radius += sqrt(d);
					swap(indices[i],indices[end]);
					swap(belongs_to[i],belongs_to[end]);
					end++;
				}
			}
			variance /= s;
			mean_radius /= s;
			variance -= squaredDist(centers[c]);
			
			node.childs[c] = pool.allocate!(KMeansNodeSt);
			node.childs[c].radius = radiuses[c];
			node.childs[c].pivot = centers[c];
			node.childs[c].variance = variance;
			node.childs[c].mean_radius = mean_radius;
			computeClustering(node.childs[c],indices[start..end],branching, level+1);
			start=end;
		}
		
		delete centers;
		delete radiuses;
		delete count;
		delete belongs_to;
	}
	
	 public bool first_time = true;
	/** 
	 * Find set of nearest neighbors to vec. Their indices are stored inside
	 * the result object. 
	 * 
	 * Params:
	 *     result = the result object in which the indices of the nearest-neighbors are stored 
	 *     vec = the vector for which to search the nearest neighbors
	 *     maxCheck = the maximum number of restarts (in a best-bin-first manner)
	 */
	public void findNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
		if (first_time) {
			logger.info(sprint("cb_index is: {}",cb_index));
			first_time = false;
		}
		
		
		if (maxCheck==-1) {
			findExactNN(root, result, vec);
		}
		else {
			heap.clear();			
			
			findNN(root, result, vec);
			
			int checks = 0;			
			BranchSt branch;
			while (heap.popMin(branch) && (++checks<maxCheck || !result.full)) {
				KMeansNode node = branch.node;			
				findNN(node, result, vec);
			}
			assert(result.full);
		}
		
	}
	
	
	/**
	 * Performs one descent in the hierarchical k-means tree. The branches not
	 * visited are stored in a priority queue.
	 */
	private void findNN(KMeansNode node, ResultSet result, float[] vec)
	{
		// Ignore those clusters that are too far away
		{
			float bsq = squaredDist(vec, node.pivot);
			float rsq = node.radius;
			float wsq = result.worstDist;
			
			float val = bsq-rsq-wsq;
			float val2 = val*val-4*rsq*wsq;
			
	 		//if (val>0) {
			if (val>0 && val2>0) {
				return;
			}
		}
	
		if (node.childs.length==0) {
			if (node.indices.length==0) {
				throw new FLANNException("Reached empty cluster. This shouldn't happen.\n");
			}
			
			for (int i=0;i<node.indices.length;++i) {		
				result.addPoint(vecs[node.indices[i]], node.indices[i]);
			}
		} 
		else {
			int closest_center = exploreNodeBranches(node, vec);			
			findNN(node.childs[closest_center],result,vec);
		}		
	}
	
	/**
	 * Helper function that computes the nearest childs of a node to a given query point.
	 * Params:
	 *     node = the node
	 *     q = the query point
	 *     distances = array with the distances to each child node.
	 * Returns:
	 */	
	private int exploreNodeBranches(KMeansNode node, float[] q)
	{
		int nc = node.childs.length;
//		static float distances[];
//		if (distances is null || distances.length!=nc) distances = new float[nc];
//		scope float distances[] =  new float[nc];
		
		int best_index = 0;
		domain_distances[best_index] = squaredDist(q,node.childs[best_index].pivot); 
		for (int i=1;i<nc;++i) {
			domain_distances[i] = squaredDist(q,node.childs[i].pivot);
			if (domain_distances[i]<domain_distances[best_index]) {
				best_index = i;
			}
		}
		
		float[] best_center = node.childs[best_index].pivot;
		for (int i=0;i<nc;++i) {
			if (i != best_index) {
				domain_distances[i] -= cb_index*node.childs[i].variance;

//				float dist_to_border = getDistanceToBorder(node.childs[i].pivot,best_center,q);
//				if (domain_distances[i]<dist_to_border) {
//					domain_distances[i] = dist_to_border;
//				}
				heap.insert(BranchSt(node.childs[i],domain_distances[i]));
			}
		}
		
		return best_index;
	}

	
	/**
	 * Function the performs exact nearest neighbor search by traversing the entire tree. 
	 */
	private void findExactNN(KMeansNode node, ResultSet result, float[] vec)
	{
		// Ignore those clusters that are too far away
		{
			float bsq = squaredDist(vec, node.pivot);
			float rsq = node.radius;
			float wsq = result.worstDist;
			
			float val = bsq-rsq-wsq;
			float val2 = val*val-4*rsq*wsq;
			
	//  		if (val>0) {
			if (val>0 && val2>0) {
				return;
			}
		}
	
	
		if (node.childs.length==0) {
			if (node.indices.length==0) {
				throw new FLANNException("Reached empty cluster. This shouldn't happen.\n");
			}
			
			for (int i=0;i<node.indices.length;++i) {
				result.addPoint(vecs[node.indices[i]], node.indices[i]);
			}	
		} 
		else {
			int nc = node.childs.length;
			int[] sort_indices = new int[nc];
			
			getCenterOrdering(node, vec, sort_indices);

			for (int i=0; i<nc; ++i) {
 				findExactNN(node.childs[sort_indices[i]],result,vec);
			}
			delete sort_indices;
		}		
	}


	/**
	 * Helper function. 
	 * 
	 * I computes the order in which to traverse the child nodes of a particular node.
	 */
	private void getCenterOrdering(KMeansNode node, float[] q, ref int[] sort_indices)
	{
		int nc = node.childs.length;
		
//		static float[] domain_distances;
//		if (domain_distances is null) {
//			domain_distances = new float[nc];
//		}
		
		for (int i=0;i<nc;++i) {
			float dist = squaredDist(q,node.childs[i].pivot);
			
			int j=0;
			while (domain_distances[j]<dist && j<i) j++;
			for (int k=i;k>j;--k) {
				domain_distances[k] = domain_distances[k-1];
				sort_indices[k] = sort_indices[k-1];
			}
			domain_distances[j] = dist;
			sort_indices[j] = i;
		}		
	}	
	
	/** 
	 * Method that computes the squared distance from the query point q
	 * from inside region with center c to the border between this 
	 * region and the region with center p 
	 */
	private float getDistanceToBorder(float[] p, float[] c, float[] q)
	{		
		float sum = 0;
		float sum2 = 0;
		
		for (int i=0;i<p.length; ++i) {
			float t = c[i]-p[i];
			sum += t*(q[i]-(c[i]+p[i])/2);
			sum2 += t*t;
		}
		
		return sum*sum/sum2;
	}
	
	
	/**
	 * Clustering function that takes a cut in the hierarchical k-means
	 * tree and return the clusters centers of that clustering. 
	 * Params:
	 *     numClusters = number of clusters to have in the clustering computed
	 * Returns: cluster centers
	 */
	public float[][] getClusterCenters(int numClusters) 
	{
		if (numClusters<1) {
			throw new FLANNException("Number of clusters must be at least 1");
		}		

		float variance;
		KMeansNode[] clusters = allocate!(KMeansNode[])(numClusters);
		scope(exit) free(clusters);

		int clusterCount = getMinVarianceClusters(root, clusters, variance);

		float[][] centers = new float[][clusterCount];
		
		logger.info(sprint("Mean cluster variance for {} top level clusters: {:e10}",clusterCount,variance));
		
 		for (int i=0;i<clusterCount;++i) {
			centers[i] = clusters[i].pivot;
		}
		
		return centers;
	}
	

	/**
	 * Helper function the descends in the hierarchical k-means tree by spliting those clusters that minimize
	 * the overall variance of the clustering. 
	 * Params:
	 *     root = root node
	 *     clusters = array with clusters centers (return value)
	 *     varianceValue = variance of the clustering (return value)
	 * Returns:
	 */
	private int getMinVarianceClusters(KMeansNode root, KMeansNode[] clusters, out float varianceValue)
	{
		int clusterCount = 1;
		clusters[0] = root;
		
		float meanVariance = root.variance*root.size;
		
		while (clusterCount<clusters.length) {
			float minVariance = float.max;
			int splitIndex = -1;
			
			for (int i=0;i<clusterCount;++i) {
				if (clusters[i].childs.length != 0) {
			
					float variance = meanVariance - clusters[i].variance*clusters[i].size;
					 
					for (int j=0;j<clusters[i].childs.length;++j) {
					 	variance += clusters[i].childs[j].variance*clusters[i].childs[j].size;
					}
					if (variance<minVariance) {
						minVariance = variance;
						splitIndex = i;
					}			
				}
			}
			
			if (splitIndex==-1) break;			
			if ( (clusters[splitIndex].childs.length+clusterCount-1) > clusters.length) break;
			
			meanVariance = minVariance;
			
			// split node
			KMeansNode toSplit = clusters[splitIndex];
			clusters[splitIndex] = toSplit.childs[0];
			for (int i=1;i<toSplit.childs.length;++i) {
				clusters[clusterCount++] = toSplit.childs[i];
			}
		}
		
		varianceValue = meanVariance/root.size;
		return clusterCount;
	}
}

mixin AlgorithmRegistry!(KMeansTree!(float),float);
mixin AlgorithmRegistry!(KMeansTree!(ubyte),ubyte);
