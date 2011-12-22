#include <gtest/gtest.h>
#include <time.h>
#define FLANN_USE_CUDA
#include <flann/flann.h>
#include <flann/io/hdf5.h>
#include <flann/nn/ground_truth.h>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <vector_functions.h>

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
                else
				{
// 					std::cout<<i<<":"<<match[i][j]<<"!="<<indices[i][k]<<std::endl;
				}
            }
        }
    }

    return float(count)/(nn*match.rows);
}

struct smallerWithTolerance
{
	float tol;
	bool operator()(float a, float b )
	{
		return a<(b-tol);
	}
};

/** @brief Compare the distances for match accuracies
 * This is more precise: e.g. when you ask for the top 10 neighbors and they all get the same distance,
 * you might have 100 other neighbors that are at the same distance and simply matching the indices is not the way to go
 * @param gt_dists the ground truth best distances
 * @param dists the distances of the computed nearest neighbors
 * @param tol tolerance at which distanceare considered equal
 * @return
 */
template<typename T>
float computePrecisionDiscrete(const flann::Matrix<T>& gt_dists, const flann::Matrix<T>& dists, float tol)
{
  int count = 0;

  assert(gt_dists.rows == dists.rows);
  size_t nn = std::min(gt_dists.cols, dists.cols);
  std::vector<T> gt_sorted_dists(nn), sorted_dists(nn), intersection(nn);

  smallerWithTolerance swt;
  swt.tol=tol;
  for (size_t i = 0; i < gt_dists.rows; ++i)
  {
    std::copy(gt_dists[i], gt_dists[i] + nn, gt_sorted_dists.begin());
    std::sort(gt_sorted_dists.begin(), gt_sorted_dists.end());
    std::copy(dists[i], dists[i] + nn, sorted_dists.begin());
    std::sort(sorted_dists.begin(), sorted_dists.end());
    typename std::vector<T>::iterator end = std::set_intersection(gt_sorted_dists.begin(), gt_sorted_dists.end(),
                                                             sorted_dists.begin(), sorted_dists.end(),
                                                             intersection.begin(),swt);
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

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}


TEST_F(Flann_3D, KDTreeCudaTest)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeCuda3dIndexParams());
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(-1) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
}


class Flann_3D_Random_Cloud : public FLANNTestFixture {
protected:
    flann::Matrix<float> data;
    flann::Matrix<float> query;
    flann::Matrix<float> dists;
    flann::Matrix<int> indices;
	flann::Matrix<float> gt_dists;
	flann::Matrix<int> gt_indices;

    void SetUp()
    {
		const int n_points=10000;
		printf("creating random point cloud (%d points)...", n_points);
		data = flann::Matrix<float>(new float[n_points*3], n_points, 3);
		srand(1);
		for( int i=0; i<n_points; i++ )
		{
			data[i][0]=rand()/float(RAND_MAX);
			data[i][1]=rand()/float(RAND_MAX);
			data[i][2]=rand()/float(RAND_MAX);
// 			std::cout<<data[i][0]<<" "<<data[i][1]<<" "<<data[i][2]<<std::endl;
		}
		
		query= flann::Matrix<float>(new float[n_points*3], n_points, 3);
		for( int i=0; i<n_points; i++ )
		{
			query[i][0]=data[i][0];//float(rand())/RAND_MAX;
			query[i][1]=data[i][1];//float(rand())/RAND_MAX;
			query[i][2]=data[i][2];//float(rand())/RAND_MAX;
// 			std::cout<<query[i][0]<<" "<<query[i][1]<<" "<<query[i][2]<<std::endl;
		}
		
		
        printf("done\n");
		
		const int max_nn = 16;
		
        dists = flann::Matrix<float>(new float[query.rows*max_nn], query.rows, max_nn);
		gt_dists = flann::Matrix<float>(new float[query.rows*max_nn], query.rows, max_nn);
        indices = flann::Matrix<int>(new int[query.rows*max_nn], query.rows, max_nn);
		gt_indices = flann::Matrix<int>(new int[query.rows*max_nn], query.rows, max_nn);
		
		
		Index<L2<float> > index(data, flann::LinearIndexParams());
		start_timer("Building linear index...");
		index.buildIndex();
		printf("done (%g seconds)\n", stop_timer());
		
		start_timer("Searching KNN...");
		index.knnSearch(data, gt_indices, gt_dists, max_nn, flann::SearchParams() );
// 		for( int i=0; i<gt_dists.rows; i++ )
// 		{
// 			std::cout<<gt_indices[i][0]<<" "<<gt_dists[i][0]<<std::endl;
// 		}
		printf("done (%g seconds)\n", stop_timer());
    }

    void TearDown()
    {
        delete[] data.ptr();
        delete[] query.ptr();
        delete[] dists.ptr();
		delete[] gt_dists.ptr();
        delete[] indices.ptr();
		delete[] gt_indices.ptr();
		
    }
};

TEST_F(Flann_3D_Random_Cloud, Test1NN)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeCuda3dIndexParams());
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
	indices.cols=1;
	dists.cols=1;
    index.knnSearch(query, indices, dists, 1, flann::SearchParams() );
    printf("done (%g seconds)\n", stop_timer());

//     float precision = compute_precision(gt_indices,indices);
	float precision = computePrecisionDiscrete(gt_dists,dists, 0);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
	
}

TEST_F(Flann_3D_Random_Cloud, Test4NN)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeCuda3dIndexParams());
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
	indices.cols=4;
	dists.cols=4;
    index.knnSearch(query, indices, dists, 4, flann::SearchParams() );
    printf("done (%g seconds)\n", stop_timer());

//     float precision = compute_precision(gt_indices,indices);
	float precision = computePrecisionDiscrete(gt_dists,dists, 1e-08);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
	
}

TEST_F(Flann_3D_Random_Cloud, Test4NNGpuBuffers)
{
	thrust::host_vector<float4> data_host(data.rows);
	for( int i=0; i<data.rows; i++ )
	{
		data_host[i]=make_float4(data[i][0],data[i][1],data[i][2],0);
	}
	thrust::device_vector<float4> data_device = data_host;
	thrust::host_vector<float4> query_host(data.rows);
	for( int i=0; i<data.rows; i++ )
	{
		query_host[i]=make_float4(query[i][0],query[i][1],query[i][2],0);
	}
	thrust::device_vector<float4> query_device = query_host;
	
	flann::Matrix<float> data_device_matrix( (float*)thrust::raw_pointer_cast(&data_device[0]),data.rows,3,4*4);
	flann::Matrix<float> query_device_matrix( (float*)thrust::raw_pointer_cast(&query_device[0]),data.rows,3,4*4);
	
	flann::KDTreeCuda3dIndexParams index_params;
	index_params["input_is_gpu_float4"]=true;
	flann::Index<L2_Simple<float> > index(data_device_matrix, index_params);
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

	
	thrust::device_vector<int> indices_device(query.rows*4);
	thrust::device_vector<float> dists_device(query.rows*4);
	flann::Matrix<int> indices_device_matrix( (int*)thrust::raw_pointer_cast(&indices_device[0]),query.rows,4);
	flann::Matrix<float> dists_device_matrix( (float*)thrust::raw_pointer_cast(&dists_device[0]),query.rows,4);
	
    start_timer("Searching KNN...");
	indices.cols=4;
	dists.cols=4;
	flann::SearchParams sp;
	sp.matrices_in_gpu_ram=true;
    index.knnSearch(query_device_matrix, indices_device_matrix, dists_device_matrix, 4, sp );
    printf("done (%g seconds)\n", stop_timer());
	
	flann::Matrix<int> indices_host( new int[ query.rows*4],query.rows,4 );
	flann::Matrix<float> dists_host( new float[ query.rows*4],query.rows,4 );
	
	thrust::copy( dists_device.begin(), dists_device.end(), dists_host.ptr() );
	thrust::copy( indices_device.begin(), indices_device.end(), indices_host.ptr() );

//     float precision = compute_precision(gt_indices,indices);
	float precision = computePrecisionDiscrete(gt_dists,dists_host, 1e-08);
    EXPECT_GE(precision, 0.99);
    printf("Precision: %g\n", precision);
	delete [] indices_host.ptr();
	delete [] dists_host.ptr();
}

TEST_F(Flann_3D_Random_Cloud, TestRadiusSearchVector)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeCuda3dIndexParams());
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());
	float r = 0.1;
	std::vector< std::vector<int> > indices;
	std::vector< std::vector<float> > dists;
	start_timer("Radius search, r=0.1");
	index.radiusSearch( query, indices,dists, r*r, flann::SearchParams() );
	printf("done (%g seconds)", stop_timer());

	start_timer("verifying results...");
	for( int i=0; i<query.rows; i++ )
	{
		for( int j=0; j<data.rows; j++ )
		{
			float dist = 0;
			for( int k=0; k<3; k++ )
				dist += (query[i][k]-data[j][k])*(query[i][k]-data[j][k]);
			if( dist < r*r )
			{
				EXPECT_TRUE( std::find( indices[i].begin(), indices[i].end(), j )!=indices[i].end() );
			}
			else
			{
				EXPECT_TRUE( std::find( indices[i].begin(), indices[i].end(), j )==indices[i].end() );
			}
		}
	}
	printf("done (%g seconds)\n", stop_timer());
	
	r=0.05;
	start_timer("Radius search, r=0.05");
	index.radiusSearch( query, indices,dists, r*r, flann::SearchParams() );
	printf("done (%g seconds)", stop_timer());
	
	start_timer("verifying results...");
	for( int i=0; i<query.rows; i++ )
	{
		for( int j=0; j<data.rows; j++ )
		{
			// for each pair of query and data points: either the distance between them
			// is smaller than r AND the point is in the result set, or 
			// the distance is larger and it is not.
			float dist = 0;
			for( int k=0; k<3; k++ )
				dist += (query[i][k]-data[j][k])*(query[i][k]-data[j][k]);
			if( dist < r*r )
			{
				EXPECT_TRUE( std::find( indices[i].begin(), indices[i].end(), j )!=indices[i].end() );
			}
			else
			{
				EXPECT_TRUE( std::find( indices[i].begin(), indices[i].end(), j )==indices[i].end() );
			}
		}
	}
	printf("done (%g seconds)\n", stop_timer());
}

TEST_F(Flann_3D_Random_Cloud, TestRadiusSearchMatrix)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeCuda3dIndexParams());
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());
	float r = 0.05;
	flann::Matrix<int> counts( new int[query.rows], query.rows,1);
	flann::Matrix<float> dummy( 0,0,0 );
	flann::SearchParams counting_params;
	counting_params.max_neighbors=0;
	start_timer("counting neighbors...");
	index.radiusSearch( query, counts,dummy, r*r, counting_params );
	printf("done (%g seconds)", stop_timer());
	
	int max_neighbors=0;
	for( int i=0; i<query.rows; i++ )
	{
		max_neighbors = std::max(max_neighbors, counts[i][0]);
	}
	EXPECT_TRUE(max_neighbors > 0 );
	flann::Matrix<int> indices( new int[max_neighbors*query.rows], query.rows, max_neighbors );
	flann::Matrix<float> dists( new float[max_neighbors*query.rows], query.rows, max_neighbors );
		
	start_timer("Radius search, r=0.05");
	index.radiusSearch( query, indices,dists, r*r, flann::SearchParams() );
	printf("done (%g seconds)", stop_timer());

	start_timer("verifying results...");
	for( int i=0; i<query.rows; i++ )
	{
		for( int j=0; j<data.rows; j++ )
		{
			// for each pair of query and data points: either the distance between them
			// is smaller than r AND the point is in the result set, or 
			// the distance is larger and it is not.
			float dist = 0;
			for( int k=0; k<3; k++ )
				dist += (query[i][k]-data[j][k])*(query[i][k]-data[j][k]);
			if( dist < r*r )
			{
				EXPECT_TRUE( std::find( indices[i], indices[i]+max_neighbors, j )!=indices[i]+max_neighbors );
			}
			else
			{
				EXPECT_TRUE( std::find( indices[i], indices[i]+max_neighbors, j )==indices[i]+max_neighbors );
			}
		}
	}
	printf("done (%g seconds)\n", stop_timer());
	delete []counts.ptr();
	delete []indices.ptr();
	delete []dists.ptr();
}

TEST_F(Flann_3D, TestRadiusSearch)
{
    flann::Index<L2_Simple<float> > index(data, flann::KDTreeCuda3dIndexParams());
    start_timer("Building kd-tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());
	float r = 0.02;
	std::vector< std::vector<int> > indices;
	std::vector< std::vector<float> > dists;
	start_timer("Radius search, r=0.02...");
	index.radiusSearch( query, indices,dists, r*r, flann::SearchParams() );
	printf("done (%g seconds)\n", stop_timer());
	
	start_timer("verifying results...");
	for( int i=0; i<query.rows; i++ )
	{
		for( int j=0; j<data.rows; j++ )
		{
			float dist = 0;
			for( int k=0; k<3; k++ )
				dist += (query[i][k]-data[j][k])*(query[i][k]-data[j][k]);
			if( dist < r*r )
			{
				EXPECT_TRUE( std::find( indices[i].begin(), indices[i].end(), j )!=indices[i].end() );
			}
			else
			{
				EXPECT_TRUE( std::find( indices[i].begin(), indices[i].end(), j )==indices[i].end() );
			}
		}
	}
	printf("done (%g seconds)\n", stop_timer());
	
	r=0.01;
	start_timer("Radius search, r=0.01");
	index.radiusSearch( query, indices,dists, r*r, flann::SearchParams() );
	printf("done (%g seconds)\n", stop_timer());
	
	start_timer("verifying results...");
	for( int i=0; i<query.rows; i++ )
	{
		for( int j=0; j<data.rows; j++ )
		{
			float dist = 0;
			for( int k=0; k<3; k++ )
				dist += (query[i][k]-data[j][k])*(query[i][k]-data[j][k]);
			if( dist < r*r )
			{
				EXPECT_TRUE( std::find( indices[i].begin(), indices[i].end(), j )!=indices[i].end() );
			}
			else
			{
				EXPECT_TRUE( std::find( indices[i].begin(), indices[i].end(), j )==indices[i].end() );
			}
		}
	}
	printf("done (%g seconds)\n", stop_timer());
}

int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
