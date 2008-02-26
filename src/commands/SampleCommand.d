module commands.SampleCommand;

import tango.text.convert.Sprint;

import commands.GenericCommand;
import commands.DefaultCommand;
import dataset.Dataset;
import output.Console;
import util.Logger;
import util.Utils;


static this() {
 	register_command!(SampleCommand);
}

class SampleCommand : DefaultCommand
{
	public static string NAME = "sample";
	string file;
	string saveFile;
	uint count;
	bool byteFeatures;
	char[] format;
	
	this(string name) 
	{
		super(name);
		register(file,"f","file", "","The name of the file containing the dataset to sample.");
		register(saveFile,"s","save-file", "sampled.dat","The name of the file to save the sampled dataset to.");
 		register(count,"c","count", 0, "Number of features to sample.");
 		register(byteFeatures,"B","byte-features", 0, "Use byte sized feature elements.");
 		register(format,"F","format","bin","Save format (dat, bin) (Default: bin)");
 		
 		description = "Create a dataset by sampling from a larger dataset.";
	}
	
	
	private void executeWithType(T)() 
	{
		if (count>0) {
			auto dataset = new Dataset!(T)();
			showOperation("Reading features from input file "~file, {dataset.readFromFile(file);});
			Dataset!(T) sampledDataset; 
			showOperation(sprint("Sampling {} features",count), {sampledDataset = dataset.sample(count);});
			showOperation("Saving new dataset to file "~saveFile, {sampledDataset.writeToFile(saveFile, format);});
		}
		else {
			throw new FANNException("A positive number of features must be sampled.");
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