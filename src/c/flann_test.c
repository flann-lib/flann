	
	
#include "flann.h"

#include <stdio.h>
#include <stdlib.h>


float* read_dat_file(char* filename, int rows, int cols)
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

void write_dat_file(char* filename, int *data, int rows, int cols)
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



int main(int argc, char** argv)
{
	int rows = 9000;
	int cols = 128;
	
	int tcount = 1000;
	
	printf("Reading input data file.\n");
	float* dataset = read_dat_file("dataset.dat", rows, cols);
	printf("Reading test data file.\n");
	float* testset = read_dat_file("testset.dat", tcount, cols);
	
	IndexParameters p;
		
	int nn = 3;
	int* result = (int*) malloc(tcount*nn*sizeof(int));
	
	flann_init();
	
	FLANNParameters fp;
	fp.log_level = LOG_WARN;
	fp.log_destination = NULL;
	
    p.algorithm = KDTREE;
    p.checks = 2;
    p.trees = 8;
    p.target_precision = -1;

	float speedup;
	
	printf("Computing index and optimum parameters.\n");
	int index_id = flann_build_index(dataset, rows, cols, &speedup, &p, &fp);

    flann_free_index(index_id, &fp);

    printf("second forest building...\n");

    int index_id1 = flann_build_index(dataset, rows, cols, &speedup, &p, &fp);

	/*flann_find_nearest_neighbors_index(index_id, testset, tcount, result, nn, p.checks, &fp);*/
	
	write_dat_file("results.dat",result, tcount, nn);
	
	free(dataset);
	free(result);
	
	return 0;
}
