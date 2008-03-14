/************************
 * Authors: 	Marius Muja, mariusm@cs.ubc.ca
 */

module nn.Autotune;

import tango.math.Math;

import dataset.Dataset;
import algo.all;
import nn.Testing;
import util.Profile;
import util.Logger;
import util.Utils;





private float optimizeSimplexDownhill(T)(T[][] params, float delegate(T[]) func, float[] vals)
{
	const int MAX_ITERATIONS = 10;
	int n = params.length-1;
	
	assert(n>0);
	assert(params[0].length==n);
	
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
	
	bool allocatedVals = false;
	if (vals is null) {
		// evaluate function in all the points
		// and order values and parameter in increasing order
		vals = new float[n+1];
		allocatedVals = true;
	
		for (int i=0;i<n+1;++i) {
			float val = func(params[i]);
			addValue(val,i, params[i]);
		}
	}
	
	T[] p_o = new T[n];
	T[] p_r = new T[n];
	T[] p_e = new T[n];
	
	
	int iterations = 0;
	
	while (true) {
	
		if (iterations++ > MAX_ITERATIONS) break;
	
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
	if (allocatedVals) delete vals;
	
	return bestVal;
}

private float executeActions(int times, float delegate() action)
{
	float sum = 0;
	for (int i=0;i<times;++i) {
		sum += action();
	}		
	return sum/times;
}


struct CostData {
	float searchTimeCost;
	float buildTimeCost;
	float timeCost;
	float memoryCost;
	float cost;
	int[] params;
}

const int REPEATS = 1;


Params estimateBuildIndexParams(T)(Dataset!(T) inputDataset, float desiredPrecision, float buildTimeFactor = 0.1, float memoryFactor = 0.1, float samplePercentage = 0.1)
{	
	// subsample datasets
	int sampleSize = rndint(samplePercentage*inputDataset.rows);
	int testSampleSize = MIN(sampleSize/10, 1000);
	
	Params bestParams;
	float bestCost = float.max;
	
	if (testSampleSize<1) {
		bestParams["algorithm"] = "linear";
		return bestParams;
	}
	
	Dataset!(T) sampledDataset = inputDataset.sample(sampleSize, false);	
	Dataset!(float) testDataset = new Dataset!(float)();
	testDataset.init(sampledDataset.sample(testSampleSize,true));
	logger.info(sprint("Sampled dataset size: {}",sampledDataset.rows));
	logger.info(sprint("Test dataset size: {}",testDataset.rows));
 	
 	
 	logger.info("Computing ground truth: ");
 	testDataset.computeGT(sampledDataset,1,0);
	
	// Start parameter autotune process
	logger.info("Autotuning parameters...");

	Params kmeansParams;
	kmeansParams["algorithm"] = "kmeans";
	kmeansParams["trees"] = 1u;
	kmeansParams["centers-init"] = "random";

	CostData evaluate_kmeans(int[] p) 
	{
		CostData cost;
	
		kmeansParams["max-iterations"] = p[0];
		kmeansParams["branching"] = p[1];
		
		int checks;
		const int nn = 1;
		
		logger.info(sprint("KMeansTree using params: max_iterations={}, branching={}",p[0],p[1]));
		KMeansTree!(T) kmeans = new KMeansTree!(T)(sampledDataset,kmeansParams);
		float buildTime = profile({kmeans.buildIndex();});	
		float searchTime = executeActions(REPEATS, {return testNNIndexPrecision!(T,true,false)(kmeans, sampledDataset, testDataset, desiredPrecision, checks, nn);});
		float datasetMemory = sampledDataset.rows*sampledDataset.cols*T.sizeof;
		cost.memoryCost = (kmeans.usedMemory+datasetMemory)/datasetMemory;
		cost.searchTimeCost = searchTime;
		cost.buildTimeCost = buildTime;
		cost.timeCost = buildTime*buildTimeFactor+searchTime;
		logger.info(sprint("KMeansTree buildTime={:f3}, searchTime={:f3}, timeCost={:f3}",buildTime, searchTime, cost.timeCost));
		
		delete kmeans;
		return cost;
	}
	
	
	
	int[] maxIterations = [ 1, 3, 5, 7];
	int[] branchingFactors = [ 32, 64, 128, 256 ];
	
	int[][] kmeans_params = new int[][](maxIterations.length*branchingFactors.length,2);
	CostData[] kmeansCosts = new CostData[maxIterations.length*branchingFactors.length];
	
	// evaluate kmeans for all parameter combinations
	int cnt = 0;
	foreach (iterations;maxIterations) {
		foreach (branching;branchingFactors) {
			kmeans_params[cnt][0] = iterations;
			kmeans_params[cnt][1] = branching;
			kmeansCosts[cnt] = evaluate_kmeans(kmeans_params[cnt]);
			
			int k = cnt;
			// order by time cost
			while (k>0 && kmeansCosts[k].timeCost < kmeansCosts[k-1].timeCost) {
				swap(kmeansCosts[k],kmeansCosts[k-1]);
				swap(kmeans_params[k],kmeans_params[k-1]);
				k--;
			}
			
			cnt++;
		}
	}
	
	
	
	Params kdtreeParams;
	kdtreeParams["algorithm"] = "kdtree";
	
	CostData evaluate_kdtree(int[] p) 
	{
		CostData cost;
		kdtreeParams["trees"] = p[0];
		int checks;
		const int nn = 1;
		
		logger.info(sprint("KDTree using params: trees={}",p[0]));
		
		KDTree!(T) kdtree = new KDTree!(T)(sampledDataset,kdtreeParams);
		
		float buildTime = profile({kdtree.buildIndex();});
		float searchTime = executeActions( REPEATS, { 
						return testNNIndexPrecision!(T,true,false)(kdtree, sampledDataset, testDataset, desiredPrecision, checks, nn);
						} );
		float datasetMemory = sampledDataset.rows*sampledDataset.cols*T.sizeof;
		cost.memoryCost = (kdtree.usedMemory+datasetMemory)/datasetMemory;
		cost.searchTimeCost = searchTime;
		cost.buildTimeCost = buildTime;
		cost.timeCost = buildTime*buildTimeFactor+searchTime;	
		logger.info(sprint("KDTree buildTime={:f3}, searchTime={:f3}, timeCost={:f3}",buildTime, searchTime, cost.timeCost));
				
		delete kdtree;
		
		return cost;
	}
	
	uint[] testTrees = [ 1, 5, 10, 16, 32];

	int[][] kdtree_params = new int[][](testTrees.length,1);
	CostData[] kdtreeCosts = new CostData[testTrees.length];
	
	
	// evaluate kdtree for all parameter combinations
	cnt = 0;
	foreach (trees;testTrees) {
		kdtree_params[cnt][0] = trees;
		kdtreeCosts[cnt] = evaluate_kdtree(kdtree_params[cnt]);
		
		int k = cnt;
		// order by time cost
		while (k>0 && kdtreeCosts[k].timeCost < kdtreeCosts[k-1].timeCost) {
			swap(kdtreeCosts[k],kdtreeCosts[k-1]);
			swap(kdtree_params[k],kdtree_params[k-1]);
			k--;
		}
		
		cnt++;
	}
	
	
	
	// get the optimum time cost
	float optTimeCost = min(kmeansCosts[0].timeCost, kdtreeCosts[0].timeCost);
	
	if (optTimeCost<1e-6) {
		optTimeCost = 1;
	}
	
	logger.info(sprint("Optimum Time Cost = {:f3}",optTimeCost));
	
	// recompute total costs
	for (int i=0;i<kmeansCosts.length;++i) {
		kmeansCosts[i].cost = kmeansCosts[i].timeCost/optTimeCost +
							memoryFactor * kmeansCosts[i].memoryCost;
		
		int k = i;
		while (k>0 && kmeansCosts[k].cost < kmeansCosts[k-1].cost) {
			swap(kmeansCosts[k],kmeansCosts[k-1]);
			swap(kmeans_params[k],kmeans_params[k-1]);
			k--;
		}
	}
	for (int i=0;i<kmeansCosts.length;++i) {
		logger.info(sprint("KMeans, branching={}, iterations={}, time_cost={:f3} (build={}, search={}), memory_cost={:f3}, cost={:f3}", kmeans_params[i][1],kmeans_params[i][0],kmeansCosts[i].timeCost,kmeansCosts[i].buildTimeCost, kmeansCosts[i].searchTimeCost,kmeansCosts[i].memoryCost,kmeansCosts[i].cost));
	}	
	
/+	float compute_kmeans_cost(int[] params) 
	{
		if (params[0]<1 || params[1]<2) {
			return float.max;
		}
		CostData c = evaluate_kmeans(params);
		return c.timeCost/optKMeansTimeCost + memoryFactor * c.memoryCost;
	}
		
	// optimize for kmeans
	
	float costs[3];
	for (int i=0;i<3;++i) {
		costs[i] = kmeansCosts[i].cost;
	}
	
 	float kmeansCost = optimizeSimplexDownhill!(int)(kmeans_params[0..3], &compute_kmeans_cost, costs);+/
 	float kmeansCost = kmeansCosts[0].cost;
	logger.info(sprint("Best params: {}", kmeans_params[0]));
	kmeansParams["max-iterations"] = kmeans_params[0][0];
	kmeansParams["branching"] = kmeans_params[0][1];
	
	delete kmeans_params;
	delete kmeansCosts;
		
	if (kmeansCost<bestCost) {
		bestParams = kmeansParams;
		bestCost = kmeansCost;
	}
	
	for (int i=0;i<kdtreeCosts.length;++i) {
		kdtreeCosts[i].cost = kdtreeCosts[i].timeCost/optTimeCost +
							memoryFactor * kdtreeCosts[i].memoryCost;
		
		int k = i;
		while (k>0 && kdtreeCosts[k].cost < kdtreeCosts[k-1].cost) {
			swap(kdtreeCosts[k],kdtreeCosts[k-1]);
			swap(kdtree_params[k],kdtree_params[k-1]);
			k--;
		}		
	}
	for (int i=0;i<kdtreeCosts.length;++i) {
		logger.info(sprint("kd-tree, trees={}, time_cost={:f3} (build={}, search={}), memory_cost={:f3}, cost={:f3}",kdtree_params[i][0],kdtreeCosts[i].timeCost,kdtreeCosts[i].buildTimeCost, kdtreeCosts[i].searchTimeCost,kdtreeCosts[i].memoryCost,kdtreeCosts[i].cost));
	}	
	
	
/+	float compute_kdtree_cost(int[] params) 
	{
		if (params[0]<1) {
			return float.max;
		}
		CostData c = evaluate_kdtree(params);
		return c.timeCost/optKDtreeTimeCost + memoryFactor * c.memoryCost;
	}
	
	
	// optimize for kdtree
	float kdtre_costs[2];
	for (int i=0;i<2;++i) {
		kdtre_costs[i] = kdtreeCosts[i].cost;
	}
	
 	float kdtreeCost = optimizeSimplexDownhill!(int)(kdtree_params[0..2], &compute_kdtree_cost, kdtre_costs);+/
 	float kdtreeCost = kdtreeCosts[0].cost;
	logger.info(sprint("Best params: {}", kdtree_params[0]));
	kdtreeParams["trees"] = kdtree_params[0][0];
	
	delete kdtreeCosts;
	delete kdtree_params;
	
	if (kdtreeCost<bestCost) {
		bestParams = kdtreeParams;
		bestCost = kdtreeCost;
	}
	
	logger.info(sprint("Best params: {}",bestParams));
	
	return bestParams;
}



void estimateSearchParams(T)(NNIndex index, Dataset!(T) inputDataset, float desiredPrecision, Params searchParams)
{
	const int nn = 1;
	const int SAMPLE_COUNT = 500;
	
	int samples = min(inputDataset.rows/10, SAMPLE_COUNT);
	if (samples>0) {
		Dataset!(float) testDataset = new Dataset!(float)();
		testDataset.init(inputDataset.sample(samples,false));
		logger.info("Computing ground truth");
		
		float linear = profile({testDataset.computeGT(inputDataset,1,1);});
		
		int checks;
		logger.info("Estimating number of checks");
		float searchTime = testNNIndexPrecision!(T, true,false)(index, inputDataset, testDataset, desiredPrecision, checks, nn, 1);
		
		logger.info(sprint("Required number of checks: {} ",checks));;
		searchParams["checks"] = checks;
		searchParams["speedup"] = (linear/searchTime);
	}
}
