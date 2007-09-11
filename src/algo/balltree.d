
/************************************************************************
Project: nn

Module: balltree.d 
Author: Marius Muja (2007)

*************************************************************************/
module algo.balltree;

import std.math;

import util.utils;
import util.heap;
import util.resultset;
import util.features;
import util.logger;
import algo.nnindex;
import algo.agglomerativetree2;
import util.registry;	


mixin AlgorithmRegistry!(BallTree,float);

class BallTree : NNIndex {

	static const NAME = "balltree";

	struct BallNodeSt {
		
		float[] pivot; // center of this node
		float variance; // the variance of the points in the node
		int size;  // number of points in the node. Should be \sum{children.size}
		float radius;
		
		int orig_id;
		float[][] points;
		
		BallTreeNode children[];
		
		void describe(T)(T ar)
		{
			ar.describe(pivot);
			ar.describe(variance);
			ar.describe(size);
			ar.describe(radius);
			ar.describe(orig_id);
			if (size>1) {
				ar.describe(children);
			}
		}	

	};
	alias BallNodeSt* BallTreeNode;
		
	
	
	alias BranchStruct!(BallTreeNode) BallBranchStruct;

	int pcount; 		// number of nodes remaining to agglomerate (should be equal to kdtree.vcount)
	int veclen;
	
	BallTreeNode btRoot;
	Heap!(BallBranchStruct) btHeap;

	
	AgglomerativeExTree aggTree;
	
	
	private this()
	{
		btHeap = new Heap!(BallBranchStruct)(512);
	}
	
	public this(Features!(float) inputData, Params params)
	{
		this();
		aggTree = new AgglomerativeExTree(inputData,params);
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
		
		Logger.log(Logger.INFO,"Building the ball-tree using the agglomerative-tree\n");
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
		Logger.log(Logger.INFO,"Nodes in ball-tree: %d\n",countNodes);
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
	
		
	public void findNeighbors(ResultSet resultSet, float[] vec, int maxChecks) 
	{
		if (maxChecks==-1) {
			findExactNN(resultSet, vec, btRoot);	
		}
		else {
			btHeap.init();
			btHeap.insert(BallBranchStruct(btRoot, 0));
			
			int checks = 0;
			BallBranchStruct branch;
			
			while (checks++<maxChecks && btHeap.popMin(branch)) {
				findNN(resultSet, vec, branch.node);
			}
		}
	}
	
	private bool findNN(ResultSet resultSet, float[] vec, BallTreeNode node) 
	{
		float ball_dist = sqrt(squaredDist(vec, node.pivot));
		float node_radius = sqrt(node.radius);
		float dist = (ball_dist-node_radius)*(ball_dist-node_radius);
		float worst_dist = resultSet.worstDist;
		
 		if (dist>worst_dist) {
// 		if (ball_dist-node_radius>worst_dist) {
			return true;
		}

	
		if (node.children.length == 0) {
			resultSet.addPoint(node.pivot, node.orig_id);
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

	private void findExactNN(ResultSet resultSet, float[] vec, BallTreeNode node) 
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

	
		if (node.children.length == 0) {
			resultSet.addPoint(node.pivot, node.orig_id);
			return true;
		}
		else {
		
			float bestDist = float.max;
			int bestIndex = -1;
			
			
			int nc = node.children.length;
			int[] sort_indices = new int[nc];	
			
			getCenterOrdering(node, vec, sort_indices);

			for (int i=0; i<nc; ++i) {
				findExactNN(resultSet, vec, node.children[sort_indices[i]]);
			}
		}
	}

	private void getCenterOrdering(BallTreeNode node, float[] q, ref int[] sort_indices)
	{
		int nc = node.children.length;
		float distances[] = new float[nc];
		
		for (int i=0;i<nc;++i) {
			float dist = squaredDist(q,node.children[i].pivot);
			
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

	void describe(T)(T ar)
	{
		ar.describe(pcount);
		ar.describe(veclen);
		ar.describe(btRoot);
	}	
}

