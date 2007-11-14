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
import nn.testing;

struct OptimalParams 
{
	string algo;
	int branching;
	int maxIter;
	int numTrees;
	int checks;
}

/+
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
}+/


Params estimateBuildIndexParams(T)(Features!(T) inputDataset, float desiredPrecision, float indexFactor, float samplePercentage)
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
	int sampleSize = lround(samplePercentage*inputDataset.count/100);
	Features!(T) sampledDataset = inputDataset.sample(sampleSize, false);
	
	int testSampleSize = MIN(sampleSize/10, 1000);
	Features!(float) testDataset = new Features!(float)();
	testDataset.init(sampledDataset.sample(testSampleSize,true));
	
	Logger.log(Logger.INFO,"Sampled dataset size: ",sampledDataset.count,"\n");
	Logger.log(Logger.INFO,"Test dataset size: ",testDataset.count,"\n");
 	
 	
 	Logger.log(Logger.INFO,"Computing ground truth: ");
 	testDataset.computeGT(sampledDataset,1,0);
	
	
	Logger.log(Logger.INFO,"Autotuning parameters...\n");
	
	
	const int REPEAT = 2;
		
	int checks;
	const int nn = 1;
		
	Params kmeansParams;
	float kmeansCost = float.max;
	// search best kmeans params
	{
		uint[] testIterations = [ 1, 3, 5, 7];
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
				float searchTime = mean( doSearch( REPEAT, { 
							return testNNIndexPrecision!(T,true,false)(kmeans, sampledDataset, testDataset, desiredPrecision, checks, nn);
							} ) );
				float cost = buildTime*indexFactor+searchTime;
				
				writefln("buildTime: %g, searchTime: %g, cost: %g",buildTime, searchTime, cost);			
				
				if (cost<kmeansCost) {
					copy(kmeansParams,params);
					kmeansCost = cost;
					
				}
				Logger.log(Logger.INFO,"Best KMeans bf: ",kmeansParams["branching"],"\n");	
				
				std.gc.fullCollect();
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
				float searchTime = mean( doSearch( REPEAT, { 
							return testNNIndexPrecision!(T,true,false)(kdtree, sampledDataset, testDataset, desiredPrecision, checks, nn);
							} ) );
			float cost = buildTime*indexFactor+searchTime;
			
				writefln("buildTime: %g, searchTime: %g, cost: %g",buildTime, searchTime, cost);			
// 				Logger.log(Logger.INFO,params);
			
			if (cost<kdtreeCost) {
				copy(kdtreeParams,params);
				kdtreeCost = cost;
			}
			
			std.gc.fullCollect();
		}
//  		Logger.log(Logger.INFO,"Best kdtree params: ",kdtreeParams,"\n");
	}

	if (kmeansCost<kdtreeCost) {
		return kmeansParams;
	} else {
		return kdtreeParams;
	}
}


int estimateSearchParams(T)(NNIndex index, Features!(T) inputDataset, float desiredPrecision)
{
	const int nn = 1;
	const int SAMPLE_COUNT = 500;
	Features!(float) testDataset = new Features!(float)();
	testDataset.init(inputDataset.sample(SAMPLE_COUNT,false));
	writefln("computing ground truth");
	testDataset.computeGT(inputDataset,1,1);
	
	int checks;
	writefln("Estimating number of checks");
	testNNIndexPrecision!(T, true,false)(index, inputDataset, testDataset, desiredPrecision, checks, nn, 1);
	
	writefln("required number of checks: ", checks);
	
	return checks;
}
