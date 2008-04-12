// file flann_example.cc

#include "flann.h"
#include <stdio.h>
#include <assert.h>

// Function that reads a dataset
float* read_points(char* filename, int *rows, int *cols);

int main(int argc, char** argv)
{
   int rows,cols;
   int t_rows, t_cols;
   float speedup;

   // read dataset points from file dataset.dat
   float* dataset = read_points("dataset.dat", &rows, &cols);
   float* testset = read_points("testset.dat", &t_rows, &t_cols);

   // points in dataset and testset should have the same dimensionality
   assert(cols==t_cols);

   // number of nearest neighbors to search
   int nn = 3;
   // allocate memory for the nearest-neighbors
   int* result = new int[t_rows*nn];
   // initialize the FLANN library
   flann_init();  
   // index parameters are stored here
   IndexParameters p;
   // want 90% target precision
   // the rest of the parameters are automatically computed
   p.target_precision = 0.9;  
   // compute the 3 nearest-neighbors of each point in the testset
   flann_find_nearest_neighbors(dataset, rows, cols, testset, t_rows, result, nn, &p, NULL);

   // ...


   delete dataset;
   delete testset;
   delete result;

   return 0;
}
