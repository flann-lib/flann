
// long

module std.typeinfo.ti_long;

class TypeInfo_l : TypeInfo
{
    char[] toString() { return "long"; }

    hash_t getHash(void *p)
    {
	return *cast(uint *)p + (cast(uint *)p)[1];
    }

    int equals(void *p1, void *p2)
    {
	return *cast(long *)p1 == *cast(long *)p2;
    }

    int compare(void *p1, void *p2)
    {
	if (*cast(long *)p1 < *cast(long *)p2)
	    return -1;
	else if (*cast(long *)p1 > *cast(long *)p2)
	    return 1;
	return 0;
    }

    size_t tsize()
    {
	return long.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	long t;

	t = *cast(long *)p1;
	*cast(long *)p1 = *cast(long *)p2;
	*cast(long *)p2 = t;
    }
}

