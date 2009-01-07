/*
 * test_dist.c
 *
 *  Created on: 17-Dec-2008
 *      Author: marius
 */


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



/**
 *  Compute the squared distance between one vector and the origin.
 *
 */
template <typename Iterator1, typename Iterator2>
double euclidean_dist(Iterator1 first1, Iterator1 last1, Iterator2 first2)
{
	double distsq = 0.0;
	double diff0, diff1, diff2, diff3;
	Iterator1 lastgroup = last1 - 3;

	/* Process 4 items with each loop for efficiency. */
	while (first1 < lastgroup) {
		diff0 = first1[0] - first2[0];
		diff1 = first1[1] - first2[1];
		diff2 = first1[2] - first2[2];
		diff3 = first1[3] - first2[3];
		distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
		first1 += 4;
		first2 += 4;
	}
	/* Process last 0-3 pixels.  Not needed for standard vector lengths. */
	while (first1 < last1) {
		diff0 = *first1++ - *first2++;
		distsq += diff0 * diff0;
	}
	return distsq;
}

enum distance_type {
	EUCLIDEAN,
	L1,
	MINKOWSKI
};



template <typename Iterator1, typename Iterator2>
double custom_dist(Iterator1 first1, Iterator1 last1, Iterator2 first2, distance_type type)
{
	switch (type) {
	case EUCLIDEAN:
		return euclidean_dist(first1, last1, first2);
	}

}


template <typename T>
struct ZeroIterator {

	T operator*() {
		return 0;
	}

	T operator[](int index) {
		return 0;
	}

	ZeroIterator<T>& operator ++(int) {
		return *this;
	}

	ZeroIterator<T>& operator+=(int) {
		return *this;
	}

};

ZeroIterator<float> zero;


void time_dist(float* dataset, int rows, int cols)
{
	printf("Computing distances.\n");
	clock_t start = clock();
	double distance = 0;
	for (int i=0;i<rows;++i) {
		for (int j=0;j<rows;++j){
			distance =  custom_dist(dataset+cols*i,dataset+cols*i+cols,zero,EUCLIDEAN);
//			distance =  euclidean_dist(dataset+cols*i,dataset+cols*i+cols);
			if (j%1000==0 && i%1000==0) printf("%g ",distance);
		}
		if (i%1000==0) printf("\n");
	}

	printf("It took: %g\n",double(clock()-start)/CLOCKS_PER_SEC);

}



int main(int argc, char **argv)
{
	int rows = 9000;
	int cols = 128;

	printf("Reading input data file.\n");
	float* dataset = read_dat_file("dataset.dat", rows, cols);

	time_dist(dataset, rows, cols);

}
