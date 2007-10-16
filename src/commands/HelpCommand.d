module commands.HelpCommand;

import std.string;

import commands.GenericCommand;
import commands.DefaultCommand;
import util.logger;

static this() {
 	register_command!(HelpCommand);
}

class HelpCommand : DefaultCommand
{
	public static string NAME = "help";
	
	this(string name) {
		super(name);
		
		description = "Shows help about a given command";
	}
	
	
	void execute()
	{
		if (positionalArgs.length==1) {
			if (is_command(positionalArgs[0])) {
				showCommandHelp(positionalArgs[0]);
			}
			else {
				showProgramHelp(positionalArgs[0]);
			}
		} 
		else {
			showHelp();
		}
	}
	
	public void showHelp()
	{
		writefln("Command: %s command_name",name);
		writefln();
		writefln("Shows help about 'command_name'.");
		writefln("Valid commands:");
		showValidCommands();
	}


	private void showCommandHelp(string commandName)
	{
		get_command(commandName).showHelp();
	}
	
	private void showValidCommands()
	{
		string[] commands = get_commands();
		foreach (command;commands) {
			writefln("\t",command);
		}
	}

	private void showProgramHelp(string programName)
	{
		writefln("Usage: %s [command command_options]", programName);
		writefln();
		
		writefln("Commands:");
		showValidCommands();
		writefln();
		
		writefln("For more info type: %s help [command]",programName);		
	}
}