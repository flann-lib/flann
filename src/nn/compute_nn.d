module nn.compute_nn;

import std.stdio;

import algo.nnindex;
import dataset.features;
import util.resultset;
import util.logger;
import util.utils;
import output.console;

void computeNearestNeighbors(string outputFile, NNIndex index, Features!(float) testData, int nn, int checks, uint skipMatches)
{
	FILE* fout = fOpen(outputFile, "w","Cannot open file: "~outputFile);
	
	Logger.log(Logger.INFO,"Searching... \n");

	ResultSet resultSet = new ResultSet(nn+skipMatches);
			
	int correct, cormatch, match;
	correct = cormatch = match = 0;

	showProgressBar(testData.count, 70, (Ticker tick){
		for (int i = 0; i < testData.count; i++) {
			tick();
			
			resultSet.init(testData.vecs[i]);
	
			index.findNeighbors(resultSet,testData.vecs[i], checks);			
			
			for (int j=0;j<nn;++j) {
				if (j!=0) {
					fwritef(fout," ");
				}
				fwritef(fout,"%d",resultSet.getPointIndex(j+skipMatches));
			}
			fwritef(fout,"\n");
		}
	});

	fclose(fout);
}

