#include <gtest/gtest.h>
#include <time.h>

#include <flann/flann.h>
#include <flann/io/hdf5.h>

#include "flann_tests.h"

using namespace flann;

/**
 * Test fixture for SIFT 10K dataset
 */
class Linear_SIFT10K : public DatasetTestFixture<float, float> {
protected:
	Linear_SIFT10K() : DatasetTestFixture("sift10K.h5") {}
};


TEST_F(Linear_SIFT10K, TestSearch)
{
	TestSearch<flann::L2<float> >(data, flann::LinearIndexParams(),
			query, indices, dists, knn, flann::SearchParams(0), 1.0, gt_indices);
}

TEST_F(Linear_SIFT10K, TestRemove)
{
	TestRemove<flann::L2<float> >(data, flann::LinearIndexParams(),
			query, indices, dists, knn, flann::SearchParams(0));
}


TEST_F(Linear_SIFT10K, TestSave)
{
	TestSave<flann::L2<float> >(data, flann::LinearIndexParams(),
			query, indices, dists, knn, flann::SearchParams(0), 1.0, gt_indices);
}

TEST_F(Linear_SIFT10K, TestCopy)
{
	TestCopy<flann::L2<float> >(data, flann::LinearIndexParams(),
			query, indices, dists, knn, flann::SearchParams(0), 1.0, gt_indices);
}


TEST_F(Linear_SIFT10K, TestCopy2)
{
	TestCopy<flann::L2<float> >(data, flann::LinearIndexParams(),
			query, indices, dists, knn, flann::SearchParams(0), 1.0, gt_indices);
}


/**
 * Test fixture for SIFT 100K dataset
 */
class Linear_SIFT100K :  public DatasetTestFixture<float, float> {
protected:
	Linear_SIFT100K() : DatasetTestFixture("sift100K.h5") {}
};


TEST_F(Linear_SIFT100K, TestSearch)
{
	TestSearch<flann::L2<float> >(data, flann::LinearIndexParams(),
			query, indices, dists, knn, flann::SearchParams(0), 1.0, gt_indices);
}


/**
 * Test fixture for SIFT 10K dataset with byte feature elements
 */
class Linear_SIFT10K_byte : public DatasetTestFixture<unsigned char, float> {
protected:
	Linear_SIFT10K_byte() : DatasetTestFixture("sift10K_byte.h5") {}
};



TEST_F(Linear_SIFT10K_byte, Linear)
{
	TestSearch<flann::L2<unsigned char> >(data, flann::LinearIndexParams(),
			query, indices, dists, knn, flann::SearchParams(0), 1.0, gt_indices);
}




class Linear_SIFT100K_byte : public DatasetTestFixture<unsigned char, float> {
protected:
	Linear_SIFT100K_byte() : DatasetTestFixture("sift100K_byte.h5") {}
};



TEST_F(Linear_SIFT100K_byte, TestSearch)
{
	TestSearch<flann::L2<unsigned char> >(data, flann::LinearIndexParams(),
			query, indices, dists, knn, flann::SearchParams(0), 1.0, gt_indices);
}



int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
