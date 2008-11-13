#ifndef TESTING_H
#define TESTING_H


#include "NNIndex.h"
#include "Dataset.h"


using namespace std;


void search_for_neighbors(NNIndex& index, const Dataset<float>& testset, Dataset<int>& result, Params searchParams, int skip = 0);

float testNNIndex(NNIndex& index, const Dataset<float>& inputData, const Dataset<float>& testData, const Dataset<int>& matches, int checks, int nn = 1, uint skipMatches = 0);

float testNNIndexPrecision(NNIndex& index, const Dataset<float>& inputData, const Dataset<float>& testData, const Dataset<int>& matches,
             float precision, int& checks, int nn = 1, uint skipMatches = 0);

float testNNIndexPrecisions(NNIndex& index, const Dataset<float>& inputData, const Dataset<float>& testData, const Dataset<int>& matches,
                    float* precisions, int precisions_length, int nn = 1, uint skipMatches = 0, float maxTime = 0);



#endif //TESTING_H
