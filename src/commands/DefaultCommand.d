module commands.DefaultCommand;

import std.string;

import commands.GenericCommand;
import util.logger;

static this() {
	register_command(new DefaultCommand(DefaultCommand.NAME));
}

class DefaultCommand : GenericCommand
{
	public static string NAME = "default_command";
	string verbosity;
	
	this(string name) {
		super(name);
		register(verbosity,"v","verbosity","info","The program verbosity.(info,error...)");
	}
	
	void execute()
	{
		string[] logLevels = split(verbosity,",");
		foreach (logLevel;logLevels) {
			Logger.enableLevel(strip(logLevel));
		}
	}

}