
// Regular Expressions

/*
 *  Copyright (C) 2000-2005 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with Tango.
 */

/**********************************************
 * $(LINK2 http://www.digitalmars.com/ctg/regular.html, Regular expressions)
 * are a powerful method of string pattern matching.
 * The regular expression
 * language used is the same as that commonly used, however, some of the very
 * advanced forms may behave slightly differently.
 *
 * In the following guide, $(I pattern)[] refers to a
 * $(LINK2 http://www.digitalmars.com/ctg/regular.html, regular expression).
 * The $(I attributes)[] refers to
        a string controlling the interpretation
        of the regular expression.
        It consists of a sequence of one or more
        of the following characters:

        <table border=1 cellspacing=0 cellpadding=5>
        <caption>Attribute Characters</caption>
        $(TR $(TH Attribute) $(TH Action))
        <tr>
        $(TD $(B g))
        $(TD global; repeat over the whole input string)
        </tr>
        <tr>
        $(TD $(B i))
        $(TD case insensitive)
        </tr>
        <tr>
        $(TD $(B m))
        $(TD treat as multiple lines separated by newlines)
        </tr>
        </table>
 *
 * The $(I format)[] string has the formatting characters:
 *
 *      <table border=1 cellspacing=0 cellpadding=5>
        <caption>Formatting Characters</caption>
        $(TR $(TH Format) $(TH Replaced With))
        $(TR
        $(TD $(B $$))   $(TD $)
        )
        $(TR
        $(TD $(B $&))   $(TD The matched substring.)
        )
        $(TR
        $(TD $(B $`))   $(TD The portion of string that precedes the matched substring.)
        )
        $(TR
        $(TD $(B $'))   $(TD The portion of string that follows the matched substring.)
        )
        $(TR
        $(TD $(B $(DOLLAR))$(I n)) $(TD The $(I n)th capture, where $(I n)
                        is a single digit 1-9
                        and $$(I n) is not followed by a decimal digit.)
        )
        $(TR
        $(TD $(B $(DOLLAR))$(I nn)) $(TD The $(I nn)th capture, where $(I nn)
                        is a two-digit decimal
                        number 01-99.
                        If $(I nn)th capture is undefined or more than the number
                        of parenthesized subexpressions, use the empty
                        string instead.)
        )
        </table>

 *      Any other $ are left as is.
 *
 * References:
 *      $(LINK2 http://en.wikipedia.org/wiki/Regular_expressions, Wikipedia)
 * Macros:
 *      WIKI = StdRegexp
 *      DOLLAR = $
 */

/*
        Escape sequences:

        \nnn starts out a 1, 2 or 3 digit octal sequence,
        where n is an octal digit. If nnn is larger than
        0377, then the 3rd digit is not part of the sequence
        and is not consumed.
        For maximal portability, use exactly 3 digits.

        \xXX starts out a 1 or 2 digit hex sequence. X
        is a hex character. If the first character after the \x
        is not a hex character, the value of the sequence is 'x'
        and the XX are not consumed.
        For maximal portability, use exactly 2 digits.

        \uUUUU is a unicode sequence. There are exactly
        4 hex characters after the \u, if any are not, then
        the value of the sequence is 'u', and the UUUU are not
        consumed.

        Character classes:

        [a-b], where a is greater than b, will produce
        an error.

        References:

        http://www.unicode.org/unicode/reports/tr18/
 */

module tango.text.Regex;

//debug = Regex;

private
{
    import tango.stdc.string;
    import tango.stdc.stdio;
    import tango.stdc.ctype;
    import tango.stdc.stdlib; // for alloca

    import tango.core.BitArray;
    import tango.core.Vararg;
}

/** Regular expression to extract an _email address */
const char[] email =
    r"[a-zA-Z]([.]?([[a-zA-Z0-9_]-]+)*)?@([[a-zA-Z0-9_]\-_]+\.)+[a-zA-Z]{2,6}";

/** Regular expression to extract a _url */
const char[] url = r"(([h|H][t|T]|[f|F])[t|T][p|P]([s|S]?)\:\/\/|~/|/)?([\w]+:\w+@)?(([a-zA-Z]{1}([\w\-]+\.)+([\w]{2,5}))(:[\d]{1,5})?)?((/?\w+/)+|/?)(\w+\.[\w]{3,4})?([,]\w+)*((\?\w+=\w+)?(&\w+=\w+)*([,]\w*)*)?";

/************************************
 * One of these gets thrown on compilation errors
 */

class RegexException : Exception
{
    this(char[] msg)
    {
        super(msg);
    }
}

struct regmatch_t
{
    int rm_so;                  // index of start of match
    int rm_eo;                  // index past end of match
}

private alias char rchar;       // so we can make a wchar version

/******************************************************
 * Search string for matches with regular expression
 * pattern with attributes.
 * Replace each match with string generated from format.
 * Params:
 *      string = String to search.
 *      pattern = Regular expression pattern.
 *      format = Replacement string format.
 *      attributes = Regular expression attributes.
 * Returns:
 *      the resulting string
 * Example:
 *      Replace the letters 'a' with the letters 'ZZ'.
 * ---
 * s = "Strap a rocket engine on a chicken."
 * sub(s, "a", "ZZ")        // result: StrZZp a rocket engine on a chicken.
 * sub(s, "a", "ZZ", "g")   // result: StrZZp ZZ rocket engine on ZZ chicken.
 * ---
 *      The replacement format can reference the matches using
 *      the $&amp;, $$, $', $`, $0 .. $99 notation:
 * ---
 * sub(s, "[ar]", "[$&]", "g") // result: St[r][a]p [a] [r]ocket engine on [a] chi
 * ---
 */

char[] sub(char[] string, char[] pattern, char[] format, char[] attributes = null)
{
    auto r = new Regex(pattern, attributes);
    auto result = r.replace(string, format);
    delete r;
    return result;
}

debug( UnitTest )
{
    unittest
    {
        debug(Regex) printf("Regex.sub.unittest\n");

        char[] r = sub("hello", "ll", "ss");
        assert(r == "hesso");
    }
}

/*******************************************************
 * Search string for matches with regular expression
 * pattern with attributes.
 * Pass each match to delegate dg.
 * Replace each match with the return value from dg.
 * Params:
 *      string = String to search.
 *      pattern = Regular expression pattern.
 *      dg = Delegate
 *      attributes = Regular expression attributes.
 * Returns: the resulting string.
 * Example:
 * Capitalize the letters 'a' and 'r':
 * ---
 * s = "Strap a rocket engine on a chicken.";
 * sub(s, "[ar]",
 *    delegate char[] (Regex m)
 *    {
 *         return toupper(m.match(0));
 *    },
 *    "g");    // result: StRAp A Rocket engine on A chicken.
 * ---
 */

char[] sub(char[] string, char[] pattern, char[] delegate(Regex) dg, char[] attributes = null)
{
    auto r = new Regex(pattern, attributes);
    rchar[] result;
    int lastindex;
    int offset;

    result = string;
    lastindex = 0;
    offset = 0;
    while (r.test(string, lastindex))
    {
        int so = r.pmatch[0].rm_so;
        int eo = r.pmatch[0].rm_eo;

        rchar[] replacement = dg(r);
/+
 + TODO: Add std.string.replace so this may be used.
 +
        // Optimize by using std.string.replace if possible - Dave Fladebo
        rchar[] slice = result[offset + so .. offset + eo];
        if (r.attributes & Regex.REA.global &&          // global, so replace all
            !(r.attributes & Regex.REA.ignoreCase) &&   // not ignoring case
            !(r.attributes & Regex.REA.multiline) &&    // not multiline
            pattern == slice)                           // simple pattern (exact match, no special characters)
        {
            debug(Regex)
            printf("pattern: %.*s, slice: %.*s, replacement: %.*s\n",
                cast(int) pattern.length, pattern.ptr,
                cast(int) (eo-so), result.ptr + offset,
                cast(int) replacement.length, replacement.ptr);
                result = std.string.replace(result,slice,replacement);
            break;
        }
+/
        result = replaceSlice(result, result[offset + so .. offset + eo], replacement);

        if (r.attributes & Regex.REA.global)
        {
            offset += replacement.length - (eo - so);

            if (lastindex == eo)
                lastindex++;            // always consume some source
            else
                lastindex = eo;
        }
        else
            break;
    }
    delete r;

    return result;
}

debug( UnitTest )
{
    unittest
    {
        debug(Regex) printf("Regex.sub.unittest\n");

        char[] foo(Regex r) { return "ss"; }

        char[] r = sub("hello", "ll", delegate char[](Regex r) { return "ss"; });
        assert(r == "hesso");
    }
}


/*************************************************
 * Search string[] for first match with pattern[] with attributes[].
 * Params:
 *      string = String to search.
 *      pattern = Regular expression pattern.
 *      attributes = Regular expression attributes.
 * Returns:
 *      index into string[] of match if found, -1 if no match.
 * Example:
 * ---
 * auto s = "abcabcabab";
 * tango.text.Regex.find(s, "b");    // match, returns 1
 * tango.text.Regex.find(s, "f");    // no match, returns -1
 * ---
 */

int find(rchar[] string, char[] pattern, char[] attributes = null)
{
    int i = -1;

    auto r = new Regex(pattern, attributes);
    if (r.test(string))
    {
        i = r.pmatch[0].rm_so;
    }
    delete r;
    return i;
}

debug( UnitTest )
{
    unittest
    {
        debug(Regex) printf("Regex.find.unittest\n");

        int i;
        i = find("xabcy", "abc");
        assert(i == 1);
        i = find("cba", "abc");
        assert(i == -1);
    }
}



/*************************************************
 * Search string[] for last match with pattern[] with attributes[].
 * Params:
 *      string = String to search.
 *      pattern = Regular expression pattern.
 *      attributes = Regular expression attributes.
 * Returns:
 *      index into string[] of match if found, -1 if no match.
 * Example:
 * ---
 * auto s = "abcabcabab";
 * tango.text.Regex.find(s, "b");    // match, returns 9
 * tango.text.Regex.find(s, "f");    // no match, returns -1
 * ---
 */

int rfind(rchar[] string, char[] pattern, char[] attributes = null)
{
    int i = -1;
    int lastindex = 0;

    auto r = new Regex(pattern, attributes);
    while (r.test(string, lastindex))
    {   int eo = r.pmatch[0].rm_eo;
        i = r.pmatch[0].rm_so;
        if (lastindex == eo)
            lastindex++;                // always consume some source
        else
            lastindex = eo;
    }
    delete r;
    return i;
}

debug( UnitTest )
{
    unittest
    {
        int i;

        debug(Regex) printf("Regex.rfind.unittest\n");
        i = rfind("abcdefcdef", "c");
        assert(i == 6);
        i = rfind("abcdefcdef", "cd");
        assert(i == 6);
        i = rfind("abcdefcdef", "x");
        assert(i == -1);
        i = rfind("abcdefcdef", "xy");
        assert(i == -1);
        i = rfind("abcdefcdef", "");
        assert(i == 10);
    }
}


/********************************************
 * Split string[] into an array of strings, using the regular
 * expression pattern[] with attributes[] as the separator.
 * Params:
 *      string = String to search.
 *      pattern = Regular expression pattern.
 *      attributes = Regular expression attributes.
 * Returns:
 *      array of slices into string[]
 * Example:
 * ---
 * foreach (s; split("abcabcabab", "C.", "i"))
 * {
 *     writefln("s = '%s'", s);
 * }
 * // Prints:
 * // s = 'ab'
 * // s = 'b'
 * // s = 'bab'
 * ---
 */

char[][] split(char[] string, char[] pattern, char[] attributes = null)
{
    auto r = new Regex(pattern, attributes);
    auto result = r.split(string);
    delete r;
    return result;
}

debug( UnitTest )
{
    unittest
    {
        debug(Regex) printf("Regex.split.unittest()\n");
        char[][] result;

        result = split("ab", "a*");
        assert(result.length == 2);
        assert(result[0] == "");
        assert(result[1] == "b");
    }
}

/****************************************************
 * Search string[] for first match with pattern[] with attributes[].
 * Params:
 *      string = String to search.
 *      pattern = Regular expression pattern.
 *      attributes = Regular expression attributes.
 * Returns:
 *      corresponding Regex if found, null if not.
 * Example:
 * ---
 * import tango.stdc.stdio;
 * import tango.text.Regex;
 *
 * void main()
 * {
 *     if (auto m = tango.text.Regex.search("abcdef", "c"))
 *     {
 *         writefln("%s[%s]%s", m.pre, m.match(0), m.post);
 *     }
 * }
 * // Prints:
 * // ab[c]def
 * ---
 */

Regex search(char[] string, char[] pattern, char[] attributes = null)
{
    auto r = new Regex(pattern, attributes);

    if (r.test(string))
    {
    }
    else
    {   delete r;
        r = null;
    }
    return r;
}

/* ********************************* Regex ******************************** */

/*****************************
 * Regex is a class to handle regular expressions.
 *
 * It is the core foundation for adding powerful string pattern matching
 * capabilities to programs like grep, text editors, awk, sed, etc.
 */
class Regex
{
    /*****
     * Construct a Regex object. Compile pattern
     * with <i>attributes</i> into
     * an internal form for fast execution.
     * Params:
     *  pattern = regular expression
     *  attributes = _attributes
     * Throws: RegexException if there are any compilation errors.
     * Example:
     *  Declare two variables and assign to them a Regex object:
     * ---
     * auto r = new Regex("pattern");
     * auto s = new Regex(r"p[1-5]\s*");
     * ---
     */
    public this(rchar[] pattern, rchar[] attributes = null)
    {
        pmatch = (&gmatch)[0 .. 1];
        compile(pattern, attributes);
    }

    /*****
     * Generate instance of Regex.
     * Params:
     *  pattern = regular expression
     *  attributes = _attributes
     * Throws: RegexException if there are any compilation errors.
     * Example:
     *  Declare two variables and assign to them a Regex object:
     * ---
     * auto r = Regex("pattern");
     * auto s = Regex(r"p[1-5]\s*");
     */
    public static Regex opCall(rchar[] pattern, rchar[] attributes = null)
    {
        return new Regex(pattern, attributes);
    }

    /************************************
     * Set up for start of foreach loop.
     * Returns:
     *  search() returns instance of Regex set up to _search string[].
     * Example:
     * ---
     * import tango.stdc.stdio;
     * import tango.text.Regex;
     *
     * void main()
     * {
     *     foreach(m; Regex("ab").search("abcabcabab"))
     *     {
     *         writefln("%s[%s]%s", m.pre, m.match(0), m.post);
     *     }
     * }
     * // Prints:
     * // [ab]cabcabab
     * // abc[ab]cabab
     * // abcabc[ab]ab
     * // abcabcab[ab]
     * ---
     */

    public Regex search(rchar[] string)
    {
        input = string;
        pmatch[0].rm_eo = 0;
        return this;
    }

    /** ditto */
    public int opApply(int delegate(inout Regex) dg)
    {
        int result;
        Regex r = this;

        while (test())
        {
            result = dg(r);
            if (result)
                break;
        }

        return result;
    }

    /******************
     * Retrieve match n.
     *
     * n==0 means the matched substring, n>0 means the
     * n'th parenthesized subexpression.
     * if n is larger than the number of parenthesized subexpressions,
     * null is returned.
     */
    public char[] match(size_t n)
    {
        if (n >= pmatch.length)
            return null;
        else
        {   size_t rm_so, rm_eo;
            rm_so = pmatch[n].rm_so;
            rm_eo = pmatch[n].rm_eo;
            if (rm_so == rm_eo)
                return null;
            return input[rm_so .. rm_eo];
        }
    }

    /*******************
     * Return the slice of the input that precedes the matched substring.
     */
    public char[] pre()
    {
        return input[0 .. pmatch[0].rm_so];
    }

    /*******************
     * Return the slice of the input that follows the matched substring.
     */
    public char[] post()
    {
        return input[pmatch[0].rm_eo .. $];
    }

    uint re_nsub;               // number of parenthesized subexpression matches
    regmatch_t[] pmatch;        // array [re_nsub + 1]

    rchar[] input;              // the string to search

    // per instance:

    rchar[] pattern;            // source text of the regular expression

    rchar[] flags;              // source text of the attributes parameter

    int errors;

    uint attributes;

    enum REA
    {
        global          = 1,    // has the g attribute
        ignoreCase      = 2,    // has the i attribute
        multiline       = 4,    // if treat as multiple lines separated
                                // by newlines, or as a single line
        dotmatchlf      = 8,    // if . matches \n
    }


private:
    size_t src;                 // current source index in input[]
    size_t src_start;           // starting index for match in input[]
    size_t p;                   // position of parser in pattern[]
    regmatch_t gmatch;          // match for the entire regular expression
                                // (serves as storage for pmatch[0])

    ubyte[] program;            // pattern[] compiled into regular expression program
    OutBuffer buf;




/******************************************/

// Opcodes

enum : ubyte
{
    REend,              // end of program
    REchar,             // single character
    REichar,            // single character, case insensitive
    REdchar,            // single UCS character
    REidchar,           // single wide character, case insensitive
    REanychar,          // any character
    REanystar,          // ".*"
    REstring,           // string of characters
    REistring,          // string of characters, case insensitive
    REtestbit,          // any in bitmap, non-consuming
    REbit,              // any in the bit map
    REnotbit,           // any not in the bit map
    RErange,            // any in the string
    REnotrange,         // any not in the string
    REor,               // a | b
    REplus,             // 1 or more
    REstar,             // 0 or more
    REquest,            // 0 or 1
    REnm,               // n..m
    REnmq,              // n..m, non-greedy version
    REbol,              // beginning of line
    REeol,              // end of line
    REparen,            // parenthesized subexpression
    REgoto,             // goto offset

    REwordboundary,
    REnotwordboundary,
    REdigit,
    REnotdigit,
    REspace,
    REnotspace,
    REword,
    REnotword,
    REbackref,
}

// BUG: should this include '$'?
private int isword(dchar c) { return isalnum(c) || c == '_'; }

private uint inf = ~0u;

/* ********************************
 * Throws RegexException on error
 */

public void compile(rchar[] pattern, rchar[] attributes)
{
    //printf("Regex.compile('%.*s', '%.*s')\n", pattern, attributes);

    this.attributes = 0;
    foreach (rchar c; attributes)
    {   REA att;

        switch (c)
        {
            case 'g': att = REA.global;         break;
            case 'i': att = REA.ignoreCase;     break;
            case 'm': att = REA.multiline;      break;
            default:
                error("unrecognized attribute");
                return;
        }
        if (this.attributes & att)
        {   error("redundant attribute");
            return;
        }
        this.attributes |= att;
    }

    input = null;

    this.pattern = pattern;
    this.flags = attributes;

    uint oldre_nsub = re_nsub;
    re_nsub = 0;
    errors = 0;

    buf = new OutBuffer();
    buf.reserve(pattern.length * 8);
    p = 0;
    parseRegexp();
    if (p < pattern.length)
    {   error("unmatched ')'");
    }
    optimize();
    program = buf.data;
    buf.data = null;
    delete buf;

    if (re_nsub > oldre_nsub)
    {
        if (pmatch.ptr is &gmatch)
            pmatch = null;
        pmatch.length = re_nsub + 1;
    }
    pmatch[0].rm_so = 0;
    pmatch[0].rm_eo = 0;
}

/********************************************
 * Split string[] into an array of strings, using the regular
 * expression as the separator.
 * Returns:
 *      array of slices into string[]
 */

public rchar[][] split(rchar[] string)
{
    debug(Regex) printf("Regex.split()\n");

    rchar[][] result;

    if (string.length)
    {
        int p = 0;
        int q;
        for (q = p; q != string.length;)
        {
            if (test(string, q))
            {   int e;

                q = pmatch[0].rm_so;
                e = pmatch[0].rm_eo;
                if (e != p)
                {
                    result ~= string[p .. q];
                    for (int i = 1; i < pmatch.length; i++)
                    {
                        int so = pmatch[i].rm_so;
                        int eo = pmatch[i].rm_eo;
                        if (so == eo)
                        {   so = 0;     // -1 gives array bounds error
                            eo = 0;
                        }
                        result ~= string[so .. eo];
                    }
                    q = p = e;
                    continue;
                }
            }
            q++;
        }
        result ~= string[p .. string.length];
    }
    else if (!test(string))
        result ~= string;
    return result;
}

debug( UnitTest )
{
    unittest
    {
        debug(Regex) printf("Regex.split.unittest()\n");

        auto r = new Regex("a*?", null);
        rchar[][] result;
        rchar[] j;
        int i;

        result = r.split("ab");

        assert(result.length == 2);
        i = cmp(result[0], "a");
        assert(i == 0);
        i = cmp(result[1], "b");
        assert(i == 0);

        r = new Regex("a*", null);
        result = r.split("ab");
        assert(result.length == 2);
        i = cmp(result[0], "");
        assert(i == 0);
        i = cmp(result[1], "b");
        assert(i == 0);

        r = new Regex("<(\\/)?([^<>]+)>", null);
        result = r.split("a<b>font</b>bar<TAG>hello</TAG>");

        for (i = 0; i < result.length; i++)
        {
            //debug(Regex) printf("result[%d] = '%.*s'\n", i, result[i]);
        }

        j = join(result, ",");
        //printf("j = '%.*s'\n", j);
        i = cmp(j, "a,,b,font,/,b,bar,,TAG,hello,/,TAG,");
        assert(i == 0);

        r = new Regex("a[bc]", null);
        result = r.match("123ab");
        j = join(result, ",");
        i = cmp(j, "ab");
        assert(i == 0);

        result = r.match("ac");
        j = join(result, ",");
        i = cmp(j, "ac");
        assert(i == 0);
    }
}

/*************************************************
 * Search string[] for match with regular expression.
 * Returns:
 *      index of match if successful, -1 if not found
 */

public int find(rchar[] string)
{
    int i;

    i = test(string);
    if (i)
        i = pmatch[0].rm_so;
    else
        i = -1;                 // no match
    return i;
}

//deprecated alias find search;

debug( UnitTest )
{
    unittest
    {
        debug(Regex) printf("Regex.find.unittest()\n");

        int i;
        Regex r = new Regex("abc", null);
        i = r.find("xabcy");
        assert(i == 1);
        i = r.find("cba");
        assert(i == -1);
    }
}


/*************************************************
 * Search string[] for match.
 * Returns:
 *      If global attribute, return same value as exec(string).
 *      If not global attribute, return array of all matches.
 */

public rchar[][] match(rchar[] string)
{
    rchar[][] result;

    if (attributes & REA.global)
    {
        int lastindex = 0;

        while (test(string, lastindex))
        {   int eo = pmatch[0].rm_eo;

            result ~= input[pmatch[0].rm_so .. eo];
            if (lastindex == eo)
                lastindex++;            // always consume some source
            else
                lastindex = eo;
        }
    }
    else
    {
        result = exec(string);
    }
    return result;
}

debug( UnitTest )
{
    unittest
    {
        debug(Regex) printf("Regex.match.unittest()\n");

        int i;
        rchar[][] result;
        rchar[] j;
        Regex r;

        r = new Regex("a[bc]", null);
        result = r.match("1ab2ac3");
        j = join(result, ",");
        i = cmp(j, "ab");
        assert(i == 0);

        r = new Regex("a[bc]", "g");
        result = r.match("1ab2ac3");
        j = join(result, ",");
        i = cmp(j, "ab,ac");
        assert(i == 0);
    }
}

/*************************************************
 * Find regular expression matches in string[]. Replace those matches
 * with a new _string composed of format[] merged with the result of the
 * matches.
 * If global, replace all matches. Otherwise, replace first match.
 * Returns: the new _string
 */

public rchar[] replace(rchar[] string, rchar[] format)
{
    rchar[] result;
    int lastindex;
    int offset;

    result = string;
    lastindex = 0;
    offset = 0;
    for (;;)
    {
        if (!test(string, lastindex))
            break;

        int so = pmatch[0].rm_so;
        int eo = pmatch[0].rm_eo;

        rchar[] replacement = replace(format);
/+
 + TODO: Add std.string.replace so this may be used.
 +
        // Optimize by using std.string.replace if possible - Dave Fladebo
        rchar[] slice = result[offset + so .. offset + eo];
        if (attributes & REA.global &&          // global, so replace all
           !(attributes & REA.ignoreCase) &&    // not ignoring case
           !(attributes & REA.multiline) &&     // not multiline
           pattern == slice &&                  // simple pattern (exact match, no special characters)
           format == replacement)               // simple format, not $ formats
        {
            debug(Regex)
            printf("pattern: %.*s, slice: %.*s, format: %.*s, replacement: %.*s\n",
                cast(int) pattern.length, pattern.ptr,
                cast(int) (eo-so), result.ptr + offset,
                cast(int) format.length, format.ptr,
                cast(int) replacement.length, replacement.ptr);
                result = std.string.replace(result,slice,replacement);
            break;
        }
+/
        result = replaceSlice(result, result[offset + so .. offset + eo], replacement);

        if (attributes & REA.global)
        {
            offset += replacement.length - (eo - so);

            if (lastindex == eo)
                lastindex++;            // always consume some source
            else
                lastindex = eo;
        }
        else
            break;
    }

    return result;
}

debug( UnitTest )
{
    unittest
    {
        debug(Regex) printf("Regex.replace.unittest()\n");

        int i;
        rchar[] result;
        Regex r;

        r = new Regex("a[bc]", "g");
        result = r.replace("1ab2ac3", "x$&y");
        i = cmp(result, "1xaby2xacy3");
        assert(i == 0);
    }
}

/*************************************************
 * Search string[] for match.
 * Returns:
 *      array of slices into string[] representing matches
 */

public rchar[][] exec(rchar[] string)
{
    debug(Regex) printf("Regex.exec(string = '%.*s')\n",
                        cast(int) string.length, string.ptr);
    input = string;
    pmatch[0].rm_so = 0;
    pmatch[0].rm_eo = 0;
    return exec();
}

/*************************************************
 * Pick up where last exec(string) or exec() left off,
 * searching string[] for next match.
 * Returns:
 *      array of slices into string[] representing matches
 */

public rchar[][] exec()
{
    if (!test())
        return null;

    auto result = new rchar[][pmatch.length];
    for (int i = 0; i < pmatch.length; i++)
    {
        if (pmatch[i].rm_so == pmatch[i].rm_eo)
            result[i] = null;
        else
            result[i] = input[pmatch[i].rm_so .. pmatch[i].rm_eo];
    }

    return result;
}

/************************************************
 * Search string[] for match.
 * Returns: 0 for no match, !=0 for match
 */

public int test(rchar[] string)
{
    return test(string, 0 /*pmatch[0].rm_eo*/);
}

/************************************************
 * Pick up where last test(string) or test() left off, and search again.
 * Returns: 0 for no match, !=0 for match
 */

public int test()
{
    return test(input, pmatch[0].rm_eo);
}

/************************************************
 * Test string[] starting at startindex against regular expression.
 * Returns: 0 for no match, !=0 for match
 */

public int test(char[] string, int startindex)
{
    char firstc;
    uint si;

    input = string;
    debug (Regex) printf("Regex.test(input[] = '%.*s', startindex = %d)\n", input, startindex);
    pmatch[0].rm_so = 0;
    pmatch[0].rm_eo = 0;
    if (startindex < 0 || startindex > input.length)
    {
        return 0;                       // fail
    }
    //debug(Regex) printProgram(program);

    // First character optimization
    firstc = 0;
    if (program[0] == REchar)
    {
        firstc = program[1];
        if (attributes & REA.ignoreCase && isalpha(firstc))
            firstc = 0;
    }

    for (si = startindex; ; si++)
    {
        if (firstc)
        {
            if (si == input.length)
                break;                  // no match
            if (input[si] != firstc)
            {
                si++;
                if (!chr(si, firstc))   // if first character not found
                    break;              // no match
            }
        }
        for (int i = 0; i < re_nsub + 1; i++)
        {
            pmatch[i].rm_so = -1;
            pmatch[i].rm_eo = -1;
        }
        src_start = src = si;
        if (trymatch(0, program.length))
        {
            pmatch[0].rm_so = si;
            pmatch[0].rm_eo = src;
            //debug(Regex) printf("start = %d, end = %d\n", gmatch.rm_so, gmatch.rm_eo);
            return 1;
        }
        // If possible match must start at beginning, we are done
        if (program[0] == REbol || program[0] == REanystar)
        {
            if (attributes & REA.multiline)
            {
                // Scan for the next \n
                if (!chr(si, '\n'))
                    break;              // no match if '\n' not found
            }
            else
                break;
        }
        if (si == input.length)
            break;
        //debug(Regex) printf("Starting new try: '%.*s'\n", input[si + 1 .. input.length]);
    }
    return 0;           // no match
}

int chr(inout uint si, rchar c)
{
    for (; si < input.length; si++)
    {
        if (input[si] == c)
            return 1;
    }
    return 0;
}


void printProgram(ubyte[] prog)
{
  debug(Regex)
  {
    uint pc;
    uint len;
    uint n;
    uint m;
    ushort *pu;
    uint *puint;
    ubyte[] s;

    printf("printProgram()\n");
    for (pc = 0; pc < prog.length; )
    {
        printf("%3d: ", pc);

        //printf("prog[pc] = %d, REchar = %d, REnmq = %d\n", prog[pc], REchar, REnmq);
        switch (prog[pc])
        {
            case REchar:
                printf("\tREchar '%c'\n", prog[pc + 1]);
                pc += 1 + char.sizeof;
                break;

            case REichar:
                printf("\tREichar '%c'\n", prog[pc + 1]);
                pc += 1 + char.sizeof;
                break;

            case REdchar:
                printf("\tREdchar '%c'\n", *cast(dchar *)&prog[pc + 1]);
                pc += 1 + dchar.sizeof;
                break;

            case REidchar:
                printf("\tREidchar '%c'\n", *cast(dchar *)&prog[pc + 1]);
                pc += 1 + dchar.sizeof;
                break;

            case REanychar:
                printf("\tREanychar\n");
                pc++;
                break;

            case REstring:
                len = *cast(uint *)&prog[pc + 1];
                s = (&prog[pc + 1 + uint.sizeof])[0 .. len];
                printf("\tREstring x%x, '%.*s'\n", len,
            cast(int) s.length, s.ptr);
                pc += 1 + uint.sizeof + len * rchar.sizeof;
                break;

            case REistring:
                len = *cast(uint *)&prog[pc + 1];
                s = (&prog[pc + 1 + uint.sizeof])[0 .. len];
                printf("\tREistring x%x, '%.*s'\n", len,
                    cast(int) s.length, s.ptr);
                pc += 1 + uint.sizeof + len * rchar.sizeof;
                break;

            case REtestbit:
                pu = cast(ushort *)&prog[pc + 1];
                printf("\tREtestbit %d, %d\n", pu[0], pu[1]);
                len = pu[1];
                pc += 1 + 2 * ushort.sizeof + len;
                break;

            case REbit:
                pu = cast(ushort *)&prog[pc + 1];
                len = pu[1];
                printf("\tREbit cmax=%02x, len=%d:", pu[0], len);
                for (n = 0; n < len; n++)
                    printf(" %02x", prog[pc + 1 + 2 * ushort.sizeof + n]);
                printf("\n");
                pc += 1 + 2 * ushort.sizeof + len;
                break;

            case REnotbit:
                pu = cast(ushort *)&prog[pc + 1];
                printf("\tREnotbit %d, %d\n", pu[0], pu[1]);
                len = pu[1];
                pc += 1 + 2 * ushort.sizeof + len;
                break;

            case RErange:
                len = *cast(uint *)&prog[pc + 1];
                printf("\tRErange %d\n", len);
                // BUG: REAignoreCase?
                pc += 1 + uint.sizeof + len;
                break;

            case REnotrange:
                len = *cast(uint *)&prog[pc + 1];
                printf("\tREnotrange %d\n", len);
                // BUG: REAignoreCase?
                pc += 1 + uint.sizeof + len;
                break;

            case REbol:
                printf("\tREbol\n");
                pc++;
                break;

            case REeol:
                printf("\tREeol\n");
                pc++;
                break;

            case REor:
                len = *cast(uint *)&prog[pc + 1];
                printf("\tREor %d, pc=>%d\n", len, pc + 1 + uint.sizeof + len);
                pc += 1 + uint.sizeof;
                break;

            case REgoto:
                len = *cast(uint *)&prog[pc + 1];
                printf("\tREgoto %d, pc=>%d\n", len, pc + 1 + uint.sizeof + len);
                pc += 1 + uint.sizeof;
                break;

            case REanystar:
                printf("\tREanystar\n");
                pc++;
                break;

            case REnm:
            case REnmq:
                // len, n, m, ()
                puint = cast(uint *)&prog[pc + 1];
                len = puint[0];
                n = puint[1];
                m = puint[2];
                printf("\tREnm%s len=%d, n=%u, m=%u, pc=>%d\n",
                    (prog[pc] == REnmq) ? cast(char*)"q" : cast(char*)" ",
                    len, n, m, pc + 1 + uint.sizeof * 3 + len);
                pc += 1 + uint.sizeof * 3;
                break;

            case REparen:
                // len, n, ()
                puint = cast(uint *)&prog[pc + 1];
                len = puint[0];
                n = puint[1];
                printf("\tREparen len=%d n=%d, pc=>%d\n", len, n, pc + 1 + uint.sizeof * 2 + len);
                pc += 1 + uint.sizeof * 2;
                break;

            case REend:
                printf("\tREend\n");
                return;

            case REwordboundary:
                printf("\tREwordboundary\n");
                pc++;
                break;

            case REnotwordboundary:
                printf("\tREnotwordboundary\n");
                pc++;
                break;

            case REdigit:
                printf("\tREdigit\n");
                pc++;
                break;

            case REnotdigit:
                printf("\tREnotdigit\n");
                pc++;
                break;

            case REspace:
                printf("\tREspace\n");
                pc++;
                break;

            case REnotspace:
                printf("\tREnotspace\n");
                pc++;
                break;

            case REword:
                printf("\tREword\n");
                pc++;
                break;

            case REnotword:
                printf("\tREnotword\n");
                pc++;
                break;

            case REbackref:
                printf("\tREbackref %d\n", prog[1]);
                pc += 2;
                break;

            default:
                assert(0);
        }
    }
  }
}


/**************************************************
 * Match input against a section of the program[].
 * Returns:
 *      1 if successful match
 *      0 no match
 */

int trymatch(int pc, int pcend)
{   int srcsave;
    uint len;
    uint n;
    uint m;
    uint count;
    uint pop;
    uint ss;
    regmatch_t *psave;
    uint c1;
    uint c2;
    ushort* pu;
    uint* puint;

    debug(Regex)
    {
        char[] s = input[src .. input.length];
        printf("Regex.trymatch(pc = %d, src = '%.*s', pcend = %d)\n",
               pc, cast(int) s.length, s.ptr, pcend);
    }
    srcsave = src;
    psave = null;
    for (;;)
    {
        if (pc == pcend)                // if done matching
        {   debug(regex) printf("\tprogend\n");
            return 1;
        }

        //printf("\top = %d\n", program[pc]);
        switch (program[pc])
        {
            case REchar:
                if (src == input.length)
                    goto Lnomatch;
                debug(Regex) printf("\tREchar '%c', src = '%c'\n", program[pc + 1], input[src]);
                if (program[pc + 1] != input[src])
                    goto Lnomatch;
                src++;
                pc += 1 + char.sizeof;
                break;

            case REichar:
                if (src == input.length)
                    goto Lnomatch;
                debug(Regex) printf("\tREichar '%c', src = '%c'\n", program[pc + 1], input[src]);
                c1 = program[pc + 1];
                c2 = input[src];
                if (c1 != c2)
                {
                    if (islower(cast(rchar)c2))
                        c2 = toupper(cast(rchar)c2);
                    else
                        goto Lnomatch;
                    if (c1 != c2)
                        goto Lnomatch;
                }
                src++;
                pc += 1 + char.sizeof;
                break;

            case REdchar:
                debug(Regex) printf("\tREdchar '%c', src = '%c'\n", *(cast(dchar *)&program[pc + 1]), input[src]);
                if (src == input.length)
                    goto Lnomatch;
                if (*(cast(dchar *)&program[pc + 1]) != input[src])
                    goto Lnomatch;
                src++;
                pc += 1 + dchar.sizeof;
                break;

            case REidchar:
                debug(Regex) printf("\tREidchar '%c', src = '%c'\n", *(cast(dchar *)&program[pc + 1]), input[src]);
                if (src == input.length)
                    goto Lnomatch;
                c1 = *(cast(dchar *)&program[pc + 1]);
                c2 = input[src];
                if (c1 != c2)
                {
                    if (islower(cast(rchar)c2))
                        c2 = toupper(cast(rchar)c2);
                    else
                        goto Lnomatch;
                    if (c1 != c2)
                        goto Lnomatch;
                }
                src++;
                pc += 1 + dchar.sizeof;
                break;

            case REanychar:
                debug(Regex) printf("\tREanychar\n");
                if (src == input.length)
                    goto Lnomatch;
                if (!(attributes & REA.dotmatchlf) && input[src] == cast(rchar)'\n')
                    goto Lnomatch;
                src++;
                pc++;
                break;

            case REstring:
                len = *cast(uint *)&program[pc + 1];
                debug(Regex)
                {
                    char[] s = (&program[pc + 1 + uint.sizeof])[0 .. len];
                    printf("\tREstring x%x, '%.*s'\n", len,
                        cast(int) s.length, s.ptr);
                }
                if (src + len > input.length)
                    goto Lnomatch;
                if (memcmp(&program[pc + 1 + uint.sizeof], &input[src], len * rchar.sizeof))
                    goto Lnomatch;
                src += len;
                pc += 1 + uint.sizeof + len * rchar.sizeof;
                break;

            case REistring:
                len = *cast(uint *)&program[pc + 1];
                debug(Regex)
                {
                    char[] s = (&program[pc + 1 + uint.sizeof])[0 .. len];
                    printf("\tREistring x%x, '%.*s'\n", len,
                        cast(int) s.length, s.ptr);
                }
                if (src + len > input.length)
                    goto Lnomatch;
                version (Win32)
                {
                    if (memicmp(cast(char*)&program[pc + 1 + uint.sizeof], &input[src], len * rchar.sizeof))
                        goto Lnomatch;
                }
                else
                {
                    if (icmp((cast(char*)&program[pc + 1 + uint.sizeof])[0..len],
                             input[src .. src + len]))
                        goto Lnomatch;
                }
                src += len;
                pc += 1 + uint.sizeof + len * rchar.sizeof;
                break;

            case REtestbit:
                pu = (cast(ushort *)&program[pc + 1]);
                debug(Regex) printf("\tREtestbit %d, %d, '%c', x%02x\n",
                    pu[0], pu[1], input[src], input[src]);
                if (src == input.length)
                    goto Lnomatch;
                len = pu[1];
                c1 = input[src];
                //printf("[x%02x]=x%02x, x%02x\n", c1 >> 3, ((&program[pc + 1 + 4])[c1 >> 3] ), (1 << (c1 & 7)));
                if (c1 <= pu[0] &&
                    !((&(program[pc + 1 + 4]))[c1 >> 3] & (1 << (c1 & 7))))
                    goto Lnomatch;
                pc += 1 + 2 * ushort.sizeof + len;
                break;

            case REbit:
                pu = (cast(ushort *)&program[pc + 1]);
                debug(Regex) printf("\tREbit %d, %d, '%c'\n",
                    pu[0], pu[1], input[src]);
                if (src == input.length)
                    goto Lnomatch;
                len = pu[1];
                c1 = input[src];
                if (c1 > pu[0])
                    goto Lnomatch;
                if (!((&program[pc + 1 + 4])[c1 >> 3] & (1 << (c1 & 7))))
                    goto Lnomatch;
                src++;
                pc += 1 + 2 * ushort.sizeof + len;
                break;

            case REnotbit:
                pu = (cast(ushort *)&program[pc + 1]);
                debug(Regex) printf("\tREnotbit %d, %d, '%c'\n",
                    pu[0], pu[1], input[src]);
                if (src == input.length)
                    goto Lnomatch;
                len = pu[1];
                c1 = input[src];
                if (c1 <= pu[0] &&
                    ((&program[pc + 1 + 4])[c1 >> 3] & (1 << (c1 & 7))))
                    goto Lnomatch;
                src++;
                pc += 1 + 2 * ushort.sizeof + len;
                break;

            case RErange:
                len = *cast(uint *)&program[pc + 1];
                debug(Regex) printf("\tRErange %d\n", len);
                if (src == input.length)
                    goto Lnomatch;
                // BUG: REA.ignoreCase?
                if (memchr(cast(char*)&program[pc + 1 + uint.sizeof], input[src], len) == null)
                    goto Lnomatch;
                src++;
                pc += 1 + uint.sizeof + len;
                break;

            case REnotrange:
                len = *cast(uint *)&program[pc + 1];
                debug(Regex) printf("\tREnotrange %d\n", len);
                if (src == input.length)
                    goto Lnomatch;
                // BUG: REA.ignoreCase?
                if (memchr(cast(char*)&program[pc + 1 + uint.sizeof], input[src], len) != null)
                    goto Lnomatch;
                src++;
                pc += 1 + uint.sizeof + len;
                break;

            case REbol:
                debug(Regex) printf("\tREbol\n");
                if (src == 0)
                {
                }
                else if (attributes & REA.multiline)
                {
                    if (input[src - 1] != '\n')
                        goto Lnomatch;
                }
                else
                    goto Lnomatch;
                pc++;
                break;

            case REeol:
                debug(Regex) printf("\tREeol\n");
                if (src == input.length)
                {
                }
                else if (attributes & REA.multiline && input[src] == '\n')
                    src++;
                else
                    goto Lnomatch;
                pc++;
                break;

            case REor:
                len = (cast(uint *)&program[pc + 1])[0];
                debug(Regex) printf("\tREor %d\n", len);
                pop = pc + 1 + uint.sizeof;
                ss = src;
                if (trymatch(pop, pcend))
                {
                    if (pcend != program.length)
                    {   int s;

                        s = src;
                        if (trymatch(pcend, program.length))
                        {   debug(Regex) printf("\tfirst operand matched\n");
                            src = s;
                            return 1;
                        }
                        else
                        {
                            // If second branch doesn't match to end, take first anyway
                            src = ss;
                            if (!trymatch(pop + len, program.length))
                            {
                                debug(Regex) printf("\tfirst operand matched\n");
                                src = s;
                                return 1;
                            }
                        }
                        src = ss;
                    }
                    else
                    {   debug(Regex) printf("\tfirst operand matched\n");
                        return 1;
                    }
                }
                pc = pop + len;         // proceed with 2nd branch
                break;

            case REgoto:
                debug(Regex) printf("\tREgoto\n");
                len = (cast(uint *)&program[pc + 1])[0];
                pc += 1 + uint.sizeof + len;
                break;

            case REanystar:
                debug(Regex) printf("\tREanystar\n");
                pc++;
                for (;;)
                {   int s1;
                    int s2;

                    s1 = src;
                    if (src == input.length)
                        break;
                    if (!(attributes & REA.dotmatchlf) && input[src] == '\n')
                        break;
                    src++;
                    s2 = src;

                    // If no match after consumption, but it
                    // did match before, then no match
                    if (!trymatch(pc, program.length))
                    {
                        src = s1;
                        // BUG: should we save/restore pmatch[]?
                        if (trymatch(pc, program.length))
                        {
                            src = s1;           // no match
                            break;
                        }
                    }
                    src = s2;
                }
                break;

            case REnm:
            case REnmq:
                // len, n, m, ()
                puint = cast(uint *)&program[pc + 1];
                len = puint[0];
                n = puint[1];
                m = puint[2];
                debug(Regex) printf("\tREnm%s len=%d, n=%u, m=%u\n", (program[pc] == REnmq) ? cast(char*)"q" : cast(char*)"", len, n, m);
                pop = pc + 1 + uint.sizeof * 3;
                for (count = 0; count < n; count++)
                {
                    if (!trymatch(pop, pop + len))
                        goto Lnomatch;
                }
                if (!psave && count < m)
                {
                    //version (Win32)
                        psave = cast(regmatch_t *)alloca((re_nsub + 1) * regmatch_t.sizeof);
                    //else
                        //psave = new regmatch_t[re_nsub + 1];
                }
                if (program[pc] == REnmq)       // if minimal munch
                {
                    for (; count < m; count++)
                    {   int s1;

                        memcpy(psave, pmatch.ptr, (re_nsub + 1) * regmatch_t.sizeof);
                        s1 = src;

                        if (trymatch(pop + len, program.length))
                        {
                            src = s1;
                            memcpy(pmatch.ptr, psave, (re_nsub + 1) * regmatch_t.sizeof);
                            break;
                        }

                        if (!trymatch(pop, pop + len))
                        {   debug(Regex) printf("\tdoesn't match subexpression\n");
                            break;
                        }

                        // If source is not consumed, don't
                        // infinite loop on the match
                        if (s1 == src)
                        {   debug(Regex) printf("\tsource is not consumed\n");
                            break;
                        }
                    }
                }
                else    // maximal munch
                {
                    for (; count < m; count++)
                    {   int s1;
                        int s2;

                        memcpy(psave, pmatch.ptr, (re_nsub + 1) * regmatch_t.sizeof);
                        s1 = src;
                        if (!trymatch(pop, pop + len))
                        {   debug(Regex) printf("\tdoesn't match subexpression\n");
                            break;
                        }
                        s2 = src;

                        // If source is not consumed, don't
                        // infinite loop on the match
                        if (s1 == s2)
                        {   debug(Regex) printf("\tsource is not consumed\n");
                            break;
                        }

                        // If no match after consumption, but it
                        // did match before, then no match
                        if (!trymatch(pop + len, program.length))
                        {
                            src = s1;
                            if (trymatch(pop + len, program.length))
                            {
                                src = s1;               // no match
                                memcpy(pmatch.ptr, psave, (re_nsub + 1) * regmatch_t.sizeof);
                                break;
                            }
                        }
                        src = s2;
                    }
                }
                debug(Regex) printf("\tREnm len=%d, n=%u, m=%u, DONE count=%d\n", len, n, m, count);
                pc = pop + len;
                break;

            case REparen:
                // len, ()
                debug(Regex) printf("\tREparen\n");
                puint = cast(uint *)&program[pc + 1];
                len = puint[0];
                n = puint[1];
                pop = pc + 1 + uint.sizeof * 2;
                ss = src;
                if (!trymatch(pop, pop + len))
                    goto Lnomatch;
                pmatch[n + 1].rm_so = ss;
                pmatch[n + 1].rm_eo = src;
                pc = pop + len;
                break;

            case REend:
                debug(Regex) printf("\tREend\n");
                return 1;               // successful match

            case REwordboundary:
                debug(Regex) printf("\tREwordboundary\n");
                if (src > 0 && src < input.length)
                {
                    c1 = input[src - 1];
                    c2 = input[src];
                    if (!(
                          (isword(cast(rchar)c1) && !isword(cast(rchar)c2)) ||
                          (!isword(cast(rchar)c1) && isword(cast(rchar)c2))
                         )
                       )
                        goto Lnomatch;
                }
                pc++;
                break;

            case REnotwordboundary:
                debug(Regex) printf("\tREnotwordboundary\n");
                if (src == 0 || src == input.length)
                    goto Lnomatch;
                c1 = input[src - 1];
                c2 = input[src];
                if (
                    (isword(cast(rchar)c1) && !isword(cast(rchar)c2)) ||
                    (!isword(cast(rchar)c1) && isword(cast(rchar)c2))
                   )
                    goto Lnomatch;
                pc++;
                break;

            case REdigit:
                debug(Regex) printf("\tREdigit\n");
                if (src == input.length)
                    goto Lnomatch;
                if (!isdigit(input[src]))
                    goto Lnomatch;
                src++;
                pc++;
                break;

            case REnotdigit:
                debug(Regex) printf("\tREnotdigit\n");
                if (src == input.length)
                    goto Lnomatch;
                if (isdigit(input[src]))
                    goto Lnomatch;
                src++;
                pc++;
                break;

            case REspace:
                debug(Regex) printf("\tREspace\n");
                if (src == input.length)
                    goto Lnomatch;
                if (!isspace(input[src]))
                    goto Lnomatch;
                src++;
                pc++;
                break;

            case REnotspace:
                debug(Regex) printf("\tREnotspace\n");
                if (src == input.length)
                    goto Lnomatch;
                if (isspace(input[src]))
                    goto Lnomatch;
                src++;
                pc++;
                break;

            case REword:
                debug(Regex) printf("\tREword\n");
                if (src == input.length)
                    goto Lnomatch;
                if (!isword(input[src]))
                    goto Lnomatch;
                src++;
                pc++;
                break;

            case REnotword:
                debug(Regex) printf("\tREnotword\n");
                if (src == input.length)
                    goto Lnomatch;
                if (isword(input[src]))
                    goto Lnomatch;
                src++;
                pc++;
                break;

            case REbackref:
            {
                n = program[pc + 1];
                debug(Regex) printf("\tREbackref %d\n", n);

                int so = pmatch[n + 1].rm_so;
                int eo = pmatch[n + 1].rm_eo;
                len = eo - so;
                if (src + len > input.length)
                    goto Lnomatch;
                else if (attributes & REA.ignoreCase)
                {
                    if (icmp(input[src .. src + len], input[so .. eo]))
                        goto Lnomatch;
                }
                else if (memcmp(&input[src], &input[so], len * rchar.sizeof))
                    goto Lnomatch;
                src += len;
                pc += 2;
                break;
            }

            default:
                assert(0);
        }
    }

Lnomatch:
    debug(Regex) printf("\tnomatch pc=%d\n", pc);
    src = srcsave;
    return 0;
}

/* =================== Compiler ================== */

int parseRegexp()
{   uint offset;
    uint gotooffset;
    uint len1;
    uint len2;

    //printf("parseRegexp() '%.*s'\n", pattern[p .. pattern.length]);
    offset = buf.offset;
    for (;;)
    {
        assert(p <= pattern.length);
        if (p == pattern.length)
        {   buf.write(REend);
            return 1;
        }
        switch (pattern[p])
        {
            case ')':
                return 1;

            case '|':
                p++;
                gotooffset = buf.offset;
                buf.write(REgoto);
                buf.write(cast(uint)0);
                len1 = buf.offset - offset;
                buf.spread(offset, 1 + uint.sizeof);
                gotooffset += 1 + uint.sizeof;
                parseRegexp();
                len2 = buf.offset - (gotooffset + 1 + uint.sizeof);
                buf.data[offset] = REor;
                (cast(uint *)&buf.data[offset + 1])[0] = len1;
                (cast(uint *)&buf.data[gotooffset + 1])[0] = len2;
                break;

            default:
                parsePiece();
                break;
        }
    }
    assert(0);
}

int parsePiece()
{   uint offset;
    uint len;
    uint n;
    uint m;
    ubyte op;
    int plength = pattern.length;

    //printf("parsePiece() '%.*s'\n", pattern[p .. pattern.length]);
    offset = buf.offset;
    parseAtom();
    if (p == plength)
        return 1;
    switch (pattern[p])
    {
        case '*':
            // Special optimization: replace .* with REanystar
            if (buf.offset - offset == 1 &&
                buf.data[offset] == REanychar &&
                p + 1 < plength &&
                pattern[p + 1] != '?')
            {
                buf.data[offset] = REanystar;
                p++;
                break;
            }

            n = 0;
            m = inf;
            goto Lnm;

        case '+':
            n = 1;
            m = inf;
            goto Lnm;

        case '?':
            n = 0;
            m = 1;
            goto Lnm;

        case '{':       // {n} {n,} {n,m}
            p++;
            if (p == plength || !isdigit(pattern[p]))
                goto Lerr;
            n = 0;
            do
            {
                // BUG: handle overflow
                n = n * 10 + pattern[p] - '0';
                p++;
                if (p == plength)
                    goto Lerr;
            } while (isdigit(pattern[p]));
            if (pattern[p] == '}')              // {n}
            {   m = n;
                goto Lnm;
            }
            if (pattern[p] != ',')
                goto Lerr;
            p++;
            if (p == plength)
                goto Lerr;
            if (pattern[p] == /*{*/ '}')        // {n,}
            {   m = inf;
                goto Lnm;
            }
            if (!isdigit(pattern[p]))
                goto Lerr;
            m = 0;                      // {n,m}
            do
            {
                // BUG: handle overflow
                m = m * 10 + pattern[p] - '0';
                p++;
                if (p == plength)
                    goto Lerr;
            } while (isdigit(pattern[p]));
            if (pattern[p] != /*{*/ '}')
                goto Lerr;
            goto Lnm;

        Lnm:
            p++;
            op = REnm;
            if (p < plength && pattern[p] == '?')
            {   op = REnmq;     // minimal munch version
                p++;
            }
            len = buf.offset - offset;
            buf.spread(offset, 1 + uint.sizeof * 3);
            buf.data[offset] = op;
            uint* puint = cast(uint *)&buf.data[offset + 1];
            puint[0] = len;
            puint[1] = n;
            puint[2] = m;
            break;

        default:
            break;
    }
    return 1;

Lerr:
    error("badly formed {n,m}");
    assert(0);
}

int parseAtom()
{   ubyte op;
    uint offset;
    rchar c;

    //printf("parseAtom() '%.*s'\n", pattern[p .. pattern.length]);
    if (p < pattern.length)
    {
        c = pattern[p];
        switch (c)
        {
            case '*':
            case '+':
            case '?':
                error("*+? not allowed in atom");
                p++;
                return 0;

            case '(':
                p++;
                buf.write(REparen);
                offset = buf.offset;
                buf.write(cast(uint)0);         // reserve space for length
                buf.write(re_nsub);
                re_nsub++;
                parseRegexp();
                *cast(uint *)&buf.data[offset] =
                    buf.offset - (offset + uint.sizeof * 2);
                if (p == pattern.length || pattern[p] != ')')
                {
                    error("')' expected");
                    return 0;
                }
                p++;
                break;

            case '[':
                if (!parseRange())
                    return 0;
                break;

            case '.':
                p++;
                buf.write(REanychar);
                break;

            case '^':
                p++;
                buf.write(REbol);
                break;

            case '$':
                p++;
                buf.write(REeol);
                break;

            case '\\':
                p++;
                if (p == pattern.length)
                {   error("no character past '\\'");
                    return 0;
                }
                c = pattern[p];
                switch (c)
                {
                    case 'b':    op = REwordboundary;    goto Lop;
                    case 'B':    op = REnotwordboundary; goto Lop;
                    case 'd':    op = REdigit;           goto Lop;
                    case 'D':    op = REnotdigit;        goto Lop;
                    case 's':    op = REspace;           goto Lop;
                    case 'S':    op = REnotspace;        goto Lop;
                    case 'w':    op = REword;            goto Lop;
                    case 'W':    op = REnotword;         goto Lop;

                    Lop:
                        buf.write(op);
                        p++;
                        break;

                    case 'f':
                    case 'n':
                    case 'r':
                    case 't':
                    case 'v':
                    case 'c':
                    case 'x':
                    case 'u':
                    case '0':
                        c = cast(char)escape();
                        goto Lbyte;

                    case '1': case '2': case '3':
                    case '4': case '5': case '6':
                    case '7': case '8': case '9':
                        c -= '1';
                        if (c < re_nsub)
                        {   buf.write(REbackref);
                            buf.write(cast(ubyte)c);
                        }
                        else
                        {   error("no matching back reference");
                            return 0;
                        }
                        p++;
                        break;

                    default:
                        p++;
                        goto Lbyte;
                }
                break;

            default:
                p++;
            Lbyte:
                op = REchar;
                if (attributes & REA.ignoreCase)
                {
                    if (isalpha(c))
                    {
                        op = REichar;
                        c = cast(char)toupper(c);
                    }
                }
                if (op == REchar && c <= 0xFF)
                {
                    // Look ahead and see if we can make this into
                    // an REstring
                    int q;
                    int len;

                    for (q = p; q < pattern.length; ++q)
                    {   rchar qc = pattern[q];

                        switch (qc)
                        {
                            case '{':
                            case '*':
                            case '+':
                            case '?':
                                if (q == p)
                                    goto Lchar;
                                q--;
                                break;

                            case '(':   case ')':
                            case '|':
                            case '[':   case ']':
                            case '.':   case '^':
                            case '$':   case '\\':
                            case '}':
                                break;

                            default:
                                continue;
                        }
                        break;
                    }
                    len = q - p;
                    if (len > 0)
                    {
                        debug(Regex) printf("writing string len %d, c = '%c', pattern[p] = '%c'\n", len+1, c, pattern[p]);
                        buf.reserve(5 + (1 + len) * rchar.sizeof);
                        buf.write((attributes & REA.ignoreCase) ? REistring : REstring);
                        buf.write(len + 1);
                        buf.write(c);
                        buf.write(pattern[p .. p + len]);
                        p = q;
                        break;
                    }
                }
                if (c >= 0x80)
                {
                    // Convert to dchar opcode
                    op = (op == REchar) ? REdchar : REidchar;
                    buf.write(op);
                    buf.write(c);
                }
                else
                {
                 Lchar:
                    debug(Regex) printf("It's an REchar '%c'\n", c);
                    buf.write(op);
                    buf.write(cast(char)c);
                }
                break;
        }
    }
    return 1;
}

private:
class Range
{
    uint maxc;
    uint maxb;
    OutBuffer buf;
    ubyte* base;
    BitArray bits;

    this(OutBuffer buf)
    {
        this.buf = buf;
        if (buf.data.length)
            this.base = &buf.data[buf.offset];
    }

    void setbitmax(uint u)
    {   uint b;

        //printf("setbitmax(x%x), maxc = x%x\n", u, maxc);
        if (u > maxc)
        {
            maxc = u;
            b = u / 8;
            if (b >= maxb)
            {   uint u2;

                u2 = base ? base - &buf.data[0] : 0;
                buf.fill0(b - maxb + 1);
                base = &buf.data[u2];
                maxb = b + 1;
                //bits = (cast(bit*)this.base)[0 .. maxc + 1];
                bits.ptr = cast(uint*)this.base;
            }
            bits.len = maxc + 1;
        }
    }

    void setbit2(uint u)
    {
        setbitmax(u + 1);
        //printf("setbit2 [x%02x] |= x%02x\n", u >> 3, 1 << (u & 7));
        bits[u] = 1;
    }

}

int parseRange()
{   ubyte op;
    int c;
    int c2;
    uint i;
    uint cmax;
    uint offset;

    cmax = 0x7F;
    p++;
    op = REbit;
    if (p == pattern.length)
        goto Lerr;
    if (pattern[p] == '^')
    {   p++;
        op = REnotbit;
        if (p == pattern.length)
            goto Lerr;
    }
    buf.write(op);
    offset = buf.offset;
    buf.write(cast(uint)0);             // reserve space for length
    buf.reserve(128 / 8);
    auto r = new Range(buf);
    if (op == REnotbit)
        r.setbit2(0);
    switch (pattern[p])
    {
        case ']':
        case '-':
            c = pattern[p];
            p++;
            r.setbit2(c);
            break;

        default:
            break;
    }

    enum RS { start, rliteral, dash };
    RS rs;

    rs = RS.start;
    for (;;)
    {
        if (p == pattern.length)
            goto Lerr;
        switch (pattern[p])
        {
            case ']':
                switch (rs)
                {   case RS.dash:
                        r.setbit2('-');
                    case RS.rliteral:
                        r.setbit2(c);
                        break;
                    case RS.start:
                        break;
                    default:
                        assert(0);
                }
                p++;
                break;

            case '\\':
                p++;
                r.setbitmax(cmax);
                if (p == pattern.length)
                    goto Lerr;
                switch (pattern[p])
                {
                    case 'd':
                        for (i = '0'; i <= '9'; i++)
                            r.bits[i] = 1;
                        goto Lrs;

                    case 'D':
                        for (i = 1; i < '0'; i++)
                            r.bits[i] = 1;
                        for (i = '9' + 1; i <= cmax; i++)
                            r.bits[i] = 1;
                        goto Lrs;

                    case 's':
                        for (i = 0; i <= cmax; i++)
                            if (isspace(i))
                                r.bits[i] = 1;
                        goto Lrs;

                    case 'S':
                        for (i = 1; i <= cmax; i++)
                            if (!isspace(i))
                                r.bits[i] = 1;
                        goto Lrs;

                    case 'w':
                        for (i = 0; i <= cmax; i++)
                            if (isword(cast(rchar)i))
                                r.bits[i] = 1;
                        goto Lrs;

                    case 'W':
                        for (i = 1; i <= cmax; i++)
                            if (!isword(cast(rchar)i))
                                r.bits[i] = 1;
                        goto Lrs;

                    Lrs:
                        switch (rs)
                        {   case RS.dash:
                                r.setbit2('-');
                            case RS.rliteral:
                                r.setbit2(c);
                                break;
                            default:
                                break;
                        }
                        rs = RS.start;
                        continue;

                    default:
                        break;
                }
                c2 = escape();
                goto Lrange;

            case '-':
                p++;
                if (rs == RS.start)
                    goto Lrange;
                else if (rs == RS.rliteral)
                    rs = RS.dash;
                else if (rs == RS.dash)
                {
                    r.setbit2(c);
                    r.setbit2('-');
                    rs = RS.start;
                }
                continue;

            default:
                c2 = pattern[p];
                p++;
            Lrange:
                switch (rs)
                {   case RS.rliteral:
                        r.setbit2(c);
                    case RS.start:
                        c = c2;
                        rs = RS.rliteral;
                        break;

                    case RS.dash:
                        if (c > c2)
                        {   error("inverted range in character class");
                            return 0;
                        }
                        r.setbitmax(c2);
                        //printf("c = %x, c2 = %x\n",c,c2);
                        for (; c <= c2; c++)
                            r.bits[c] = 1;
                        rs = RS.start;
                        break;

                    default:
                        assert(0);
                }
                continue;
        }
        break;
    }
    if (attributes & REA.ignoreCase)
    {
        // BUG: what about dchar?
        r.setbitmax(0x7F);
        for (c = 'a'; c <= 'z'; c++)
        {
            if (r.bits[c])
                r.bits[c + 'A' - 'a'] = 1;
            else if (r.bits[c + 'A' - 'a'])
                r.bits[c] = 1;
        }
    }
    //printf("maxc = %d, maxb = %d\n",r.maxc,r.maxb);
    (cast(ushort *)&buf.data[offset])[0] = cast(ushort)r.maxc;
    (cast(ushort *)&buf.data[offset])[1] = cast(ushort)r.maxb;
    return 1;

Lerr:
    error("invalid range");
    return 0;
}

void error(char[] msg)
{
    errors++;
    debug(Regex) printf("error: %.*s\n", cast(int) msg.length, msg.ptr);
//assert(0);
//*(char*)0=0;
    throw new RegexException(msg);
}

// p is following the \ char
int escape()
in
{
    assert(p < pattern.length);
}
body
{   int c;
    int i;
    rchar tc;

    c = pattern[p];             // none of the cases are multibyte
    switch (c)
    {
        case 'b':    c = '\b';  break;
        case 'f':    c = '\f';  break;
        case 'n':    c = '\n';  break;
        case 'r':    c = '\r';  break;
        case 't':    c = '\t';  break;
        case 'v':    c = '\v';  break;

        // BUG: Perl does \a and \e too, should we?

        case 'c':
            ++p;
            if (p == pattern.length)
                goto Lretc;
            c = pattern[p];
            // Note: we are deliberately not allowing dchar letters
            if (!(('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z')))
            {
             Lcerr:
                error("letter expected following \\c");
                return 0;
            }
            c &= 0x1F;
            break;

        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
            c -= '0';
            for (i = 0; i < 2; i++)
            {
                p++;
                if (p == pattern.length)
                    goto Lretc;
                tc = pattern[p];
                if ('0' <= tc && tc <= '7')
                {   c = c * 8 + (tc - '0');
                    // Treat overflow as if last
                    // digit was not an octal digit
                    if (c >= 0xFF)
                    {   c >>= 3;
                        return c;
                    }
                }
                else
                    return c;
            }
            break;

        case 'x':
            c = 0;
            for (i = 0; i < 2; i++)
            {
                p++;
                if (p == pattern.length)
                    goto Lretc;
                tc = pattern[p];
                if ('0' <= tc && tc <= '9')
                    c = c * 16 + (tc - '0');
                else if ('a' <= tc && tc <= 'f')
                    c = c * 16 + (tc - 'a' + 10);
                else if ('A' <= tc && tc <= 'F')
                    c = c * 16 + (tc - 'A' + 10);
                else if (i == 0)        // if no hex digits after \x
                {
                    // Not a valid \xXX sequence
                    return 'x';
                }
                else
                    return c;
            }
            break;

        case 'u':
            c = 0;
            for (i = 0; i < 4; i++)
            {
                p++;
                if (p == pattern.length)
                    goto Lretc;
                tc = pattern[p];
                if ('0' <= tc && tc <= '9')
                    c = c * 16 + (tc - '0');
                else if ('a' <= tc && tc <= 'f')
                    c = c * 16 + (tc - 'a' + 10);
                else if ('A' <= tc && tc <= 'F')
                    c = c * 16 + (tc - 'A' + 10);
                else
                {
                    // Not a valid \uXXXX sequence
                    p -= i;
                    return 'u';
                }
            }
            break;

        default:
            break;
    }
    p++;
Lretc:
    return c;
}

/* ==================== optimizer ======================= */

void optimize()
{   ubyte[] prog;

    debug(Regex) printf("Regex.optimize()\n");
    prog = buf.toBytes();
    for (size_t i = 0; 1;)
    {
        //printf("\tprog[%d] = %d, %d\n", i, prog[i], REstring);
        switch (prog[i])
        {
            case REend:
            case REanychar:
            case REanystar:
            case REbackref:
            case REeol:
            case REchar:
            case REichar:
            case REdchar:
            case REidchar:
            case REstring:
            case REistring:
            case REtestbit:
            case REbit:
            case REnotbit:
            case RErange:
            case REnotrange:
            case REwordboundary:
            case REnotwordboundary:
            case REdigit:
            case REnotdigit:
            case REspace:
            case REnotspace:
            case REword:
            case REnotword:
                return;

            case REbol:
                i++;
                continue;

            case REor:
            case REnm:
            case REnmq:
            case REparen:
            case REgoto:
            {
                auto bitbuf = new OutBuffer;
                auto r = new Range(bitbuf);
                uint offset;

                offset = i;
                if (starrchars(r, prog[i .. prog.length]))
                {
                    debug(Regex) printf("\tfilter built\n");
                    buf.spread(offset, 1 + 4 + r.maxb);
                    buf.data[offset] = REtestbit;
                    (cast(ushort *)&buf.data[offset + 1])[0] = cast(ushort)r.maxc;
                    (cast(ushort *)&buf.data[offset + 1])[1] = cast(ushort)r.maxb;
                    i = offset + 1 + 4;
                    buf.data[i .. i + r.maxb] = r.base[0 .. r.maxb];
                }
                return;
            }
            default:
                assert(0);
        }
    }
}

/////////////////////////////////////////
// OR the leading character bits into r.
// Limit the character range from 0..7F,
// trymatch() will allow through anything over maxc.
// Return 1 if success, 0 if we can't build a filter or
// if there is no point to one.

int starrchars(Range r, ubyte[] prog)
{   rchar c;
    uint maxc;
    uint maxb;
    uint len;
    uint b;
    uint n;
    uint m;
    ubyte* pop;

    //printf("Regex.starrchars(prog = %p, progend = %p)\n", prog, progend);
    for (size_t i = 0; i < prog.length;)
    {
        switch (prog[i])
        {
            case REchar:
                c = prog[i + 1];
                if (c <= 0x7F)
                    r.setbit2(c);
                return 1;

            case REichar:
                c = prog[i + 1];
                if (c <= 0x7F)
                {   r.setbit2(c);
                    r.setbit2(tolower(cast(rchar)c));
                }
                return 1;

            case REdchar:
            case REidchar:
                return 1;

            case REanychar:
                return 0;               // no point

            case REstring:
                len = *cast(uint *)&prog[i + 1];
                assert(len);
                c = *cast(rchar *)&prog[i + 1 + uint.sizeof];
                debug(Regex) printf("\tREstring %d, '%c'\n", len, c);
                if (c <= 0x7F)
                    r.setbit2(c);
                return 1;

            case REistring:
                len = *cast(uint *)&prog[i + 1];
                assert(len);
                c = *cast(rchar *)&prog[i + 1 + uint.sizeof];
                debug(Regex) printf("\tREistring %d, '%c'\n", len, c);
                if (c <= 0x7F)
                {   r.setbit2(toupper(cast(rchar)c));
                    r.setbit2(tolower(cast(rchar)c));
                }
                return 1;

            case REtestbit:
            case REbit:
                maxc = (cast(ushort *)&prog[i + 1])[0];
                maxb = (cast(ushort *)&prog[i + 1])[1];
                if (maxc <= 0x7F)
                    r.setbitmax(maxc);
                else
                    maxb = r.maxb;
                for (b = 0; b < maxb; b++)
                    r.base[b] |= prog[i + 1 + 4 + b];
                return 1;

            case REnotbit:
                maxc = (cast(ushort *)&prog[i + 1])[0];
                maxb = (cast(ushort *)&prog[i + 1])[1];
                if (maxc <= 0x7F)
                    r.setbitmax(maxc);
                else
                    maxb = r.maxb;
                for (b = 0; b < maxb; b++)
                    r.base[b] |= ~prog[i + 1 + 4 + b];
                return 1;

            case REbol:
            case REeol:
                return 0;

            case REor:
                len = (cast(uint *)&prog[i + 1])[0];
                return starrchars(r, prog[i + 1 + uint.sizeof .. prog.length]) &&
                       starrchars(r, prog[i + 1 + uint.sizeof + len .. prog.length]);

            case REgoto:
                len = (cast(uint *)&prog[i + 1])[0];
                i += 1 + uint.sizeof + len;
                break;

            case REanystar:
                return 0;

            case REnm:
            case REnmq:
                // len, n, m, ()
                len = (cast(uint *)&prog[i + 1])[0];
                n   = (cast(uint *)&prog[i + 1])[1];
                m   = (cast(uint *)&prog[i + 1])[2];
                pop = &prog[i + 1 + uint.sizeof * 3];
                if (!starrchars(r, pop[0 .. len]))
                    return 0;
                if (n)
                    return 1;
                i += 1 + uint.sizeof * 3 + len;
                break;

            case REparen:
                // len, ()
                len = (cast(uint *)&prog[i + 1])[0];
                n   = (cast(uint *)&prog[i + 1])[1];
                pop = &prog[0] + i + 1 + uint.sizeof * 2;
                return starrchars(r, pop[0 .. len]);

            case REend:
                return 0;

            case REwordboundary:
            case REnotwordboundary:
                return 0;

            case REdigit:
                r.setbitmax('9');
                for (c = '0'; c <= '9'; c++)
                    r.bits[c] = 1;
                return 1;

            case REnotdigit:
                r.setbitmax(0x7F);
                for (c = 0; c <= '0'; c++)
                    r.bits[c] = 1;
                for (c = '9' + 1; c <= r.maxc; c++)
                    r.bits[c] = 1;
                return 1;

            case REspace:
                r.setbitmax(0x7F);
                for (c = 0; c <= r.maxc; c++)
                    if (isspace(c))
                        r.bits[c] = 1;
                return 1;

            case REnotspace:
                r.setbitmax(0x7F);
                for (c = 0; c <= r.maxc; c++)
                    if (!isspace(c))
                        r.bits[c] = 1;
                return 1;

            case REword:
                r.setbitmax(0x7F);
                for (c = 0; c <= r.maxc; c++)
                    if (isword(cast(rchar)c))
                        r.bits[c] = 1;
                return 1;

            case REnotword:
                r.setbitmax(0x7F);
                for (c = 0; c <= r.maxc; c++)
                    if (!isword(cast(rchar)c))
                        r.bits[c] = 1;
                return 1;

            case REbackref:
                return 0;

            default:
                assert(0);
        }
    }
    return 1;
}

/* ==================== replace ======================= */

/***********************
 * After a match is found with test(), this function
 * will take the match results and, using the format
 * string, generate and return a new string.
 */

public rchar[] replace(rchar[] format)
{
    return replace3(format, input, pmatch[0 .. re_nsub + 1]);
}

// Static version that doesn't require a Regex object to be created

public static rchar[] replace3(rchar[] format, rchar[] input, regmatch_t[] pmatch)
{
    rchar[] result;
    uint c2;
    int rm_so;
    int rm_eo;
    int i;

//    printf("replace3(format = '%.*s', input = '%.*s')\n", format, input);
    result.length = format.length;
    result.length = 0;
    for (size_t f = 0; f < format.length; f++)
    {
        auto c = format[f];
      L1:
        if (c != '$')
        {
            result ~= c;
            continue;
        }
        ++f;
        if (f == format.length)
        {
            result ~= '$';
            break;
        }
        c = format[f];
        switch (c)
        {
            case '&':
                rm_so = pmatch[0].rm_so;
                rm_eo = pmatch[0].rm_eo;
                goto Lstring;

            case '`':
                rm_so = 0;
                rm_eo = pmatch[0].rm_so;
                goto Lstring;

            case '\'':
                rm_so = pmatch[0].rm_eo;
                rm_eo = input.length;
                goto Lstring;

            case '0': case '1': case '2': case '3': case '4':
            case '5': case '6': case '7': case '8': case '9':
                i = c - '0';
                if (f + 1 == format.length)
                {
                    if (i == 0)
                    {
                        result ~= '$';
                        result ~= c;
                        continue;
                    }
                }
                else
                {
                    c2 = format[f + 1];
                    if (c2 >= '0' && c2 <= '9')
                    {   i = (c - '0') * 10 + (c2 - '0');
                        f++;
                    }
                    if (i == 0)
                    {
                        result ~= '$';
                        result ~= c;
            c = cast(char)c2;
                        goto L1;
                    }
                }

                if (i < pmatch.length)
                {   rm_so = pmatch[i].rm_so;
                    rm_eo = pmatch[i].rm_eo;
                    goto Lstring;
                }
                break;

            Lstring:
                if (rm_so != rm_eo)
                    result ~= input[rm_so .. rm_eo];
                break;

            default:
                result ~= '$';
                result ~= c;
                break;
        }
    }
    return result;
}

/************************************
 * Like replace(char[] format), but uses old style formatting:
                <table border=1 cellspacing=0 cellpadding=5>
                <th>Format
                <th>Description
                <tr>
                <td><b>&</b>
                <td>replace with the match
                </tr>
                <tr>
                <td><b>\</b><i>n</i>
                <td>replace with the <i>n</i>th parenthesized match, <i>n</i> is 1..9
                </tr>
                <tr>
                <td><b>\</b><i>c</i>
                <td>replace with char <i>c</i>.
                </tr>
                </table>
 */

public rchar[] replaceOld(rchar[] format)
{
    rchar[] result;

//printf("replace: this = %p so = %d, eo = %d\n", this, pmatch[0].rm_so, pmatch[0].rm_eo);
//printf("3input = '%.*s'\n", input);
    result.length = format.length;
    result.length = 0;
    for (size_t i; i < format.length; i++)
    {
        auto c = format[i];
        switch (c)
        {
            case '&':
//printf("match = '%.*s'\n", input[pmatch[0].rm_so .. pmatch[0].rm_eo]);
                result ~= input[pmatch[0].rm_so .. pmatch[0].rm_eo];
                break;

            case '\\':
                if (i + 1 < format.length)
                {
                    c = format[++i];
                    if (c >= '1' && c <= '9')
                    {   uint j;

                        j = c - '0';
                        if (j <= re_nsub && pmatch[j].rm_so != pmatch[j].rm_eo)
                            result ~= input[pmatch[j].rm_so .. pmatch[j].rm_eo];
                        break;
                    }
                }
                result ~= c;
                break;

            default:
                result ~= c;
                break;
        }
    }
    return result;
}

}

debug( UnitTest )
{
    unittest
    {   // Created and placed in public domain by Don Clugston

        auto m = search("aBC r s", `bc\x20r[\40]s`, "i");
        assert(m.pre=="a");
        assert(m.match(0)=="BC r s");
        auto m2 = search("7xxyxxx", `^\d([a-z]{2})\D\1`);
        assert(m2.match(0)=="7xxyxx");
        // Just check the parsing.
        auto m3 = search("dcbxx", `ca|b[\d\]\D\s\S\w-\W]`);
        auto m4 = search("xy", `[^\ca-\xFa\r\n\b\f\t\v\0123]{2,485}$`);
        auto m5 = search("xxx", `^^\r\n\b{13,}\f{4}\t\v\u02aF3a\w\W`);
        auto m6 = search("xxy", `.*y`);
        assert(m6.match(0)=="xxy");
        auto m7 = search("QWDEfGH", "(ca|b|defg)+", "i");
        assert(m7.match(0)=="DEfG");
        auto m8 = search("dcbxx", `a?\B\s\S`);
        auto m9 = search("dcbxx", `[-w]`);
        auto m10 = search("dcbsfd", `aB[c-fW]dB|\d|\D|\u012356|\w|\W|\s|\S`, "i");
        auto m11 = search("dcbsfd", `[]a-]`);
        m.replaceOld(`a&b\1c`);
        m.replace(`a$&b$'$1c`);
    }
}

//
// NOTE: This code is being included temporarily until Regex can be modified
//       so as not to require it.
//
private
{
    import tango.core.Memory; // for OutBuffer
    extern (C) int memicmp(char *, char *, uint);


    /**********************************
     * Compare two strings. cmp is case sensitive, icmp is case insensitive.
     * Returns:
     *  <table border=1 cellpadding=4 cellspacing=0>
     *  <tr> <td> < 0   <td> s1 < s2
     *  <tr> <td> = 0   <td> s1 == s2
     *  <tr> <td> > 0   <td> s1 > s2
     *  </table>
     */
    int cmp(char[] s1, char[] s2)
    {
        size_t len = s1.length;
        int result;

        //printf("cmp('%.*s', '%.*s')\n", s1, s2);
        if (s2.length < len)
        len = s2.length;
        result = memcmp(s1.ptr, s2.ptr, len);
        if (result == 0)
        result = cast(int)s1.length - cast(int)s2.length;
        return result;
    }

    /*********************************
     * ditto
     */
    int icmp(char[] s1, char[] s2)
    {
        size_t len = s1.length;
        int result;

        if (s2.length < len)
        len = s2.length;
        version (Win32)
        {
        result = memicmp(s1.ptr, s2.ptr, len);
        }
        version (linux)
        {
        for (size_t i = 0; i < len; i++)
        {
            if (s1[i] != s2[i])
            {
                char c1 = s1[i];
                char c2 = s2[i];

                if (c1 >= 'A' && c1 <= 'Z')
                    c1 += cast(int)'a' - cast(int)'A';
                if (c2 >= 'A' && c2 <= 'Z')
                    c2 += cast(int)'a' - cast(int)'A';
                result = cast(int)c1 - cast(int)c2;
                if (result)
                    break;
            }
        }
        }
        if (result == 0)
        result = cast(int)s1.length - cast(int)s2.length;
        return result;
    }

  debug( UnitTest )
  {
    unittest
    {
        int result;

        debug(string) printf("string.cmp.unittest\n");
        result = cmp("abc", "abc");
        assert(result == 0);
        result = cmp(null, null);
        assert(result == 0);
        result = cmp("", "");
        assert(result == 0);
        result = cmp("abc", "abcd");
        assert(result < 0);
        result = cmp("abcd", "abc");
        assert(result > 0);
        result = cmp("abc", "abd");
        assert(result < 0);
        result = cmp("bbc", "abc");
        assert(result > 0);
    }
  }

    /*********************************
     * Convert array of chars s[] to a C-style 0 terminated string.
     */
    char* toStringz(char[] s)
        in
        {
        }
        out (result)
        {
        if (result)
        {   assert(strlen(result) == s.length);
            assert(memcmp(result, s.ptr, s.length) == 0);
        }
        }
        body
        {
        char[] copy;

        if (s.length == 0)
            return "";

        /+ Unfortunately, this isn't reliable.
           We could make this work if string literals are put
           in read-only memory and we test if s[] is pointing into
           that.

            /* Peek past end of s[], if it's 0, no conversion necessary.
             * Note that the compiler will put a 0 past the end of static
             * strings, and the storage allocator will put a 0 past the end
             * of newly allocated char[]'s.
             */
            char* p = &s[0] + s.length;
            if (*p == 0)
                return s;
        +/

        // Need to make a copy
        copy = new char[s.length + 1];
        copy[0..s.length] = s;
        copy[s.length] = 0;
        return copy.ptr;
        }

  debug( UnitTest )
  {
    unittest
    {
        debug(string) printf("string.toStringz.unittest\n");

        char* p = toStringz("foo");
        assert(strlen(p) == 3);
        char foo[] = "abbzxyzzy";
        p = toStringz(foo[3..5]);
        assert(strlen(p) == 2);

        char[] test = "";
        p = toStringz(test);
        assert(*p == 0);
    }
  }

    /*****************************
     * Return a _string that is string[] with slice[] replaced by replacement[].
     */
    char[] replaceSlice(char[] string, char[] slice, char[] replacement)
    in
    {
        // Verify that slice[] really is a slice of string[]
        int so = cast(char*)slice - cast(char*)string;
        assert(so >= 0);
        //printf("string.length = %d, so = %d, slice.length = %d\n", string.length, so, slice.length);
        assert(string.length >= so + slice.length);
    }
    body
    {
        char[] result;
        int so = cast(char*)slice - cast(char*)string;

        result.length = string.length - slice.length + replacement.length;

        result[0 .. so] = string[0 .. so];
        result[so .. so + replacement.length] = replacement;
        result[so + replacement.length .. result.length] = string[so + slice.length .. string.length];

        return result;
    }

  debug( UnitTest )
  {
    unittest
    {
        debug(string) printf("string.replaceSlice.unittest\n");

        char[] string = "hello";
        char[] slice = string[2 .. 4];

        char[] r = replaceSlice(string, slice, "bar");
        int i;
        i = cmp(r, "hebaro");
        assert(i == 0);
    }
  }

    // NOTE: join is used for unittests only!

    /********************************************
     * Concatenate all the strings in words[] together into one
     * string; use sep[] as the separator.
     */
    char[] join(char[][] words, char[] sep)
    {
        size_t len;
        uint seplen;
        uint i;
        uint j;
        char[] result;

        if (words.length)
        {
        len = 0;
        for (i = 0; i < words.length; i++)
            len += words[i].length;

        seplen = sep.length;
        len += (words.length - 1) * seplen;

        result = new char[len];

        i = 0;
        while (true)
        {
            uint wlen = words[i].length;

            result[j .. j + wlen] = words[i];
            j += wlen;
            i++;
            if (i >= words.length)
                break;
            result[j .. j + seplen] = sep;
            j += seplen;
        }
        assert(j == len);
        }
        return result;
    }

  debug( UnitTest )
  {
    unittest
    {
        debug(string) printf("string.join.unittest\n");

        char[] word1 = "peter";
        char[] word2 = "paul";
        char[] word3 = "jerry";
        char[][3] words;
        char[] r;
        int i;

        words[0] = word1;
        words[1] = word2;
        words[2] = word3;
        r = join(words, ",");
        i = cmp(r, "peter,paul,jerry");
        assert(i == 0);
    }
  }

    /*********************************************
     * OutBuffer provides a way to build up an array of bytes out
     * of raw data. It is useful for things like preparing an
     * array of bytes to write out to a file.
     * OutBuffer's byte order is the format native to the computer.
     * To control the byte order (endianness), use a class derived
     * from OutBuffer.
     */

    class OutBuffer
    {
        ubyte data[];
        uint offset;

        invariant
        {
        //printf("this = %p, offset = %x, data.length = %u\n", this, offset, data.length);
        assert(offset <= data.length);
        }

        this()
        {
        //printf("in OutBuffer constructor\n");
        }

        /*********************************
         * Convert to array of bytes.
         */

        ubyte[] toBytes() { return data[0 .. offset]; }

        /***********************************
         * Preallocate nbytes more to the size of the internal buffer.
         *
         * This is a
         * speed optimization, a good guess at the maximum size of the resulting
         * buffer will improve performance by eliminating reallocations and copying.
         */


        void reserve(uint nbytes)
        in
        {
            assert(offset + nbytes >= offset);
        }
        out
        {
            assert(offset + nbytes <= data.length);
            assert(data.length <= GC.sizeOf(data.ptr));
        }
        body
        {
            //c.stdio.printf("OutBuffer.reserve: length = %d, offset = %d, nbytes = %d\n", data.length, offset, nbytes);
            if (data.length < offset + nbytes)
            {
                data.length = (offset + nbytes) * 2;
                GC.clrAttr(data.ptr, GC.BlkAttr.NO_SCAN);
            }
        }

        /*************************************
         * Append data to the internal buffer.
         */

        void write(ubyte[] bytes)
        {
            reserve(bytes.length);
            data[offset .. offset + bytes.length] = bytes;
            offset += bytes.length;
        }

        void write(ubyte b)             /// ditto
        {
            reserve(ubyte.sizeof);
            this.data[offset] = b;
            offset += ubyte.sizeof;
        }

        void write(byte b) { write(cast(ubyte)b); }             /// ditto
        void write(char c) { write(cast(ubyte)c); }             /// ditto

        void write(ushort w)            /// ditto
        {
        reserve(ushort.sizeof);
        *cast(ushort *)&data[offset] = w;
        offset += ushort.sizeof;
        }

        void write(short s) { write(cast(ushort)s); }           /// ditto

        void write(wchar c)             /// ditto
        {
        reserve(wchar.sizeof);
        *cast(wchar *)&data[offset] = c;
        offset += wchar.sizeof;
        }

        void write(uint w)              /// ditto
        {
        reserve(uint.sizeof);
        *cast(uint *)&data[offset] = w;
        offset += uint.sizeof;
        }

        void write(int i) { write(cast(uint)i); }               /// ditto

        void write(ulong l)             /// ditto
        {
        reserve(ulong.sizeof);
        *cast(ulong *)&data[offset] = l;
        offset += ulong.sizeof;
        }

        void write(long l) { write(cast(ulong)l); }             /// ditto

        void write(float f)             /// ditto
        {
        reserve(float.sizeof);
        *cast(float *)&data[offset] = f;
        offset += float.sizeof;
        }

        void write(double f)            /// ditto
        {
        reserve(double.sizeof);
        *cast(double *)&data[offset] = f;
        offset += double.sizeof;
        }

        void write(real f)              /// ditto
        {
        reserve(real.sizeof);
        *cast(real *)&data[offset] = f;
        offset += real.sizeof;
        }

        void write(char[] s)            /// ditto
        {
        write(cast(ubyte[])s);
        }

        void write(OutBuffer buf)               /// ditto
        {
        write(buf.toBytes());
        }

        /****************************************
         * Append nbytes of 0 to the internal buffer.
         */

        void fill0(uint nbytes)
        {
        reserve(nbytes);
        data[offset .. offset + nbytes] = 0;
        offset += nbytes;
        }

        /**********************************
         * 0-fill to align on power of 2 boundary.
         */

        void alignSize(uint alignsize)
        in
        {
        assert(alignsize && (alignsize & (alignsize - 1)) == 0);
        }
        out
        {
        assert((offset & (alignsize - 1)) == 0);
        }
        body
        {   uint nbytes;

        nbytes = offset & (alignsize - 1);
        if (nbytes)
            fill0(alignsize - nbytes);
        }

        /****************************************
         * Optimize common special case alignSize(2)
         */

        void align2()
        {
        if (offset & 1)
            write(cast(byte)0);
        }

        /****************************************
         * Optimize common special case alignSize(4)
         */

        void align4()
        {
        if (offset & 3)
        {   uint nbytes = (4 - offset) & 3;
            fill0(nbytes);
        }
        }

        /**************************************
         * Convert internal buffer to array of chars.
         */

        char[] toString()
        {
        //printf("OutBuffer.toString()\n");
        return cast(char[])data[0 .. offset];
        }

        /*****************************************
         * Append output of C's vprintf() to internal buffer.
         */

        void vprintf(char[] format, va_list args)
        {
        char[128] buffer;
        char* p;
        char* f;
        uint psize;
        int count;

        f = toStringz(format);
        p = buffer.ptr;
        psize = buffer.length;
        for (;;)
        {
            version(Win32)
            {
                count = _vsnprintf(p,psize,f,args);
                if (count != -1)
                    break;
                psize *= 2;
                p = cast(char *) alloca(psize); // buffer too small, try again with larger size
            }
            version(linux)
            {
                count = vsnprintf(p,psize,f,args);
                if (count == -1)
                    psize *= 2;
                else if (count >= psize)
                    psize = count + 1;
                else
                    break;
                /+
                if (p != buffer)
                    c.stdlib.free(p);
                p = (char *) c.stdlib.malloc(psize);    // buffer too small, try again with larger size
                +/
                p = cast(char *) alloca(psize); // buffer too small, try again with larger size
            }
        }
        write(p[0 .. count]);
        /+
        version (linux)
        {
            if (p != buffer)
                c.stdlib.free(p);
        }
        +/
        }

        /*****************************************
         * Append output of C's printf() to internal buffer.
         */

        void printf(char[] format, ...)
        {
        va_list ap;
        ap = cast(va_list)&format;
        ap += format.sizeof;
        vprintf(format, ap);
        }

        /*****************************************
         * At offset index into buffer, create nbytes of space by shifting upwards
         * all data past index.
         */

        void spread(uint index, uint nbytes)
        in
        {
            assert(index <= offset);
        }
        body
        {
            reserve(nbytes);

            // This is an overlapping copy - should use memmove()
            for (uint i = offset; i > index; )
            {
                --i;
                data[i + nbytes] = data[i];
            }
            offset += nbytes;
        }
    }

  debug( UnitTest )
  {
    unittest
    {
        //printf("Starting OutBuffer test\n");

        OutBuffer buf = new OutBuffer();

        //printf("buf = %p\n", buf);
        //printf("buf.offset = %x\n", buf.offset);
        assert(buf.offset == 0);
        buf.write("hello");
        buf.write(cast(byte)0x20);
        buf.write("world");
        buf.printf(" %d", 6);
        //printf("buf = '%.*s'\n", buf.toString());
        assert(cmp(buf.toString(), "hello world 6") == 0);
    }
  }
}
