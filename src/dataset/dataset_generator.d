/*
Project: nn
*/

module util.dataset_generator;

import util.defines;
import util.utils;
import util.random;
import output.console;
import util.logger;

void generateRandomDataset(string file, uint count, uint length)
{
	withOpenFile(file, (FormatOutput writer) {
		logger.info(sprint("Generating random dataset with {} features of {} dimension(s).",count,length));	
		
		showProgressBar(count, 70, (Ticker tick) {
			for (int i=0;i<count;++i) {
				for (int j=0;j<length;++j) {
					if (j!=0) {
						writer(" ");
					}
					writer.format("{:10} ",drand48());
				}
				writer("\n");
				tick();
			}
		});
	});
}