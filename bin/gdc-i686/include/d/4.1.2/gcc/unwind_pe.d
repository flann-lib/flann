/* GDC -- D front-end for GCC
   Copyright (C) 2004 David Friedman
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
 
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
/* GNU/GCC unwind interface declarations for D.  This must match unwind-pe.h */

module gcc.unwind_pe;

import gcc.unwind;
private import std.c.process : abort;

/* @@@ Really this should be out of line, but this also causes link
   compatibility problems with the base ABI.  This is slightly better
   than duplicating code, however.  */

/* Pointer encodings, from dwarf2.h.  */
enum {
    DW_EH_PE_absptr = 0x00,
    DW_EH_PE_omit = 0xff,

    DW_EH_PE_uleb128 = 0x01,
    DW_EH_PE_udata2 = 0x02,
    DW_EH_PE_udata4 = 0x03,
    DW_EH_PE_udata8 = 0x04,
    DW_EH_PE_sleb128 = 0x09,
    DW_EH_PE_sdata2 = 0x0A,
    DW_EH_PE_sdata4 = 0x0B,
    DW_EH_PE_sdata8 = 0x0C,
    DW_EH_PE_signed = 0x08,

    DW_EH_PE_pcrel = 0x10,
    DW_EH_PE_textrel = 0x20,
    DW_EH_PE_datarel = 0x30,
    DW_EH_PE_funcrel = 0x40,
    DW_EH_PE_aligned = 0x50,

    DW_EH_PE_indirect = 0x80
}

version (NO_SIZE_OF_ENCODED_VALUE) {
} else {
    /* Given an encoding, return the number of bytes the format occupies.
       This is only defined for fixed-size encodings, and so does not
       include leb128.  */

    uint
    size_of_encoded_value (ubyte encoding)
    {
      if (encoding == DW_EH_PE_omit)
	return 0;

      switch (encoding & 0x07)
	{
	case DW_EH_PE_absptr:
	  return (void *).sizeof;
	case DW_EH_PE_udata2:
	  return 2;
	case DW_EH_PE_udata4:
	  return 4;
	case DW_EH_PE_udata8:
	  return 8;
	}
      abort ();
    }
}

version (NO_BASE_OF_ENCODED_VALUE) {
} else {
    /* Given an encoding and an _Unwind_Context, return the base to which
       the encoding is relative.  This base may then be passed to
       read_encoded_value_with_base for use when the _Unwind_Context is
       not available.  */

    _Unwind_Ptr
    base_of_encoded_value (ubyte encoding, _Unwind_Context *context)
    {
      if (encoding == DW_EH_PE_omit)
	return cast(_Unwind_Ptr) 0;

      switch (encoding & 0x70)
	{
	case DW_EH_PE_absptr:
	case DW_EH_PE_pcrel:
	case DW_EH_PE_aligned:
	  return cast(_Unwind_Ptr) 0;

	case DW_EH_PE_textrel:
	  return _Unwind_GetTextRelBase (context);
	case DW_EH_PE_datarel:
	  return _Unwind_GetDataRelBase (context);
	case DW_EH_PE_funcrel:
	  return _Unwind_GetRegionStart (context);
	}
      abort ();
    }
}

/* Read an unsigned leb128 value from P, store the value in VAL, return
   P incremented past the value.  We assume that a word is large enough to
   hold any value so encoded; if it is smaller than a pointer on some target,
   pointers should not be leb128 encoded on that target.  */

ubyte *
read_uleb128 (ubyte *p, _Unwind_Word *val)
{
  uint shift = 0;
  ubyte a_byte;
  _Unwind_Word result;

  result = cast(_Unwind_Word) 0;
  do
    {
      a_byte = *p++;
      result |= (cast(_Unwind_Word)a_byte & 0x7f) << shift;
      shift += 7;
    }
  while (a_byte & 0x80);

  *val = result;
  return p;
}


/* Similar, but read a signed leb128 value.  */

ubyte *
read_sleb128 (ubyte *p, _Unwind_Sword *val)
{
  uint shift = 0;
  ubyte a_byte;
  _Unwind_Word result;

  result = cast(_Unwind_Word) 0;
  do
    {
      a_byte = *p++;
      result |= (cast(_Unwind_Word)a_byte & 0x7f) << shift;
      shift += 7;
    }
  while (a_byte & 0x80);

  /* Sign-extend a negative value.  */
  if (shift < 8 * result.sizeof && (a_byte & 0x40) != 0)
    result |= -((cast(_Unwind_Word)1L) << shift);

  *val = cast(_Unwind_Sword) result;
  return p;
}

/* Load an encoded value from memory at P.  The value is returned in VAL;
   The function returns P incremented past the value.  BASE is as given
   by base_of_encoded_value for this encoding in the appropriate context.  */

ubyte *
read_encoded_value_with_base (ubyte encoding, _Unwind_Ptr base,
			      ubyte *p, _Unwind_Ptr *val)
{
    // D Notes: Todo -- packed!
  union unaligned
    {
      align(1) void *ptr;
      align(1) ushort u2 ;
      align(1) uint u4 ;
      align(1) ulong u8 ;
      align(1) short s2 ;
      align(1) int s4 ;
      align(1) long s8 ;
    }

  unaligned *u = cast(unaligned *) p;
  _Unwind_Internal_Ptr result;

  if (encoding == DW_EH_PE_aligned)
    {
      _Unwind_Internal_Ptr a = cast(_Unwind_Internal_Ptr) p;
      a = cast(_Unwind_Internal_Ptr)( (a + (void *).sizeof - 1) & - (void *).sizeof );
      result = * cast(_Unwind_Internal_Ptr *) a;
      p = cast(ubyte *) cast(_Unwind_Internal_Ptr) (a + (void *).sizeof);
    }
  else
    {
      switch (encoding & 0x0f)
	{
	case DW_EH_PE_absptr:
	  result = cast(_Unwind_Internal_Ptr) u.ptr;
	  p += (void *).sizeof;
	  break;

	case DW_EH_PE_uleb128:
	  {
	    _Unwind_Word tmp;
	    p = read_uleb128 (p, &tmp);
	    result = cast(_Unwind_Internal_Ptr) tmp;
	  }
	  break;

	case DW_EH_PE_sleb128:
	  {
	    _Unwind_Sword tmp;
	    p = read_sleb128 (p, &tmp);
	    result = cast(_Unwind_Internal_Ptr) tmp;
	  }
	  break;

	case DW_EH_PE_udata2:
	  result = cast(_Unwind_Internal_Ptr) u.u2;
	  p += 2;
	  break;
	case DW_EH_PE_udata4:
	  result = cast(_Unwind_Internal_Ptr) u.u4;
	  p += 4;
	  break;
	case DW_EH_PE_udata8:
	  result = cast(_Unwind_Internal_Ptr) u.u8;
	  p += 8;
	  break;

	case DW_EH_PE_sdata2:
	  result = cast(_Unwind_Internal_Ptr) u.s2;
	  p += 2;
	  break;
	case DW_EH_PE_sdata4:
	  result = cast(_Unwind_Internal_Ptr) u.s4;
	  p += 4;
	  break;
	case DW_EH_PE_sdata8:
	  result = cast(_Unwind_Internal_Ptr) u.s8;
	  p += 8;
	  break;

	default:
	  abort ();
	}

      if (result != 0)
	{
	  result += ((encoding & 0x70) == DW_EH_PE_pcrel
		     ? cast(_Unwind_Internal_Ptr) u : base);
	  if (encoding & DW_EH_PE_indirect)
	    result = *cast(_Unwind_Internal_Ptr *) result;
	}
    }

  *val = result;
  return p;
}

version (NO_BASE_OF_ENCODED_VALUE) {
} else {
    /* Like read_encoded_value_with_base, but get the base from the context
       rather than providing it directly.  */

    ubyte *
    read_encoded_value (_Unwind_Context *context, ubyte encoding,
			ubyte *p, _Unwind_Ptr *val)
    {
      return read_encoded_value_with_base (encoding,
		    base_of_encoded_value (encoding, context),
		    p, val);
    }
}

