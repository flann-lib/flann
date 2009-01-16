#ifndef BBSEARCH_H
#define BBSEARCH_H

#include "constants.h"
#include "NNIndex.h"
#include "LinearSearch.h"
#include "KDTree.h"
#include "Heap.h"

const int BFS_NN = 10;

class BFSearch : public NNIndex {

	Dataset<float>& dataset;
	int* bfs_nn;

	KDTree* kdtree;

	bool* visited;

	float min_dist;

	typedef BranchStruct<int> BranchSt;




public:

	BFSearch(Dataset<float>& inputData, Params params) : dataset(inputData)
	{
		visited = new bool[dataset.rows];
	}

	~BFSearch()
	{
		delete visited;
	}

    flann_algorithm_t getType() const
    {
        return BFSEARCH;
    }


	int size() const
	{
		return dataset.rows;
	}

	int veclen() const
	{
		return dataset.cols;
	}


	int usedMemory() const
	{
		return 0;
	}

	void buildIndex()
	{
		bfs_nn = new int[dataset.rows*BFS_NN];

		Params p;
		LinearSearch ls(dataset,p);
		KNNResultSet resultSet(BFS_NN+1);

		logger.info("Computing neighbourhood structure\n");
		for (int i=0;i<dataset.rows;++i) {
			float* target = dataset[i];
			resultSet.init(target, dataset.cols);
			ls.findNeighbors(resultSet,target,p);

	        int* neighbors = resultSet.getNeighbors();
	        for (int j=0;j<BFS_NN;++j) {
	        	(bfs_nn+i*BFS_NN)[j] = neighbors[j+1];
	        }

	        logger.info("%g     \r",float(i)*100/dataset.rows);
		}
		logger.info("Done computing neighbourhood structure\n");

		Params tree_params;
		tree_params["trees"] = 1;
		kdtree = new KDTree(dataset,tree_params);

		logger.info("Building kd-tree\n");
		kdtree->buildIndex();
	}

	void findNeighbors(ResultSet& resultSet, float* query, Params searchParams)
	{
        int maxChecks;
        if (searchParams.find("checks") == searchParams.end()) {
            maxChecks = -1;
        }
        else {
            maxChecks = (int)searchParams["checks"];
        }

		if (maxChecks==-1) {
			throw FLANNException("Exhaustive search not implemented for BFSearch.");
		}

		for (int i=0;i<dataset.rows;++i) {
			visited[i] = false;
		}

		KNNResultSet rs(1,query,dataset.cols);
		Params kdtreeParams;
		kdtreeParams["checks"] = 1;
		kdtree->findNeighbors(rs,query,kdtreeParams);

		int *neighbors = rs.getNeighbors();
		float* dists = rs.getDistances();

		min_dist = dists[0];

		BranchSt branch = BranchSt::make_branch(neighbors[0],dists[0]);

		Heap<BranchSt>* heap = new Heap<BranchSt>(dataset.rows);

		heap->insert(branch);
		int checks = 1;
		while (checks<maxChecks) {
			exploreNeighbors(resultSet, query, *heap, checks,maxChecks);

			do {
				kdtree->continueSearch(rs,query,1);
				neighbors = rs.getNeighbors();
				dists = rs.getDistances();
				checks++;
			} while (dists[0]>=min_dist && checks<maxChecks);
			branch = BranchSt::make_branch(neighbors[0],dists[0]);
			heap->insert(branch);
		}


	}

    Params estimateSearchParams(float precision, Dataset<float>* testset = NULL)
    {
        Params params;
        return params;
    }


private:
	void exploreNeighbors(ResultSet& resultSet, float* query, Heap<BranchSt>& heap, int& checks, int maxChecks)
	{
		BranchSt branch;

		while (heap.popMin(branch) && checks<maxChecks)
		{
//			printf("Index: %d, dist: %g\n", branch.node, branch.mindistsq);
			int index = branch.node;
			resultSet.addPoint(dataset[index],index);
			visited[index] = true;

			for (int i=0;i<BFS_NN;++i) {
				int new_index = (bfs_nn+index*BFS_NN)[i];
				float new_dist;

				if (!visited[new_index]) {
					visited[new_index] = true;
					new_dist = flann_dist(query, query+dataset.cols, dataset[new_index]);
					checks++;
				}

				if (new_dist<min_dist || !resultSet.full()) {
					min_dist = min(min_dist,new_dist);
					BranchSt new_branch = BranchSt::make_branch(new_index,new_dist);
					heap.insert(new_branch);
				}
			}
		}

	}
};

register_index(BFSEARCH,BFSearch)

#endif // BBSEARCH_H
