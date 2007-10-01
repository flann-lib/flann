
/************************************************************************
Project: nn

  Demo software: Approximate Nearest-Neighbor Matching
  Converted from C
Author: Marus Muja (2007)

*************************************************************************/
module main;

import std.stdio;

import util.logger;
import commands.all;


/** 
	Program entry point 
*/
void main(char[][] args)
{
	Logger.enableLevel(Logger.ERROR);
	std.gc.disable();
	
	if (args.length==1) {
		execute_command("help",args[0..1]);
		return;
	}
	
	int index = 1;
	while (index<args.length && !is_command(args[index]) ) index++;
	execute_command("default_command",args[1..index]);
	if (index<args.length) {
		if (args[index]=="help" && index+1==args.length) {
			execute_command("help",args[0..1]);
		}
		else {
			execute_command(args[index],args[index+1..$]);
		}
	} else {
		execute_command("help",args[0..1]);
	}
	
	return 0;	
}



