module console.commands.RunTestCommand;

import tango.text.Util : split;
import tango.util.Convert;
import tango.time.WallClock;

import console.commands.GenericCommand;
import console.commands.IndexCommand;
import nn.Testing;
import dataset.Dataset;
import algo.NNIndex;
import algo.KMeansTree;
import console.report.Report;
import util.Logger;
import util.Utils;
import util.Profile;


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
	char[] precisionList;
	uint skipMatches;
	bool altEstimator = false;
	char[] approxMatch;
	float maxTime;
	char[] cbIndexList;
	
	this(string name) 
	{
		super(name);
		register(testFile,"t","test-file", "","Name of file with test dataset.");
		register(matchFile,"m","match-file", "","File containing ground-truth matches.");
		register(nn,"n","nn", 1,"Number of nearest neighbors to search for.");
		register(checkList,"c","checks", "32","Number of times to restart search (in best-bin-first manner).");
		register(precisionList,"P","precision", "","A coma-separated list with the desired precisions to be tested.");
		register(altEstimator,"A","alternative-estimator", null,"Use alternative precision estimator.");
		register(skipMatches,"K","skip-matches", 0u,"Skip the first NUM matches at test phase.");
		register(approxMatch,"X","approx-match", "","File to save approx matches to.");
		register(maxTime,"T","max-time", 0 ,"Max time for one search.");
		register(cbIndexList,"R","cb-index", "1" ,"Cluster-border index.");
 			
 		description = super.description~" Test the index against the test dataset (ground truth given in the match file).";
	}
	
	private void executeWithType(T)() 
	{
				

		Dataset!(float) testData;
/+		if ((testFile == "") && (inputData !is null)) {
			testData = inputData;
		}
		else +/
		if (testFile != "") {
			logger.info("Reading test data from "~testFile);
			testData = new Dataset!(float)();
			testData.readFromFile(testFile);
		}
		if (testData is null) {
			throw new FLANNException("No test data given.");
		}
		
		if (matchFile != "") {
			testData.readMatches(matchFile);
		}
		
		if (testData.match is null) {
			throw new FLANNException("There are no correct matches to compare to, aborting test phase.");
		}
		report("test_count", testData.rows);
		report("nn", nn);
		
		auto d = WallClock.toDate();
		char[] dateTime = sprint("{}-{}-{} {:D2}:{:D2}:{:D2}",d.date.year,d.date.month,d.date.day,d.time.hours,d.time.minutes,d.time.seconds).dup;
		report("date",dateTime);

		float[] cbIndex = to!(float[])(split(cbIndexList,","));
		KMeansTree!(T) kmeansIndex = null;
		if (algorithm=="kmeans") {
			kmeansIndex = cast(KMeansTree!(T))index;
		}
		
		if (precisionList != "") {
			float[] precisions = to!(float[])(split(precisionList,","));
			
			foreach (r;cbIndex) {
				if (kmeansIndex !is null) {
					kmeansIndex.first_time = true;
					kmeansIndex.cb_index = r;
					report("cb_index", r);
				}
				testNNIndexPrecisions!(T,true,true)(index,inputData!(T),testData, precisions, nn, skipMatches, maxTime );
			}
		}
		else {
			try {
				checkList = params["checks"].get!(char[]);
			} catch(Exception e) {};
		
			checks = to!(typeof(checks))(split(checkList,","));

		
			foreach (r;cbIndex) {
				if (kmeansIndex !is null) {
					kmeansIndex.first_time = true;
					kmeansIndex.cb_index = r;
				}
				foreach (c;checks) {
					testNNIndex!(T,true,true)(index,inputData!(T),testData, c, nn, skipMatches);
				}
			}
		}
		
		delete index;
		delete inputData!(T);
		delete testData;
	}
	

	void execute() 
	{
		super.execute();

		if (byteFeatures) {
			executeWithType!(ubyte)();
		} else {
			executeWithType!(float)();
		}
	}
	
}