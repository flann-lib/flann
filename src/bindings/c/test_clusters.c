	
	
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

void write_dat_file(char* filename, float *data, int rows, int cols)
{
	FILE* fout = fopen(filename,"w");
	if (!fout) {
		printf("Cannot open output file.\n");
		exit(1);
	}
	
	float* p = data;
	
	for (int i=0;i<rows;++i) {
		for (int j=0;j<cols;++j) {
			fprintf(fout,"%g ",*p);
			p++;
		}
		fprintf(fout,"\n");
	}
	
	fclose(fout);
}



int main(int argc, char** argv)
{
	int rows = 10000;
	int cols = 128;
	
	printf("Reading input dat file.\n");
	float* dataset = read_dat_file("sift10K.dat",rows, cols);
	
	int result;
	
	Parameters p;
	p.checks=32;
	p.algorithm = KMEANS;
	p.trees=1;
	p.branching=32;
	p.iterations=7;
	
	
	int cluster_count = 100;
	
	float* clusters = (float*) malloc(cluster_count*cols*sizeof(float));
	
   	fann_init();
   	
	printf("Computing clusters.\n");
   	int c_count = fann_compute_cluster_centers(dataset,rows, cols, cluster_count, clusters, &p);
	
	printf("Writing clusters to dat file.\n");
	write_dat_file("clusters.dat",clusters, c_count, cols);
	
	free(dataset);
	free(clusters);
	
	return 0;
}
