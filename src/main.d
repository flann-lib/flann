
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

import optparse;
import kdtree;
import agglomerativetree;
import agglomerativetree2;
import util;
import resultset;
import features;
import nnindex;
import kmeans;
import bottom_up_agg_simple;
import bottom_up_agg;
import balltree;





void testNNIndex(NNIndex index, Features testData, int nn, int checks)
{
	writefln("Building index...");

	clock_t startTime = clock();
	index.buildIndex();
	
	float elapsed = (cast(float) clock() - startTime) / CLOCKS_PER_SEC;
	
	writef("Time to build %d tree%s for %d vectors: %5.2f seconds\n\n",
		index.numTrees, index.numTrees == 1 ? "" : "s", index.size, elapsed);

	writef("  Nodes    %% correct   %% of good     Time     Time/vector\n"
			" checked   neighbors    matches    (seconds)      (ms)\n"
			" -------   ---------   ---------   ---------  -----------\n");

	/* Create a table showing computation time and accuracy as a function
	   of "checks", the number of neighbors that are checked.
	   Note that we should check average of at least 2 nodes per random
	   tree, as first neighbor found is just the query vector itself.
	   Print statistics on success rate and time for value.
	 */

	ResultSet resultSet = new ResultSet(nn+1);
	
	startTime = clock();
	
	int correct, cormatch, match;
	correct = cormatch = match = 0;

	for (int i = 0; i < testData.count; i++) {
//	for (int i = 0; i < 1; i++) {
	
		resultSet.init(testData.vecs[i]);

		index.findNeighbors(resultSet,testData.vecs[i], checks);			
		int nn_index = resultSet.getPointIndex(1);

	
		if (testData.mtype[i])
			match++;
		/* Note that closest vector will have distance of 0, as it is the same
			vector.  Therefore, we use second neighbor, result[1].
			*/
		if (nn_index == testData.match[i]) {
			correct++;
			if (testData.mtype[i])
				cormatch++;
		}
	}
	elapsed = (cast(float) clock() - startTime) / CLOCKS_PER_SEC;
	writef("  %5d     %6.2f      %6.2f      %6.2f      %6.3f\n",
			checks, correct * 100.0 / cast(float) testData.count,
			cormatch * 100.0 / cast(float) match,
			elapsed, 1000.0 * elapsed / testData.count);
	
//		delete index;

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
	
	auto optInputFile = new StringOption("i", "input", "input_file", "-", "FILE");
	optInputFile.helpMessage = "Read input vectors from FILE";
	
	auto optTestFile = new StringOption("t", "test", "test_file", null, "FILE");
	optTestFile.helpMessage = "Read test vectors from FILE (if not given the input file is used)";
	
	auto optNN = new NumericOption!(uint)("n", "nn", "nn", 1u, "NN");
	optNN.helpMessage = "Search should return NN nearest-neighbors";
	
	auto optChecks = new NumericOption!(uint)("c", "checks", "checks", 32u, "NUM");
	optChecks.helpMessage = "Stop searching after exploring NUM features.";
	
	auto optNumTrees = new NumericOption!(uint)("r", "trees", "num_trees", 4u, "NUM");
	optNumTrees.helpMessage = "Number of trees to build (default: 4).";
	
	auto optBranching = new NumericOption!(uint)("b", "branching", "branching", 2u, "NUM");
	optBranching.helpMessage = "Branching factor (where applicable, for example kmeans) (default: 2).";
	
	auto optHelp = new FlagTrueOption("h", "help", "help");
	optHelp.helpMessage = "Show help message";
	
	
	// Next, add these options to the parser
	optParser.addOption(optAlgo);
	optParser.addOption(optInputFile);
	optParser.addOption(optTestFile);
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

	char[] inputFile = unbox!(char[])(optParser["input_file"]);
	if (inputFile is null) {
		writefln("Input file is required.");
		exit(1);
	}
	
	char[] testFile = unbox!(char[])(optParser["test_file"]);
	char[] algorithm = unbox!(char[])(optParser["algorithm"]);
	uint nn = unbox!(uint)(optParser["nn"]);
	uint checks = unbox!(uint)(optParser["checks"]);
	uint numTrees = unbox!(uint)(optParser["num_trees"]);
	uint branching = unbox!(uint)(optParser["branching"]);

	Features inputData = new Features();
	if (inputFile=="-") { //read from stdin
		inputData.readFromFile(null); 
	}
	else {
		inputData.readFromFile(inputFile);
	}
	
	Features testData;
	if (testFile is null) {
		testData = inputData;
	}
	else {
		testData = new Features();
		testData.readFromFile(testFile);
	}


	NNIndex index;
	
	writef("Algorithm: %s\n",algorithm);
	if (algorithm=="kdtree") {
		index = new KDTree(inputData.vecs, inputData.veclen, numTrees);
	}
	else if (algorithm=="aggnn") {
		index = new AgglomerativeTree(inputData);
	}
	else if (algorithm=="aggnnex") {
		index = new AgglomerativeExTree(inputData);
	}
	else if (algorithm=="agg_bu") {
		index = new BottomUpAgglomerativeTree(inputData);
	}
	else if (algorithm=="agg_bu_simple") {
		index = new BottomUpSimpleAgglomerativeTree(inputData);
	}
	else if (algorithm=="kmeans") {
		index = new KMeansTree(inputData, branching);
	}
	else if (algorithm=="balltree") {
		index = new BallTree(inputData);
	} 
	else if (algorithm=="linear") {
		index = new LinearSearch(inputData);
	} 
	else {
		throw new Exception("No such algorithm.");
	}
		
	testNNIndex(index,testData, nn, checks);
	
	return 0;
}



