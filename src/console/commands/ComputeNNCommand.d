module console.commands.ComputeNNCommand;

import console.commands.GenericCommand;
import console.commands.IndexCommand;
import util.Logger;
import util.Profile;
import util.Utils;
import dataset.Dataset;
import algo.NNIndex;


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
 			
 		description = "Builds an index from a dataset and searches that index for the nearest
neighbors of all the features in a testset.";
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
			logger.info(sprint("Reading test data from {}... ",testFile));
			testData = new Dataset!(float)();
			testData.readFromFile(testFile);
		}
		if (testData is null) {
			throw new FLANNException("No test data given.");
		}

		
		if (outputFile != "") {
			float searchTime = 0;
		
			withOpenFile(outputFile, (FormatOutput writer) {
			searchTime = profile({
				logger.info("Searching...");
			
				ResultSet resultSet = new ResultSet(nn+skipMatches);
			
				for (int i = 0; i < testData.rows; i++) {
					
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
			});
			});
			logger.info(sprint("Time to search {} vectors: {} seconds",testData.rows,searchTime));
			logger.info("Wrote the nearest neighbors to "~outputFile);
		}
	}
	

	
}