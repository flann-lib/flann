


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

class Flann_SIFT10K_Test : public FLANNTestFixture {
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
        dists = flann::Matrix<float>(new float[1000*nn], 1000, nn);
        indices = flann::Matrix<int>(new int[1000*nn], 1000, nn);
        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data, "sift10K.h5","dataset");
        flann::load_from_file(query,"sift10K.h5","query");
        flann::load_from_file(match,"sift10K.h5","match");
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


TEST_F(Flann_SIFT10K_Test, Linear)
{
    Index<L2<float> > index(data, flann::LinearIndexParams());
    start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, nn, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_EQ(precision, 1.0); // linear search, must be exact
    printf("Precision: %g\n", precision);
}

TEST_F(Flann_SIFT10K_Test, KDTreeTest)
{
    Index<L2<float> > index(data, flann::KDTreeIndexParams(4));
    start_timer("Building randomised kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, nn, flann::SearchParams(256));
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}


TEST_F(Flann_SIFT10K_Test, KMeansTree)
{
    Index<L2<float> > index(data, flann::KMeansIndexParams(7, 3, FLANN_CENTERS_RANDOM, 0.4));
    start_timer("Building hierarchical k-means index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, nn, flann::SearchParams(128) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}


class Flann_SIFT10K_Test_byte : public FLANNTestFixture {
protected:
    flann::Matrix<unsigned char> data;
    flann::Matrix<unsigned char> query;
    flann::Matrix<int> match;
    flann::Matrix<float> dists;
    flann::Matrix<int> indices;

    int nn;

    void SetUp()
    {
        nn = 5;
        dists = flann::Matrix<float>(new float[1000*nn], 1000, nn);
        indices = flann::Matrix<int>(new int[1000*nn], 1000, nn);
        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data, "sift10K_byte.h5","dataset");
        flann::load_from_file(query,"sift10K_byte.h5","query");
        flann::load_from_file(match,"sift10K_byte.h5","match");
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


TEST_F(Flann_SIFT10K_Test_byte, Linear)
{
    flann::Index<L2<unsigned char> > index(data, flann::LinearIndexParams());
    start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, nn, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_EQ(precision, 1.0); // linear search, must be exact
    printf("Precision: %g\n", precision);
}

TEST_F(Flann_SIFT10K_Test_byte, KDTreeTest)
{
    flann::Index<L2<unsigned char> > index(data, flann::KDTreeIndexParams(4));
    start_timer("Building randomised kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, nn, flann::SearchParams(256));
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}


TEST_F(Flann_SIFT10K_Test_byte, KMeansTree)
{
    flann::Index<L2<unsigned char> > index(data, flann::KMeansIndexParams(7, 3, FLANN_CENTERS_RANDOM, 0.4));
    start_timer("Building hierarchical k-means index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, nn, flann::SearchParams(128) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}




class Flann_SIFT100K_Test : public FLANNTestFixture {
protected:
    flann::Matrix<float> data;
    flann::Matrix<float> query;
    flann::Matrix<int> match;
    flann::Matrix<float> dists;
    flann::Matrix<int> indices;

    void SetUp()
    {
        dists = flann::Matrix<float>(new float[1000*5], 1000, 5);
        indices = flann::Matrix<int>(new int[1000*5], 1000, 5);
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


TEST_F(Flann_SIFT100K_Test, Linear)
{
    Index<L2<float> > index(data, flann::LinearIndexParams());
    start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_EQ(precision, 1.0); // linear search, must be exact
    printf("Precision: %g\n", precision);
}


TEST_F(Flann_SIFT100K_Test, KDTreeTest)
{
    Index<L2<float> > index(data, flann::KDTreeIndexParams(4));
    start_timer("Building randomised kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    index.save("kdtree.idx");

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(128) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}

TEST_F(Flann_SIFT100K_Test, KMeansTreeTest)
{
    Index<L2<float> > index(data, flann::KMeansIndexParams(32, 11, FLANN_CENTERS_RANDOM, 0.2));
    start_timer("Building hierarchical k-means index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    index.save("kmeans_tree.idx");

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(96) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}


TEST_F(Flann_SIFT100K_Test, AutotunedTest)
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


TEST_F(Flann_SIFT100K_Test, SavedTest)
{
    float precision;

    // -------------------------------------
    //      kd-tree index
    printf("Loading kdtree index\n");
    flann::Index<L2<float> > kdtree_index(data, flann::SavedIndexParams("kdtree.idx"));

    start_timer("Searching KNN...");
    kdtree_index.knnSearch(query, indices, dists, 5, flann::SearchParams(128) );
    printf("done (%g seconds)\n", stop_timer());

    precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);

    // -------------------------------------
    // kmeans index
    printf("Loading kmeans index\n");
    flann::Index<L2<float> > kmeans_index(data, flann::SavedIndexParams("kmeans_tree.idx"));

    start_timer("Searching KNN...");
    kmeans_index.knnSearch(query, indices, dists, 5, flann::SearchParams(96) );
    printf("done (%g seconds)\n", stop_timer());

    precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);

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



/*
 *
 */
class Flann_SIFT100K_Test_byte : public FLANNTestFixture {
protected:
    flann::Matrix<unsigned char> data;
    flann::Matrix<unsigned char> query;
    flann::Matrix<int> match;
    flann::Matrix<float> dists;
    flann::Matrix<int> indices;

    void SetUp()
    {
        dists = flann::Matrix<float>(new float[1000*5], 1000, 5);
        indices = flann::Matrix<int>(new int[1000*5], 1000, 5);
        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data, "sift100K_byte.h5","dataset");
        flann::load_from_file(query,"sift100K_byte.h5","query");
        flann::load_from_file(match,"sift100K_byte.h5","match");
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


TEST_F(Flann_SIFT100K_Test_byte, Linear)
{
    flann::Index<L2<unsigned char> > index(data, flann::LinearIndexParams());
    start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_EQ(precision, 1.0); // linear search, must be exact
    printf("Precision: %g\n", precision);
}



TEST_F(Flann_SIFT100K_Test_byte, KDTreeTest)
{
    flann::Index<L2<unsigned char> > index(data, flann::KDTreeIndexParams(4));
    start_timer("Building randomised kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(128) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}

TEST_F(Flann_SIFT100K_Test_byte, KMeansTree)
{
    flann::Index<L2<unsigned char> > index(data, flann::KMeansIndexParams(32, 11, FLANN_CENTERS_RANDOM, 0.2));
    start_timer("Building hierarchical k-means index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(80) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.75);
    printf("Precision: %g\n", precision);
}


class Flann_3D : public FLANNTestFixture {
protected:
    flann::Matrix<float> data;
    flann::Matrix<float> query;
    flann::Matrix<int> match;
    flann::Matrix<float> dists;
    flann::Matrix<int> indices;

    void SetUp()
    {
        printf("Reading test data...");
        fflush(stdout);
        flann::load_from_file(data, "cloud.h5","dataset");
        flann::load_from_file(query,"cloud.h5","query");
        flann::load_from_file(match,"cloud.h5","indices");

        dists = flann::Matrix<float>(new float[query.rows*5], query.rows, 5);
        indices = flann::Matrix<int>(new int[query.rows*5], query.rows, 5);
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


TEST_F(Flann_3D, KDTreeSingleTest)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(12, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    index.save("kdtree_3d.idx");

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

TEST_F(Flann_3D, KDTreeSingleTest_Padded)
{
    flann::Matrix<float> data_padded;
    flann::load_from_file(data_padded, "cloud.h5", "dataset_padded");
    flann::Matrix<float> data2(data_padded.ptr(), data_padded.rows, 3, data_padded.cols*sizeof(float));

    flann::Index<L2_Simple<float> > index(data2, flann::KDTreeSingleIndexParams(12, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);

    delete[] data_padded.ptr();
}

TEST_F(Flann_3D, SavedTest)
{
    printf("Loading kdtree index\n");
    flann::Index<L2_Simple<float> > index(data, flann::SavedIndexParams("kdtree_3d.idx"));

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());
    
    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

TEST_F(Flann_3D, KDTreeSingleTestReordered)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(12, true));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    index.save("kdtree_3d.idx");

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

TEST_F(Flann_3D, SavedTest2)
{
    printf("Loading kdtree index\n");
    flann::Index<L2_Simple<float> > index(data, flann::SavedIndexParams("kdtree_3d.idx"));

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());
    
    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Flann_Brief100K_Test : public FLANNTestFixture
{
protected:
  typedef flann::Hamming<unsigned char> Distance;
  typedef Distance::ElementType ElementType;
  typedef Distance::ResultType DistanceType;
  flann::Matrix<unsigned char> data;
  flann::Matrix<unsigned char> query;
  flann::Matrix<int> match;
  flann::Matrix<DistanceType> dists;
  flann::Matrix<DistanceType> gt_dists;
  flann::Matrix<int> indices;
  unsigned int k_nn_;

  void SetUp()
  {
    k_nn_ = 3;
    printf("Reading test data...");
    fflush(stdout);
    flann::load_from_file(data, "brief100K.h5", "dataset");
    flann::load_from_file(query, "brief100K.h5", "query");

    dists = flann::Matrix<DistanceType>(new DistanceType[query.rows * k_nn_], query.rows, k_nn_);
    indices = flann::Matrix<int>(new int[query.rows * k_nn_], query.rows, k_nn_);

    printf("done\n");

    // The matches are bogus so we compute them the hard way
//    flann::load_from_file(match,"brief100K.h5","indices");

    flann::Index<Distance> index(data, flann::LinearIndexParams());
    index.buildIndex();

    start_timer("Searching KNN for ground truth...");
    match = flann::Matrix<int>(new int[query.rows * k_nn_], query.rows, k_nn_);
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

TEST_F(Flann_Brief100K_Test, HierarchicalClusteringTest)
{
    flann::Index<Distance> index(data, flann::HierarchicalClusteringIndexParams());
    start_timer("Building hierarchical clustering index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, k_nn_, flann::SearchParams(2000));
    printf("done (%g seconds)\n", stop_timer());

    index.save("hierarchical_clustering_brief.idx");

    float precision = computePrecisionDiscrete(gt_dists, dists);
    EXPECT_GE(precision, 0.9);
    printf("Precision: %g\n", precision);
}

TEST_F(Flann_Brief100K_Test, LshTest)
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

TEST_F(Flann_Brief100K_Test, SavedTest)
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


int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
