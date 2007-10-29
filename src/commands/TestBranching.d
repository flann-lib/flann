module commands.TestBranching;

import std.string;
import std.boxer;

import commands.GenericCommand;
import commands.DefaultCommand;
import util.logger;
import util.registry;
import util.utils;
import util.profiler;
import nn.testing;
import dataset.features;
import algo.nnindex;
import algo.kmeans;
import output.console;


static this() {
 	register_command!(TestBranching);
}

class TestBranching : DefaultCommand
{
	public static string NAME = "test_branching";
	
	string testFile;
	string matchFile;
	uint nn;
	uint trees;
	double precision;
	uint skipMatches;
	string inputFile;
	string branching;
	bool byteFeatures;
	string centersAlgorithm;
	uint maxIter;
	
	
	this(string name) 
	{
		super(name);
		register(inputFile,"i","input-file", "","Name of file with input dataset.");
		register(branching,"b","branching", "2:512:2","Branching factor range in the form: start:end:skip.");
		register(trees,"r","trees", 1,"Number of parallel trees to use (where available, for example kdtree).");
		register(byteFeatures,"B","byte-features", null ,"Use byte-sized feature elements.");
		register(centersAlgorithm,"C","centers-algorithm", "random","Algorithm to choose cluster centers for kmeans (default: random).");
		register(maxIter,"M","max-iterations", uint.max,"Max iterations to perform for kmeans (default: until convergence).");	register(testFile,"t","test-file", "","Name of file with test dataset.");
		register(matchFile,"m","match-file", "","File containing ground-truth matches.");
		register(nn,"n","nn", 1,"Number of nearest neighbors to search for.");
		register(precision,"P","precision", -1,"The desired precision.");
		register(skipMatches,"K","skip-matches", 0u,"Skip the first NUM matches at test phase.");
 			
 		description = " Run algorithm for several different branching factors.";
	}
	
	
	
	private void executeWithType(T)() 
	{
		Features!(T) inputData = null;
		if (inputFile != "") {
			showOperation( "Reading input data from %s".format(inputFile), {
				inputData = new Features!(T)();
				inputData.readFromFile(inputFile);
			});
		}
	
		if (inputData is null) {
			throw new Exception("No input data given.");
		}
		
		
		Features!(float) testData;
/+		if ((testFile == "") && (inputData !is null)) {
			testData = inputData;
		}
		else +/
		if (testFile != "") {
			showOperation("Reading test data from %s".format(testFile),{
				testData = new Features!(float)();
				testData.readFromFile(testFile);
			});
		}
		if (testData is null) {
			throw new Exception("No test data given.");
		}
		
		
		if (matchFile != "") {
			testData.readMatches(matchFile);
		}
		
		if (testData.match is null) {
			throw new Exception("There are no correct matches to compare to, aborting test phase.");
		}

		
		Params params;
		copyParams(params,optParser,["trees", "centers-algorithm","max-iterations"]);
		
		params["branching"] = box(2);
		
		
		auto index = new KMeansTree!(T)(inputData, params);
		
		
		Range range = new Range(branching);
		
		assert(precision>=0 && precision<=100);
		
		for(int br = range.begin;br<range.end;br+=range.skip) {
			index.branching = br;
		
			Logger.log(Logger.INFO,"Building index... \n");
			float indexTime = profile({
				index.buildIndex();
			});
			
			Logger.log(Logger.INFO,"Time to build %d tree%s for %d vectors: %5.2f seconds\n\n",
				index.numTrees, index.numTrees == 1 ? "" : "s", index.size, indexTime);
			Logger.log(Logger.SIMPLE,"%f\n",indexTime);
		
			int checks;
			testNNIndexPrecisionAlt!(true,true)(index,testData, precision, checks, nn, skipMatches);
		}
	}	
	
	void execute() 
	{
		if (byteFeatures) {
			executeWithType!(ubyte)();
		} else {
			executeWithType!(float)();
		}		
	}
}