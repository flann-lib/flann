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
	flann::Matrix<size_t> match;
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
		match = flann::Matrix<size_t>(new size_t[query.rows * k_nn_], query.rows, k_nn_);
		gt_dists = flann::Matrix<DistanceType>(new DistanceType[query.rows * k_nn_], query.rows, k_nn_);
		index.knnSearch(query, match, gt_dists, k_nn_, flann::SearchParams(-1));
		printf("done (%g seconds)\n", stop_timer());
	}

  void TearDown()
  {
    delete[] data.ptr();
    delete[] query.ptr();
    delete[] match.ptr();
    delete[] gt_dists.ptr();
    delete[] dists.ptr();
    delete[] indices.ptr();
  }
};


TEST_F(LshIndex_Brief100K, TestSearch)
{
    flann::Index<Distance> index(data, flann::LshIndexParams(12, 20, 2));
    start_timer("Building LSH index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1));
    printf("done (%g seconds)\n", stop_timer());

    index.save("lsh_brief.idx");

    float precision = computePrecisionDiscrete(gt_dists, dists);
    EXPECT_GE(precision, 0.9);
    printf("Precision: %g\n", precision);
}


TEST_F(LshIndex_Brief100K, TestIncremental)
{
    size_t size1 = data.rows/2-1;
    size_t size2 = data.rows-size1;
    Matrix<ElementType> data1(data[0], size1, data.cols);
    Matrix<ElementType> data2(data[size1], size2, data.cols);

    flann::Index<Distance> index(data1, flann::LshIndexParams(12, 20, 2));
    start_timer("Building LSH index...");
    index.buildIndex();
    index.addPoints(data2);
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1));
    printf("done (%g seconds)\n", stop_timer());

    float precision = computePrecisionDiscrete(gt_dists, dists);
    EXPECT_GE(precision, 0.9);
    printf("Precision: %g\n", precision);
}

TEST_F(LshIndex_Brief100K, TestIncremental2)
{
    size_t size1 = data.rows/2+1;
    size_t size2 = data.rows-size1;
    Matrix<ElementType> data1(data[0], size1, data.cols);
    Matrix<ElementType> data2(data[size1], size2, data.cols);

    flann::Index<Distance> index(data1, flann::LshIndexParams(12, 20, 2));
    start_timer("Building LSH index...");
    index.buildIndex();
    index.addPoints(data2);
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1));
    printf("done (%g seconds)\n", stop_timer());

    float precision = computePrecisionDiscrete(gt_dists, dists);
    EXPECT_GE(precision, 0.9);
    printf("Precision: %g\n", precision);
}


TEST_F(LshIndex_Brief100K, TestRemove)
{
    flann::Index<Distance> index(data, flann::LshIndexParams(12, 20, 2));
    start_timer("Building LSH index...");
	index.buildIndex();
	printf("done (%g seconds)\n", stop_timer());

	start_timer("Searching KNN before removing points...");
	index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1) );
	printf("done (%g seconds)\n", stop_timer());

	// remove about 50% of neighbors found
	std::set<int> neighbors;
	for (size_t i=0;i<indices.rows;++i) {
		for (size_t j=0;j<indices.cols;++j) {
			if (rand_double()<0.5) {
				neighbors.insert(indices[i][j]);
			}
		}
	}
	for (std::set<int>::iterator it = neighbors.begin(); it!=neighbors.end();++it) {
		index.removePoint(*it);
	}

	// also remove 10% of the initial points
	size_t offset = data.rows/10;
	for (size_t i=0;i<offset;++i) {
		index.removePoint(i);
	}

	start_timer("Searching KNN after remove points...");
	index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1) );
	printf("done (%g seconds)\n", stop_timer());

	for (size_t i=0;i<indices.rows;++i) {
		for (size_t j=0;j<indices.cols;++j) {
			EXPECT_GE(indices[i][j], offset);
			EXPECT_TRUE(neighbors.find(indices[i][j])==neighbors.end());
		}
	}

	// rebuild index
	index.buildIndex();

	start_timer("Searching KNN after remove points and rebuild index...");
	index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(128) );
	printf("done (%g seconds)\n", stop_timer());

	for (size_t i=0;i<indices.rows;++i) {
		for (size_t j=0;j<indices.cols;++j) {
			EXPECT_GE(indices[i][j], offset);
			EXPECT_TRUE(neighbors.find(indices[i][j])==neighbors.end());
		}
	}
}


TEST_F(LshIndex_Brief100K, SavedTest)
{
    printf("Loading hierarchical clustering index\n");
    flann::Index<Distance> index(data, flann::SavedIndexParams("hierarchical_clustering_brief.idx"));

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(2000));
    printf("done (%g seconds)\n", stop_timer());


    float precision = computePrecisionDiscrete(gt_dists, dists);
    EXPECT_GE(precision, 0.9);
    printf("Precision: %g\n", precision);

    printf("Loading lsh index\n");
    flann::Index<Distance> index_lsh(data, flann::SavedIndexParams("lsh_brief.idx"));

    start_timer("Searching KNN...");
    index_lsh.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1));
    printf("done (%g seconds)\n", stop_timer());

    precision = computePrecisionDiscrete(gt_dists, dists);
    EXPECT_GE(precision, 0.9);
    printf("Precision: %g\n", precision);
}


TEST_F(LshIndex_Brief100K, TestCopy)
{
    flann::Index<Distance> index(data, flann::LshIndexParams(12, 20, 2));
    start_timer("Building LSH index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1));
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    printf("Precision: %g\n", precision);
    EXPECT_GE(precision, 0.75);

    // test copy constructor
    flann::Index<Distance> index2(index);

    start_timer("Searching KNN...");
    index2.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1));
    printf("done (%g seconds)\n", stop_timer());

    float precision2 = compute_precision(match, indices);
    printf("Precision: %g\n", precision2);
    EXPECT_EQ(precision, precision2);

    // test assignment operator
    flann::Index<Distance> index3(data, flann::LshIndexParams(12, 20, 2));
    index3 = index;

    start_timer("Searching KNN...");
    index3.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(2000));
    printf("done (%g seconds)\n", stop_timer());

    float precision3 = compute_precision(match, indices);
    printf("Precision: %g\n", precision3);
    EXPECT_EQ(precision, precision3);
}


TEST_F(LshIndex_Brief100K, TestCopy2)
{
    flann::LshIndex<Distance> index(data, flann::LshIndexParams(12, 20, 2));
    start_timer("Building LSH index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1));
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    printf("Precision: %g\n", precision);
    EXPECT_GE(precision, 0.75);

    // test copy constructor
    flann::LshIndex<Distance> index2(index);

    start_timer("Searching KNN...");
    index2.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(-1));
    printf("done (%g seconds)\n", stop_timer());

    float precision2 = compute_precision(match, indices);
    printf("Precision: %g\n", precision2);
    EXPECT_EQ(precision, precision2);

    // test assignment operator
    flann::LshIndex<Distance> index3(data, flann::LshIndexParams(12, 20, 2));
    index3 = index;

    start_timer("Searching KNN...");
    index3.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(2000));
    printf("done (%g seconds)\n", stop_timer());

    float precision3 = compute_precision(match, indices);
    printf("Precision: %g\n", precision3);
    EXPECT_EQ(precision, precision3);
}

int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
