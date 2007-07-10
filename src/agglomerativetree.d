
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



class AgglomerativeTree : NNIndex{

	// tree node data structure
	struct NodeSt {
		int kd_ind;
		
		float[] pivot; // center of this node
		float variance; // the variance of the points in the node
		int size;  // number of points in the node. Should be child1.size + child2.size
		
		int orig_id;
		
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

	KDTree kdtree;
	
	TreeNode[] chain; // the chain array used by the agglomerative algorithm
	float[] sim;	// the sim array used by the agglomerative algorithm
	
	TreeNode[] nodes;  // vector of nodes to agglomerate
	int pcount; 		// number of nodes remaining to agglomerate (should be equal to kdtree.vcount)
	int veclen;
	
	TreeNode[] clusters;

	int[] rmap; 	// reverse mapping from kd_indices to indices in nodes vector
	
	Pool pool;		// pool for memory allocation
	Heap!(BranchStruct) heap;
	ResultSet resultSet;
	
	int indexSize;

	public this(Features inputData)
	{
		kdtree = new KDTree(inputData.vecs,inputData.veclen, NUM_KDTREES);
		
		pool = kdtree.pool;
		
		int vcount = inputData.count;
		indexSize = vcount;
		
		this.chain = new TreeNode[vcount];
		this.sim = new float[vcount];
		
		version (GDebug){
			GPDebuger.sendCommand("hold on");
		}
		
		this.nodes = new TreeNode[vcount];
		this.rmap = new int[vcount];
		for (int i=0;i<vcount;++i) {
			nodes[i] = new NodeSt();
			nodes[i].kd_ind = i;
			nodes[i].pivot = inputData.vecs[i];
			nodes[i].variance = 0.0;
			nodes[i].child1 = nodes[i].child2 = null;
			nodes[i].size = 1;
			nodes[i].orig_id = i;
			
			rmap[i] = i;
			
			version (GDebug){
				GPDebuger.plotPoint(inputData.vecs[i][0..2], "b+");
			}			
		}
		
		
		heap = new Heap!(BranchStruct)(512);
		
		this.veclen = inputData.veclen;
		this.pcount = vcount;
		
		resultSet = new ResultSet(2);
	}
	
	public ~this() 
	{
		delete kdtree;
	}
	
	
	public int size() 
	{
		return indexSize;
	}
	
	public int numTrees()
	{
		return 1;
	}


	
	
	/**
		Method that performs the agglomerative clustering.
	*/
	public void buildIndex() 
	{
		kdtree.buildIndex();
	
	
		int last = -1;
		
		while ( kdtree.vcount !=0 ) {
			if (last<0) {
				// initialize new chain with random point
				last = 0;
				TreeNode v = selectRandomPoint();				
				chain[last] = v;
				removePoint(v);
				sim[last] = 0;				
			}
			
		
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
				// Found RNN, agglomerate the last two nodes in the chain
				// and add result to the kdtree
				if (sim[last]>SIM_THRESHOLD) { // ??
					agglomerateAdd(chain[last],chain[last-1]);
					last -= 2;
				} else {
					clusters ~= chain[0..last+1];
					last = -1; // discard the current chain
				}
			}
		}
		
		if (last>=0) {
			clusters ~= chain[0..last+1];
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
	
	private void removePoint(TreeNode v) 
	{
		if (!kdtree.RemoveElement(v.kd_ind)) {
			throw new Exception("Element not found");
		}
		
		setNode(rmap[v.kd_ind], nodes[--pcount]);		
		rmap[v.kd_ind] = -1;
	}
	
	/* 
		Returns the similarity between two nodes 
	*/
	private float similarity(TreeNode n1, TreeNode n2) 
	{
		return 1/(n1.variance +  n2.variance +
					squaredDist(n1.pivot,n2.pivot));
	}
	
	
	private void setNode(int pos, TreeNode value) 
	{
		nodes[pos] = value;
		rmap[value.kd_ind] = pos;
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
		
		// add node to kdtree
		bt_new.kd_ind = kdtree.InsertElement(bt_new.pivot);
		
		// add node to nodes array
		setNode(pcount++,bt_new);
		
		// add to reverse mapping
		if (bt_new.kd_ind>=rmap.length) { 
			rmap.length = bt_new.kd_ind+1;	// increase size of array if needed (nice D feature)
		}
		
		
		version (GDebug){
			GPDebuger.plotLine(node1.pivot[0..2], node2.pivot[0..2]);
			GPDebuger.plotPoint(bt_new.pivot[0..2], "g*", false);
		}
		
		return bt_new.kd_ind;
	}
	
	
	/* 
		Returns the nearest neighbor of a given clusters
	*/
	private TreeNode getNearestNeighbor(TreeNode node)
	{
		resultSet.init(node.pivot);
		kdtree.findNeighbors(resultSet, node.pivot, KD_MAXCHECK);
		int nn_index = resultSet.getPointIndex(0);
		assert(nodes[rmap[nn_index]].kd_ind==nn_index);
		return nodes[rmap[nn_index]];
	}
	
	
	
	int checked;
	int maxCheck;
	
	public void findNeighbors(ResultSet resultSet, float[] vec, int maxCheck) 
	{
		version (GDebug){
			GPDebuger.plotPoint(vec[0..2], "r+");
		}
		
		checked = 0;		
		this.maxCheck = maxCheck;
		
		heap.init();
	
		int imin = 0;
		float minval = float.max;
		
		for (int i=0;i<clusters.length;++i) {
			float dist = squaredDist(vec, clusters[i].pivot);
			
			heap.insert(BranchStruct(clusters[i], dist));
		}
		
		BranchStruct branch;
		
		while (heap.popMin(branch)) {
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
			return true;
		}
		else {
			float dist1 = squaredDist(vec, node.child1.pivot);
			float dist2 = squaredDist(vec, node.child2.pivot);
			
			float diff = dist1-dist2;
	
			TreeNode bestNode = (diff<0)?node.child1:node.child2;
			TreeNode otherNode = (diff<0)?node.child2:node.child1;
			
			float maxdist = (diff<0)?dist2:dist1;
			
			if (checked<maxCheck) {
//				writef("Insert branch\n");
				heap.insert(BranchStruct(otherNode, maxdist));
				
				checked++;
			}
			
			return findNN(resultSet, vec, bestNode);
		}
	}

}