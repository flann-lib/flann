module commands.RunTestCommand;

import std.string;

import commands.GenericCommand;
import commands.IndexCommand;
import util.logger;
import util.registry;
import util.utils;
import util.profiler;
import nn.testing;
import dataset.features;
import algo.nnindex;
import algo.kmeans;
import console.progressbar;


static this() {
	register_command(new RunTestCommand(RunTestCommand.NAME));
}

class RunTestCommand : IndexCommand
{
	public static string NAME = "run_test";
	
	string testFile;
	string matchFile;
	uint nn;
	double precision;
	uint skipMatches;
	string inputFile;
	string algorithm;
	uint trees;
	string branching;
	bool byteFeatures;
	string centersAlgorithm;
	uint maxIter;
	
	
	this(string name) 
	{
		super(name);
		register(inputFile,"i","input-file", "","Name of file with input dataset.");
		register(algorithm,"a","algorithm", "","The algorithm to use when constructing the index (kdtree, kmeans...).");
		register(trees,"r","trees", 1,"Number of parallel trees to use (where available, for example kdtree).");
		register(branching,"b","branching", 2,"Branching factor (where applicable, for example kmeans) (default: 2).");
		register(byteFeatures,"B","byte-features", null ,"Use byte-sized feature elements.");
		register(centersAlgorithm,"C","centers-algorithm", "random","Algorithm to choose cluster centers for kmeans (default: random).");
		register(maxIter,"M","max-iterations", uint.max,"Max iterations to perform for kmeans (default: until convergence).");		register(testFile,"t","test-file", "","Name of file with test dataset.");
		register(matchFile,"m","match-file", "","File containing ground-truth matches.");
		register(nn,"n","nn", 1,"Number of nearest neighbors to search for.");
		register(precision,"P","precision", -1,"The desired precision.");
		register(skipMatches,"K","skip-matches", 0u,"Skip the first NUM matches at test phase.");
 			
 		description = " Run algorithm for several different branching factors.";
	}
	
	
	
	private void executeWithType(T)() 
	{
		if (!(algorithm in indexRegistry!(T))) {
			Logger.log(Logger.ERROR,"Algorithm not supported.\n");
			Logger.log(Logger.ERROR,"Available algorithms:\n");
			foreach (algo,val; indexRegistry!(T)) {
				Logger.log(Logger.ERROR,"\t%s\n",algo);
			}
			throw new Exception("Bailing out...\n");
		}
		
		if (inputFile != "") {
			showOperation( "Reading input data from %s".format(inputFile), {
				inputData!(T) = new Features!(T)();
				inputData!(T).readFromFile(inputFile);
			});
		}
	
		if (inputData!(T) is null) {
			throw new Exception("No input data given.");
		}
		
		Logger.log(Logger.INFO,"Algorithm: %s\n",algorithm);
		
		Params params;
		copyParams(params,optParser,["trees","branching", "centers-algorithm","max-iterations"]);
		
		index = indexRegistry!(T)[algorithm](inputData!(T), params);
		
		
		
		
		Logger.log(Logger.INFO,"Building index... \n");
		float indexTime = profile({
			index.buildIndex();
		});
		
		Logger.log(Logger.INFO,"Time to build %d tree%s for %d vectors: %5.2f seconds\n\n",
			index.numTrees, index.numTrees == 1 ? "" : "s", index.size, indexTime);
		Logger.log(Logger.SIMPLE,"%f\n",indexTime);

// 		if (saveFile !is null) {
// 			Logger.log(Logger.INFO,"Saving index to file %s... ",saveFile);
// 			fflush(stdout);
// 			index.save(saveFile);
// 			Logger.log(Logger.INFO,"done\n");
// 		}
	}	
	
	
	
	void execute() 
	{
		super.execute();
		
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

		assert(precision>=0 && precision<=100);
		testNNIndexExactPrecision(index,testData, nn, precision, skipMatches);

	}
	

	
}