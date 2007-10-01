module commands.GenerateRandomCommand;

import commands.GenericCommand;

import util.logger;
import dataset.dataset_generator;


static this() {
	register_command(new GenerateRandomCommand(GenerateRandomCommand.NAME));
}

class GenerateRandomCommand : GenericCommand
{
	public static string NAME = "generate_random";
	string file;
	uint count;
	uint length;
	
	this(string name) 
	{
		super(name);
		register(file,"f","file", "random.dat","Name of the file to save the dataset to.");
		register(count,"c","count", 0,"Size of the dataset to generate (number of features).");
 		register(length,"l","length", 0, "Length of one feature.");
 		
 		description = "Generates a random dataset.";
	}
	
	void execute() 
	{
		if (length>0 && count>0) {
			generateRandomDataset(file,count,length);
		}
		else {
			throw new Exception("Dataset size and feature size must be strictly positive.");
		}
	}
	

	
}