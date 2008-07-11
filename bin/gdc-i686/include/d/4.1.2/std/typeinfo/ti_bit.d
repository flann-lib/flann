
// bit

module std.typeinfo.ti_bit;

class TypeInfo_b : TypeInfo
{
    char[] toString() { return "bit"; }

    uint getHash(void *p)
    {
	return *cast(bit *)p;
    }

    int equals(void *p1, void *p2)
    {
	return *cast(bit *)p1 == *cast(bit *)p2;
    }

    int compare(void *p1, void *p2)
    {
	if (*cast(bit*) p1 < *cast(bit*) p2)
	    return -1;
	else if (*cast(bit*) p1 > *cast(bit*) p2)
	    return 1;
	return 0;
    }

    size_t tsize()
    {
	return bit.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	bit t;

	t = *cast(bit *)p1;
	*cast(bit *)p1 = *cast(bit *)p2;
	*cast(bit *)p2 = t;
    }
}

