
// ushort

module std.typeinfo.ti_ushort;

class TypeInfo_t : TypeInfo
{
    char[] toString() { return "ushort"; }

    hash_t getHash(void *p)
    {
	return *cast(ushort *)p;
    }

    int equals(void *p1, void *p2)
    {
	return *cast(ushort *)p1 == *cast(ushort *)p2;
    }

    int compare(void *p1, void *p2)
    {
	return *cast(ushort *)p1 - *cast(ushort *)p2;
    }

    size_t tsize()
    {
	return ushort.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	ushort t;

	t = *cast(ushort *)p1;
	*cast(ushort *)p1 = *cast(ushort *)p2;
	*cast(ushort *)p2 = t;
    }
}

