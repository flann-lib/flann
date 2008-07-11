/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: May 2005      
      
        author:         Kris

        Converts between native and text representations of HTTP time
        values. Internally, time is represented as UTC with an epoch 
        fixed at Jan 1st 1970. The text representation is formatted in
        accordance with RFC 1123, and the parser will accept one of 
        RFC 1123, RFC 850, or asctime formats.

        See http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html for
        further detail.

        Applying the D "import alias" mechanism to this module is highly
        recommended, in order to limit namespace pollution:
        ---
        import TimeStamp = tango.text.convert.TimeStamp;

        auto t = TimeStamp.parse ("Sun, 06 Nov 1994 08:49:37 GMT");
        ---
        
*******************************************************************************/

module tango.text.convert.TimeStamp;

private import tango.time.Time;

private import tango.core.Exception;

private import Util = tango.text.Util;

private import tango.time.chrono.Gregorian;

private import Int = tango.text.convert.Integer;

/******************************************************************************

        Parse provided input and return a UTC epoch time. An exception
        is raised where the provided string is not fully parsed.

******************************************************************************/

ulong toTime(T) (T[] src)
{
        uint len;

        auto x = parse (src, &len);
        if (len < src.length)
            throw new IllegalArgumentException ("unknown time format: "~src);
        return x;
}

/******************************************************************************

        Template wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

char[] toString (Time time)
{
        char[32] tmp = void;
        
        return format (tmp, time).dup;
}
               
/******************************************************************************

        Template wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

wchar[] toString16 (Time time)
{
        wchar[32] tmp = void;
        
        return format (tmp, time).dup;
}
               
/******************************************************************************

        Template wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

dchar[] toString32 (Time time)
{
        dchar[32] tmp = void;
        
        return format (tmp, time).dup;
}
               
/******************************************************************************

        RFC1123 formatted time

        Converts to the format "Sun, 06 Nov 1994 08:49:37 GMT", and
        returns a populated slice of the provided buffer. Note that
        RFC1123 format is always in absolute GMT time, and a thirty-
        element buffer is sufficient for the produced output

        Throws an exception where the supplied time is invalid

******************************************************************************/

T[] format(T, U=Time) (T[] output, U t)
{return format!(T)(output, cast(Time) t);}

T[] format(T) (T[] output, Time t)
{
        static T[][] Months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        static T[][] Days   = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

        T[] convert (T[] tmp, int i)
        {
                return Int.format!(T) (tmp, i, Int.Style.Unsigned, Int.Flags.Zero);
        }


        assert (output.length >= 29);
        if (t is t.max)
            throw new IllegalArgumentException ("TimeStamp.format :: invalid Time argument");

        // convert time to field values
        auto time = t.time;
        auto date = Gregorian.generic.toDate (t);

        // use the featherweight formatter ...
        T[14] tmp = void;
        return Util.layout (output, "%0, %1 %2 %3 %4:%5:%6 GMT", 
                            Days[date.dow],
                            convert (tmp[0..2], date.day),
                            Months[date.month-1],
                            convert (tmp[2..6], date.year),
                            convert (tmp[6..8], time.hours),
                            convert (tmp[8..10], time.minutes),
                            convert (tmp[10..12], time.seconds)
                           );
}


/******************************************************************************

      Parse provided input and return a UTC epoch time. A return value 
      of Time.max indicated a parse-failure.

      An option is provided to return the count of characters parsed - 
      an unchanged value here also indicates invalid input.

******************************************************************************/

Time parse(T) (T[] src, uint* ate = null)
{
        int     len;
        Time    value;

        if ((len = rfc1123 (src, value)) > 0 || 
            (len = rfc850  (src, value)) > 0 || 
            (len = asctime (src, value)) > 0)
           {
           if (ate)
               *ate = len;
           return value;
           }

        return Time.max;
}


/******************************************************************************

        RFC 822, updated by RFC 1123 :: "Sun, 06 Nov 1994 08:49:37 GMT"

        Returns the number of elements consumed by the parse; zero if
        the parse failed

******************************************************************************/

int rfc1123(T) (T[] src, inout Time value)
{
        TimeOfDay       tod;
        Date            date;
        T*              p = src.ptr;

        bool dt (inout T* p)
        {
                return ((date.day = parseInt(p)) > 0     &&
                         *p++ == ' '                     &&
                        (date.month = parseMonth(p)) > 0 &&
                         *p++ == ' '                     &&
                        (date.year = parseInt(p)) > 0);
        }

        if (parseShortDay(p) >= 0 &&
            *p++ == ','           &&
            *p++ == ' '           &&
            dt (p)                &&
            *p++ == ' '           &&
            time (tod, p)         &&
            *p++ == ' '           &&
            p[0..3] == "GMT")
            {
            value = Gregorian.generic.toTime (date, tod);
            return (p+3) - src.ptr;
            }

        return 0;
}


/******************************************************************************

        RFC 850, obsoleted by RFC 1036 :: "Sunday, 06-Nov-94 08:49:37 GMT"

        Returns the number of elements consumed by the parse; zero if
        the parse failed

******************************************************************************/

int rfc850(T) (T[] src, inout Time value)
{
        TimeOfDay       tod;
        Date            date;
        T*              p = src.ptr;

        bool dt (inout T* p)
        {
                return ((date.day = parseInt(p)) > 0     &&
                         *p++ == '-'                     &&
                        (date.month = parseMonth(p)) > 0 &&
                         *p++ == '-'                     &&
                        (date.year = parseInt(p)) > 0);
        }

        if (parseFullDay(p) >= 0 &&
            *p++ == ','          &&
            *p++ == ' '          &&
            dt (p)               &&
            *p++ == ' '          &&
            time (tod, p)        &&
            *p++ == ' '          &&
            p[0..3] == "GMT")
            {
            if (date.year < 70)
                date.year += 2000;
            else
               if (date.year < 100)
                   date.year += 1900;

            value = Gregorian.generic.toTime (date, tod);
            return (p+3) - src.ptr;
            }

        return 0;
}


/******************************************************************************

        ANSI C's asctime() format :: "Sun Nov 6 08:49:37 1994"

        Returns the number of elements consumed by the parse; zero if
        the parse failed

******************************************************************************/

int asctime(T) (T[] src, inout Time value)
{
        TimeOfDay       tod;
        Date            date;
        T*              p = src.ptr;

        bool dt (inout T* p)
        {
                return ((date.month = parseMonth(p)) > 0  &&
                         *p++ == ' '                      &&
                        ((date.day = parseInt(p)) > 0     ||
                        (*p++ == ' '                      &&
                        (date.day = parseInt(p)) > 0)));
        }

        if (parseShortDay(p) >= 0 &&
            *p++ == ' '           &&
            dt (p)                &&
            *p++ == ' '           &&
            time (tod, p)         &&
            *p++ == ' '           &&
            (date.year = parseInt (p)) > 0)
            {
            value = Gregorian.generic.toTime (date, tod);
            return p - src.ptr;
            }

        return 0;
}

/******************************************************************************

        DOS time format :: "12-31-06 08:49AM"

        Returns the number of elements consumed by the parse; zero if
        the parse failed

******************************************************************************/

int dostime(T) (T[] src, inout Time value)
{
        TimeOfDay       tod;
        Date            date;
        T*              p = src.ptr;

        bool dt (inout T* p)
        {
                return ((date.month = parseInt(p)) > 0 &&
                         *p++ == '-'                   &&
                        ((date.day = parseInt(p)) > 0  &&
                        (*p++ == '-'                   &&
                        (date.year = parseInt(p)) > 0)));
        }

        if (dt(p) >= 0                       &&
            *p++ == ' '                      &&
            (tod.hours = parseInt(p)) > 0    &&
            *p++ == ':'                      &&
            (tod.minutes = parseInt(p)) > 0  &&
            (*p == 'A' || *p == 'P'))
            {
            if (*p is 'P')
                tod.hours += 12;
            
            if (date.year < 70)
                date.year += 2000;
            else
               if (date.year < 100)
                   date.year += 1900;
            
            value = Gregorian.generic.toTime (date, tod);
            return (p+2) - src.ptr;
            }

        return 0;
}

/******************************************************************************

        ISO-8601 format :: "2006-01-31 14:49:30,001"

        Returns the number of elements consumed by the parse; zero if
        the parse failed

******************************************************************************/

int iso8601(T) (T[] src, inout Time value)
{
        TimeOfDay       tod;
        Date            date;
        T*              p = src.ptr;

        bool dt (inout T* p)
        {
                return ((date.year = parseInt(p)) > 0   &&
                         *p++ == '-'                    &&
                        ((date.month = parseInt(p)) > 0 &&
                        (*p++ == '-'                    &&
                        (date.day = parseInt(p)) > 0)));
        }

        if (dt(p) >= 0     &&
            *p++ == ' '    &&
            time (tod, p) &&
            *p++ == ',')
            {
            tod.millis = parseInt (p);
            value = Gregorian.generic.toTime (date, tod);
            return p - src.ptr;
            }

        return 0;
}


/******************************************************************************

        Parse a time field

******************************************************************************/

private bool time(T) (inout TimeOfDay time, inout T* p)
{
        return ((time.hours = parseInt(p)) > 0   &&
                 *p++ == ':'                     &&
                (time.minutes = parseInt(p)) > 0 &&
                 *p++ == ':'                     &&
                (time.seconds = parseInt(p)) > 0);
}


/******************************************************************************

        Match a month from the input

******************************************************************************/

private int parseMonth(T) (inout T* p)
{
        int month;

        switch (p[0..3])
               {
               case "Jan":
                    month = 1;
                    break; 
               case "Feb":
                    month = 2;
                    break; 
               case "Mar":
                    month = 3;
                    break; 
               case "Apr":
                    month = 4;
                    break; 
               case "May":
                    month = 5;
                    break; 
               case "Jun":
                    month = 6;
                    break; 
               case "Jul":
                    month = 7;
                    break; 
               case "Aug":
                    month = 8;
                    break; 
               case "Sep":
                    month = 9;
                    break; 
               case "Oct":
                    month = 10;
                    break; 
               case "Nov":
                    month = 11;
                    break; 
               case "Dec":
                    month = 12;
                    break; 
               default:
                    return month;
               }

        p += 3;
        return month;
}


/******************************************************************************

        Match a day from the input

******************************************************************************/

private int parseShortDay(T) (inout T* p)
{
        int day;

        switch (p[0..3])
               {
               case "Sun":
                    day = 0;
                    break;
               case "Mon":
                    day = 1;
                    break; 
               case "Tue":
                    day = 2;
                    break; 
               case "Wed":
                    day = 3;
                    break; 
               case "Thu":
                    day = 4;
                    break; 
               case "Fri":
                    day = 5;
                    break; 
               case "Sat":
                    day = 6;
                    break; 
               default:
                    return -1;
               }

        p += 3;
        return day;
}


/******************************************************************************

        Match a day from the input. Sunday is 0

******************************************************************************/

private int parseFullDay(T) (inout T* p)
{
        static T[][] days =
        [
        "Sunday", 
        "Monday", 
        "Tuesday", 
        "Wednesday", 
        "Thursday", 
        "Friday", 
        "Saturday", 
        ];

        foreach (i, day; days)
                 if (day == p[0..day.length])
                    {
                    p += day.length;
                    return i;
                    }
        return -1;
}


/******************************************************************************

        Extract an integer from the input

******************************************************************************/

private static int parseInt(T) (inout T* p)
{
        int value;

        while (*p >= '0' && *p <= '9')
               value = value * 10 + *p++ - '0';
        return value;
}


/******************************************************************************

******************************************************************************/

debug (UnitTest)
{
        unittest
        {
                wchar[30] tmp;
                wchar[] test = "Sun, 06 Nov 1994 08:49:37 GMT";
                
                auto time = parse (test);
                auto text = format (tmp, time);
                assert (text == test);
        }
}

/******************************************************************************

******************************************************************************/

debug (TimeStamp)
{
        void main()
        {
                wchar[30] tmp;
                wchar[] test = "Sun, 06 Nov 1994 08:49:37 GMT";
                
                auto time = parse (test);
                auto text = format (tmp, time);
                assert (text == test);              
        }
}
