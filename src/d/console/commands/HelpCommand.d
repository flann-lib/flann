module console.commands.HelpCommand;

// import std.string;
import tango.io.Stdout;

import console.commands.GenericCommand;
import console.commands.DefaultCommand;
import util.Logger;
import util.defines;

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
		Stdout.format("Command: {} command_name\n",name);
		Stdout("Shows help about 'command_name'.\n");
		Stdout("Valid commands:\n");
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
			Stdout.formatln("\t{}",command);
		}
	}

	private void showProgramHelp(string programName)
	{
		Stdout.format("Usage: {} [command command_options]\n", programName);
		Stdout("\n");
		
		Stdout("Commands:\n");
		showValidCommands();
		Stdout("\n");
		
		Stdout.format("For more info type: {} help [command]\n",programName);		
	}
}