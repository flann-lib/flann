module commands.ConvertDatasetCommand;

import commands.DefaultCommand;
import commands.GenericCommand;
import util.defines;
import output.Console;
import dataset.Dataset;


static this() {
 	register_command!(ConvertDatasetCommand);
}

class ConvertDatasetCommand : DefaultCommand
{
	public static string NAME = "convert";
	string inputFile;
	string outputFile;
	string outputFormat;
	
	bool byteFeatures;
	
	this(string name) 
	{
		super(name);
		register(inputFile,"i","input-file", "","Input dataset file.");		
		register(outputFile,"o","output-file", "","Output dataset file.");
		register(outputFormat,"f","format", "dat","Output dataset format.");

 		register(byteFeatures,"B","byte-features", 0, "Use byte sized feature elements.");
 		
 		description = "Computes the ground-truth given an input dataset and a test dataset. If test dataset is not present it is"
 					" sampled form the input dataset";
	}
	
	
	void executeWithType(T)()
	{
		Dataset!(T) inputData = new Dataset!(T)();
		showOperation("Reading input file "~inputFile, {
			inputData.readFromFile(inputFile);
		});
		showOperation("Writing file "~outputFile, {
			inputData.writeToFile(outputFile,outputFormat);
		});

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