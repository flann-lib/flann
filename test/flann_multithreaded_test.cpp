#include <gtest/gtest.h>
#include <time.h>

#include <flann/flann.h>
#include <flann/io/hdf5.h>
#include <flann/nn/ground_truth.h>

using namespace flann;

float compute_precision(const flann::Matrix<int>& match, const flann::Matrix<int>& indices)
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


/* Test Fixture which loads the cloud.h5 cloud as data and query matrix */
class FlannTest : public FLANNTestFixture {
protected:
    flann::Matrix<float> data;
    flann::Matrix<float> query;
    flann::Matrix<int> match;
    flann::Matrix<float> dists;
    flann::Matrix<int> indices;

    int nn;

    void SetUp()
    {
        nn = 5;

        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data, "cloud.h5","dataset");
        flann::load_from_file(query,"cloud.h5","query");
        flann::load_from_file(match,"cloud.h5","indices");

        dists = flann::Matrix<float>(new float[query.rows*nn], query.rows, nn);
        indices = flann::Matrix<int>(new int[query.rows*nn], query.rows, nn);

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

    int GetNN() { return nn; }
};

TEST_F(FlannTest, HandlesSingleCoreSearch)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(50, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    int checks = -1;
    float eps = 0.0f;
    bool sorted = true;
    int cores = 1;

    start_timer("Searching KNN...");
    SearchParams params(checks,eps,sorted);
    params.cores = cores;
    index.knnSearch(query, indices, dists, GetNN(), params);
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

TEST_F(FlannTest, HandlesMultiCoreSearch)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(50, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    int checks = -1;
    float eps = 0.0f;
    bool sorted = true;
    int cores = 2;

    start_timer("Searching KNN...");
    SearchParams params(checks,eps,sorted);
    params.cores = cores;
    index.knnSearch(query, indices, dists, GetNN(), params);
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}


/* Test Fixture which loads the cloud.h5 cloud as data and query matrix and holds two dists
   and indices matrices for comparing single and multi core KNN search */
class FlannCompareKnnTest : public FLANNTestFixture {
protected:
    flann::Matrix<float> data;
    flann::Matrix<float> query;
    flann::Matrix<float> dists_single;
    flann::Matrix<int> indices_single;
    flann::Matrix<float> dists_multi;
    flann::Matrix<int> indices_multi;

    int nn;

    void SetUp()
    {
        nn = 5;

        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data, "cloud.h5","dataset");
        flann::load_from_file(query,"cloud.h5","query");

        dists_single = flann::Matrix<float>(new float[query.rows*nn], query.rows, nn);
        indices_single = flann::Matrix<int>(new int[query.rows*nn], query.rows, nn);
        dists_multi = flann::Matrix<float>(new float[query.rows*nn], query.rows, nn);
        indices_multi = flann::Matrix<int>(new int[query.rows*nn], query.rows, nn);

        printf("done\n");
    }

    void TearDown()
    {
        delete[] data.ptr();
        delete[] query.ptr();
        delete[] dists_single.ptr();
        delete[] indices_single.ptr();
        delete[] dists_multi.ptr();
        delete[] indices_multi.ptr();
    }

    int GetNN() { return nn; }
};

TEST_F(FlannCompareKnnTest, CompareMultiSingleCoreKnnSearchSorted)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(50, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    int checks = -1;
    float eps = 0.0f;
    bool sorted = true;
    int single_core = 1;
    int multi_core = -1;

    start_timer("Searching KNN (single core)...");
    SearchParams params(checks,eps,sorted);
    params.cores = single_core;
    int single_neighbor_count = index.knnSearch(query, indices_single, dists_single, GetNN(), params);
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN (multi core)...");
    params.cores = multi_core;
    int multi_neighbor_count = index.knnSearch(query, indices_multi, dists_multi, GetNN(), params);
    printf("done (%g seconds)\n", stop_timer());

    EXPECT_EQ(single_neighbor_count, multi_neighbor_count);

    float precision = compute_precision(indices_single, indices_multi);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

TEST_F(FlannCompareKnnTest, CompareMultiSingleCoreKnnSearchUnsorted)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(50, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    int checks = -1;
    float eps = 0.0f;
    bool sorted = false;
    int single_core = 1;
    int multi_core = -1;

    start_timer("Searching KNN (single core)...");
    SearchParams params(checks,eps,sorted);
    params.cores = single_core;
    int single_neighbor_count = index.knnSearch(query, indices_single, dists_single, GetNN(), params);
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN (multi core)...");
    params.cores = multi_core;
    int multi_neighbor_count = index.knnSearch(query, indices_multi, dists_multi, GetNN(), params);
    printf("done (%g seconds)\n", stop_timer());

    EXPECT_EQ(single_neighbor_count, multi_neighbor_count);

    float precision = compute_precision(indices_single, indices_multi);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}


/* Test Fixture which loads the cloud.h5 cloud as data and query matrix and holds two dists
   and indices matrices for comparing single and multi core radius search */
class FlannCompareRadiusTest : public FLANNTestFixture {
protected:
    flann::Matrix<float> data;
    flann::Matrix<float> query;
    flann::Matrix<float> dists_single;
    flann::Matrix<int> indices_single;
    flann::Matrix<float> dists_multi;
    flann::Matrix<int> indices_multi;

    float radius;

    void SetUp()
    {
        radius = 0.1f;

        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data, "cloud.h5","dataset");
        flann::load_from_file(query,"cloud.h5","query");

        // If the indices / dists matrix cannot contain all points found in the radius, only the points
        // that can be stored in the matrix will be returned and search is stopped. For each query point
        // we reserve as many space as we think is needed. For large point clouds, reserving 'cloudsize'
        // space for each query point might cause memory errors.
        int reserve_size = data.rows / 1000;

        dists_single = flann::Matrix<float>(new float[query.rows*reserve_size], query.rows, reserve_size);
        indices_single = flann::Matrix<int>(new int[query.rows*reserve_size], query.rows, reserve_size);
        dists_multi = flann::Matrix<float>(new float[query.rows*reserve_size], query.rows, reserve_size);
        indices_multi = flann::Matrix<int>(new int[query.rows*reserve_size], query.rows, reserve_size);

        printf("done\n");
    }

    void TearDown()
    {
        delete[] data.ptr();
        delete[] query.ptr();
        delete[] dists_single.ptr();
        delete[] indices_single.ptr();
        delete[] dists_multi.ptr();
        delete[] indices_multi.ptr();
    }

    float GetRadius() { return radius; }
};

TEST_F(FlannCompareRadiusTest, CompareMultiSingleCoreRadiusSearchSorted)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(50, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    int checks = -1;
    float eps = 0.0f;
    bool sorted = true;
    int single_core = 1;
    int multi_core = -1;

    start_timer("Searching Radius (single core)...");
    SearchParams params(checks,eps,sorted);
    params.cores = single_core;
    int single_neighbor_count = index.radiusSearch(query, indices_single, dists_single, GetRadius(), params);
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching Radius (multi core)...");
    params.cores = multi_core;
    int multi_neighbor_count = index.radiusSearch(query, indices_multi, dists_multi, GetRadius(), params);
    printf("done (%g seconds)\n", stop_timer());

    EXPECT_EQ(single_neighbor_count, multi_neighbor_count);

    float precision = compute_precision(indices_single, indices_multi);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

TEST_F(FlannCompareRadiusTest, CompareMultiSingleCoreRadiusSearchUnsorted)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(50, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    int checks = -1;
    float eps = 0.0f;
    bool sorted = false;
    int single_core = 1;
    int multi_core = -1;

    start_timer("Searching Radius (single core)...");
    SearchParams params(checks,eps,sorted);
    params.cores = single_core;
    int single_neighbor_count = index.radiusSearch(query, indices_single, dists_single, GetRadius(), params);
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching Radius (multi core)...");
    params.cores = multi_core;
    int multi_neighbor_count = index.radiusSearch(query, indices_multi, dists_multi, GetRadius(), params);
    printf("done (%g seconds)\n", stop_timer());

    EXPECT_EQ(single_neighbor_count, multi_neighbor_count);

    float precision = compute_precision(indices_single, indices_multi);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}


int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
