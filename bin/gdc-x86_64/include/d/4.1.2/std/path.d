
/**
 * Macros:
 *	WIKI = Phobos/StdPath
 * Copyright:
 *	Placed into public domain.
 *	www.digitalmars.com
 *
 * Grzegorz Adam Hankiewicz added some documentation.
 *
 * This module is used to parse file names. All the operations
 * work only on strings; they don't perform any input/output
 * operations. This means that if a path contains a directory name
 * with a dot, functions like getExt() will work with it just as
 * if it was a file. To differentiate these cases,
 * use the std.file module first (i.e. std.file.isDir()).
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, March 2006
*/

module std.path;

//debug=path;		// uncomment to turn on debugging printf's
//private import std.stdio;

private import std.string;

version(Unix)
{
    private import std.c.stdlib;
    private import std.c.unix.unix;
    private import std.outofmemory;
}

version(Windows)
{

    /** String used to separate directory names in a path. Under
     *  Windows this is a backslash, under Linux a slash. */
    const char[1] sep = "\\";
    /** Alternate version of sep[] used in Windows (a slash). Under
     *  Linux this is empty. */
    const char[1] altsep = "/";
    /** Path separator string. A semi colon under Windows, a colon
     *  under Linux. */
    const char[1] pathsep = ";";
    /** String used to separate lines, \r\n under Windows and \n
     * under Linux. */
    const char[2] linesep = "\r\n"; /// String used to separate lines.
    const char[1] curdir = ".";	 /// String representing the current directory.
    const char[2] pardir = ".."; /// String representing the parent directory.
}
else version(Unix)
{
    /** String used to separate directory names in a path. Under
     *  Windows this is a backslash, under Linux a slash. */
    const char[1] sep = "/";
    /** Alternate version of sep[] used in Windows (a slash). Under
     *  Linux this is empty. */
    const char[0] altsep;
    /** Path separator string. A semi colon under Windows, a colon
     *  under Linux. */
    const char[1] pathsep = ":";
    /** String used to separate lines, \r\n under Windows and \n
     * under Linux. */
    const char[1] linesep = "\n";
    const char[1] curdir = ".";	 /// String representing the current directory.
    const char[2] pardir = ".."; /// String representing the parent directory.
}
else
{
    static assert(0);
}

/*****************************
 * Compare file names.
 * Returns:
 *	<table border=1 cellpadding=4 cellspacing=0>
 *	<tr> <td> &lt; 0	<td> filename1 &lt; filename2
 *	<tr> <td> = 0	<td> filename1 == filename2
 *	<tr> <td> &gt; 0	<td> filename1 &gt; filename2
 *	</table>
 */

version (Windows) alias std.string.icmp fcmp;

version (Unix) alias std.string.cmp fcmp;

/**************************
 * Extracts the extension from a filename or path.
 *
 * This function will search fullname from the end until the
 * first dot, path separator or first character of fullname is
 * reached. Under Windows, the drive letter separator (<i>colon</i>)
 * also terminates the search.
 *
 * Returns: If a dot was found, characters to its right are
 * returned. If a path separator was found, or fullname didn't
 * contain any dots or path separators, returns null.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * version(Win32)
 * {
 *     getExt(r"d:\path\foo.bat") // "bat"
 *     getExt(r"d:\path.two\bar") // null
 * }
 * version(linux)
 * {
 *     getExt(r"/home/user.name/bar.")  // ""
 *     getExt(r"d:\\path.two\\bar")     // "two\\bar"
 *     getExt(r"/home/user/.resource")  // "resource"
 * }
 * -----
 */

char[] getExt(char[] fullname)
{
    size_t i;

    i = fullname.length;
    while (i > 0)
    {
	if (fullname[i - 1] == '.')
	    return fullname[i .. fullname.length];
	i--;
	version(Win32)
	{
	    if (fullname[i] == ':' || fullname[i] == '\\')
		break;
	}
	else version(Unix)
	{
	    if (fullname[i] == '/')
		break;
	}
    }
    return null;
}

unittest
{
    debug(path) printf("path.getExt.unittest\n");
    int i;
    char[] result;

    version (Win32)
	result = getExt("d:\\path\\foo.bat");
    version (Unix)
	result = getExt("/path/foo.bat");
    i = cmp(result, "bat");
    assert(i == 0);

    version (Win32)
	result = getExt("d:\\path\\foo.");
    version (Unix)
	result = getExt("d/path/foo.");
    i = cmp(result, "");
    assert(i == 0);

    version (Win32)
	result = getExt("d:\\path\\foo");
    version (Unix)
	result = getExt("d/path/foo");
    i = cmp(result, "");
    assert(i == 0);

    version (Win32)
	result = getExt("d:\\path.bar\\foo");
    version (Unix)
	result = getExt("/path.bar/foo");

    i = cmp(result, "");
    assert(i == 0);

    result = getExt("foo");
    i = cmp(result, "");
    assert(i == 0);
}

/**************************
 * Returns the extensionless version of a filename or path.
 *
 * This function will search fullname from the end until the
 * first dot, path separator or first character of fullname is
 * reached. Under Windows, the drive letter separator (<i>colon</i>)
 * also terminates the search.
 *
 * Returns: If a dot was found, characters to its left are
 * returned. If a path separator was found, or fullname didn't
 * contain any dots or path separators, returns null.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * version(Win32)
 * {
 *     getName(r"d:\path\foo.bat") => "d:\path\foo"
 *     getName(r"d:\path.two\bar") => null
 * }
 * version(linux)
 * {
 *     getName("/home/user.name/bar.")  => "/home/user.name/bar"
 *     getName(r"d:\path.two\bar") => "d:\path"
 *     getName("/home/user/.resource") => "/home/user/"
 * }
 * -----
 */

char[] getName(char[] fullname)
{
    size_t i;

    i = fullname.length;
    while (i > 0)
    {
	if (fullname[i - 1] == '.')
	    return fullname[0 .. i - 1];
	i--;
	version(Win32)
	{
	    if (fullname[i] == ':' || fullname[i] == '\\')
		break;
	}
	version(Unix)
	{
	    if (fullname[i] == '/')
		break;
	}
    }
    return null;
}

unittest
{
    debug(path) printf("path.getName.unittest\n");
    int i;
    char[] result;

    result = getName("foo.bar");
    i = cmp(result, "foo");
    assert(i == 0);

    result = getName("d:\\path.two\\bar");
    version (Win32)
	i = cmp(result, null);
    version (linux)
	i = cmp(result, "d:\\path");
    assert(i == 0);
}

/**************************
 * Extracts the base name of a path.
 *
 * This function will search fullname from the end until the
 * first path separator or first character of fullname is
 * reached. Under Windows, the drive letter separator (<i>colon</i>)
 * also terminates the search.
 *
 * Returns: If a path separator was found, all the characters to its
 * right are returned. Otherwise, fullname is returned.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * version(Win32)
 * {
 *     getBaseName(r"d:\path\foo.bat") => "foo.bat"
 * }
 * version(linux)
 * {
 *     getBaseName("/home/user.name/bar.")  => "bar."
 * }
 * -----
 */

char[] getBaseName(char[] fullname)
    out (result)
    {
	assert(result.length <= fullname.length);
    }
    body
    {
	size_t i;

	for (i = fullname.length; i > 0; i--)
	{
	    version(Win32)
	    {
		if (fullname[i - 1] == ':' || fullname[i - 1] == '\\')
		    break;
	    }
	    else version(Unix)
	    {
		if (fullname[i - 1] == '/')
		    break;
	    }
	}
	return fullname[i .. fullname.length];
    }

unittest
{
    debug(path) printf("path.getBaseName.unittest\n");
    int i;
    char[] result;

    version (Windows)
	result = getBaseName("d:\\path\\foo.bat");
    version (Unix)
	result = getBaseName("/path/foo.bat");
    //printf("result = '%.*s'\n", result);
    i = cmp(result, "foo.bat");
    assert(i == 0);

    version (Windows)
	result = getBaseName("a\\b");
    version (Unix)
	result = getBaseName("a/b");
    i = cmp(result, "b");
    assert(i == 0);
}


/**************************
 * Extracts the directory part of a path.
 *
 * This function will search fullname from the end until the
 * first path separator or first character of fullname is
 * reached. Under Windows, the drive letter separator (<i>colon</i>)
 * also terminates the search.
 *
 * Returns: If a path separator was found, all the characters to its
 * left are returned. Otherwise, fullname is returned.
 *
 * Under Windows, the found path separator will be included in the
 * returned string if it is preceeded by a colon.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * version(Win32)
 * {
 *     getDirName(r"d:\path\foo.bat") => "d:\path"
 *     getDirName(getDirName(r"d:\path\foo.bat")) => "d:\"
 * }
 * version(linux)
 * {
 *     getDirName("/home/user")  => "/home"
 *     getDirName(getDirName("/home/user"))  => ""
 * }
 * -----
 */

char[] getDirName(char[] fullname)
    out (result)
    {
	assert(result.length <= fullname.length);
    }
    body
    {
	size_t i;

	for (i = fullname.length; i > 0; i--)
	{
	    version(Win32)
	    {
		if (fullname[i - 1] == ':')
		    break;
		if (fullname[i - 1] == '\\')
		{   i--;
		    break;
		}
	    }
	    else version(Unix)
	    {
		if (fullname[i - 1] == '/')
		{   i--;
		    break;
		}
	    }
	}
	return fullname[0 .. i];
    }


/********************************
 * Extracts the drive letter of a path.
 *
 * This function will search fullname for a colon from the beginning.
 *
 * Returns: If a colon is found, all the characters to its left
 * plus the colon are returned.  Otherwise, null is returned.
 *
 * Under Linux, this function always returns null immediately.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * getDrive(r"d:\path\foo.bat") => "d:"
 * -----
 */

char[] getDrive(char[] fullname)
    out (result)
    {
	assert(result.length <= fullname.length);
    }
    body
    {
	version(Win32)
	{
	    size_t i;

	    for (i = 0; i < fullname.length; i++)
	    {
		if (fullname[i] == ':')
		    return fullname[0 .. i + 1];
	    }
	    return null;
	}
	else version(Unix)
	{
	    return null;
	}
    }

/****************************
 * Appends a default extension to a filename.
 *
 * This function first searches filename for an extension and
 * appends ext if there is none. ext should not have any leading
 * dots, one will be inserted between filename and ext if filename
 * doesn't already end with one.
 *
 * Returns: filename if it contains an extension, otherwise filename
 * + ext.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * defaultExt("foo.txt", "raw") => "foo.txt"
 * defaultExt("foo.", "raw") => "foo.raw"
 * defaultExt("bar", "raw") => "bar.raw"
 * -----
 */

char[] defaultExt(char[] filename, char[] ext)
{
    char[] existing;

    existing = getExt(filename);
    if (existing.length == 0)
    {
	// Check for filename ending in '.'
	if (filename.length && filename[filename.length - 1] == '.')
	    filename ~= ext;
	else
	    filename = filename ~ "." ~ ext;
    }
    return filename;
}


/****************************
 * Adds or replaces an extension to a filename.
 *
 * This function first searches filename for an extension and
 * replaces it with ext if found.  If there is no extension, ext
 * will be appended. ext should not have any leading dots, one will
 * be inserted between filename and ext if filename doesn't already
 * end with one.
 *
 * Returns: filename + ext if filename is extensionless. Otherwise
 * strips filename's extension off, appends ext and returns the
 * result.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * addExt("foo.txt", "raw") => "foo.raw"
 * addExt("foo.", "raw") => "foo.raw"
 * addExt("bar", "raw") => "bar.raw"
 * -----
 */

char[] addExt(char[] filename, char[] ext)
{
    char[] existing;

    existing = getExt(filename);
    if (existing.length == 0)
    {
	// Check for filename ending in '.'
	if (filename.length && filename[filename.length - 1] == '.')
	    filename ~= ext;
	else
	    filename = filename ~ "." ~ ext;
    }
    else
    {
	filename = filename[0 .. filename.length - existing.length] ~ ext;
    }
    return filename;
}


/*************************************
 * Checks if path is absolute.
 *
 * Returns: non-zero if the path starts from the root directory (Linux) or
 * drive letter and root directory (Windows),
 * zero otherwise.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * version(Win32)
 * {
 *     isabs(r"relative\path") => 0
 *     isabs(r"\relative\path") => 0
 *     isabs(r"d:\absolute") => 1
 * }
 * version(linux)
 * {
 *     isabs("/home/user") => 1
 *     isabs("foo") => 0
 * }
 * -----
 */

int isabs(char[] path)
{
    char[] d = getDrive(path);

    version (Windows)
    {
	return d.length && d.length < path.length && path[d.length] == sep[0];
    }
    else
	return d.length < path.length && path[d.length] == sep[0];
}

unittest
{
    debug(path) printf("path.isabs.unittest\n");

    version (Windows)
    {
	assert(isabs(r"relative\path") == 0);
	assert(isabs(r"\relative\path") == 0);
	assert(isabs(r"d:\absolute") == 1);
    }
    version (linux)
    {
	assert(isabs("/home/user") == 1);
	assert(isabs("foo") == 0);
    }
}

/*************************************
 * Joins two path components.
 *
 * If p1 doesn't have a trailing path separator, one will be appended
 * to it before concatting p2.
 *
 * Returns: p1 ~ p2. However, if p2 is an absolute path, only p2
 * will be returned.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * version(Win32)
 * {
 *     join(r"c:\foo", "bar") => "c:\foo\bar"
 *     join("foo", r"d:\bar") => "d:\bar"
 * }
 * version(linux)
 * {
 *     join("/foo/", "bar") => "/foo/bar"
 *     join("/foo", "/bar") => "/bar"
 * }
 * -----
 */

char[] join(char[] p1, char[] p2)
{
    if (!p2.length)
	return p1;
    if (!p1.length)
	return p2;

    char[] p;
    char[] d1;

    version(Win32)
    {
	if (getDrive(p2))
	{
	    p = p2;
	}
	else
	{
	    d1 = getDrive(p1);
	    if (p1.length == d1.length)
	    {
		p = p1 ~ p2;
	    }
	    else if (p2[0] == '\\')
	    {
		if (d1.length == 0)
		    p = p2;
		else if (p1[p1.length - 1] == '\\')
		    p = p1 ~ p2[1 .. p2.length];
		else
		    p = p1 ~ p2;
	    }
	    else if (p1[p1.length - 1] == '\\')
	    {
		p = p1 ~ p2;
	    }
	    else
	    {
		p = p1 ~ sep ~ p2;
	    }
	}
    }
    else version(Unix)
    {
	if (p2[0] == sep[0])
	{
	    p = p2;
	}
	else if (p1[p1.length - 1] == sep[0])
	{
	    p = p1 ~ p2;
	}
	else
	{
	    p = p1 ~ sep ~ p2;
	}
    }
    return p;
}

unittest
{
    debug(path) printf("path.join.unittest\n");

    char[] p;
    int i;

    p = join("foo", "bar");
    version (Win32)
	i = cmp(p, "foo\\bar");
    version (Unix)
	i = cmp(p, "foo/bar");
    assert(i == 0);

    version (Win32)
    {	p = join("foo\\", "bar");
	i = cmp(p, "foo\\bar");
    }
    version (Unix)
    {	p = join("foo/", "bar");
	i = cmp(p, "foo/bar");
    }
    assert(i == 0);

    version (Win32)
    {	p = join("foo", "\\bar");
	i = cmp(p, "\\bar");
    }
    version (Unix)
    {	p = join("foo", "/bar");
	i = cmp(p, "/bar");
    }
    assert(i == 0);

    version (Win32)
    {	p = join("foo\\", "\\bar");
	i = cmp(p, "\\bar");
    }
    version (Unix)
    {	p = join("foo/", "/bar");
	i = cmp(p, "/bar");
    }
    assert(i == 0);

    version(Win32)
    {
	p = join("d:", "bar");
	i = cmp(p, "d:bar");
	assert(i == 0);

	p = join("d:\\", "bar");
	i = cmp(p, "d:\\bar");
	assert(i == 0);

	p = join("d:\\", "\\bar");
	i = cmp(p, "d:\\bar");
	assert(i == 0);

	p = join("d:\\foo", "bar");
	i = cmp(p, "d:\\foo\\bar");
	assert(i == 0);

	p = join("d:", "\\bar");
	i = cmp(p, "d:\\bar");
	assert(i == 0);

	p = join("foo", "d:");
	i = cmp(p, "d:");
	assert(i == 0);

	p = join("foo", "d:\\");
	i = cmp(p, "d:\\");
	assert(i == 0);

	p = join("foo", "d:\\bar");
	i = cmp(p, "d:\\bar");
	assert(i == 0);
    }
}


/*********************************
 * Matches filename characters.
 *
 * Under Windows, the comparison is done ignoring case. Under Linux
 * an exact match is performed.
 *
 * Returns: non zero if c1 matches c2, zero otherwise.
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * version(Win32)
 * {
 *     fncharmatch('a', 'b') => 0
 *     fncharmatch('A', 'a') => 1
 * }
 * version(linux)
 * {
 *     fncharmatch('a', 'b') => 0
 *     fncharmatch('A', 'a') => 0
 * }
 * -----
 */

int fncharmatch(dchar c1, dchar c2)
{
    version (Win32)
    {
	if (c1 != c2)
	{
	    if ('A' <= c1 && c1 <= 'Z')
		c1 += cast(char)'a' - 'A';
	    if ('A' <= c2 && c2 <= 'Z')
		c2 += cast(char)'a' - 'A';
	    return c1 == c2;
	}
	return true;
    }
    else version (Unix)
    {
	return c1 == c2;
    }
    /* this is filesystem-dependent, figure out the filesystem?
    else version (GNU)
    {
	// %% figure out filesystem?
	return c1 == c2;
    }
    */
}

/************************************
 * Matches a pattern against a filename.
 *
 * Some characters of pattern have special a meaning (they are
 * <i>meta-characters</i>) and <b>can't</b> be escaped. These are:
 * <p><table>
 * <tr><td><b>*</b></td>
 *     <td>Matches 0 or more instances of any character.</td></tr>
 * <tr><td><b>?</b></td>
 *     <td>Matches exactly one instances of any character.</td></tr>
 * <tr><td><b>[</b><i>chars</i><b>]</b></td>
 *     <td>Matches one instance of any character that appears
 *     between the brackets.</td></tr>
 * <tr><td><b>[!</b><i>chars</i><b>]</b></td>
 *     <td>Matches one instance of any character that does not appear
 *     between the brackets after the exclamation mark.</td></tr>
 * </table><p>
 * Internally individual character comparisons are done calling
 * fncharmatch(), so its rules apply here too. Note that path
 * separators and dots don't stop a meta-character from matching
 * further portions of the filename.
 *
 * Returns: non zero if pattern matches filename, zero otherwise.
 *
 * See_Also: fncharmatch().
 *
 * Throws: Nothing.
 *
 * Examples:
 * -----
 * version(Win32)
 * {
 *     fnmatch("foo.bar", "*") => 1
 *     fnmatch(r"foo/foo\bar", "f*b*r") => 1
 *     fnmatch("foo.bar", "f?bar") => 0
 *     fnmatch("Goo.bar", "[fg]???bar") => 1
 *     fnmatch(r"d:\foo\bar", "d*foo?bar") => 1
 * }
 * version(linux)
 * {
 *     fnmatch("Go*.bar", "[fg]???bar") => 0
 *     fnmatch("/foo*home/bar", "?foo*bar") => 1
 *     fnmatch("foobar", "foo?bar") => 1
 * }
 * -----
 */

int fnmatch(char[] filename, char[] pattern)
    in
    {
	// Verify that pattern[] is valid
	size_t i;
	int inbracket = false;

	for (i = 0; i < pattern.length; i++)
	{
	    switch (pattern[i])
	    {
		case '[':
		    assert(!inbracket);
		    inbracket = true;
		    break;

		case ']':
		    assert(inbracket);
		    inbracket = false;
		    break;

		default:
		    break;
	    }
	}
    }
    body
    {
	size_t pi;
	size_t ni;
	char pc;
	char nc;
	size_t j;
	int not;
	int anymatch;

	ni = 0;
	for (pi = 0; pi < pattern.length; pi++)
	{
	    pc = pattern[pi];
	    switch (pc)
	    {
		case '*':
		    if (pi + 1 == pattern.length)
			goto match;
		    for (j = ni; j < filename.length; j++)
		    {
			if (fnmatch(filename[j .. filename.length], pattern[pi + 1 .. pattern.length]))
			    goto match;
		    }
		    goto nomatch;

		case '?':
		    if (ni == filename.length)
			goto nomatch;
		    ni++;
		    break;

		case '[':
		    if (ni == filename.length)
			goto nomatch;
		    nc = filename[ni];
		    ni++;
		    not = 0;
		    pi++;
		    if (pattern[pi] == '!')
		    {	not = 1;
			pi++;
		    }
		    anymatch = 0;
		    while (1)
		    {
			pc = pattern[pi];
			if (pc == ']')
			    break;
			if (!anymatch && fncharmatch(nc, pc))
			    anymatch = 1;
			pi++;
		    }
		    if (!(anymatch ^ not))
			goto nomatch;
		    break;

		default:
		    if (ni == filename.length)
			goto nomatch;
		    nc = filename[ni];
		    if (!fncharmatch(pc, nc))
			goto nomatch;
		    ni++;
		    break;
	    }
	}
	if (ni < filename.length)
	    goto nomatch;

    match:
	return true;

    nomatch:
	return false;
    }

unittest
{
    debug(path) printf("path.fnmatch.unittest\n");

    version (Win32)
	assert(fnmatch("foo", "Foo"));
    version (Unix)
	assert(!fnmatch("foo", "Foo"));
    assert(fnmatch("foo", "*"));
    assert(fnmatch("foo.bar", "*"));
    assert(fnmatch("foo.bar", "*.*"));
    assert(fnmatch("foo.bar", "foo*"));
    assert(fnmatch("foo.bar", "f*bar"));
    assert(fnmatch("foo.bar", "f*b*r"));
    assert(fnmatch("foo.bar", "f???bar"));
    assert(fnmatch("foo.bar", "[fg]???bar"));
    assert(fnmatch("foo.bar", "[!gh]*bar"));

    assert(!fnmatch("foo", "bar"));
    assert(!fnmatch("foo", "*.*"));
    assert(!fnmatch("foo.bar", "f*baz"));
    assert(!fnmatch("foo.bar", "f*b*x"));
    assert(!fnmatch("foo.bar", "[gh]???bar"));
    assert(!fnmatch("foo.bar", "[!fg]*bar"));
    assert(!fnmatch("foo.bar", "[fg]???baz"));
}

/**
 * Performs tilde expansion in paths.
 *
 * There are two ways of using tilde expansion in a path. One
 * involves using the tilde alone or followed by a path separator. In
 * this case, the tilde will be expanded with the value of the
 * environment variable <i>HOME</i>.  The second way is putting
 * a username after the tilde (i.e. <tt>~john/Mail</tt>). Here,
 * the username will be searched for in the user database
 * (i.e. <tt>/etc/passwd</tt> on Unix systems) and will expand to
 * whatever path is stored there.  The username is considered the
 * string after the tilde ending at the first instance of a path
 * separator.
 *
 * Note that using the <i>~user</i> syntax may give different
 * values from just <i>~</i> if the environment variable doesn't
 * match the value stored in the user database.
 *
 * When the environment variable version is used, the path won't
 * be modified if the environment variable doesn't exist or it
 * is empty. When the database version is used, the path won't be
 * modified if the user doesn't exist in the database or there is
 * not enough memory to perform the query.
 *
 * Returns: inputPath with the tilde expanded, or just inputPath
 * if it could not be expanded.
 * For Windows, expandTilde() merely returns its argument inputPath.
 *
 * Throws: std.outofmemory.OutOfMemoryException if there is not enough
 * memory to perform
 * the database lookup for the <i>~user</i> syntax.
 *
 * Examples:
 * -----
 * import std.path;
 *
 * void process_file(char[] filename)
 * {
 *     char[] path = expandTilde(filename);
 *     ...
 * }
 * -----
 *
 * -----
 * import std.path;
 *
 * const char[] RESOURCE_DIR_TEMPLATE = "~/.applicationrc";
 * char[] RESOURCE_DIR;    // This gets expanded in main().
 *
 * int main(char[][] args)
 * {
 *     RESOURCE_DIR = expandTilde(RESOURCE_DIR_TEMPLATE);
 *     ...
 * }
 * -----
 * Version: Available since v0.143.
 * Authors: Grzegorz Adam Hankiewicz, Thomas Kühne.
 */

char[] expandTilde(char[] inputPath)
{
    version(Unix)
    {
	static assert(sep.length == 1);

        // Return early if there is no tilde in path.
        if (inputPath.length < 1 || inputPath[0] != '~')
	    return inputPath;

	if (inputPath.length == 1 || inputPath[1] == sep[0])
	    return expandFromEnvironment(inputPath);
        else
	    return expandFromDatabase(inputPath);
    }
    else version(Windows)
    {
	// Put here real windows implementation.
	return inputPath;
    }
    else
    {
	static assert(0); // Guard. Implement on other platforms.
    }
}


unittest
{
    debug(path) printf("path.expandTilde.unittest\n");

    version (Unix)
    {
	// Retrieve the current home variable.
	char* c_home = getenv("HOME");

	// Testing when there is no environment variable.
	unsetenv("HOME");
	assert(expandTilde("~/") == "~/");
	assert(expandTilde("~") == "~");

	// Testing when an environment variable is set.
	int ret = setenv("HOME", "dmd/test\0", 1);
	assert(ret == 0);
	assert(expandTilde("~/") == "dmd/test/");
	assert(expandTilde("~") == "dmd/test");

	// The same, but with a variable ending in a slash.
	ret = setenv("HOME", "dmd/test/\0", 1);
	assert(ret == 0);
	assert(expandTilde("~/") == "dmd/test/");
	assert(expandTilde("~") == "dmd/test");

	// Recover original HOME variable before continuing.
	if (c_home)
	    setenv("HOME", c_home, 1);
	else
	    unsetenv("HOME");

	// Test user expansion for root. Are there unices without /root?
	/*
	assert(expandTilde("~root") == "/root");
	assert(expandTilde("~root/") == "/root/");
	*/
	assert(expandTilde("~Idontexist/hey") == "~Idontexist/hey");
    }
}

version (Unix)
{

/**
 * Replaces the tilde from path with the environment variable HOME.
 */
private char[] expandFromEnvironment(char[] path)
{
    assert(path.length >= 1);
    assert(path[0] == '~');
    
    // Get HOME and use that to replace the tilde.
    char* home = getenv("HOME");
    if (home == null)
        return path;

    return combineCPathWithDPath(home, path, 1);
}


/**
 * Joins a path from a C string to the remainder of path.
 *
 * The last path separator from c_path is discarded. The result
 * is joined to path[char_pos .. length] if char_pos is smaller
 * than length, otherwise path is not appended to c_path.
 */
private char[] combineCPathWithDPath(char* c_path, char[] path, int char_pos)
{
    assert(c_path != null);
    assert(path.length > 0);
    assert(char_pos >= 0);

    // Search end of C string
    size_t end = std.string.strlen(c_path);

    // Remove trailing path separator, if any
    if (end && c_path[end - 1] == sep[0])
	end--;

    // Create our own copy, as lifetime of c_path is undocumented
    char[] cp = c_path[0 .. end].dup;

    // Do we append something from path?
    if (char_pos < path.length)
	cp ~= path[char_pos .. length];

    return cp;
}


/**
 * Replaces the tilde from path with the path from the user database.
 */
private char[] expandFromDatabase(char[] path)
{
    assert(path.length > 2 || (path.length == 2 && path[1] != sep[0]));
    assert(path[0] == '~');

    // Extract username, searching for path separator.
    char[] username;
    ptrdiff_t last_char = find(path, sep[0]);

    if (last_char == -1)
    {
        username = path[1 .. length] ~ '\0';
	last_char = username.length + 1;
    }
    else
    {
        username = path[1 .. last_char] ~ '\0';
    }
    assert(last_char > 1);
    
    version (GNU_Unix_Have_getpwnam_r)
    {
    
    // Reserve C memory for the getpwnam_r() function.
    passwd result;
    int extra_memory_size = 5 * 1024;
    void* extra_memory;

    while (1)
    {
	extra_memory = std.c.stdlib.malloc(extra_memory_size);
	if (extra_memory == null)
	    goto Lerror;

	// Obtain info from database.
	passwd *verify;
	std.c.stdlib.setErrno(0);
	if (getpwnam_r(username.ptr, &result, cast(char*) extra_memory, extra_memory_size,
		&verify) == 0)
	{
	    // Failure if verify doesn't point at result.
	    if (verify != &result)
		// username is not found, so return path[]
		goto Lnotfound;
	    break;
	}

	switch (std.c.stdlib.getErrno()) {
	case 0:
	case ENOENT:
	case ESRCH:
	case EBADF:
	case EPERM:
	    goto Lnotfound;
	case ERANGE:
	    break;
	default:
	    // not just out of memory: EMFILE, ENFILE too
	    goto Lerror;
	}

	// extra_memory isn't large enough
	std.c.stdlib.free(extra_memory);
	extra_memory_size *= 2;
    }

    path = combineCPathWithDPath(result.pw_dir, path, last_char);

Lnotfound:
    std.c.stdlib.free(extra_memory);
    return path;

Lerror:
    // Errors are going to be caused by running out of memory
    if (extra_memory)
	std.c.stdlib.free(extra_memory);
    _d_OutOfMemory();
    return null;

    }
    else
    {
	passwd * result;

	/* This does not guarantee another thread will not
	   use getpwnam at the same time */
	synchronized {
	    result = getpwnam(username);
	}
	
	if (result)
	    path = combineCPathWithDPath(result.pw_dir, path, last_char);
	return path;
    }
}

}
