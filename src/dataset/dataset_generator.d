/*
Project: nn
*/

module util.dataset_generator;

import std.stdio;
import std.string;

import util.utils;
import util.random;
import output.console;
import util.logger;

void generateRandomDataset(string file, uint count, uint length)
{
	FILE* fout = fOpen(file,"w","Cannot open file: "~file);
	
	Logger.log(Logger.INFO,"Generating random dataset with %d features of %d dimension(s).\n",count,length);	
	
	showProgressBar(count, 70, (Ticker tick) {
		for (int i=0;i<count;++i) {
			for (int j=0;j<length;++j) {
				if (j!=0) {
					fwritef(fout," ");
				}
				fwritef(fout,"%g",drand48());
			}
			fwritef(fout,"\n");
			tick();
		}
	});
	fclose(fout);
}