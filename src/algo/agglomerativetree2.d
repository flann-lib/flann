/************************************************************************
Project: nn

Module: agglomerativetree.d (class that constructs an agglomerative tree
			using the reciprocal-nearest-neighbor algorithm )
Author: Marius Muja (2007)

*************************************************************************/
module algo.agglomerativetree2;


import std.math;

import util.utils;
import util.random;
import util.heap;
import util.resultset;
import dataset.features;	
import util.logger;	
import algo.nnindex;
import util.registry;	


mixin AlgorithmRegistry!(AgglomerativeExTree,float);

class AgglomerativeExTree : NNIndex {

	static string NAME = "agglomerative";

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
			
		void describe(T)(T ar)
		{
			ar.describe(ind);
			ar.describe(pivot);
			ar.describe(variance);
			ar.describe(size);
			ar.describe(radius);
			ar.describe(orig_id);
//			ar.describe(points);
			if (size>1) {
				ar.describe(child1);
				ar.describe(child2);
			}
		}
	};
	alias NodeSt* TreeNode;
	
	alias BranchStruct!(TreeNode) BranchSt;
	
	TreeNode[] nodes;  // vector of nodes to agglomerate
	int pcount; 		// number of nodes remaining to agglomerate (should be equal to kdtree.vcount)
	int veclen;
	
	TreeNode root;

	Heap!(BranchSt) heap;

	int pointCounter;
	int indexSize;
	
	
	private this()
	{
		heap = new Heap!(BranchSt)(512);
	}
	
	public this(Features!(float) inputData, Params params)
	{
		pcount = inputData.count;
		indexSize = pcount;
				
		version (GDebug){
			GPDebuger.sendCommand("hold on");
		}
		
		this.nodes = new TreeNode[pcount];
		this.pointCounter = 0;
		for (int i=0;i<pcount;++i) {
			nodes[i] = new NodeSt();
			nodes[i].ind = i;
			nodes[i].pivot = inputData.vecs[i];
			nodes[i].variance = 0.0;
			nodes[i].radius = 0.0;
			nodes[i].child1 = nodes[i].child2 = null;
			nodes[i].size = 1;
			nodes[i].orig_id = pointCounter++;
			
			nodes[i].points = new float[][1];
			nodes[i].points[0] = nodes[i].pivot;
	
		}
				
		heap = new Heap!(BranchSt)(inputData.count);
		
		this.veclen = inputData.veclen;
	}
	
	public ~this() 
	{
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
		TreeNode[] chain = new TreeNode[pcount]; // the chain array used by the agglomerative algorithm
		float[] sim = new float[pcount];		// the sim array used by the agglomerative algorithm
		
		int last = -1;
		
		while ( pcount !=0 || last>0) {
			if (last<0 && pcount!=0) {
				// initialize new chain with random point
				last = 0;
				TreeNode v = selectRandomPoint();				
				chain[last] = v;
				removePoint(v);
				sim[last] = float.max;				
			}
			
			if (pcount!=0) {
		
				TreeNode s = getNearestNeighbor(chain[last]);
				float sm = similarity(chain[last],s);
			
				if (sm<sim[last]) { 
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
		
		assert(last==0);
		root = chain[0];
				
/+		writef("Root radius: %f\n",root.radius);
		writef("Root variance: %f\n",root.variance);		+/
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
		return (n1.variance +  n2.variance +
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
		bt_new.orig_id = pointCounter++;

		
		bt_new.ind = pcount;
		nodes[pcount++] = bt_new;	
		
		
/+		void write(TreeNode node) {
			writef("%d",node.orig_id);
		}+/
		
// 		writef("Agglomerate: ");
// 		write(node1);
// 		writef(" + ");
// 		write(node2);
// 		writef(" = ");
// 		write(bt_new);
// 		writef("\n");

		
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
			if (node !is nodes[i]) {
				float dist = squaredDist(node.pivot,nodes[i].pivot)+node.variance+nodes[i].variance;
				
				if (dist<minDist) {
					minDist = dist;
					bestNode = nodes[i];
				}
			} else {
				throw new Exception("Equal!!!\n");
			}
			
		}
	
		return bestNode;
	}
	
// 	int nodes_checked;
	
	public void findNeighbors(ResultSet resultSet, float[] vec, int maxChecks) 
	{		
// 		nodes_checked = 0;
		if (maxChecks==-1) {
			findExactNN(resultSet, vec, root);
		}
		else {
			heap.init();		
			heap.insert(BranchSt(root, 0));
						
			int checks = 0;		
			BranchSt branch;
			while (checks++<maxChecks && heap.popMin(branch)) {
				findNN(resultSet, vec, branch.node);
			}
		}
//		writefln("Nodes checked: %d",nodes_checked);
	}
	
	
	private void findExactNN(ResultSet resultSet, float[] vec, TreeNode node)
	{
		float bsq = squaredDist(vec, node.pivot);
		float rsq = node.radius;
		float wsq = resultSet.worstDist;
		
		float val = bsq-rsq-wsq;
		float val2 = val*val-4*rsq*wsq;
		
// //  		if (val>0) {
		if (val>0 && val2>0) {
			return;
		}
		
		if (node.child1 == null && node.child2 == null) {
// 			nodes_checked++;
			resultSet.addPoint(node.pivot, node.orig_id);
			return;
		}
		else {
			float dist1 = squaredDist(vec, node.child1.pivot);
			float dist2 = squaredDist(vec, node.child2.pivot);
			
			float diff = dist1-dist2;	
			TreeNode bestNode = (diff<0)?node.child1:node.child2;
			TreeNode otherNode = (diff<0)?node.child2:node.child1;
						
			findExactNN(resultSet, vec, bestNode);
			findExactNN(resultSet, vec, otherNode);
			
		}		
	}
	
	
	private void findNN(ResultSet resultSet, float[] vec, TreeNode node) 
	{		
		float bsq = squaredDist(vec, node.pivot);
		float rsq = node.radius;
		float wsq = resultSet.worstDist;
		
		float val = bsq-rsq-wsq;
		float val2 = val*val-4*rsq*wsq;
		
// //  		if (val>0) {
		if (val>0 && val2>0) {
			return;
		}
		
		if (node.child1 == null && node.child2 == null) {
			resultSet.addPoint(node.pivot, node.orig_id);
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
			
			heap.insert(BranchSt(otherNode, maxdist));
			
			findNN(resultSet, vec, bestNode);
		}
	}
	
	
	/+
		----------------------------------------------------------
	+/
	
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
	
	
	public float meanClusterVariance1(int numClusters)
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
			
			Logger.log(Logger.INFO,"%f - %f\n",variances[i],q[i].variance);
			
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
			Logger.log(Logger.INFO,"Cluster %d size: %d\n",i, clusterSize[i]);
		}
		
		return meanVariance;		
	}
	
	
	float[][] getClusterCenters(int numClusters) 
	{
		float variance;
		TreeNode[] clusters = getMinVarianceClusters(root, numClusters, variance);
	
		Logger.log(Logger.INFO,"Mean cluster variance for %d top level clusters: %f\n",clusters.length,variance);
		
		float[][] centers = new float[][clusters.length];
		
 		foreach (index, cluster; clusters) {
			centers[index] = cluster.pivot;
		}
		
		return centers;
	}

	
	
	public TreeNode[] getMinVarianceClusters(TreeNode root, int numClusters, out float varianceValue)
	{
		TreeNode clusters[] = new TreeNode[10];
		
		int clusterCount = 1;
		clusters[0] = root;
		 
		float meanVariance = root.variance*root.size;
		 
		while (clusterCount<numClusters) {
			
			float minVariance = float.max;
			int splitIndex = -1;
			
			for (int i=0;i<clusterCount;++i) {
			
			
				if (!(clusters[i].child1 is null) && !(clusters[i].child1 is null)) {
					float variance = meanVariance - clusters[i].variance*clusters[i].size +
							clusters[i].child1.variance*clusters[i].child1.size +
							clusters[i].child2.variance*clusters[i].child2.size;
					
					if (variance<minVariance) {
						minVariance = variance;
						splitIndex = i;
					}
				}			
			}
			
			meanVariance = minVariance;
			
			// increase vector if needed
			if (clusterCount==clusters.length) {
				clusters.length = clusters.length*2;
			}
			
			// split node
			TreeNode toSplit = clusters[splitIndex];
			clusters[splitIndex] = toSplit.child1;
			clusters[clusterCount++] = toSplit.child2;
		}
		
// 		for (int i=0;i<numClusters;++i) {
// 			writef("Cluster %d size: %d\n",i,clusters[i].size);
// 		}
		
		varianceValue = meanVariance/root.size;
		
		return clusters[0..clusterCount];
	}
	
	void describe(T)(T ar)
	{
		ar.describe(pcount);
		ar.describe(veclen);
		ar.describe(root);
		ar.describe(indexSize);
	}

}

