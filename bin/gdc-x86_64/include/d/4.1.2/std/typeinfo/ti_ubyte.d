
// ubyte

module std.typeinfo.ti_ubyte;

class TypeInfo_h : TypeInfo
{
    char[] toString() { return "ubyte"; }

    hash_t getHash(void *p)
    {
	return *cast(ubyte *)p;
    }

    int equals(void *p1, void *p2)
    {
	return *cast(ubyte *)p1 == *cast(ubyte *)p2;
    }

    int compare(void *p1, void *p2)
    {
	return *cast(ubyte *)p1 - *cast(ubyte *)p2;
    }

    size_t tsize()
    {
	return ubyte.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	ubyte t;

	t = *cast(ubyte *)p1;
	*cast(ubyte *)p1 = *cast(ubyte *)p2;
	*cast(ubyte *)p2 = t;
    }
}

class TypeInfo_b : TypeInfo_h
{
    char[] toString() { return "bool"; }
}
