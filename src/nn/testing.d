module nn.testing;

import std.math;
import std.stdio;

import algo.nnindex;
import dataset.features;
import util.resultset;
import util.timer;
import util.logger;
import util.profiler;
import output.console;
import output.ConsoleReporter;





void testNNIndex(NNIndex index, Features!(float) testData, int nn, int checks, uint skipMatches)
{
	Logger.log(Logger.INFO,"Searching... \n");
	/* Create a table showing computation time and accuracy as a function
	   of "checks", the number of neighbors that are checked.
	   Note that we should check average of at least 2 nodes per random
	   tree, as first neighbor found is just the query vector itself.
	   Print statistics on success rate and time for value.
	 */

	ResultSet resultSet = new ResultSet(nn+skipMatches);	
	int correct = 0;
	
	float elapsed = profile( {
	showProgressBar(testData.count, 70, (Ticker tick){
		for (int i = 0; i < testData.count; i++) {
			tick();
			
			resultSet.init(testData.vecs[i]);
	
			index.findNeighbors(resultSet,testData.vecs[i], checks);			
			int nn_index = resultSet.getPointIndex(0+skipMatches);
	
		
			if (nn_index == testData.match[i]) {
				correct++;
			}
		}
	});});
	
	float precision = correct * 100.0 / cast(float) testData.count;

	Logger.log(Logger.INFO,"  Nodes    %% correct    Time     Time/vector\n"
			" checked   neighbors   (seconds)      (ms)\n"
			" -------   ---------   ---------  -----------\n");
	Logger.log(Logger.INFO,"  %5d     %6.2f      %6.2f      %6.3f\n",
			checks, precision,
			elapsed, 1000.0 * elapsed / testData.count);
	
	
	
	Logger.log(Logger.SIMPLE,"%d %f %f %f\n",
			checks, precision,
			elapsed, 1000.0 * elapsed / testData.count);

}






void testNNIndexPrecision(NNIndex index, Features!(float) testData, int nn, float precision, uint skipMatches)
{
	Logger.log(Logger.INFO,"Searching... \n");

	ResultSet resultSet = new ResultSet(nn+skipMatches);

 	Logger.log(Logger.INFO,"  Nodes    %% correct    Time     Time/vector\n"
 			" checked   neighbors   (seconds)      (ms)\n"
 			" -------   ---------   ---------  -----------\n");
	
	float search(int checks) {
//		Logger.log(Logger.INFO,"\rSearching... checks=%d    ",checks);
		int correct = 0;
		float elapsed = profile( {
		for (int i = 0; i < testData.count; i++) {
			resultSet.init(testData.vecs[i]);
			index.findNeighbors(resultSet,testData.vecs[i], checks);			
			int nn_index = resultSet.getPointIndex(0+skipMatches);
			
			if (nn_index == testData.match[i]) {
				correct++;
			}
		}
		});
		
		float performance = 100*cast(float)correct/testData.count;
		
		Logger.log(Logger.INFO,"  %5d     %6.2f      %6.2f      %6.3f\n",
				checks, performance,
				elapsed, 1000.0 * elapsed / testData.count);
		
		
		Logger.log(Logger.SIMPLE,"%d %f %f %f\n",
				checks, correct * 100.0 / cast(float) testData.count,
				elapsed, 1000.0 * elapsed / testData.count);

		
		return performance;
	}

	int checks = 1;
	float performance;
	
	performance = search(checks);
	while (performance<precision) {
		checks *=2;
		performance = search(checks);
	}
//	Logger.log(Logger.INFO,"\n");


}

void testNNIndexExactPrecision(NNIndex index, Features!(float) testData, int nn, float precision, uint skipMatches)
{
	auto reporter = new ConsoleReporter();

	Logger.log(Logger.INFO,"Searching... \n");

	ResultSet resultSet = new ResultSet(nn+skipMatches);

 	Logger.log(Logger.INFO,"  Nodes    %% correct    Time     Time/vector\n"
 			" checked   neighbors   (seconds)      (ms)\n"
 			" -------   ---------   ---------  -----------\n");
	
	float search(int checks, out float time) {
		int correct = 0;
		time = profile( {
		for (int i = 0; i < testData.count; i++) {
			resultSet.init(testData.vecs[i]);
			index.findNeighbors(resultSet,testData.vecs[i], checks);			
			int nn_index = resultSet.getPointIndex(0+skipMatches);
			
			if (nn_index == testData.match[i]) {
				correct++;
			}
		}
		});
		
		float performance = 100*cast(float)correct/testData.count;
		
		Logger.log(Logger.INFO,"  %5d     %6.2f      %6.2f      %6.3f\n",
				checks, performance,
				time, 1000.0 * time / testData.count);
		
		
		return performance;
	}

	int[2] c;
	float[2] p;	
	float time;
	
	c[0] = 1;
	c[1] = 2;
	
	p[0] = search(c[0],time);
	p[1] = search(c[1],time);
	
	
	int estimate(float px) {
		real a = pow(p[1]/p[0],1.0/(c[1]-c[0]));
		real b = pow(a,c[1])/p[1];
		
		real cx = log(b*px)/log(a);
		
		return cast(int) cx;
	}
	
	int cx = estimate(precision);
	float realPrecision = search(cx,time);
	while (abs(realPrecision-precision)>0.05) {
		if (realPrecision!=p[1]) {
			p[0] = p[1];
			c[0] = c[1];
		}
		c[1] = cx;
		p[1] = realPrecision;
		int new_cx = estimate(precision);
		if (cx==new_cx) {
			new_cx += precision>realPrecision?1:-1;
		}
		if (new_cx==c[0]) {
			break;	
		}
		
		cx=new_cx;
		realPrecision = search(cx,time);
	}
	
	
	reporter["checks"] = cx;
	reporter["match"] = cast(double)realPrecision;
	reporter["search_time"] = cast(double)time;
	reporter.flush();


	Logger.log(Logger.SIMPLE,"  %5d     %6.2f      %6.2f      %6.3f\n",
				cx, realPrecision,
				time, 1000.0 * time / testData.count);

}

