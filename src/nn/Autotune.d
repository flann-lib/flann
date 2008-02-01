module nn.Autotune;

// import std.stdio;
// import std.math;
import tango.math.Math;
import tango.io.Stdout;
import tango.core.Memory;

import dataset.Features;
import algo.all;
import nn.Testing;
import util.Profile;
import util.Logger;
import util.Utils;



alias int param_t;

param_t[] optimizeSimpleDownhill(param_t[][] params, float delegate(param_t[]) func)
{
	int n = params.length-1;
	
	assert(n>0);
	assert(params[0].length==n);
	
	// evaluate function in all the points
	// and order values and parameter in increasing order
	float[] vals = new float[n];
	
	void addValue(float val, int pos, param_t[] p) {
		vals[pos] = val;
		params[pos] = p;
		
				// bubble up
		int j=pos;
		while (j>0 && vals[j]<vals[j-1]) {
			swap(vals[j],vals[j-1]);
			swap(params[j],params[j-1]);
			--j;
		}
	}
	
	for (int i=0;i<n+1;++i) {
		float val = func(params[i]);
		addValue(val,i, params[i]);
	}
	
	const int TIMES=20;
	
	
	param_t[] p_o = new param_t[n];
	param_t[] p_r = new param_t[n];
	param_t[] p_e = new param_t[n];
	
	for (int k=1;k<TIMES;++k) {
	
		p_o[] = 0;
		for (int j=0;j<n;++j) {
			for (int i=0;i<n;++i) {
				p_o[i] += params[j][i];
			}
		}
		for (int i=0;i<n;++i) {
			p_o[i] /= n;
		}
		
		for (int i=0;i<n;++i) {
			p_r[i] = 2*p_o[i]-params[n][i];
		}
		float val_r = func(p_r);
		
		if (val_r>vals[0] && val_r<vals[n-1]) {
			addValue(val_r,n,p_r);
		}
		else if (val_r<=vals[0]) {
			for (int i=0;i<n;++i) {
				p_e[i] = 2*p_r[i]-p_o[i];
			}
			float val_e = func(p_e);
			
			if (val_e<val_r) {
				addValue(val_e,n,p_e);
			}
			else {
				addValue(val_r,n,p_r);
			}
		}
		else if (vals[n-1]<val_r && val_r<vals[n]) {
			for (int i=0;i<n;++i) {
				p_e[i] = (3*p_o[i]-params[n][i])/2;
			}
			float val_e = func(p_e);
			
			if (val_e<val_r) {
				addValue(val_e,n,p_e);
			}
		}
		else if (val_r>=vals[n]) {
			for (int i=0;i<n;++i) {
				p_e[i] = (p_o[i]+params[n][i])/2;
			}
			float val_e = func(p_e);
			
			if (val_e<vals[n]) {
				addValue(val_e,n,p_e);
			}
		} else {
			for (int j=1;j<=n;++j) {
				for (int i=0;i<n;++i) {
					params[j][i] = (params[j][i]+params[0][i])/2;
				}
				float val = func(params[j]);
				addValue(val,j,params[j]);
			}
		}
	}
	
	return params[0];
}



Params estimateBuildIndexParams2(T)(Features!(T) inputDataset, float desiredPrecision, float indexFactor = 0, float samplePercentage = 10)
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
	
	
	
	float evaluate_kmeans(int[] p) {
	
		Params params;
		params["algorithm"] = "kmeans";
		params["trees"] = 1u;
		params["centers-algorithm"] = "random";
		params["max-iterations"] = p[0];
		params["branching"] = p[1];
		int checks;
		const int nn = 1;
		
		logger.info(sprint("KMeansTree using params: max_iterations={}, branching={}",p[0],p[1]));
		
		KMeansTree!(T) kmeans = new KMeansTree!(T)(sampledDataset,params);
		
		float buildTime = profile({kmeans.buildIndex();});	
		float searchTime = testNNIndexPrecision!(T,true,false)(kmeans, sampledDataset, testDataset, desiredPrecision, checks, nn);
		float cost = buildTime*indexFactor+searchTime;
		
		Stdout.formatln("buildTime: {}, searchTime: {}, cost: {}",buildTime, searchTime, cost);			
	
		delete kmeans;
		
		return cost;
	}
	
	
	int[][] params = [ [1, 8],
						[1, 64],
						[7, 64]];
						
	
	int[] best_params = optimizeSimpleDownhill(params, evaluate_kmeans);
	
	logger.info("Best params: {}", best_params);
	Params params;
	params["algorithm"] = "kmeans";
	params["trees"] = 1u;
	params["centers-algorithm"] = "random";
	params["max-iterations"] = best_params[0];
	params["branching"] = best_params[1];

	return params;
}




Params estimateBuildIndexParams(T)(Features!(T) inputDataset, float desiredPrecision, float indexFactor = 0, float samplePercentage = 10)
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
	
	logger.info(sprint("Params chosen: {}",compositeParams));
	
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
