
// ulong

module std.typeinfo.ti_ulong;

class TypeInfo_m : TypeInfo
{
    char[] toString() { return "ulong"; }

    hash_t getHash(void *p)
    {
	return *cast(uint *)p + (cast(uint *)p)[1];
    }

    int equals(void *p1, void *p2)
    {
	return *cast(ulong *)p1 == *cast(ulong *)p2;
    }

    int compare(void *p1, void *p2)
    {
	if (*cast(ulong *)p1 < *cast(ulong *)p2)
	    return -1;
	else if (*cast(ulong *)p1 > *cast(ulong *)p2)
	    return 1;
	return 0;
    }

    size_t tsize()
    {
	return ulong.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	ulong t;

	t = *cast(ulong *)p1;
	*cast(ulong *)p1 = *cast(ulong *)p2;
	*cast(ulong *)p2 = t;
    }
}

