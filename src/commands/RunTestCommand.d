module commands.RunTestCommand;

import std.string;

import commands.GenericCommand;
import commands.IndexCommand;
import util.logger;
import util.registry;
import util.utils;
import util.profiler;
import nn.testing;
import dataset.features;
import algo.nnindex;
import algo.kmeans;
import output.console;
import output.report;


static this() {
 	register_command!(RunTestCommand);
}

class RunTestCommand : IndexCommand
{
	public static string NAME = "run_test";
	
	string testFile;
	string matchFile;
	uint nn;
	string checkList;
	int[] checks;
	double precision;
	uint skipMatches;
	bool altEstimator = false;

	this(string name) 
	{
		super(name);
		register(testFile,"t","test-file", "","Name of file with test dataset.");
		register(matchFile,"m","match-file", "","File containing ground-truth matches.");
		register(nn,"n","nn", 1,"Number of nearest neighbors to search for.");
		register(checkList,"c","checks", "32","Number of times to restart search (in best-bin-first manner).");
		register(precision,"P","precision", -1,"The desired precision.");
		register(altEstimator,"A","alternative-estimator", null,"Use alternative precision estimator.");
		register(skipMatches,"K","skip-matches", 0u,"Skip the first NUM matches at test phase.");
 			
 		description = super.description~" Test the index against the test dataset (ground truth given in the match file).";
	}
	
	void execute() 
	{
		super.execute();
		
		checks = convert!(typeof(checks),string[])(split(checkList,","));

		Features!(float) testData;
/+		if ((testFile == "") && (inputData !is null)) {
			testData = inputData;
		}
		else +/
		if (testFile != "") {
			showOperation("Reading test data from %s".format(testFile),{
				testData = new Features!(float)();
				testData.readFromFile(testFile);
			});
		}
		if (testData is null) {
			throw new Exception("No test data given.");
		}
		
		if (matchFile != "") {
			testData.readMatches(matchFile);
		}
		
		if (testData.match is null) {
			throw new Exception("There are no correct matches to compare to, aborting test phase.");
		}
		
		reportedValues["test_count"] = testData.count;

		writefln("AltEstimator: ",altEstimator);
		if (precision>0) {
			assert(precision<=100);
 			if (altEstimator) {
 				testNNIndexPrecision!(true,true)(index,testData, nn, precision, skipMatches);
 			}
 			else {
	 			testNNIndexExactPrecision!(true,true)(index,testData, nn, precision, skipMatches);
 			}
 			
		}
		else {
			foreach (c;checks) {
				testNNIndex!(true)(index,testData, nn, c, skipMatches);
			}
		}

	}
	

	
}