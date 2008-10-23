

template <typename T>
class Dataset {

    bool allocated;

public:
    T* vecs;
    int rows;
    int cols;


	Dataset(int rows_, int cols_, T* data = NULL) : 
        rows(rows_), cols(cols_), vecs(data), allocated(false)
	{
        if (data==NULL) {
		    vecs = new T[rows*cols];
            allocated = true;
        }
	}

	~Dataset()
	{
        if (allocated) {
		  delete[] vecs;
        }
	}
	
    
    T* operator[](int index) 
    {
        return vecs+index*cols;
    }	

};


