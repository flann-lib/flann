
// short

module std.typeinfo.ti_short;

class TypeInfo_s : TypeInfo
{
    char[] toString() { return "short"; }

    hash_t getHash(void *p)
    {
	return *cast(short *)p;
    }

    int equals(void *p1, void *p2)
    {
	return *cast(short *)p1 == *cast(short *)p2;
    }

    int compare(void *p1, void *p2)
    {
	return *cast(short *)p1 - *cast(short *)p2;
    }

    size_t tsize()
    {
	return short.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	short t;

	t = *cast(short *)p1;
	*cast(short *)p1 = *cast(short *)p2;
	*cast(short *)p2 = t;
    }
}

