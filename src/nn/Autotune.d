/************************
 * Authors: 	Marius Muja, mariusm@cs.ubc.ca
 */

module nn.Autotune;

import tango.math.Math;
import tango.io.Stdout;
import tango.core.Memory;

import dataset.Features;
import algo.all;
import nn.Testing;
import util.Profile;
import util.Logger;
import util.Utils;





float optimizeSimpleDownhill(T)(ref T[][] params, float delegate(T[]) func)
{
			int n = params.length-1;
	
	assert(n>0);
	assert(params[0].length==n);
	
	// evaluate function in all the points
	// and order values and parameter in increasing order
	float[] vals = new float[n+1];
	
	void addValue(float val, int pos, T[] p) {
		vals[pos] = val;
		for (int i=0;i<n;++i) {
			params[pos][i] = p[i];
		}
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
	
	T[] p_o = new T[n];
	T[] p_r = new T[n];
	T[] p_e = new T[n];
	
	while (true) {
		debug logger.info(sprint("Current params: {}",params));
		debug logger.info(sprint("Current costs: {}",vals));
		p_o[] = 0;
		for (int j=0;j<n;++j) {
			for (int i=0;i<n;++i) {
				p_o[i] += params[j][i];
			}
		}
		for (int i=0;i<n;++i) {
			p_o[i] /= n;
		}
		
		bool converged = true;
		for (int i=0;i<n;++i) {
			if (p_o[i] != params[n][i]) {
				converged = false;
			}
		}
		if (converged) break;
		
		for (int i=0;i<n;++i) {
			p_r[i] = 2*p_o[i]-params[n][i];
		}
		float val_r = func(p_r);
		debug logger.info(sprint("Computing p_r={} from p_o={} and params[n]={}... val_r={}",p_r,p_o,params[n],val_r));
		
		if (val_r>vals[0] && val_r<vals[n-1]) {
			debug logger.info("Reflection");
			addValue(val_r,n,p_r);
			continue;
		}
		if (val_r<=vals[0]) {
			for (int i=0;i<n;++i) {
				p_e[i] = 2*p_r[i]-p_o[i];
			}
			float val_e = func(p_e);
			
			if (val_e<val_r) {
				debug logger.info(sprint("Reflection and expansion, val_e={}",val_e));
				addValue(val_e,n,p_e);
			}
			else {
				debug logger.info("Reflection without expansion");
				addValue(val_r,n,p_r);
			}
			continue;
		}
		if (vals[n-1]<val_r && val_r<vals[n]) {
			for (int i=0;i<n;++i) {
				p_e[i] = (3*p_o[i]-params[n][i])/2;
			}
			float val_e = func(p_e);
			
			if (val_e<val_r) {
				debug logger.info(sprint("Reflexion and contraction, val_c={}",val_e));
				addValue(val_e,n,p_e);
			}
			else {
				debug logger.info("Reflexion without contraction");
				addValue(val_r,n,p_r);
			}
			continue;
		}
		if (val_r>=vals[n]) {
			for (int i=0;i<n;++i) {
				p_e[i] = (p_o[i]+params[n][i])/2;
			}
			float val_e = func(p_e);
			
			if (val_e<vals[n]) {
				debug logger.info(sprint("Just contraction, new val[n]={}",val_e));
				addValue(val_e,n,p_e);
				continue;
			}
		}
		{
			debug logger.info(sprint("Full contraction: {}",params));
			for (int j=1;j<=n;++j) {
				for (int i=0;i<n;++i) {
					params[j][i] = (params[j][i]+params[0][i])/2;
				}
				float val = func(params[j]);
				addValue(val,j,params[j]);
			}
		}
	}
	
	
	float bestVal = vals[0];
	
	delete p_r;
	delete p_o;
	delete p_e;
	delete vals;
	
	return bestVal;
}

float executeActions(int times, float delegate() action)
{
	float sum = 0;
	for (int i=0;i<times;++i) {
		sum += action();
	}		
	return sum/times;
}

Params estimateBuildIndexParams(T)(Features!(T) inputDataset, float desiredPrecision, float buildTimeFactor = 0.1, float memoryFactor = 0.1, float samplePercentage = 0.1)
{	
	// subsample datasets
	int sampleSize = rndint(samplePercentage*inputDataset.rows);
	Features!(T) sampledDataset = inputDataset.sample(sampleSize, false);
	
	int testSampleSize = MIN(sampleSize/10, 1000);
	Features!(float) testDataset = new Features!(float)();
	testDataset.init(sampledDataset.sample(testSampleSize,true));
	
	logger.info(sprint("Sampled dataset size: {}",sampledDataset.rows));
	logger.info(sprint("Test dataset size: {}",testDataset.rows));
 	
 	
 	logger.info("Computing ground truth: ");
 	testDataset.computeGT(sampledDataset,1,0);
	
	
	logger.info("Autotuning parameters...");
	
	const int REPEAT = 1;
	
	Params kmeansParams;
	kmeansParams["algorithm"] = "kmeans";
	kmeansParams["trees"] = 1u;
	kmeansParams["centers-algorithm"] = "random";

	float evaluate_kmeans(int[] p) {
	
		if (p[0]<1 || p[1]<2) {
			return float.max;
		}
	
		kmeansParams["max-iterations"] = p[0];
		kmeansParams["branching"] = p[1];
		
		int checks;
		const int nn = 1;
		
		logger.info(sprint("KMeansTree using params: max_iterations={}, branching={}",p[0],p[1]));
		
		KMeansTree!(T) kmeans = new KMeansTree!(T)(sampledDataset,kmeansParams);
		
		float buildTime = profile({kmeans.buildIndex();});	
		float searchTime = executeActions(REPEAT, {return testNNIndexPrecision!(T,true,false)(kmeans, sampledDataset, testDataset, desiredPrecision, checks, nn);});
		float datasetMemory = sampledDataset.rows*sampledDataset.cols*T.sizeof;
		logger.info(sprint("datasetMemory={}",datasetMemory));
		float memoryIndex = (kmeans.usedMemory+datasetMemory)/datasetMemory;
		logger.info(sprint("memoryIndex={}",memoryIndex));
		logger.info(sprint("memoryFactor={}",memoryFactor));
		float cost = searchTime+buildTime*buildTimeFactor+memoryFactor*memoryIndex;
		
		logger.info(sprint("buildTime: {}, searchTime: {}, cost: {}",buildTime, searchTime, cost));
	
		delete kmeans;
		
		return cost;
	}
	
	
	Params kdtreeParams;
	kdtreeParams["algorithm"] = "kdtree";
	
	float evaluate_kdtree(int[] p) {
	
		if (p[0]<1) {
			return float.max;
		}
	
		kdtreeParams["trees"] = p[0];
		int checks;
		const int nn = 1;
		
		logger.info(sprint("KDTree using params: trees={}",p[0]));
		
		KDTree!(T) kdtree = new KDTree!(T)(sampledDataset,kdtreeParams);
		
		float buildTime = profile({kdtree.buildIndex();});
		float searchTime = executeActions( REPEAT, { 
						return testNNIndexPrecision!(T,true,false)(kdtree, sampledDataset, testDataset, desiredPrecision, checks, nn);
						} );
		float datasetMemory = sampledDataset.rows*sampledDataset.cols*T.sizeof;
		float memoryIndex = (kdtree.usedMemory+datasetMemory)/datasetMemory;
		float cost = searchTime+buildTime*buildTimeFactor+memoryFactor*memoryIndex;
				
		logger.info(sprint("buildTime: {}, searchTime: {}, cost: {}",buildTime, searchTime, cost));
	
		delete kdtree;
		
		return cost;
	}
	
	Params bestParams;
	float bestCost = float.max;
	
	
	// optimize for kmeans
	
	int[][] kmeans_params = [ [1, 8], [1, 64], [7, 64]];
	float kmeansCost = optimizeSimpleDownhill(kmeans_params, &evaluate_kmeans);
	logger.info(sprint("Best params: {}", kmeans_params[0]));
	kmeansParams["max-iterations"] = kmeans_params[0][0];
	kmeansParams["branching"] = kmeans_params[0][1];
	
	if (kmeansCost<bestCost) {
		bestParams = kmeansParams;
		bestCost = kmeansCost;
	}

	int[][] kdtree_params = [ [4], [8] ];
	float kdtreeCost = optimizeSimpleDownhill(kdtree_params, &evaluate_kdtree);
	logger.info(sprint("Best KDTree params: {}", kdtree_params[0]));
	kdtreeParams["trees"] = kdtree_params[0][0];
	
	if (kdtreeCost<bestCost) {
		bestParams = kdtreeParams;
		bestCost = kdtreeCost;
	}

	return bestParams;
}









Params estimateBuildIndexParams_(T)(Features!(T) inputDataset, float desiredPrecision, float indexFactor = 0, float samplePercentage = 10)
{	
	// subsample datasets
	int sampleSize = rndint(samplePercentage*inputDataset.rows);
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
