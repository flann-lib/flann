/*
Project: nn
*/

module dataset.compute_gt;

import std.stdio;
import std.string;
import std.c.string;
import std.conv;
import util.dist;
import output.console;
import util.logger;
import dataset.features;
import util.utils;
import util.allocator;


private void findNearest(T,U)(T[][] vecs, U[] query, int[] matches, int skip = 0) 
{
	int n = matches.length + skip;
	mixin(allocate_static("int[n] nn;"));
	mixin(allocate_static("float[n] dists;"));
	
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

public int[][] computeGroundTruth(T,U)(Features!(T) inputData, Features!(U) testData, int nn, int skip = 0) 
{
	int[][] matches = new int[][](testData.count,nn);

	showProgressBar(testData.count, 70, (Ticker tick) {
		for (int i=0;i<testData.count;++i) {
			findNearest(inputData.vecs, testData.vecs[i], matches[i], skip);
			tick();
		}
	});
	
	return matches;
}


void writeMatches(string match_file, int[][] matches)
{
	withOpenFile(match_file,"w", (FILE* f){
		foreach (index,match; matches) {
			fwritef(f,"%d ",index);
			foreach (value;match) {
				fwritef(f,"%d ",value);
			}
			fwritefln(f);
		}
	});
}

void compute_gt(T)(string featuresFile, string testFile, string matchFile, int nn, int skip = 0)
{
	Features!(T) inputData;
	Features!(T) testData;
	
	showOperation("Reading input data from "~featuresFile, {
		inputData = new Features!(T)();
		inputData.readFromFile(featuresFile);
	});
	
	
	if (std.file.exists(testFile) && std.file.isfile(testFile)) {
		showOperation("Reading test data from "~testFile, {
			testData = new Features!(T)();
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
		writeMatches(matchFile,matches);
	});

}