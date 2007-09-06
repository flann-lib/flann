/*
Project: nn
*/

module util.resultset;

import util.heap;
import util.utils;

template Index(T) {

struct Point {

	static Point opCall(T[] point, int index) 
	{
		Point p;
		p.point = point;
		p.index = index;
		
		return p;
	}

	T[] point;
	int index;
	float dist;
}

class ResultSet 
{
	Point[] points;
	T[] target;
	
	int count;
	
	public this(int capacity) 
	{
		points = new Point[capacity];
	}
	
	public this(T[] target, int capacity)
	{
		this(capacity);
		init(target);
	}
	
	public void init(T[] target) 
	{
		this.target = target;
		count = 0;
	}
	
	
	public int getPointIndex(int num) 
	{	
		if (num<count) {
			return points[num].index;
		}
		else {
			return -1;
		}
	}
	
	public bool full() 
	{	//return false;
		return count == points.length;
	}
	
	public bool addPoint(T[] point, int index) 
	{
		Point p = Point(point,index);
	
		p.dist = target.squaredDist(point);
		
		if (count<points.length) {
			points[count++] = p;	
		} 
		else if (p.dist < points[count-1].dist) {
			points[count-1] = p;
		} 
		else { 
			return false;
		}
		
		int i = count-1;
		// bubble up
		while (i>=1 && points[i].dist<points[i-1].dist) {
			swap(points[i],points[i-1]);
			i--;
		}
		
		return true;
	}
	
	public float worstDist()
	{
		return (count<points.length) ? T.max : points[count-1].dist;
	}
	
}

}