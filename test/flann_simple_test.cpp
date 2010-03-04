


#include <gtest/gtest.h>
#include <time.h>
#include <flann/flann.h>
#include <flann/io.h>



float compute_precision(const flann::Matrix<int>& match, const flann::Matrix<int>& indices)
{
	int count = 0;

	assert(match.rows == indices.rows);
	size_t nn = std::min(match.cols, indices.cols);

	for(size_t i=0; i<match.rows; ++i) {
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


class Flann_SIFT100K_Test : public ::testing::Test {
protected:
	flann::Matrix<float> data;
	flann::Matrix<float> query;
	flann::Matrix<int> match;
	flann::Matrix<float> dists;
	flann::Matrix<int> indices;

	clock_t start_time_;

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
		data.free();
		query.free();
		match.free();
		dists.free();
		indices.free();
	}

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



TEST_F(Flann_SIFT100K_Test, Linear)
{
	flann::Index index(data, flann::LinearIndexParams());
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
	flann::Index index(data, flann::KDTreeIndexParams(4));
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


TEST_F(Flann_SIFT100K_Test, KMeansTree)
{
	flann::Index index(data, flann::KMeansIndexParams(32, 11, CENTERS_RANDOM, 0.2));
	start_timer("Building hierarchical k-means index...");
	index.buildIndex();
	printf("done (%g seconds)\n", stop_timer());

	start_timer("Searching KNN...");
	index.knnSearch(query, indices, dists, 5, flann::SearchParams(64) );
	printf("done (%g seconds)\n", stop_timer());

	float precision = compute_precision(match, indices);
	EXPECT_GE(precision, 0.72);
	printf("Precision: %g\n", precision);
}


int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
