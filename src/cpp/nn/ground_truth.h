#ifndef GROUND_TRUTH_H
#define GROUND_TRUTH_H

#include "Dataset.h"
#include "dist.h"


template <typename T>
void find_nearest(const Dataset<T>& dataset, T* query, int* matches, int nn, int skip = 0)
{
    int n = nn + skip;

    T* query_end = query + dataset.cols;

    long* match = new long[n];
    T* dists = new T[n];

    dists[0] = flann_dist(query, query_end, dataset[0]);
    match[0] = 0;
    int dcnt = 1;

    for (int i=1;i<dataset.rows;++i) {
        T tmp = flann_dist(query, query_end, dataset[i]);

        if (dcnt<n) {
            match[dcnt] = i;
            dists[dcnt++] = tmp;
        }
        else if (tmp < dists[dcnt-1]) {
            dists[dcnt-1] = tmp;
            match[dcnt-1] = i;
        }

        int j = dcnt-1;
        // bubble up
        while (j>=1 && dists[j]<dists[j-1]) {
            swap(dists[j],dists[j-1]);
            swap(match[j],match[j-1]);
            j--;
        }
    }

    for (int i=0;i<nn;++i) {
        matches[i] = match[i+skip];
    }

    delete[] match;
    delete[] dists;
}


template <typename T>
void compute_ground_truth(const Dataset<T>& dataset, const Dataset<T>& testset, Dataset<int>& matches, int skip=0)
{
    for (int i=0;i<testset.rows;++i) {
        find_nearest(dataset, testset[i], matches[i], matches.cols, skip);
    }
}


#endif //GROUND_TRUTH_H
