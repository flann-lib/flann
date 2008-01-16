
// void

module std.typeinfo.ti_void;

class TypeInfo_v : TypeInfo
{
    char[] toString() { return "void"; }

    hash_t getHash(void *p)
    {
	assert(0);
    }

    int equals(void *p1, void *p2)
    {
	return *cast(byte *)p1 == *cast(byte *)p2;
    }

    int compare(void *p1, void *p2)
    {
	return *cast(byte *)p1 - *cast(byte *)p2;
    }

    size_t tsize()
    {
	return void.sizeof;
    }

    void swap(void *p1, void *p2)
    {
	byte t;

	t = *cast(byte *)p1;
	*cast(byte *)p1 = *cast(byte *)p2;
	*cast(byte *)p2 = t;
    }

    uint flags()
    {
	return 1;
    }
}

