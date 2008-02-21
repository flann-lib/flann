module commands.ComputeNNCommand;

import commands.GenericCommand;
import commands.IndexCommand;
import util.Logger;
import util.Utils;
import dataset.Dataset;
import algo.NNIndex;
import output.Console;


static this() {
 	register_command!(ComputeNNCommand);
}

class ComputeNNCommand : IndexCommand
{
	public static string NAME = "compute_nn";
	
	string outputFile;
	string testFile;
	uint nn;
	uint checks;
	uint skipMatches;

	this(string name) 
	{
		super(name);
		register(testFile,"t","test-file", "","Name of file with test dataset.");
		register(outputFile,"o","output-file", "","Output file to save the features to.");
		register(nn,"n","nn", 1,"Number of nearest neighbors to search for.");
		register(checks,"c","checks", 32,"Number of times to restart search (in best-bin-first manner).");
		register(skipMatches,"K","skip-matches", 0u,"Skip the first NUM matches at test phase.");
 			
 		description = super.description~" Save the cluster centers to a file.";
	}
	
	void execute() 
	{
		super.execute();
		
		Dataset!(float) testData;
/+		if ((testFile == "") && (inputData !is null)) {
			testData = inputData;
		}
		else +/
		if (testFile != "") {
			showOperation(sprint("Reading test data from {}... ",testFile),{
				testData = new Dataset!(float)();
				testData.readFromFile(testFile);
			});
		}
		if (testData is null) {
			throw new Exception("No test data given.");
		}

		
		if (outputFile != "") {
		
			withOpenFile(outputFile, (FormatOutput writer) {
				logger.info("Searching...");
			
				ResultSet resultSet = new ResultSet(nn+skipMatches);
				
				logger.info(sprint("nn: {}",nn));
			
// 				showProgressBar(testData.rows, 70, (Ticker tick){
					for (int i = 0; i < testData.rows; i++) {
// 						tick();
						
						resultSet.init(testData.vecs[i]);
				
						index.findNeighbors(resultSet,testData.vecs[i], checks);			
						
						int[] neighbors = resultSet.getNeighbors();
						neighbors = neighbors[skipMatches..$];
						
						foreach(j,neighbor;neighbors) {
							if (j!=0) writer(" ");
							writer(neighbor);
						}
						writer("\n");
					}
// 				});
			});
		}
	}
	

	
}