/*
Project: aggnn
*/


public float squaredDist(float[] a, float[] b) 
{
	return DistSquared(&a[0], &b[0],a.length);
}

public float squaredDist(float[] a) 
{
	return DistSquared(&a[0], a.length);
}

/* Return the squared distance between two vectors. 
	This is highly optimized, with loop unrolling, as it is one
	of the most expensive inner loops of recognition.
*/
public float DistSquared(float *v1, float *v2, int veclen)
{
	float diff, distsq = 0.0;
	float diff0, diff1, diff2, diff3;
	float *final_, finalgroup;

	final_ = v1 + veclen;
	finalgroup = final_ - 3;

	/* Process 4 pixels with each loop for efficiency. */
	while (v1 < finalgroup) {
		diff0 = v1[0] - v2[0];
		diff1 = v1[1] - v2[1];
		diff2 = v1[2] - v2[2];
		diff3 = v1[3] - v2[3];
		distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
		v1 += 4;
		v2 += 4;
	}
	/* Process last 0-3 pixels.  Not needed for standard vector lengths. */
	while (v1 < final_) {
		diff = *v1++ - *v2++;
		distsq += diff * diff;
	}
	return distsq;
}


public float DistSquared(float *v1, int veclen)
{
	float diff, distsq = 0.0;
	float diff0, diff1, diff2, diff3;
	float *final_, finalgroup;

	final_ = v1 + veclen;
	finalgroup = final_ - 3;

	/* Process 4 pixels with each loop for efficiency. */
	while (v1 < finalgroup) {
		diff0 = v1[0];
		diff1 = v1[1];
		diff2 = v1[2];
		diff3 = v1[3];
		distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
		v1 += 4;
	}
	/* Process last 0-3 pixels.  Not needed for standard vector lengths. */
	while (v1 < final_) {
		diff = *v1++;
		distsq += diff * diff;
	}
	return distsq;
}


public float computeVariance(float[][] points)
{
	if (points.length==0) {
		return 0;
	}
	
	float[] mu = points[0].dup;
	
	mu[] = 0;	
	for (int j=0;j<mu.length;++j) {
		for (int i=0;i<points.length;++i) {
			mu[j] += points[i][j];
		}
		mu[j]/=points.length;
	}
	
	float variance = 0;
	for (int i=0;i<points.length;++i) {
		variance += squaredDist(mu,points[i]);
	}
	variance/=points.length;

	return variance;
}
