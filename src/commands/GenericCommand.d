module commands.GenericCommand;

import tango.io.Stdout;

import lib.optparse;
import lib.variant;
import util.Utils;

public import util.defines;

private {
alias GenericCommand function() CommandMaker;
CommandMaker[string] commands;
}

public:
void register_command(alias Command)()
{
	commands[Command.NAME] = function() {static GenericCommand c; if (c is null ) c =  new Command(Command.NAME); return c;};
}

void execute_command(string commandName, string[] args)
{
	if (!(commandName in commands)) {
		throw new Exception("Unknown command: "~commandName);
	}
	commands[commandName]().executeCommand(args);
}

string[] get_commands()
{
	return commands.keys;
}

GenericCommand get_command(string commandName)
{
	return (*(commandName in commands))();
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
	int[string] sizes;
	string[] positionalArgs;
		
	this(string name) {
		this.name = name;
		optParser = new OptionParser();
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
			else {
				opt = new FlagTrueOption(shortName, longName, longName);
			}
		else static if ( is(T : real) )
			opt = new NumericOption!(T)(shortName, longName, longName,defaultValue, argName);
		else static assert(0);
		opt.helpMessage = description;
		optParser.addOption(opt);
		params[longName] = &param;
		sizes[longName] = param.sizeof;
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
				params[o.longName][0..sizes[o.longName]] = pData[0..sizes[o.longName]];
			}
		}

		executeDefault();
	}
	
	protected bool isParamPresent(string name) 
	{
		foreach(o;optParser.options) {
			if (o.longName == name) {
				return true;
			}
		}
		return false;
	}
	
	void showHelp()
	{
		Stdout.formatln("Command: {} [options]",name);
		if (description!="") {
			Stdout(description).newline;
		}
		Stdout.newline;
		Stdout("Options:").newline;
		optParser.showHelp();
	}
	
	
	protected void executeDefault();
}
