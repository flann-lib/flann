
// pointer

module std.typeinfo.ti_ptr;

class TypeInfo_P : TypeInfo
{
    hash_t getHash(void *p)
    {
	return cast(hash_t)*cast(void* *)p;
    }

    int equals(void *p1, void *p2)
    {
	return *cast(void* *)p1 == *cast(void* *)p2;
    }

    int compare(void *p1, void *p2)
    {
	auto c = *cast(void* *)p1 - *cast(void* *)p2;
	if (c < 0)
	    return -1;
	else if (c > 0)
	    return 1;
	return 0;
    }

    size_t tsize()
    {
	return (void*).sizeof;
    }

    void swap(void *p1, void *p2)
    {
	void* t;

	t = *cast(void* *)p1;
	*cast(void* *)p1 = *cast(void* *)p2;
	*cast(void* *)p2 = t;
    }

    uint flags()
    {
	return 1;
    }
}

