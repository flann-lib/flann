module commands.AutotuneParams;

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
		register(precision,"P","precision", 95,"The desired search precision (default: 95%).");
		register(indexFactor,"f","index-factor", 0,"Index build time penalty factor (relative to search time).");
		register(samplePercentage,"s","sample-percentage", 10,"Percentage of the inpute dataset to use for parameter tunning default: 10%).");
		
		register(byteFeatures,"B","byte-features", 2,"Use byte-sized feature elements.");
 			
 		description = "Compute optimum parameters for a specific dataset.";
		
	}
	
	
	
	
	private void executeWithType(T)()
	{
		Features!(T) inputData;
		
		// read input data		
		if (inputFile != "") {
			showOperation( "Reading input data from "~inputFile, {
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
		
		logger.info("Building index...");
		float indexTime = profile( {
			index.buildIndex();
		});
		logger.info(sprint("Time to build {} tree{} for {} vectors: {} seconds",
			index.numTrees, index.numTrees == 1 ? "" : "s", index.size, indexTime));
		
		uint checks = estimateSearchParams!(T)(index, inputData, precision);

		params["checks"] = checks;

		
		if (paramsFile == "") {
			paramsFile = inputFile~".params";
		}
		
		params.save(paramsFile);
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