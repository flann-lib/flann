/*
Project: nn
*/

module dataset.ComputeGroundTruth;

import algo.dist;
import output.Console;
import dataset.Dataset;
import util.defines;
import util.Logger;
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

	showProgressBar(testData.rows, 70, (Ticker tick) {
		for (int i=0;i<testData.rows;++i) {
			findNearest(inputData.vecs, testData.vecs[i], matches[i], skip);
			tick();
		}
	});
	
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

void compute_gt(T)(string featuresFile, string testFile, string matchFile, int nn, int skip = 0)
{
	Dataset!(T) inputData;
	Dataset!(T) testData;
	
	showOperation("Reading input data from "~featuresFile, {
		inputData = new Dataset!(T)();
		inputData.readFromFile(featuresFile);
	});
	
	auto path = new FilePath(testFile);
	if (path.exists() && !path.isFolder()) {
		showOperation("Reading test data from "~testFile, {
			testData = new Dataset!(T)();
			testData.readFromFile(testFile);
		});
	} 
	else {
		showOperation("Sampling test data from input data and writing to "~testFile, {
			testData = inputData.sample(1000);
			testData.writeToFile(testFile);
		});
		showOperation("Writing input data to "~("new_"~featuresFile), {
			inputData.writeToFile("new_"~featuresFile);
		});
	}

	int matches[][];
	showOperation("Computing ground truth", {
		matches = computeGroundTruth(inputData, testData, nn, skip);
	});

	showOperation("Writing matches to "~matchFile, {
//		Dataset!(int).handler.write(matchFile,matches,"dat");
		writeMatches(matchFile,matches);
	});
	free(matches);

}