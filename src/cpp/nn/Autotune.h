/*
Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.

THE BSD LICENSE

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef AUTOTUNE_H
#define AUTOTUNE_H

#include <limits>

#include "constants.h"
#include "Dataset.h"
#include "NNIndex.h"
#include "KMeansTree.h"
#include "KDTree.h"
#include "Timer.h"
#include "Logger.h"
#include "Testing.h"
#include "dist.h"
#include "ground_truth.h"
#include "simplex_downhill.h"



/**
 This class chooses the best nearest-neighbor algorithm and its optimal
parameters.
*/
class Autotune {

    float buildTimeFactor;
    float memoryFactor;
    float samplePercentage;

    Dataset<float>* sampledDataset;
    Dataset<float>* testDataset;
    Dataset<int>* gt_matches;

    float desiredPrecision;

    struct CostData {
        float searchTimeCost;
        float buildTimeCost;
        float timeCost;
        float memoryCost;
        float totalCost;
        Params params;

    };



    void evaluate_kmeans(CostData& cost)
    {
        StartStopTimer t;
        int checks;
        const int nn = 1;

        logger.info("KMeansTree using params: max_iterations=%d, branching=%d\n",int(cost.params["max-iterations"]),int(cost.params["branching"]));
        KMeansTree kmeans(*sampledDataset,cost.params);
        // measure index build time
        t.start();
        kmeans.buildIndex();
        t.stop();
        float buildTime = t.value;

        // measure search time
        float searchTime = test_index_precision(kmeans, *sampledDataset, *testDataset, *gt_matches, desiredPrecision, checks, nn);;

        float datasetMemory = sampledDataset->rows*sampledDataset->cols*sizeof(float);
        cost.memoryCost = (kmeans.usedMemory()+datasetMemory)/datasetMemory;
        cost.searchTimeCost = searchTime;
        cost.buildTimeCost = buildTime;
        cost.timeCost = (buildTime*buildTimeFactor+searchTime);
        logger.info("KMeansTree buildTime=%g, searchTime=%g, timeCost=%g, buildTimeFactor=%g\n",buildTime, searchTime, cost.timeCost, buildTimeFactor);
    }


     void evaluate_kdtree(CostData& cost)
    {
        StartStopTimer t;
        int checks;
        const int nn = 1;

        logger.info("KDTree using params: trees=%d\n",int(cost.params["trees"]));
        KDTree kdtree(*sampledDataset,cost.params);

        t.start();
        kdtree.buildIndex();
        t.stop();
        float buildTime = t.value;

        //measure search time
        float searchTime = test_index_precision(kdtree, *sampledDataset, *testDataset, *gt_matches, desiredPrecision, checks, nn);

        float datasetMemory = sampledDataset->rows*sampledDataset->cols*sizeof(float);
        cost.memoryCost = (kdtree.usedMemory()+datasetMemory)/datasetMemory;
        cost.searchTimeCost = searchTime;
        cost.buildTimeCost = buildTime;
        cost.timeCost = (buildTime*buildTimeFactor+searchTime);
        logger.info("KDTree buildTime=%g, searchTime=%g, timeCost=%g\n",buildTime, searchTime, cost.timeCost);
    }


    struct KMeansSimpleDownhillFunctor {

        Autotune& autotuner;
        KMeansSimpleDownhillFunctor(Autotune& autotuner_) : autotuner(autotuner_) {};

        float operator()(int* params) {

            float maxFloat = numeric_limits<float>::max();

            if (params[0]<2) return maxFloat;
            if (params[1]<0) return maxFloat;

            CostData c;
            c.params["algorithm"] = KMEANS;
            c.params["centers-init"] = CENTERS_RANDOM;
            c.params["branching"] = params[0];
            c.params["max-iterations"] = params[1];

            autotuner.evaluate_kmeans(c);

            return c.timeCost;

        }
    };

    struct KDTreeSimpleDownhillFunctor {

        Autotune& autotuner;
        KDTreeSimpleDownhillFunctor(Autotune& autotuner_) : autotuner(autotuner_) {};

        float operator()(int* params) {
            float maxFloat = numeric_limits<float>::max();

            if (params[0]<1) return maxFloat;

            CostData c;
            c.params["algorithm"] = KDTREE;
            c.params["trees"] = params[0];

            autotuner.evaluate_kdtree(c);

            return c.timeCost;

        }
    };



    CostData optimizeKMeans()
    {
        logger.info("KMEANS, Step 1: Exploring parameter space\n");

        // explore kmeans parameters space using combinations of the parameters below
        int maxIterations[] = { 1, 5, 10, 15 };
        int branchingFactors[] = { 16, 32, 64, 128, 256 };

        int kmeansParamSpaceSize = ARRAY_LEN(maxIterations)*ARRAY_LEN(branchingFactors);
        CostData* kmeansCosts = new CostData[kmeansParamSpaceSize];

        // evaluate kmeans for all parameter combinations
        int cnt = 0;
        for (int i=0; i<ARRAY_LEN(maxIterations); ++i) {
            for (int j=0; j<ARRAY_LEN(branchingFactors); ++j) {
                kmeansCosts[cnt].params["algorithm"] = KMEANS;
                kmeansCosts[cnt].params["centers-init"] = CENTERS_RANDOM;
                kmeansCosts[cnt].params["max-iterations"] = maxIterations[i];
                kmeansCosts[cnt].params["branching"] = branchingFactors[j];

                evaluate_kmeans(kmeansCosts[cnt]);

                int k = cnt;
                // order by time cost
                while (k>0 && kmeansCosts[k].timeCost < kmeansCosts[k-1].timeCost) {
                    swap(kmeansCosts[k],kmeansCosts[k-1]);
                    --k;
                }
                ++cnt;
            }
        }

//         logger.info("KMEANS, Step 2: simplex-downhill optimization\n");
//
//         const int n = 2;
//         // choose initial simplex points as the best parameters so far
//         int kmeansNMPoints[n*(n+1)];
//         float kmeansVals[n+1];
//         for (int i=0;i<n+1;++i) {
//             kmeansNMPoints[i*n] = (int)kmeansCosts[i].params["branching"];
//             kmeansNMPoints[i*n+1] = (int)kmeansCosts[i].params["max-iterations"];
//             kmeansVals[i] = kmeansCosts[i].timeCost;
//         }
//         KMeansSimpleDownhillFunctor kmeans_cost_func(*this);
//         // run optimization
//         optimizeSimplexDownhill(kmeansNMPoints,n,kmeans_cost_func,kmeansVals);
//         // store results
//         for (int i=0;i<n+1;++i) {
//             kmeansCosts[i].params["branching"] = kmeansNMPoints[i*2];
//             kmeansCosts[i].params["max-iterations"] = kmeansNMPoints[i*2+1];
//             kmeansCosts[i].timeCost = kmeansVals[i];
//         }

        float optTimeCost = kmeansCosts[0].timeCost;
        // recompute total costs factoring in the memory costs
        for (int i=0;i<kmeansParamSpaceSize;++i) {
            kmeansCosts[i].totalCost = (kmeansCosts[i].timeCost/optTimeCost + memoryFactor * kmeansCosts[i].memoryCost);

            int k = i;
            while (k>0 && kmeansCosts[k].totalCost < kmeansCosts[k-1].totalCost) {
                swap(kmeansCosts[k],kmeansCosts[k-1]);
                k--;
            }
        }
        // display the costs obtained
        for (int i=0;i<kmeansParamSpaceSize;++i) {
            logger.info("KMeans, branching=%d, iterations=%d, time_cost=%g[%g] (build=%g, search=%g), memory_cost=%g, cost=%g\n",
                int(kmeansCosts[i].params["branching"]), int(kmeansCosts[i].params["max-iterations"]),
            kmeansCosts[i].timeCost,kmeansCosts[i].timeCost/optTimeCost,
            kmeansCosts[i].buildTimeCost, kmeansCosts[i].searchTimeCost,
            kmeansCosts[i].memoryCost,kmeansCosts[i].totalCost);
        }

        CostData bestCost = kmeansCosts[0];
        delete[] kmeansCosts;

        return bestCost;
    }


    CostData optimizeKDTree()
    {

        logger.info("KD-TREE, Step 1: Exploring parameter space\n");

        // explore kd-tree parameters space using the parameters below
        int testTrees[] = { 1, 4, 8, 16, 32 };

        int kdtreeParamSpaceSize = ARRAY_LEN(testTrees);
        CostData* kdtreeCosts = new CostData[kdtreeParamSpaceSize];

        // evaluate kdtree for all parameter combinations
        int cnt = 0;
        for (int i=0; i<ARRAY_LEN(testTrees); ++i) {
            kdtreeCosts[cnt].params["algorithm"] = KDTREE;
            kdtreeCosts[cnt].params["trees"] = testTrees[i];

            evaluate_kdtree(kdtreeCosts[cnt]);

            int k = cnt;
            // order by time cost
            while (k>0 && kdtreeCosts[k].timeCost < kdtreeCosts[k-1].timeCost) {
                swap(kdtreeCosts[k],kdtreeCosts[k-1]);
                --k;
            }
            ++cnt;
        }

//         logger.info("KD-TREE, Step 2: simplex-downhill optimization\n");
//
//         const int n = 1;
//         // choose initial simplex points as the best parameters so far
//         int kdtreeNMPoints[n*(n+1)];
//         float kdtreeVals[n+1];
//         for (int i=0;i<n+1;++i) {
//             kdtreeNMPoints[i] = (int)kdtreeCosts[i].params["trees"];
//             kdtreeVals[i] = kdtreeCosts[i].timeCost;
//         }
//         KDTreeSimpleDownhillFunctor kdtree_cost_func(*this);
//         // run optimization
//         optimizeSimplexDownhill(kdtreeNMPoints,n,kdtree_cost_func,kdtreeVals);
//         // store results
//         for (int i=0;i<n+1;++i) {
//             kdtreeCosts[i].params["trees"] = kdtreeNMPoints[i];
//             kdtreeCosts[i].timeCost = kdtreeVals[i];
//         }

        float optTimeCost = kdtreeCosts[0].timeCost;
        // recompute costs for kd-tree factoring in memory cost
        for (int i=0;i<kdtreeParamSpaceSize;++i) {
            kdtreeCosts[i].totalCost = (kdtreeCosts[i].timeCost/optTimeCost + memoryFactor * kdtreeCosts[i].memoryCost);

            int k = i;
            while (k>0 && kdtreeCosts[k].totalCost < kdtreeCosts[k-1].totalCost) {
                swap(kdtreeCosts[k],kdtreeCosts[k-1]);
                k--;
            }
        }
        // display costs obtained
        for (int i=0;i<kdtreeParamSpaceSize;++i) {
            logger.info("kd-tree, trees=%d, time_cost=%g[%g] (build=%g, search=%g), memory_cost=%g, cost=%g\n",
            int(kdtreeCosts[i].params["trees"]),kdtreeCosts[i].timeCost,kdtreeCosts[i].timeCost/optTimeCost,
            kdtreeCosts[i].buildTimeCost, kdtreeCosts[i].searchTimeCost,
            kdtreeCosts[i].memoryCost,kdtreeCosts[i].totalCost);
        }

        CostData bestCost = kdtreeCosts[0];
        delete[] kdtreeCosts;

        return bestCost;
    }


public:

    Autotune(float buildTimeFactor_, float memoryFactor_, float samplePercentage_ = 0.1) :
        buildTimeFactor(buildTimeFactor_), memoryFactor(memoryFactor_), samplePercentage(samplePercentage_)
    {
        sampledDataset = NULL;
        testDataset = NULL;
    }

    ~Autotune()
    {
    }


    /**
        Chooses the best nearest-neighbor algorithm and estimates the optimal
        parameters to use when building the index (for a given precision).
        Returns a dictionary with the optimal parameters.
    */
    Params estimateBuildIndexParams(const Dataset<float>& inputDataset, float desiredPrecision_)
    {

        desiredPrecision = desiredPrecision_;
        Params bestParams;
        float bestCost = numeric_limits<float>::max();

        int sampleSize = int(samplePercentage*inputDataset.rows);
        int testSampleSize = min(sampleSize/10, 1000);

        logger.info("Enterng autotuning, dataset size: %d, sampleSize: %d, testSampleSize: %d\n",inputDataset.rows, sampleSize, testSampleSize);

        // For a very small dataset, it makes no sense to build any fancy index, just
        // use linear search
        if (testSampleSize<1) {
            logger.info("Choosing linear, dataset too small\n");
            bestParams["algorithm"] = LINEAR;
            return bestParams;
        }

        // We use a fraction of the original dataset to speedup the autotune algorithm
        sampledDataset = inputDataset.sample(sampleSize);
        // We use a cross-validation approach, first we sample a testset from the dataset
        testDataset = sampledDataset->sample(testSampleSize,true);

        // We compute the ground truth using linear search
        logger.info("Computing ground truth... \n");
        gt_matches = new Dataset<int>(testDataset->rows, 1);
        StartStopTimer t;
        t.start();
        compute_ground_truth(*sampledDataset, *testDataset, *gt_matches, 0);
        t.stop();
        float linearTime = t.value;

        // Start parameter autotune process
        logger.info("Autotuning parameters...\n");


        CostData kmeansCost = optimizeKMeans();

        if (kmeansCost.totalCost<bestCost) {
            bestParams = kmeansCost.params;
            bestCost = kmeansCost.totalCost;
        }

        CostData kdtreeCost = optimizeKDTree();

        if (kdtreeCost.totalCost<bestCost) {
            bestParams = kdtreeCost.params;
            bestCost = kdtreeCost.totalCost;
        }


        // display best parameters
        logger.info("Best params: ");
        log_params(LOG_INFO, bestParams);
        logger.info("\n");

        // free the memory used by the datasets we sampled
        delete sampledDataset;
        delete testDataset;
        delete gt_matches;

        return bestParams;
    }



    /**
        Estimates the search time parameters needed to get the desired precision.
        Precondition: the index is built
        Postcondition: the searchParams will have the optimum params set, also the speedup obtained over linear search.
    */
    void estimateSearchParams(NNIndex& index, Dataset<float>& inputDataset, float desiredPrecision, Params& searchParams)
    {
        const int nn = 1;
        const long SAMPLE_COUNT = 1000;

        int samples = min(inputDataset.rows/10, SAMPLE_COUNT);
        if (samples>0) {
            Dataset<float>* testDataset = inputDataset.sample(samples, false);

            logger.info("Computing ground truth\n");

            // we need to compute teh ground truth first
            Dataset<int> gt_matches(testDataset->rows,1);
            StartStopTimer t;
            t.start();
            compute_ground_truth(inputDataset, *testDataset, gt_matches,1);
            t.stop();
            float linear = t.value;

            int checks;
            logger.info("Estimating number of checks\n");

            float searchTime;
            float cb_index;
            if (index.getType() == KMEANS) {

                logger.info("KMeans algorithm, estimating cluster border factor\n");
                KMeansTree* kmeans = (KMeansTree*)&index;
                float bestSearchTime = -1;
                float best_cb_index = -1;
                int best_checks = -1;
                for (cb_index = 0;cb_index<1.1; cb_index+=0.2) {
                    kmeans->set_cb_index(cb_index);
                    searchTime = test_index_precision(*kmeans, inputDataset, *testDataset, gt_matches, desiredPrecision, checks, nn, 1);
                    if (searchTime<bestSearchTime || bestSearchTime == -1) {
                        bestSearchTime = searchTime;
                        best_cb_index = cb_index;
                        best_checks = checks;
                    }
                }
                searchTime = bestSearchTime;
                cb_index = best_cb_index;
                checks = best_checks;

                kmeans->set_cb_index(best_cb_index);
                logger.info("Optimum cb_index: %g\n",cb_index);;
                searchParams["cb_index"] = cb_index;
            }
            else {
                searchTime = test_index_precision(index, inputDataset, *testDataset, gt_matches, desiredPrecision, checks, nn, 1);
            }

            logger.info("Required number of checks: %d \n",checks);;
            searchParams["checks"] = checks;
            if (searchTime < 1e-6) {
            	searchParams["speedup"] = -1;
            } else {
            	searchParams["speedup"] = (linear/searchTime);
            }

            delete testDataset;
        }
    }

};

#endif //AUTOTUNE_H
