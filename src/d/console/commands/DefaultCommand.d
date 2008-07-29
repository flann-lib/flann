module console.commands.DefaultCommand;

// import std.string;
import tango.core.Array : find;
import tango.text.Util : split,trim;
import tango.util.log.Log;

import console.commands.GenericCommand;
import console.report.Report;
import util.defines;
import util.Registry;


abstract class DefaultCommand : GenericCommand
{
	string verbosity;
	string reporters;
	bool help;
	
	this(string name) {
		super(name);
		register(verbosity,"v","verbosity","info","The program verbosity (trace > info > warn > error > fatal > none) (Default: info)");
		register(reporters,"e","reporters","","Comma-delimited list of reporters to use.");
		register(help,"h","help",null,"Display help message");
	}
	
	final void executeDefault()
	{
		if (help) {
			showHelp();
			return;
		} 
		
		Log.getLogger("log").setLevel(Log.level(verbosity));
	
		if (reporters != "") {	
			string[] reporterList = split(reporters,",");
			foreach (reporter;reporterList) {
				uint pos = find(reporter,":");
				if (pos!=reporter.length) {
					report.addBackend(Registry.get!(ReportBackend)(reporter[0..pos]~"_reporter",reporter[pos+1..$]));
				} else {
					report.addBackend(Registry.get!(ReportBackend)(reporter[0..pos]~"_reporter"));
				}
			}
		}
		
		execute();
	}
	
	
	public void execute();

}
