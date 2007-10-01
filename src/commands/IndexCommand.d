module commands.IndexCommand;

import std.string;
import std.c.stdlib;

import commands.GenericCommand;
import util.logger;
import util.registry;
import util.utils;
import util.profiler;
import dataset.features;
import algo.all;
import console.progressbar;


static this() {
//	register_command(new IndexCommand(IndexCommand.NAME));
}

class IndexCommand : GenericCommand
{
	public static string NAME = "create_index";
	
	string inputFile;
	string algorithm;
	bool printAlgorithms;
	uint trees;
	uint branching;
	bool byteFeatures;
	string centersAlgorithm;
	uint maxIter;
	
	protected {
		NNIndex index;
		Features!(float) inputData = null;
		Features!(ubyte) inputDataByte = null;
	}
	

	this(string name) 
	{
		super(name);
		register(inputFile,"i","input-file", "","Name of file with input dataset.");
		register(algorithm,"a","algorithm", "","The algorithm to use when constructing the index (kdtree, kmeans...).");
		register(printAlgorithms,"p","print-algorithms", null,"Display the available algorithms.");
		register(trees,"r","trees", 1,"Number of parallel trees to use (where available, for example kdtree).");
		register(branching,"b","branching", 2,"Branching factor (where applicable, for example kmeans) (default: 2).");
		register(byteFeatures,"B","byte-features", 2,"Use byte-sized feature elements.");
		register(centersAlgorithm,"C","centers-algorithm", "random","Algorithm to choose cluster centers for kmeans (default: random).");
		register(maxIter,"M","max-iterations", uint.max,"Max iterations to perform for kmeans (default: until convergence).");		
 		
 		description = "Index the input dataset.";
	}
	
	void execute() 
	{
		if (printAlgorithms) {
			Logger.log(Logger.INFO,"Available algorithms:\n");
			foreach (algo,val; indexRegistry) {
				Logger.log(Logger.INFO,"\t%s\n",algo);
			}
			Logger.log(Logger.INFO,"\n");
			
			exit(0);
		}
		
		if (!(algorithm in indexRegistry)) {
			Logger.log(Logger.ERROR,"Algorithm not supported.\n");
			Logger.log(Logger.ERROR,"Available algorithms:\n");
			foreach (algo,val; indexRegistry) {
				Logger.log(Logger.ERROR,"\t%s\n",algo);
			}
			
			throw new Exception("Bailing out...\n");
			
		}
		
		
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
			showOperation( "Reading input data from %s".format(inputFile), {
				if (!byteFeatures) {
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
		
		Logger.log(Logger.INFO,"Algorithm: %s\n",algorithm);
		
		Params params;
		copyParams(params,optParser,["trees","branching", "centers-algorithm","max-iterations"]);
		
		if (! byteFeatures) {
			index = indexRegistry[algorithm](inputData, params);
		} else {
			index = new KMeansTree!(ubyte)(inputDataByte,params);
		}
		
		
		float indexTime = profile( {
			Logger.log(Logger.INFO,"Building index... \n");
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
	

	
}