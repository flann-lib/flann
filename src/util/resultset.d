/*
Project: nn
*/

module util.resultset;

import util.heap;
import util.utils;
import util.allocator;


class ResultSet 
{
	int[] indices;
	float[] dists;
	
	float[] target;
	
	int count;
	
	public this(int capacity) 
	{
		indices = new int[capacity];
		dists = new float[capacity];
	}
	
	public this(float[] target, int capacity)
	{
		this(capacity);
		init(target);
	}
	
	public void init(float[] target) 
	{
		this.target = target;
		count = 0;
	}
	
	
	public int[] getNeighbors() 
	{	
		return indices;
	}
	
	public bool full() 
	{	//return false;
		return count == indices.length;
	}
	
	public bool addPoint(T)(T[] point, int index) 
	{
		float dist = target.squaredDist(point);
		
		if (count<indices.length) {
			indices[count] = index;
			dists[count] = dist;	
			count++;
		} 
		else if (dist < dists[count-1]) {
			indices[count-1] = index;
			dists[count-1] = dist;
		} 
		else { 
			return false;
		}
		
		int i = count-1;
		// bubble up
		while (i>=1 && dists[i]<dists[i-1]) {
			swap(indices[i],indices[i-1]);
			swap(dists[i],dists[i-1]);
			i--;
		}
		
		return true;
	}
	
	public float worstDist()
	{
		return (count<dists.length) ? float.max : dists[count-1];
	}
	
}

