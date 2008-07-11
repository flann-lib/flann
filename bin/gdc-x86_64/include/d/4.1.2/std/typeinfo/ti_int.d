
// int

module std.typeinfo.ti_int;

class TypeInfo_i : TypeInfo
{
    char[] toString() { return "int"; }

    hash_t getHash(void *p)
    {
	return *cast(uint *)p;
    }

    int equals(void *p1, void *p2)
    {
	return *cast(uint *)p1 == *cast(uint *)p2;
    }

    int compare(void *p1, void *p2)
    {
	if (*cast(int*) p1 < *cast(int*) p2)
	    return -1;
	else if (*cast(int*) p1 > *cast(int*) p2)
	    return 1;
	return 0;
    }

    size_t tsize()
    {
	return int.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	int t;

	t = *cast(int *)p1;
	*cast(int *)p1 = *cast(int *)p2;
	*cast(int *)p2 = t;
    }
}

