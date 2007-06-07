
/************************************************************************
Project: aggnn

Module: agglomerativetree.d (class that constructs an agglomerative tree
			using the reciprocal-nearest-neighbor algorithm )
Author: Marius Muja (2007)

*************************************************************************/

import std.stdio;

import util;
import heap;
import kdtree;
import resultset;
import features;
import nnindex;

//import debuger;
version (GDebug){
	import gpdebuger;
}



class AgglomerativeExTree : NNIndex {

	// tree node data structure
	struct NodeSt {
		int ind;
		
		float[] pivot; // center of this node
		float variance; // the variance of the points in the node
		int size;  // number of points in the node. Should be child1.size + child2.size
		float radius;
		
		int orig_id;
		float[][] points;
		
		TreeNode child1;
		TreeNode child2;	
	};
	alias NodeSt* TreeNode;
	
		
	
	struct BranchStruct {
		TreeNode node;        		/* Tree node at which search resumes */
		float mindistsq;     		/* Minimum distance to query. */
		
		int opCmp(BranchStruct rhs) 
		{ 
			if (mindistsq < rhs.mindistsq) {
				return -1;
			} if (mindistsq > rhs.mindistsq) {
				return 1;
			} else {
				return 0;
			}
		}
		
		static BranchStruct opCall(TreeNode aNode, float dist) 
		{
			BranchStruct s;
			s.node = aNode;
			s.mindistsq = dist;
			
			return s;
		}
		
	}; 


	const int NUM_KDTREES = 4;
	const int KD_MAXCHECK = 128;
	const float SIM_THRESHOLD = 5e-6;;

	//KDTree kdtree;
	
	TreeNode[] chain; // the chain array used by the agglomerative algorithm
	float[] sim;	// the sim array used by the agglomerative algorithm
	
	TreeNode[] nodes;  // vector of nodes to agglomerate
	int pcount; 		// number of nodes remaining to agglomerate (should be equal to kdtree.vcount)
	int veclen;
	
	TreeNode[] clusters;

	int[] rmap; 	// reverse mapping from kd_indices to indices in nodes vector
	
	//Pool pool;		// pool for memory allocation
	
	Heap!(BranchStruct) heap;


	public this(Features inputData)
	{
//		kdtree = new KDTree(inputData.vecs,inputData.veclen, NUM_KDTREES);
		
//		pool = kdtree.pool;
		
		int vcount = inputData.count;
		
		this.chain = new TreeNode[vcount];
		this.sim = new float[vcount];
		
		version (GDebug){
			GPDebuger.sendCommand("hold on");
		}
		
		this.nodes = new TreeNode[vcount];
		this.rmap = new int[vcount];
		for (int i=0;i<vcount;++i) {
			nodes[i] = new NodeSt();
			nodes[i].ind = i;
			nodes[i].pivot = inputData.vecs[i];
			nodes[i].variance = 0.0;
			nodes[i].radius = 0.0;
			nodes[i].child1 = nodes[i].child2 = null;
			nodes[i].size = 1;
			nodes[i].orig_id = i;
			
			nodes[i].points = new float[][1];
			nodes[i].points[0] = nodes[i].pivot;
			
			rmap[i] = i;
			
			version (GDebug){
				GPDebuger.plotPoint(inputData.vecs[i][0..2], "b+");
			}			
		}
		
		
		heap = new Heap!(BranchStruct)(512);
		
		this.veclen = inputData.veclen;
		this.pcount = vcount;
	}
	
	public ~this() 
	{
	}
	
	
	public int size() 
	{
		return pcount;
	}
	
	public int numTrees()
	{
		return 1;
	}


	/**
		Method that performs the agglomerative clustering.
	*/
	public void buildIndex1() 
	{
		int last = -1;
		
		while ( pcount !=0 || last>0) {
			if (last<0 && pcount!=0) {
				// initialize new chain with random point
				last = 0;
				TreeNode v = selectRandomPoint();				
				chain[last] = v;
				removePoint(v);
				sim[last] = 0;				
			}
			
			if (pcount!=0) {
		
				TreeNode s = getNearestNeighbor(chain[last]);
				float sm = similarity(chain[last],s);
			
				if (sm>sim[last]) { 
					// no RNN, adding s to the chain
					last++;
					chain[last] = s;
					removePoint(s);
					sim[last] = sm;
				}
				else {  
					agglomerateAdd(chain[last],chain[last-1]);
					last -= 2;
				}
			} else if (last>0) {
					agglomerateAdd(chain[last],chain[last-1]);
					last -= 2;
				
			}
		}
		
		if (last>=0) {
			clusters ~= chain[0..last+1];
		}
		
		
		writef("Top level clusters: %d\n",clusters.length);
		writef("Mean cluster variance for %d top level clusters: %f\n",20,meanClusterVariance(20));
		writef("Root radius: %f\n",chain[0].radius);
	}
	
	
	
	const int MAX_CHAIN_AGG = 10;
	/**
		Method that performs the agglomerative clustering.
	*/
	public void buildIndex() 
	{
		int last = -1;
		int chainAgglomerations = 0;
		
		while ( pcount !=0 || last>0) {
		
			//start new chain with random point
			if (last<0 && pcount!=0) {
				// initialize new chain with random point
				last = 0;
				TreeNode v = selectRandomPoint();
				chain[last] = v;
				removePoint(v);
				sim[last] = 0;				
			}
			
			if (pcount!=0) {
		
				TreeNode s = getNearestNeighbor(chain[last]);
				float sm = similarity(chain[last],s);
			
				if (sm>sim[last]) { 
					// no RNN, adding s to the chain
					last++;
					chain[last] = s;
					removePoint(s);
					sim[last] = sm;
				}
				else {
					if (chainAgglomerations<MAX_CHAIN_AGG) {
						agglomerateAdd(chain[last],chain[last-1]);
						last -= 2;
						chainAgglomerations++;
					} else {
						// max chain agglomerations reached, start with new chain
						
						while (last>=0) {
							nodes[pcount++] = chain[last--];
							nodes[pcount-1].ind = pcount-1;
						}
						chainAgglomerations = 0;
					}
				}
			} else if (last>0) {
					agglomerateAdd(chain[last],chain[last-1]);
					last -= 2;
				
			}
		}
		
		if (last>=0) {
			clusters ~= chain[0..last+1];
		}
		
		
		writef("Top level clusters: %d\n",clusters.length);
		writef("Mean cluster variance for %d top level clusters: %f\n",20,meanClusterVariance(20));
		writef("Root radius: %f\n",chain[0].radius);
	}

	
	/* Selects a random cluster from the 
		current clusters
	*/
	private TreeNode selectRandomPoint() 
	{
	 	int rand = cast(int) (drand48() * pcount);  
		assert(rand >=0 && rand < pcount);
		
		return nodes[rand];
	}
	
	private void removePoint(TreeNode v) 
	{
		TreeNode t = nodes[pcount-1];
		t.ind = v.ind;
		nodes[v.ind] = t;
		
		v.ind = -1;
		
		pcount--;
	}
	
	/* 
		Returns the similarity between two nodes 
	*/
	private float similarity(TreeNode n1, TreeNode n2) 
	{
		return 1/(n1.variance +  n2.variance +
					squaredDist(n1.pivot,n2.pivot));
	}
		
	/*
		Methods that performs the agglomeration fo two clusters
	*/
	private int agglomerateAdd(TreeNode node1, TreeNode node2) 
	{	
	
		int n = node1.size;
		int m = node2.size;
		
		TreeNode bt_new = new NodeSt();
		
		bt_new.pivot = new float[veclen];
		for (int i=0;i<veclen;++i) {
			bt_new.size = n + m;
			bt_new.pivot[i] = (n*node1.pivot[i]+m*node2.pivot[i])/bt_new.size;
		}
		float dist = squaredDist(node1.pivot, node2.pivot);
		bt_new.variance = (n*node1.variance+m*node2.variance+ (n*m*dist)/(n+m))/(n+m);		
		bt_new.child1 = node1;
		bt_new.child2 = node2;
		bt_new.orig_id = -1;
		bt_new.points = node1.points ~ node2.points;
		
		// compute new clusters' radius (the max distance from teh cluster center
		// to the farthest point in the cluster
		float maxDist = float.min;
		foreach (int i, float[] p; bt_new.points) {
			float crtDist = squaredDist(bt_new.pivot,p);
			if (crtDist>maxDist) {
				maxDist = crtDist;
			}
		}
		bt_new.radius = maxDist;
		
		bt_new.ind = pcount;
		nodes[pcount++] = bt_new;	
		
		
/+		version (GDebug){
			GPDebuger.plotLine(node1.pivot[0..2], node2.pivot[0..2]);
			GPDebuger.plotPoint(bt_new.pivot[0..2], "g*", true);
		}+/
		
		return bt_new.ind;
	}
	
	/* 
		Returns the nearest neighbor of a given clusters
	*/
	private TreeNode getNearestNeighbor(TreeNode node)
	{
		float minDist = float.max;
		TreeNode bestNode;
		for (int i=0;i<pcount;++i) {
			if (!(node is nodes[i])) {
				float dist = squaredDist(node.pivot,nodes[i].pivot)+node.variance+nodes[i].variance;
//				float dist = squaredDist(node.pivot,nodes[i].pivot);
				
				if (dist<minDist) {
					minDist = dist;
					bestNode = nodes[i];
				}
			} else {
				writef("Equal!!!\n");
			}
			
		}
	
		return bestNode;
	}
	
	
	
	int checks;
	int maxCheck;
	
	public void findNeighbors(ResultSet resultSet, float[] vec, int maxCheck) 
	{
		version (GDebug){
			GPDebuger.plotPoint(vec[0..2], "r+");
		}
		
		checks = 0;		
		this.maxCheck = maxCheck;
		
		heap.init();
	
		int imin = 0;
		float minval = float.max;
		
		for (int i=0;i<clusters.length;++i) {
			float dist = squaredDist(vec, clusters[i].pivot);
			
			heap.insert(BranchStruct(clusters[i], dist));
		}
		
		BranchStruct branch;
		
		while (checks<maxCheck && heap.popMin(branch)) {
			findNN(resultSet, vec, branch.node);
		}
				
	}
	
	private bool findNN(ResultSet resultSet, float[] vec, TreeNode node) 
	{
		version (GDebug){
			GPDebuger.plotLine(node.child1.pivot[0..2], node.child2.pivot[0..2]);
			GPDebuger.plotPoint(node.pivot[0..2], "c+");
		}

		if (node.child1 == null && node.child2 == null) {
			resultSet.addPoint(Point(node.pivot, node.orig_id));
			checks++;

			return true;
		}
		else {
			float dist1 = squaredDist(vec, node.child1.pivot);
			float dist2 = squaredDist(vec, node.child2.pivot);
			
/+			float dist1 = squaredDist(vec, node.child1.pivot) - node.child1.radius;
			float dist2 = squaredDist(vec, node.child2.pivot) -  node.child2.radius; +/
			
			float diff = dist1-dist2;
	
			TreeNode bestNode = (diff<0)?node.child1:node.child2;
			TreeNode otherNode = (diff<0)?node.child2:node.child1;
			
			float maxdist = (diff<0)?dist2:dist1;
			
			heap.insert(BranchStruct(otherNode, maxdist));
			
			return findNN(resultSet, vec, bestNode);
		}
	}
	
	
	float[][] getClusterPoints(TreeNode node)
	{
/+		float[][] points = new float[][10];
		int size = 0;
		getClusterPoints_Helper(node,points,size);
		
		return points[0..size];+/
		
		return node.points;
	}
	
	void getClusterPoints_Helper(TreeNode node, inout float[][] points, inout int size) 
	{
		if (node.child1 == null && node.child2 == null) {
			if (size==points.length) {
				points.length = points.length*2;
			}
			points[size++] = node.pivot;
		}
		else {
			getClusterPoints_Helper(node.child1,points,size);
			getClusterPoints_Helper(node.child2,points,size);
		}
	}
	
	
	public float meanClusterVariance(int numClusters)
	{
		Queue!(TreeNode) q = new Queue!(TreeNode)(numClusters);
		
		for (int i=0;i<clusters.length;++i) {
			q.push(clusters[i]);
		}

		while(!q.full) {
			TreeNode t;
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
		
		
		for (int i=0;i<clusterSize.length;++i) {
			writef("Cluster %d size: %d\n",i, clusterSize[i]);
		}
		
		
		
		return meanVariance;		
	}

}