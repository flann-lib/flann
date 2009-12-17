

#include <flann.h>

#include <boost/thread/thread.hpp>
#include <boost/thread/mutex.hpp>

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

float* read_dat_file(const char* filename, int rows, int cols)
{
	FILE* fin = fopen(filename,"r");
	if (!fin) {
		printf("Cannot open input file.\n");
		exit(1);
	}

	float* data = (float*) malloc(rows*cols*sizeof(float));
	if (!data) {
		printf("Cannot allocate memory.\n");
		exit(1);
	}
	float* p = data;

	for (int i=0;i<rows;++i) {
		for (int j=0;j<cols;++j) {
			fscanf(fin,"%g ",p);
			p++;
		}
	}

	fclose(fin);

	return data;
}

int* read_dat_file_int(const char* filename, int rows, int cols)
{
	FILE* fin = fopen(filename,"r");
	if (!fin) {
		printf("Cannot open input file.\n");
		exit(1);
	}

	int* data = (int*) malloc(rows*cols*sizeof(int));
	if (!data) {
		printf("Cannot allocate memory.\n");
		exit(1);
	}
	int* p = data;

	for (int i=0;i<rows;++i) {
		for (int j=0;j<cols;++j) {
			fscanf(fin,"%d ",p);
			p++;
		}
	}

	fclose(fin);

	return data;
}


void write_dat_file(const char* filename, int *data, int rows, int cols)
{
	FILE* fout = fopen(filename,"w");
	if (!fout) {
		printf("Cannot open output file.\n");
		exit(1);
	}

	int* p = data;

	for (int i=0;i<rows;++i) {
		for (int j=0;j<cols;++j) {
			fprintf(fout,"%d ",*p);
			p++;
		}
		fprintf(fout,"\n");
	}

	fclose(fout);
}


void test_single_thread1(flann_index_t index_id, float* testset, int cols, int count,
					int* result, float* dists, int nn, FLANNParameters& p)
{
	flann_find_nearest_neighbors_index(index_id, testset, count, result, dists, nn, p.checks, &p);
}


void test_single_thread2(flann_index_t index_id, float* testset, int cols, int count,
					int* result, float* dists, int nn, FLANNParameters& p)
{
	float* testset_it = testset;
	int* result_it = result;
	float* dists_it = dists;
	for (int i=0;i<count;++i) {
		flann_find_nearest_neighbors_index(index_id, testset_it, 1, result_it, dists_it, nn, p.checks, &p);
		testset_it += cols;
		result_it += nn;
		dists_it += nn;
	}
}


boost::mutex idx_lock;
int idx;

void multithreaded_matcher(flann_index_t index_id, float* testset, int cols, int count,
		int* result, float* dists, int nn, FLANNParameters& p, int id)
{
	while (idx<count) {

		idx_lock.lock();
		idx++;
		idx_lock.unlock();

		flann_find_nearest_neighbors_index(index_id, testset+idx*cols, 1, result+idx,
				dists+idx, nn, p.checks, &p);
	}
}



void test_multithreaded(flann_index_t index_id, float* testset, int cols, int count,
					int* result, float* dists, int nn, FLANNParameters& p, int threads)
{
	idx = 0;

	boost::thread t1(boost::bind(&multithreaded_matcher, index_id, testset, cols, count,result, dists, nn, p, 1));
	boost::thread t2(boost::bind(&multithreaded_matcher, index_id, testset, cols, count,result, dists, nn, p, 2));

	t1.join();
	t2.join();
}



double check_precision(int* matches, int* result, int cnt)
{
	int correct = 0;

	for (int i=0;i<cnt;++i) {
		if (matches[i] == result[i]) correct++;
	}

	return double(correct)/cnt;
}

double clock_()
{
	return double(clock())/CLOCKS_PER_SEC;
}

int main(int argc, char** argv)
{
	int rows = 99000;
	int cols = 128;

	int tcount = 1000;
	int nn = 1;

	printf("Reading input data file.\n");
	float* dataset = read_dat_file("dataset.dat", rows, cols);
	printf("Reading test data file.\n");
	float* testset = read_dat_file("testset.dat", tcount, cols);
	printf("Reading match data file.\n");
	int* matches = read_dat_file_int("matches.dat", tcount, nn);

	FLANNParameters p;

	int* result = (int*) malloc(tcount*nn*sizeof(int));
    float* dists = (float*) malloc(tcount*nn*sizeof(float));

	p.log_level = LOG_INFO;
	p.log_destination = NULL;

    p.algorithm = KDTREE_MT;
    p.checks = 64;
    p.trees = 8;
    p.target_precision = -1;

	float speedup;

	printf("Computing index\n");
	FLANN_INDEX index_id = flann_build_index(dataset, rows, cols, &speedup, &p);


	printf("Testing single thread, all testset at once... \n");
	double start = clock_();
	test_single_thread1(index_id, testset, cols, tcount, result, dists, nn, p);
	double precision = check_precision(matches, result, tcount);
	printf("\ttime: %f seconds, precision: %f \n",  clock_()-start, precision);

	printf("Testing single thread, one at a time... \n");
	start = clock_();
	test_single_thread2(index_id, testset, cols, tcount, result, dists, nn, p);
	precision = check_precision(matches, result, tcount);
	printf("\ttime: %f seconds, precision: %f \n",  clock_()-start, precision);

	int threads = 2;
	printf("Testing multithreaded, threads=%d... \n", threads);
	start = clock_();
	test_multithreaded(index_id, testset, cols, tcount, result, dists, nn, p, threads);
	precision = check_precision(matches, result, tcount);
	printf("\ttime: %f seconds, precision: %f \n",  clock_()-start, precision);

	write_dat_file("results.dat",result, tcount, nn);

    flann_free_index(index_id, &p);
	free(dataset);
    free(testset);
	free(result);
    free(dists);

	return 0;
}
