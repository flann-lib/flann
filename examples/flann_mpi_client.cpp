#include <stdio.h>
#include <time.h>

#include <cstdlib>
#include <iostream>
#include <flann/util/params.h>
#include <flann/io/hdf5.h>
#include <boost/asio.hpp>
#include "queries.h"

#define IF_RANK0 if (world.rank()==0)

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


namespace flann {

template<typename ElementType, typename DistanceType>
class ClientIndex
{
public:
	ClientIndex(const std::string& host, const std::string& service)
	{
	    tcp::resolver resolver(io_service_);
	    tcp::resolver::query query(tcp::v4(), host, service);
	    iterator_ = resolver.resolve(query);
	}


	void knnSearch(const flann::Matrix<ElementType>& queries, flann::Matrix<int>& indices, flann::Matrix<DistanceType>& dists, int knn, const SearchParams& params)
	{
	    tcp::socket sock(io_service_);
	    sock.connect(*iterator_);

	    Request<ElementType> req;
	    req.nn = knn;
	    req.queries = queries;
	    // send request
	    write_object(sock,req);

	    Response<DistanceType> resp;
	    // read response
	    read_object(sock, resp);

	    for (size_t i=0;i<indices.rows;++i) {
	    	for (size_t j=0;j<indices.cols;++j) {
	    		indices[i][j] = resp.indices[i][j];
	    		dists[i][j] = resp.dists[i][j];
	    	}
	    }
	}


private:
	boost::asio::io_service io_service_;
	tcp::resolver::iterator iterator_;
};


}


using boost::asio::ip::tcp;


int main(int argc, char* argv[])
{
	try {

		flann::Matrix<float> query;
		flann::Matrix<int> match;

		flann::load_from_file(query, "sift100K.h5","query");
		flann::load_from_file(match, "sift100K.h5","match");
		//	flann::load_from_file(gt_dists, "sift100K.h5","dists");

		flann::ClientIndex<float, float> index("localhost","9999");

		int nn = 1;
		flann::Matrix<int> indices(new int[query.rows*nn], query.rows, nn);
		flann::Matrix<float> dists(new float[query.rows*nn], query.rows, nn);

		start_timer("Performing search...\n");
		index.knnSearch(query, indices, dists, nn, flann::SearchParams(128));
		printf("Search done (%g seconds)\n", stop_timer());

		printf("Checking results\n");
		float precision = compute_precision(match, indices);
		printf("Precision is: %g\n", precision);

	}
	catch (std::exception& e) {
		std::cerr << "Exception: " << e.what() << "\n";
	}

	return 0;
}

