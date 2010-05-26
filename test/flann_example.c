

#include <flann/flann.h>

#include <stdio.h>
#include <stdlib.h>


float* read_dat_file(const char* filename, int rows, int cols)
{
    int i,j;
    float* data;
    float* p;
    int ret;

    FILE* fin = fopen(filename,"r");
    if (!fin) {
        printf("Cannot open input file.\n");
        exit(1);
    }
    
    data = (float*) malloc(rows*cols*sizeof(float));
    if (!data) {
        printf("Cannot allocate memory.\n");
        exit(1);
    }
    p = data;
    
    for (i=0;i<rows;++i) {
        for (j=0;j<cols;++j) {
            ret = fscanf(fin,"%g ",p);
            p++;
        }
    }
    
    fclose(fin);
    
    return data;
}

void write_dat_file(const char* filename, int *data, int rows, int cols)
{
    int* p;
    int i,j;
    FILE* fout = fopen(filename,"w");
    if (!fout) {
        printf("Cannot open output file.\n");
        exit(1);
    }
    
    p = data;
    for (i=0;i<rows;++i) {
        for (j=0;j<cols;++j) {
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

    int nn = 3;
    float* dataset;
    float* testset;
    int* result;
    float* dists;
    struct FLANNParameters p;
    float speedup;
    flann_index_t index_id;


    
    printf("Reading input data file.\n");
    dataset = read_dat_file("dataset.dat", rows, cols);
    printf("Reading test data file.\n");
    testset = read_dat_file("testset.dat", tcount, cols);
    
    result = (int*) malloc(tcount*nn*sizeof(int));
    dists = (float*) malloc(tcount*nn*sizeof(float));
    
    p = FLANN_DEFAULT_PARAMETERS;
    p.log_level = LOG_INFO;
 
    p.algorithm = KDTREE;
    p.trees = 8;
    
    printf("Computing index.\n");
    index_id = flann_build_index(dataset, rows, cols, &speedup, &p);
    flann_find_nearest_neighbors_index(index_id, testset, tcount, result, dists, nn, &p);
    
    write_dat_file("results.dat",result, tcount, nn);
    
    flann_free_index(index_id, &p);
    free(dataset);
    free(testset);
    free(result);
    free(dists);
    
    return 0;
}
