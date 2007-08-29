/*
Project: nn
*/

import std.stdio;
import std.string;
import std.c.string;
import std.conv;
import util.dist;
import console.progressbar;
import util.logger;
import util.features;


int findNearest(float[][] vecs, float[] query) 
{
	int nn = 0;
	float dist = squaredDist(vecs[nn], query);
	for (int i=0;i<vecs.length;++i) {
		float tmp = squaredDist(vecs[i], query);
		if (tmp<dist) {
			dist = tmp;
			nn = i;
		}
	}
	
	//writefln("%f",dist);
	
	return nn;
}

int[] computeGroundTruth(Features inputData, Features testData) 
{
	int[] matches = new int[testData.count];

	showProgressBar(testData.count, 70, (Ticker tick) {
		for (int i=0;i<testData.count;++i) {
			matches[i] = findNearest(inputData.vecs, testData.vecs[i]);
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

void compute_gt(string featuresFile, string testFile, string matchFile)
{
	Features inputData;
	Features testData;
	
	showOperation("Reading input data from "~featuresFile, {
		inputData = new Features();
		inputData.readFromFile(featuresFile);
	});
	
	if (std.file.exists(testFile) && std.file.isfile(testFile)) {
		showOperation("Reading test data from "~testFile, {
			testData = new Features();
			testData.readFromFile(testFile);
		});
	} 
	else {
		showOperation("Sampling test data from input data and writing to "~testFile, {
			testData = inputData.extractSubset(1000);
			testData.writeToFile(testFile);
		});
		showOperation("Writing input data to "~("new_"~featuresFile), {
			inputData.writeToFile("new_"~featuresFile);
		});
	}

	int matches[];
	showOperation("Computing ground truth", {
		matches = computeGroundTruth(inputData, testData);
	});

	showOperation("Writing matches to "~matchFile, {
		writeMatches(matchFile,matches);
	});

}