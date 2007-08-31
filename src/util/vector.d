/*
	Project: vector
*/

class vector(T) {
	private T data_[];
	private int size_;
	
	public this()
	{
		this(8);
	}
	
	public this(int capacity)
	{
		data_.length = capacity;
		size_ = 0;
	}
	
	T opIndex(int index) 
	{
		debug {
			if (index<0 || index>=size_) {
				throw new Exception("Illegal index in operator []");
			}
		}
		
		return data_[index];
	}
	
	vector!(T) opCat(T value)
	{
		
		if (size>=data_.length) {
			data_.length = data_.length*2;
		}
		
		data_[size_++] = value;
		
		return this;
	}
	
	vector!(T) opCatAssign(T value)
	{
		
		if (size>=data_.length) {
			data_.length = data_.length*2;
		}
		
		data_[size_++] = value;
		
		return this;
	}

	T opIndexAssign(T value, int index)
	{
		debug {
			if (index<0 || index>=size_) {
				throw new Exception("Illegal index in operator []");
			}
		}
				
		data_[index] = value;
		
		return value;
	}

	public int size() {
		return size_;
	}
	
	public int capacity() {
		return data_.length;
	}
};

unittest 
{

	
	writef("Begin unittest\n");
	vector!(int) v = new vector!(int);

	v = v ~ 1;
	v ~= 20;
	
	try {
		v[2] = 21;
		debug {
			assert(false);
		}
	}
	catch (Exception e) {};
	//v[3] = 21;
	
	writef("%s\n",v.data_[0..v.size_]);
	
	writef("End unittest\n");
}


void main()
{
}