module commands.SampleCommand;

import std.string;

import commands.GenericCommand;
import util.logger;
import dataset.features;
import console.progressbar;


static this() {
	register_command(new SampleCommand(SampleCommand.NAME));
}

class SampleCommand : GenericCommand
{
	public static string NAME = "sample";
	string file;
	string saveFile;
	uint count;
	bool byteFeatures;
	
	this(string name) 
	{
		super(name);
		register(file,"f","file", "","The name of the file containing the dataset to sample.");
		register(saveFile,"s","save-file", "sampled.dat","The name pf teh file to save the sampled dataset to.");
 		register(count,"c","count", 0, "Number of features to sample.");
 		register(byteFeatures,"B","byte-features", 0, "Use byte sized feature elements.");
 		
 		description = "Create a dataset by sampling from a larger dataset.";
	}
	
	
	private void executeWithType(T)() 
	{
		if (count>0) {
			auto dataset = new Features!(T)();
			showOperation("Reading features from input file "~file, {dataset.readFromFile(file);});
			Features!(T) sampledDataset; 
			showOperation("Sampling %d features".format(count), {sampledDataset= dataset.sample(count);});
			showOperation("Saving new dataset to file "~saveFile, {sampledDataset.writeToFile(saveFile);});
		}
		else {
			throw new Exception("A positive number of features must be sampled.");
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