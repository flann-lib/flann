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
	TestSearch<L2_Simple<float> >(data, flann::KDTreeSingleIndexParams(12, false),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);
}

TEST_F(KDTreeSingle, TestSearchPadded)
{
    flann::Matrix<float> data_padded;
    flann::load_from_file(data_padded, "cloud.h5", "dataset_padded");
    flann::Matrix<float> data2(data_padded.ptr(), data_padded.rows, 3, data_padded.cols*sizeof(float));

	TestSearch<L2_Simple<float> >(data2, flann::KDTreeSingleIndexParams(12, false),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);

    delete[] data_padded.ptr();
}

TEST_F(KDTreeSingle, TestAddIncremental)
{
	TestAddIncremental<L2_Simple<float> >(data, flann::KDTreeSingleIndexParams(12, false),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);
}

TEST_F(KDTreeSingle, TestAddIncremental2)
{
	TestAddIncremental2<L2_Simple<float> >(data, flann::KDTreeSingleIndexParams(12, false),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);
}


TEST_F(KDTreeSingle, TestRemove)
{
	TestRemove<L2_Simple<float> >(data, flann::KDTreeSingleIndexParams(12, false),
			query, indices, dists, knn, flann::SearchParams(-1));
}


TEST_F(KDTreeSingle, TestSave)
{
	TestSave<L2_Simple<float> >(data, flann::KDTreeSingleIndexParams(12, false),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);
}

TEST_F(KDTreeSingle, TestSearchReorder)
{
	TestSearch<L2_Simple<float> >(data, flann::KDTreeSingleIndexParams(12, true),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);
}

TEST_F(KDTreeSingle, TestSaveReorder)
{
	TestSave<L2_Simple<float> >(data, flann::KDTreeSingleIndexParams(12, true),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);
}

TEST_F(KDTreeSingle, TestCopy)
{
	TestCopy<L2_Simple<float> >(data, flann::KDTreeSingleIndexParams(12, false),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);

	// repeat tests with reorder=true
	TestCopy<L2_Simple<float> >(data, flann::KDTreeSingleIndexParams(12, true),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);
}

TEST_F(KDTreeSingle, TestCopy2)
{
	TestCopy2<flann::KDTreeSingleIndex<L2_Simple<float> > >(data, flann::KDTreeSingleIndexParams(12, false),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);

	// repeat tests with reorder=true
	TestCopy2<flann::KDTreeSingleIndex<L2_Simple<float> > >(data, flann::KDTreeSingleIndexParams(12, true),
			query, indices, dists, knn, flann::SearchParams(-1), 0.99, gt_indices);
}

TEST_F(KDTreeSingle, TestNoNeighbours)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeSingleIndexParams(12, false));
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());


    float min_dist = dists[0][0];
    for (size_t i=0;i<query.rows;++i) {
    	min_dist = std::min(min_dist, dists[i][0]);
    }

    start_timer("Searching radius smaller than minimum distance...");
    int count = index.radiusSearch(query, indices, dists, min_dist/2, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    EXPECT_EQ(0,count);
    for (size_t i=0;i<dists.rows;++i) {
    	EXPECT_EQ(dists[i][0],std::numeric_limits<float>::infinity());
    }

    std::vector<std::vector<size_t> > indices2;
    std::vector<std::vector<float> > dists2;
    start_timer("Searching radius smaller than minimum distance...");
    int count2 = index.radiusSearch(query, indices2, dists2, min_dist/2, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    EXPECT_EQ(0,count2);
    for (size_t i=0;i<indices2.size();++i) {
    	EXPECT_EQ(indices2[i].size(),0);
    }
}


// Test cases for 3D point clouds, borrowed from PCL test_kdtree
struct MyPoint
{
  MyPoint (float x, float y, float z) {this->x=x; this->y=y; this->z=z;}

  float x,y,z;
};


class KDTreeSinglePointCloud : public FLANNTestFixture
{
public:
	void SetUp()
	{
		float resolution = 0.1f;
		for (float z = -0.5f; z <= 0.5f; z += resolution)
			for (float y = -0.5f; y <= 0.5f; y += resolution)
				for (float x = -0.5f; x <= 0.5f; x += resolution)
					cloud_.push_back (MyPoint (x, y, z));

		cloud_mat_ = flann::Matrix<float>(&cloud_[0].x, cloud_.size(), 3);


		srand(static_cast<unsigned int> (time (NULL)));
		// Randomly create a new point cloud
		for (size_t i = 0; i < 640*480; ++i)
			cloud_big_.push_back (MyPoint (static_cast<float> (1024 * rand () / (RAND_MAX + 1.0)),
					static_cast<float> (1024 * rand () / (RAND_MAX + 1.0)),
					static_cast<float> (1024 * rand () / (RAND_MAX + 1.0))));


		cloud_big_mat_ = flann::Matrix<float>(&cloud_big_[0].x, cloud_big_.size(), 3);
	}

	std::vector<MyPoint> cloud_;
	flann::Matrix<float> cloud_mat_;

	std::vector<MyPoint> cloud_big_;
	flann::Matrix<float> cloud_big_mat_;
};

TEST_F(KDTreeSinglePointCloud, TestRadiusSearch)
{
	std::vector<std::vector<int> > k_indices;
	std::vector<std::vector<float> > k_distances;

	{
	    flann::Index<L2_Simple<float> > index(cloud_mat_, flann::KDTreeSingleIndexParams(12, false));
	    index.buildIndex();

	    L2_Simple<float> euclideanDistance;
		MyPoint test_point(0.0f, 0.0f, 0.0f);
		flann::Matrix<float> test_mat(&test_point.x, 1, 3);
		double max_dist = 0.15*0.15;
		std::set<int> brute_force_result;
		for (unsigned int i=0; i<cloud_mat_.rows; ++i)
			if (euclideanDistance(cloud_mat_[i], test_mat[0], 3) < max_dist)
				brute_force_result.insert(i);
		index.radiusSearch (test_mat, k_indices, k_distances, max_dist, flann::SearchParams(-1));

		for (size_t i = 0; i < k_indices[0].size (); ++i)
		{
			std::set<int>::iterator brute_force_result_it = brute_force_result.find (k_indices[0][i]);
			bool ok = brute_force_result_it != brute_force_result.end ();
			//if (!ok)  cerr << k_indices[i] << " is not correct...\n";
			//else      cerr << k_indices[i] << " is correct...\n";
			EXPECT_EQ (ok, true);
			if (ok)
				brute_force_result.erase (brute_force_result_it);
		}
		//for (set<int>::const_iterator it=brute_force_result.begin(); it!=brute_force_result.end(); ++it)
		//cerr << "FLANN missed "<<*it<<"\n";

		bool error = brute_force_result.size () > 0;
		//if (error)  cerr << "Missed too many neighbors!\n";
		EXPECT_EQ (error, false);
	}

	{
	    flann::Index<L2_Simple<float> > index(flann::KDTreeSingleIndexParams(15));
	    index.buildIndex(cloud_big_mat_);

	    start_timer("radiusSearch...");
	    flann::SearchParams params(-1);
	    index.radiusSearch(cloud_big_mat_, k_indices, k_distances, 0.1*0.1, params);
	    printf("done (%g seconds)\n", stop_timer());
	}

	{
	    flann::Index<L2_Simple<float> > index(flann::KDTreeSingleIndexParams(15));
	    index.buildIndex(cloud_big_mat_);

	    start_timer("radiusSearch (max neighbors in radius)...");
	    flann::SearchParams params(-1);
	    params.max_neighbors = 10;
	    index.radiusSearch(cloud_big_mat_, k_indices, k_distances, 0.1*0.1, params);
	    printf("done (%g seconds)\n", stop_timer());
	}

	{
	    flann::Index<L2_Simple<float> > index(flann::KDTreeSingleIndexParams(15));
	    index.buildIndex(cloud_big_mat_);

	    start_timer("radiusSearch (unsorted results)...");
	    flann::SearchParams params(-1);
	    params.sorted = false;
	    index.radiusSearch(cloud_big_mat_, k_indices, k_distances, 0.1*0.1, params);
	    printf("done (%g seconds)\n", stop_timer());
	}
}


TEST_F(KDTreeSinglePointCloud, TestKNearestSearch)
{
	unsigned int no_of_neighbors = 20;

	{
		flann::Index<L2_Simple<float> > index(cloud_mat_, flann::KDTreeSingleIndexParams(12, false));
		index.buildIndex();

		L2_Simple<float> euclideanDistance;
		MyPoint test_point (0.01f, 0.01f, 0.01f);
		flann::Matrix<float> test_mat(&test_point.x, 1, 3);

		std:: multimap<float, int> sorted_brute_force_result;
		for (size_t i = 0; i < cloud_.size (); ++i)
		{
			float distance = euclideanDistance (cloud_mat_[i], test_mat[0],3);
			sorted_brute_force_result.insert (std::make_pair (distance, static_cast<int> (i)));
		}
		float max_dist = 0.0f;
		unsigned int counter = 0;
		for (std::multimap<float, int>::iterator it = sorted_brute_force_result.begin (); it != sorted_brute_force_result.end () && counter < no_of_neighbors; ++it)
		{
			max_dist = std::max (max_dist, it->first);
			++counter;
		}

		std::vector< std::vector<int> > k_indices(1);
		k_indices[0].resize (no_of_neighbors);
		std::vector<std::vector<float> > k_distances(1);
		k_distances[0].resize (no_of_neighbors);
		index.knnSearch(test_mat, k_indices, k_distances, no_of_neighbors, flann::SearchParams(-1));
		//if (k_indices.size() != no_of_neighbors)  cerr << "Found "<<k_indices.size()<<" instead of "<<no_of_neighbors<<" neighbors.\n";
		EXPECT_EQ (k_indices[0].size (), no_of_neighbors);

		// Check if all found neighbors have distance smaller than max_dist
		for (size_t i = 0; i < k_indices[0].size (); ++i)
		{
			float* point = cloud_mat_[k_indices[0][i]];
			bool ok = euclideanDistance (test_mat[0], point, 3) <= max_dist;
			EXPECT_EQ (ok, true);
		}
	}

	{
		flann::Index<L2_Simple<float> > index(flann::KDTreeSingleIndexParams(15));
		index.buildIndex(cloud_big_mat_);

		start_timer("K nearest neighbour search...");
		flann::SearchParams params(-1);
		params.sorted = false;
		std::vector<std::vector<int> > k_indices;
		std::vector<std::vector<float> > k_distances;
		index.knnSearch (cloud_big_mat_, k_indices, k_distances, no_of_neighbors, params);
		printf("done (%g seconds)\n", stop_timer());
	}

}

int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
