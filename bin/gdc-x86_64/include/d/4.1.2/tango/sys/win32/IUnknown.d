/**
 * This module contains a definition for the IUnknown interface, used with COM.
 *
 * Copyright: Copyright (C) 2005-2006 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Walter Bright, Sean Kelly
 */
module tango.sys.win32.IUnknown;


private
{
    import tango.sys.win32.Types;
    extern (C) extern IID IID_IUnknown;
}


class IUnknown
{
    HRESULT QueryInterface( REFIID iid, out IUnknown obj )
    {
	if ( iid == &IID_IUnknown )
	{
	    AddRef();
	    obj = this;
	    return S_OK;
	}
	else
	{
	    obj = null;
	    return E_NOINTERFACE;
	}
    }

    ULONG AddRef()
    {
	return ++m_count;
    }

    ULONG Release()
    {
	if( --m_count == 0 )
	{
	    // free object
	    return 0;
	}
	return m_count;
    }

private:
    ULONG m_count = 1;
}
