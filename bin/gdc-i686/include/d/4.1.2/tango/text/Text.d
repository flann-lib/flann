/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005

        author:         Kris


        _Text is a class for storing and manipulating Unicode characters.

        _Text maintains a current "selection", controlled via the mark(),
        select() and selectPrior() methods. Each of append(), prepend(),
        replace() and remove() operate with respect to the selection. The
        select() methods operate with respect to the current selection
        also, providing a means of iterating across matched patterns. To
        set a selection across the entire content, use the mark() method
        with no arguments.

        Indexes and lengths of content always count code units, not code
        points. This is similar to traditional ascii string handling, yet
        indexing is rarely used in practice due to the selection idiom:
        substring indexing is generally implied as opposed to manipulated
        directly. This allows for a more streamlined model with regard to
        surrogates.

        Strings support a range of functionality, from insert and removal
        to utf encoding and decoding. There is also an immutable subset
        called TextView, intended to simplify life in a multi-threaded
        environment. However, TextView must expose the raw content as
        needed and thus immutability depends to an extent upon so-called
        "honour" of a callee. D does not enable immutability enforcement
        at this time, but this class will be modified to support such a
        feature when it arrives - via the slice() method.

        The class is templated for use with char[], wchar[], and dchar[],
        and should migrate across encodings seamlessly. In particular, all
        functions in tango.text.Util are compatible with _Text content in
        any of the supported encodings. In future, this class will become
        the principal gateway to the extensive ICU unicode library.

        Note that several common text operations can be constructed through
        combining tango.text._Text with tango.text.Util e.g. lines of text
        can be processed thusly:
        ---
        auto source = new Text!(char)("one\ntwo\nthree");

        foreach (line; Util.lines(source.slice))
                 // do something with line
        ---

        Substituting patterns within text can be implemented simply and
        rather efficiently:
        ---
        auto dst = new Text!(char);

        foreach (element; Util.patterns ("all cows eat grass", "eat", "chew"))
                 dst.append (element);
        ---

        Speaking a bit like Yoda might be accomplished as follows:
        ---
        auto dst = new Text!(char);

        foreach (element; Util.delims ("all cows eat grass", " "))
                 dst.prepend (element);
        ---

        Below is an overview of the API and class hierarchy:
        ---
        class Text(T) : TextView!(T)
        {
                // set or reset the content
                Text set (T[] chars, bool mutable=true);
                Text set (TextView other, bool mutable=true);

                // retreive currently selected text
                T[] selection ();

                // get the index and length of the current selection
                Span selectionSpan ();

                // mark a selection
                Text select (int start=0, int length=int.max);

                // move the selection around
                bool select (T c);
                bool select (T[] pattern);
                bool select (TextView other);
                bool selectPrior (T c);
                bool selectPrior (T[] pattern);
                bool selectPrior (TextView other);

                // append behind current selection
                Text append (TextView other);
                Text append (T[] text);
                Text append (T chr, int count=1);
                Text append (int value, options);
                Text append (long value, options);
                Text append (double value, options);

                // transcode behind current selection
                Text encode (char[]);
                Text encode (wchar[]);
                Text encode (dchar[]);

                // insert before current selection
                Text prepend (T[] text);
                Text prepend (TextView other);
                Text prepend (T chr, int count=1);

                // replace current selection
                Text replace (T chr);
                Text replace (T[] text);
                Text replace (TextView other);

                // remove current selection
                Text remove ();

                // clear content
                Text clear ();

                // trim leading and trailing whitespace
                Text trim ();

                // trim leading and trailing chr instances
                Text strip (T chr);

                // truncate at point, or current selection
                Text truncate (int point = int.max);

                // reserve some space for inserts/additions
                Text reserve (int extra);
        }

        class TextView(T) : UniText
        {
                // hash content
                hash_t toHash ();

                // return length of content
                uint length ();

                // compare content
                bool equals  (T[] text);
                bool equals  (TextView other);
                bool ends    (T[] text);
                bool ends    (TextView other);
                bool starts  (T[] text);
                bool starts  (TextView other);
                int compare  (T[] text);
                int compare  (TextView other);
                int opEquals (Object other);
                int opCmp    (Object other);

                // copy content
                T[] copy (T[] dst);

                // return content
                T[] slice ();

                // return data type
                typeinfo encoding ();

                // replace the comparison algorithm
                Comparator comparator (Comparator other);
        }

        class UniText
        {
                // convert content
                abstract char[]  toString  (char[]  dst = null);
                abstract wchar[] toString16 (wchar[] dst = null);
                abstract dchar[] toString32 (dchar[] dst = null);
        }
        ---

*******************************************************************************/

module tango.text.Text;

private import  Util = tango.text.Util;

private import  Utf = tango.text.convert.Utf;

private import  Float = tango.text.convert.Float;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

*******************************************************************************/

private extern (C) void memmove (void* dst, void* src, uint bytes);


/*******************************************************************************

        The mutable Text class actually implements the full API, whereas
        the superclasses are purely abstract (could be interfaces instead).

*******************************************************************************/

class Text(T) : TextView!(T)
{
        public  alias set               opAssign;
        public  alias append            opCatAssign;
        private alias TextView!(T)      TextViewT;

        private T[]                     content;
        private bool                    mutable;
        private Comparator              comparator_;
        private uint                    selectPoint,
                                        selectLength,
                                        contentLength;

        /***********************************************************************

                Selection span

        ***********************************************************************/

        public struct Span
        {
                uint    begin,                  /// index of selection point
                        length;                 /// length of selection
        }

        /***********************************************************************

                Create an empty Text with the specified available
                space

        ***********************************************************************/

        this (uint space = 0)
        {
                content.length = space;
                this.comparator_ = &simpleComparator;
        }

        /***********************************************************************

                Create a Text upon the provided content. If said
                content is immutable (read-only) then you might consider
                setting the 'copy' parameter to false. Doing so will
                avoid allocating heap-space for the content until it is
                modified via Text methods. This can be useful when
                wrapping an array "temporarily" with a stack-based Text

        ***********************************************************************/

        this (T[] content, bool copy = true)
        {
                set (content, copy);
                this.comparator_ = &simpleComparator;
        }

        /***********************************************************************

                Create a Text via the content of another. If said
                content is immutable (read-only) then you might consider
                setting the 'copy' parameter to false. Doing so will avoid
                allocating heap-space for the content until it is modified
                via Text methods. This can be useful when wrapping an array
                temporarily with a stack-based Text

        ***********************************************************************/

        this (TextViewT other, bool copy = true)
        {
                this (other.slice, copy);
        }

        /***********************************************************************

                Set the content to the provided array. Parameter 'copy'
                specifies whether the given array is likely to change. If
                not, the array is aliased until such time it is altered via
                this class. This can be useful when wrapping an array
                "temporarily" with a stack-based Text

        ***********************************************************************/

        final Text set (T[] chars, bool copy = true)
        {
                if ((this.mutable = copy) is true)
                     content = chars.dup;
                else
                   content = chars;

                return select (0, contentLength = chars.length);
        }

        /***********************************************************************

                Replace the content of this Text. If the new content
                is immutable (read-only) then you might consider setting the
                'copy' parameter to false. Doing so will avoid allocating
                heap-space for the content until it is modified via one of
                these methods. This can be useful when wrapping an array
                "temporarily" with a stack-based Text

        ***********************************************************************/

        final Text set (TextViewT other, bool copy = true)
        {
                return set (other.slice, copy);
        }

        /***********************************************************************

                Explicitly set the current selection

        ***********************************************************************/

        final Text select (int start=0, int length=int.max)
        {
                pinIndices (start, length);
                selectPoint = start;
                selectLength = length;
                return this;
        }

        /***********************************************************************

                Return the currently selected content

        ***********************************************************************/

        final T[] selection ()
        {
                return slice [selectPoint .. selectPoint+selectLength];
        }

        /***********************************************************************

                Return the index and length of the current selection

        ***********************************************************************/

        final Span selectionSpan ()
        {
                Span span;
                span.begin = selectPoint;
                span.length = selectLength;
                return span;
        }

        /***********************************************************************

                Find and select the next occurrence of a BMP code point
                in a string. Returns true if found, false otherwise

        ***********************************************************************/

        final bool select (T c)
        {
                auto s = slice();
                auto x = Util.locate (s, c, selectPoint);
                if (x < s.length)
                   {
                   select (x, 1);
                   return true;
                   }
                return false;
        }

        /***********************************************************************

                Find and select the next substring occurrence.  Returns
                true if found, false otherwise

        ***********************************************************************/

        final bool select (TextViewT other)
        {
                return select (other.slice);
        }

        /***********************************************************************

                Find and select the next substring occurrence. Returns
                true if found, false otherwise

        ***********************************************************************/

        final bool select (T[] chars)
        {
                auto s = slice();
                auto x = Util.locatePattern (s, chars, selectPoint);
                if (x < s.length)
                   {
                   select (x, chars.length);
                   return true;
                   }
                return false;
        }

        /***********************************************************************

                Find and select a prior occurrence of a BMP code point
                in a string. Returns true if found, false otherwise

        ***********************************************************************/

        final bool selectPrior (T c)
        {
                auto s = slice();
                auto x = Util.locatePrior (s, c, selectPoint);
                if (x < s.length)
                   {
                   select (x, 1);
                   return true;
                   }
                return false;
        }

        /***********************************************************************

                Find and select a prior substring occurrence. Returns
                true if found, false otherwise

        ***********************************************************************/

        final bool selectPrior (TextViewT other)
        {
                return selectPrior (other.slice);
        }

        /***********************************************************************

                Find and select a prior substring occurrence. Returns
                true if found, false otherwise

        ***********************************************************************/

        final bool selectPrior (T[] chars)
        {
                auto s = slice();
                auto x = Util.locatePatternPrior (s, chars, selectPoint);
                if (x < s.length)
                   {
                   select (x, chars.length);
                   return true;
                   }
                return false;
        }

        /***********************************************************************

                Append text to this Text

        ***********************************************************************/

        final Text append (TextViewT other)
        {
                return append (other.slice);
        }

        /***********************************************************************

                Append text to this Text

        ***********************************************************************/

        final Text append (T[] chars)
        {
                return append (chars.ptr, chars.length);
        }

        /***********************************************************************

                Append a count of characters to this Text

        ***********************************************************************/

        final Text append (T chr, int count=1)
        {
                uint point = selectPoint + selectLength;
                expand (point, count);
                return set (chr, point, count);
        }

        /***********************************************************************

                Append an integer to this Text

        ***********************************************************************/

        final Text append (int v, Integer.Style fmt=Integer.Style.Signed)
        {
                return append (cast(long) v, fmt);
        }

        /***********************************************************************

                Append a long to this Text

        ***********************************************************************/

        final Text append (long v, Integer.Style fmt=Integer.Style.Signed)
        {
                T[64] tmp = void;
                return append (Integer.format(tmp, v, fmt));
        }

        /***********************************************************************

                Append a double to this Text

        ***********************************************************************/

        final Text append (double v, uint decimals=2, int e=10)
        {
                T[64] tmp = void;
                return append (Float.format(tmp, v, decimals, e));
        }

        /***********************************************************************

                Insert characters into this Text

        ***********************************************************************/

        final Text prepend (T chr, int count=1)
        {
                expand (selectPoint, count);
                return set (chr, selectPoint, count);
        }

        /***********************************************************************

                Insert text into this Text

        ***********************************************************************/

        final Text prepend (T[] other)
        {
                expand (selectPoint, other.length);
                content[selectPoint..selectPoint+other.length] = other;
                return this;
        }

        /***********************************************************************

                Insert another Text into this Text

        ***********************************************************************/

        final Text prepend (TextViewT other)
        {
                return prepend (other.slice);
        }

        /***********************************************************************

                Append encoded text at the current selection point. The text
                is converted as necessary to the appropritate utf encoding.

        ***********************************************************************/

        final Text encode (char[] s)
        {
                T[1024] tmp = void;

                static if (is (T == char))
                           return append(s);

                static if (is (T == wchar))
                           return append (Utf.toString16(s, tmp));

                static if (is (T == dchar))
                           return append (Utf.toString32(s, tmp));
        }

        /// ditto
        final Text encode (wchar[] s)
        {
                T[1024] tmp = void;

                static if (is (T == char))
                           return append (Utf.toString(s, tmp));

                static if (is (T == wchar))
                           return append (s);

                static if (is (T == dchar))
                           return append (Utf.toString32(s, tmp));
        }

        /// ditto
        final Text encode (dchar[] s)
        {
                T[1024] tmp = void;

                static if (is (T == char))
                           return append (Utf.toString(s, tmp));

                static if (is (T == wchar))
                           return append (Utf.toString16(s, tmp));

                static if (is (T == dchar))
                           return append (s);
        }

        /// ditto
        final Text encode (Object o)
        {
                return encode (o.toString);
        }

        /***********************************************************************

                Replace a section of this Text with the specified
                character

        ***********************************************************************/

        final Text replace (T chr)
        {
                return set (chr, selectPoint, selectLength);
        }

        /***********************************************************************

                Replace a section of this Text with the specified
                array

        ***********************************************************************/

        final Text replace (T[] chars)
        {
                int chunk = chars.length - selectLength;
                if (chunk >= 0)
                    expand (selectPoint, chunk);
                else
                   remove (selectPoint, -chunk);

                content [selectPoint .. selectPoint+chars.length] = chars;
                return select (selectPoint, chars.length);
        }

        /***********************************************************************

                Replace a section of this Text with another

        ***********************************************************************/

        final Text replace (TextViewT other)
        {
                return replace (other.slice);
        }

        /***********************************************************************

                Remove the selection from this Text and reset the
                selection to zero length

        ***********************************************************************/

        final Text remove ()
        {
                remove (selectPoint, selectLength);
                return select (selectPoint, 0);
        }

        /***********************************************************************

                Remove the selection from this Text

        ***********************************************************************/

        private Text remove (int start, int count)
        {
                pinIndices (start, count);
                if (count > 0)
                   {
                   if (! mutable)
                         realloc ();

                   uint i = start + count;
                   memmove (content.ptr+start, content.ptr+i, (contentLength-i) * T.sizeof);
                   contentLength -= count;
                   }
                return this;
        }

        /***********************************************************************

                Truncate this string at an optional index. Default behaviour
                is to truncate at the current append point. Current selection
                is moved to the truncation point, with length 0

        ***********************************************************************/

        final Text truncate (int index = int.max)
        {
                if (index is int.max)
                    index = selectPoint + selectLength;

                pinIndex (index);
                return select (contentLength = index, 0);
        }

        /***********************************************************************

                Clear the string content

        ***********************************************************************/

        final Text clear ()
        {
                return select (contentLength = 0, 0);
        }

        /***********************************************************************

                Remove leading and trailing whitespace from this Text,
                and reset the selection to the trimmed content

        ***********************************************************************/

        final Text trim ()
        {
                content = Util.trim (slice);
                select (0, contentLength = content.length);
                return this;
        }

        /***********************************************************************

                Remove leading and trailing matches from this Text,
                and reset the selection to the stripped content

        ***********************************************************************/

        final Text strip (T matches)
        {
                content = Util.strip (slice, matches);
                select (0, contentLength = content.length);
                return this;
        }

        /***********************************************************************

                Reserve some extra room

        ***********************************************************************/

        final Text reserve (uint extra)
        {
                realloc (extra);
                return this;
        }



        /* ======================== TextView methods ======================== */



        /***********************************************************************

                Get the encoding type

        ***********************************************************************/

        final TypeInfo encoding()
        {
                return typeid(T);
        }

        /***********************************************************************

                Set the comparator delegate. Where other is null, we behave
                as a getter only

        ***********************************************************************/

        final Comparator comparator (Comparator other)
        {
                auto tmp = comparator_;
                if (other)
                    comparator_ = other;
                return tmp;
        }

        /***********************************************************************

                Hash this Text

        ***********************************************************************/

        override hash_t toHash ()
        {
                return Util.jhash (cast(ubyte*) content.ptr, contentLength * T.sizeof);
        }

        /***********************************************************************

                Return the length of the valid content

        ***********************************************************************/

        final uint length ()
        {
                return contentLength;
        }

        /***********************************************************************

                Is this Text equal to another?

        ***********************************************************************/

        final bool equals (TextViewT other)
        {
                if (other is this)
                    return true;
                return equals (other.slice);
        }

        /***********************************************************************

                Is this Text equal to the provided text?

        ***********************************************************************/

        final bool equals (T[] other)
        {
                if (other.length == contentLength)
                    return Util.matching (other.ptr, content.ptr, contentLength);
                return false;
        }

        /***********************************************************************

                Does this Text end with another?

        ***********************************************************************/

        final bool ends (TextViewT other)
        {
                return ends (other.slice);
        }

        /***********************************************************************

                Does this Text end with the specified string?

        ***********************************************************************/

        final bool ends (T[] chars)
        {
                if (chars.length <= contentLength)
                    return Util.matching (content.ptr+(contentLength-chars.length), chars.ptr, chars.length);
                return false;
        }

        /***********************************************************************

                Does this Text start with another?

        ***********************************************************************/

        final bool starts (TextViewT other)
        {
                return starts (other.slice);
        }

        /***********************************************************************

                Does this Text start with the specified string?

        ***********************************************************************/

        final bool starts (T[] chars)
        {
                if (chars.length <= contentLength)
                    return Util.matching (content.ptr, chars.ptr, chars.length);
                return false;
        }

        /***********************************************************************

                Compare this Text start with another. Returns 0 if the
                content matches, less than zero if this Text is "less"
                than the other, or greater than zero where this Text
                is "bigger".

        ***********************************************************************/

        final int compare (TextViewT other)
        {
                if (other is this)
                    return 0;

                return compare (other.slice);
        }

        /***********************************************************************

                Compare this Text start with an array. Returns 0 if the
                content matches, less than zero if this Text is "less"
                than the other, or greater than zero where this Text
                is "bigger".

        ***********************************************************************/

        final int compare (T[] chars)
        {
                return comparator_ (slice, chars);
        }

        /***********************************************************************

                Return content from this Text

                A slice of dst is returned, representing a copy of the
                content. The slice is clipped to the minimum of either
                the length of the provided array, or the length of the
                content minus the stipulated start point

        ***********************************************************************/

        final T[] copy (T[] dst)
        {
                uint i = contentLength;
                if (i > dst.length)
                    i = dst.length;

                return dst [0 .. i] = content [0 .. i];
        }

        /***********************************************************************

                Return an alias to the content of this TextView. Note
                that you are bound by honour to leave this content wholly
                unmolested. D surely needs some way to enforce immutability
                upon array references

        ***********************************************************************/

        final T[] slice ()
        {
                return content [0 .. contentLength];
        }

        /***********************************************************************

                Convert to the UniText types. The optional argument
                dst will be resized as required to house the conversion.
                To minimize heap allocation during subsequent conversions,
                apply the following pattern:
                ---
                _Text  string;

                wchar[] buffer;
                wchar[] result = string.utf16 (buffer);

                if (result.length > buffer.length)
                    buffer = result;
                ---
                You can also provide a buffer from the stack, but the output
                will be moved to the heap if said buffer is not large enough

        ***********************************************************************/

        final char[] toString (char[] dst = null)
        {
                static if (is (T == char))
                           return slice();

                static if (is (T == wchar))
                           return Utf.toString (slice, dst);

                static if (is (T == dchar))
                           return Utf.toString (slice, dst);
        }

        /// ditto
        final wchar[] toString16 (wchar[] dst = null)
        {
                static if (is (T == char))
                           return Utf.toString16 (slice, dst);

                static if (is (T == wchar))
                           return slice;

                static if (is (T == dchar))
                           return Utf.toString16 (slice, dst);
        }

        /// ditto
        final dchar[] toString32 (dchar[] dst = null)
        {
                static if (is (T == char))
                           return Utf.toString32 (slice, dst);

                static if (is (T == wchar))
                           return Utf.toString32 (slice, dst);

                static if (is (T == dchar))
                           return slice;
        }

        /***********************************************************************

                Compare this Text to another. We compare against other
                Strings only. Literals and other objects are not supported

        ***********************************************************************/

        override int opCmp (Object o)
        {
                auto other = cast (TextViewT) o;

                if (other is null)
                    return -1;

                return compare (other);
        }

        /***********************************************************************

                Is this Text equal to the text of something else?

        ***********************************************************************/

        override int opEquals (Object o)
        {
                auto other = cast (TextViewT) o;

                if (other)
                    return equals (other);

                // this can become expensive ...
                char[1024] tmp = void;
                return this.toString(tmp) == o.toString;
        }

        /// ditto
        final int opEquals (T[] s)
        {
                return slice == s;
        }

        /***********************************************************************

                Pin the given index to a valid position.

        ***********************************************************************/

        private void pinIndex (inout int x)
        {
                if (x > contentLength)
                    x = contentLength;
        }

        /***********************************************************************

                Pin the given index and length to a valid position.

        ***********************************************************************/

        private void pinIndices (inout int start, inout int length)
        {
                if (start > contentLength)
                    start = contentLength;

                if (length > (contentLength - start))
                    length = contentLength - start;
        }

        /***********************************************************************

                Compare two arrays. Returns 0 if the content matches, less
                than zero if A is "less" than B, or greater than zero where
                A is "bigger". Where the substrings match, the shorter is
                considered "less".

        ***********************************************************************/

        private int simpleComparator (T[] a, T[] b)
        {
                uint i = a.length;
                if (b.length < i)
                    i = b.length;

                for (int j, k; j < i; ++j)
                     if ((k = a[j] - b[j]) != 0)
                          return k;

                return a.length - b.length;
        }

        /***********************************************************************

                Make room available to insert or append something

        ***********************************************************************/

        private void expand (uint index, uint count)
        {
                if (!mutable || (contentLength + count) > content.length)
                     realloc (count);

                memmove (content.ptr+index+count, content.ptr+index, (contentLength - index) * T.sizeof);
                selectLength += count;
                contentLength += count;
        }

        /***********************************************************************

                Replace a section of this Text with the specified
                character

        ***********************************************************************/

        private Text set (T chr, uint start, uint count)
        {
                content [start..start+count] = chr;
                return this;
        }

        /***********************************************************************

                Allocate memory due to a change in the content. We handle
                the distinction between mutable and immutable here.

        ***********************************************************************/

        private void realloc (uint count = 0)
        {
                uint size = (content.length + count + 127) & ~127;

                if (mutable)
                    content.length = size;
                else
                   {
                   mutable = true;
                   T[] x = content;
                   content = new T[size];
                   if (contentLength)
                       content[0..contentLength] = x;
                   }
        }

        /***********************************************************************

                Internal method to support Text appending

        ***********************************************************************/

        private Text append (T* chars, uint count)
        {
                uint point = selectPoint + selectLength;
                expand (point, count);
                content[point .. point+count] = chars[0 .. count];
                return this;
        }
}



/*******************************************************************************

        Immutable string

*******************************************************************************/

class TextView(T) : UniText
{
        public typedef int delegate (T[] a, T[] b) Comparator;

        /***********************************************************************

                Return the length of the valid content

        ***********************************************************************/

        abstract uint length ();

        /***********************************************************************

                Is this Text equal to another?

        ***********************************************************************/

        abstract bool equals (TextView other);

        /***********************************************************************

                Is this Text equal to the the provided text?

        ***********************************************************************/

        abstract bool equals (T[] other);

        /***********************************************************************

                Does this Text end with another?

        ***********************************************************************/

        abstract bool ends (TextView other);

        /***********************************************************************

                Does this Text end with the specified string?

        ***********************************************************************/

        abstract bool ends (T[] chars);

        /***********************************************************************

                Does this Text start with another?

        ***********************************************************************/

        abstract bool starts (TextView other);

        /***********************************************************************

                Does this Text start with the specified string?

        ***********************************************************************/

        abstract bool starts (T[] chars);

        /***********************************************************************

                Compare this Text start with another. Returns 0 if the
                content matches, less than zero if this Text is "less"
                than the other, or greater than zero where this Text
                is "bigger".

        ***********************************************************************/

        abstract int compare (TextView other);

        /***********************************************************************

                Compare this Text start with an array. Returns 0 if the
                content matches, less than zero if this Text is "less"
                than the other, or greater than zero where this Text
                is "bigger".

        ***********************************************************************/

        abstract int compare (T[] chars);

        /***********************************************************************

                Return content from this Text. A slice of dst is
                returned, representing a copy of the content. The
                slice is clipped to the minimum of either the length
                of the provided array, or the length of the content
                minus the stipulated start point

        ***********************************************************************/

        abstract T[] copy (T[] dst);

        /***********************************************************************

                Compare this Text to another

        ***********************************************************************/

        abstract int opCmp (Object o);

        /***********************************************************************

                Is this Text equal to another?

        ***********************************************************************/

        abstract int opEquals (Object other);

        /***********************************************************************

                Is this Text equal to another?

        ***********************************************************************/

        abstract int opEquals (T[] other);

        /***********************************************************************

                Get the encoding type

        ***********************************************************************/

        abstract TypeInfo encoding();

        /***********************************************************************

                Set the comparator delegate

        ***********************************************************************/

        abstract Comparator comparator (Comparator other);

        /***********************************************************************

                Hash this Text

        ***********************************************************************/

        abstract hash_t toHash ();

        /***********************************************************************

                Return an alias to the content of this TextView. Note
                that you are bound by honour to leave this content wholly
                unmolested. D surely needs some way to enforce immutability
                upon array references

        ***********************************************************************/

        abstract T[] slice ();
}


/*******************************************************************************

        A string abstraction that converts to anything

*******************************************************************************/

class UniText
{
        abstract char[]  toString  (char[]  dst = null);

        abstract wchar[] toString16 (wchar[] dst = null);

        abstract dchar[] toString32 (dchar[] dst = null);

        abstract TypeInfo encoding();
}



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        //void main() {}
        unittest
        {
        auto s = new Text!(char);
        s = "hello";

        s.select ("hello");
        assert (s.selection == "hello");
        s.replace ("1");
        assert (s.selection == "1");
        assert (s == "1");

        assert (s.clear == "");

        assert (s.append(12345) == "12345");
        assert (s.selection == "12345");

        //s.append ("fubar");
        s ~= "fubar";
        assert (s.selection == "12345fubar");
        assert (s.select('5'));
        assert (s.selection == "5");
        assert (s.remove == "1234fubar");
        assert (s.select("fubar"));
        assert (s.selection == "fubar");
        assert (s.select("wumpus") is false);
        assert (s.selection == "fubar");

        assert (s.clear.append(1.2345, 4) == "1.2345");

        assert (s.clear.append(0xf0, Integer.Style.Binary) == "11110000");

        assert (s.clear.encode("one"d).toString == "one");

        assert (Util.splitLines(s.clear.append("a\nb").slice).length is 2);

        assert (s.select.replace("almost ") == "almost ");
        foreach (element; Util.patterns ("all cows eat grass", "eat", "chew"))
                 s.append (element);
        assert (s.selection == "almost all cows chew grass");
        }
}
