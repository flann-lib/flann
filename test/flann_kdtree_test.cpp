#include <gtest/gtest.h>
#include <time.h>

#include <flann/flann.h>
#include <flann/io/hdf5.h>

#include "flann_tests.h"

using namespace flann;

/**
 * Test fixture for SIFT 10K dataset
 */
class KDTree_SIFT10K : public DatasetTestFixture<float, float> {
protected:
	KDTree_SIFT10K() : DatasetTestFixture("sift10K.h5") {}
};

TEST_F(KDTree_SIFT10K, TestSearch)
{
	TestSearch<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256), 0.75, gt_indices);
}

TEST_F(KDTree_SIFT10K, TestAddIncremental)
{
	TestAddIncremental<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256), 0.75, gt_indices);
}

TEST_F(KDTree_SIFT10K, TestAddIncremental2)
{
	TestAddIncremental2<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256), 0.75, gt_indices);
}

TEST_F(KDTree_SIFT10K, TestRemove)
{
	TestRemove<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256) );
}


TEST_F(KDTree_SIFT10K, TestSave)
{
	TestSave<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256), 0.75, gt_indices);
}


TEST_F(KDTree_SIFT10K, TestCopy)
{
	TestCopy<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256), 0.75, gt_indices);
}

TEST_F(KDTree_SIFT10K, TestCopy2)
{
	TestCopy2<KDTreeIndex<L2<float> > >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256), 0.75, gt_indices);
}

/**
 * Test fixture for SIFT 100K dataset
 */
class KDTree_SIFT100K : public DatasetTestFixture<float, float> {
protected:
	KDTree_SIFT100K() : DatasetTestFixture("sift100K.h5") {}
};


TEST_F(KDTree_SIFT100K, TestSearch)
{
	TestSearch<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(128), 0.75, gt_indices);
}


TEST_F(KDTree_SIFT100K, TestAddIncremental)
{
	TestAddIncremental<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256), 0.75, gt_indices);
}



TEST_F(KDTree_SIFT100K, TestAddIncremental2)
{
	TestAddIncremental2<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256), 0.75, gt_indices);
}


TEST_F(KDTree_SIFT100K, TestRemove)
{
	TestRemove<flann::L2<float> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(128) );
}


/**
 * Test fixture for SIFT 10K dataset with byte feature elements
 */
class KDTree_SIFT10K_byte : public DatasetTestFixture<unsigned char, float> {
protected:
	KDTree_SIFT10K_byte() : DatasetTestFixture("sift10K_byte.h5") {}
};


TEST_F(KDTree_SIFT10K_byte, TestSearch)
{
	TestSearch<flann::L2<unsigned char> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(256), 0.75, gt_indices);
}


class KDTree_SIFT100K_byte : public DatasetTestFixture<unsigned char, float> {
protected:
	KDTree_SIFT100K_byte() : DatasetTestFixture("sift100K_byte.h5") {}
};


TEST_F(KDTree_SIFT100K_byte, TestSearch)
{
	TestSearch<flann::L2<unsigned char> >(data, flann::KDTreeIndexParams(4), query, indices,
			dists, knn, flann::SearchParams(128), 0.75, gt_indices);
}


int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
