module console.commands.GenerateRandomCommand;

import console.commands.GenericCommand;
import console.commands.DefaultCommand;

import util.Logger;
import util.Utils;
import util.Random;


static this() {
  	register_command!(GenerateRandomCommand);
}

class GenerateRandomCommand : DefaultCommand
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
			logger.info(sprint("Generating random dataset with {} features of {} dimension(s).",count,length));	
			
			char[] bin_file = file~".bin";
			withOpenFile(file, (FormatOutput print) {
				print("BINARY").newline;
				print(bin_file).newline;
				print(length).newline;
				print("float").newline;
			});
			
			float[]
			
			buffer = new float[length];
			scope(exit) delete buffer;
			
			withOpenFile(bin_file, (FileOutput stream) {
// 				showProgressBar(count, 70, (Ticker tick) {
		
					for (int i=0;i<count;++i) {
						for (int j=0;j<length;++j) {
							buffer[j] = cast(float) drand48();
						}
						stream.write((cast(void*)buffer.ptr)[0..float.sizeof*length]);
// 						tick();
					}
// 				});
			});		
		}
		else {
			throw new FANNException("Dataset size and feature size must be strictly positive.");
		}
	}
	

	
}