
module std.typeinfo.ti_Abit;

private import std.string;

// bit[]

class TypeInfo_Ab : TypeInfo
{
    char[] toString() { return "bit[]"; }

    uint getHash(void *p)
    {	ubyte[] s = *cast(ubyte[]*)p;
	size_t len = (s.length + 7) / 8;
	ubyte *str = s;
	uint hash = 0;

	while (1)
	{
	    switch (len)
	    {
		case 0:
		    return hash;

		case 1:
		    hash *= 9;
		    hash += *cast(ubyte *)str;
		    return hash;

		case 2:
		    hash *= 9;
		    hash += *cast(ushort *)str;
		    return hash;

		case 3:
		    hash *= 9;
		    hash += (*cast(ushort *)str << 8) +
			    (cast(ubyte *)str)[2];
		    return hash;

		default:
		    hash *= 9;
		    hash += *cast(uint *)str;
		    str += 4;
		    len -= 4;
		    break;
	    }
	}

	return hash;
    }

    int equals(void *p1, void *p2)
    {
	bit[] s1 = *cast(bit[]*)p1;
	bit[] s2 = *cast(bit[]*)p2;

	size_t len = s1.length;

	if (s2.length != len)
	    return 0;;

	// Woefully inefficient bit-by-bit comparison
	for (size_t u = 0; u < len; u++)
	{
	    if (s1[u] != s2[u])
		return 0;
	}
	return 1;
    }

    int compare(void *p1, void *p2)
    {
	bit[] s1 = *cast(bit[]*)p1;
	bit[] s2 = *cast(bit[]*)p2;

	size_t len = s1.length;

	if (s2.length < len)
	    len = s2.length;

	// Woefully inefficient bit-by-bit comparison
	for (size_t u = 0; u < len; u++)
	{
	    int result = s1[u] - s2[u];
	    if (result)
		return result;
	}
	return cast(int)s1.length - cast(int)s2.length;
    }

    size_t tsize()
    {
	return (bit[]).sizeof;
    }
}

