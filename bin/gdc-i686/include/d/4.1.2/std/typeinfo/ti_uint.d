
// uint

module std.typeinfo.ti_uint;

class TypeInfo_k : TypeInfo
{
    char[] toString() { return "uint"; }

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
	if (*cast(uint*) p1 < *cast(uint*) p2)
	    return -1;
	else if (*cast(uint*) p1 > *cast(uint*) p2)
	    return 1;
	return 0;
    }

    size_t tsize()
    {
	return uint.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	int t;

	t = *cast(uint *)p1;
	*cast(uint *)p1 = *cast(uint *)p2;
	*cast(uint *)p2 = t;
    }
}

