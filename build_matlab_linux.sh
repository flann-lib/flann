#!/bin/sh
# searching for flann static library path, the search result should be successful for the mex command to work properly.
ld -lflann_s --verbose
#compiling FLANN for MATLAB using the highest possible optimization level
mex -v -outdir src/matlab -lflann_s  -Isrc/cpp LDFLAGS='$LDFLAGS -fopenmp' CXXFLAGS='$CXXFLAGS -fopenmp -Wall -std=c++11' CXXOPTIMFLAGS='-O3 -DNDEBUG' src/matlab/nearest_neighbors.cpp
