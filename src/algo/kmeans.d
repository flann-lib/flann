/*
Project: aggnn
*/

module algo.kmeans;

import std.stdio;


import algo.nnindex;
import util.resultset;
import util.heap;
import util.utils;
import util.features;
import std.c.time;


void print_vec(float[] v)
{
	for (int i=0;i<v.length;++i) {
		printf("%.10f ",v[i]);
	}
}


mixin AlgorithmRegistry!(KMeansTree);


struct BranchStruct(T) {
	T node;           /* Tree node at which search resumes */
	float mindistsq;     /* Minimum distance to query for all nodes below. */
	
	int opCmp(BranchStruct!(T) rhs) 
	{ 
		if (mindistsq < rhs.mindistsq) {
			return -1;
		} if (mindistsq > rhs.mindistsq) {
			return 1;
		} else {
			return 0;
		}
	}
	
	static BranchStruct!(T) opCall(T aNode, float dist) 
	{
		BranchSt s;
		s.node = aNode;
		s.mindistsq = dist;
		
		return s;
	}
	
}; 

alias BranchStruct!(KMeansCluster) BranchSt;

alias Heap!(BranchSt) BranchHeap;

static this() {
//	Serializer.registerClass!(KMeansCluster)();
}

private class KMeansCluster
{
	private {
		Feature[] points;
	
		float[] pivot;
		float radius;
		
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

	/** 
	Method that computes the k-means clustering 
	*/
	void computeClustering(int branching)
	{
		int n = points.length;
		int nc = branching;
		int flength = points[0].data.length;
		
		
		if (n<nc) {
			return;
		}
	
		int cind[] = new int[nc];
		
		for (int i=0;i<nc;++i) {
			cind[i] = i;
		}
		
		for (int i=0;i<nc;++i) {
			int rand = cast(int) (drand48() * nc);  
			assert(rand >=0 && rand < nc);
			swap(cind[i], cind[rand]);
		}
		
		// choose the initial cluster centers
		float[][] centers = new float[][nc];
		float[] radiuses = new float[nc];
		radiuses[] = 0;
		for (int i=0;i<nc;++i) {
			centers[i] = points[cind[i]].data;
		}
	
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
		}
	
		bool converged = false;
		//float[] centroids[] = new float[][nc];
		
		for (int i=0;i<nc;++i) {
// 			centers[i] = new Feature();
			centers[i] = new float[](flength);
		}
		
		int[] count = new int[nc];
			
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
	
	
		// compute kmeans clustering for each of the resulting clusters
		childs = new KMeansCluster[nc];
		for (int c=0;c<nc;++c) {
			int s = count[c];
			Feature[] child_points = new Feature[s];
			int cnt_indices = 0;
			for (int i=0;i<n;++i) {
				if (belongs_to[i]==c) {
					child_points[cnt_indices] = points[i];
					cnt_indices++;
				}
			}
			childs[c] = new KMeansCluster(child_points);
			childs[c].radius = radiuses[c];
			childs[c].pivot = centers[c];
			childs[c].computeClustering(branching);
		}
	}

	/**
	Method that searches for the nearest-neighbot of a 
	query point q
	*/
	public void findNN(ResultSet result,float[] vec, ref BranchHeap heap)
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
			float distances[] = new float[nc];
			int ci = getNearestCenter(vec, distances);
			
			for (int i=0;i<nc;++i) {
				if (i!=ci) {
					heap.insert(BranchSt(childs[i],distances[i]));
				}
			}
	
			childs[ci].findNN(result,vec, heap);
		}		
	}
	
	/** Method the computes the nearest cluster center to 
	the query point q */
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


	/** Method the computes the nearest cluster center to 
	the query point q */
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
	
	private KMeansCluster root[];
	private float[][] vecs;
	private int flength;
	private BranchHeap heap;	


	private this()
	{
		heap = new BranchHeap(512);
	}
	
	public this(Features inputData, Params params)
	{
		this.branching = params.branching;
		this.numTrees_ = params.numTrees;
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

	public void buildIndex() 
	{
		Feature[] points = new Feature[vecs.length];

		for (int i=0;i<points.length;++i) {
			points[i] = new Feature(i,vecs[i]);
		}
	
	
		this.root = new KMeansCluster[numTrees_];
		
		root[0] = new KMeansCluster(points);
		root[0].computeClustering(branching);
		
		//writef("Mean cluster variance for %d top level clusters: %f\n",30,meanClusterVariance(30));		
	}
	

	void findNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
		if (maxCheck==-1) {
			root[0].findExactNN(result, vec);
		}
		else {
			heap.init();			
			
			root[0].findNN(result, vec, heap);
			
			int checks = 0;			
			BranchSt branch;
			while (checks++<maxCheck && heap.popMin(branch)) {
				KMeansCluster cluster = branch.node;			
				cluster.findNN(result,vec, heap);
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
	
	
	public float meanClusterVariance(int numClusters)
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
		
	/+	
		for (int i=0;i<clusterSize.length;++i) {
			writef("Cluster %d size: %d\n",i, clusterSize[i]);
		}
	+/
		
		return meanVariance;		
	}


	void describe(T)(T ar)
	{
		ar.describe(branching);
		ar.describe(flength);
		ar.describe(vecs);
		//ar.describe(root);
	}


}
