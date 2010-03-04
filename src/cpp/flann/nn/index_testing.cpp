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

#include <algorithm>
#include <math.h>

#include "flann/flann.h"
#include "flann/algorithms/dist.h"
#include "flann/util/common.h"
#include "flann/nn/index_testing.h"
#include "flann/util/timer.h"


namespace flann
{

int countCorrectMatches(int* neighbors, int* groundTruth, int n)
{
    int count = 0;
    for (int i=0;i<n;++i) {
        for (int k=0;k<n;++k) {
            if (neighbors[i]==groundTruth[k]) {
                count++;
                break;
            }
        }
    }
    return count;
}


float computeDistanceRaport(const Matrix<float>& inputData, float* target, int* neighbors, int* groundTruth, int veclen, int n)
{
	float* target_end = target + veclen;
    float ret = 0;
    for (int i=0;i<n;++i) {
        float den = flann_dist(target,target_end, inputData[groundTruth[i]]);
        float num = flann_dist(target,target_end, inputData[neighbors[i]]);

//        printf("den=%g,num=%g\n",den,num);

        if (den==0 && num==0) {
            ret += 1;
        } else {
            ret += num/den;
        }
    }

    return ret;
}

float search_with_ground_truth(NNIndex& index, const Matrix<float>& inputData, const Matrix<float>& testData, const Matrix<int>& matches, int nn, int checks, float& time, float& dist, int skipMatches)
{
    if (matches.cols<size_t(nn)) {
        logger.info("matches.cols=%d, nn=%d\n",matches.cols,nn);

        throw FLANNException("Ground truth is not computed for as many neighbors as requested");
    }

    KNNResultSet resultSet(nn+skipMatches);
    SearchParams searchParams(checks);

    int correct;
    float distR;
    StartStopTimer t;
    int repeats = 0;
    while (t.value<0.2) {
        repeats++;
        t.start();
        correct = 0;
        distR = 0;
        for (size_t i = 0; i < testData.rows; i++) {
            float* target = testData[i];
            resultSet.init(target, testData.cols);
            index.findNeighbors(resultSet,target, searchParams);
            int* neighbors = resultSet.getNeighbors();
            neighbors = neighbors+skipMatches;

            correct += countCorrectMatches(neighbors,matches[i], nn);
            distR += computeDistanceRaport(inputData, target,neighbors,matches[i], testData.cols, nn);
        }
        t.stop();
    }
    time = t.value/repeats;


    float precicion = (float)correct/(nn*testData.rows);

    dist = distR/(testData.rows*nn);

    logger.info("%8d %10.4g %10.5g %10.5g %10.5g\n",
            checks, precicion, time, 1000.0 * time / testData.rows, dist);

    return precicion;
}


}
