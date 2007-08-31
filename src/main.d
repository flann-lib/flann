
/************************************************************************
Project: nn

  Demo software: Approximate Nearest-Neighbor Matching
  Converted from C
Author: Marus Muja (2007)

*************************************************************************/


import std.c.stdio;
import std.string;
import std.boxer;
import std.c.stdlib;
import std.c.math;
import std.c.time;


import util.optparse;
import util.utils;
import util.resultset;
import util.features;
import console.progressbar;
import util.logger;
import algo.kdtree;
import algo.agglomerativetree2;
import algo.nnindex;
import algo.kmeans;
import algo.bottom_up_agg_simple;
import algo.balltree;
import algo.linearsearch;
import convert.compute_gt;



class Range 
{
	int begin;
	int end;
	int skip;
	
	this(int begin, int end, int skip) {
		this.begin = begin;
		this.end = end;
		this.skip = skip;
	}
	
	this(string range) {
		int[] values = toVec!(int)(split(range,":"));
		
		begin = values[0];
		if (values.length>1) {
			end = values[1];
			
			if (values.length>2) {
				skip = values[2];
			}
			else {
				skip = 1;
			}
		}
		else {
			skip = 1;
			end = begin + skip;
		} 
	}
}




void testNNIndex(NNIndex index, Features testData, int nn, int checks, uint skipMatches)
{
	Logger.log(Logger.INFO,"Searching... \n");
	/* Create a table showing computation time and accuracy as a function
	   of "checks", the number of neighbors that are checked.
	   Note that we should check average of at least 2 nodes per random
	   tree, as first neighbor found is just the query vector itself.
	   Print statistics on success rate and time for value.
	 */

	ResultSet resultSet = new ResultSet(nn+skipMatches);
	
	clock_t startTime = clock();
	
	int correct, cormatch, match;
	correct = cormatch = match = 0;

	showProgressBar(testData.count, 70, (Ticker tick){
		for (int i = 0; i < testData.count; i++) {
			tick();
			
			resultSet.init(testData.vecs[i]);
	
			index.findNeighbors(resultSet,testData.vecs[i], checks);			
			int nn_index = resultSet.getPointIndex(0+skipMatches);
	
		
			if (nn_index == testData.match[i]) {
				correct++;
			}
	/+		else {
				writef("%d, got:  %d, expected: %d\n",i, nn_index, testData.match[i]);
			}+/
		}
	});

	float elapsed = (cast(float) clock() - startTime) / CLOCKS_PER_SEC;
	Logger.log(Logger.INFO,"  Nodes    %% correct    Time     Time/vector\n"
			" checked   neighbors   (seconds)      (ms)\n"
			" -------   ---------   ---------  -----------\n");
	Logger.log(Logger.INFO,"  %5d     %6.2f      %6.2f      %6.3f\n",
			checks, correct * 100.0 / cast(float) testData.count,
			elapsed, 1000.0 * elapsed / testData.count);
	
	Logger.log(Logger.SIMPLE,"%d %f %f %f\n",
			checks, correct * 100.0 / cast(float) testData.count,
			elapsed, 1000.0 * elapsed / testData.count);

}


void writeToFile(float[][] centers, char[] centerFile) 
{
	FILE* fp = fopen(toStringz(centerFile),"w");
	if (fp is null) {
		throw new Exception("Cannot open output file: "~centerFile);
	}
	
	for (int i=0;i<centers.length;++i) {
		for (int j=0;j<centers[i].length;++j) {
			if (j!=0) {
				fprintf(fp," ");
			}
			fprintf(fp,"%f", centers[i][j]);
		}
		fprintf(fp,"\n");
	}
	fclose(fp);
}




/** 
	Program entry point 
*/
void main(char[][] args)
{
	Logger.enableLevel(Logger.ERROR);
	std.gc.disable();

	// Create our option parser
	auto optParser = new OptionParser();
	
	auto optAlgo = new StringOption("a", "algorithm", "algorithm", null, "ALGO");
	optAlgo.helpMessage = "Use the ALGO nn search algorithm";
	
	auto optPrintAlgos = new FlagTrueOption("p", "print-algorithms", "print-algorithms");
	optPrintAlgos.helpMessage = "Display available algorithms";
	
	auto optInputFile = new StringOption("i", "input", "input_file", null, "FILE");
	optInputFile.helpMessage = "Read input vectors from FILE";
	
	auto optTestFile = new StringOption("t", "test", "test_file", null, "FILE");
	optTestFile.helpMessage = "Read test vectors from FILE (if not given the input file is used)";
	
	auto optMatchFile = new StringOption("m", "match", "match_file", null, "FILE");
	optMatchFile.helpMessage = "The match file.";
	
	auto optSaveFile = new StringOption("s", "save", "save_file", null, "FILE");
	optSaveFile.helpMessage = "Save the built index to this file.";
	
	auto optLoadFile = new StringOption("l", "load", "load_file", null, "FILE");
	optLoadFile.helpMessage = "Load the index from this file. The type of index (algorithm) must be specified.";
	
	auto optNN = new NumericOption!(uint)("n", "nn", "nn", 1u, "NN");
	optNN.helpMessage = "Search should return NN nearest-neighbors";
	
	auto optChecks = new StringOption("c", "checks", "checks", "32", "RANGE(b:e:s)");
	optChecks.helpMessage = "Stop searching after exploring NUM features.";
	
	auto optNumTrees = new NumericOption!(uint)("r", "trees", "num_trees", 1u, "NUM");
	optNumTrees.helpMessage = "Number of trees to build (default: 1).";
	
	auto optBranching = new NumericOption!(uint)("b", "branching", "branching", 2u, "NUM");
	optBranching.helpMessage = "Branching factor (where applicable, for example kmeans) (default: 2).";
	
	auto optClusterFile = new StringOption("f", "cluster-file", "cluster_file", null, "FILE");
	optClusterFile.helpMessage = "Clusters save file.";
	
	auto optClusters = new NumericOption!(uint)("k", "clusters", "clusters", 100u, "NUM");
	optClusters.helpMessage = "Number of clusters to save.";
		
	auto optNoTest = new FlagTrueOption("S", "skip-test", "skip_test");
	optNoTest.helpMessage = "Skip test phase";
	
	auto optVerbosity = new StringOption("v", "verbosity", "verbosity", "info", "VALUE");
	optVerbosity.helpMessage = "Stop searching after exploring NUM features.";
	
	auto optSkipMatches = new NumericOption!(uint)("K", "skip-matches", "skip_matches", 0u, "NUM");
	optSkipMatches.helpMessage = "Skip the first NUM matches at test phase.";
	
	auto optRandom = new BoolOption("R", "random", "random");
	optRandom.helpMessage = "Build random (kmeans-like) tree";
	
	auto optCenters = new StringOption("C", "centers", "centers", "random", "VALUE");
	optCenters.helpMessage = "Algorithms for choosing initial kmeans centers.";
	
	auto optComputeGT = new FlagTrueOption("G", "compute-gt", "compute_gt");
	optComputeGT.helpMessage = "Computer ground truth";
	
	auto optHelp = new FlagTrueOption("h", "help", "help");
	optHelp.helpMessage = "Show help message";

	
	// Next, add these options to the parser
	optParser.addOption(optAlgo);
	optParser.addOption(optPrintAlgos);
	optParser.addOption(optInputFile);
	optParser.addOption(optTestFile);
	optParser.addOption(optMatchFile);
	optParser.addOption(optSaveFile);
	optParser.addOption(optLoadFile);
	optParser.addOption(optNN);
	optParser.addOption(optChecks);
	optParser.addOption(optNumTrees);
	optParser.addOption(optBranching);
	optParser.addOption(optNoTest);
	optParser.addOption(optClusterFile);
	optParser.addOption(optClusters);
	optParser.addOption(optVerbosity);
	optParser.addOption(optSkipMatches);
	optParser.addOption(optRandom);
	optParser.addOption(optCenters);
	optParser.addOption(optComputeGT);
	optParser.addOption(optHelp);

	// Now we can finally parse our own command line
	optParser.parse(args[1..$]);

	string verbosity = unbox!(string)(optParser["verbosity"]);
	string[] logLevels = split(verbosity,",");
	foreach (logLevel;logLevels) {
		Logger.enableLevel(logLevel);
	}


	// Check to see if --help was supplied
	if( unbox!(bool)(optParser["help"]) )
	{
			Logger.log(Logger.ERROR,"Usage: %s [OPTIONS] FILES\n", args[0]);
			Logger.log(Logger.ERROR,"\n");
			optParser.showHelp();
			Logger.log(Logger.ERROR,"\n");
			exit(0);
	}
	
	
	if (unbox!(bool)(optParser["compute_gt"]) ) {
		if (optParser.positionalArgs.length != 3) {
			throw new Exception("Compute ground truth options expects three file names");
		}
		compute_gt(optParser.positionalArgs[0],optParser.positionalArgs[1],optParser.positionalArgs[2]);
		exit(0);
	}
	
	
	if( unbox!(bool)(optParser["print-algorithms"]) )
	{
		Logger.log(Logger.ERROR,"Available algorithms:\n");
		foreach (algo,val; indexRegistry) {
			Logger.log(Logger.ERROR,"\t%s\n",algo);
		}
		Logger.log(Logger.ERROR,"\n");
		exit(0);
	}


	char[] inputFile = unbox!(char[])(optParser["input_file"]);
	char[] testFile = unbox!(char[])(optParser["test_file"]);
	char[] matchFile = unbox!(char[])(optParser["match_file"]);
	char[] saveFile = unbox!(char[])(optParser["save_file"]);
	char[] loadFile = unbox!(char[])(optParser["load_file"]);
	char[] algorithm = unbox!(char[])(optParser["algorithm"]);
	uint nn = unbox!(uint)(optParser["nn"]);
	Range checks = new Range(unbox!(string)(optParser["checks"]));
	bool skipTest = unbox!(bool)(optParser["skip_test"]);
	int clusters = unbox!(uint)(optParser["clusters"]);
	char[] clusterFile = unbox!(char[])(optParser["cluster_file"]);
	uint skipMatches = unbox!(uint)(optParser["skip_matches"]);

	Params params;
	params.numTrees = unbox!(uint)(optParser["num_trees"]);
	params.branching = unbox!(uint)(optParser["branching"]);
	params.random = unbox!(bool)(optParser["random"]);
	params.centersAlgorithm = unbox!(string)(optParser["centers"]);

	if (!(algorithm in indexRegistry)) {
		Logger.log(Logger.ERROR,"Algorithm not supported.\n");
		Logger.log(Logger.ERROR,"Available algorithms:\n");
		foreach (algo,val; indexRegistry) {
			Logger.log(Logger.ERROR,"\t%s\n",algo);
		}
		Logger.log(Logger.ERROR,"Bailing out...\n");
		exit(0);
	}
	Logger.log(Logger.INFO,"Algorithm: %s\n",algorithm);


	Features inputData = null;

	NNIndex index;
	if (loadFile !is null) {
		Logger.log(Logger.INFO,"Loading index from file %s... ",loadFile);
		fflush(stdout);
		index = loadIndexRegistry[algorithm](loadFile);
/+		Serializer s = new Serializer(loadFile, FileMode.In);
		AgglomerativeExTree index2;
		s.describe(index2);
		index = index2;+/
		Logger.log(Logger.INFO,"done\n");
	}
	else {
	
		if (inputFile=="-") { //read from stdin
			Logger.log(Logger.INFO,"Reading input data from stdin...\n");
			inputData = new Features();
			inputData.readFromFile(null); 
		}
		else if (inputFile !is null) {
			showOperation( "Reading input data from %s".format(inputFile), {
				inputData = new Features();
				inputData.readFromFile(inputFile);
			});
		}
	
		if (inputData is null) {
			throw new Exception("No input data given.");
		}
		index = indexRegistry[algorithm](inputData, params);
		
		Logger.log(Logger.INFO,"Building index... \n");
		clock_t startTime = clock();
		index.buildIndex();
		float elapsed = (cast(float) clock() - startTime) / CLOCKS_PER_SEC;
		
		Logger.log(Logger.INFO,"Time to build %d tree%s for %d vectors: %5.2f seconds\n\n",
			index.numTrees, index.numTrees == 1 ? "" : "s", index.size, elapsed);
		Logger.log(Logger.SIMPLE,"%f\n",elapsed);
	}
	
	
	if (clusterFile !is null) {
		
		float[][] centers = index.getClusterCenters(clusters);
		
		Logger.log(Logger.INFO,"Writing %d cluster centers to file %s... ", centers.length, clusterFile);
		fflush(stdout);
		writeToFile(centers, clusterFile);
		Logger.log(Logger.INFO,"done\n");
	}
	
	if (!skipTest) {
	
		Features testData;
		if ((testFile is null) && (inputData !is null)) {
			testData = inputData;
		}
		else if (testFile !is null) {
			Logger.log(Logger.INFO,"Reading test data from %s... ",testFile);
			fflush(stdout);
			testData = new Features();
			testData.readFromFile(testFile);
			Logger.log(Logger.INFO,"done\n");
		}
			
		if (testData is null) {
			throw new Exception("No test data given.");
		}
		
		if (matchFile !is null) {
			testData.readMatches(matchFile);
		}
		
		if (testData.match is null) {
			throw new Exception("There are no correct matches to compare to, aborting test phase.");
		}
		
		for (int c=checks.begin;c<checks.end;c+=checks.skip) {
			testNNIndex(index,testData, nn, c, skipMatches);
		}
	}
	
	if (saveFile !is null) {
		Logger.log(Logger.INFO,"Saving index to file %s... ",saveFile);
		fflush(stdout);
		index.save(saveFile);
		Logger.log(Logger.INFO,"done\n");
	}

	
	
	return 0;
}



