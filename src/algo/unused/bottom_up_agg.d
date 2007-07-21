
/************************************************************************

Module: agglomerativetree.d (class that constructs an agglomerative tree
			using the reciprocal-nearest-neighbor algorithm )
Author: Marius Muja (2007)

*************************************************************************/

import std.stdio;

import util.utils;
import util.heap;
import util.resultset;
import util.features;
import algo.kdtree;
import algo.nnindex;

//import debuger;
version (GDebug){
	import gpdebuger;
}

//mixin AlgorithmRegistry!(BottomUpAgglomerativeTree);

class BottomUpAgglomerativeTree : NNIndex {

	static const NAME = "agg_bu";

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
		
		TreeNode[] neighbors;
		int ncount;
	};
	alias NodeSt* TreeNode;
	
/+	
	struct NodeNeighbor {
		TreeNode node;
		float dist;
		NodeNeighbor* next;
	};+/
		
	
	
	struct LinkStruct {
		float dist;
		TreeNode node1;
		TreeNode node2;
		
		int opCmp(LinkStruct rhs) 
		{ 
			if (dist < rhs.dist) {
				return -1;
			} if (dist > rhs.dist) {
				return 1;
			} else {
				return 0;
			}
		}
	};
	
	
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

	TreeNode[] nodes;  // vector of nodes to agglomerate
	int pcount; 		// number of nodes remaining to agglomerate (should be equal to kdtree.vcount)
	int veclen;
	
	TreeNode root;
	
	Heap!(BranchStruct) heap;
	//Heap!(LinkStruct) distHeap;
	LinkStruct[] distances;
	int dcount;


	private this()
	{
	}


	public this(Features inputData, Params params)
	{
		int count = inputData.count;
		
		this.nodes = new TreeNode[count];
		for (int i=0;i<count;++i) {
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
			nodes[i].neighbors = null;
						
			version (GDebug){
				GPDebuger.plotPoint(inputData.vecs[i][0..2], "b+");
			}			
		}
		
		//distHeap = new Heap!(LinkStruct)(nodes.length);

		distances = new LinkStruct[nodes.length];
		dcount = 0;
		
		heap = new Heap!(BranchStruct)(512);
		
		this.veclen = inputData.veclen;
		this.pcount = count;
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





	
	
	//-------------------------------------------------
	// neighborhood list
	//------------------------------------------------
	
	
	private void removeFromNeighborList(TreeNode theNode, TreeNode removeNode)
	{
		if (theNode.neighbors==null) {
			return;
		}
		
		
		for (int i=0;i<theNode.ncount;++i) {
			if (removeNode is theNode.neighbors[i]) {
				theNode.neighbors[i] = theNode.neighbors[theNode.ncount-1];
				theNode.ncount--;
				return;
			}
		}

	}


	
	private void addNodeNeighbor(TreeNode node, TreeNode neighbor, float dist)
	{
		node.neighbors ~= neighbor;
		node.ncount++;
	}





	//----------------------------------------------
	// distances list
	//-----------------------------------------------


	LinkStruct getMinDistance() 
	{
		float dist = float.max;
		int minIndex = -1;
		
		for (int i=0;i<dcount;++i) {
			if (distances[i].dist<dist) {
				minIndex = i;
				dist = distances[i].dist;
			}
		}
		
		return distances[minIndex];
	}

	void removeDistance(TreeNode node1, TreeNode node2)
	{
		for (int i=0;i<dcount;++i) {
			if (((distances[i].node1 is node1) && (distances[i].node2 is node2)) ||
					((distances[i].node1 is node2) && (distances[i].node2 is node1))) {
				//remove distance
					distances[i] = distances[dcount-1];
					dcount--;
					return;	
				}
		}
	}
	
	void removeDistancesContaining(TreeNode node1, TreeNode node2)
	{
		for (int i=0;i<dcount;++i) {
			if (((distances[i].node1 is node1) || (distances[i].node1 is node2)) ||
					((distances[i].node2 is node1) || (distances[i].node2 is node2))) {
				//remove distance
					distances[i] = distances[dcount-1];
					i--;
					dcount--;
				}
		}
	}
	
	void addDistance(TreeNode node, TreeNode neighbor, float dist)
	{
		LinkStruct ls;
		ls.dist = dist;
		ls.node1 = node;
		ls.node2 = neighbor;
		
		distances[dcount++] = ls;
	}
	
	
	
	bool distancePresent(TreeNode node1, TreeNode node2, float dist)
	{
		for (int i=0;i<dcount;++i) {
			if (((distances[i].node1 is node1) && (distances[i].node2 is node2)) ||
					((distances[i].node1 is node2) && (distances[i].node2 is node1))) {
					return true;	
			}
		}
		return false;
	}	
	
	
	//--------------------------------------------
	// manage points
	//------------------------------------------
	
	private int addPoint(TreeNode v) 
	{
		// add point
		v.ind = pcount;
		nodes[pcount++] = v;

		return v.ind;
	}
	
	
	private void removePoint(TreeNode v) 
	{
		TreeNode t = nodes[pcount-1];
		t.ind = v.ind;
		nodes[v.ind] = t;
		
		v.ind = -1;
		
		pcount--;
	}
	
	
	
	

	/**
		Method that performs the agglomerative clustering.
	*/
	public void buildIndex() 
	{
		computeNNPairs();
				
		while (dcount!=0) {
			LinkStruct ls = getMinDistance();
			//distHeap.popMin(ls);
			TreeNode node1 = ls.node1;
			TreeNode node2 = ls.node2;
			
			
			TreeNode newNode = agglomerate(ls.node1,ls.node2, ls.dist);			
			removePoint(node1);
			removePoint(node2);

			addPoint(newNode);
		
			writef("%d - %d\n",pcount, dcount);
		
			removeDistancesContaining(node1,node2);
		
			for (int i=0;i<node1.ncount;++i) {
				removeFromNeighborList(node1.neighbors[i],node1);
				computeNearestNeighbor(node1.neighbors[i]);
			}
			for (int i=0;i<node2.ncount;++i) {
				removeFromNeighborList(node2.neighbors[i],node2);
				computeNearestNeighbor(node2.neighbors[i]);
			}
			computeNearestNeighbor(newNode);
		}	
		
		assert(pcount==1);
		
		root = nodes[0];
	}
	

	
	private void computeNearestNeighbor(TreeNode node)
	{
		float distance;
		TreeNode nn = getNearestNeighbor(node, distance);
		
		if (!distancePresent(node,nn,distance)) {
			addDistance(node,nn,distance);
				
			addNodeNeighbor(node,nn,distance);
			addNodeNeighbor(nn,node,distance);

		}
		
	}
	

	
	public void computeNNPairs()
	{
		for (int i=0;i<nodes.length;++i) {
			computeNearestNeighbor(nodes[i]);
		}
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
	private TreeNode agglomerate(TreeNode node1, TreeNode node2, float distance) 
	{	
	
		int n = node1.size;
		int m = node2.size;
		
		TreeNode bt_new = new NodeSt();
		
		bt_new.pivot = new float[veclen];
		for (int i=0;i<veclen;++i) {
			bt_new.size = n + m;
			bt_new.pivot[i] = (n*node1.pivot[i]+m*node2.pivot[i])/bt_new.size;
		}
		bt_new.variance = (n*node1.variance+m*node2.variance+ (n*m*distance)/(n+m))/(n+m);		
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
		
		
		return bt_new;
	}
	
	/* 
		Returns the nearest neighbor of a given clusters
	*/
	private TreeNode getNearestNeighbor(TreeNode node, out float distance)
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
			}
			
		}
		distance =  minDist;
	
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
		
		
		float dist = squaredDist(vec, root.pivot);
		heap.insert(BranchStruct(root, dist));

		
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
			resultSet.addPoint(node.pivot, node.orig_id);
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
		
		q.push(root);

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
	
	void describe(T)(T ar)
	{
	}	

}
