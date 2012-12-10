#include <gtest/gtest.h>
#include <time.h>

#include <flann/flann.h>
#include <flann/io/hdf5.h>
#include <flann/nn/ground_truth.h>

using namespace flann;

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

class FLANNTestFixture : public ::testing::Test {
protected:
    timespec ts_;

    void start_timer(const std::string& message = "")
    {
        if (!message.empty()) {
            printf("%s", message.c_str());
            fflush(stdout);
        }
        clock_gettime(CLOCK_REALTIME, &ts_);
    }

    double stop_timer()
    {
		timespec ts2;
        clock_gettime(CLOCK_REALTIME, &ts2);
        return double((ts2.tv_sec-ts_.tv_sec)+(ts2.tv_nsec-ts_.tv_nsec)/1e9);
    }

};


/* Test Fixture which loads the cloud.h5 cloud as data and query matrix */
class FlannTest : public FLANNTestFixture {
protected:
    flann::Matrix<float> data_;
    flann::Matrix<float> query_;
    flann::Matrix<size_t> match_;
    flann::Matrix<float> dists_;
    flann::Matrix<size_t> indices_;

    int knn_;

    void SetUp()
    {
        knn_ = 5;

        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data_, "cloud.h5","dataset");
        flann::load_from_file(query_,"cloud.h5","query");
        flann::load_from_file(match_,"cloud.h5","match");

        dists_ = flann::Matrix<float>(new float[query_.rows*knn_], query_.rows, knn_);
        indices_ = flann::Matrix<size_t>(new size_t[query_.rows*knn_], query_.rows, knn_);

        printf("done\n");
    }

    void TearDown()
    {
        delete[] data_.ptr();
        delete[] query_.ptr();
        delete[] match_.ptr();
        delete[] dists_.ptr();
        delete[] indices_.ptr();
    }

};

TEST_F(FlannTest, HandlesSingleCoreSearch)
{
    flann::Index<L2_Simple<float> > index(data_, flann::KDTreeSingleIndexParams(50, false));
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
    index.knnSearch(query_, indices_, dists_, knn_, params);
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match_, indices_);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

TEST_F(FlannTest, HandlesMultiCoreSearch)
{
    flann::Index<L2_Simple<float> > index(data_, flann::KDTreeSingleIndexParams(50, false));
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
    index.knnSearch(query_, indices_, dists_, knn_, params);
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match_, indices_);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}


/* Test Fixture which loads the cloud.h5 cloud as data and query matrix and holds two dists
   and indices matrices for comparing single and multi core KNN search */
class FlannCompareKnnTest : public FLANNTestFixture {
protected:
    flann::Matrix<float> data_;
    flann::Matrix<float> query_;
    flann::Matrix<float> dists_single_;
    flann::Matrix<size_t> indices_single_;
    flann::Matrix<float> dists_multi_;
    flann::Matrix<size_t> indices_multi_;

    int knn_;

    void SetUp()
    {
        knn_ = 5;

        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data_, "cloud.h5","dataset");
        flann::load_from_file(query_,"cloud.h5","query");

        dists_single_ = flann::Matrix<float>(new float[query_.rows*knn_], query_.rows, knn_);
        indices_single_ = flann::Matrix<size_t>(new size_t[query_.rows*knn_], query_.rows, knn_);
        dists_multi_ = flann::Matrix<float>(new float[query_.rows*knn_], query_.rows, knn_);
        indices_multi_ = flann::Matrix<size_t>(new size_t[query_.rows*knn_], query_.rows, knn_);

        printf("done\n");
    }

    void TearDown()
    {
        delete[] data_.ptr();
        delete[] query_.ptr();
        delete[] dists_single_.ptr();
        delete[] indices_single_.ptr();
        delete[] dists_multi_.ptr();
        delete[] indices_multi_.ptr();
    }

};



TEST_F(FlannCompareKnnTest, CompareMultiSingleCoreKnnSearch)
{
    flann::Index<L2_Simple<float> > index(data_, flann::KDTreeSingleIndexParams(50, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    SearchParams params;
    params.checks = -1;
    params.eps = 0.0f;
    params.sorted = true;

    start_timer("Searching KNN (single core)...");
    params.cores = 1;
    int single_neighbor_count = index.knnSearch(query_, indices_single_, dists_single_, knn_, params);
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN (multi core)...");
    params.cores = 0;
    int multi_neighbor_count = index.knnSearch(query_, indices_multi_, dists_multi_, knn_, params);
    printf("done (%g seconds)\n", stop_timer());

    EXPECT_EQ(single_neighbor_count, multi_neighbor_count);

    printf("Checking results...\n");
    float precision = compute_precision(indices_single_, indices_multi_);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

/* Test Fixture which loads the cloud.h5 cloud as data and query matrix and holds two dists
   and indices matrices for comparing single and multi core radius search */
class FlannCompareRadiusTest : public FLANNTestFixture {
protected:
    flann::Matrix<float> data_;
    flann::Matrix<float> query_;
    flann::Matrix<float> dists_single_;
    flann::Matrix<int> indices_single_;
    flann::Matrix<float> dists_multi_;
    flann::Matrix<int> indices_multi_;

    float radius_;

    void SetUp()
    {
        radius_ = 0.1f;

        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data_, "cloud.h5","dataset");
        flann::load_from_file(query_,"cloud.h5","query");

        int reserve_size = data_.rows / 1000;

        dists_single_ = flann::Matrix<float>(new float[query_.rows*reserve_size], query_.rows, reserve_size);
        indices_single_ = flann::Matrix<int>(new int[query_.rows*reserve_size], query_.rows, reserve_size);
        dists_multi_ = flann::Matrix<float>(new float[query_.rows*reserve_size], query_.rows, reserve_size);
        indices_multi_ = flann::Matrix<int>(new int[query_.rows*reserve_size], query_.rows, reserve_size);

        printf("done\n");
    }

    void TearDown()
    {
        delete[] data_.ptr();
        delete[] query_.ptr();
        delete[] dists_single_.ptr();
        delete[] indices_single_.ptr();
        delete[] dists_multi_.ptr();
        delete[] indices_multi_.ptr();
    }

    void runTest(const flann::Index<L2_Simple<float> >& index, SearchParams params)
    {
        start_timer("Searching Radius (single core)...");
        params.cores = 1;
        int single_neighbor_count = index.radiusSearch(query_, indices_single_, dists_single_, radius_, params);
        printf("done (%g seconds)\n", stop_timer());

        start_timer("Searching Radius (multi core)...");
        params.cores = 0;
        int multi_neighbor_count = index.radiusSearch(query_, indices_multi_, dists_multi_, radius_, params);
        printf("done (%g seconds)\n", stop_timer());

        EXPECT_EQ(single_neighbor_count, multi_neighbor_count);

        printf("Checking results...\n");
        float precision = compute_precision(indices_single_, indices_multi_);
        EXPECT_GE(precision, 0.99);
        printf("Precision: %g\n", precision);
    }
};

TEST_F(FlannCompareRadiusTest, CompareMultiSingleCoreRadiusSearchSorted)
{
    flann::Index<L2_Simple<float> > index(data_, flann::KDTreeSingleIndexParams(50, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    SearchParams params;
    params.checks = -1;
    params.eps = 0.0f;
    params.sorted = true;

    runTest(index, params);
}

TEST_F(FlannCompareRadiusTest, CompareMultiSingleCoreRadiusSearchUnsorted)
{
    flann::Index<L2_Simple<float> > index(data_, flann::KDTreeSingleIndexParams(50, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    SearchParams params;
    params.checks = -1;
    params.eps = 0.0f;
    params.sorted = false;

    runTest(index, params);
}


int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
