
// Written in the D programming language.

/**
 * Dates are represented in several formats. The date implementation revolves
 * around a central type, d_time, from which other formats are converted to and
 * from.
 * Dates are calculated using the Gregorian calendar.
 * References:
 *	$(LINK2 http://en.wikipedia.org/wiki/Gregorian_calendar, Gregorian calendar (Wikipedia))
 * Macros:
 *	WIKI = Phobos/StdDate
 */

// Copyright (c) 1999-2007 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// www.digitalmars.com

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, May 2005
*/

module std.date;

private import std.stdio;
private import std.dateparse;

/**
 * d_time is a signed arithmetic type giving the time elapsed since January 1,
 * 1970.
 * Negative values are for dates preceding 1970. The time unit used is Ticks.
 * Ticks are milliseconds or smaller intervals.
 *
 * The usual arithmetic operations can be performed on d_time, such as adding,
 * subtracting, etc. Elapsed time in Ticks can be computed by subtracting a
 * starting d_time from an ending d_time. 
 */
alias long d_time;

/**
 * A value for d_time that does not represent a valid time.
 */
const d_time d_time_nan = long.min;

/**
 * Time broken down into its components.
 */
struct Date
{
    int year = int.min;	/// use int.min as "nan" year value
    int month;		/// 1..12
    int day;		/// 1..31
    int hour;		/// 0..23
    int minute;		/// 0..59
    int second;		/// 0..59
    int ms;		/// 0..999
    int weekday;	/// 0: not specified, 1..7: Sunday..Saturday
    int tzcorrection = int.min;	/// -1200..1200 correction in hours

    /// Parse date out of string s[] and store it in this Date instance.
    void parse(string s)
    {
	DateParse dp;

	dp.parse(s, *this);
    }
}

enum
{
	HoursPerDay    = 24,
	MinutesPerHour = 60,
	msPerMinute    = 60 * 1000,
	msPerHour      = 60 * msPerMinute,
	msPerDay       = 86400000,
	TicksPerMs     = 1,
	TicksPerSecond = 1000,			/// Will be at least 1000
	TicksPerMinute = TicksPerSecond * 60,
	TicksPerHour   = TicksPerMinute * 60,
	TicksPerDay    = TicksPerHour   * 24,
}

d_time LocalTZA = 0;


const char[] daystr = "SunMonTueWedThuFriSat";
const char[] monstr = "JanFebMarAprMayJunJulAugSepOctNovDec";

const int[12] mdays = [ 0,31,59,90,120,151,181,212,243,273,304,334 ];

/********************************
 * Compute year and week [1..53] from t. The ISO 8601 week 1 is the first week
 * of the year that includes January 4. Monday is the first day of the week.
 * References:
 *	$(LINK2 http://en.wikipedia.org/wiki/ISO_8601, ISO 8601 (Wikipedia))
 */

void toISO8601YearWeek(d_time t, out int year, out int week)
{
    year = YearFromTime(t);

    int yday = Day(t) - DayFromYear(year);
    int d;
    int w;
    int ydaybeg;

    /* Determine day of week Jan 4 falls on.
     * Weeks begin on a Monday.
     */

    d = DayFromYear(year);
    w = (d + 3/*Jan4*/ + 3) % 7;
    if (w < 0)
        w += 7;

    /* Find yday of beginning of ISO 8601 year
     */
    ydaybeg = 3/*Jan4*/ - w;

    /* Check if yday is actually the last week of the previous year
     */
    if (yday < ydaybeg)
    {
	year -= 1;
	week = 53;
        return;
    }

    /* Check if yday is actually the first week of the next year
     */
    if (yday >= 362)                            // possible
    {   int d2;
        int ydaybeg2;

        d2 = DayFromYear(year + 1);
        w = (d2 + 3/*Jan4*/ + 3) % 7;
        if (w < 0)
            w += 7;
        //printf("w = %d\n", w);
        ydaybeg2 = 3/*Jan4*/ - w;
        if (d + yday >= d2 + ydaybeg2)
        {
	    year += 1;
	    week = 1;
            return;
        }
    }

    week = (yday - ydaybeg) / 7 + 1;
}

/* ***********************************
 * Divide time by divisor. Always round down, even if d is negative.
 */

d_time floor(d_time d, int divisor)
{
    if (d < 0)
	d -= divisor - 1;
    return d / divisor;
}

int dmod(d_time n, d_time d)
{   d_time r;

    r = n % d;
    if (r < 0)
	r += d;
    assert(cast(int)r == r);
    return cast(int)r;
}

int HourFromTime(d_time t)
{
    return dmod(floor(t, msPerHour), HoursPerDay);
}

int MinFromTime(d_time t)
{
    return dmod(floor(t, msPerMinute), MinutesPerHour);
}

int SecFromTime(d_time t)
{
    return dmod(floor(t, TicksPerSecond), 60);
}

int msFromTime(d_time t)
{
    return dmod(t / (TicksPerSecond / 1000), 1000);
}

int TimeWithinDay(d_time t)
{
    return dmod(t, msPerDay);
}

d_time toInteger(d_time n)
{
    return n;
}

int Day(d_time t)
{
    return cast(int)floor(t, msPerDay);
}

int LeapYear(int y)
{
    return ((y & 3) == 0 &&
	    (y % 100 || (y % 400) == 0));
}

int DaysInYear(int y)
{
    return 365 + LeapYear(y);
}

int DayFromYear(int y)
{
    return cast(int) (365 * (y - 1970) +
		floor((y - 1969), 4) -
		floor((y - 1901), 100) +
		floor((y - 1601), 400));
}

d_time TimeFromYear(int y)
{
    return cast(d_time)msPerDay * DayFromYear(y);
}

/*****************************
 * Calculates the year from the d_time t.
 */

int YearFromTime(d_time t)
{   int y;

    if (t == d_time_nan)
	return 0;

    // Hazard a guess
    //y = 1970 + cast(int) (t / (365.2425 * msPerDay));
    // Use integer only math
    y = 1970 + cast(int) (t / (3652425 * (msPerDay / 10000)));

    if (TimeFromYear(y) <= t)
    {
	while (TimeFromYear(y + 1) <= t)
	    y++;
    }
    else
    {
	do
	{
	    y--;
	}
	while (TimeFromYear(y) > t);
    }
    return y;
}

/*******************************
 * Determines if d_time t is a leap year.
 *
 * A leap year is every 4 years except years ending in 00 that are not
 * divsible by 400.
 *
 * Returns: !=0 if it is a leap year.
 *
 * References:
 *	$(LINK2 http://en.wikipedia.org/wiki/Leap_year, Wikipedia)
 */

int inLeapYear(d_time t)
{
    return LeapYear(YearFromTime(t));
}

/*****************************
 * Calculates the month from the d_time t.
 *
 * Returns: Integer in the range 0..11, where
 *	0 represents January and 11 represents December.
 */

int MonthFromTime(d_time t)
{
    int day;
    int month;
    int year;

    year = YearFromTime(t);
    day = Day(t) - DayFromYear(year);

    if (day < 59)
    {
	if (day < 31)
	{   assert(day >= 0);
	    month = 0;
	}
	else
	    month = 1;
    }
    else
    {
	day -= LeapYear(year);
	if (day < 212)
	{
	    if (day < 59)
		month = 1;
	    else if (day < 90)
		month = 2;
	    else if (day < 120)
		month = 3;
	    else if (day < 151)
		month = 4;
	    else if (day < 181)
		month = 5;
	    else
		month = 6;
	}
	else
	{
	    if (day < 243)
		month = 7;
	    else if (day < 273)
		month = 8;
	    else if (day < 304)
		month = 9;
	    else if (day < 334)
		month = 10;
	    else if (day < 365)
		month = 11;
	    else
		assert(0);
	}
    }
    return month;
}

/*******************************
 * Compute which day in a month a d_time t is.
 * Returns:
 *	Integer in the range 1..31
 */
int DateFromTime(d_time t)
{
    int day;
    int leap;
    int month;
    int year;
    int date;

    year = YearFromTime(t);
    day = Day(t) - DayFromYear(year);
    leap = LeapYear(year);
    month = MonthFromTime(t);
    switch (month)
    {
	case 0:	 date = day +   1;		break;
	case 1:	 date = day -  30;		break;
	case 2:	 date = day -  58 - leap;	break;
	case 3:	 date = day -  89 - leap;	break;
	case 4:	 date = day - 119 - leap;	break;
	case 5:	 date = day - 150 - leap;	break;
	case 6:	 date = day - 180 - leap;	break;
	case 7:	 date = day - 211 - leap;	break;
	case 8:	 date = day - 242 - leap;	break;
	case 9:	 date = day - 272 - leap;	break;
	case 10: date = day - 303 - leap;	break;
	case 11: date = day - 333 - leap;	break;
	default:
	    assert(0);
    }
    return date;
}

/*******************************
 * Compute which day of the week a d_time t is.
 * Returns:
 *	Integer in the range 0..6, where 0 represents Sunday
 *	and 6 represents Saturday.
 */
int WeekDay(d_time t)
{   int w;

    w = (cast(int)Day(t) + 4) % 7;
    if (w < 0)
	w += 7;
    return w;
}

/***********************************
 * Convert from UTC to local time.
 */

d_time UTCtoLocalTime(d_time t)
{
    return (t == d_time_nan)
	? d_time_nan
	: t + LocalTZA + DaylightSavingTA(t);
}

/***********************************
 * Convert from local time to UTC.
 */

d_time LocalTimetoUTC(d_time t)
{
    return (t == d_time_nan)
	? d_time_nan
	: t - LocalTZA - DaylightSavingTA(t - LocalTZA);
}


d_time MakeTime(d_time hour, d_time min, d_time sec, d_time ms)
{
    return hour * TicksPerHour +
	   min * TicksPerMinute +
	   sec * TicksPerSecond +
	   ms * TicksPerMs;
}


d_time MakeDay(d_time year, d_time month, d_time date)
{   d_time t;
    int y;
    int m;
    int leap;

    y = cast(int)(year + floor(month, 12));
    m = dmod(month, 12);

    leap = LeapYear(y);
    t = TimeFromYear(y) + cast(d_time)mdays[m] * msPerDay;
    if (leap && month >= 2)
	t += msPerDay;

    if (YearFromTime(t) != y ||
	MonthFromTime(t) != m ||
	DateFromTime(t) != 1)
    {
	return  d_time_nan;
    }

    return Day(t) + date - 1;
}

d_time MakeDate(d_time day, d_time time)
{
    if (day == d_time_nan || time == d_time_nan)
	return d_time_nan;

    return day * TicksPerDay + time;
}

d_time TimeClip(d_time time)
{
    //printf("TimeClip(%g) = %g\n", time, toInteger(time));

    return toInteger(time);
}

/*************************************
 * Converts UTC time into a text string of the form:
 * "Www Mmm dd hh:mm:ss GMT+-TZ yyyy".
 * For example, "Tue Apr 02 02:04:57 GMT-0800 1996".
 * If time is invalid, i.e. is d_time_nan,
 * the string "Invalid date" is returned.
 *
 * Example:
 * ------------------------------------
  d_time lNow;
  char[] lNowString;

  // Grab the date and time relative to UTC
  lNow = std.date.getUTCtime();
  // Convert this into the local date and time for display.
  lNowString = std.date.toString(lNow);
 * ------------------------------------
 */

string toString(d_time time)
{
    d_time t;
    char sign;
    int hr;
    int mn;
    int len;
    d_time offset;
    d_time dst;

    // Years are supposed to be -285616 .. 285616, or 7 digits
    // "Tue Apr 02 02:04:57 GMT-0800 1996"
    char[] buffer = new char[29 + 7 + 1];

    if (time == d_time_nan)
	return "Invalid Date";

    dst = DaylightSavingTA(time);
    offset = LocalTZA + dst;
    t = time + offset;
    sign = '+';
    if (offset < 0)
    {	sign = '-';
//	offset = -offset;
	offset = -(LocalTZA + dst);
    }

    mn = cast(int)(offset / msPerMinute);
    hr = mn / 60;
    mn %= 60;

    //printf("hr = %d, offset = %g, LocalTZA = %g, dst = %g, + = %g\n", hr, offset, LocalTZA, dst, LocalTZA + dst);

    len = sprintf(buffer.ptr, "%.3s %.3s %02d %02d:%02d:%02d GMT%c%02d%02d %d",
	&daystr[WeekDay(t) * 3],
	&monstr[MonthFromTime(t) * 3],
	DateFromTime(t),
	HourFromTime(t), MinFromTime(t), SecFromTime(t),
	sign, hr, mn,
	/*cast(long)*/YearFromTime(t));

    // Ensure no buggy buffer overflows
    //printf("len = %d, buffer.length = %d\n", len, buffer.length);
    assert(len < buffer.length);

    return buffer[0 .. len];
}

/***********************************
 * Converts t into a text string of the form: "Www, dd Mmm yyyy hh:mm:ss UTC".
 * If t is invalid, "Invalid date" is returned.
 */

string toUTCString(d_time t)
{
    // Years are supposed to be -285616 .. 285616, or 7 digits
    // "Tue, 02 Apr 1996 02:04:57 GMT"
    char[] buffer = new char[25 + 7 + 1];
    int len;

    if (t == d_time_nan)
	return "Invalid Date";

    len = sprintf(buffer.ptr, "%.3s, %02d %.3s %d %02d:%02d:%02d UTC",
	&daystr[WeekDay(t) * 3], DateFromTime(t),
	&monstr[MonthFromTime(t) * 3],
	YearFromTime(t),
	HourFromTime(t), MinFromTime(t), SecFromTime(t));

    // Ensure no buggy buffer overflows
    assert(len < buffer.length);

    return buffer[0 .. len];
}

/************************************
 * Converts the date portion of time into a text string of the form: "Www Mmm dd
 * yyyy", for example, "Tue Apr 02 1996".
 * If time is invalid, "Invalid date" is returned.
 */

string toDateString(d_time time)
{
    d_time t;
    d_time offset;
    d_time dst;
    int len;

    // Years are supposed to be -285616 .. 285616, or 7 digits
    // "Tue Apr 02 1996"
    char[] buffer = new char[29 + 7 + 1];

    if (time == d_time_nan)
	return "Invalid Date";

    dst = DaylightSavingTA(time);
    offset = LocalTZA + dst;
    t = time + offset;

    len = sprintf(buffer.ptr, "%.3s %.3s %02d %d",
	&daystr[WeekDay(t) * 3],
	&monstr[MonthFromTime(t) * 3],
	DateFromTime(t),
	/*cast(long)*/YearFromTime(t));

    // Ensure no buggy buffer overflows
    assert(len < buffer.length);

    return buffer[0 .. len];
}

/******************************************
 * Converts the time portion of t into a text string of the form: "hh:mm:ss
 * GMT+-TZ", for example, "02:04:57 GMT-0800".
 * If t is invalid, "Invalid date" is returned.
 * The input must be in UTC, and the output is in local time.
 */

string toTimeString(d_time time)
{
    d_time t;
    char sign;
    int hr;
    int mn;
    int len;
    d_time offset;
    d_time dst;

    // "02:04:57 GMT-0800"
    char[] buffer = new char[17 + 1];

    if (time == d_time_nan)
	return "Invalid Date";

    dst = DaylightSavingTA(time);
    offset = LocalTZA + dst;
    t = time + offset;
    sign = '+';
    if (offset < 0)
    {	sign = '-';
//	offset = -offset;
	offset = -(LocalTZA + dst);
    }

    mn = cast(int)(offset / msPerMinute);
    hr = mn / 60;
    mn %= 60;

    //printf("hr = %d, offset = %g, LocalTZA = %g, dst = %g, + = %g\n", hr, offset, LocalTZA, dst, LocalTZA + dst);

    len = sprintf(buffer.ptr, "%02d:%02d:%02d GMT%c%02d%02d",
	HourFromTime(t), MinFromTime(t), SecFromTime(t),
	sign, hr, mn);

    // Ensure no buggy buffer overflows
    assert(len < buffer.length);

    // Lop off terminating 0
    return buffer[0 .. len];
}


/******************************************
 * Parses s as a textual date string, and returns it as a d_time.
 * If the string is not a valid date, d_time_nan is returned.
 */

d_time parse(string s)
{
    Date dp;
    d_time n;
    d_time day;
    d_time time;

    try
    {
	dp.parse(s);

	//writefln("year = %d, month = %d, day = %d", dp.year, dp.month, dp.day);
	//writefln("%02d:%02d:%02d.%03d", dp.hour, dp.minute, dp.second, dp.ms);
	//writefln("weekday = %d, ampm = %d, tzcorrection = %d", dp.weekday, 1, dp.tzcorrection);

	time = MakeTime(dp.hour, dp.minute, dp.second, dp.ms);
	if (dp.tzcorrection == int.min)
	    time -= LocalTZA;
	else
	{
	    time += cast(d_time)(dp.tzcorrection / 100) * msPerHour +
		    cast(d_time)(dp.tzcorrection % 100) * msPerMinute;
	}
	day = MakeDay(dp.year, dp.month - 1, dp.day);
	n = MakeDate(day,time);
	n = TimeClip(n);
    }
    catch
    {
	n =  d_time_nan;		// erroneous date string
    }
    return n;
}

static this()
{
    LocalTZA = getLocalTZA();
    //printf("LocalTZA = %g, %g\n", LocalTZA, LocalTZA / msPerHour);
}

version (Win32)
{

    private import std.c.windows.windows;
    //import c.time;

    /******
     * Get current UTC time.
     */
    d_time getUTCtime()
    {
	SYSTEMTIME st;
	d_time n;

	GetSystemTime(&st);		// get time in UTC
	n = SYSTEMTIME2d_time(&st, 0);
	return n;
	//return c.time.time(null) * TicksPerSecond;
    }

    static d_time FILETIME2d_time(FILETIME *ft)
    {   SYSTEMTIME st;

	if (!FileTimeToSystemTime(ft, &st))
	    return d_time_nan;
	return SYSTEMTIME2d_time(&st, 0);
    }

    static d_time SYSTEMTIME2d_time(SYSTEMTIME *st, d_time t)
    {
	d_time n;
	d_time day;
	d_time time;

	if (st.wYear)
	{
	    time = MakeTime(st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
	    day = MakeDay(st.wYear, st.wMonth - 1, st.wDay);
	}
	else
	{   // wDayOfWeek is weekday, wDay is which week in the month
	    int year;
	    int wd;
	    int mday;
	    int month;
	    d_time x;

	    year = YearFromTime(t);
	    month = st.wMonth - 1;
	    x = MakeDay(year, month, 1);
	    wd = WeekDay(MakeDate(x, 0));

	    mday = (7 - wd + st.wDayOfWeek);
	    if (mday >= 7)
		mday -= 7;
	    mday += (st.wDay - 1) * 7 + 1;
	    //printf("month = %d, wDayOfWeek = %d, wDay = %d, mday = %d\n", st.wMonth, st.wDayOfWeek, st.wDay, mday);

	    day = MakeDay(year, month, mday);
	    time = 0;
	}
	n = MakeDate(day,time);
	n = TimeClip(n);
	return n;
    }

    d_time getLocalTZA()
    {
	d_time t;
	DWORD r;
	TIME_ZONE_INFORMATION tzi;

	/* http://msdn.microsoft.com/library/en-us/sysinfo/base/gettimezoneinformation.asp
	 * http://msdn2.microsoft.com/en-us/library/ms725481.aspx
	 */
	r = GetTimeZoneInformation(&tzi);
	//printf("bias = %d\n", tzi.Bias);
	//printf("standardbias = %d\n", tzi.StandardBias);
	//printf("daylightbias = %d\n", tzi.DaylightBias);
	switch (r)
	{
	    case TIME_ZONE_ID_STANDARD:
		t = -(tzi.Bias + tzi.StandardBias) * cast(d_time)(60 * TicksPerSecond);
		break;
	    case TIME_ZONE_ID_DAYLIGHT:
		//t = -(tzi.Bias + tzi.DaylightBias) * cast(d_time)(60 * TicksPerSecond);
		//break;
	    case TIME_ZONE_ID_UNKNOWN:
		t = -(tzi.Bias) * cast(d_time)(60 * TicksPerSecond);
		break;

	    default:
		t = 0;
		break;
	}

	return t;
    }

    /*
     * Get daylight savings time adjust for time dt.
     */

    int DaylightSavingTA(d_time dt)
    {
	int t;
	DWORD r;
	TIME_ZONE_INFORMATION tzi;
	d_time ts;
	d_time td;

	/* http://msdn.microsoft.com/library/en-us/sysinfo/base/gettimezoneinformation.asp
	 */
	r = GetTimeZoneInformation(&tzi);
	t = 0;
	switch (r)
	{
	    case TIME_ZONE_ID_STANDARD:
	    case TIME_ZONE_ID_DAYLIGHT:
		if (tzi.StandardDate.wMonth == 0 ||
		    tzi.DaylightDate.wMonth == 0)
		    break;

		ts = SYSTEMTIME2d_time(&tzi.StandardDate, dt);
		td = SYSTEMTIME2d_time(&tzi.DaylightDate, dt);

		if (td <= dt && dt <= ts)
		{
		    t = -tzi.DaylightBias * (60 * TicksPerSecond);
		    //printf("DST is in effect, %d\n", t);
		}
		else
		{
		    //printf("no DST\n");
		}
		break;

	    case TIME_ZONE_ID_UNKNOWN:
		// Daylight savings time not used in this time zone
		break;

	    default:
		assert(0);
	}
	return t;
    }
}
else version (Unix)
{
    // for now, just copy linux
    private import std.c.unix.unix;

    d_time getUTCtime()
    {   timeval tv;

	if (gettimeofday(&tv, null))
	{   // Some error happened - try time() instead
	    return time(null) * TicksPerSecond;
	}

	return tv.tv_sec * cast(d_time)TicksPerSecond +
		(tv.tv_usec / (1000000 / cast(d_time)TicksPerSecond));
    }

    private extern (C) time_t _d_gnu_cbridge_tza();
    
    d_time getLocalTZA()
    {
	return _d_gnu_cbridge_tza() * TicksPerSecond;
    }

    /*
     * Get daylight savings time adjust for time dt.
     */

    int DaylightSavingTA(d_time dt)
    {
	tm *tmp;
	time_t t;
	int dst = 0;

	if (dt != d_time_nan)
	{
	    d_time seconds = dt / TicksPerSecond;
	    t = cast(time_t) seconds;
	    if (t == seconds)	// if in range
	    {
		tmp = localtime(&t);
		if (tmp.tm_isdst > 0)
		    dst = TicksPerHour;	// BUG: Assume daylight savings time is plus one hour.
	    }
	    else	// out of range for system time, use our own calculation
	    {	// Daylight savings time goes from 2 AM the first Sunday
		// in April through 2 AM the last Sunday in October

		dt -= LocalTZA;

		int year = YearFromTime(dt);
		int leap = LeapYear(cast(int)dt);
		//writefln("year = %s, leap = %s, month = %s", year, leap, MonthFromTime(dt));

		d_time start = TimeFromYear(year);		// Jan 1
		d_time end = start;
		// Move fwd to Apr 1
		start += cast(d_time)(mdays[3] + leap) * TicksPerDay;
		// Advance a day at a time until we find Sunday (0)
		while (WeekDay(start) != 0)
		    start += TicksPerDay;

		// Move fwd to Oct 30
		end += cast(d_time)(mdays[9] + leap + 30) * TicksPerDay;
		// Back up a day at a time until we find Sunday (0)
		while (WeekDay(end) != 0)		// 0 is Sunday
		    end -= TicksPerDay;

		dt -= 2 * TicksPerHour;			// 2 AM
		if (dt >= start && dt <= end)
		    dst = TicksPerHour;
		//writefln("start = %s, dt = %s, end = %s, dst = %s", start, dt, end, dst);
	    }
	}
	return dst;
    }
}
else version (linux)
{

    private import std.c.linux.linux;

    d_time getUTCtime()
    {   timeval tv;

	//printf("getUTCtime()\n");
	if (gettimeofday(&tv, null))
	{   // Some error happened - try time() instead
	    return time(null) * TicksPerSecond;
	}

	return tv.tv_sec * cast(d_time)TicksPerSecond +
		(tv.tv_usec / (1000000 / cast(d_time)TicksPerSecond));
    }

    d_time getLocalTZA()
    {
	int t;

	time(&t);
	localtime(&t);	// this will set timezone
	return -(timezone * TicksPerSecond);
    }

    /*
     * Get daylight savings time adjust for time dt.
     */

    int DaylightSavingTA(d_time dt)
    {
	tm *tmp;
	int t;
	int dst = 0;

	if (dt != d_time_nan)
	{
	    d_time seconds = dt / TicksPerSecond;
	    t = cast(int) seconds;
	    if (t == seconds)	// if in range
	    {
		tmp = localtime(&t);
		if (tmp.tm_isdst > 0)
		    dst = TicksPerHour;	// BUG: Assume daylight savings time is plus one hour.
	    }
	    else	// out of range for system time, use our own calculation
	    {	// Daylight savings time goes from 2 AM the first Sunday
		// in April through 2 AM the last Sunday in October

		dt -= LocalTZA;

		int year = YearFromTime(dt);
		int leap = LeapYear(dt);
		//writefln("year = %s, leap = %s, month = %s", year, leap, MonthFromTime(dt));

		d_time start = TimeFromYear(year);		// Jan 1
		d_time end = start;
		// Move fwd to Apr 1
		start += cast(d_time)(mdays[3] + leap) * TicksPerDay;
		// Advance a day at a time until we find Sunday (0)
		while (WeekDay(start) != 0)
		    start += TicksPerDay;

		// Move fwd to Oct 30
		end += cast(d_time)(mdays[9] + leap + 30) * TicksPerDay;
		// Back up a day at a time until we find Sunday (0)
		while (WeekDay(end) != 0)		// 0 is Sunday
		    end -= TicksPerDay;

		dt -= 2 * TicksPerHour;			// 2 AM
		if (dt >= start && dt <= end)
		    dst = TicksPerHour;
		//writefln("start = %s, dt = %s, end = %s, dst = %s", start, dt, end, dst);
	    }
	}
	return dst;
    }

}
else version (NoSystem)
{
    d_time getLocalTZA() { return 0; }    
    int DaylightSavingTA(d_time dt) { return 0; }
}

/+ ====================== DOS File Time =============================== +/

/***
 * Type representing the DOS file date/time format.
 */
typedef uint DosFileTime;

/************************************
 * Convert from DOS file date/time to d_time.
 */

d_time toDtime(DosFileTime time)
{
    uint dt = cast(uint)time;

    if (dt == 0)
	return d_time_nan;

    int year = ((dt >> 25) & 0x7F) + 1980;
    int month = ((dt >> 21) & 0x0F) - 1;	// 0..12
    int dayofmonth = ((dt >> 16) & 0x1F);	// 0..31
    int hour = (dt >> 11) & 0x1F;		// 0..23
    int minute = (dt >> 5) & 0x3F;		// 0..59
    int second = (dt << 1) & 0x3E;		// 0..58 (in 2 second increments)

    d_time t;

    t = std.date.MakeDate(std.date.MakeDay(year, month, dayofmonth),
	    std.date.MakeTime(hour, minute, second, 0));

    assert(YearFromTime(t) == year);
    assert(MonthFromTime(t) == month);
    assert(DateFromTime(t) == dayofmonth);
    assert(HourFromTime(t) == hour);
    assert(MinFromTime(t) == minute);
    assert(SecFromTime(t) == second);

    t -= LocalTZA + DaylightSavingTA(t);

    return t;
}

/****************************************
 * Convert from d_time to DOS file date/time.
 */

DosFileTime toDosFileTime(d_time t)
{   uint dt;

    if (t == d_time_nan)
	return cast(DosFileTime)0;

    t += LocalTZA + DaylightSavingTA(t);

    uint year = YearFromTime(t);
    uint month = MonthFromTime(t);
    uint dayofmonth = DateFromTime(t);
    uint hour = HourFromTime(t);
    uint minute = MinFromTime(t);
    uint second = SecFromTime(t);

    dt = (year - 1980) << 25;
    dt |= ((month + 1) & 0x0F) << 21;
    dt |= (dayofmonth & 0x1F) << 16;
    dt |= (hour & 0x1F) << 11;
    dt |= (minute & 0x3F) << 5;
    dt |= (second >> 1) & 0x1F;

    return cast(DosFileTime)dt;
}
