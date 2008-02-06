module nn.ComputeNN;

import util.defines;
import algo.NNIndex;
import dataset.Features;
import util.Logger;
import util.Utils;
import output.Console;

void computeNearestNeighbors(string outputFile, NNIndex index, Features!(float) testData, int nn, int checks, uint skipMatches)
{
	
	withOpenFile(outputFile, (FormatOutput writer) {
		logger.info("Searching...");
	
		ResultSet resultSet = new ResultSet(nn+skipMatches);
	
		showProgressBar(testData.rows, 70, (Ticker tick){
			for (int i = 0; i < testData.rows; i++) {
				tick();
				
				resultSet.init(testData.vecs[i]);
		
				index.findNeighbors(resultSet,testData.vecs[i], checks);			
				
				int[] neighbors = resultSet.getNeighbors();
				neighbors = neighbors[skipMatches..$];
				
				for (int j=0;j<nn;++j) {
					if (j!=0) {
						writer(" ");
					}
					writer("{}",neighbors[i]);
				}
				writer("\n");
			}
		});
	});

}

