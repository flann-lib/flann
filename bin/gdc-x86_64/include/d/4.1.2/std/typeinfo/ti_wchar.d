
module std.typeinfo.ti_wchar;


class TypeInfo_u : TypeInfo
{
    char[] toString() { return "wchar"; }

    hash_t getHash(void *p)
    {
	return *cast(wchar *)p;
    }

    int equals(void *p1, void *p2)
    {
	return *cast(wchar *)p1 == *cast(wchar *)p2;
    }

    int compare(void *p1, void *p2)
    {
	return *cast(wchar *)p1 - *cast(wchar *)p2;
    }

    size_t tsize()
    {
	return wchar.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	wchar t;

	t = *cast(wchar *)p1;
	*cast(wchar *)p1 = *cast(wchar *)p2;
	*cast(wchar *)p2 = t;
    }

    void[] init()
    {	static wchar c;

	return (cast(wchar *)&c)[0 .. 1];
    }
}

