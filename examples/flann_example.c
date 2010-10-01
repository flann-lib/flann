

#include <flann/flann.h>

#include <stdio.h>
#include <stdlib.h>


float* read_points(const char* filename, int rows, int cols)
{
    int ret;

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
            ret = fscanf(fin,"%g ",p);
            p++;
        }
    }
    
    fclose(fin);
    
    return data;
}

void write_results(const char* filename, int *data, int rows, int cols)
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
    float* dataset = read_points("dataset.dat", rows, cols);
    printf("Reading test data file.\n");
    float* testset = read_points("testset.dat", tcount, cols);
    
    int nn = 3;
    int* result = (int*) malloc(tcount*nn*sizeof(int));
    float* dists = (float*) malloc(tcount*nn*sizeof(float));
    
    struct FLANNParameters p = DEFAULT_FLANN_PARAMETERS;
    p.algorithm = KDTREE;
    p.trees = 8;
    p.log_level = LOG_INFO;
    
    float speedup;
    printf("Computing index.\n");
    flann_index_t index_id = flann_build_index(dataset, rows, cols, &speedup, &p);
    flann_find_nearest_neighbors_index(index_id, testset, tcount, result, dists, nn, &p);
    
    write_results("results.dat",result, tcount, nn);
    
    flann_free_index(index_id, &p);
    free(dataset);
    free(testset);
    free(result);
    free(dists);
    
    return 0;
}
