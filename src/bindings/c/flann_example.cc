// file flann_example.cc

#include "flann.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>


// Function that reads a dataset of points from a file
float* read_points(char* filename, int *rows, int *cols);

// Function that writes the newrest neighbor indices to a file
void write_dat_file(char* filename, int *data, int rows, int cols);

int main(int argc, char** argv)
{
    int rows,cols;
    int t_rows, t_cols;

    // read dataset points from file dataset.dat
    float* dataset = read_points("dataset.dat", &rows, &cols);
    float* testset = read_points("testset.dat", &t_rows, &t_cols);

    // points in dataset and testset should have the same dimensionality
    assert(cols==t_cols);

    int nn = 3;     // number of nearest-neighbors

    // allocate memory for the nearest-neighbors 
    int* result = new int[t_rows*nn];

    flann_init();  // initialize the FLANN library

    Parameters p;   // index parameters are stored here

    p.target_precision = 0.9;  // want 90% target precision
    // create the index
    FLANN_INDEX index_id = flann_build_index(dataset, rows, cols, &p);

    // compute the nearest-neighbors
    flann_find_nearest_neighbors_index(index_id, testset, t_rows, result, nn, p.checks);

    write_dat_file("results.dat",result, t_rows, nn);

    // delete the index and free the allocated memory
    flann_free_index(index_id);

    delete dataset;
    delete testset;
    delete result;

    return 0;
}
