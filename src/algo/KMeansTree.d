/************************************************************************
 * Hierarchical KMeans approximate nearest neighbor search
 * 
 * This module finds the nearest-neighbors of vectors in high dimensional 
 * spaces using a search of a kmeans tree.
 * 
 * Authors: Marius Muja, mariusm@cs.ubc.ca
 * 
 * Version: 0.9
 * 
 * History:
 * 
 * License:
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

/**
 * Hierarchical kmeans index
 * 
 * Contains a tree constructed through a hierarchical kmeans clustering 
 * and other information for indexing a set of points for nearest-neighbor matching.
 */
class KMeansTree(T) : NNIndex
{
	
	static const NAME = "kmeans";

	alias BranchStruct!(KMeansNode) BranchSt;
	alias Heap!(BranchSt) BranchHeap;


	// index parameters
	public uint branching;
	private uint max_iter;
	
	private T[][] vecs;
	private int flength;
	private BranchHeap heap;	
	
	struct KMeansNodeSt	{
		float[] pivot;
		float radius;
		float variance;
		int size;
		
		KMeansNode[] childs;
		int[] indices;
	}
	alias KMeansNodeSt* KMeansNode;
	

	private KMeansNode root;
	private int[] indices;
	
	private	PooledAllocator pool;
		
	alias T[][] function(int k, T[][] vecs, int[] indices) centersAlgFunction;
	static centersAlgFunction[string] centerAlgs;
	static this() {
		centerAlgs["random"] = &chooseCentersRandom;
		centerAlgs["gonzales"] = &chooseCentersGonzales;		
	}
	
	private centersAlgFunction chooseCenters;
	
	
	
	
	
	
	public this(Dataset!(T) inputData, Params params)
	{
		pool = new PooledAllocator();
	
		// get algorithm parameters
		this.branching = params["branching"].get!(uint);		
		if (branching<2) {
			throw new Exception("Branching factor must be at least 2");
		}
		int iterations = params["max-iterations"].get!(int);
		if (iterations<0) {
			iterations = int.max;
		}
		this.max_iter = iterations;
		
		string centersAlgorithm = params["centers-algorithm"].get!(string);
		if (centersAlgorithm in centerAlgs) {
			chooseCenters = centerAlgs[centersAlgorithm];
		}
		else {
			throw new Exception("Unknown algorithm for choosing initial centers.");
		}
		
		this.vecs = inputData.vecs;
		this.flength = inputData.cols;
		
		heap = new BranchHeap(inputData.rows);	
	}
	
	
	public ~this()
	{
		debug {
			logger.info(sprint("KMeansTree used memory: {} KB", pool.usedMemory/1000));
			logger.info(sprint("KMeansTree wasted memory: {} KB", pool.wastedMemory/1000));
			logger.info(sprint("KMeansTree total memory: {} KB", pool.usedMemory/1000+pool.wastedMemory/1000));
		}
		delete pool;
	}


	public int size() 
	{
		return vecs.length;
	}
	
	public int veclen() 
	{
		return flength;
	}
	
	public int numTrees()
	{
		return 1;
	}
	
	public int usedMemory()
	{
		return  pool.usedMemory+pool.wastedMemory;
	}



	private static T[][] chooseCentersRandom(int k, T[][] vecs, int[] indices)
	{
		DistinctRandom r = new DistinctRandom(indices.length);
		
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

	private static T[][] chooseCentersGonzales(int k, T[][] vecs, int[] indices)
	{
		int n = indices.length;
		
		static T[][] centers;
		if (centers is null) centers = new T[][k];
		
		int rand = cast(int) (drand48() * n);  
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



	public void buildIndex() 
	{	
		indices = new int[vecs.length];
		for (int i=0;i<vecs.length;++i) {
			indices[i] = i;
		}
		
		root = pool.allocate!(KMeansNodeSt);
		computeNodeStatistics(root, indices);
		computeClustering(root, indices, branching);
	}
	

	private void computeNodeStatistics(KMeansNode node, int[] indices) {
	
		float radius = 0;
		float variance = 0;
		float[] mean = pool.allocate!(float[])(flength);
		
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
	
	
	// TODO: for 1-sized clusters don't store a cluster center (it's the same as the single cluster point)
	private void computeClustering(KMeansNode node, int[] indices, int branching)
	{
		int n = indices.length;
		node.size = n;
		
		if (indices.length < branching) {
			node.indices = indices.sort;
			node.childs.length = 0;
			return;
		}
		
		T[][] initial_centers;
		initial_centers = chooseCenters(branching, vecs, indices); 
		
		if (initial_centers.length<branching) {
			node.indices = indices.sort;
			node.childs.length = 0;
			return;
		}
		
 		float[][] centers = pool.allocate!(float[][])(branching,flength);
 		double[][] dcenters = pool.allocate!(double[][])(branching,flength);
		
		//float[][] centers = new float[][](nc,flength);
		mat_copy(centers,initial_centers);
		
	 	float[] radiuses = new float[branching];
		int[] count = new int[branching];
		
		// assign points to clusters
		int[] belongs_to = new int[n];
		for (int i=0;i<n;++i) {

			float sq_dist = squaredDist(vecs[indices[i]],centers[0]); 
			belongs_to[i] = 0;
			for (int j=1;j<branching;++j) {
				float new_sq_dist = squaredDist(vecs[indices[i]],centers[j]);
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
			
			mat_copy(centers,dcenters);
			
			radiuses[] = 0;
			// reassign points to clusters
			for (int i=0;i<n;++i) {
				float sq_dist = squaredDist(vecs[indices[i]],centers[0]); 
				int new_centroid = 0;
				for (int j=1;j<branching;++j) {
					float new_sq_dist = squaredDist(vecs[indices[i]],centers[j]);
					if (sq_dist>new_sq_dist) {
						new_centroid = j;
						sq_dist = new_sq_dist;
					}
				}
				if (sq_dist>radiuses[new_centroid]) {
					radiuses[new_centroid] = sq_dist;
				}
				if (new_centroid != belongs_to[i]) {
					//logger.warn(sprint("Moving center form {} to {} for point {}",new_centroid,belongs_to[i],indices[i]));
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
	
	
		// compute kmeans clustering for each of the resulting clusters
		node.childs = pool.allocate!(KMeansNode[])(branching);
		int start = 0;
		int end = start;
		for (int c=0;c<branching;++c) {
			int s = count[c];
			
			float variance = 0;
			for (int i=0;i<n;++i) {
				if (belongs_to[i]==c) {					
					variance += squaredDist(vecs[indices[i]]);
					swap(indices[i],indices[end]);
					swap(belongs_to[i],belongs_to[end]);
					end++;
				}
			}
			variance /= s;
			variance -= squaredDist(centers[c]);
			
			node.childs[c] = pool.allocate!(KMeansNodeSt);
			node.childs[c].radius = radiuses[c];
			node.childs[c].pivot = centers[c];
			node.childs[c].variance = variance;
			computeClustering(node.childs[c],indices[start..end],branching);
			start=end;
		}
		
		delete radiuses;
		delete count;
		delete belongs_to;		
	}
	
	
	
	
	
	void findNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
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
	----------------------------------------------------------------------
		Approximate nearest neighbor search
	----------------------------------------------------------------------
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
				throw new Exception("Reached empty cluster. This shouldn't happen.\n");
			}
			
			for (int i=0;i<node.indices.length;++i) {		
				result.addPoint(vecs[node.indices[i]], node.indices[i]);
			}	
		} 
		else {
			int nc = node.childs.length;
			static float distances[];
			if (distances is null || distances.length!=nc) distances = new float[nc];
			int ci = getNearestCenter(node, vec, distances);
			
			for (int i=0;i<nc;++i) {
				if (i!=ci) {
 					heap.insert(BranchSt(node.childs[i],distances[i]));
//					heap.insert(BranchSt(node.childs[i], getDistanceToBorder(node.childs[i].pivot,node.childs[ci].pivot,vec)));
				}
			}
			
			findNN(node.childs[ci],result,vec);
		}		
	}
	
	
	
	private int getNearestCenter(KMeansNode node, float[] q, ref float[] distances)
	{
		int nc = node.childs.length;
	
		int best_index = 0;
		distances[best_index] = squaredDist(q,node.childs[best_index].pivot);
		
		for (int i=1;i<nc;++i) {
			distances[i] = squaredDist(q,node.childs[i].pivot);
			if (distances[i]<distances[best_index]) {
				best_index = i;
			}
		}
		
		return best_index;
	}
	
	
	
	/**
	----------------------------------------------------------------------
		Exact nearest neighbor search
	----------------------------------------------------------------------
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
				throw new Exception("Reached empty cluster. This shouldn't happen.\n");
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
		}		
	}


	private void getCenterOrdering(KMeansNode node, float[] q, ref int[] sort_indices)
	{
		int nc = node.childs.length;
		
		static float[] distances;
		if (distances is null) {
			distances = new float[nc];
		}
		
		for (int i=0;i<nc;++i) {
			float dist = squaredDist(q,node.childs[i].pivot);
			
			int j=0;
			while (distances[j]<dist && j<i) j++;
			for (int k=i;k>j;--k) {
				distances[k] = distances[k-1];
				sort_indices[k] = sort_indices[k-1];
			}
			distances[j] = dist;
			sort_indices[j] = i;
		}		
	}	
	
	/** Method that computes the distance from the query point q
		from inside region with center c to the border between this 
		region and the region with center p */
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
	
	
	public float[][] getClusterCenters(int numClusters) 
	{
		if (numClusters<1) {
			throw new Exception("Number of clusters must be at least 1");
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
