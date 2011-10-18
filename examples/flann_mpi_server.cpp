#include <flann/flann_mpi.hpp>
#include <stdio.h>
#include <time.h>

#include <cstdlib>
#include <iostream>
#include <boost/bind.hpp>
#include <boost/smart_ptr.hpp>
#include <boost/asio.hpp>
#include <boost/thread/thread.hpp>

#include "queries.h"

namespace flann {

template<typename Distance>
class MPIServer
{

	typedef typename Distance::ElementType ElementType;
	typedef typename Distance::ResultType DistanceType;
	typedef boost::shared_ptr<tcp::socket> socket_ptr;
	typedef flann::mpi::Index<Distance> FlannIndex;

	void session(socket_ptr sock)
	{
		boost::mpi::communicator world;
		try {
			Request<ElementType> req;
			if (world.rank()==0) {
				read_object(*sock,req);
				std::cout << "Received query\n";
			}
			// broadcast request to all MPI processes
			boost::mpi::broadcast(world, req, 0);

			Response<DistanceType> resp;
			if (world.rank()==0) {
				int rows = req.queries.rows;
				int cols = req.nn;
				resp.indices = flann::Matrix<int>(new int[rows*cols], rows, cols);
				resp.dists = flann::Matrix<DistanceType>(new DistanceType[rows*cols], rows, cols);
			}

			std::cout << "Searching in process " << world.rank() << "\n";
			index_->knnSearch(req.queries, resp.indices, resp.dists, req.nn, flann::SearchParams(128));

			if (world.rank()==0) {
				std::cout << "Sending result\n";
				write_object(*sock,resp);
			}

			delete[] req.queries.data;
			if (world.rank()==0) {
				delete[] resp.indices.data;
				delete[] resp.dists.data;
			}

		}
		catch (std::exception& e) {
			std::cerr << "Exception in thread: " << e.what() << "\n";
		}
	}



public:
	MPIServer(const std::string& filename, const std::string& dataset, short port) :
		port_(port)
	{
		boost::mpi::communicator world;
		if (world.rank()==0) {
			std::cout << "Reading dataset and building index...";
			std::flush(std::cout);
		}
		index_ = new FlannIndex(filename, dataset, flann::KDTreeIndexParams(4));
		index_->buildIndex();
		world.barrier(); // wait for data to be loaded and indexes to be created
		if (world.rank()==0) {
			std::cout << "done.\n";
		}
	}


	void run()
	{
		boost::mpi::communicator world;
		boost::shared_ptr<boost::asio::io_service> io_service;
		boost::shared_ptr<tcp::acceptor> acceptor;

		if (world.rank()==0) {
			io_service.reset(new boost::asio::io_service());
			acceptor.reset(new tcp::acceptor(*io_service, tcp::endpoint(tcp::v4(), port_)));
			std::cout << "Start listening for queries...\n";
		}
		for (;;) {
			socket_ptr sock;
			if (world.rank()==0) {
				sock.reset(new tcp::socket(*io_service));
				acceptor->accept(*sock);
				std::cout << "Accepted connection\n";
			}
			world.barrier(); // everybody waits here for a connection
			boost::thread t(boost::bind(&MPIServer::session, this, sock));
			t.join();
		}

	}

private:
	FlannIndex* index_;
	short port_;
};


}


int main(int argc, char* argv[])
{
	boost::mpi::environment env(argc, argv);

	try {
		if (argc != 4) {
			std::cout << "Usage: " << argv[0] << " <file> <dataset> <port>\n";
			return 1;
		}
		flann::MPIServer<flann::L2<float> > server(argv[1], argv[2], std::atoi(argv[3]));

		server.run();
	}
	catch (std::exception& e) {
		std::cerr << "Exception: " << e.what() << "\n";
	}

	return 0;
}

