module commands.AutotuneParams;

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
 	register_command!(AutotuneParams);
}

class AutotuneParams : DefaultCommand
{
	public static string NAME = "autotune_params";
	
	string inputFile;
	string paramsFile;
	float precision;
	float indexFactor;
	bool byteFeatures;
	float samplePercentage;
	

	this(string name) 
	{
		super(name);
		register(inputFile,"i","input-file", "","Name of file with input dataset.");
		register(paramsFile,"p","params-file", "","Name of file where to save the params.");
		register(precision,"P","precision", -1,"The desired search precision.");
		register(indexFactor,"f","index-factor", 0,"Index build time penalty factor (relative to search time).");
		register(samplePercentage,"s","sample-percentage", 0,"Percentage of the inpute dataset to use for parameter tunning.");
		
		register(byteFeatures,"B","byte-features", 2,"Use byte-sized feature elements.");
 			
 		description = "Compute optimum parameters for a specific dataset.";
		
	}
	
	
	
	
	private void executeWithType(T)()
	{
		Features!(T) inputData;
		
		// read input data		
		if (inputFile != "") {
			showOperation( "Reading input data from %s".format(inputFile), {
				inputData = new Features!(T)();
				inputData.readFromFile(inputFile);
			});
		}	
		if (inputData is null) {
			throw new Exception("No input data given.");
		}
				
		Params params = estimateBuildIndexParams!(T)(inputData, precision, indexFactor, samplePercentage);
		
 		string algorithm = params["algorithm"].get!(string);
		NNIndex index = indexRegistry!(T)[algorithm](inputData, params);
		
		Logger.log(Logger.INFO,"Building index... \n");
		float indexTime = profile( {
			index.buildIndex();
		});
		Logger.log(Logger.INFO,"Time to build %d tree%s for %d vectors: %5.2f seconds\n\n",
			index.numTrees, index.numTrees == 1 ? "" : "s", index.size, indexTime);
		Logger.log(Logger.SIMPLE,"%f\n",indexTime);
		
		uint checks = estimateSearchParams!(T)(index, inputData, precision);

		params["checks"] = checks;

		
		if (paramsFile == "") {
			paramsFile = inputFile~".params";
		}
		
		saveParams(paramsFile,params);
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