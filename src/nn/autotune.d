module nn.autotune;

import std.stdio;
import std.math;

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
	
	float[] doSearch(int times, float delegate() action)
	{
		float[] searchTimes = new float[times];
		for (int i=0;i<times;++i) {
			searchTimes[i] = action();
		}		
		return searchTimes;
	}
	
	float mean(float[] vec) {
		float ret = 0;
		foreach (elem;vec) {
			ret += elem;
		}
		return (ret / vec.length);		
	}

	
	// subsample datasets
	Features!(T) sampledDataset = inputDataset.sample(inputDataset.count/scaleFactor, false);
	Features!(float) sampledTestDataset = testDataset.sample(testDataset.count/scaleFactor,false);	
	sampledTestDataset.computeGT(sampledDataset);
	
	
	Logger.log(Logger.INFO,"Autotuning parameters...\n");
	
		
	int checks;
		
	Params kmeansParams;
	float kmeansCost = float.max;
	// search best kmeans params
	{
		uint[] testIterations = [ 1, 2, 3, 4, 5, 6, 7];
		uint[] branchingFactors = [ 32, 64, 128, 256 ];
		
		Params params;
		params["algorithm"] = "kmeans";
		params["trees"] = 1u;
		params["centers-algorithm"] = "random";
		foreach (maxIterations;testIterations) {
			params["max-iterations"] = maxIterations;
			foreach (branchingFactor;branchingFactors) {
				params["branching"] = branchingFactor;
				
				KMeansTree!(T) kmeans = new KMeansTree!(T)(sampledDataset,params);
				
				float buildTime = profile({kmeans.buildIndex();});
				float searchTime = mean( doSearch( 5,{ return testNN(kmeans, sampledTestDataset, desiredPrecision, checks);} ) );
				float cost = buildTime*indexFactor+searchTime;
				
				writefln("buildTime: %g, searchTime: %g, cost: %g",buildTime, searchTime, cost);			
// 				Logger.log(Logger.INFO,params);
				
				if (cost<kmeansCost) {
					copy(kmeansParams,params);
					kmeansCost = cost;
					
				}
			Logger.log(Logger.INFO,"Best KMeans bf: ",kmeansParams["branching"],"\n");	
			}
		}
// 		Logger.log(Logger.INFO,"Best KMeans params: ",kmeansParams,"\n");
//		Logger.log(Logger.INFO,"Best KMeans bf: ",kmeansParams["branching"],"\n");
	}
	
	Params kdtreeParams;
	float kdtreeCost = float.max;
	// search best kdtree params
	{
		uint[] testTrees = [ 1, 5, 10, 16, 32];
			
		Params params;
		params["algorithm"] = "kdtree";

		foreach (trees;testTrees) {
			params["trees"] = trees;
			
			KDTree!(T) kdtree = new KDTree!(T)(sampledDataset,params);
			
			float buildTime = profile({kdtree.buildIndex();});
			float searchTime = mean( doSearch( 5,{ return testNN(kdtree, sampledTestDataset, desiredPrecision, checks);} ) );
			float cost = buildTime*indexFactor+searchTime;
			
				writefln("buildTime: %g, searchTime: %g, cost: %g",buildTime, searchTime, cost);			
// 				Logger.log(Logger.INFO,params);
			
			if (cost<kdtreeCost) {
				copy(kdtreeParams,params);
				kdtreeCost = cost;
			}
		}
// 		Logger.log(Logger.INFO,"Best kdtree params: ",kdtreeParams,"\n");
	}

	if (kmeansCost<kdtreeCost) {
		return kmeansParams;
	} else {
		return kdtreeParams;
	}

}