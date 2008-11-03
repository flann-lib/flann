#ifndef AUTOTUNE_H
#define AUTOTUNE_H

#include <limits>

#include "Dataset.h"
#include "NNIndex.h"
#include "KMeansTree.h"
#include "KDTree.h"
#include "Timer.h"
#include "Logger.h"
#include "Testing.h"
#include "dist.h"


void find_nearest(const Dataset<float>& dataset, float* query, int* matches, int nn, int skip = 0) 
{
    int n = nn + skip;
    
    long* match = new long[n];
    float* dists = new float[n];
    
    dists[0] = squared_dist(dataset[0], query, dataset.cols);
    int dcnt = 1;
    
    for (int i=1;i<dataset.rows;++i) {
        float tmp = squared_dist(dataset[i], query, dataset.cols);
        
        if (dcnt<n) {
            match[dcnt] = i;   
            dists[dcnt++] = tmp;
        } 
        else if (tmp < dists[dcnt-1]) {
            dists[dcnt-1] = tmp;
            match[dcnt-1] = i;
        } 
        
        int j = dcnt-1;
        // bubble up
        while (j>=1 && dists[j]<dists[j-1]) {
            swap(dists[j],dists[j-1]);
            swap(match[j],match[j-1]);
            j--;
        }
    }
    
    for (int i=0;i<nn;++i) {
        matches[i] = match[i+skip];
    }   
 
    delete[] match;
    delete[] dists;   
}


void compute_ground_truth(const Dataset<float>& dataset, const Dataset<float>& testset, Dataset<int>& matches, int skip=0)
{
    for (int i=0;i<testset.rows;++i) {
        find_nearest(dataset, testset[i], matches[i], matches.cols, skip);
    }
}




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
        float cost;
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
        float searchTime = testNNIndexPrecision<true>(kmeans, *sampledDataset, *testDataset, *gt_matches, desiredPrecision, checks, nn);;
    
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
        float searchTime = testNNIndexPrecision<true>(kdtree, *sampledDataset, *testDataset, *gt_matches, desiredPrecision, checks, nn);
    
        float datasetMemory = sampledDataset->rows*sampledDataset->cols*sizeof(float);
        cost.memoryCost = (kdtree.usedMemory()+datasetMemory)/datasetMemory;
        cost.searchTimeCost = searchTime;
        cost.buildTimeCost = buildTime;
        cost.timeCost = (buildTime*buildTimeFactor+searchTime);
        logger.info("KDTree buildTime=%g, searchTime=%g, timeCost=%g\n",buildTime, searchTime, cost.timeCost);            
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

    
    Params estimateBuildIndexParams(const Dataset<float>& inputDataset, float desiredPrecision_)
    {   

        desiredPrecision = desiredPrecision_;

        // subsample datasets
        int sampleSize = int(samplePercentage*inputDataset.rows);
        int testSampleSize = min(sampleSize/10, 1000);

        Params bestParams;
        float bestCost = numeric_limits<float>::max();

        if (testSampleSize<1) {
            bestParams["algorithm"] = "linear";
            return bestParams;
        }
        // sampling a dataset to use for autotuning
        sampledDataset = inputDataset.sample(sampleSize);    
    
        // sampling a test(query) set
        testDataset = sampledDataset->sample(testSampleSize,true);
                
        logger.info("Sampled dataset size: %d\n",sampledDataset->rows);
        logger.info("Test dataset size: %d\n",testDataset->rows);
        
        logger.info("Computing ground truth... \n");
        gt_matches = new Dataset<int>(testDataset->rows, 1);
        StartStopTimer t;
        t.start();
        compute_ground_truth(*sampledDataset, *testDataset, *gt_matches, 0);
        t.stop();
        float linearTime = t.value;
        
        // Start parameter autotune process
        logger.info("Autotuning parameters...\n");
    
    
        // explore kmeans parameters space
        int maxIterations[] = { 1, 5, 10, 15 };
        int branchingFactors[] = { 16, 32, 64, 128, 256 };
    
        int kmeansParamSpaceSize = ARRAY_LEN(maxIterations)*ARRAY_LEN(branchingFactors);
        CostData* kmeansCosts = new CostData[kmeansParamSpaceSize];
    
        // evaluate kmeans for all parameter combinations
        int cnt = 0;
        for (int i=0; i<ARRAY_LEN(maxIterations); ++i) {
            for (int j=0; j<ARRAY_LEN(branchingFactors); ++j) {
                kmeansCosts[cnt].params["algorithm"] = "kmeans";
                kmeansCosts[cnt].params["centers-init"] = "random";
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
        
        
        // explore kd-tree parameters space
        int testTrees[] = { 1, 4, 8, 16, 32 };
    
        int kdtreeParamSpaceSize = ARRAY_LEN(testTrees);
        CostData* kdtreeCosts = new CostData[kdtreeParamSpaceSize];
        
        // evaluate kdtree for all parameter combinations
        cnt = 0;
        for (int i=0; i<ARRAY_LEN(testTrees); ++i) {
            kdtreeCosts[cnt].params["algorithm"] = "kdtree";
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
        
        
        
        // get the optimum time cost
        float optTimeCost = min(kmeansCosts[0].timeCost, kdtreeCosts[0].timeCost);
        
        if (optTimeCost<1e-6) {
            optTimeCost = 1;
        }
        
        logger.info("Optimum Time Cost = %g\n",optTimeCost);
        
        // recompute total costs taking into account the optimum time cost
        for (int i=0;i<kmeansParamSpaceSize;++i) {
            kmeansCosts[i].cost = (kmeansCosts[i].timeCost/optTimeCost + memoryFactor * kmeansCosts[i].memoryCost);
            
            int k = i;
            while (k>0 && kmeansCosts[k].cost < kmeansCosts[k-1].cost) {
                swap(kmeansCosts[k],kmeansCosts[k-1]);
                k--;
            }
        }
        for (int i=0;i<kmeansParamSpaceSize;++i) {
            logger.info("KMeans, branching=%d, iterations=%d, time_cost=%g[%g] (build=%g, search=%g[speedup: %g]), memory_cost=%g, cost=%g\n", 
                int(kmeansCosts[i].params["branching"]), int(kmeansCosts[i].params["max-iterations"]),
            kmeansCosts[i].timeCost,kmeansCosts[i].timeCost/optTimeCost,
            kmeansCosts[i].buildTimeCost, kmeansCosts[i].searchTimeCost,linearTime/kmeansCosts[i].searchTimeCost,
            kmeansCosts[i].memoryCost,kmeansCosts[i].cost);
        }   

        
//         float kmeansCost = optimizeSimplexDownhill!(int)(kmeans_params[0..3], &compute_kmeans_cost, costs);*/
        float kmeansCost = kmeansCosts[0].cost;
        Params kmeansParams = kmeansCosts[0].params;
        
        delete[] kmeansCosts;

            
        if (kmeansCost<bestCost) {
            bestParams = kmeansParams;
            bestCost = kmeansCost;
        }
        
        for (int i=0;i<kdtreeParamSpaceSize;++i) {
            kdtreeCosts[i].cost = (kdtreeCosts[i].timeCost/optTimeCost + memoryFactor * kdtreeCosts[i].memoryCost);
            
            int k = i;
            while (k>0 && kdtreeCosts[k].cost < kdtreeCosts[k-1].cost) {
                swap(kdtreeCosts[k],kdtreeCosts[k-1]);
                k--;
            }       
        }
        for (int i=0;i<kdtreeParamSpaceSize;++i) {
            logger.info("kd-tree, trees=%d, time_cost=%g[%g] (build=%g, search=%g[speedup: %g]), memory_cost=%g, cost=%g\n",
            int(kdtreeCosts[i].params["trees"]),kdtreeCosts[i].timeCost,kdtreeCosts[i].timeCost/optTimeCost,
            kdtreeCosts[i].buildTimeCost, kdtreeCosts[i].searchTimeCost, linearTime/kdtreeCosts[i].searchTimeCost,
            kdtreeCosts[i].memoryCost,kdtreeCosts[i].cost);
        }   
        
        
//         float kdtreeCost = optimizeSimplexDownhill!(int)(kdtree_params[0..2], &compute_kdtree_cost, kdtre_costs);
        float kdtreeCost = kdtreeCosts[0].cost;
        Params kdtreeParams = kdtreeCosts[0].params;
        
        delete[] kdtreeCosts;
        
        if (kdtreeCost<bestCost) {
            bestParams = kdtreeParams;
            bestCost = kdtreeCost;
        }
        
        logger.info("Best params: \n");
        log_params(LOG_INFO, bestParams);
        
        delete sampledDataset;
        delete testDataset;
        delete gt_matches;
    
        return bestParams;
    }


    
    void estimateSearchParams(NNIndex& index, Dataset<float>& inputDataset, float desiredPrecision, Params& searchParams)
    {
        const int nn = 1;
        const int SAMPLE_COUNT = 1000;
        
        int samples = min(inputDataset.rows/10, SAMPLE_COUNT);
        if (samples>0) {
            Dataset<float>* testDataset = inputDataset.sample(samples, false);

            logger.info("Computing ground truth\n");
            
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
            if (strcmp(index.name(),"kmeans") == 0) {

                logger.info("KMeans algorithm, estimating cluster border factor\n");
                KMeansTree* kmeans = (KMeansTree*)&index;
                float bestSearchTime = -1;
                float best_cb_index = -1;
                int best_checks = -1;
                for (cb_index = 0;cb_index<1.1; cb_index+=0.2) {
                    kmeans->set_cb_index(cb_index);
                    searchTime = testNNIndexPrecision<true>(*kmeans, inputDataset, *testDataset, gt_matches, desiredPrecision, checks, nn, 1);
                    if (searchTime<bestSearchTime || bestSearchTime == -1) {
                        bestSearchTime = searchTime;
                        best_cb_index = cb_index;
                        best_checks = checks;
                    }
                }
                searchTime = bestSearchTime;
                cb_index = best_cb_index;
                checks = best_checks;
            }
            else {
                searchTime = testNNIndexPrecision<true>(index, inputDataset, *testDataset, gt_matches, desiredPrecision, checks, nn, 1);
            }
    
            logger.info("Required number of checks: %d \n",checks);;
            searchParams["checks"] = checks;
            searchParams["speedup"] = (linear/searchTime);
            searchParams["cb_index"] = cb_index;

            delete testDataset;
        }
    }

};

#endif //AUTOTUNE_H
