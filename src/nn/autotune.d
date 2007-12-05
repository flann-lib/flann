module nn.autotune;

// import std.stdio;
// import std.math;
import tango.math.Math;
import tango.io.Stdout;
import tango.core.Memory;

import dataset.features;
import util.utils;
import util.profiler;
import algo.all;
import util.resultset;
import util.logger;
import util.utils;
import nn.testing;

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
	int sampleSize = rndint(samplePercentage*inputDataset.count/100);
	Features!(T) sampledDataset = inputDataset.sample(sampleSize, false);
	
	int testSampleSize = MIN(sampleSize/10, 1000);
	Features!(float) testDataset = new Features!(float)();
	testDataset.init(sampledDataset.sample(testSampleSize,true));
	
	logger.info(sprint("Sampled dataset size: {}",sampledDataset.count));
	logger.info(sprint("Test dataset size: {}",testDataset.count));
 	
 	
 	logger.info("Computing ground truth: ");
 	testDataset.computeGT(sampledDataset,1,0);
	
	
	logger.info("Autotuning parameters...");
	
	
	const int REPEAT = 1;
		
	int checks;
	const int nn = 1;
version (kmeans_autotune) {		
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
				
				Stdout.formatln("buildTime: {}, searchTime: {}, cost: {}",buildTime, searchTime, cost);			
				
				if (cost<kmeansCost) {
					copy(kmeansParams,params);
					kmeansCost = cost;
					
				}
				logger.info("Best KMeans bf: "~kmeansParams["branching"]);	
				
				GC.collect();
			}
		}
// 		Logger.log(Logger.INFO,"Best KMeans params: ",kmeansParams,"\n");
//		Logger.log(Logger.INFO,"Best KMeans bf: ",kmeansParams["branching"],"\n");
	}
}
version (kdtree_autotune) {		
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
			
				Stdout.formatln("buildTime: {}, searchTime: {}, cost: {}",buildTime, searchTime, cost);			
// 				Logger.log(Logger.INFO,params);
			
			if (cost<kdtreeCost) {
				copy(kdtreeParams,params);
				kdtreeCost = cost;
			}
			
			GC.collect();
		}
//  		Logger.log(Logger.INFO,"Best kdtree params: ",kdtreeParams,"\n");
	}
}

	Params compositeParams;
	float compositeCost = float.max;
	// search best kmeans params
	{
/+		uint[] testIterations = [ 1, 3, 5, 7];
		uint[] branchingFactors = [ 32, 64, 128, 256 ];
		uint[] testTrees = [ 1, 5, 10, 16, 32];+/
		uint[] testIterations = [ 1, 3];
		uint[] branchingFactors = [ 32, 64 ];
		uint[] testTrees = [ 4, 8 ];
		
		Params params;
		params["algorithm"] = "composite";
		params["centers-algorithm"] = "random";
		foreach (maxIterations;testIterations) {
			params["max-iterations"] = maxIterations;
			foreach (branchingFactor;branchingFactors) {
				params["branching"] = branchingFactor;
				foreach (trees;testTrees) {
					params["trees"] = trees;
						
					logger.info(sprint("Trying iterations:{}, branching:{}, trees:{}",maxIterations,branchingFactor, trees));	
					
					CompositeTree!(T) composite = new CompositeTree!(T)(sampledDataset,params);
					
					float buildTime = profile({composite.buildIndex();});	
					float searchTime = mean( doSearch( REPEAT, { 
								return testNNIndexPrecision!(T,true,false)(composite, sampledDataset, testDataset, desiredPrecision, checks, nn);
								} ) );
					float cost = buildTime*indexFactor+searchTime;
									
					if (cost<compositeCost) {
						copy(compositeParams,params);
						compositeCost = cost;
						
					}
					
					GC.collect();
				}
			}
		}
// 		Logger.log(Logger.INFO,"Best KMeans params: ",kmeansParams,"\n");
//		Logger.log(Logger.INFO,"Best KMeans bf: ",kmeansParams["branching"],"\n");
	}


/+	if (kmeansCost<kdtreeCost) {
		return kmeansParams;
	} else {
		return kdtreeParams;
	}+/
	return compositeParams;
}


int estimateSearchParams(T)(NNIndex index, Features!(T) inputDataset, float desiredPrecision)
{
	const int nn = 1;
	const int SAMPLE_COUNT = 500;
	Features!(float) testDataset = new Features!(float)();
	testDataset.init(inputDataset.sample(SAMPLE_COUNT,false));
	logger.info("Computing ground truth");
	testDataset.computeGT(inputDataset,1,1);
	
	int checks;
	logger.info("Estimating number of checks");
	testNNIndexPrecision!(T, true,false)(index, inputDataset, testDataset, desiredPrecision, checks, nn, 1);
	
	logger.info(sprint("Required number of checks: {} ",checks));;
	
	return checks;
}
