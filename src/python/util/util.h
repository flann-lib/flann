



template<typename T>
void swap(T& a, T& b)
{
    T tmp;
    tmp = a;
    a = b;
    b = tmp;
}



template<typename T>
float dist_squared_float(T *v1, T *v2, int veclen)
{
    float diff, distsq = 0.0;
    float diff0, diff1, diff2, diff3;
    T *final, *finalgroup;

    final = v1 + veclen;
    finalgroup = final - 3;
        

    /* Process 4 pixels with each loop for efficiency. */
    while (v1 < finalgroup) {
      diff0 = v1[0] - v2[0];
      diff1 = v1[1] - v2[1];
      diff2 = v1[2] - v2[2];
      diff3 = v1[3] - v2[3];
      distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
      v1 += 4;
      v2 += 4;
    }
    /* Process last 0-3 pixels.  Not needed for standard vector lengths. */
    while (v1 < final) {
      diff = *v1++ - *v2++;
      distsq += diff * diff;
    }
    return distsq;
}






void find_nearest(float* vecs, int rows, int cols, float* query, long* matches, int nn, int skip = 0) 
{
    int n = nn + skip;
    
    long* match = new long[n];
    float* dists = new float[n];
    
    dists[0] = dist_squared_float(vecs, query, cols);
    int dcnt = 1;
    
    float* pvecs = vecs+cols;
    for (int i=1;i<rows;++i) {
        float tmp = dist_squared_float(pvecs, query, cols);
        
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
        pvecs += cols;
    }
    
    for (int i=0;i<nn;++i) {
        matches[i] = match[i+skip];
    }   
 
    delete[] match;
    delete[] dists;   
}


void compute_ground_truth_float(float* dataset, int rows, int cols, float* testset, int t_rows, long* matches, int nn, int skip=0)
{
        for (int i=0;i<t_rows;++i) {
            find_nearest(dataset, rows, cols, testset+i*cols, matches+i*nn, nn, skip);
        }
}
