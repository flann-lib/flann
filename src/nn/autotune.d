module nn.autotune;

import std.boxer;
import std.stdio;

import dataset.features;
import util.utils;
import util.profiler;
import algo.all;
import util.resultset;
import util.logger;
import util.utils;

struct OptimalParams 
{
	string algo;
	int branching;
	int maxIter;
	int numTrees;
	int checks;
}


float testNN(NNIndex index, Features!(float) testData, float desiredPrecision, out int checks)
{
	const int skipMatches = 0;
	ResultSet resultSet = new ResultSet(1+skipMatches);
	
	float search(int checks) {
		int correct = 0;
		float elapsed = profile( {
		for (int i = 0; i < testData.count; i++) {
			resultSet.init(testData.vecs[i]);
			index.findNeighbors(resultSet,testData.vecs[i], checks);			
			int nn_index = resultSet.getPointIndex(0+skipMatches);
			
			if (nn_index == testData.match[i]) {
				correct++;
			}
			else {
// 				writefln("I got: %d, I want: %d",nn_index,testData.match[i]);
			}
		}
		});
		float performance = 100*cast(float)correct/testData.count;
		return performance;
	}

	checks = 1;
	float performance;
	float searchTime = profile({performance = search(checks);});
	while (performance<desiredPrecision) {
		checks *=2;
		searchTime = profile({performance = search(checks);});
// 		writefln("checks: ",checks,", performance: ",performance);
	}
	
	// optional: interpolate checks number
	
	return searchTime;
}


Params estimateOptimalParams(T)(Features!(T) inputDataset, Features!(float) testDataset, float desiredPrecision, float indexFactor, int scaleFactor = 10)
{
	Params p;
	int[] branchingFactors = [ 32, 64, 128, 256 ];
	Features!(T) sampledDataset = inputDataset.sample(inputDataset.count/scaleFactor, false);
	Features!(float) sampledTestDataset = testDataset.sample(testDataset.count/scaleFactor,false);
	
	sampledTestDataset.computeGT(sampledDataset);
	
	Logger.log(Logger.INFO,"Autotuning parameters...\n");
	
	int bestBranching;
	int bestChecks;
	p["max-iterations"] = box(1u);
	p["centers-algorithm"] = box("random");
	p["trees"] = box(1);
	float cost = float.max;
	int checks;
	foreach (branchingFactor;branchingFactors) {
		p["branching"] = box(branchingFactor);
		KMeansTree!(T) kmeans = new KMeansTree!(T)(sampledDataset,p);
		
		float buildTime = profile({kmeans.buildIndex();});
		float searchTime = testNN(kmeans, sampledTestDataset, desiredPrecision, checks);
		float thisCost = buildTime*indexFactor+searchTime;
		
		writefln("buildTime: %g, searchTime: %g, cost: %g",buildTime, searchTime, thisCost);
		
		Logger.log(Logger.INFO,"algo: kmeans; branching: %d; checks: %d, search time: %g\n",branchingFactor, checks, searchTime);
		
		if (thisCost<cost) {
			bestBranching = branchingFactor;		
			bestChecks = checks;
			cost = thisCost;
		}
	}
	Logger.log(Logger.INFO,"KMeans best branching: %d\n",bestBranching);
	
	
	
	
	p["checks"] = box(checks);
	p["algorithm"] = box("kmeans");
	p["branching"] = box(bestBranching);


	
	return p;	
	

}