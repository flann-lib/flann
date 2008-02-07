	
	
#include "fann.h"

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
   float* dataset = read_dat_file("features.dat", rows, cols);
   printf("Reading test data file.\n");
   float* testset = read_dat_file("test.dat", tcount, cols);
	
	Parameters p;
		
	int nn = 3;
   int* result = (int*) malloc(tcount*nn*sizeof(int));
	
  	nn_init();
   	
	printf("Computing index and optimum parameters.\n");
   int index_id = build_index(dataset, rows, cols, 90, &p);
   find_nearest_neighbors_index(index_id, testset, tcount, result, nn, p.checks);
   
   write_dat_file("results.dat",result, tcount, nn);
   
	free(dataset);
	free(result);
	
	return 0;
}
