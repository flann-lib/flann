module commands.DefaultCommand;

import std.string;

import commands.GenericCommand;
import util.logger;
import output.report;


abstract class DefaultCommand : GenericCommand
{
	string verbosity;
	string reporters;
	bool help;
	
	this(string name) {
		super(name);
		register(verbosity,"v","verbosity","info","The program verbosity.(info,error...)");
		register(reporters,"e","reporters","","Comma-delimited list of reporters to use.");
		register(help,"h","help",null,"Display help message");
	}
	
	void executeDefault()
	{
		if (help) {
			showHelp();
			return;
		} 
		
		string[] logLevels = split(verbosity,",");
		foreach (logLevel;logLevels) {
			Logger.enableLevel(strip(logLevel));
		}
		
		string[] reporterList = split(reporters,",");
		foreach (reporter;reporterList) {
			activate_reporter(reporter);
		}
		
		execute();
	}
	
	
	public void execute();

}