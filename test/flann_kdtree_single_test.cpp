#include <gtest/gtest.h>
#include <time.h>

#include <flann/flann.h>
#include <flann/io/hdf5.h>

#include "flann_tests.h"

using namespace flann;

class KDTreeSingle :public DatasetTestFixture<float, float> {
protected:
	KDTreeSingle() : DatasetTestFixture("cloud.h5") {}
};

TEST_F(KDTreeSingle, TestSearch)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(12, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

TEST_F(KDTreeSingle, TestSearchPadded)
{
    flann::Matrix<float> data_padded;
    flann::load_from_file(data_padded, "cloud.h5", "dataset_padded");
    flann::Matrix<float> data2(data_padded.ptr(), data_padded.rows, 3, data_padded.cols*sizeof(float));

    flann::Index<L2_Simple<float> > index(data2, flann::KDTreeSingleIndexParams(12, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);

    delete[] data_padded.ptr();
}

TEST_F(KDTreeSingle, TestIncremental)
{
    size_t size1 = data.rows/2-1;
    size_t size2 = data.rows-size1;
    Matrix<float> data1(data[0], size1, data.cols);
    Matrix<float> data2(data[size1], size2, data.cols);

    flann::Index<L2_Simple<float> > index(data1, flann::KDTreeSingleIndexParams(12, false));
    start_timer("Building hierarchical clustering index...");
    index.buildIndex();
    index.addPoints(data2);
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}



TEST_F(KDTreeSingle, TestRemove)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(12, false));
    start_timer("Building kd-tree index...");
	index.buildIndex();
	printf("done (%g seconds)\n", stop_timer());

	start_timer("Searching KNN before removing points...");
	index.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
	printf("done (%g seconds)\n", stop_timer());

	// remove about 10% of neighbors found
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

	start_timer("Searching KNN after remove points...");
	index.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
	printf("done (%g seconds)\n", stop_timer());

	for (size_t i=0;i<indices.rows;++i) {
		for (size_t j=0;j<indices.cols;++j) {
			EXPECT_TRUE(neighbors.find(indices[i][j])==neighbors.end());
		}
	}}


TEST_F(KDTreeSingle, TestSave)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(12, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    index.save("kdtree_3d.idx");

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);

    printf("Loading kdtree index\n");
    flann::Index<L2_Simple<float> > index_saved(data, flann::SavedIndexParams("kdtree_3d.idx"));

    start_timer("Searching KNN...");
    index_saved.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    float precision2 = compute_precision(match, indices);
    EXPECT_EQ(precision2, precision);
    printf("Precision: %g\n", precision);
}

TEST_F(KDTreeSingle, TestReorder)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(12, true));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

TEST_F(KDTreeSingle, TestSaveReorder)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(12, true));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    index.save("kdtree_3d.idx");

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);

    printf("Loading kdtree index\n");
    flann::Index<L2_Simple<float> > index_saved(data, flann::SavedIndexParams("kdtree_3d.idx"));

    start_timer("Searching KNN...");
    index_saved.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    float precision2 = compute_precision(match, indices);
    EXPECT_EQ(precision2, precision);
    printf("Precision: %g\n", precision);
}

int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
