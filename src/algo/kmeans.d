/*
Project: nn
*/

module algo.kmeans;

import std.c.time;

import algo.nnindex;
import util.resultset;
import util.heap;
import util.utils;
import util.features;
import util.logger;
import util.random;


mixin AlgorithmRegistry!(KMeansTree);


alias BranchStruct!(KMeansCluster) BranchSt;
alias Heap!(BranchSt) BranchHeap;

static this() {
  Serializer.registerClass!(KMeansCluster)();
}


private string centersAlgorithm;



private class KMeansCluster
{
	private {
		Feature[] points;
	
		float[] pivot;
		float radius;
		float variance;
		
		KMeansCluster[] childs;
	}
	
	void describe(T)(T ar)
	{
		ar.describe(points);
		ar.describe(pivot);
		ar.describe(radius);
		
		ar.describe(childs);
	}
	
	
	public this()
	{
	}
	
	public this(Feature[] points)
	{
		this.points = points;
	}



	float[][] chooseCentersRandom(int k, Feature[] points)
	{
		DistinctRandom r = new DistinctRandom(points.length);
		
		// choose the initial cluster centers
		float[][] centers = new float[][k];
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
				
				centers[index] = points[rnd].data;
				
				for (int j=0;j<index;++j) {
					if (squaredDist(centers[index],centers[j])<1e-9) {
						duplicate = true;
					}
				}
			}
		}
		
		return centers[0..index];
	}

	float[][] chooseCentersGonzales(int k, Feature[] points)
	{
		int n = points.length;
		
		float[][] centers = new float[][k];
		
		int rand = cast(int) (drand48() * n);  
		assert(rand >=0 && rand < n);
		
		centers[0] = points[rand].data;
		
		int index;
		for (index=1; index<k; ++index) {
			
			int best_index = -1;
			float best_val = 0;
			for (int j=0;j<n;++j) {
				float dist = squaredDist(centers[0],points[j].data);
				for (int i=1;i<index;++i) {
					float tmp_dist = squaredDist(centers[i],points[j].data);
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
				centers[index] = points[best_index].data;
			} 
			else {
				break;
			}
		}
		return centers[0..index];
	}
	
	/** 
	Method that computes the k-means clustering 
	*/
	void computeClustering( int branching)
	{
		int n = points.length;
		int nc = branching;
		int flength = points[0].data.length;
			
		float[][] centers;
		if (centersAlgorithm=="gonzales") {
			centers = chooseCentersGonzales(nc,points);
		}
		else if (centersAlgorithm=="random") {
			centers = chooseCentersRandom(nc,points);		
		}
		else {
			throw new Exception("Unknown algorithms for choosing initial centers.");
		}

		if (centers.length<nc) {
			return;
		}
		
		float[] radiuses = new float[nc];
		int[] count = new int[nc];		
		
		// assign points to clusters
		int[] belongs_to = new int[n];
		for (int i=0;i<n;++i) {

			float sq_dist = squaredDist(points[i].data,centers[0]); 
			belongs_to[i] = 0;
			for (int j=1;j<nc;++j) {
				float new_sq_dist = squaredDist(points[i].data,centers[j]);
				if (sq_dist>new_sq_dist) {
					belongs_to[i] = j;
					sq_dist = new_sq_dist;
				}
			}
			count[belongs_to[i]]++;
		}

		bool converged = false;
		
		for (int i=0;i<nc;++i) {
			centers[i] = new float[](flength);
		}
		
		while (!converged) {
			
			converged = true;
			
			for (int i=0;i<nc;++i) {
				centers[i][] = 0.0;
				
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
				}
			}
			
	
			// compute the new clusters
			for (int i=0;i<n;++i) {
				for (int j=0;j<nc;++j) {
					if (belongs_to[i]==j) {
						for (int k=0;k<flength;++k) {
							centers[j][k]+=points[i].data[k];
						}
						break;	
					}
				}
			}
			
						
			for (int j=0;j<nc;++j) {
				for (int k=0;k<flength;++k) {
					centers[j][k] /= count[j];
				}
			}
			
			
			radiuses[] = 0;
			// reassign points to clusters
			for (int i=0;i<n;++i) {
				float sq_dist = squaredDist(points[i].data,centers[0]); 
				int new_centroid = 0;
				for (int j=1;j<nc;++j) {
					float new_sq_dist = squaredDist(points[i].data,centers[j]);
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
		//	writef("done\n");
		}
	
	
		// compute kmeans clustering for each of the resulting clusters
		childs = new KMeansCluster[nc];
		for (int c=0;c<nc;++c) {
			int s = count[c];
			Feature[] child_points = new Feature[s];
			int cnt_indices = 0;
			
			float variance = 0;
			for (int i=0;i<n;++i) {
				if (belongs_to[i]==c) {
					child_points[cnt_indices++] = points[i];
					variance += squaredDist(points[i].data);;
				}
			}
			variance /= s;
			variance -= squaredDist(centers[c]);
			
			//writefln("-------------------------------------------");
			
			childs[c] = new KMeansCluster(child_points);
			
/+			childs[c].computeStatistics();			
			assert (childs[c].radius == radiuses[c]);
			assert (childs[c].pivot == centers[c]);
			assert (childs[c].variance == variance);+/
			childs[c].radius = radiuses[c];
			childs[c].pivot = centers[c];
			childs[c].variance = variance;
			childs[c].computeClustering(branching);
		}
	}

	void computeRandomClustering(int branching)
	{
		
		int n = points.length;
		int nc = branching;
		int flength = points[0].data.length;
		
	
		float[][] centers;
		if (centersAlgorithm=="gonzales") {
			centers = chooseCentersGonzales(nc,points);
		}
		else if (centersAlgorithm=="random") {
			centers = chooseCentersRandom(nc,points);		
		}
		else {
			throw new Exception("Unknown algorithms for choosing initial centers.");
		}
		
		if (centers.length<nc) {
			return;
		}

		float[] radiuses = new float[nc];
		int[] count = new int[nc];
	
		// assign points to clusters
		int[] belongs_to = new int[n];
		for (int i=0;i<n;++i) {
			float sq_dist = squaredDist(points[i].data,centers[0]); 
			belongs_to[i] = 0;
			for (int j=1;j<nc;++j) {
				float new_sq_dist = squaredDist(points[i].data,centers[j]);
				if (sq_dist>new_sq_dist) {
					belongs_to[i] = j;
					sq_dist = new_sq_dist;
				}
			}
			count[belongs_to[i]]++;
		}
		
/+			
	//	int iterations = 0;
		while (!converged) {
		
//			writef("Iteration %d\n",iterations++);
		
			converged = true;
			
			for (int i=0;i<nc;++i) {
				centers[i][] = 0.0;
			}
			count[] = 0;
			
			
	
			// compute the new clusters
			for (int i=0;i<n;++i) {
				for (int j=0;j<nc;++j) {
					if (belongs_to[i]==j) {
						for (int k=0;k<flength;++k) {
							centers[j][k]+=points[i].data[k];
						}
						count[j]++;
					}
				}
			}
						
			for (int j=0;j<nc;++j) {
				for (int k=0;k<flength;++k) {
					if (count[j]==0) {
						throw new Exception("Degenerate cluster\n");
					}
					centers[j][k] /= count[j];
				}
			}
			
			
			radiuses[] = 0;
			// reassign points to clusters
			for (int i=0;i<n;++i) {
				float sq_dist = squaredDist(points[i].data,centers[0]); 
				int new_centroid = 0;
				for (int j=1;j<nc;++j) {
					float new_sq_dist = squaredDist(points[i].data,centers[j]);
					if (sq_dist>new_sq_dist) {
						new_centroid = j;
						sq_dist = new_sq_dist;
					}
				}
				if (sq_dist>radiuses[new_centroid]) {
					radiuses[new_centroid] = sq_dist;
				}
				if (new_centroid != belongs_to[i]) {
					belongs_to[i] = new_centroid;
					converged = false;
				}
			}
		//	writef("done\n");
		}
	
	+/
		// compute kmeans clustering for each of the resulting clusters
		childs = new KMeansCluster[nc];
		for (int c=0;c<nc;++c) {
			int s = count[c];
			Feature[] child_points = new Feature[s];
			int cnt_indices = 0;
			
			float variance = 0;
			for (int i=0;i<n;++i) {
				if (belongs_to[i]==c) {
					child_points[cnt_indices++] = points[i];
					variance += squaredDist(points[i].data);;
				}
			}
			variance /= s;
			variance -= squaredDist(centers[c]);
			
			//writefln("-------------------------------------------");
			
			childs[c] = new KMeansCluster(child_points);
			
/+			childs[c].computeStatistics();			
			assert (childs[c].radius == radiuses[c]);
			assert (childs[c].pivot == centers[c]);
			assert (childs[c].variance == variance);+/
			childs[c].radius = radiuses[c];
			childs[c].pivot = centers[c];
			childs[c].variance = variance;
			childs[c].computeClustering(branching);
		}
	}


	void computeStatistics() {
	
		float radius = 0;
		float variance = 0;
		float[] mean = points[0].data.dup;
		variance = squaredDist(points[0].data);
		for (int i=1;i<points.length;++i) {
			for (int j=0;j<mean.length;++j) {
				mean[j] += points[i].data[j];
			}			
			variance += squaredDist(points[i].data);
		}
		for (int j=0;j<mean.length;++j) {
			mean[j] /= points.length;
		}
		variance /= points.length;
		variance -= squaredDist(mean);
		
		float tmp = 0;
		for (int i=0;i<points.length;++i) {
			tmp = squaredDist(mean, points[i].data);
			if (tmp>radius) {
				radius = tmp;
			}
		}
		
		this.variance = variance;
		this.radius = radius;
		this.pivot = mean;
		
	}





	/**
	----------------------------------------------------------------------
		Approximate nearest neighbor search
	----------------------------------------------------------------------
	*/
	public void findNN(ResultSet result,float[] vec, ref BranchHeap heap, int checkID)
	{
		if (pivot!=null) {
			float bsq = squaredDist(vec, pivot);
			float rsq = radius;
			float wsq = result.worstDist;
			
			float val = bsq-rsq-wsq;
			float val2 = val*val-4*rsq*wsq;
			
	//  		if (val>0) {
			if (val>0 && val2>0) {
				return true;
			}
		}
	
	
		
		if (childs.length==0) {
			if (points.length==0) {
				throw new Exception("Reached empty cluster. This shouldn't happen.\n");
			}
			
			for (int i=0;i<points.length;++i) {
				
				if (points[i].checkID == checkID) {
					return;
				}
				points[i].checkID = checkID;
				
				result.addPoint(points[i].data, points[i].id);
			}	
		} 
		else {
			int nc = childs.length;
			float distances[] = new float[nc];
			int ci = getNearestCenter(vec, distances);
			
			for (int i=0;i<nc;++i) {
				if (i!=ci) {
 					heap.insert(BranchSt(childs[i],distances[i]));
//					heap.insert(BranchSt(childs[i], getDistanceToBorder(childs[i].pivot,childs[ci].pivot,vec)));
				}
			}
	
			childs[ci].findNN(result,vec, heap, checkID);
		}		
	}
	
	
	private int getNearestCenter(float[] q, ref float[] distances)
	{
		int nc = childs.length;
	
		int best_index = 0;
		distances[best_index] = squaredDist(q,childs[best_index].pivot);
		
		for (int i=1;i<nc;++i) {
			distances[i] = squaredDist(q,childs[i].pivot);
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
	public void findExactNN(ResultSet result,float[] vec)
	{
		if (pivot!=null) {
			float bsq = squaredDist(vec, pivot);
			float rsq = radius;
			float wsq = result.worstDist;
			
			float val = bsq-rsq-wsq;
			float val2 = val*val-4*rsq*wsq;
			
			
	//  		if (val>0) {
			if (val>0 && val2>0) {
				return true;
			}
		}
	
	
		if (childs.length==0) {
			if (points.length==0) {
				throw new Exception("Reached empty cluster. This shouldn't happen.\n");
			}
			
			for (int i=0;i<points.length;++i) {
				result.addPoint(points[i].data, points[i].id);
			}	
		} 
		else {
			int nc = childs.length;
			int[] sort_indices = new int[nc];	
/+			for (int i=0; i<nc; ++i) {
				sort_indices[i] = i;
			}+/
			getCenterOrdering(vec, sort_indices);

			for (int i=0; i<nc; ++i) {
 				childs[sort_indices[i]].findExactNN(result,vec);
// 				childs[i].findExactNN(result,vec);
			}
		}		
	}


	private void getCenterOrdering(float[] q, ref int[] sort_indices)
	{
		int nc = childs.length;
		float distances[] = new float[nc];
		
		for (int i=0;i<nc;++i) {
			float dist = squaredDist(q,childs[i].pivot);
			
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

}



class KMeansTree : NNIndex
{
	static const NAME = "kmeans";

	private int branching;
	private int numTrees_;
	private bool randomTree;
	
	private KMeansCluster root[];
	private float[][] vecs;
	private int flength;
	private BranchHeap heap;	
	private int checkID = -1;

	private this()
	{
		heap = new BranchHeap(512);
	}
	
	public this(Features inputData, Params params)
	{
		this.branching = params.branching;
		this.numTrees_ = params.numTrees;
		this.randomTree = params.random;
		
		centersAlgorithm = params.centersAlgorithm;
		
		this.vecs = inputData.vecs;
		this.flength = inputData.veclen;
		
		heap = new BranchHeap(inputData.count);

	}

	public int size() 
	{
		return vecs.length;
	}
	
	public int numTrees()
	{
		return numTrees_;
	}
	
	private static bool isPrime(int num)
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

	public void buildIndex() 
	{
		Feature[] points = new Feature[vecs.length];

		for (int i=0;i<points.length;++i) {
			points[i] = new Feature(i,vecs[i]);
		}
	
		this.root = new KMeansCluster[numTrees];
		
		int branchings[];
				
		// computing numTrees prime number branchings
		{
			int below = (numTrees-1)/2;
			int crt_branching = branching-1;
			int tries = 0;
/+			while (crt_branching>=2 && tries<below) {
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
		}
		
		Logger.log(Logger.INFO,"Using the following branching factors: ",branchings,"\n");
		
		foreach (index,value; branchings) {
			root[index] = new KMeansCluster(points);
			root[index].computeStatistics();
			
			if (randomTree) {
				root[index].computeRandomClustering(value);
			}
			else {
				root[index].computeClustering(value);
			}
		}
		
		
/+		float variance;
		getMinVarianceClusters(root[0], 30, variance);
		writef("Mean cluster variance for %d top level clusters: %f\n",30,variance);		+/
	}
	

	void findNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
		if (maxCheck==-1) {
			root[0].findExactNN(result, vec);
		}
		else {
			checkID -= 1;
			heap.init();			
			
			for (int i=0;i<numTrees;++i) {
				root[i].findNN(result, vec, heap, checkID);
			}
			
			int checks = 0;			
			BranchSt branch;
			while (checks++<maxCheck && heap.popMin(branch)) {
				KMeansCluster cluster = branch.node;			
				cluster.findNN(result,vec, heap, checkID);
			}
		}
	}
	
		
	float[][] getClusterPoints(KMeansCluster node)
	{
		float[][] points = new float[][10];
		int size = 0;
		getClusterPoints_Helper(node,points,size);
		
		return points[0..size];
	}
	
	void getClusterPoints_Helper(KMeansCluster node, inout float[][] points, inout int size) 
	{
		if (node.childs.length == 0) {
			while (size>=points.length-node.points.length) {
				points.length = points.length*2;
			}
			
			for (int i=0;i<node.points.length;++i) {
				points[size++] = node.points[i].data;
			}
		}
		else {
			for (int i=0;i<node.childs.length;++i) {
				getClusterPoints_Helper(node.childs[i],points,size);
			}
		}
	}
	
	float[][] getClusterCenters(int numClusters) 
	{
		float variance;
		KMeansCluster[] clusters = getMinVarianceClusters(root[0], numClusters, variance);

		float[][] centers = new float[][clusters.length];
		
		Logger.log(Logger.INFO,"Mean cluster variance for %d top level clusters: %f\n",clusters.length,variance);
		
 		foreach (index, cluster; clusters) {
			centers[index] = cluster.pivot;
		}
		
		return centers;
	}
	
	public float meanClusterVariance2(int numClusters)
	{
		Queue!(KMeansCluster) q = new Queue!(KMeansCluster)(numClusters);
		
		q.push(root[0]);

		while(!q.full) {
			KMeansCluster t;
			q.pop(t);
			if (t.childs.length==0) {
				q.push(t);
			}
			else {
				for (int i=0;i<t.childs.length;++i) {
					q.push(t.childs[i]);
				}
			}
		}
			
		float variances[] = new float[q.size];
		int clusterSize[] = new int[q.size];
		
		for (int i=0;i<q.size;++i) {
//			float[][] clusterPoints = getClusterPoints(q[i]);
// 			variances[i] = computeVariance(clusterPoints);
			variances[i] = q[i].variance;
// 			clusterSize[i] = clusterPoints.length;
 			clusterSize[i] = q[i].points.length;
		}
		
		float meanVariance = 0;
		int sum = 0;
		for (int i=0;i<variances.length;++i) {
			meanVariance += variances[i]*clusterSize[i];
			sum += clusterSize[i];
		}
		meanVariance/=sum;
		
	/+	
		for (int i=0;i<clusterSize.length;++i) {
			writef("Cluster %d size: %d\n",i, clusterSize[i]);
		}
	+/
		
		return meanVariance;		
	}

	public KMeansCluster[] getMinVarianceClusters(KMeansCluster root, int numClusters, out float varianceValue)
	{
		KMeansCluster clusters[] = new KMeansCluster[10];
		
		int clusterCount = 1;
		clusters[0] = root;
		 
		float meanVariance = root.variance*root.points.length;
		 
		while (clusterCount<numClusters) {
			
			float minVariance = float.max;
			int splitIndex = -1;
			
			for (int i=0;i<clusterCount;++i) {
				if (clusters[i].childs.length != 0) {
			
					float variance = meanVariance - clusters[i].variance*clusters[i].points.length;
					 
					for (int j=0;j<clusters[i].childs.length;++j) {
					 	variance += clusters[i].childs[j].variance*clusters[i].childs[j].points.length;
					}
					if (variance<minVariance) {
						minVariance = variance;
						splitIndex = i;
					}			
				}
			}
			
			if (splitIndex==-1) break;
			
			meanVariance = minVariance;
			
			
			while (clusterCount+clusters[splitIndex].childs.length>=clusters.length) {
				// increase vector if needed
				clusters.length = clusters.length*2;
			}
			
			
			// split node
			KMeansCluster toSplit = clusters[splitIndex];
			clusters[splitIndex] = toSplit.childs[0];
			
			for (int i=1;i<toSplit.childs.length;++i) {
				clusters[clusterCount++] = toSplit.childs[i];
			}
		}
		
/+ 		for (int i=0;i<clusterCount;++i) {
 			writef("Cluster %d size: %d\n",i,clusters[i].points.length);
 		}+/
		
		
		varianceValue = meanVariance/root.points.length;
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
