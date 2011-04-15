/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
 *
 * THE BSD LICENSE
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *************************************************************************/
#ifndef AUTOTUNEDINDEX_H_
#define AUTOTUNEDINDEX_H_

#include "flann/general.h"
#include "flann/algorithms/nn_index.h"
#include "flann/nn/ground_truth.h"
#include "flann/nn/index_testing.h"
#include "flann/util/sampling.h"
#include "flann/algorithms/kdtree_index.h"
#include "flann/algorithms/kdtree_single_index.h"
#include "flann/algorithms/kmeans_index.h"
#include "flann/algorithms/composite_index.h"
#include "flann/algorithms/linear_index.h"

namespace flann
{
typedef ObjectFactory<IndexParams, flann_algorithm_t> ParamsFactory;

template<typename Distance>
NNIndex<Distance>* index_by_type(const Matrix<typename Distance::ElementType>& dataset, const IndexParams& params, const Distance& distance)
{
    flann_algorithm_t index_type = params.getIndexType();

    NNIndex<Distance>* nnIndex;
    switch (index_type) {
    case FLANN_INDEX_LINEAR:
        nnIndex = new LinearIndex<Distance>(dataset, (const LinearIndexParams&)params, distance);
        break;
    case FLANN_INDEX_KDTREE_SINGLE:
        nnIndex = new KDTreeSingleIndex<Distance>(dataset, (const KDTreeSingleIndexParams&)params, distance);
        break;
    case FLANN_INDEX_KDTREE:
        nnIndex = new KDTreeIndex<Distance>(dataset, (const KDTreeIndexParams&)params, distance);
        break;
    case FLANN_INDEX_KMEANS:
        nnIndex = new KMeansIndex<Distance>(dataset, (const KMeansIndexParams&)params, distance);
        break;
    case FLANN_INDEX_COMPOSITE:
        nnIndex = new CompositeIndex<Distance>(dataset, (const CompositeIndexParams&)params, distance);
        break;
    default:
        printf("Index type: %d\n", (int)index_type);
        throw FLANNException("Unknown index type");
    }

    return nnIndex;
}


struct AutotunedIndexParams : public IndexParams
{
    AutotunedIndexParams(float target_precision_ = 0.8, float build_weight_ = 0.01, float memory_weight_ = 0, float sample_fraction_ = 0.1) :
        IndexParams(FLANN_INDEX_AUTOTUNED), target_precision(target_precision_), build_weight(build_weight_), memory_weight(memory_weight_), sample_fraction(sample_fraction_)
    {
    }

    float target_precision;         // precision desired (used for autotuning, -1 otherwise)
    float build_weight;             // build tree time weighting factor
    float memory_weight;            // index memory weighting factor
    float sample_fraction;          // what fraction of the dataset to use for autotuning

    void fromParameters(const FLANNParameters& p)
    {
        assert(p.algorithm == algorithm);
        target_precision = p.target_precision;
        build_weight = p.build_weight;
        memory_weight = p.memory_weight;
        sample_fraction = p.sample_fraction;
    }

    void toParameters(FLANNParameters& p) const
    {
        p.algorithm = algorithm;
        p.target_precision = target_precision;
        p.build_weight = build_weight;
        p.memory_weight = memory_weight;
        p.sample_fraction = sample_fraction;
    }

    void print() const
    {
        logger.info("Index type: %d\n", (int)algorithm);
        logger.info("Target precision: %g\n", target_precision);
        logger.info("Build weight: %g\n", build_weight);
        logger.info("Memory weight: %g\n", memory_weight);
        logger.info("Sample fraction: %g\n", sample_fraction);
    }
};


template <typename Distance>
class AutotunedIndex : public NNIndex<Distance>
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    NNIndex<Distance>* bestIndex;

    IndexParams* bestParams;
    SearchParams bestSearchParams;

    Matrix<ElementType> sampledDataset;
    Matrix<ElementType> testDataset;
    Matrix<int> gt_matches;

    float speedup;

    /**
     * The dataset used by this index
     */
    const Matrix<ElementType> dataset;

    /**
     * Index parameters
     */
    const AutotunedIndexParams index_params;

    Distance distance;
public:

    AutotunedIndex(const Matrix<ElementType>& inputData, const AutotunedIndexParams& params = AutotunedIndexParams(), Distance d = Distance()) :
        dataset(inputData), index_params(params), distance(d)
    {
        bestIndex = NULL;
        bestParams = NULL;
    }

    virtual ~AutotunedIndex()
    {
        if (bestIndex != NULL) {
            delete bestIndex;
            bestIndex = NULL;
        }
        if (bestParams != NULL) {
            delete bestParams;
            bestParams = NULL;
        }
    }

    /**
     *          Method responsible with building the index.
     */
    virtual void buildIndex()
    {
        bestParams = estimateBuildParams();
        logger.info("----------------------------------------------------\n");
        logger.info("Autotuned parameters:\n");
        bestParams->print();
        logger.info("----------------------------------------------------\n");
        flann_algorithm_t index_type = bestParams->getIndexType();
        switch (index_type) {
        case FLANN_INDEX_LINEAR:
            bestIndex = new LinearIndex<Distance>(dataset, (const LinearIndexParams&) *bestParams, distance);
            break;
        case FLANN_INDEX_KDTREE:
            bestIndex = new KDTreeIndex<Distance>(dataset, (const KDTreeIndexParams&) *bestParams, distance);
            break;
        case FLANN_INDEX_KMEANS:
            bestIndex = new KMeansIndex<Distance>(dataset, (const KMeansIndexParams&) *bestParams, distance);
            break;
        default:
            throw FLANNException("Unknown algorithm chosen by the autotuning, most likely a bug.");
        }
        bestIndex->buildIndex();
        speedup = estimateSearchParams(bestSearchParams);
    }

    /**
     *  Saves the index to a stream
     */
    virtual void saveIndex(FILE* stream)
    {
        save_value(stream, (int)bestIndex->getType());
        bestIndex->saveIndex(stream);
        save_value(stream, bestSearchParams);
    }

    /**
     *  Loads the index from a stream
     */
    virtual void loadIndex(FILE* stream)
    {
        int index_type;

        load_value(stream, index_type);
        IndexParams* params = ParamsFactory::instance().create((flann_algorithm_t)index_type);
        bestIndex = index_by_type<Distance>(dataset, *params, distance);
        bestIndex->loadIndex(stream);
        load_value(stream, bestSearchParams);
    }

    /**
     *      Method that searches for nearest-neighbors
     */
    virtual void findNeighbors(ResultSet<DistanceType>& result, const ElementType* vec, const SearchParams& searchParams)
    {
        if (searchParams.checks == FLANN_CHECKS_AUTOTUNED) {
            bestIndex->findNeighbors(result, vec, bestSearchParams);
        }
        else {
            bestIndex->findNeighbors(result, vec, searchParams);
        }
    }


    const IndexParams* getParameters() const
    {
        return bestIndex->getParameters();
    }

    const SearchParams* getSearchParameters() const
    {
        return &bestSearchParams;
    }

    float getSpeedup() const
    {
        return speedup;
    }


    /**
     *      Number of features in this index.
     */
    virtual size_t size() const
    {
        return bestIndex->size();
    }

    /**
     *  The length of each vector in this index.
     */
    virtual size_t veclen() const
    {
        return bestIndex->veclen();
    }

    /**
     * The amount of memory (in bytes) this index uses.
     */
    virtual int usedMemory() const
    {
        return bestIndex->usedMemory();
    }

    /**
     * Algorithm name
     */
    virtual flann_algorithm_t getType() const
    {
        return FLANN_INDEX_AUTOTUNED;
    }

private:

    struct CostData
    {
        float searchTimeCost;
        float buildTimeCost;
        float memoryCost;
        float totalCost;
        IndexParams*    params;
    };

    typedef std::pair<CostData, KDTreeIndexParams> KDTreeCostData;
    typedef std::pair<CostData, KMeansIndexParams> KMeansCostData;


    void evaluate_kmeans(CostData& cost)
    {
        StartStopTimer t;
        int checks;
        const int nn = 1;

        KMeansIndexParams* kmeans_params = (KMeansIndexParams*)cost.params;

        logger.info("KMeansTree using params: max_iterations=%d, branching=%d\n", kmeans_params->iterations, kmeans_params->branching);
        KMeansIndex<Distance> kmeans(sampledDataset, *kmeans_params, distance);
        // measure index build time
        t.start();
        kmeans.buildIndex();
        t.stop();
        float buildTime = t.value;

        // measure search time
        float searchTime = test_index_precision(kmeans, sampledDataset, testDataset, gt_matches, index_params.target_precision, checks, distance, nn);

        float datasetMemory = sampledDataset.rows * sampledDataset.cols * sizeof(float);
        cost.memoryCost = (kmeans.usedMemory() + datasetMemory) / datasetMemory;
        cost.searchTimeCost = searchTime;
        cost.buildTimeCost = buildTime;
        logger.info("KMeansTree buildTime=%g, searchTime=%g, buildTimeFactor=%g\n", buildTime, searchTime, index_params.build_weight);
    }


    void evaluate_kdtree(CostData& cost)
    {
        StartStopTimer t;
        int checks;
        const int nn = 1;

        KDTreeIndexParams* kdtree_params = (KDTreeIndexParams*)cost.params;

        logger.info("KDTree using params: trees=%d\n", kdtree_params->trees);
        KDTreeIndex<Distance> kdtree(sampledDataset, *kdtree_params, distance);

        t.start();
        kdtree.buildIndex();
        t.stop();
        float buildTime = t.value;

        //measure search time
        float searchTime = test_index_precision(kdtree, sampledDataset, testDataset, gt_matches, index_params.target_precision, checks, distance, nn);

        float datasetMemory = sampledDataset.rows * sampledDataset.cols * sizeof(float);
        cost.memoryCost = (kdtree.usedMemory() + datasetMemory) / datasetMemory;
        cost.searchTimeCost = searchTime;
        cost.buildTimeCost = buildTime;
        logger.info("KDTree buildTime=%g, searchTime=%g\n", buildTime, searchTime);
    }


    //    struct KMeansSimpleDownhillFunctor {
    //
    //        Autotune& autotuner;
    //        KMeansSimpleDownhillFunctor(Autotune& autotuner_) : autotuner(autotuner_) {};
    //
    //        float operator()(int* params) {
    //
    //            float maxFloat = numeric_limits<float>::max();
    //
    //            if (params[0]<2) return maxFloat;
    //            if (params[1]<0) return maxFloat;
    //
    //            CostData c;
    //            c.params["algorithm"] = KMEANS;
    //            c.params["centers-init"] = CENTERS_RANDOM;
    //            c.params["branching"] = params[0];
    //            c.params["max-iterations"] = params[1];
    //
    //            autotuner.evaluate_kmeans(c);
    //
    //            return c.timeCost;
    //
    //        }
    //    };
    //
    //    struct KDTreeSimpleDownhillFunctor {
    //
    //        Autotune& autotuner;
    //        KDTreeSimpleDownhillFunctor(Autotune& autotuner_) : autotuner(autotuner_) {};
    //
    //        float operator()(int* params) {
    //            float maxFloat = numeric_limits<float>::max();
    //
    //            if (params[0]<1) return maxFloat;
    //
    //            CostData c;
    //            c.params["algorithm"] = KDTREE;
    //            c.params["trees"] = params[0];
    //
    //            autotuner.evaluate_kdtree(c);
    //
    //            return c.timeCost;
    //
    //        }
    //    };



    void optimizeKMeans(std::vector<CostData>& costs)
    {
        logger.info("KMEANS, Step 1: Exploring parameter space\n");

        // explore kmeans parameters space using combinations of the parameters below
        int maxIterations[] = { 1, 5, 10, 15 };
        int branchingFactors[] = { 16, 32, 64, 128, 256 };

        int kmeansParamSpaceSize = ARRAY_LEN(maxIterations) * ARRAY_LEN(branchingFactors);
        costs.reserve(costs.size() + kmeansParamSpaceSize);

        // evaluate kmeans for all parameter combinations
        for (size_t i = 0; i < ARRAY_LEN(maxIterations); ++i) {
            for (size_t j = 0; j < ARRAY_LEN(branchingFactors); ++j) {
                CostData cost;
                KMeansIndexParams* params = new KMeansIndexParams();
                params->centers_init = FLANN_CENTERS_RANDOM;
                params->iterations = maxIterations[i];
                params->branching = branchingFactors[j];
                cost.params = params;

                evaluate_kmeans(cost);
                costs.push_back(cost);
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
    }


    void optimizeKDTree(std::vector<CostData>& costs)
    {
        logger.info("KD-TREE, Step 1: Exploring parameter space\n");

        // explore kd-tree parameters space using the parameters below
        int testTrees[] = { 1, 4, 8, 16, 32 };

        // evaluate kdtree for all parameter combinations
        for (size_t i = 0; i < ARRAY_LEN(testTrees); ++i) {
            CostData cost;
            KDTreeIndexParams* params = new KDTreeIndexParams();
            params->trees = testTrees[i];
            cost.params = params;

            evaluate_kdtree(cost);
            costs.push_back(cost);
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
    }

    /**
     *  Chooses the best nearest-neighbor algorithm and estimates the optimal
     *  parameters to use when building the index (for a given precision).
     *  Returns a dictionary with the optimal parameters.
     */
    IndexParams* estimateBuildParams()
    {
        std::vector<CostData> costs;

        int sampleSize = int(index_params.sample_fraction * dataset.rows);
        int testSampleSize = std::min(sampleSize / 10, 1000);

        logger.info("Entering autotuning, dataset size: %d, sampleSize: %d, testSampleSize: %d, target precision: %g\n", dataset.rows, sampleSize, testSampleSize, index_params.target_precision);

        // For a very small dataset, it makes no sense to build any fancy index, just
        // use linear search
        if (testSampleSize < 10) {
            logger.info("Choosing linear, dataset too small\n");
            return new LinearIndexParams();
        }

        // We use a fraction of the original dataset to speedup the autotune algorithm
        sampledDataset = random_sample(dataset, sampleSize);
        // We use a cross-validation approach, first we sample a testset from the dataset
        testDataset = random_sample(sampledDataset, testSampleSize, true);

        // We compute the ground truth using linear search
        logger.info("Computing ground truth... \n");
        gt_matches = Matrix<int>(new int[testDataset.rows], testDataset.rows, 1);
        StartStopTimer t;
        t.start();
        compute_ground_truth<Distance>(sampledDataset, testDataset, gt_matches, 0, distance);
        t.stop();

        CostData linear_cost;
        linear_cost.searchTimeCost = t.value;
        linear_cost.buildTimeCost = 0;
        linear_cost.memoryCost = 0;
        linear_cost.params = new LinearIndexParams();

        costs.push_back(linear_cost);

        // Start parameter autotune process
        logger.info("Autotuning parameters...\n");

        optimizeKMeans(costs);
        optimizeKDTree(costs);

        float bestTimeCost = costs[0].searchTimeCost;
        for (size_t i = 0; i < costs.size(); ++i) {
            float timeCost = costs[i].buildTimeCost * index_params.build_weight + costs[i].searchTimeCost;
            if (timeCost < bestTimeCost) {
                bestTimeCost = timeCost;
            }
        }

        float bestCost = costs[0].searchTimeCost / bestTimeCost;
        IndexParams* bestParams = costs[0].params;
        if (bestTimeCost > 0) {
            for (size_t i = 0; i < costs.size(); ++i) {
                float crtCost = (costs[i].buildTimeCost * index_params.build_weight + costs[i].searchTimeCost) / bestTimeCost +
                                index_params.memory_weight * costs[i].memoryCost;
                if (crtCost < bestCost) {
                    bestCost = crtCost;
                    bestParams = costs[i].params;
                }
            }
        }
        // free all parameter structures, except the one returned
        for (size_t i = 0; i < costs.size(); ++i) {
            if (costs[i].params != bestParams) {
                delete costs[i].params;
            }
        }

        gt_matches.free();
        testDataset.free();
        sampledDataset.free();

        return bestParams;
    }



    /**
     *  Estimates the search time parameters needed to get the desired precision.
     *  Precondition: the index is built
     *  Postcondition: the searchParams will have the optimum params set, also the speedup obtained over linear search.
     */
    float estimateSearchParams(SearchParams& searchParams)
    {
        const int nn = 1;
        const size_t SAMPLE_COUNT = 1000;

        assert(bestIndex != NULL); // must have a valid index

        float speedup = 0;

        int samples = std::min(dataset.rows / 10, SAMPLE_COUNT);
        if (samples > 0) {
            Matrix<ElementType> testDataset = random_sample(dataset, samples);

            logger.info("Computing ground truth\n");

            // we need to compute the ground truth first
            Matrix<int> gt_matches(new int[testDataset.rows], testDataset.rows, 1);
            StartStopTimer t;
            t.start();
            compute_ground_truth<Distance>(dataset, testDataset, gt_matches, 1, distance);
            t.stop();
            float linear = t.value;

            int checks;
            logger.info("Estimating number of checks\n");

            float searchTime;
            float cb_index;
            if (bestIndex->getType() == FLANN_INDEX_KMEANS) {
                logger.info("KMeans algorithm, estimating cluster border factor\n");
                KMeansIndex<Distance>* kmeans = (KMeansIndex<Distance>*)bestIndex;
                float bestSearchTime = -1;
                float best_cb_index = -1;
                int best_checks = -1;
                for (cb_index = 0; cb_index < 1.1; cb_index += 0.2) {
                    kmeans->set_cb_index(cb_index);
                    searchTime = test_index_precision(*kmeans, dataset, testDataset, gt_matches, index_params.target_precision, checks, distance, nn, 1);
                    if ((searchTime < bestSearchTime) || (bestSearchTime == -1)) {
                        bestSearchTime = searchTime;
                        best_cb_index = cb_index;
                        best_checks = checks;
                    }
                }
                searchTime = bestSearchTime;
                cb_index = best_cb_index;
                checks = best_checks;

                kmeans->set_cb_index(best_cb_index);
                logger.info("Optimum cb_index: %g\n", cb_index);
                ((KMeansIndexParams*)bestParams)->cb_index = cb_index;
            }
            else {
                searchTime = test_index_precision(*bestIndex, dataset, testDataset, gt_matches, index_params.target_precision, checks, distance, nn, 1);
            }

            logger.info("Required number of checks: %d \n", checks);
            searchParams.checks = checks;

            speedup = linear / searchTime;

            gt_matches.free();
            testDataset.free();
        }

        return speedup;
    }
};
}

#endif /* AUTOTUNEDINDEX_H_ */
