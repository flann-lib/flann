module commands.TestMatch;

import tango.text.convert.Sprint;

import commands.GenericCommand;
import commands.DefaultCommand;
import dataset.Features;
import output.Console;
import util.Logger;
import util.Utils;


static this() {
 	register_command!(TestMatch);
}

class TestMatch : DefaultCommand
{
	public static string NAME = "test_match";
	string file;
	string matchFile;
	
	this(string name) 
	{
		super(name);
		register(file,"f","file", "","The name of the file containing the matches to test.");
		register(matchFile,"m","match-file", "match.dat","The name of the file with ground truth matches.");
 		
 		description = "Test a match file.";
	}
	
	void execute() 
	{
		auto m1 = new Features!(float)();
		auto m2 = new Features!(float)();
		
		m1.readMatches(file);
		m2.readMatches(matchFile);
		
		if (m1.match.length != m2.match.length) {
			logger.error("Match file lengths should be equal");
			return;
		}
		
		int count = 0;
		foreach (i,m;m1.match) {
			if (m[0]==m2.match[i][0]) {
				count++;
			}
		}
		
		logger.info(sprint("Precision: {}",(cast(double)count/m1.match.length)*100));
	}
	

	
}