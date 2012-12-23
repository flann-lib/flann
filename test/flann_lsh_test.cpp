#include <gtest/gtest.h>
#include <time.h>

#include <flann/flann.h>
#include <flann/io/hdf5.h>

#include "flann_tests.h"

using namespace flann;


class LshIndex_Brief100K : public FLANNTestFixture
{
protected:
	typedef flann::Hamming<unsigned char> Distance;
	typedef Distance::ElementType ElementType;
	typedef Distance::ResultType DistanceType;
	flann::Matrix<unsigned char> data;
	flann::Matrix<unsigned char> query;
	flann::Matrix<size_t> gt_indices;
	flann::Matrix<DistanceType> dists;
	flann::Matrix<DistanceType> gt_dists;
	flann::Matrix<size_t> indices;
	unsigned int k_nn_;

	void SetUp()
	{
		k_nn_ = 3;
		printf("Reading test data...");
		fflush(stdout);
		flann::load_from_file(data, "brief100K.h5", "dataset");
		flann::load_from_file(query, "brief100K.h5", "query");

		dists = flann::Matrix<DistanceType>(new DistanceType[query.rows * k_nn_], query.rows, k_nn_);
		indices = flann::Matrix<size_t>(new size_t[query.rows * k_nn_], query.rows, k_nn_);

		printf("done\n");

		// The matches are bogus so we compute them the hard way
		//    flann::load_from_file(match,"brief100K.h5","indices");

		flann::Index<Distance> index(data, flann::LinearIndexParams());
		index.buildIndex();

		start_timer("Searching KNN for ground truth...");
		gt_indices = flann::Matrix<size_t>(new size_t[query.rows * k_nn_], query.rows, k_nn_);
		gt_dists = flann::Matrix<DistanceType>(new DistanceType[query.rows * k_nn_], query.rows, k_nn_);
		index.knnSearch(query, gt_indices, gt_dists, k_nn_, flann::SearchParams(-1));
		printf("done (%g seconds)\n", stop_timer());
	}

  void TearDown()
  {
    delete[] data.ptr();
    delete[] query.ptr();
    delete[] gt_indices.ptr();
    delete[] gt_dists.ptr();
    delete[] dists.ptr();
    delete[] indices.ptr();
  }
};


TEST_F(LshIndex_Brief100K, TestSearch)
{
	TestSearch<Distance>(data, flann::LshIndexParams(12, 20, 2),
			query, indices, dists, k_nn_, flann::SearchParams(-1), 0.9, gt_indices, gt_dists);
}


TEST_F(LshIndex_Brief100K, TestAddIncremental)
{
	TestAddIncremental<Distance>(data, flann::LshIndexParams(12, 20, 2),
			query, indices, dists, k_nn_, flann::SearchParams(-1), 0.9, gt_indices, gt_dists);
}

TEST_F(LshIndex_Brief100K, TestIncremental2)
{
	TestAddIncremental2<Distance>(data, flann::LshIndexParams(12, 20, 2),
			query, indices, dists, k_nn_, flann::SearchParams(-1), 0.9, gt_indices, gt_dists);
}


TEST_F(LshIndex_Brief100K, TestRemove)
{
	TestRemove<Distance>(data, flann::LshIndexParams(12, 20, 2),
			query, indices, dists, k_nn_, flann::SearchParams(-1));
}


TEST_F(LshIndex_Brief100K, TestSave)
{
	TestSave<Distance>(data, flann::LshIndexParams(12, 20, 2),
			query, indices, dists, k_nn_, flann::SearchParams(-1), 0.9, gt_indices, gt_dists);
}


TEST_F(LshIndex_Brief100K, TestCopy)
{
	TestCopy<Distance>(data, flann::LshIndexParams(12, 20, 2),
			query, indices, dists, k_nn_, flann::SearchParams(-1), 0.9, gt_indices, gt_dists);
}


TEST_F(LshIndex_Brief100K, TestCopy2)
{
	TestCopy2<flann::LshIndex<Distance> >(data, flann::LshIndexParams(12, 20, 2),
			query, indices, dists, k_nn_, flann::SearchParams(-1), 0.9, gt_indices, gt_dists);
}

int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
