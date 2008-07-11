/**
 * Encodes/decodes MIME base64 data.
 *
 * Macros:
 *	WIKI=Phobos/StdBase64
 * References:
 *	<a href="http://en.wikipedia.org/wiki/Base64">Wikipedia Base64</a>$(BR)
 *	<a href="http://www.ietf.org/rfc/rfc2045.txt">RFC 2045</a>$(BR)
 */


/* base64.d
 * Modified from C. Miller's version, his copyright is below.
 */

/*
	Copyright (C) 2004 Christopher E. Miller
	
	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.
	
	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:
	
	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgment in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
*/

module std.base64;

/**
 */

class Base64Exception: Exception
{
	this(char[] msg)
	{
		super(msg);
	}
}


/**
 */

class Base64CharException: Base64Exception
{
	this(char[] msg)
	{
		super(msg);
	}
}


const char[] array = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";


/**
 * Returns the number of bytes needed to encode a string of length slen.
 */

size_t encodeLength(size_t slen)
{
	uint result;
	result = slen / 3;
	if(slen % 3)
		result++;
	return result * 4;
}

/**
 * Encodes str[] and places the result in buf[].
 * Params:
 *	str = string to encode
 * 	buf = destination buffer, must be large enough for the result.
 * Returns:
 *	slice into buf[] representing encoded result
 */

char[] encode(char[] str, char[] buf)
in
{
	assert(buf.length >= encodeLength(str.length));
}
body
{
	if(!str.length)
		return buf[0 .. 0];
	
	size_t stri;
	size_t strmax = str.length / 3;
	size_t strleft = str.length % 3;
	uint x;
	char* sp, bp;
	
	bp = &buf[0];
	sp = &str[0];
	for(stri = 0; stri != strmax; stri++)
	{
		x = (sp[0] << 16) | (sp[1] << 8) | (sp[2]);
		sp+= 3;
		*bp++ = array[(x & 0b11111100_00000000_00000000) >> 18];
		*bp++ = array[(x & 0b00000011_11110000_00000000) >> 12];
		*bp++ = array[(x & 0b00000000_00001111_11000000) >> 6];
		*bp++ = array[(x & 0b00000000_00000000_00111111)];
	}
	
	switch(strleft)
	{
		case 2:
			x = (sp[0] << 16) | (sp[1] << 8);
			sp += 2;
			*bp++ = array[(x & 0b11111100_00000000_00000000) >> 18];
			*bp++ = array[(x & 0b00000011_11110000_00000000) >> 12];
			*bp++ = array[(x & 0b00000000_00001111_11000000) >> 6];
			*bp++ = '=';
			break;
		
		case 1:
			x = *sp++ << 16;
			*bp++ = array[(x & 0b11111100_00000000_00000000) >> 18];
			*bp++ = array[(x & 0b00000011_11110000_00000000) >> 12];
			*bp++ = '=';
			*bp++ = '=';
			break;
		
		case 0:
			break;

		default:
			assert(0);
	}
	
	return buf[0 .. (bp - &buf[0])];
}


/**
 * Encodes str[] and returns the result.
 */

char[] encode(char[] str)
{
	return encode(str, new char[encodeLength(str.length)]);
}


unittest
{
	assert(encode("f") == "Zg==");
	assert(encode("fo") == "Zm8=");
	assert(encode("foo") == "Zm9v");
	assert(encode("foos") == "Zm9vcw==");
	assert(encode("all your base64 are belong to foo") == "YWxsIHlvdXIgYmFzZTY0IGFyZSBiZWxvbmcgdG8gZm9v");
}


/**
 * Returns the number of bytes needed to decode an encoded string of this
 * length.
 */
size_t decodeLength(size_t elen)
{
	return elen / 4 * 3;
}


/**
 * Decodes str[] and places the result in buf[].
 * Params:
 *	str = string to encode
 * 	buf = destination buffer, must be large enough for the result.
 * Returns:
 *	slice into buf[] representing encoded result
 * Errors:
 *	Throws Base64Exception on invalid base64 encoding in estr[].
 *	Throws Base64CharException on invalid base64 character in estr[].
 */
char[] decode(char[] estr, char[] buf)
in
{
	assert(buf.length + 2 >= decodeLength(estr.length)); //account for '=' padding
}
body
{
	void badc(char ch)
	{
		throw new Base64CharException("Invalid base64 character '" ~ (&ch)[0 .. 1] ~ "'");
	}
	
	
	uint arrayIndex(char ch)
	out(result)
	{
		assert(ch == array[result]);
	}
	body
	{
		if(ch >= 'A' && ch <= 'Z')
			return ch - 'A';
		if(ch >= 'a' && ch <= 'z')
			return 'Z' - 'A' + 1 + ch - 'a';
		if(ch >= '0' && ch <= '9')
			return 'Z' - 'A' + 1 + 'z' - 'a' + 1 + ch - '0';
		if(ch == '+')
			return 'Z' - 'A' + 1 + 'z' - 'a' + 1 + '9' - '0' + 1;
		if(ch == '/')
			return 'Z' - 'A' + 1 + 'z' - 'a' + 1 + '9' - '0' + 1 + 1;
		badc(ch);
		assert(0);
	}
	
	
	if(!estr.length)
		return buf[0 .. 0];
	
	if(estr.length % 4)
		throw new Base64Exception("Invalid encoded base64 string");
	
	size_t estri;
	size_t estrmax = estr.length / 4;
	uint x;
	char* sp, bp;
	char ch;
	
	sp = &estr[0];
	bp = &buf[0];
	for(estri = 0; estri != estrmax; estri++)
	{
		x = arrayIndex(sp[0]) << 18 | arrayIndex(sp[1]) << 12;
		sp += 2;

		ch = *sp++;
		if(ch == '=')
		{
			if(*sp++ != '=')
				badc('=');
			*bp++ = cast(char) (x >> 16);
			break;
		}
		x |= arrayIndex(ch) << 6;
		
		ch = *sp++;
		if(ch == '=')
		{
			*bp++ = cast(char) (x >> 16);
			*bp++ = cast(char) ((x >> 8) & 0xFF);
			break;
		}
		x |= arrayIndex(ch);
		
		*bp++ = cast(char) (x >> 16);
		*bp++ = cast(char) ((x >> 8) & 0xFF);
		*bp++ = cast(char) (x & 0xFF);
	}
	
	return buf[0 .. (bp - &buf[0])];
}

/**
 * Decodes estr[] and returns the result.
 * Errors:
 *	Throws Base64Exception on invalid base64 encoding in estr[].
 *	Throws Base64CharException on invalid base64 character in estr[].
 */

char[] decode(char[] estr)
{
	return decode(estr, new char[decodeLength(estr.length)]);
}


unittest
{
	assert(decode(encode("f")) == "f");
	assert(decode(encode("fo")) == "fo");
	assert(decode(encode("foo")) == "foo");
	assert(decode(encode("foos")) == "foos");
	assert(decode(encode("all your base64 are belong to foo")) == "all your base64 are belong to foo");
	
	assert(decode(encode("testing some more")) == "testing some more");
	assert(decode(encode("asdf jkl;")) == "asdf jkl;");
	assert(decode(encode("base64 stuff")) == "base64 stuff");
	assert(decode(encode("\1\2\3\4\5\6\7foo\7\6\5\4\3\2\1!")) == "\1\2\3\4\5\6\7foo\7\6\5\4\3\2\1!");
}

