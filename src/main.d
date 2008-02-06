
/************************************************************************
Project: nn
Author: Marius Muja (2007)

*************************************************************************/
module main;

import tango.core.Memory : GC;

import commands.all;

debug {
import jive.stacktrace;
}

/** 
	Program entry point 
*/
void main(char[][] args)
{
	// don't use garbage collector... manage memory manually
	GC.disable();
	
	if (args.length==1) {
		execute_command("help",args[0..1]);
		return;
	}
	
	int index = 1;
	if ( index<args.length || !is_command(args[index]) ) {
		if (args[index]=="help" && index+1==args.length) {
			execute_command("help",args[0..1]);
		}
		else {
			execute_command(args[index],args[index+1..$]);
		}
	} 
	else {
		execute_command("help",args[0..1]);
	}
	
	GC.collect();
	return 0;	
}



