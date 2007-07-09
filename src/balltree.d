
/************************************************************************
Project: aggnn

Module: balltree.d 
Author: Marius Muja (2007)

*************************************************************************/

import std.stdio;

import util;
import heap;
import resultset;
import features;
import nnindex;

import agglomerativetree2;


class BallTree : NNIndex {

	struct BallNodeSt {
		
		float[] pivot; // center of this node
		float variance; // the variance of the points in the node
		int size;  // number of points in the node. Should be \sum{children.size}
		float radius;
		
		int orig_id;
		float[][] points;
		
		BallTreeNode children[];
	};
	alias BallNodeSt* BallTreeNode;
		
	

	struct BallBranchStruct {
		BallTreeNode node;        		/* Tree node at which search resumes */
		float mindistsq;     		/* Minimum distance to query. */
		
		int opCmp(BallBranchStruct rhs) 
		{ 
			if (mindistsq < rhs.mindistsq) {
				return -1;
			} if (mindistsq > rhs.mindistsq) {
				return 1;
			} else {
				return 0;
			}
		}
		
		static BallBranchStruct opCall(BallTreeNode aNode, float dist) 
		{
			BallBranchStruct s;
			s.node = aNode;
			s.mindistsq = dist;
			
			return s;
		}
		
	}; 



	int pcount; 		// number of nodes remaining to agglomerate (should be equal to kdtree.vcount)
	int veclen;
	
	BallTreeNode btRoot;
	Heap!(BallBranchStruct) btHeap;

	
	AgglomerativeExTree aggTree;
	
	public this(Features inputData)
	{
//		kdtree = new KDTree(inputData.vecs,inputData.veclen, NUM_KDTREES);
		
//		pool = kdtree.pool;

		aggTree = new AgglomerativeExTree(inputData);
		
		btHeap = new Heap!(BallBranchStruct)(inputData.count);
		
	}
	
	public ~this() 
	{
	}
	
	
	public int size() 
	{
		return aggTree.indexSize;
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
	
		aggTree.buildIndex();
		
		writef("Building the ball-tree using the agglomerative-tree\n");
		btRoot = new BallNodeSt();
		
		btRoot.variance = aggTree.root.variance;
		btRoot.pivot = aggTree.root.pivot;
		btRoot.size = aggTree.root.size;
		btRoot.radius = aggTree.root.radius;
		btRoot.points = aggTree.root.points;
		btRoot.orig_id = aggTree.root.orig_id;


		buildBallTree(btRoot,aggTree.root);
		
		int countNodes = 0;
		
		countNodesBallTree(btRoot, countNodes);
		writef("Nodes in ball-tree: %d\n",countNodes);
	}
	
	private void countNodesBallTree(BallTreeNode node, inout int count) 
	{
		count++;
		
		for (int i=0;i<node.children.length;++i) {
			countNodesBallTree(node.children[i],count);
		}
	}
	
	
	
	void push_back(T)(inout T[] vector, T element) 
	{
		vector.length = vector.length+1;
		vector[vector.length-1] = element;
	}
	
	
	
	float shrinkFactor = 2;
	
	
	private void buildBallTree(BallTreeNode btNode, AgglomerativeExTree.TreeNode node)
	{
		if (node is null) 
			return;
		
		if (btNode.variance<shrinkFactor*node.variance) {
			buildBallTree(btNode,node.child1);
			buildBallTree(btNode,node.child2);
		}
		else {
			BallTreeNode newBtNode =  new BallNodeSt();
			
			newBtNode.variance = node.variance;
			newBtNode.pivot = node.pivot;
			newBtNode.size = node.size;
			newBtNode.radius = node.radius;
			newBtNode.points = node.points;
			newBtNode.orig_id = node.orig_id;

			push_back!(BallTreeNode)(btNode.children,newBtNode);
			
			buildBallTree(newBtNode,node.child1);
			buildBallTree(newBtNode,node.child2);
			
		}
		
	}
	
	
	
	
	
	int checks;
	int maxCheck;
	
	
	public void findNeighbors(ResultSet resultSet, float[] vec, int maxCheck) 
	{
		checks = 0;		
		this.maxCheck = maxCheck;
		
		btHeap.init();
	
		int imin = 0;
		float minval = float.max;
		
		float dist = squaredDist(vec, btRoot.pivot);	
		btHeap.insert(BallBranchStruct(btRoot, dist));
		
		BallBranchStruct branch;
		
		while (checks<maxCheck && btHeap.popMin(branch)) {
			if (branch.mindistsq-branch.node.radius>resultSet.worstDist) {
				writef("Distance to ball: %f\n",branch.mindistsq);
				writef("Ball radius: %f\n",branch.node.radius);
				writef("Worst distance: %f\n\n",resultSet.worstDist());
			}
			findNN(resultSet, vec, branch.node);
		}
				
	}
	
	private bool findNN(ResultSet resultSet, float[] vec, BallTreeNode node) 
	{
		if (node.children.length == 0) {
			resultSet.addPoint(Point(node.pivot, node.orig_id));
			checks++;

			return true;
		}
		else {
		
			float bestDist = float.max;
			int bestIndex = -1;
			
			float[] distances = new float[node.children.length];
			
			for (int i=0;i<node.children.length;++i) {
			
				distances[i] = squaredDist(vec, node.children[i].pivot);
				
				if (distances[i]<bestDist) {
					bestDist = distances[i];
					bestIndex = i;
				}
			}
			
			for (int i=0;i<node.children.length;++i) {
				if (i!=bestIndex) {
					btHeap.insert(BallBranchStruct(node.children[i], distances[i]));
				}				
			}
			
			BallTreeNode bestNode = node.children[bestIndex];
			
			return findNN(resultSet, vec, bestNode);
		}
	}

	
	

}