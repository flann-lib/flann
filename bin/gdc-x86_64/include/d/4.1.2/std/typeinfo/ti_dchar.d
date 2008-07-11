
// dchar

module std.typeinfo.ti_dchar;

class TypeInfo_w : TypeInfo
{
    char[] toString() { return "dchar"; }

    hash_t getHash(void *p)
    {
	return *cast(dchar *)p;
    }

    int equals(void *p1, void *p2)
    {
	return *cast(dchar *)p1 == *cast(dchar *)p2;
    }

    int compare(void *p1, void *p2)
    {
	return *cast(dchar *)p1 - *cast(dchar *)p2;
    }

    size_t tsize()
    {
	return dchar.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	dchar t;

	t = *cast(dchar *)p1;
	*cast(dchar *)p1 = *cast(dchar *)p2;
	*cast(dchar *)p2 = t;
    }

    void[] init()
    {	static dchar c;

	return (cast(dchar *)&c)[0 .. 1];
    }
}

