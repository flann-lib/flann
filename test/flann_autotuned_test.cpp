#include <gtest/gtest.h>
#include <time.h>

#include <flann/flann.h>
#include <flann/io/hdf5.h>
#include <flann/nn/ground_truth.h>

#include "flann_tests.h"

using namespace flann;





class Autotuned_SIFT100K : public FLANNTestFixture {
protected:
    flann::Matrix<float> data;
    flann::Matrix<float> query;
    flann::Matrix<size_t> match;
    flann::Matrix<float> dists;
    flann::Matrix<size_t> indices;

    void SetUp()
    {
        dists = flann::Matrix<float>(new float[1000*5], 1000, 5);
        indices = flann::Matrix<size_t>(new size_t[1000*5], 1000, 5);
        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data, "sift100K.h5","dataset");
        flann::load_from_file(query,"sift100K.h5","query");
        flann::load_from_file(match,"sift100K.h5","match");
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


TEST_F(Autotuned_SIFT100K, TestSearch)
{
    flann::log_verbosity(FLANN_LOG_INFO);

    Index<L2<float> > index(data, flann::AutotunedIndexParams(0.8,0.01,0,0.1)); // 80% precision

    start_timer("Building autotuned index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    index.save("autotuned.idx");

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(FLANN_CHECKS_AUTOTUNED) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}


TEST_F(Autotuned_SIFT100K, SavedTest)
{
    float precision;

    // -------------------------------------
    // autotuned index
    printf("Loading autotuned index\n");
    flann::Index<L2<float> > autotuned_index(data, flann::SavedIndexParams("autotuned.idx"));

    const flann::IndexParams index_params = autotuned_index.getParameters();
    printf("The index has the following parameters:\n");
    flann::print_params(index_params);

    printf("Index type is: %d\n", autotuned_index.getType());

    start_timer("Searching KNN...");
    autotuned_index.knnSearch(query, indices, dists, 5, flann::SearchParams(-2) );
    printf("done (%g seconds)\n", stop_timer());

    precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}

TEST_F(Autotuned_SIFT100K, TestCopy)
{
    float precision;

    // -------------------------------------
    // autotuned index
    printf("Loading autotuned index\n");
    flann::Index<L2<float> > index(data, flann::SavedIndexParams("autotuned.idx"));

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(-2) );
    printf("done (%g seconds)\n", stop_timer());

    precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);


    // test copy constructor
    Index<L2<float> > index2(index);

    start_timer("Searching KNN...");
    index2.knnSearch(query, indices, dists, 5, flann::SearchParams(-2) );
    printf("done (%g seconds)\n", stop_timer());

    float precision2 = compute_precision(match, indices);
    printf("Precision: %g\n", precision2);
    EXPECT_EQ(precision, precision2);

    // test assignment operator
    Index<L2<float> > index3(data, flann::LinearIndexParams());
    index3 = index;

    start_timer("Searching KNN...");
    index3.knnSearch(query, indices, dists, 5, flann::SearchParams(-2) );
    printf("done (%g seconds)\n", stop_timer());

    float precision3 = compute_precision(match, indices);
    printf("Precision: %g\n", precision3);
    EXPECT_EQ(precision, precision3);
}


TEST_F(Autotuned_SIFT100K, TestCopy2)
{
    float precision;

    // -------------------------------------
    // autotuned index
    printf("Loading autotuned index\n");
    flann::AutotunedIndex<L2<float> > index(data);
    FILE* f = fopen("autotuned.idx", "r");
    index.loadIndex(f);
    fclose(f);

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(-2) );
    printf("done (%g seconds)\n", stop_timer());

    precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);


    // test copy constructor
    AutotunedIndex<L2<float> > index2(index);

    start_timer("Searching KNN...");
    index2.knnSearch(query, indices, dists, 5, flann::SearchParams(-2) );
    printf("done (%g seconds)\n", stop_timer());

    float precision2 = compute_precision(match, indices);
    printf("Precision: %g\n", precision2);
    EXPECT_EQ(precision, precision2);

    // test assignment operator
    AutotunedIndex<L2<float> > index3(data);
    index3 = index;

    start_timer("Searching KNN...");
    index3.knnSearch(query, indices, dists, 5, flann::SearchParams(-2) );
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
