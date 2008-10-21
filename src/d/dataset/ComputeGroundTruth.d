/*
Project: nn
*/

module dataset.ComputeGroundTruth;

import algo.dist;
import dataset.Dataset;
import dataset.DatFormatHandler;
import util.defines;
import util.Utils;
import util.Allocator;


private void findNearest(T,U)(T[][] vecs, U[] query, int[] matches, int skip = 0) 
{
	int n = matches.length + skip;
	
	scope int[] nn = new int[n];
	scope float[] dists = new float[n];
	
	dists[0] = squaredDist(vecs[0], query);
	int dcnt = 1;
	
	for (int i=1;i<vecs.length;++i) {
		float tmp = squaredDist(vecs[i], query);
		
		if (dcnt<dists.length) {
			nn[dcnt] = i;	
			dists[dcnt++] = tmp;
		} 
		else if (tmp < dists[dcnt-1]) {
			dists[dcnt-1] = tmp;
			nn[dcnt-1] = i;
		} 
		
		int j = dcnt-1;
		// bubble up
		while (j>=1 && dists[j]<dists[j-1]) {
			swap(dists[j],dists[j-1]);
			swap(nn[j],nn[j-1]);
			j--;
		}
	}
	
	for (int i=0;i<matches.length;++i) {
		matches[i] = nn[i+skip];
	}	
	
}

public int[][] computeGroundTruth(T,U)(Dataset!(T) inputData, Dataset!(U) testData, int nn, int skip = 0) 
{
	int[][] matches = allocate!(int[][])(testData.rows,nn);

// 	showProgressBar(testData.rows, 70, (Ticker tick) {
		for (int i=0;i<testData.rows;++i) {
			findNearest(inputData.vecs, testData.vecs[i], matches[i], skip);
// 			tick();
		}
// 	});
	
	return matches;
}


void writeMatches(string match_file, int[][] matches)
{
	withOpenFile(match_file,(FormatOutput writer){
		foreach (index,match; matches) {
			writer.format("{} ",index);
			foreach (value;match) {
				writer.format("{} ",value);
			}
			writer("\n");
		}
	});
}

public int[][] readMatches(string file)
{
    auto gridData = new DatFormatHandler!(int)();       
    int[][] values = gridData.read(file);
    int[][] matches;
    
    if (values.length >= 1) {
        matches = allocate!(int[][])(values.length, values[0].length-1);
        foreach (v;values) {
            matches[v[0]][] = v[1..$];
        }
    }
    free(values);
    return matches;
}

