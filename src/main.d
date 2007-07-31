
/************************************************************************
Project: aggnn

  Demo software: Approximate Nearest-Neighbor Matching
  Converted from C
Author: David Lowe (2006)

testnn.c:
This file contains a sample program to read files of vectors and then
perform tests of approximate nearest-neighbor matching.

To run a test, use an input file such as sift10K.nn for standard input:
% testnn <sift10K.nn

 *************************************************************************/


import std.stdio;
import std.string;
import std.boxer;
import std.c.stdlib;
import std.c.math;
import std.c.time;


import util.optparse;
import util.utils;
import util.resultset;
import util.features;
import algo.kdtree;
import algo.agglomerativetree2;
import algo.nnindex;
import algo.kmeans;
import algo.bottom_up_agg_simple;
import algo.balltree;
import algo.linearsearch;







void testNNIndex(NNIndex index, Features testData, int nn, int checks)
{
	writef("Searching... ");
	fflush(stdout);
	/* Create a table showing computation time and accuracy as a function
	   of "checks", the number of neighbors that are checked.
	   Note that we should check average of at least 2 nodes per random
	   tree, as first neighbor found is just the query vector itself.
	   Print statistics on success rate and time for value.
	 */

	ResultSet resultSet = new ResultSet(nn+1);
	
	clock_t startTime = clock();
	
	int correct, cormatch, match;
	correct = cormatch = match = 0;

 	for (int i = 0; i < testData.count; i++) {
//  	for (int i = 18; i < 19; i++) {
	
		resultSet.init(testData.vecs[i]);

		index.findNeighbors(resultSet,testData.vecs[i], checks);			
		int nn_index = resultSet.getPointIndex(1);

	
/+		if (testData.mtype[i])
			match++;+/
		/* Note that closest vector will have distance of 0, as it is the same
			vector.  Therefore, we use second neighbor, result[1].
			*/
		if (nn_index == testData.match[i]) {
			correct++;
/+			if (testData.mtype[i])
				cormatch++;+/
		}
/+		else {
			writef("%d, got:  %d, expected: %d\n",i, nn_index, testData.match[i]);
		}+/
	}
	writefln("done");
	
	float elapsed = (cast(float) clock() - startTime) / CLOCKS_PER_SEC;
	writef("  Nodes    %% correct    Time     Time/vector\n"
			" checked   neighbors   (seconds)      (ms)\n"
			" -------   ---------   ---------  -----------\n");
	writef("  %5d     %6.2f      %6.2f      %6.3f\n",
			checks, correct * 100.0 / cast(float) testData.count,
			elapsed, 1000.0 * elapsed / testData.count);
	
}













/** 
	Program entry point 
*/
void main(char[][] args)
{
	 //	std.gc.disable();

	// Create our option parser
	auto optParser = new OptionParser();
	
	auto optAlgo = new StringOption("a", "algorithm", "algorithm", "kdtree", "ALGO");
	optAlgo.helpMessage = "Use the ALGO nn search algorithm (default: kdtree)";
	
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
	
	auto optChecks = new NumericOption!(int)("c", "checks", "checks", 32u, "NUM");
	optChecks.helpMessage = "Stop searching after exploring NUM features.";
	
	auto optNumTrees = new NumericOption!(uint)("r", "trees", "num_trees", 4u, "NUM");
	optNumTrees.helpMessage = "Number of trees to build (default: 4).";
	
	auto optBranching = new NumericOption!(uint)("b", "branching", "branching", 2u, "NUM");
	optBranching.helpMessage = "Branching factor (where applicable, for example kmeans) (default: 2).";
	
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
	optParser.addOption(optHelp);

	// Now we can finally parse our own command line
	optParser.parse(args[1..$]);

	// Check to see if --help was supplied
	if( unbox!(bool)(optParser["help"]) )
	{
			writefln("Usage: %s [OPTIONS] FILES", args[0]);
			writefln("");
			optParser.showHelp();
			writefln("");
			exit(0);
	}
	
	
	if( unbox!(bool)(optParser["print-algorithms"]) )
	{
		writefln("Available algorithms:");
		foreach (algo,val; indexRegistry) {
			writefln("\t%s",algo);
		}
		writefln();
		exit(0);
	}


	char[] inputFile = unbox!(char[])(optParser["input_file"]);
	char[] testFile = unbox!(char[])(optParser["test_file"]);
	char[] matchFile = unbox!(char[])(optParser["match_file"]);
	char[] saveFile = unbox!(char[])(optParser["save_file"]);
	char[] loadFile = unbox!(char[])(optParser["load_file"]);
	char[] algorithm = unbox!(char[])(optParser["algorithm"]);
	uint nn = unbox!(uint)(optParser["nn"]);
	int checks = unbox!(int)(optParser["checks"]);
	Params params;
	params.numTrees = unbox!(uint)(optParser["num_trees"]);
	params.branching = unbox!(uint)(optParser["branching"]);

	if (!(algorithm in indexRegistry)) {
		writefln("Algorithm not supported.");
		writefln("Available algorithms:");
		foreach (algo,val; indexRegistry) {
			writefln("\t%s",algo);
		}
		writefln("Bailing out...");
		exit(0);
	}
	writef("Algorithm: %s\n",algorithm);


	Features inputData = null;

	NNIndex index;
	if (loadFile !is null) {
		writef("Loading index from file %s... ",loadFile);
		fflush(stdout);
		index = loadIndexRegistry[algorithm](loadFile);
/+		Serializer s = new Serializer(loadFile, FileMode.In);
		AgglomerativeExTree index2;
		s.describe(index2);
		index = index2;+/
		writefln("done");
	}
	else {
	
		if (inputFile=="-") { //read from stdin
			writefln("Reading input data from stdin...");
			inputData = new Features();
			inputData.readFromFile(null); 
		}
		else if (inputFile !is null) {
			writef("Reading input data from %s... ",inputFile);
			fflush(stdout);
			inputData = new Features();
			inputData.readFromFile(inputFile);
			writefln("done");
		}
	
		if (inputData is null) {
			throw new Exception("No input data given.");
		}
		index = indexRegistry[algorithm](inputData, params);
		
		writefln("Building index... ");
		clock_t startTime = clock();
		index.buildIndex();
		float elapsed = (cast(float) clock() - startTime) / CLOCKS_PER_SEC;
		
		writef("Time to build %d tree%s for %d vectors: %5.2f seconds\n\n",
			index.numTrees, index.numTrees == 1 ? "" : "s", index.size, elapsed);
	}
	
	Features testData;
	if ((testFile is null) && (inputData !is null)) {
		testData = inputData;
	}
	else if (testFile !is null) {
		writef("Reading test data from %s... ",testFile);
		fflush(stdout);
		testData = new Features();
		testData.readFromFile(testFile);
		writefln("done");
	}
		
	if (testData is null) {
		throw new Exception("No test data given.");
	}
	
	if (matchFile !is null) {
		testData.readMatches(matchFile);
	}
	
	
	for (int i=0;i<20;++i) {
		writef("%d ",testData.match[i]);
	}
	
	if (testData.match is null) {
		throw new Exception("There are no correct matches to compare to, aborting test phase.");
	}
	
	testNNIndex(index,testData, nn, checks);
	
	if (saveFile !is null) {
		writef("Saving index to file %s... ",saveFile);
		fflush(stdout);
		index.save(saveFile);
		writefln("done");
	}

	
	
	return 0;
}



