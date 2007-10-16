module commands.AutotuneRunTestCommand;

import std.string;
import std.c.stdlib;

import commands.GenericCommand;
import commands.DefaultCommand;
import util.logger;
import util.registry;
import util.utils;
import util.profiler;
import nn.autotune;
import nn.testing;
import dataset.features;
import algo.nnindex;
import algo.kmeans;
import output.console;


static this() {
 	register_command!(AutotuneRunTestCommand);
}

class AutotuneRunTestCommand : DefaultCommand
{
	public static string NAME = "autotune_run_test";
	
	string inputFile;
	string testFile;
	string matchFile;
	uint nn;
	double precision;
	double indexFactor;
	uint skipMatches;
	bool byteFeatures;

	protected {
		NNIndex index;
		
		template inputData(T) {
			Features!(T) inputData;
		}
	}



	this(string name) 
	{
		super(name);
		register(inputFile,"i","input-file", "","Name of file with input dataset.");
		register(byteFeatures,"B","byte-features", 2,"Use byte-sized feature elements.");
/+		register(trees,"r","trees", 1,"Number of parallel trees to use (where available, for example kdtree).");
		register(branching,"b","branching", 2,"Branching factor (where applicable, for example kmeans) (default: 2).");
		register(centersAlgorithm,"C","centers-algorithm", "random","Algorithm to choose cluster centers for kmeans (default: random).");
		register(maxIter,"M","max-iterations", uint.max,"Max iterations to perform for kmeans (default: until convergence).");		+/
		
		register(testFile,"t","test-file", "","Name of file with test dataset.");
		register(matchFile,"m","match-file", "","File containing ground-truth matches.");
		register(nn,"n","nn", 1,"Number of nearest neighbors to search for.");
// 		register(checkList,"c","checks", "32","Number of times to restart search (in best-bin-first manner).");
		register(precision,"P","precision", -1,"The desired search precision.");
		register(indexFactor,"f","index-factor", 0,"Index build time penalty factor (relative to search time).");
		register(skipMatches,"K","skip-matches", 0u,"Skip the first NUM matches at test phase.");
 			
 		description = "Build index with autotuned parameters and test the index against the test dataset (ground truth given in the match file).";
	}
	
	
	
	
	private void executeWithType(T)()
	{
	
		// read input data		
		if (inputFile != "") {
			showOperation( "Reading input data from %s".format(inputFile), {
				inputData!(T) = new Features!(T)();
				inputData!(T).readFromFile(inputFile);
			});
		}	
		if (inputData!(T) is null) {
			throw new Exception("No input data given.");
		}
		
		// read test data
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
		
		// read ground-truth matches
		if (matchFile != "") {
			testData.readMatches(matchFile);
		}		
		if (testData.match is null) {
			throw new Exception("There are no correct matches to compare to, aborting test phase.");
		}

		Params params = estimateOptimalParams!(T)(inputData!(T), testData, precision, indexFactor);
		
		string algorithm = params["algorithm"].get!(string);
		
/+		if (!byteFeatures) {
			index = indexRegistry[algorithm](inputData, params);
		} else {
			index = new KMeansTree!(ubyte)(inputDataByte,params);
		}+/
		
		Logger.log(Logger.INFO,"Building index... \n");
		float indexTime = profile( {
			index.buildIndex();
		});
		
		Logger.log(Logger.INFO,"Time to build %d tree%s for %d vectors: %5.2f seconds\n\n",
			index.numTrees, index.numTrees == 1 ? "" : "s", index.size, indexTime);
		Logger.log(Logger.SIMPLE,"%f\n",indexTime);

		uint checks = params["checks"].get!(int);
		testNNIndex(index,testData, nn, checks, skipMatches);
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