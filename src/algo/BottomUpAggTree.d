
/************************************************************************
Project: nn

Module: agglomerativetree.d (class that constructs an agglomerative tree
			using the reciprocal-nearest-neighbor algorithm )
Author: Marius Muja (2007)

*************************************************************************/
module algo.BottomUpAggTree;

import util.utils;
import util.random;
import util.heap;
import util.resultset;
import dataset.features;
import util.logger;
import algo.nnindex;
import util.registry;	


mixin AlgorithmRegistry!(BottomUpSimpleAgglomerativeTree,float);

class BottomUpSimpleAgglomerativeTree : NNIndex {

	static const NAME = "agg_bu_simple";

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

	TreeNode[] nodes;  // vector of nodes to agglomerate
	int pcount;
	int veclen;
	
	TreeNode root;
	
	Heap!(BranchStruct) heap;

	int pointCounter;
	
	private this()
	{
	}

	public this(Features!(float) inputData, Params params)
	{
		int count = inputData.count;
		
		this.nodes = new TreeNode[count];
		pointCounter = 0;
		for (int i=0;i<count;++i) {
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



	private float findNearestClusters(out TreeNode c1, out TreeNode c2)
	{
		float minDist = float.max;
		int ind1,ind2;
		for (int i=0;i<pcount-1;++i) {
			for (int j=i+1;j<pcount;++j) {
				float dist = squaredDist(nodes[i].pivot, nodes[j].pivot) + nodes[i].variance + nodes[j].variance;
				//float dist = squaredDist(nodes[i].pivot, nodes[j].pivot);
				if (dist<minDist) {
					ind1 = i;
					ind2 = j;
					minDist = dist;
				}
			}
		}
		
		c1 = nodes[ind1];
		c2 = nodes[ind2];
		
//		writef("Min dist: %f\n",minDist);
		return minDist;
	}

	/**
		Method that performs the agglomerative clustering.
	*/
	public void buildIndex() 
	{
		while (pcount>1) {
			TreeNode c1;
			TreeNode c2;
			float distance = findNearestClusters(c1,c2);
			removePoint(c1);
			removePoint(c2);
			TreeNode c = agglomerate(c1,c2, distance);
			addPoint(c);			
		}
		
		root = nodes[0];

/+		writef("Mean cluster variance for %d top level clusters: %f\n",4,meanClusterVariance(4));		
		writef("Root radius: %f\n",root.radius);+/
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
	
	private void write(TreeNode node) 
	{
		Logger.log(Logger.INFO,"#{} ",node.orig_id);
/+		writef("{");
		for (int i=0;i<node.pivot.length;++i) {
			if (i!=0) writef(",");
			writef("%f",node.pivot[i]);
		}
		writef("}");+/
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
	
		
		distance = squaredDist(node1.pivot, node2.pivot);
	
		bt_new.size = n + m;
		for (int i=0;i<veclen;++i) {
			bt_new.pivot[i] = (n*node1.pivot[i]+m*node2.pivot[i])/bt_new.size;
		}
		bt_new.variance = (n*node1.variance+m*node2.variance + (n*m*distance)/(bt_new.size))/(bt_new.size);		
		bt_new.child1 = node1;
		bt_new.child2 = node2;
		
		// new node's points is the contatenation of the child nodes' points
		bt_new.points = node1.points ~ node2.points;
		
		// compute new clusters' radius (the max distance from the cluster center
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

		
		
/+		writef("Agglomerate: ");
		write(node1);
		writef(" + ");
		write(node2);
		writef(" = ");
		write(bt_new);
		writef("\n");+/
		
		
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
	
	
	
	public void findNeighbors(ResultSet resultSet, float[] vec, int maxChecks) 
	{
		heap.init();
		heap.insert(BranchStruct(root, 0));
		
		int checks = 0;
		BranchStruct branch;
		while (checks++<maxChecks && heap.popMin(branch)) {
			findNN(resultSet, vec, branch.node);
		}
	}
	
	private bool findNN(ResultSet resultSet, float[] vec, TreeNode node) 
	{
		version (GDebug){
			GPDebuger.plotLine(node.child1.pivot[0..2], node.child2.pivot[0..2]);
			GPDebuger.plotPoint(node.pivot[0..2], "c+");
		}
		
		if (squaredDist(vec, node.pivot)-node.radius>resultSet.worstDist) {
			return true;
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
			Logger.log(Logger.INFO,"Cluster {} size: {}\n",i, clusterSize[i]);
		}
		
		
		
		return meanVariance;		
	}


float[][] getClusterCenters(int numClusters) 
	{
		float variance;
		TreeNode[] clusters = getMinVarianceClusters(root, numClusters, variance);
	
		Logger.log(Logger.INFO,"Mean cluster variance for {} top level clusters: {}\n",clusters.length,variance);
		
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

}
