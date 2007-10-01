/*
Project: nn
*/

module algo.kmeans;

import std.c.time;
import std.stdio;
import std.boxer;

import algo.nnindex;
import util.resultset;
import util.heap;
import util.utils;
import dataset.features;
import util.logger;
import util.random;
import util.allocator;
import util.registry;	
import util.timer;


class KMeansTree(T) : NNIndex
{
	//mixin class_allocator;
	
	static const NAME = "kmeans";

	alias BranchStruct!(KMeansNode) BranchSt;
	alias Heap!(BranchSt) BranchHeap;


	private int branching;
	private int numTrees_;
	private uint max_iter;
	private string centersAlgorithm;
	
	private StartStopTimer timer;

	private T[][] vecs;
	private int flength;
	private BranchHeap heap;	
	private int checkID = -1;
	
	
	
	struct KMeansNodeSt	{	
		float[] pivot;
		float radius;
		float variance;
		int size;
		
		KMeansNode[] childs;
		int[] indices;
	}
	alias KMeansNodeSt* KMeansNode;
	

	private KMeansNode root[];
	private int[] indices;
	
	
	alias T[][] delegate(int k, T[][] vecs, int[] indices) centersAlgDelegate;
	centersAlgDelegate[string] centerAlgs;
	

	private this()
	{
		heap = new BranchHeap(512);
		
		initCentersAlgorithms();
		
		timer = new StartStopTimer();
	}
	
	public this(Features!(T) inputData, Params params)
	{
		this.branching = unbox!(uint)(params["branching"]);
		this.numTrees_ = unbox!(uint)(params["trees"]);
		this.max_iter = unbox!(uint)(params["max-iterations"]);
		centersAlgorithm = unbox!(string)(params["centers-algorithm"]);
		
		this.vecs = inputData.vecs;
		this.flength = inputData.veclen;
		
		heap = new BranchHeap(inputData.count);
		
		initCentersAlgorithms();

		timer = new StartStopTimer();
	}
	

	private void initCentersAlgorithms()
	{
		centerAlgs["random"] = &chooseCentersRandom;
		centerAlgs["gonzales"] = &chooseCentersGonzales;
	}



	public int size() 
	{
		return vecs.length;
	}
	
	public int numTrees()
	{
		return numTrees_;
	}
	

	private int[] getBranchingFactors()	
	{
		bool isPrime(int num)
		{
			if (num<2) {
				return false;
			}
			else if (num==2) {
				return true;
			} else {
				if (num%2==0) {
					return false;
				}
				for (int i=3;i*i<=num;i+=2) {
					if (num%i==0) {
						return false;
					}
				}
			}
			return true;
		}

		int[] branchings;// = new int[numTrees];
		
		int below = (numTrees-1)/2;
		int crt_branching = branching-1;
		int tries = 0;
/+		while (crt_branching>=2 && tries<below) {
			if (isPrime(crt_branching)) {
				branchings ~= crt_branching;
				tries++;
			}
			crt_branching--;
		}+/
		branchings ~= branching;
		int above = numTrees-1-tries;
		crt_branching = branching+1;
		tries = 0;
		while (tries<above) {
			if (isPrime(crt_branching)) {
				branchings ~= crt_branching;
				tries++;
			}
			crt_branching++;
		}
		
		return branchings;
	}


	public void buildIndex() 
	{	
	
		int branchings[] = getBranchingFactors();
		Logger.log(Logger.INFO,"Using the following branching factors: ",branchings,"\n");
		
		root = allocate!(KMeansNode[])(numTrees);
		indices = allocate!(int[])(vecs.length);
		for (int i=0;i<vecs.length;++i) {
			indices[i] = i;
		}
		
		foreach (index,branchingValue; branchings) {
			root[index] = allocate!(KMeansNodeSt)();
			computeNodeStatistics(root[index], indices);
			computeClustering(root[index], indices, branchingValue);
		}		
//		Logger.log(Logger.INFO, "Time spend in allocating points: %.2f\n",timer.value);
	}
	
	
	private void writeIndex(string file) {
		FILE* f = fOpen(file,"w","Cannot open " ~ file);
		
		void writeIndex_helper(KMeansNode node) {
			if (node.childs.length==0) {
				node.indices.sort;
				foreach(v;node.indices) fwritefln(f,v);
				fwritefln(f);
			}
			else {
				foreach(v;node.childs) writeIndex_helper(v);
			}
		}
		
		writeIndex_helper(root[0]);
		fclose(f);	
	}
	
	
	void computeNodeStatistics(KMeansNode node, int[] indices) {
	
		float radius = 0;
		float variance = 0;
		float[] mean = allocate!(float[])(vecs[0].length);
		for (int i=0;i<indices.length;++i) {
			for (int j=0;j<mean.length;++j) {
				mean[j] += vecs[indices[i]][j];
			}			
			variance += squaredDist(vecs[indices[i]]);
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
	
	
	
	private void computeClustering(KMeansNode node, int[] indices, int branching)
	{
		int n = indices.length;
		int nc = branching;
		
		node.size = indices.length;
		
//		Logger.log(Logger.INFO,"\rStarting clustering, size: %d                 ",node.size);		
				
		T[][] initial_centers;
		if (centersAlgorithm in centerAlgs) {
			initial_centers = centerAlgs[centersAlgorithm](nc,vecs, indices); 
		}
		else {
			throw new Exception("Unknown algorithm for choosing initial centers.");
		}
		
		
		if (initial_centers.length<nc) {
			node.indices = indices.sort;
			return;
		}
		
//		float[][] centers = allocate_mat!(float[][])(nc,flength);		
		float[][] centers = new float[][](nc,flength);		
		mat_copy(centers,initial_centers);
		
// 	 	float[] radiuses = allocate!(float[])(nc);		
	 	float[] radiuses = new float[nc];		
//		int[] count = allocate!(int[])(nc);		
		int[] count = new int[nc];
		
		// assign points to clusters
//		int[] belongs_to = allocate!(int[])(n);
		int[] belongs_to = new int[n];
		for (int i=0;i<n;++i) {

			float sq_dist = squaredDist(vecs[indices[i]],centers[0]); 
			belongs_to[i] = 0;
			for (int j=1;j<nc;++j) {
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
//			Logger.log(Logger.INFO,"\rIteration %d",iteration);		

			
			for (int i=0;i<nc;++i) {
				centers[i][] = 0.0;				
			}
			
		
			// compute the new clusters
			foreach (i,index; indices) {
 				addTo(centers[belongs_to[i]],vecs[index]);
/+				auto vecs_i = vecs[index]; 
				foreach (k, inout value; centers[belongs_to[i]]) 
				 	value += vecs_i[k];+/
			}
						
			foreach (j,center;centers) {
				foreach(inout value;center) {
					value /= count[j];
				}
			}
			
			
			radiuses[] = 0;
			// reassign points to clusters
			for (int i=0;i<n;++i) {
				float sq_dist = squaredDist(vecs[indices[i]],centers[0]); 
				int new_centroid = 0;
				for (int j=1;j<nc;++j) {
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
					count[belongs_to[i]]--;
					count[new_centroid]++;
					belongs_to[i] = new_centroid;
					
					converged = false;
				}
			}
			
			for (int i=0;i<nc;++i) {
				// if one cluster converges to an empty cluster,
				// move an element into that cluster
				if (count[i]==0) {
					int j = (i+1)%nc;
					while (count[j]<=1) {
						j = (j+1)%nc;
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
		node.childs = allocate!(KMeansNode[])(nc);
		int start = 0;
		int end = start;
		for (int c=0;c<nc;++c) {
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
			
			node.childs[c] = allocate!(KMeansNodeSt)();
			node.childs[c].radius = radiuses[c];
			node.childs[c].pivot = centers[c];
			node.childs[c].variance = variance;
			computeClustering(node.childs[c],indices[start..end],branching);
			start=end;
		}
		
		delete radiuses;
		delete count;
		delete belongs_to;
		delete centers;
	}
	
	
	
	private T[][] chooseCentersRandom(int k, T[][] vecs, int[] indices)
	{
		DistinctRandom r = new DistinctRandom(indices.length);
		
		static T[][] centers;
		if (centers is null) centers = allocate!(T[][])(k);
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
					if (squaredDist(centers[index],centers[j])<1e-9) {
						duplicate = true;
					}
				}
			}
		}
		
		return centers[0..index];
	}

	private T[][] chooseCentersGonzales(int k, T[][] vecs, int[] indices)
	{
		int n = indices.length;
		
		static T[][] centers;
		if (centers is null) centers = allocate!(T[][])(k);
		
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
	
	
	void findNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
		if (maxCheck==-1) {
			findExactNN(root[0], result, vec);
		}
		else {
			checkID -= 1;
			heap.init();			
			
			for (int i=0;i<numTrees;++i) {
				findNN(root[i], result, vec);
			}
			
			int checks = 0;			
			BranchSt branch;
			while (checks++<maxCheck && heap.popMin(branch)) {
				KMeansNode node = branch.node;			
				findNN(node, result, vec);
			}
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
				
//  				if (points[i].checkID == checkID) {
// 					return;
// 				}
// 				points[i].checkID = checkID;
				result.addPoint(vecs[node.indices[i]], node.indices[i]);
			}	
		} 
		else {
			int nc = node.childs.length;
			static float distances[];
			if (distances is null) distances = allocate!(float[])(nc);
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
	public void findExactNN(KMeansNode node, ResultSet result, float[] vec)
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
			int[] sort_indices = allocate!(int[])(nc);	
			
			getCenterOrdering(node, vec, sort_indices);

			for (int i=0; i<nc; ++i) {
 				findExactNN(node.childs[sort_indices[i]],result,vec);
// 				childs[i].findExactNN(result,vec);
			}
		}		
	}


	private void getCenterOrdering(KMeansNode node, float[] q, ref int[] sort_indices)
	{
		int nc = node.childs.length;
		
		static float[] distances;
		if (distances is null) {
			distances = allocate!(float[])(nc);		
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
	
	
		
	
	private T[][] getClusterPoints(KMeansNode node)
	{
		void getClusterPoints_Helper(KMeansNode node, inout T[][] points, inout int size) 
		{
			if (node.childs.length == 0) {			
				for (int i=0;i<node.indices.length;++i) {
					points[size++] =  vecs[node.indices[i]];
				}
			}
			else {
				for (int i=0;i<node.childs.length;++i) {
					getClusterPoints_Helper(node.childs[i],points,size);
				}
			}
		}
	
	
		static T[][] points;
		if (points==null) {
			points = allocate!(T[][])(vecs.length);
		}
		int size = 0;
		getClusterPoints_Helper(node,points,size);
		
		return points[0..size];
	}
	

	float[][] getClusterCenters(int numClusters) 
	{
		float variance;
		KMeansNode[] clusters = getMinVarianceClusters(root[0], numClusters, variance);

		static float[][] centers;
		if (centers is null) centers = allocate!(float[][])(clusters.length);
		
		Logger.log(Logger.INFO,"Mean cluster variance for %d top level clusters: %f\n",clusters.length,variance);
		
 		foreach (index, cluster; clusters) {
			centers[index] = cluster.pivot;
		}
		
		return centers;
	}
	
	private KMeansNode[] getMinVarianceClusters(KMeansNode root, int numClusters, out float varianceValue)
	{
		static KMeansNode[] clusters;
		if (clusters==null) clusters = allocate!(KMeansNode[])(vecs.length);
		
		int clusterCount = 1;
		clusters[0] = root;
		 
		float meanVariance = root.variance*root.size;
		
		while (clusterCount<numClusters) {
			
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
			
			meanVariance = minVariance;
			
			// split node
			KMeansNode toSplit = clusters[splitIndex];
			clusters[splitIndex] = toSplit.childs[0];
			
			for (int i=1;i<toSplit.childs.length;++i) {
				clusters[clusterCount++] = toSplit.childs[i];
			}
		}
		
		varianceValue = meanVariance/root.size;
		return clusters[0..clusterCount];
	}



	void describe(T)(T ar)
	{
		ar.describe(branching);
		ar.describe(flength);
		ar.describe(vecs);
		//ar.describe(root);
	}

}

mixin AlgorithmRegistry!(KMeansTree!(float),float);
//mixin AlgorithmRegistry!(KMeansTree!(ubyte),ubyte);
