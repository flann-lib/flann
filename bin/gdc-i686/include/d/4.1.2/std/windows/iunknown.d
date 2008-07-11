
module std.windows.iunknown;

private import std.c.windows.windows;

alias int HRESULT;

enum : int
{
	S_OK = 0,
	E_NOINTERFACE = cast(int)0x80004002,
}

struct GUID {          // size is 16
    align(1):
	DWORD Data1;
	WORD   Data2;
	WORD   Data3;
	BYTE  Data4[8];
}

alias GUID IID;

extern (C)
{
    extern IID IID_IUnknown;
}

class IUnknown
{
    HRESULT QueryInterface(IID* riid, out IUnknown pvObject)
    {
	if (riid == &IID_IUnknown)
	{
	    pvObject = this;
	    AddRef();
	    return S_OK;
	}
	else
	{   pvObject = null;
	    return E_NOINTERFACE;
	}
    }

    ULONG AddRef()
    {
	return ++count;
    }

    ULONG Release()
    {
	if (--count == 0)
	{
	    // free object
	    return 0;
	}
	return count;
    }

    int count = 1;
}
