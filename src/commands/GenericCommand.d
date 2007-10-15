module commands.GenericCommand;

public import std.stdio;

import util.optparse;
import util.utils;
import util.variant;

private GenericCommand[string] commands;

public:
void register_command(GenericCommand command)
{
	commands[command.name] = command;
}

void execute_command(string commandName, string[] args)
{
	if (!(commandName in commands)) {
		throw new Exception("Unknown command: "~commandName);
	}
	commands[commandName].executeCommand(args);
}

string[] get_commands()
{
	return commands.keys;
}

GenericCommand get_command(string commandName)
{
	return *(commandName in commands);
}

bool is_command(string name)
{
	return (name in commands)!=null;
}




abstract class GenericCommand
{
	public string name;
	public string description;
	
	OptionParser optParser;
	void*[string] params;
	string[] positionalArgs;
	
	bool help;

	
	this(string name) {
		this.name = name;
		optParser = new OptionParser();
		
		register(help,"h","help",null,"Display help message");
	}
	
	void register(T,U)(ref T param, string shortName, string longName, U defaultValue, string description)
	{
		string argName = "";
		Option opt;
		static if ( is(T == string) )
			opt = new StringOption(shortName, longName, longName, defaultValue, argName);
		else static if ( is(T == bool) )
			static if ( is (U == bool) )
				opt = new BoolOption(shortName, longName, longName, defaultValue, argName);
			else
				opt = new FlagTrueOption(shortName, longName, longName);
		else static if ( is(T : real) )
			opt = new NumericOption!(T)(shortName, longName, longName,defaultValue, argName);
		else static assert(0);
		opt.helpMessage = description;
		optParser.addOption(opt);
		params[longName] = &param;
	}	
	
	private void executeCommand(string[] args) 
	in {
		assert(optParser !is null);
	}
	body {
		optParser.parse(args);
		positionalArgs = optParser.positionalArgs;
		foreach(o;optParser.options) {
			Variant b = optParser[o.longName];
			void[] pData = b.data;
			if (o.longName in params) {
				params[o.longName][0..pData.length] = pData;
			}
		}
		
		if (help) {
			showHelp();
		} else {
			execute();
		}
	}
	
	void showHelp()
	{
		writefln("Command: %s [options]",name);
		if (description!="") {
			writefln(description);
		}
		writefln();
		writefln("Options:");
		optParser.showHelp();
	}
	
	
	public void execute();
}
