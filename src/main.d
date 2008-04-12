/************************************************************************
 * Fast Library for Approximate Nearest Neighbors
 *
 * File containing the entry point for the command line version
 * of the FLANN library.
 * 
 * Authors: Marius Muja, mariusm@cs.ubc.ca
 * 
 * Version: 1.0
 * 
 * History:
 * 
 * License: LGPL
 * 
 *************************************************************************/
module main;

import tango.core.Memory : GC;
debug {
	import jive.stacktrace;
}

import console.commands.all;


/**
 * Program entry point
 * Params:
 *     args = array containing the program arguments
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
	
	return 0;	
}



