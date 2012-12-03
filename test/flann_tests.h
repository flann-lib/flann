/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2012  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2012  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
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


#ifndef FLANN_TESTS_H_
#define FLANN_TESTS_H_

#include <flann/util/matrix.h>
#include <vector>
#include <set>


template<typename T>
float compute_precision(const flann::Matrix<T>& match, const flann::Matrix<T>& indices)
{
    int count = 0;

    assert(match.rows == indices.rows);
    size_t nn = std::min(match.cols, indices.cols);

    for (size_t i=0; i<match.rows; ++i) {
        for (size_t j=0;j<nn;++j) {
            for (size_t k=0;k<nn;++k) {
                if (match[i][j]==indices[i][k]) {
                    count ++;
                }
            }
        }
    }

    return float(count)/(nn*match.rows);
}

/** @brief Compare the distances for match accuracies
 * This is more precise: e.g. when you ask for the top 10 neighbors and they all get the same distance,
 * you might have 100 other neighbors that are at the same distance and simply matching the indices is not the way to go
 * @param gt_dists the ground truth best distances
 * @param dists the distances of the computed nearest neighbors
 * @param tol tolerance at which distanceare considered equal
 * @return
 */
template<typename T>
float computePrecisionDiscrete(const flann::Matrix<T>& gt_dists, const flann::Matrix<T>& dists)
{
  int count = 0;

  assert(gt_dists.rows == dists.rows);
  size_t nn = std::min(gt_dists.cols, dists.cols);
  std::vector<T> gt_sorted_dists(nn), sorted_dists(nn), intersection(nn);

  for (size_t i = 0; i < gt_dists.rows; ++i)
  {
    std::copy(gt_dists[i], gt_dists[i] + nn, gt_sorted_dists.begin());
    std::sort(gt_sorted_dists.begin(), gt_sorted_dists.end());
    std::copy(dists[i], dists[i] + nn, sorted_dists.begin());
    std::sort(sorted_dists.begin(), sorted_dists.end());
    typename std::vector<T>::iterator end = std::set_intersection(gt_sorted_dists.begin(), gt_sorted_dists.end(),
                                                             sorted_dists.begin(), sorted_dists.end(),
                                                             intersection.begin());
    count += (end - intersection.begin());
  }

  return float(count) / (nn * gt_dists.rows);
}


class FLANNTestFixture : public ::testing::Test {
protected:
    clock_t start_time_;

    void start_timer(const std::string& message = "")
    {
        if (!message.empty()) {
            printf("%s", message.c_str());
            fflush(stdout);
        }
        start_time_ = clock();
    }

    double stop_timer()
    {
        return double(clock()-start_time_)/CLOCKS_PER_SEC;
    }

};


template<typename ElementType, typename DistanceType>
class DatasetTestFixture : public FLANNTestFixture
{
protected:

	std::string filename_;

    flann::Matrix<ElementType> data;
    flann::Matrix<ElementType> query;
    flann::Matrix<size_t> match;
    flann::Matrix<DistanceType> dists;
    flann::Matrix<size_t> indices;

    int knn;

    DatasetTestFixture(const std::string& filename) : filename_(filename)
    {
    }


    void SetUp()
    {
        knn = 5;
        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data, filename_.c_str(), "dataset");
        flann::load_from_file(query, filename_.c_str(), "query");
        flann::load_from_file(match, filename_.c_str(), "match");

        dists = flann::Matrix<DistanceType>(new DistanceType[query.rows*knn], query.rows, knn);
        indices = flann::Matrix<size_t>(new size_t[query.rows*knn], query.rows, knn);

        printf("done\n");
    }

    void TearDown()
    {
        delete[] data.ptr();
        delete[] query.ptr();
        delete[] match.ptr();
        delete[] dists.ptr();
        delete[] indices.ptr();

    }
};


#endif /* FLANN_TESTS_H_ */

