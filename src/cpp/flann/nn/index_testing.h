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

#ifndef TESTING_H
#define TESTING_H

#include <cstring>
#include <cassert>

#include "flann/util/matrix.h"
#include "flann/algorithms/nn_index.h"
#include "flann/util/result_set.h"
#include "flann/util/logger.h"


using namespace std;

namespace flann
{

float search_with_ground_truth(NNIndex& index, const Matrix<float>& inputData, const Matrix<float>& testData, const Matrix<int>& matches, int nn, int checks, float& time, float& dist, int skipMatches);

template <typename ELEM_TYPE, typename DIST_TYPE >
void search_for_neighbors(NNIndex& index, const Matrix<ELEM_TYPE>& testset, Matrix<int>& result, Matrix<DIST_TYPE>& dists, const SearchParams &searchParams, int skip = 0)
{
    assert(testset.rows == result.rows);

    int nn = result.cols;
    KNNResultSet resultSet(nn+skip);


    for (size_t i = 0; i < testset.rows; i++) {
        float* target = testset[i];
        resultSet.init(target, testset.cols);

        index.findNeighbors(resultSet,target, searchParams);

        int* neighbors = resultSet.getNeighbors();
        float* distances = resultSet.getDistances();
        memcpy(result[i], neighbors+skip, nn*sizeof(int));
        memcpy(dists[i], distances+skip, nn*sizeof(float));
    }

}

template <typename ELEM_TYPE>
float test_index_checks(NNIndex& index, const Matrix<ELEM_TYPE>& inputData, const Matrix<ELEM_TYPE>& testData, const Matrix<int>& matches,
            int checks, float& precision, int nn = 1, int skipMatches = 0)
{
    logger.info("  Nodes  Precision(%)   Time(s)   Time/vec(ms)  Mean dist\n");
    logger.info("---------------------------------------------------------\n");

    float time = 0;
    float dist = 0;
    precision = search_with_ground_truth(index, inputData, testData, matches, nn, checks, time, dist, skipMatches);

    return time;
}

template <typename ELEM_TYPE>
float test_index_precision(NNIndex& index, const Matrix<ELEM_TYPE>& inputData, const Matrix<ELEM_TYPE>& testData, const Matrix<int>& matches,
             float precision, int& checks, int nn = 1, int skipMatches = 0)
{
	const float SEARCH_EPS = 0.001;

    logger.info("  Nodes  Precision(%)   Time(s)   Time/vec(ms)  Mean dist\n");
    logger.info("---------------------------------------------------------\n");

    int c2 = 1;
    float p2;
    int c1 = 1;
    float p1;
    float time;
    float dist;

    p2 = search_with_ground_truth(index, inputData, testData, matches, nn, c2, time, dist, skipMatches);

    if (p2>precision) {
        logger.info("Got as close as I can\n");
        checks = c2;
        return time;
    }

    while (p2<precision) {
        c1 = c2;
        p1 = p2;
        c2 *=2;
        p2 = search_with_ground_truth(index, inputData, testData, matches, nn, c2, time, dist, skipMatches);
    }

    int cx;
    float realPrecision;
    if (fabs(p2-precision)>SEARCH_EPS) {
        logger.info("Start linear estimation\n");
        // after we got to values in the vecinity of the desired precision
        // use linear approximation get a better estimation

        cx = (c1+c2)/2;
        realPrecision = search_with_ground_truth(index, inputData, testData, matches, nn, cx, time, dist, skipMatches);
        while (fabs(realPrecision-precision)>SEARCH_EPS) {

            if (realPrecision<precision) {
                c1 = cx;
            }
            else {
                c2 = cx;
            }
            cx = (c1+c2)/2;
            if (cx==c1) {
                logger.info("Got as close as I can\n");
                break;
            }
            realPrecision = search_with_ground_truth(index, inputData, testData, matches, nn, cx, time, dist, skipMatches);
        }

        c2 = cx;
        p2 = realPrecision;

    } else {
        logger.info("No need for linear estimation\n");
        cx = c2;
        realPrecision = p2;
    }

    checks = cx;
    return time;
}


template <typename ELEM_TYPE>
float test_index_precisions(NNIndex& index, const Matrix<ELEM_TYPE>& inputData, const Matrix<ELEM_TYPE>& testData, const Matrix<int>& matches,
                    float* precisions, int precisions_length, int nn = 1, int skipMatches = 0, float maxTime = 0)
{
	const float SEARCH_EPS = 0.001;

    // make sure precisions array is sorted
    sort(precisions, precisions+precisions_length);

    int pindex = 0;
    float precision = precisions[pindex];

    logger.info("  Nodes  Precision(%)   Time(s)   Time/vec(ms)  Mean dist");
    logger.info("---------------------------------------------------------");

    int c2 = 1;
    float p2;

    int c1 = 1;
    float p1;

    float time;
    float dist;

    p2 = search_with_ground_truth(index, inputData, testData, matches, nn, c2, time, dist, skipMatches);

    // if precision for 1 run down the tree is already
    // better then some of the requested precisions, then
    // skip those
    while (precisions[pindex]<p2 && pindex<precisions_length) {
        pindex++;
    }

    if (pindex==precisions_length) {
        logger.info("Got as close as I can\n");
        return time;
    }

    for (int i=pindex;i<precisions_length;++i) {

        precision = precisions[i];
        while (p2<precision) {
            c1 = c2;
            p1 = p2;
            c2 *=2;
            p2 = search_with_ground_truth(index, inputData, testData, matches, nn, c2, time, dist, skipMatches);
            if (maxTime> 0 && time > maxTime && p2<precision) return time;
        }

        int cx;
        float realPrecision;
        if (fabs(p2-precision)>SEARCH_EPS) {
            logger.info("Start linear estimation\n");
            // after we got to values in the vecinity of the desired precision
            // use linear approximation get a better estimation

            cx = (c1+c2)/2;
            realPrecision = search_with_ground_truth(index, inputData, testData, matches, nn, cx, time, dist, skipMatches);
            while (fabs(realPrecision-precision)>SEARCH_EPS) {

                if (realPrecision<precision) {
                    c1 = cx;
                }
                else {
                    c2 = cx;
                }
                cx = (c1+c2)/2;
                if (cx==c1) {
                    logger.info("Got as close as I can\n");
                    break;
                }
                realPrecision = search_with_ground_truth(index, inputData, testData, matches, nn, cx, time, dist, skipMatches);
            }

            c2 = cx;
            p2 = realPrecision;

        } else {
            logger.info("No need for linear estimation\n");
            cx = c2;
            realPrecision = p2;
        }

    }
    return time;
}

}

#endif //TESTING_H
