/*
Project: aggnn
*/

import std.stdio;


import algo.nnindex;
import util.resultset;
import util.heap;
import util.utils;
import util.features;


void print_vec(float[] v)
{
	for (int i=0;i<v.length;++i) {
		printf("%.10f ",v[i]);
	}
}


mixin AlgorithmRegistry!(KMeansTree);


struct BranchSt {
	KMeansCluster node;           /* Tree node at which search resumes */
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
	
	static BranchSt opCall(KMeansCluster aNode, float dist) 
	{
		BranchSt s;
		s.node = aNode;
		s.mindistsq = dist;
		
		return s;
	}
	
}; 


alias Heap!(BranchSt) BranchHeap;

private class KMeansCluster
{
	private {
		KMeansTree clustering;
		int[] indices;
		int level;
	
		float[] centers[];
		KMeansCluster childs[];
	}

	public this(int[] indices, int level, KMeansTree clustering)
	{
		this.indices = indices;
		this.level = level;
		this.clustering = clustering;
	}

	/** 
	Method that computes the k-means clustering 
	*/
	void computeClustering()
	{
		int n = indices.length;
		int nc = clustering.branching;
	
		if (n<nc) {
			return;
		}
	
		float[][] vecs = clustering.vecs;
		int flength = clustering.flength;
	
	
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
		centers = new float[][nc];
		for (int i=0;i<nc;++i) {
			centers[i] = vecs[indices[cind[i]]];
		}
	
		// assign points to clusters
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
		}
	
		bool converged = false;
		//float[] centroids[] = new float[][nc];
		
		for (int i=0;i<nc;++i) {
			centers[i] = new float[flength];
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
							centers[j][k]+=vecs[indices[i]][k];
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
			//writef("%d %d\n",n,nc);
			for (int i=0;i<n;++i) {
/+				if (i%100==0) {
					writef("i=%d\n",i);
				}+/
				float sq_dist = squaredDist(vecs[indices[i]],centers[0]); 
				int new_centroid = 0;
				for (int j=1;j<nc;++j) {
					float new_sq_dist = squaredDist(vecs[indices[i]],centers[j]);
					if (sq_dist>new_sq_dist) {
						new_centroid = j;
						sq_dist = new_sq_dist;
					}
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
			int[] child_indices = new int[s];
			int cnt_indices = 0;
			for (int i=0;i<n;++i) {
				if (belongs_to[i]==c) {
					child_indices[cnt_indices++] = indices[i];
				}
	
			}
			childs[c] = new KMeansCluster(child_indices,level+1,clustering);
			childs[c].computeClustering();
		}
	}

	/**
	Method that searches for the nearest-neighbot of a 
	query point q
	*/
	public void findNN(ResultSet result,float[] vec, ref BranchHeap heap, int maxCheck)
	{
		static int count = 0;
	
		float[][] vecs = clustering.vecs;
		

		
		if (childs.length==0) {
			if (indices.length==0) {
				throw new Exception("Reached empty cluster. This shouldn't happen.\n");
			}
			
			for (int i=0;i<indices.length;++i) {
				result.addPoint(vecs[indices[i]], indices[i]);
			}	
		} 
		else {
			int nc = childs.length;
			int ci = getNearestCenter(vec);
			float[] c = centers[ci];
			
			
			if (maxCheck>0) { 
				for (int i=0;i<nc;++i) {
					if (i!=ci) {
						float dist = squaredDist(vec,centers[i]);
						
/+						if (count<30) {
							printf("Distance to cluster to insert: %f\n",dist);
//							print_vec(centers[i]);
		//					printf("\n");
	//						print_vec(vec);
						}+/
						heap.insert(BranchSt(childs[i],dist));
						
					}
				}
			}
	
			childs[ci].findNN(result,vec, heap, maxCheck);
		}		
	}

	/** Method the computes the nearest cluster center to 
	the query point q */
	private int getNearestCenter(float[] q)
	{
		int nc = childs.length;
	
		int best_index = 0;
		float dist = squaredDist(q,centers[best_index]);
	
		for (int i=1;i<nc;++i) {
			float tmp = squaredDist(q,centers[i]);
			if (tmp<dist) {
				best_index = i;
				dist = tmp;
			}
		}
		
		return best_index;
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
	private KMeansCluster root;
	private float[][] vecs;
	private int flength;
	private BranchHeap heap;	


	private this()
	{
	}
	
	public this(Features inputData, Params params)
	{
		this.branching = params.branching;
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
		return 1;
	}

	public void buildIndex() 
	{
		int[] indices = new int[vecs.length];
	
		for (int i=0;i<indices.length;++i) {
			indices[i] = i;
		}
	
		root = new KMeansCluster(indices,1, this);
		root.computeClustering();
		
		//writef("Mean cluster variance for %d top level clusters: %f\n",30,meanClusterVariance(30));		
		
		//testClustering(root);
	}
	
	void testClustering(KMeansCluster node)
	{
		if (node.childs.length==0) {
			for (int i=0;i<node.indices.length;++i) {
				fprintf(stderr,"%d\n",node.indices[i]);
			}
		}
		else {
			for (int i=0;i<node.childs.length;++i) {
				testClustering(node.childs[i]);
			}
		}
	}

	void findNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
		static int count = 0;
		heap.init();
		
		int checks = 0;
		root.findNN(result, vec, heap, maxCheck);
		
		BranchSt branch;
		while (checks++<maxCheck && heap.popMin(branch)) {
			KMeansCluster cluster = branch.node;			
// 			cluster.findNN(result,vec, heap, maxCheckf);
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
			while (size>=points.length-node.indices.length) {
				points.length = points.length*2;
			}
			
			for (int i=0;i<node.indices.length;++i) {
				points[size++] = vecs[node.indices[i]];
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
		
		q.push(root);

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
	}


}
