
module console.report.ResultReporter;

import tango.text.Util : trim,split;

public import util.defines;
import util.Utils;

public Reporter report;

static this()
{
	report = new Reporter();
}

abstract class ReportBackend
{
	private ReportBackend next;
	
	void flush(OrderedParams values);	
}

class Reporter 
{
	private ReportBackend	backend;
	private OrderedParams 	reportedValues;
	
	alias	report	opCall;

	public Reporter addBackend(ReportBackend backend)
	{
		if (this.backend) {
			backend.next = this.backend;
		}
		this.backend = backend;
		return this;
	}
	
	public Reporter clearBackends()
	{
		this.backend = null;
		
		return this;
	}

	public Reporter flush()
	{
		ReportBackend backend = this.backend;
		while (backend) {
			backend.flush(reportedValues);
			backend = backend.next;
		}
		
		return this;
	}
	
	public Reporter report(T)(char[] name, T value) 
	{
		reportedValues[name] = value;
		
		return this;
	}
}

	