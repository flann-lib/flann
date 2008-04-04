module console.commands.AutotuneParams;

import console.commands.GenericCommand;
import console.commands.DefaultCommand;
import nn.Autotune;
import nn.Testing;
import dataset.Dataset;
import algo.NNIndex;
import util.Logger;
import util.Utils;
import util.Profile;


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
	float memoryFactor;
	bool byteFeatures;
	float samplePercentage;
	

	this(string name) 
	{
		super(name);
		register(inputFile,"i","input-file", "","Name of file with input dataset.");
		register(paramsFile,"p","params-file", "","Name of file where to save the params.");
		register(precision,"P","precision", 95,"The desired search precision (default: 95%).");
		register(indexFactor,"f","index-factor", 0.1,"Index build time penalty factor (relative to search time).");
		register(memoryFactor,"m","memory-factor", 0.1,"Memory penalty factor.");
		register(samplePercentage,"s","sample-percentage", 0.1,"Fraction of the input dataset to use for parameter tunning( default: 0.1).");
		
		register(byteFeatures,"B","byte-features", 2,"Use byte-sized feature elements.");
 			
 		description = "Compute optimum parameters for a specific dataset.";
		
	}
	
	
	
	
	private void executeWithType(T)()
	{
		Dataset!(T) inputData;
		
		// read input data		
		if (inputFile != "") {
			logger.info( "Reading input data from "~inputFile);
			inputData = new Dataset!(T)();
			inputData.readFromFile(inputFile);
		}	
		if (inputData is null) {
			throw new FLANNException("No input data given.");
		}
				
		Params params = estimateBuildIndexParams!(T)(inputData, precision, indexFactor, memoryFactor, samplePercentage);
		
 		string algorithm = params["algorithm"].get!(string);
		NNIndex index = indexRegistry!(T)[algorithm](inputData, params);
		
		logger.info("Building index...");
		float indexTime = profile( {
			index.buildIndex();
		});
		logger.info(sprint("Time to build {} tree{} for {} vectors: {} seconds",
			index.numTrees, index.numTrees == 1 ? "" : "s", index.size, indexTime));
		
		estimateSearchParams!(T)(index, inputData, precision, params);
		
		if (paramsFile == "") {
			paramsFile = inputFile~".params";
		}
		
		params.save(paramsFile);
		
		delete index;
		delete inputData;
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