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
import output.report;


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

	Logger.log(Logger.INFO,"Searching... \n");
 	Logger.log(Logger.INFO,"  Nodes    %% correct    Time     Time/vector\n"
 			" checked   neighbors   (seconds)      (ms)\n"
 			" -------   ---------   ---------  -----------\n");

	ResultSet resultSet = new ResultSet(nn+skipMatches);

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
		
		float precision = 100*cast(float)correct/testData.count;
		
		Logger.log(Logger.INFO,"  %5d     %6.2f      %6.2f      %6.3f\n",
				checks, precision,
				time, 1000.0 * time / testData.count);
				
		return precision;
	}



	int estimate(int[] checks, float[] precision, int count, float desiredPrecision) {
		
		float[2][2] A;
		float[2] b;
		
		b[] = 0;
		A[0][] = 0;
		A[1][] = 0;
		
		for (int i=0;i<count;++i) {
			float c = log(checks[i]);
			float p = 100 - precision[i];
			A[1][1] += c*c;
			A[0][1] -= c;
			b[0] += c*p;
			b[1] += p;
		}
		A[1][0] = A[0][1];
		A[0][0] = count;
		
		float d = A[0][0]*A[1][1]-A[0][1]*A[1][0];
		
		float x[2];
		x[0] = (A[0][0]*b[0]+A[0][1]*b[1])/d;
		x[1] = (A[1][0]*b[0]+A[1][1]*b[1])/d;
		
		float cx = exp((100-desiredPrecision-x[1])/x[0]);
		
		return lround(cx);
	}

	
	const int MAX_CHECKS = 20;
	const float VECINITY_INTERVAL = 2;
	const float EPS = 0.05;
	
	int[MAX_CHECKS] c;
	float[MAX_CHECKS] p;	
	float time;
	int count;
	
	// get two samples of numbet_of_checks-precision dependencies
	c[0] = 1;	p[0] = search(c[0],time);
	c[1] = 5;	p[1] = search(c[1],time);
	count = 2;
	
	// use least square to estimate checks no. to obtain something close to
	// desired precision
	while (abs(p[count-1]-p[count-2])>VECINITY_INTERVAL && abs(p[count-1]-precision)>EPS) {
		c[count] = estimate(c,p,count, precision);
		p[count] = search(c[count],time);
		count++;		
	}
	
	
	if (abs(p[count-1]-p[count-2])<0.0001) {
		count--; // don't allow two equal precisions
	}
	
	int cx;
	float realPrecision;
	if (abs(p[count-1]-precision)>EPS) {
		writefln("Start linear estimation");
		// after we got to values in the vecibity of the desired precision
		// use linear approximation get a better estimation
		int c1 = c[count-2], c2 = c[count-1];
		float p1 = p[count-2], p2 = p[count - 1];
			
		cx = lround(c1+(precision-p1)*(c2-c1)/(p2-p1));
		realPrecision = search(cx,time);
		while (abs(realPrecision-precision)>EPS) {
			if (p2!=realPrecision) {
				c1 = c2; p1 = p2;
			}
			c2 = cx; p2 = realPrecision;
			cx = lround(c1+(precision-p1)*(c2-c1)/(p2-p1));
			if (c2==cx) {
				cx += precision>realPrecision?1:-1;
			}
			if (cx==c1) {
				writefln("Got as close as I can");
				break;
			}
			realPrecision = search(cx,time);
		}
		
	} else {
		writefln("No need for linear estimation");
		cx = c[count-1];
		realPrecision = p[count-1];
	}
	
	reportedValues["checks"] = cx;
	reportedValues["match"] = cast(double)realPrecision;
	reportedValues["search_time"] = cast(double)time;
	flush_reporters();


	Logger.log(Logger.SIMPLE,"  %5d     %6.2f      %6.2f      %6.3f\n",
				cx, realPrecision,
				time, 1000.0 * time / testData.count);

}

