module commands.IndexCommand;

// import std.string;
// import std.c.stdlib;

import commands.GenericCommand;
import commands.DefaultCommand;
import util.logger;
import util.registry;
import util.utils;
import util.profiler;
import dataset.features;
import algo.all;
import output.console;
import output.report;



class IndexCommand : DefaultCommand
{
	public static string NAME = "create_index";
	
	string inputFile;
	string paramsFile;
	string algorithm;
	uint trees;
	uint branching;
	bool byteFeatures;
	string centersAlgorithm;
	int maxIter;
	bool useParamsFile;
	
	protected {
		NNIndex index;
		
		template inputData(T) {
			Features!(T) inputData = null;
		}
		//Features!(ubyte) inputDataByte = null;
	}
	

	this(string name) 
	{
		super(name);
		register(inputFile,"i","input-file", "","Name of file with input dataset.");
		register(paramsFile,"p","params-file", "","File containing 'optimum' input dataset parameters.");
		register(algorithm,"a","algorithm", "","The algorithm to use when constructing the index (kdtree, kmeans...).");
		register(trees,"r","trees", 1,"Number of parallel trees to use (where available, for example kdtree).");
		register(branching,"b","branching", 2,"Branching factor (where applicable, for example kmeans) (default: 2).");
		register(byteFeatures,"B","byte-features", null ,"Use byte-sized feature elements.");
		register(centersAlgorithm,"C","centers-algorithm", "random","Algorithm to choose cluster centers for kmeans (default: random).");
		register(maxIter,"M","max-iterations", int.max,"Max iterations to perform for kmeans (default: until convergence).");		
		register(useParamsFile,"U","use-params-file", null,"Use the file with autotuned params.");		
 		
 		description = "Index the input dataset.";
	}
	
	
	private void executeWithType(T)() 
	{
		report("byte_features", byteFeatures?1:0);
		
// 		if (loadFile !is null) {
// 		Logger.log(Logger.INFO,"Loading index from file %s... ",loadFile);
// 		fflush(stdout);
// 		index = loadIndexRegistry[algorithm](loadFile);
// /+		Serializer s = new Serializer(loadFile, FileMode.In);
// 		AgglomerativeExTree index2;
// 		s.describe(index2);
// 		index = index2;+/
// 		Logger.log(Logger.INFO,"done\n");
// 		}
		
		if (inputFile != "") {
			showOperation( "Reading input data from "~inputFile, {
				inputData!(T) = new Features!(T)();
				inputData!(T).readFromFile(inputFile);
			});
		}
		
		report("dataset", inputFile);
		report("input_count", inputData!(T).count);
		report("input_size", inputData!(T).veclen);
	
		if (inputData!(T) is null) {
			throw new Exception("No input data given.");
		}
		
		Params params;
		
		if (maxIter==-1) {
			maxIter = int.max;
		}
				
		if (useParamsFile) {
			if (paramsFile == "") {
				paramsFile = inputFile~".params";
				Logger.log(Logger.INFO, "No params file given, trying ",paramsFile,"\n");
			}
			
			try {
				loadParams(paramsFile,params);
			}
			catch(Exception e) {
				Logger.log(Logger.INFO,"Cannot read params from file",paramsFile,"\n");
			}
		} else {
			params["trees"] = trees;
			params["branching"] = branching;
			params["centers-algorithm"] = centersAlgorithm;
			params["max-iterations"] = maxIter;
			params["algorithm"] = algorithm;
		}
		
		report("trees", params["trees"]);
		report("branching", params["branching"]);
		report("max_iterations", params["max-iterations"]);
		report("algorithm", params["algorithm"]);
		
		string algorithm = params["algorithm"].get!(string);
		
		if (!(algorithm in indexRegistry!(T))) {
			Logger.log(Logger.ERROR,"Algorithm not supported.\n");
			Logger.log(Logger.ERROR,"Available algorithms:\n");
			foreach (algo,val; indexRegistry!(T)) {
				Logger.log(Logger.ERROR,"      {}\n",algo);
			}			
			throw new Exception("Algorithm not found...bailing out...\n");
		}

		Logger.log(Logger.INFO,"Algorithm: {}\n",algorithm);
		index = indexRegistry!(T)[algorithm](inputData!(T), params);

		Logger.log(Logger.INFO,"Building index... \n");
		float indexTime = profile({
			index.buildIndex();
		});
		
		report("cluster_time", indexTime);
		
		Logger.log(Logger.INFO,"Time to build {} tree{} for {} vectors: {} seconds\n\n",
			index.numTrees, index.numTrees == 1 ? "" : "s", index.size, indexTime);
		Logger.log(Logger.SIMPLE,"{}\n",indexTime);

// 		if (saveFile !is null) {
// 			Logger.log(Logger.INFO,"Saving index to file %s... ",saveFile);
// 			fflush(stdout);
// 			index.save(saveFile);
// 			Logger.log(Logger.INFO,"done\n");
// 		}
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