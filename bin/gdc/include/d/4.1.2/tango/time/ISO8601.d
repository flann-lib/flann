/*******************************************************************************

        copyright:      Copyright (c) 2007 Deewiant. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Aug 2007

        author:         Deewiant

        Based on the ISO 8601:2004 standard (described in a PDF Wikipedia 
        http://isotc.iso.org/livelink/livelink/4021199/ISO_8601_2004_E.zip?
        func=doc.Fetch&nodeid=4021199), which has functions for parsing almost 
        every date/time format specified.

        The ones they don't parse are intervals, durations, and recurring 
        intervals, because I got too lazy to implement them. The functions 
        (iso8601Time, iso8601Date, and iso8601) update a Date passed instead 
        of a Time, as does the current iso8601, because that's too limited
        a format. One can always convert to a Time if necessary, keeping
        in mind that information loss might occur if the Date is outside the
        interval Time can represent.

        In addition, because its dayOfWeek function only works for 1900-3-1 to 
        2100-2-28, it would fail by a day or two on ISO week dates outside that 
        interval. (Currently it asserts outside 1901-2099.) If somebody knows a 
        good algorithm which would fix that, by all means submit it.

        Another thing it doesn't do is conversions from local time to UTC if the 
        time parsed starts with a 'T'. A comment in doIso8601Time() explains why.

        Because the Date struct has no support for time zones, the module just 
        converts times with specified time zones into UTC. This leads to 
        behaviour which may or may not be a bug, as explained in a comment in 
        getTimeZone().

*******************************************************************************/

module tango.time.ISO8601;

public import tango.time.Time;

public import tango.time.chrono.Calendar;

private import tango.time.chrono.Gregorian;

/// Returns the number of chars used to compose a valid date: 0 if no date can be composed.
/// Fields in date will either be correct (e.g. months will be >= 1 and <= 12) or zero.

size_t iso8601Date(T)(T[] src, ref Date date, size_t expanded = 0) {
    ubyte dummy = void;
    T* p = src.ptr;
    return doIso8601Date(p, src, date, expanded, dummy);
}

private size_t doIso8601Date(T)(ref T* p, T[] src, ref Date date, size_t expanded, out ubyte separators)
out {
    assert (!date.month || (date.month >= 1 && date.month <= 12));
    assert (!date.day   || (date.month && date.day   >= 1 && date.day   <= daysPerMonth(date.month, date.year)));
} body {

        // always set era to AD
        date.era = Gregorian.AD_ERA;

    size_t eaten() { return p - src.ptr; }
    bool done(T[] s) { return .done(eaten(), src.length, *p, s); }

    if (!parseYear(p, expanded, date.year))
        return (date.year = 0);

    auto onlyYear = eaten();

    // /([+-]Y{expanded})?(YYYY|YY)/
    if (done("-0123W"))
        return onlyYear;

    if (accept(p, '-'))
        separators = true;

    if (accept(p, 'W')) {
        // (year)-Www-D

        T* p2 = p;

        int i = parseIntMax(p, 3u);

        if (i) if (p - p2 == 2) {

            // (year)-Www
            if (done("-")) {
                if (getMonthAndDayFromWeek(date, i))
                    return eaten();

            // (year)-Www-D
            } else if (demand(p, '-'))
                if (getMonthAndDayFromWeek(date, i, *p++ - '0'))
                    return eaten();

        } else if (p - p2 == 3)
            // (year)WwwD
            if (getMonthAndDayFromWeek(date, i / 10, i % 10))
                return eaten();

        return onlyYear;
    }

    // next up, MM or MM[-]DD or DDD

    T* p2 = p;

    int i = parseIntMax(p);
    if (!i)
        return onlyYear;

    switch (p - p2) {
        case 2:
            date.month = i;

            if (!(date.month >= 1 && date.month <= 12)) {
                date.month = 0;
                return onlyYear;
            }

            auto onlyMonth = eaten();

            // (year)-MM
            if (done("-"))
                return onlyMonth;

            // (year)-MM-DD
            if (!(
                demand(p, '-') &&
                (date.day = parseIntMax(p, 2u)) != 0 && date.day <= daysPerMonth(date.month, date.year)
            )) {
                date.day = 0;
                return onlyMonth;
            }

            break;

        case 4:
            // e.g. 20010203, i = 203 now

            date.month = i / 100;
            date.day   = i % 100;

            // (year)MMDD
            if (!(
                date.month >= 1 && date.month <= 12 &&
                date.day   >= 0 && date.day   <= daysPerMonth(date.month, date.year)
            )) {
                date.month = date.day = 0;
                return onlyYear;
            }

            break;

        case 3:
            // (year)-DDD
            // i is the ordinal of the day within the year

            bool leap = isLeapYear(date.year);

            if (i > 365 + leap)
                return onlyYear;

            if (i <= 31) {
                date.month = 1;
                date.day   = i;

            } else if (i <= 59 + leap) {
                date.month = 2;
                date.day   = i - 31 - leap;

            } else if (i <= 90 + leap) {
                date.month = 3;
                date.day   = i - 59 - leap;

            } else if (i <= 120 + leap) {
                date.month = 4;
                date.day   = i - 90 - leap;

            } else if (i <= 151 + leap) {
                date.month = 5;
                date.day   = i - 120 - leap;

            } else if (i <= 181 + leap) {
                date.month = 6;
                date.day   = i - 151 - leap;

            } else if (i <= 212 + leap) {
                date.month = 7;
                date.day   = i - 181 - leap;

            } else if (i <= 243 + leap) {
                date.month = 8;
                date.day   = i - 212 - leap;

            } else if (i <= 273 + leap) {
                date.month = 9;
                date.day   = i - 243 - leap;

            } else if (i <= 304 + leap) {
                date.month = 10;
                date.day   = i - 273 - leap;

            } else if (i <= 334 + leap) {
                date.month = 11;
                date.day   = i - 304 - leap;

            } else {
                if (i > 365 + leap)
                    assert (false);

                date.month = 12;
                date.day   = i - 334 - leap;
            }

        default: break;
    }

    return eaten();
}

/// Returns the number of chars used to compose a valid date: 0 if no date can be composed.
/// Fields in date will be zero if incorrect: since 00:00:00,000 is a valid time, the return value must be checked to be sure of the result.
/// time.seconds may be 60 if the hours and minutes are 23 and 59, as leap seconds are occasionally added to UTC time.
/// time.hours may be 0 or 24: the latter marks the end of a day, the former the beginning.

size_t iso8601Time(T)(T[] src, ref Date date, ref TimeOfDay time) {
    bool dummy = void;
    T* p = src.ptr;
    return doIso8601Time(p, src, date, time, WHATEVER, dummy);
}

private enum : ubyte { NO = 0, YES = 1, WHATEVER }

// bothValid is used only to get iso8601() to catch errors correctly
private size_t doIso8601Time(T)(ref T* p, T[] src, ref Date date, ref TimeOfDay time, ubyte separators, out bool bothValid)
out {
    // yes, I could just write >= 0, but this emphasizes the difference between == 0 and != 0
    assert (!time.hours   || (time.hours   > 0 && time.hours   <=  24));
    assert (!time.minutes || (time.minutes > 0 && time.minutes <=  59));
    assert (!time.seconds || (time.seconds > 0 && time.seconds <=  60));
    assert (!time.millis  || (time.millis  > 0 && time.millis  <= 999));
} body {
    size_t eaten() { return p - src.ptr; }
    bool done(T[] s) { return .done(eaten(), src.length, *p, s); }

    bool checkColon() {
        if (separators == WHATEVER)
            accept(p, ':');

        else if (accept(p, ':') != separators)
            return false;

        return true;
    }

    byte getTimeZone() { return .getTimeZone(p, date, time, separators, &done); }

    // TODO/BUG: need to convert from local time if got T
    // however, Tango provides nothing like Phobos's std.date.getLocalTZA
    // (which doesn't look like it should work on Windows, it should use tzi.bias only, and GetTimeZoneInformationForYear)
    // (and which uses too complicated code for Posix, tzset should be enough)
    // and I'm not interested in delving into system-specific code right now
    // remember also that -1 BC is the year zero in ISO 8601... -2 BC is -1, etc
    if (separators == WHATEVER)
        accept(p, 'T');

    if (parseInt(p, 2u, time.hours) != 2 || time.hours > 24)
        return (time.hours = 0);

    auto onlyHour = eaten();

    // hh
    if (done("+,-.012345:"))
        return onlyHour;

    switch (getDecimal(p, time, HOUR)) {
        case NOTFOUND: break;
        case    FOUND:
            auto onlyDecimal = eaten();
            if (getTimeZone() == BAD)
                return onlyDecimal;

            // /hh,h+/
            return eaten();

        case BAD: return onlyHour;
        default: assert (false);
    }

    switch (getTimeZone()) {
        case NOTFOUND: break;
        case    FOUND: return eaten();
        case BAD:      return onlyHour;
        default: assert (false);
    }

    if (
        !checkColon() ||

        parseInt(p, 2u, time.minutes) != 2 || time.minutes > 59 ||

        // hour 24 is only for 24:00:00
        (time.hours == 24 && time.minutes != 0)
    ) {
        time.minutes = 0;
        return onlyHour;
    }

    auto onlyMinute = eaten();

    // hh:mm
    if (done("+,-.0123456:")) {
        bothValid = true;
        return onlyMinute;
    }

    switch (getDecimal(p, time, MINUTE)) {
        case NOTFOUND: break;
        case    FOUND:
            auto onlyDecimal = eaten();
            if (getTimeZone() == BAD)
                return onlyDecimal;

            // /hh:mm,m+/
            bothValid = true;
            return eaten();

        case BAD: return onlyMinute;
        default: assert (false);
    }

    switch (getTimeZone()) {
        case NOTFOUND: break;
        case    FOUND: bothValid = true; return eaten();
        case BAD:      return onlyMinute;
        default: assert (false);
    }

    if (
        !checkColon() ||
         parseInt(p, 2u, time.seconds) != 2 || time.seconds > 60 ||
        (time.hours == 24 && time.seconds  != 0) ||
        (time.seconds  == 60 && time.hours != 23 && time.minutes != 59)
    ) {
        time.seconds = 0;
        return onlyMinute;
    }

    auto onlySecond = eaten();

    // hh:mm:ss
    if (done("+,-.Z")) {
        bothValid = true;
        return onlySecond;
    }

    switch (getDecimal(p, time, SECOND)) {
        case NOTFOUND: break;
        case    FOUND:
            auto onlyDecimal = eaten();
            if (getTimeZone() == BAD)
                return onlyDecimal;

            // /hh:mm:ss,s+/
            bothValid = true;
            return eaten();

        case BAD: return onlySecond;
        default: assert (false);
    }

    if (getTimeZone() == BAD)
        return onlySecond;
    else {
        bothValid = true;
        return eaten(); // hh:mm:ss with timezone
    }
}

// combination of date and time
// stricter than just date followed by time:
//  can't have an expanded or reduced date
//  either use separators everywhere or not at all

/// This function is very strict: either a complete date and time can be extracted, or nothing can.
/// If this function returns zero, the fields of date are undefined.

size_t iso8601(T)(T[] src, ref Date date, ref TimeOfDay time) {
    T* p = src.ptr;
    ubyte sep;
    bool bothValid = false;

    if (
        doIso8601Date(p, src, date, 0u, sep) &&
        date.year && date.month && date.day &&

        // by mutual agreement this T may be omitted
        // but this is just a convenience method for date+time anyway
        demand(p, 'T') &&

        doIso8601Time(p, src, date, time, sep, bothValid) &&
        bothValid
    )
        return p - src.ptr;
    else
        return 0;
}

/+ +++++++++++++++++++++++++++++++++++++++ +\

   Privates used by date

\+ +++++++++++++++++++++++++++++++++++++++ +/

// /([+-]Y{expanded})?(YYYY|YY)/
private bool parseYear(T)(ref T* p, size_t expanded, out uint year) {

    bool doParse() {
        T* p2 = p;

        if (!parseInt(p, expanded + 4u, year))
            return false;

        // it's Y{expanded}YY, Y{expanded}YYYY, or unacceptable
        if (p - p2 - expanded == 2u)
            year *= 100;
        else if (p - p2 - expanded != 4u)
            return false;

        return true;
    }

    if (accept(p, '-')) {
        if (!doParse())
            return false;
        year = -year;
    } else {
        accept(p, '+');
        if (!doParse())
            return false;
    }

    return true;
}

// find the month and day based on the calendar week
// uses date.year for leap year calculations
// returns false if week and date.year are incompatible
// based on the VBA function at http://www.probabilityof.com/ISO8601.shtml
private bool getMonthAndDayFromWeek(ref Date date, int week, int day = 1) {
    if (week < 1 || week > 53 || day < 1 || day > 7)
        return false;

    bool leap = isLeapYear(date.year);

    // only years starting with Thursday and
    // leap years starting with Wednesday have 53 weeks

    if (week == 53) {
        int startingDay = dayOfWeek(date.year, 1, 1, leap);

        if (!(startingDay == 4 || (leap && startingDay == 3)))
            return false;
    }

    // days since year-01-04
    int delta = 7*(week - 1) - dayOfWeek(date.year, 1, 4, leap) + day;

    if (delta <= -4) {
        if (delta < -7)
            assert (false);

        --date.year;
        date.month = 12;
        date.day   = delta + 4 + 31;

    } else if (delta <= 27) {
        date.month = 1;
        date.day   = delta + 4;

    } else if (delta <= 56 + leap) {
        date.month = 2;
        date.day   = delta - 27;

    } else if (delta <= 87 + leap) {
        date.month = 3;
        date.day   = delta - 55 - leap;

    } else if (delta <= 117 + leap) {
        date.month = 4;
        date.day   = delta - 86 - leap;

    } else if (delta <= 148 + leap) {
        date.month = 5;
        date.day   = delta - 116 - leap;

    } else if (delta <= 178 + leap) {
        date.month = 6;
        date.day   = delta - 147 - leap;

    } else if (delta <= 209 + leap) {
        date.month = 7;
        date.day   = delta - 177 - leap;

    } else if (delta <= 240 + leap) {
        date.month = 8;
        date.day   = delta - 208 - leap;

    } else if (delta <= 270 + leap) {
        date.month = 9;
        date.day   = delta - 239 - leap;

    } else if (delta <= 301 + leap) {
        date.month = 10;
        date.day   = delta - 269 - leap;

    } else if (delta <= 331 + leap) {
        date.month = 11;
        date.day   = delta - 300 - leap;

    } else if (delta <= 361 + leap) {
        date.month = 12;
        date.day   = delta - 330 - leap;

    } else {
        if (delta > 365 + leap)
            assert (false);

        ++date.year;
        date.month = 1;
        date.day   = delta - 365 - leap + 4;
    }

    return true;
}

private bool isLeapYear(int year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

// Babwani's Congruence
private int dayOfWeek(int year, int month, int day, bool leap)
in {
    assert (month  >= 1 && month  <= 12);
    assert (day    >= 1 && day    <= 31);

    // BUG: only works for 1900-3-1 to 2100-2-28
    assert (year >= 1901 && year <= 2099, "iso8601 :: Can't calculate day of week outside the years 1900-2099");

} out(result) {
    assert (result >= 1 && result <= 7);

} body {
    int f() {
        if (leap && month <= 2)
            return [6,2][month-1];

        return [0,3,3,6,1,4,6,2,5,0,3,5][month-1];
    }

    int d = ((5*(year % 100) / 4) - 2*((year / 100) % 4) + f() + day) % 7;

    // defaults to Saturday=0, Friday=6: convert to Monday=1, Sunday=7
    return (d <= 1 ? d+6 : d-1);
}

/+ +++++++++++++++++++++++++++++++++++++++ +\

   Privates used by time

\+ +++++++++++++++++++++++++++++++++++++++ +/

private enum : ubyte { HOUR, MINUTE, SECOND }
private enum :  byte { BAD, FOUND, NOTFOUND }

private byte getDecimal(T)(ref T* p, ref TimeOfDay time, ubyte which) {
    if (accept(p, ',') || accept(p, '.')) {

        T* p2 = p;

        int i;
        size_t iLen = parseInt(p, i);

        if (
            iLen == 0 ||

            // if i is 0, must have at least 3 digits
            // ... or at least that's what I think the standard means
            // when it says "[i]f the magnitude of the number is less
            // than unity, the decimal sign shall be preceded by two
            // zeros"...
            // surely that should read "followed" and not "preceded"

            (i == 0 && iLen < 3)
        )
            return BAD;

        // 10 to the power of (iLen - 1)
        int pow = 1;
        while (--iLen)
            pow *= 10;

        switch (which) {
            case HOUR:
                time.minutes = 6 * i / pow;
                time.seconds = 6 * i % pow;
                break;
            case MINUTE:
                time.seconds = 6    * i / pow;
                time.millis  = 6000 * i / pow % 1000;
                break;
            case SECOND:
                time.millis = 100 * i / pow;
                break;

            default: assert (false);
        }

        return FOUND;
    }

    return NOTFOUND;
}

// the Date is always UTC, so this just adds the offset to the date fields
// another option would be to add time zone fields to Date and have this fill them

private byte getTimeZone(T)(ref T* p, ref Date date, ref TimeOfDay time, ubyte separators, bool delegate(T[]) done) {
    if (accept(p, 'Z'))
        return FOUND;

    int factor = -1;

    if (accept(p, '-'))
        factor = 1;

    else if (!accept(p, '+'))
        return NOTFOUND;

    int hour, realhour = time.hours, realminute = time.minutes;
        scope(exit) time.hours = cast(uint)realhour;
        scope(exit) time.minutes = cast(uint)realminute;
    if (parseInt(p, 2u, hour) != 2 || hour > 12 || (hour == 0 && factor == 1))
        return BAD;

    realhour += factor * hour;

    void hourCheck() {
        if (realhour > 24 || (realhour == 24 && (realminute || time.seconds))) {
            realhour -= 24;

            // BUG? what should be done?
            // if we get a time like 20:00-05:00
            // which needs to be converted to UTC by adding 05:00 to 20:00
            // we just set the time to 01:00 and the day to 1
            // even though this is time, which really has nothing to do with the day, which is part of the date
            // if this isn't a bug, it needs to be documented: it's not necessarily obvious
            if (date.day++ && date.day > daysPerMonth(date.month, date.year)) {
                date.day = 1;
                if (++date.month > 12) {
                    date.month = 1;
                    ++date.year;
                }
            }
        } else if (realhour < 0) {
            realhour += 24;

            // ditto above BUG?
            if (date.day-- && date.day < 1) {
                if (--date.month < 1) {
                    date.month = 12;
                    --date.year;
                }

                date.day = daysPerMonth(date.month, date.year);
            }
        }
    }

    if (done("012345:")) {
        hourCheck();
        return FOUND;
    }

    if (separators == WHATEVER)
        accept(p, ':');

    else if (accept(p, ':') != separators)
        return BAD;

    int minute;
    if (parseInt(p, 2u, minute) != 2)
        return BAD;

    assert (minute <= 59);

    realminute += factor * minute;

    if (realminute > 59) {
        realminute -= 60;
        ++realhour;

    } else if (realminute < 0) {
        realminute += 60;
        --realhour;
    }

    hourCheck();
    return FOUND;
}

/+ +++++++++++++++++++++++++++++++++++++++ +\

   Privates used by both date and time

\+ +++++++++++++++++++++++++++++++++++++++ +/

private bool accept(T)(ref T* p, char c) {
    if (*p == c) {
        ++p;
        return true;
    }
    return false;
}

private bool demand(T)(ref T* p, char c) {
    return (*p++ == c);
}

private bool done(T)(size_t eaten, size_t srcLen, T p, T[] s) {
    if (eaten == srcLen)
        return true;

    // s is the array of characters which may come next
    // (i.e. which p may be)
    // sorted in ascending order
    foreach (c; s) {
        if (p < c)
            return true;
        else if (p == c)
            break;
    }

    return false;
}

private int daysPerMonth(int month, int year) {
    if (month == 2 && isLeapYear(year))
        return 29;
    else
        return [31,28,31,30,31,30,31,31,30,31,30,31][month-1];
}

/******************************************************************************

        Extract an integer from the input

******************************************************************************/

// note: ISO 8601 code relies on these values always being positive, failing if *p == '-'

private uint parseIntMax(T) (ref T* p) {
    uint value = 0;
    while (*p >= '0' && *p <= '9')
        value = value * 10 + *p++ - '0';
    return value;
}

// ... but accept no more than max digits

private uint parseIntMax(T)(ref T* p, uint max) {
    size_t i = 0;
    uint value = 0;
    while (p[i] >= '0' && p[i] <= '9' && i < max)
        value = value * 10 + p[i++] - '0';
    p += i;
    return value;
}

// ... and return the amount of digits processed

private size_t parseInt(T, U)(ref T* p, out U i) {
    T* p2 = p;
    i = cast(U)parseIntMax(p);
    return p - p2;
}

private size_t parseInt(T, U)(ref T* p, uint max, out U i) {
    T* p2 = p;
    i = cast(U)parseIntMax(p, max);
    return p - p2;
}

////////////////////

debug (UnitTest) {
    import tango.io.Stdout;

    debug(ISO8601)
    {
        void main() { }
    }

    unittest {
        Date date;
        TimeOfDay time;

        // date

        size_t d(char[] s, size_t e = 0) {
            date = date.init;
            return iso8601Date(s, date, e);
        }

        assert (d("20abc") == 2);
        assert (date.year == 2000);

        assert (d("2004") == 4);
        assert (date.year == 2004);

        assert (d("+0019", 2) == 5);
        assert (date.year == 1900);

        assert (d("+111985", 2) == 7);
        assert (date.year == 111985);

        assert (d("+111985", 1) == 6);
        assert (date.year == 11198);

        assert (d("+111985", 3) == 0);
        assert (!date.year);

        assert (d("+111985", 4) == 7);
        assert (date.year == 11198500);

        assert (d("-111985", 5) == 0);
        assert (!date.year);

        assert (d("abc") == 0);
        assert (!date.year);

        assert (d("abc123") == 0);
        assert (!date.year);

        assert (d("2007-08") == 7);
        assert (date.year  == 2007);
        assert (date.month ==    8);

        assert (d("+001985-04", 2) == 10);
        assert (date.year  == 1985);
        assert (date.month ==    4);

        assert (d("2007-08-07") == 10);
        assert (date.year  == 2007);
        assert (date.month ==    8);
        assert (date.day   ==    7);

        assert (d("2008-20-30") == 4);
        assert (date.year == 2008);
        assert (!date.month);

        assert (d("2007-02-30") == 7);
        assert (date.year  == 2007);
        assert (date.month ==    2);

        assert (d("20060708") == 8);
        assert (date.year  == 2006);
        assert (date.month ==    7);
        assert (date.day   ==    8);

        assert (d("19953080") == 4);
        assert (date.year == 1995);
        assert (!date.month);

        assert (d("+001985-04-12", 2) == 13);
        assert (date.year  == 1985);
        assert (date.month ==    4);
        assert (date.day   ==   12);

        assert (d("-0123450607", 2) == 11);
        assert (date.year  == -12345);
        assert (date.month ==      6);
        assert (date.day   ==      7);

        assert (d("1985W15") == 7);
        assert (date.year  == 1985);
        assert (date.month ==    4);
        assert (date.day   ==    8);

        assert (d("2008-W01") == 8);
        assert (date.year  == 2007);
        assert (date.month ==   12);
        assert (date.day   ==   31);

        assert (d("2008-W01-2") == 10);
        assert (date.year  == 2008);
        assert (date.month ==    1);
        assert (date.day   ==    1);

        assert (d("2009-W53-4") == 10);
        assert (date.year  == 2009);
        assert (date.month ==   12);
        assert (date.day   ==   31);

        assert (d("2009-W01-1") == 10);
        assert (date.year  == 2008);
        assert (date.month ==   12);
        assert (date.day   ==   29);

        assert (d("2009W537") == 8);
        assert (date.year  == 2010);
        assert (date.month ==    1);
        assert (date.day   ==    3);

        assert (d("2010W537") == 4);
        assert (date.year  == 2010);
        assert (!date.month);

        assert (d("2009-W01-3") == 10);
        assert (date.year  == 2008);
        assert (date.month ==   12);
        assert (date.day   ==   31);

        assert (d("2009-W01-4") == 10);
        assert (date.year  == 2009);
        assert (date.month ==    1);
        assert (date.day   ==    1);

        /+ BUG: these don't work due to dayOfWeek being crap

        assert (d("1000-W07-7") == 10);
        assert (date.year  == 1000);
        assert (date.month ==    2);
        assert (date.day   ==   16);

        assert (d("1500-W11-1") == 10);
        assert (date.year  == 1500);
        assert (date.month ==    3);
        assert (date.day   ==   12);

        assert (d("1700-W14-2") == 10);
        assert (date.year  == 1700);
        assert (date.month ==    4);
        assert (date.day   ==    6);

        assert (d("1800-W19-3") == 10);
        assert (date.year  == 1800);
        assert (date.month ==    5);
        assert (date.day   ==    7);

        assert (d("1900-W25-4") == 10);
        assert (date.year  == 1900);
        assert (date.month ==    6);
        assert (date.day   ==   21);

        assert (d("0900-W27-5") == 10);
        assert (date.year  ==  900);
        assert (date.month ==    7);
        assert (date.day   ==    9);

        assert (d("0800-W33-6") == 10);
        assert (date.year  ==  800);
        assert (date.month ==    8);
        assert (date.day   ==   19);

        assert (d("0700-W37-7") == 10);
        assert (date.year  ==  700);
        assert (date.month ==    9);
        assert (date.day   ==   16);

        assert (d("0600-W41-4") == 10);
        assert (date.year  ==  600);
        assert (date.month ==   10);
        assert (date.day   ==    9);

        assert (d("0500-W45-7") == 10);
        assert (date.year  ==  500);
        assert (date.month ==   11);
        assert (date.day   ==   14);+/

        assert (d("2000-W55") == 4);
        assert (date.year == 2000);

        assert (d("1980-002") == 8);
        assert (date.year  == 1980);
        assert (date.month ==    1);
        assert (date.day   ==    2);

        assert (d("1981-034") == 8);
        assert (date.year  == 1981);
        assert (date.month ==    2);
        assert (date.day   ==    3);

        assert (d("1982-063") == 8);
        assert (date.year  == 1982);
        assert (date.month ==    3);
        assert (date.day   ==    4);

        assert (d("1983-095") == 8);
        assert (date.year  == 1983);
        assert (date.month ==    4);
        assert (date.day   ==    5);

        assert (d("1984-127") == 8);
        assert (date.year  == 1984);
        assert (date.month ==    5);
        assert (date.day   ==    6);

        assert (d("1985-158") == 8);
        assert (date.year  == 1985);
        assert (date.month ==    6);
        assert (date.day   ==    7);

        assert (d("1986-189") == 8);
        assert (date.year  == 1986);
        assert (date.month ==    7);
        assert (date.day   ==    8);

        assert (d("1987-221") == 8);
        assert (date.year  == 1987);
        assert (date.month ==    8);
        assert (date.day   ==    9);

        assert (d("1988-254") == 8);
        assert (date.year  == 1988);
        assert (date.month ==    9);
        assert (date.day   ==   10);

        assert (d("1989-284") == 8);
        assert (date.year  == 1989);
        assert (date.month ==   10);
        assert (date.day   ==   11);

        assert (d("1990316") == 7);
        assert (date.year  == 1990);
        assert (date.month ==   11);
        assert (date.day   ==   12);

        assert (d("1991-347") == 8);
        assert (date.year  == 1991);
        assert (date.month ==   12);
        assert (date.day   ==   13);

        assert (d("1992-000") == 4);
        assert (date.year == 1992);

        assert (d("1993-370") == 4);
        assert (date.year == 1993);

        // time

        size_t t(char[] s) {
            time = time.init;
            date = date.init;

            return iso8601Time(s, date, time);
        }

        assert (t("20") == 2);
        assert (time.hours == 20);
        assert (time.minutes  ==  0);
        assert (time.seconds  ==  0);

        assert (t("30") == 0);

        assert (t("2004") == 4);
        assert (time.hours == 20);
        assert (time.minutes  ==  4);
        assert (time.seconds  ==  0);

        assert (t("200406") == 6);
        assert (time.hours == 20);
        assert (time.minutes  ==  4);
        assert (time.seconds  ==  6);

        assert (t("24:00") == 5);
        assert (time.hours == 24); // should compare equal with 0... can't just set to 0, loss of information
        assert (time.minutes  ==  0);
        assert (time.seconds  ==  0);

        assert (t("00:00") == 5);
        assert (time.hours == 0);
        assert (time.minutes  == 0);
        assert (time.seconds  == 0);

        assert (t("23:59:60") == 8);
        assert (time.hours == 23);
        assert (time.minutes  == 59);
        assert (time.seconds  == 60); // leap second

        assert (t("16:49:30,001") == 12);
        assert (time.hours == 16);
        assert (time.minutes  == 49);
        assert (time.seconds  == 30);
        assert (time.millis   ==  1);

        assert (t("15:48:29,1") == 10);
        assert (time.hours ==  15);
        assert (time.minutes  ==  48);
        assert (time.seconds  ==  29);
        assert (time.millis   == 100);

        assert (t("02:10:34,a") ==  8);
        assert (time.hours ==  2);
        assert (time.minutes  == 10);
        assert (time.seconds  == 34);

        assert (t("14:50,5") == 7);
        assert (time.hours == 14);
        assert (time.minutes  == 50);
        assert (time.seconds  == 30);

        assert (t("1540,4") == 6);
        assert (time.hours == 15);
        assert (time.minutes  == 40);
        assert (time.seconds  == 24);

        assert (t("1250,") == 4);
        assert (time.hours == 12);
        assert (time.minutes  == 50);

        assert (t("14,5") == 4);
        assert (time.hours == 14);
        assert (time.minutes  == 30);

        assert (t("12,") == 2);
        assert (time.hours == 12);
        assert (time.minutes  ==  0);

        assert (t("24:00:01") == 5);
        assert (time.hours == 24);
        assert (time.minutes  ==  0);
        assert (time.seconds  ==  0);

        assert (t("12:34+:56") == 5);
        assert (time.hours == 12);
        assert (time.minutes  == 34);
        assert (time.seconds  ==  0);

        // just convert to UTC time for time zones?

        assert (t("14:45:15Z") == 9);
        assert (time.hours == 14);
        assert (time.minutes  == 45);
        assert (time.seconds  == 15);

        assert (t("23Z") == 3);
        assert (time.hours == 23);
        assert (time.minutes  ==  0);
        assert (time.seconds  ==  0);

        assert (t("21:32:43-12:34") == 14);
        assert (time.hours == 10);
        assert (time.minutes  ==  6);
        assert (time.seconds  == 43);

        assert (t("12:34,5+0000") == 12);
        assert (time.hours == 12);
        assert (time.minutes  == 34);
        assert (time.seconds  == 30);

        assert (t("03:04+07") == 8);
        assert (time.hours == 20);
        assert (time.minutes  ==  4);
        assert (time.seconds  ==  0);

        assert (t("11,5+") == 4);
        assert (time.hours == 11);
        assert (time.minutes  == 30);

        assert (t("07-") == 2);
        assert (time.hours == 7);

        assert (t("06:12,7-") == 7);
        assert (time.hours ==  6);
        assert (time.minutes  == 12);
        assert (time.seconds  == 42);

        assert (t("050403,2+") == 8);
        assert (time.hours ==   5);
        assert (time.minutes  ==   4);
        assert (time.seconds  ==   3);
        assert (time.millis   == 200);

        assert (t("061656-") == 6);
        assert (time.hours ==   6);
        assert (time.minutes  ==  16);
        assert (time.seconds  ==  56);

        // date and time together

        size_t b(char[] s) {
            date = date.init;
                        time = time.init;
            return iso8601(s, date, time);
        }

        assert (b("2007-08-09T12:34:56") == 19);
        assert (date.year  == 2007);
        assert (date.month ==    8);
        assert (date.day   ==    9);
        assert (time.hours  ==   12);
        assert (time.minutes   ==   34);
        assert (time.seconds   ==   56);

        assert (b("1985W155T235030,768") == 19);
        assert (date.year  == 1985);
        assert (date.month ==    4);
        assert (date.day   ==   12);
        assert (time.hours  ==   23);
        assert (time.minutes   ==   50);
        assert (time.seconds   ==   30);
        assert (time.millis    ==  768);

        // just convert to UTC time for time zones?

        assert (b("2009-08-07T01:02:03Z") == 20);
        assert (date.year  == 2009);
        assert (date.month ==    8);
        assert (date.day   ==    7);
        assert (time.hours  ==    1);
        assert (time.minutes   ==    2);
        assert (time.seconds   ==    3);

        assert (b("2007-08-09T03:02,5+04:56") == 24);
        assert (date.year  == 2007);
        assert (date.month ==    8);
        assert (date.day   ==    8);
        assert (time.hours  ==   22);
        assert (time.minutes   ==    6);
        assert (time.seconds   ==   30);

        assert (b("20000228T2330-01") == 16);
        assert (date.year  == 2000);
        assert (date.month ==    2);
        assert (date.day   ==   29);
        assert (time.hours  ==    0);
        assert (time.minutes   ==   30);
        assert (time.seconds   ==    0);
        
        assert (b("2007-01-01T00:00+01") == 19);
        assert (date.year  == 2006);
        assert (date.month ==   12);
        assert (date.day   ==   31);
        assert (time.hours  ==   23);
        assert (time.minutes   ==    0);
        assert (time.seconds   ==    0);

        assert (b("2007-12-31T23:00-01") == 19);
        assert (date.year  == 2007);
        assert (date.month ==   12);
        assert (date.day   ==   31);
        assert (time.hours  ==   24);
        assert (time.minutes   ==    0);
        assert (time.seconds   ==    0);

        assert (b("2007-12-31T23:01-01") == 19);
        assert (date.year  == 2008);
        assert (date.month ==    1);
        assert (date.day   ==    1);
        assert (time.hours  ==    0);
        assert (time.minutes   ==    1);
        assert (time.seconds   ==    0);

        assert (b("1902-03-04T1a") == 0);
        assert (b("1902-03-04T10:aa") == 0);
        assert (b("1902-03-04T10:1aa") == 0);
        assert (b("1985-04-12T10:15:30+0400") == 0);
        assert (b("1985-04-12T10:15:30-05:4") == 0);
        assert (b("1985-04-12T10:15:30-06:4b") == 0);
        assert (b("19020304T05:06:07") == 0);
        assert (b("1902-03-04T050607") == 0);
        assert (b("19020304T05:06:07abcd") == 0);
        assert (b("1902-03-04T050607abcd") == 0);

        // unimplemented: intervals, durations, recurring intervals
    }
}
