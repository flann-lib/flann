/*
Project: convert
*/

import std.c.stdio;
import util;


int findNearest(float[][] vecs, int index, int len) 
{
	int nn = 0;
	
	if (index==0) {
		nn = 1;
	} else {
		nn = 0;
	}

	float dist = DistSquared(&vecs[nn][0], &vecs[index][0], len);
	
	for (int i=0;i<vecs.length;++i) {
		if (i!=index) {
			float tmp = DistSquared(&vecs[i][0], &vecs[index][0], len);
			if (tmp<dist) {
				dist = tmp;
				nn = i;
			}
		}
	}
	
	return nn;
}


int main()
{
//	f = fopen("clusterData.dat","r");
	FILE *fin = stdin;	
	int size, flen;
	
	fscanf(fin,"%d %d ", &size, &flen);
	
	float[][] vecs = new float[][size];
	
	for (int i=0;i<size;++i) {
		vecs[i] = new float[flen];
		
		for (int j=0;j<flen;++j) {
			fscanf(fin,"%f ", &vecs[i][j]);
		}
	}
	
//	FILE*	fout = fopen("points.dat","w");
	FILE*	fout = stdout;
	
	fprintf(fout,"NN %d %d 1\n", size, flen);
	
	for (int i=0;i<size;++i) {
		int nearest = findNearest(vecs,i, flen);
		fprintf(fout,"%d %d 1 ", i, nearest);
		for (int j=0;j<flen;++j) {
			fprintf(fout,"%f ", vecs[i][j]);
		}
		fprintf(fout,"\n");
	}
	

	return 0;
}