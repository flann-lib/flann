/*
Project: nn
*/

module convert.compute_gt;

import std.stdio;
import std.string;
import std.c.string;
import std.conv;
import util.dist;
import console.progressbar;
import util.logger;
import util.features;
import util.utils;
import util.allocator;


private int findNearest(T)(T[][] vecs, T[] query, int skip = 0) 
{
	int n = skip + 1;
	static int[] nn;
	if (nn is null) {
		nn = allocate!(int[])(n);
	}
	
	static float[] dists; 
	if (dists is null) dists = allocate!(float[])(n);
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
	
	
	return nn[skip];
}

private int[] computeGroundTruth(T)(Features!(T) inputData, Features!(T) testData, int skip = 0) 
{
	int[] matches = allocate!(int[])(testData.count);

	showProgressBar(testData.count, 70, (Ticker tick) {
		for (int i=0;i<testData.count;++i) {
			matches[i] = findNearest(inputData.vecs, testData.vecs[i], skip);
			tick();
		}
	});
	
	return matches;
}


void writeMatches(string match_file, int[] matches)
{

	FILE* f = fopen(toStringz(match_file),"w");
	if (f==null) {
		throw new Exception("Cannot open file "~match_file);
	}

	for (int i=0;i<matches.length;++i) {
		fwritefln(f,"%d %d",i,matches[i]);
	}
	
	fclose(f);
}

void compute_gt(T)(string featuresFile, string testFile, string matchFile, int skip = 0)
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
			testData = inputData.sampleDataset(1000);
			testData.writeToFile(testFile);
		});
		showOperation("Writing input data to "~("new_"~featuresFile), {
			inputData.writeToFile("new_"~featuresFile);
		});
	}

	int matches[];
	showOperation("Computing ground truth", {
		matches = computeGroundTruth(inputData, testData, skip);
	});

	showOperation("Writing matches to "~matchFile, {
		writeMatches(matchFile,matches);
	});

}