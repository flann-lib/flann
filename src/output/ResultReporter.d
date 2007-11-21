
module output.ResultReporter;

import tango.text.Util : trim,split;

import util.utils;
public import util.defines;

abstract class ResultReporter
{
	string output;
	
	void flush(OrderedParams values);	
}

private {
alias ResultReporter function() ReporterMaker;
ReporterMaker[string] reporters;
string active_reporters[];
}

public: 
void register_reporter(alias Reporter)()
{
	reporters[Reporter.NAME] = function() {static ResultReporter c; if (c is null ) c =  new Reporter(); return c;};
}


ResultReporter get_reporter(string name)
{
	return (*(name in reporters))();
}

bool is_reporter(string name)
{
	return (name in reporters)!=null;
}

void activate_reporter(string name)
{
	string[] vals = split(name,":");

	string reporterName = vals[0];
	string reporterOutput = "";
	if (vals.length==2) {
		reporterOutput = vals[1];;
	}

	if (is_reporter(reporterName)) {
		bool found = false;
		foreach (r;active_reporters) {
			if (reporterName==r)  {
				found = true;
				break;
			}
		}
		if (!found) {
			active_reporters ~= reporterName;
		}
		
		get_reporter(reporterName).output = reporterOutput;
	}	
}

void flush_reporters()
{
	foreach (name;active_reporters) {
		get_reporter(name).flush(reportedValues);
	}
}

OrderedParams reportedValues;

