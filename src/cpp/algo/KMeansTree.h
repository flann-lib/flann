/************************************************************************
 * Hierarchical KMeans approximate nearest neighbor search
 * 
 * This module finds the nearest-neighbors of vectors in high dimensional 
 * spaces using a search of a kmeans tree.
 * 
 * Authors: Marius Muja, mariusm@cs.ubc.ca
 * 
 * Version: 1.0
 * 
 * History:
 * 
 * License: LGPL
 * 
 *************************************************************************/

#include <algorithm>
#include <map>
#include <cstdlib>
#include <cassert>
#include <limits>
#include <cmath>
#include "Heap.h"
#include "Allocator.h"
#include "Variant.h"
#include "Dataset.h"
#include "ResultSet.h"
#include "defines.h"
#include "Random.h"

using namespace std;







/**
* Chooses the initial centers in the k-means clustering in a random manner. 
* 
* Params:
*     k = number of centers 
*     vecs = the dataset of points
*     indices = indices in the dataset
*     indices_length = length of indices vector
* 
*/
void chooseCentersRandom(int k, Dataset<float> vecs, int* indices, int indices_length, float** centers, int& centers_length)
{
    UniqueRandom r(indices_length);
    
    int index;
    for (index=0;index<k;++index) {
        bool duplicate = true;
        int rnd;
        while (duplicate) {
            duplicate = false;
            rnd = r.next();
            if (rnd<0) {
                centers_length = index;
                return;
            }
            
            centers[index] = vecs[indices[rnd]];
            
            for (int j=0;j<index;++j) {
                float sq = squared_dist(centers[index],centers[j],vecs.cols);
                if (sq<1e-16) {
                    duplicate = true;
                }
            }
        }
    }
    
    centers_length = index;
}


/**
* Chooses the initial centers in the k-means using Gonzales' algorithm 
* so that the centers are spaced apart from each other. 
* 
* Params:
*     k = number of centers 
*     vecs = the dataset of points
*     indices = indices in the dataset
* Returns:
*/
void chooseCentersGonzales(int k, Dataset<float> vecs, int* indices, int indices_length, float** centers, int& centers_length)
{
    int n = indices_length;
    
    
    int rnd = rand_int(n);  
    assert(rnd >=0 && rnd < n);
    
    centers[0] = vecs[indices[rnd]];
    
    int index;
    for (index=1; index<k; ++index) {
        
        int best_index = -1;
        float best_val = 0;
        for (int j=0;j<n;++j) {
            float dist = squared_dist(centers[0],vecs[indices[j]],vecs.cols);
            for (int i=1;i<index;++i) {
                    float tmp_dist = squared_dist(centers[i],vecs[indices[j]], vecs.cols);
                if (tmp_dist<dist) {
                    dist = tmp_dist;
                }
            }
            if (dist>best_val) {
                best_val = dist;
                best_index = j;
            }
        }
        if (best_index!=-1) {
            centers[index] = vecs[indices[best_index]];
        } 
        else {
            break;
        }
    }
    centers_length = index;
}


/**
* Chooses the initial centers in the k-means using the algorithm 
* proposed in the KMeans++ paper:
* Arthur, David; Vassilvitskii, Sergei - k-means++: The Advantages of Careful Seeding
*   
* Implementation of this function was converted from the one provided in Arthur's code.
*     
* Params:
*     k = number of centers 
*     vecs = the dataset of points
*     indices = indices in the dataset
* Returns:
*/
void chooseCentersKMeanspp(int k, Dataset<float> vecs, int* indices, int indices_length, float** centers, int& centers_length)
{
    int n = indices_length;
    
    double currentPot = 0;
    double closestDistSq[n];

    // Choose one random center and set the closestDistSq values
    int index = rand_int(n);  
    assert(index >=0 && index < n);
    centers[0] = vecs[indices[index]];
    
    for (int i = 0; i < n; i++) {
        closestDistSq[i] = squared_dist(vecs[indices[i]], vecs[indices[index]], vecs.cols);
        currentPot += closestDistSq[i];
    }


    const int numLocalTries = 1;

    // Choose each center
    int centerCount;
    for (centerCount = 1; centerCount < k; centerCount++) {

        // Repeat several trials
        double bestNewPot = -1;
        int bestNewIndex; 
        for (int localTrial = 0; localTrial < numLocalTries; localTrial++) {
        
            // Choose our center - have to be slightly careful to return a valid answer even accounting
            // for possible rounding errors
        double randVal = rand_double(currentPot);
            for (index = 0; index < n-1; index++) {
                if (randVal <= closestDistSq[index])
                    break;
                else
                    randVal -= closestDistSq[index];
            }

            // Compute the new potential
            double newPot = 0;
            for (int i = 0; i < n; i++)
                newPot += min( squared_dist(vecs[indices[i]], vecs[indices[index]], vecs.cols), closestDistSq[i] );

            // Store the best result
            if (bestNewPot < 0 || newPot < bestNewPot) {
                bestNewPot = newPot;
                bestNewIndex = index;
            }
        }

        // Add the appropriate center
        centers[centerCount] = vecs[indices[bestNewIndex]];
        currentPot = bestNewPot;
        for (int i = 0; i < n; i++)
            closestDistSq[i] = min( squared_dist(vecs[indices[i]], vecs[indices[bestNewIndex]], vecs.cols), closestDistSq[i] );
    }

    centers_length = centerCount;
}




namespace {
    
    typedef void (*centersAlgFunction)(int,Dataset<float>, int*, int, float**, int&);
    /**
    * Associative array with functions to use for choosing the cluster centers. 
    */
    map<const char*,centersAlgFunction> centerAlgs;
    /**
    * Static initializer. Performs initialization befor the program starts.
    */

    void centers_init()
    {
        centerAlgs["random"] = &chooseCentersRandom;
        centerAlgs["gonzales"] = &chooseCentersGonzales;        
        centerAlgs["kmeanspp"] = &chooseCentersKMeanspp;
    }

    struct Init {
        Init() { centers_init(); }
    };
    Init __init;
}






/**
 * Hierarchical kmeans index
 * 
 * Contains a tree constructed through a hierarchical kmeans clustering 
 * and other information for indexing a set of points for nearest-neighbor matching.
 */
class KMeansTree
{
	/**
	 * Index name.
	 * 
	 * Used by the AlgorithmRegistry template for registering a new algorithm with
	 * the application. 
	 */



	/**
	 * The branching factor used in the hierarchical k-means clustering
	 */
	int branching;
	
	/**
	 * Maximum number of iterations to use when performing k-means 
	 * clustering
	 */
	int max_iter;
	
	/**
	 * Cluster border index. This is used in the tree search phase when determining
	 * the closest cluster to explore next. A zero value takes into account only
	 * the cluster centers, a value greater then zero also take into account the size
	 * of the cluster.
	 */
	float cb_index;
	
	/**
	 * The dataset used by this index
	 */
    Dataset<float>& dataset;

    int size;
    int veclen;
	
	
	/**
	 * Struture representing a node in the hierarchical k-means tree. 
	 */
	struct KMeansNodeSt	{
		/**
		 * The cluster center.
		 */
		float* pivot;
		/**
		 * The cluster radius.
		 */
		float radius;
		/**
		 * The cluster mean radius.
		 */
		float mean_radius;
		/**
		 * The cluster variance.
		 */
		float variance;
		/**
		 * The cluster size (number of points in the cluster)
		 */
		int size;
		/**
		 * Child nodes (only for non-terminal nodes)
		 */
		KMeansNodeSt** childs;
		/**
		 * Node points (only for terminal nodes)
		 */
		int* indices;
		/**
		 * Level
		 */
		int level;
	};
    typedef KMeansNodeSt* KMeansNode;
	


    /**
     * Alias definition for a nicer syntax.
     */
    typedef BranchStruct<KMeansNode> BranchSt;

    /**
     * Priority queue storing intermediate branches in the best-bin-first search
     */
    Heap<BranchSt>* heap;



	/**
	 * The root node in the tree.
	 */
	KMeansNode root;
	
	/**
	 *  Array of indices to vectors in the dataset. 
	 */
	int* indices;


	/**
	 * Pooled memory allocator.
	 * 
	 * Using a pooled memory allocator is more efficient
	 * than allocating memory directly when there is a large
	 * number small of memory allocations.
	 */
	PooledAllocator pool;
	
	/**
	 * Memory occupied by the index.
	 */
	int memoryCounter;
	
	
	/**
	 * Array with distances to the kmeans domains of a node.
	 * Used during search phase.
	 */
	float* domain_distances;
	
    /**
    * The function used for choosing the cluster centers. 
    */
    centersAlgFunction chooseCenters;

	
	
public:

	
	/**
	 * Index constructor
	 * 
	 * Params:
	 * 		inputData = dataset with the input features
	 * 		params = parameters passed to the hierarchical k-means algorithm
	 */
	KMeansTree(Dataset<float>& inputData, Params params) : dataset(inputData), root(NULL), indices(NULL)
	{
		memoryCounter = 0;

        size = dataset.rows;
        veclen = dataset.cols;
	
		// get algorithm parameters
		branching = (int)params["branching"];
		if (branching<2) {
			throw FLANNException("Branching factor must be at least 2");
		}
		int iterations = (int)params["max-iterations"];
		if (iterations<0) {
			iterations =  numeric_limits<int>::max();
		}
		max_iter = iterations;
		
		const char* centersInit = (const char*)params["centers-init"];
		if ( centerAlgs.find(centersInit) != centerAlgs.end() ) {
			chooseCenters = centerAlgs[centersInit];
		}
		else {
			throw FLANNException("Unknown algorithm for choosing initial centers.");
		}
		cb_index = 0.5;
		
		domain_distances = new float[branching];
 		heap = new Heap<BranchSt>(dataset.rows);
	}
	

    void free_centers(KMeansNode node) 
    {
        delete[] node->pivot;
        if (node->childs!=NULL) {
            for (size_t k=0;k<branching;++k) {
                free_centers(node->childs[k]);
            }
        }
    }

	/**
	 * Index destructor.
	 * 
	 * Release the memory used by the index.
	 */
	~KMeansTree()
	{
		if (root != NULL) {
			free_centers(root);
		}
		delete heap;
        if (indices!=NULL) {
		  delete[] indices;
        }
		delete[] domain_distances;
	}

	
	/**
	 * 
	 * Returns: number of trees in the index
	 */
/*	public int numTrees()
	{
		return 1;
	}*/
	
	/**
	 * Computes the inde memory usage
	 * Returns: memory used by the index
	 */
	int usedMemory()
	{
		return  pool.usedMemory+pool.wastedMemory+memoryCounter;
	}

	/**
	 * Builds the index
	 */
	void buildIndex()
	{	
		indices = new int[size];
		for (int i=0;i<size;++i) {
			indices[i] = i;
		}
		
		root = pool.allocate<KMeansNodeSt>();
		computeNodeStatistics(root, indices, size);
		computeClustering(root, indices, size, branching,0);
	}


    /** 
     * Find set of nearest neighbors to vec. Their indices are stored inside
     * the result object. 
     * 
     * Params:
     *     result = the result object in which the indices of the nearest-neighbors are stored 
     *     vec = the vector for which to search the nearest neighbors
     *     maxCheck = the maximum number of restarts (in a best-bin-first manner)
     */
    void findNeighbors(ResultSet& result, float* vec, int maxCheck)
    {
        
        if (maxCheck==-1) {
            findExactNN(root, result, vec);
        }
        else {
            heap->clear();           
            
            findNN(root, result, vec);
            
            int checks = 0;         
            BranchSt branch;
            while (heap->popMin(branch) && (++checks<maxCheck || !result.full())) {
                KMeansNode node = branch.node;      
                findNN(node, result, vec);
            }
            assert(result.full());
        }
        
    }


private:
	/**
	 * Computes the statistics of a node (mean, radius, variance).
	 * 
	 * Params:
	 *     node = the node to use 
	 *     indices = the indices of the points belonging to the node
	 */
	void computeNodeStatistics(KMeansNode node, int* indices, int indices_length) {
	
		float radius = 0;
		float variance = 0;
		float* mean = new float[veclen];
		memoryCounter += veclen*sizeof(float);
		
        memset(mean,0,veclen*sizeof(float));
		
		for (int i=0;i<size;++i) {
			float* vec = dataset[indices[i]];
            for (size_t j=0;j<veclen;++j) {
                mean[j] += vec[j];
            }
			variance += squared_dist(vec,veclen);
		}
		for (int j=0;j<veclen;++j) {
			mean[j] /= size;
		}
		variance /= size;
		variance -= squared_dist(mean,veclen);
		
		float tmp = 0;
		for (int i=0;i<indices_length;++i) {
			tmp = squared_dist(mean, dataset[indices[i]],veclen);
			if (tmp>radius) {
				radius = tmp;
			}
		}
		
		node->variance = variance;
		node->radius = radius;
		node->pivot = mean;
	}
	

	/**
	 * The method responsible with actually doing the recursive hierarchical
	 * clustering
	 * 
	 * Params:
	 *     node = the node to cluster 
	 *     indices = indices of the points belonging to the current node
	 *     branching = the branching factor to use in the clustering
	 *     
	 * TODO: for 1-sized clusters don't store a cluster center (it's the same as the single cluster point)
	 */
	void computeClustering(KMeansNode node, int* indices, int indices_length, int branching, int level)
	{
		node->size = indices_length;
		node->level = level;
		
		if (indices_length < branching) {
			node->indices = indices;
            sort(node->indices,node->indices+indices_length);
            node->childs = NULL;
			return;
		}
		
		float* initial_centers[branching];
        int centers_length;
		chooseCenters(branching, dataset, indices, indices_length, initial_centers, centers_length); 

		if (centers_length<branching) {
            node->indices = indices;
            sort(node->indices,node->indices+indices_length);
            node->childs = NULL;
			return;
		}
		

        Dataset<double> dcenters(branching,veclen);		
        for (size_t i=0; i<centers_length; ++i) {
            for (size_t k=0; k<veclen; ++k) {
                dcenters[i][k] = double(initial_centers[i][k]);
            }
        }
		
	 	float radiuses[branching];
		int count[branching];
		
		// assign points to clusters
		int belongs_to[indices_length];
		for (int i=0;i<indices_length;++i) {

			float sq_dist = squared_dist(dataset[indices[i]],dcenters[0], veclen); 
			belongs_to[i] = 0;
			for (int j=1;j<branching;++j) {
				float new_sq_dist = squared_dist(dataset[indices[i]],dcenters[j], veclen);
				if (sq_dist>new_sq_dist) {
					belongs_to[i] = j;
					sq_dist = new_sq_dist;
				}
			}
			count[belongs_to[i]]++;
		}
		
		bool converged = false;
		int iteration = 0;		
		while (!converged && iteration<max_iter) {
			converged = true;
			iteration++;
			
			// compute the new cluster centers
			for (int i=0;i<branching;++i) {
                memset(dcenters[i],0,sizeof(double)*veclen);
			}
            for (size_t i=0;i<indices_length;++i) {
				float* vec = dataset[indices[i]];
				double* center = dcenters[belongs_to[i]];
				for (size_t k=0;k<veclen;++k) {
					center[k] += vec[k];
 				}
			}
			for (size_t i=0;i<branching;++i) {
                int cnt = count[i];
                for (size_t k=0;k<veclen;++k) {
                    dcenters[i][k] /= cnt;
                }
			}
		    
            memset(radiuses,0,branching*sizeof(float));
			// reassign points to clusters
			for (int i=0;i<indices_length;++i) {
				float sq_dist = squared_dist(dataset[indices[i]],dcenters[0], veclen); 
				int new_centroid = 0;
				for (int j=1;j<branching;++j) {
					float new_sq_dist = squared_dist(dataset[indices[i]],dcenters[j], veclen);
					if (sq_dist>new_sq_dist) {
						new_centroid = j;
						sq_dist = new_sq_dist;
					}
				}
				if (sq_dist>radiuses[new_centroid]) {
					radiuses[new_centroid] = sq_dist;
				}
				if (new_centroid != belongs_to[i]) {
					count[belongs_to[i]]--;
					count[new_centroid]++;
					belongs_to[i] = new_centroid;
					
					converged = false;
				}
			}
			
			for (int i=0;i<branching;++i) {
				// if one cluster converges to an empty cluster,
				// move an element into that cluster
				if (count[i]==0) {
					int j = (i+1)%branching;
					while (count[j]<=1) {
						j = (j+1)%branching;
					}					
					
					for (int k=0;k<indices_length;++k) {
						if (belongs_to[k]==j) {
							belongs_to[k] = i;
							count[j]--;
							count[i]++;
							break;
						}
					}
					converged = false;
				}
			}

		}
        
        float* centers[branching];

        for (size_t i=0; i<branching; ++i) {
 			centers[i] = new float[veclen];
 			memoryCounter += veclen*sizeof(float);
            for (size_t k=0; k<veclen; ++k) {
                centers[i][k] = double(dcenters[i][k]);
            }
 		}	
	
		// compute kmeans clustering for each of the resulting clusters
		node->childs = pool.allocate<KMeansNode>(branching);
		int start = 0;
		int end = start;
		for (int c=0;c<branching;++c) {
			int s = count[c];
			
			float variance = 0;
			float mean_radius =0;
			for (int i=0;i<indices_length;++i) {
				if (belongs_to[i]==c) {
					float d = squared_dist(dataset[indices[i]], veclen);
					variance += d;
					mean_radius += sqrt(d);
					swap(indices[i],indices[end]);
					swap(belongs_to[i],belongs_to[end]);
					end++;
				}
			}
			variance /= s;
			mean_radius /= s;
			variance -= squared_dist(centers[c],veclen);
			
			node->childs[c] = pool.allocate<KMeansNodeSt>();
			node->childs[c]->radius = radiuses[c];
			node->childs[c]->pivot = centers[c];
			node->childs[c]->variance = variance;
			node->childs[c]->mean_radius = mean_radius;
			computeClustering(node->childs[c],indices+start, end-start, branching, level+1);
			start=end;
		}
	}
	
	
	
	/**
	 * Performs one descent in the hierarchical k-means tree. The branches not
	 * visited are stored in a priority queue.
	 */
	void findNN(KMeansNode node, ResultSet& result, float* vec)
	{
		// Ignore those clusters that are too far away
		{
			float bsq = squared_dist(vec, node->pivot, veclen);
			float rsq = node->radius;
			float wsq = result.worstDist();
			
			float val = bsq-rsq-wsq;
			float val2 = val*val-4*rsq*wsq;
			
	 		//if (val>0) {
			if (val>0 && val2>0) {
				return;
			}
		}
	
		if (node->childs==NULL) {			
			for (int i=0;i<branching;++i) {		
				result.addPoint(dataset[node->indices[i]], node->indices[i]);
			}
		} 
		else {
			int closest_center = exploreNodeBranches(node, vec);			
			findNN(node->childs[closest_center],result,vec);
		}		
	}
	
	/**
	 * Helper function that computes the nearest childs of a node to a given query point.
	 * Params:
	 *     node = the node
	 *     q = the query point
	 *     distances = array with the distances to each child node.
	 * Returns:
	 */	
	int exploreNodeBranches(KMeansNode node, float* q)
	{
		
		int best_index = 0;
		domain_distances[best_index] = squared_dist(q,node->childs[best_index]->pivot, veclen); 
		for (int i=1;i<branching;++i) {
			domain_distances[i] = squared_dist(q,node->childs[i]->pivot,veclen);
			if (domain_distances[i]<domain_distances[best_index]) {
				best_index = i;
			}
		}
		
		float* best_center = node->childs[best_index]->pivot;
		for (int i=0;i<branching;++i) {
			if (i != best_index) {
				domain_distances[i] -= cb_index*node->childs[i]->variance;

//				float dist_to_border = getDistanceToBorder(node.childs[i].pivot,best_center,q);
//				if (domain_distances[i]<dist_to_border) {
//					domain_distances[i] = dist_to_border;
//				}
				heap->insert(BranchSt::make_branch(node->childs[i],domain_distances[i]));
			}
		}
		
		return best_index;
	}

	
	/**
	 * Function the performs exact nearest neighbor search by traversing the entire tree. 
	 */
	void findExactNN(KMeansNode node, ResultSet& result, float* vec)
	{
		// Ignore those clusters that are too far away
		{
			float bsq = squared_dist(vec, node->pivot, veclen);
			float rsq = node->radius;
			float wsq = result.worstDist();
			
			float val = bsq-rsq-wsq;
			float val2 = val*val-4*rsq*wsq;
			
	//  		if (val>0) {
			if (val>0 && val2>0) {
				return;
			}
		}
	
	
		if (node->childs==NULL) {			
			for (int i=0;i<branching;++i) {
				result.addPoint(dataset[node->indices[i]], node->indices[i]);
			}	
		} 
		else {
			int sort_indices[branching];
			
			getCenterOrdering(node, vec, sort_indices);

			for (int i=0; i<branching; ++i) {
 				findExactNN(node->childs[sort_indices[i]],result,vec);
			}
		}		
	}


	/**
	 * Helper function. 
	 * 
	 * I computes the order in which to traverse the child nodes of a particular node.
	 */
	void getCenterOrdering(KMeansNode node, float* q, int* sort_indices)
	{
		
//		static float[] domain_distances;
//		if (domain_distances is null) {
//			domain_distances = new float[nc];
//		}
		
		for (int i=0;i<branching;++i) {
			float dist = squared_dist(q,node->childs[i]->pivot,veclen);
			
			int j=0;
			while (domain_distances[j]<dist && j<i) j++;
			for (int k=i;k>j;--k) {
				domain_distances[k] = domain_distances[k-1];
				sort_indices[k] = sort_indices[k-1];
			}
			domain_distances[j] = dist;
			sort_indices[j] = i;
		}		
	}	
	
	/** 
	 * Method that computes the squared distance from the query point q
	 * from inside region with center c to the border between this 
	 * region and the region with center p 
	 */
	float getDistanceToBorder(float* p, float* c, float* q)
	{		
		float sum = 0;
		float sum2 = 0;
		
		for (int i=0;i<veclen; ++i) {
			float t = c[i]-p[i];
			sum += t*(q[i]-(c[i]+p[i])/2);
			sum2 += t*t;
		}
		
		return sum*sum/sum2;
	}
	
	
	/**
	 * Clustering function that takes a cut in the hierarchical k-means
	 * tree and return the clusters centers of that clustering. 
	 * Params:
	 *     numClusters = number of clusters to have in the clustering computed
	 * Returns: number of cluster centers
	 */
	int getClusterCenters(int numClusters, float** centers) 
	{
		if (numClusters<1) {
			throw FLANNException("Number of clusters must be at least 1");
		}		

		float variance;
		KMeansNode clusters[numClusters];

		int clusterCount = getMinVarianceClusters(root, clusters, numClusters, variance);
		
		printf("Mean cluster variance for %d top level clusters: %g",clusterCount,variance);
		
 		for (int i=0;i<clusterCount;++i) {
			centers[i] = clusters[i]->pivot;
		}
		
		return clusterCount;
	}
	

	/**
	 * Helper function the descends in the hierarchical k-means tree by spliting those clusters that minimize
	 * the overall variance of the clustering. 
	 * Params:
	 *     root = root node
	 *     clusters = array with clusters centers (return value)
	 *     varianceValue = variance of the clustering (return value)
	 * Returns:
	 */
	int getMinVarianceClusters(KMeansNode root, KMeansNode* clusters, int clusters_length, float& varianceValue)
	{
		int clusterCount = 1;
		clusters[0] = root;
		
		float meanVariance = root->variance*root->size;
		
		while (clusterCount<clusters_length) {
			float minVariance = numeric_limits<float>::max();
			int splitIndex = -1;
			
			for (int i=0;i<clusterCount;++i) {
				if (clusters[i]->childs != NULL) {
			
					float variance = meanVariance - clusters[i]->variance*clusters[i]->size;
					 
					for (int j=0;j<branching;++j) {
					 	variance += clusters[i]->childs[j]->variance*clusters[i]->childs[j]->size;
					}
					if (variance<minVariance) {
						minVariance = variance;
						splitIndex = i;
					}			
				}
			}
			
			if (splitIndex==-1) break;			
			if ( (branching+clusterCount-1) > clusters_length) break;
			
			meanVariance = minVariance;
			
			// split node
			KMeansNode toSplit = clusters[splitIndex];
			clusters[splitIndex] = toSplit->childs[0];
			for (int i=1;i<branching;++i) {
				clusters[clusterCount++] = toSplit->childs[i];
			}
		}
		
		varianceValue = meanVariance/root->size;
		return clusterCount;
	}
};


