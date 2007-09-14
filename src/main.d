
/************************************************************************
Project: nn

  Demo software: Approximate Nearest-Neighbor Matching
  Converted from C
Author: Marus Muja (2007)

*************************************************************************/
module main;

import std.stdio;
import std.string;
import std.boxer;
import std.c.stdlib;
import std.c.math;
import std.conv;


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
import util.dataset_generator;
import util.timer;
import util.registry;	


void testNNIndex(NNIndex index, Features!(float) testData, int nn, int checks, uint skipMatches)
{
	Logger.log(Logger.INFO,"Searching... \n");
	/* Create a table showing computation time and accuracy as a function
	   of "checks", the number of neighbors that are checked.
	   Note that we should check average of at least 2 nodes per random
	   tree, as first neighbor found is just the query vector itself.
	   Print statistics on success rate and time for value.
	 */

	ResultSet resultSet = new ResultSet(nn+skipMatches);
	
	auto timer = new StartStopTimer();
	timer.start();
	
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

	timer.stop();
	float elapsed = timer.value;
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


void computeNearestNeighbors(string outputFile, NNIndex index, Features!(float) testData, int nn, int checks, uint skipMatches)
{
	FILE* fout = fopen(toStringz(outputFile), "w");
	
	if (fout==null) {
		throw new Exception("Cannot open file: "~outputFile);
	}

	Logger.log(Logger.INFO,"Searching... \n");

	ResultSet resultSet = new ResultSet(nn+skipMatches);
			
	int correct, cormatch, match;
	correct = cormatch = match = 0;

	showProgressBar(testData.count, 70, (Ticker tick){
		for (int i = 0; i < testData.count; i++) {
			tick();
			
			resultSet.init(testData.vecs[i]);
	
			index.findNeighbors(resultSet,testData.vecs[i], checks);			
			
			for (int j=0;j<nn;++j) {
				if (j!=0) {
					fwritef(fout," ");
				}
				fwritef(fout,"%d",resultSet.getPointIndex(j+skipMatches));
			}
			fwritef(fout,"\n");
		}
	});

	fclose(fout);
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


OptionParser parseArguments(char[][] args)
{
	// Create our option parser
	auto optParser = new OptionParser();
	
	auto optAlgo = new StringOption("a", "algorithm", "algorithm", null, "ALGO");
	optAlgo.helpMessage = "Use the ALGO nn search algorithm";
	optParser.addOption(optAlgo);
	
	auto optPrintAlgos = new FlagTrueOption("p", "print-algorithms", "print-algorithms");
	optPrintAlgos.helpMessage = "Display available algorithms";
	optParser.addOption(optPrintAlgos);
	
	auto optInputFile = new StringOption("i", "input", "input_file", null, "FILE");
	optInputFile.helpMessage = "Read input vectors from FILE";
	optParser.addOption(optInputFile);
	
	auto optTestFile = new StringOption("t", "test", "test_file", null, "FILE");
	optTestFile.helpMessage = "Read test vectors from FILE (if not given the input file is used)";
	optParser.addOption(optTestFile);
	
	auto optMatchFile = new StringOption("m", "match", "match_file", null, "FILE");
	optMatchFile.helpMessage = "The match file.";
	optParser.addOption(optMatchFile);
	
	auto optSaveFile = new StringOption("s", "save", "save_file", null, "FILE");
	optSaveFile.helpMessage = "Save the built index to this file.";
	optParser.addOption(optSaveFile);
	
	auto optLoadFile = new StringOption("l", "load", "load_file", null, "FILE");
	optLoadFile.helpMessage = "Load the index from this file. The type of index (algorithm) must be specified.";
	optParser.addOption(optLoadFile);
	
	auto optNN = new NumericOption!(uint)("n", "nn", "nn", 1u, "NN");
	optNN.helpMessage = "Search should return NN nearest-neighbors";
	optParser.addOption(optNN);
	
	auto optChecks = new StringOption("c", "checks", "checks", "32", "NUM1,NUM2,...");
	optChecks.helpMessage = "Stop searching after exploring NUM features.";
	optParser.addOption(optChecks);
	
	auto optNumTrees = new NumericOption!(uint)("r", "trees", "num_trees", 1u, "NUM");
	optNumTrees.helpMessage = "Number of trees to build (default: 1).";
	optParser.addOption(optNumTrees);
	
	auto optBranching = new NumericOption!(uint)("b", "branching", "branching", 2u, "NUM");
	optBranching.helpMessage = "Branching factor (where applicable, for example kmeans) (default: 2).";
	optParser.addOption(optBranching);
	
	auto optClusterFile = new StringOption("f", "cluster-file", "cluster_file", null, "FILE");
	optClusterFile.helpMessage = "Clusters save file.";
	optParser.addOption(optClusterFile);
	
	auto optClusters = new NumericOption!(uint)("k", "clusters", "clusters", 100u, "NUM");
	optClusters.helpMessage = "Number of clusters to save.";
	optParser.addOption(optClusters);
		
	auto optNoTest = new FlagTrueOption("S", "skip-test", "skip_test");
	optNoTest.helpMessage = "Skip test phase";
	optParser.addOption(optNoTest);
	
	auto optOutputFile = new StringOption("o", "output-file", "output_file", null, "FILE");
	optOutputFile.helpMessage = "File to save the nearest neighbors to.";
	optParser.addOption(optOutputFile);
	
	auto optVerbosity = new StringOption("v", "verbosity", "verbosity", "info", "VALUE");
	optVerbosity.helpMessage = "Stop searching after exploring NUM features.";
	optParser.addOption(optVerbosity);
	
	auto optSkipMatches = new NumericOption!(uint)("K", "skip-matches", "skip_matches", 0u, "NUM");
	optSkipMatches.helpMessage = "Skip the first NUM matches at test phase.";
	optParser.addOption(optSkipMatches);
	
	auto optRandom = new BoolOption("R", "random", "random");
	optRandom.helpMessage = "Build random (kmeans-like) tree";
	optParser.addOption(optRandom);
	
	auto optCenters = new StringOption("C", "centers", "centers", "random", "VALUE");
	optCenters.helpMessage = "Algorithms for choosing initial kmeans centers.";
	optParser.addOption(optCenters);
	
	auto optComputeGT = new FlagTrueOption("G", "compute-gt", "compute_gt");
	optComputeGT.helpMessage = "Computer ground truth";
	optParser.addOption(optComputeGT);
	
	auto optGenerateRandom = new FlagTrueOption("E", "generate-random", "generate_random");
	optGenerateRandom.helpMessage = "Generate random dataset (options: output_file, feature count, feature length)";
	optParser.addOption(optGenerateRandom);
	
	auto optByte = new FlagTrueOption("B", "byte", "byte");
	optByte.helpMessage = "Use byte storage for feature elements";
	optParser.addOption(optByte);
	
	auto optHelp = new FlagTrueOption("h", "help", "help");
	optHelp.helpMessage = "Show help message";
	optParser.addOption(optHelp);

	// Now we can finally parse our own command line
	optParser.parse(args[1..$]);
	
	return optParser;
}



/** 
	Program entry point 
*/
void main(char[][] args)
{
	Logger.enableLevel(Logger.ERROR);
	std.gc.disable();

	auto optParser = parseArguments(args);

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
			throw new Exception("Compute ground truth option expects three file names");
		}
		if ( unbox!(bool)(optParser["byte"])) {
			compute_gt!(ubyte)(optParser.positionalArgs[0],optParser.positionalArgs[1],optParser.positionalArgs[2], unbox!(uint)(optParser["skip_matches"]));
		}
		else {
			compute_gt!(float)(optParser.positionalArgs[0],optParser.positionalArgs[1],optParser.positionalArgs[2], unbox!(uint)(optParser["skip_matches"]));
		}
		exit(0);
	}
	
	if (unbox!(bool)(optParser["generate_random"]) ) {
		if (optParser.positionalArgs.length != 3) {
			throw new Exception("Generate random dataset option expects three arguments:output_file, feature count, feature length");
		}
		generateRandomDataset(optParser.positionalArgs[0],toInt(optParser.positionalArgs[1]),toInt(optParser.positionalArgs[2]));
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
	int[] checks = toVec!(int)(split(unbox!(string)(optParser["checks"]),","));
	bool skipTest = unbox!(bool)(optParser["skip_test"]);
	int clusters = unbox!(uint)(optParser["clusters"]);
	char[] clusterFile = unbox!(char[])(optParser["cluster_file"]);
	uint skipMatches = unbox!(uint)(optParser["skip_matches"]);
	char[] outputFile = unbox!(char[])(optParser["output_file"]);
	bool byte_features = unbox!(bool)(optParser["byte"]);

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


	Features!(float) inputData = null;
	Features!(ubyte) inputDataByte = null;

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
			inputData = new Features!(float)();
			inputData.readFromFile(null); 
		}
		else if (inputFile !is null) {
			showOperation( "Reading input data from %s".format(inputFile), {
				if (!byte_features) {
					inputData = new Features!(float)();
					inputData.readFromFile(inputFile);
				}
				else {
					inputDataByte = new Features!(ubyte)();
					inputDataByte.readFromFile(inputFile);
				}
			});
		}
	
		if (inputData is null && inputDataByte is null) {
			throw new Exception("No input data given.");
		}
		
		if (! byte_features) {
			index = indexRegistry[algorithm](inputData, params);
		} else {
			index = new KMeansTree!(ubyte)(inputDataByte,params);
		}
		
		Logger.log(Logger.INFO,"Building index... \n");
		auto timer = new StartStopTimer();
		timer.start();
		index.buildIndex();
		timer.stop();
		float elapsed = timer.value;
		
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
	
		Features!(float) testData;
		if ((testFile is null) && (inputData !is null)) {
			testData = inputData;
		}
		else if (testFile !is null) {
			Logger.log(Logger.INFO,"Reading test data from %s... ",testFile);
			fflush(stdout);
			testData = new Features!(float)();
			testData.readFromFile(testFile);
			Logger.log(Logger.INFO,"done\n");
		}
			
		if (testData is null) {
			throw new Exception("No test data given.");
		}
		
		
		if (outputFile !is null) {
			computeNearestNeighbors(outputFile, index,testData, nn, checks[0], skipMatches);
		} else {
			if (matchFile !is null) {
				testData.readMatches(matchFile);
			}
			
			if (testData.match is null) {
				throw new Exception("There are no correct matches to compare to, aborting test phase.");
			}
			
			foreach (c;checks) {
				testNNIndex(index,testData, nn, c, skipMatches);
			}
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



