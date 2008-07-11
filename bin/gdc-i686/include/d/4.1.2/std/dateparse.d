
/*
 *  Copyright (C) 1999-2004 by Digital Mars, www.digitalmars.com
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


module std.dateparse;

private
{
    import std.string;
    import std.c.stdlib;
    import std.date;
}

//debug=dateparse;

class DateParseError : Error
{
    this(char[] s)
    {
	super("Invalid date string: " ~ s);
    }
}

struct DateParse
{
    void parse(char[] s, out Date date)
    {
	*this = DateParse.init;

	//version (Win32)
	    buffer = (cast(char *)alloca(s.length))[0 .. s.length];
	//else
	    //buffer = new char[s.length];

	debug(dateparse) printf("DateParse.parse('%.*s')\n",
	    cast(int) s.length, s.ptr);
	if (!parseString(s))
	{
	    goto Lerror;
	}

    /+
	if (year == year.init)
	    year = 0;
	else
    +/
	debug(dateparse)
	    printf("year = %d, month = %d, day = %d\n%02d:%02d:%02d.%03d\nweekday = %d, tzcorrection = %d\n",
		year, month, day,
		hours, minutes, seconds, ms,
		weekday, tzcorrection);
	if (
	    year == year.init ||
	    (month < 1 || month > 12) ||
	    (day < 1 || day > 31) ||
	    (hours < 0 || hours > 23) ||
	    (minutes < 0 || minutes > 59) ||
	    (seconds < 0 || seconds > 59) ||
	    (tzcorrection != int.min &&
	     ((tzcorrection < -2300 || tzcorrection > 2300) ||
	      (tzcorrection % 10)))
	    )
	{
	 Lerror:
	    throw new DateParseError(s);
	}

	if (ampm)
	{   if (hours > 12)
		goto Lerror;
	    if (hours < 12)
	    {
		if (ampm == 2)	// if P.M.
		    hours += 12;
	    }
	    else if (ampm == 1)	// if 12am
	    {
		hours = 0;		// which is midnight
	    }
	}

//	if (tzcorrection != tzcorrection.init)
//	    tzcorrection /= 100;

	if (year >= 0 && year <= 99)
	    year += 1900;

	date.year = year;
	date.month = month;
	date.day = day;
	date.hour = hours;
	date.minute = minutes;
	date.second = seconds;
	date.ms = ms;
	date.weekday = weekday;
	date.tzcorrection = tzcorrection;
    }


private:
    int year = int.min;	// our "nan" Date value
    int month;		// 1..12
    int day;		// 1..31
    int hours;		// 0..23
    int minutes;	// 0..59
    int seconds;	// 0..59
    int ms;		// 0..999
    int weekday;	// 1..7
    int ampm;		// 0: not specified
			// 1: AM
			// 2: PM
    int tzcorrection = int.min;	// -1200..1200 correction in hours

    char[] s;
    int si;
    int number;
    char[] buffer;

    enum DP : byte
    {
	err,
	weekday,
	month,
	number,
	end,
	colon,
	minus,
	slash,
	ampm,
	plus,
	tz,
	dst,
	dsttz,
    }

    DP nextToken()
    {   int nest;
	uint c;
	int bi;
	DP result = DP.err;

	//printf("DateParse::nextToken()\n");
	for (;;)
	{
	    assert(si <= s.length);
	    if (si == s.length)
	    {	result = DP.end;
		goto Lret;
	    }
	    //printf("\ts[%d] = '%c'\n", si, s[si]);
	    switch (s[si])
	    {
		case ':':	result = DP.colon; goto ret_inc;
		case '+':	result = DP.plus;  goto ret_inc;
		case '-':	result = DP.minus; goto ret_inc;
		case '/':	result = DP.slash; goto ret_inc;
		case '.':
		    version(DATE_DOT_DELIM)
		    {
			result = DP.slash;
			goto ret_inc;
		    }
		    else
		    {
			si++;
			break;
		    }

		ret_inc:
		    si++;
		    goto Lret;

		case ' ':
		case '\n':
		case '\r':
		case '\t':
		case ',':
		    si++;
		    break;

		case '(':		// comment
		    nest = 1;
		    for (;;)
		    {
			si++;
			if (si == s.length)
			    goto Lret;		// error
			switch (s[si])
			{
			    case '(':
				nest++;
				break;

			    case ')':
				if (--nest == 0)
				    goto Lendofcomment;
				break;

			    default:
				break;
			}
		    }
		Lendofcomment:
		    si++;
		    break;

		default:
		    number = 0;
		    for (;;)
		    {
			if (si == s.length)
			    // c cannot be undefined here
			    break;
			c = s[si];
			if (!(c >= '0' && c <= '9'))
			    break;
			result = DP.number;
			number = number * 10 + (c - '0');
			si++;
		    }
		    if (result == DP.number)
			goto Lret;

		    bi = 0;
		bufloop:
		    while (c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z')
		    {
			if (c < 'a')		// if upper case
			    c += cast(uint)'a' - cast(uint)'A';	// to lower case
			buffer[bi] = cast(char)c;
			bi++;
			do
			{
			    si++;
			    if (si == s.length)
				break bufloop;
			    c = s[si];
			} while (c == '.');	// ignore embedded '.'s
		    }
		    result = classify(buffer[0 .. bi]);
		    goto Lret;
	    }
	}
    Lret:
	//printf("-DateParse::nextToken()\n");
	return result;
    }

    DP classify(char[] buf)
    {
	struct DateID
	{
	    char[] name;
	    DP tok;
	    short value;
	}

	static DateID dateidtab[] =
	[
	    {   "january",	DP.month,	1},
	    {   "february",	DP.month,	2},
	    {   "march",	DP.month,	3},
	    {   "april",	DP.month,	4},
	    {   "may",		DP.month,	5},
	    {   "june",		DP.month,	6},
	    {   "july",		DP.month,	7},
	    {   "august",	DP.month,	8},
	    {   "september",	DP.month,	9},
	    {   "october",	DP.month,	10},
	    {   "november",	DP.month,	11},
	    {   "december",	DP.month,	12},
	    {   "jan",		DP.month,	1},
	    {   "feb",		DP.month,	2},
	    {   "mar",		DP.month,	3},
	    {   "apr",		DP.month,	4},
	    {   "jun",		DP.month,	6},
	    {   "jul",		DP.month,	7},
	    {   "aug",		DP.month,	8},
	    {   "sep",		DP.month,	9},
	    {   "sept",		DP.month,	9},
	    {   "oct",		DP.month,	10},
	    {   "nov",		DP.month,	11},
	    {   "dec",		DP.month,	12},

	    {   "sunday",	DP.weekday,	1},
	    {   "monday",	DP.weekday,	2},
	    {   "tuesday",	DP.weekday,	3},
	    {   "tues",		DP.weekday,	3},
	    {   "wednesday",	DP.weekday,	4},
	    {   "wednes",	DP.weekday,	4},
	    {   "thursday",	DP.weekday,	5},
	    {   "thur",		DP.weekday,	5},
	    {   "thurs",	DP.weekday,	5},
	    {   "friday",	DP.weekday,	6},
	    {   "saturday",	DP.weekday,	7},

	    {   "sun",		DP.weekday,	1},
	    {   "mon",		DP.weekday,	2},
	    {   "tue",		DP.weekday,	3},
	    {   "wed",		DP.weekday,	4},
	    {   "thu",		DP.weekday,	5},
	    {   "fri",		DP.weekday,	6},
	    {   "sat",		DP.weekday,	7},

	    {   "am",		DP.ampm,		1},
	    {   "pm",		DP.ampm,		2},

	    {   "gmt",		DP.tz,		+000},
	    {   "ut",		DP.tz,		+000},
	    {   "utc",		DP.tz,		+000},
	    {   "wet",		DP.tz,		+000},
	    {   "z",		DP.tz,		+000},
	    {   "wat",		DP.tz,		+100},
	    {   "a",		DP.tz,		+100},
	    {   "at",		DP.tz,		+200},
	    {   "b",		DP.tz,		+200},
	    {   "c",		DP.tz,		+300},
	    {   "ast",		DP.tz,		+400},
	    {   "d",		DP.tz,		+400},
	    {   "est",		DP.tz,		+500},
	    {   "e",		DP.tz,		+500},
	    {   "cst",		DP.tz,		+600},
	    {   "f",		DP.tz,		+600},
	    {   "mst",		DP.tz,		+700},
	    {   "g",		DP.tz,		+700},
	    {   "pst",		DP.tz,		+800},
	    {   "h",		DP.tz,		+800},
	    {   "yst",		DP.tz,		+900},
	    {   "i",		DP.tz,		+900},
	    {   "ahst",		DP.tz,		+1000},
	    {   "cat",		DP.tz,		+1000},
	    {   "hst",		DP.tz,		+1000},
	    {   "k",		DP.tz,		+1000},
	    {   "nt",		DP.tz,		+1100},
	    {   "l",		DP.tz,		+1100},
	    {   "idlw",		DP.tz,		+1200},
	    {   "m",		DP.tz,		+1200},

	    {   "cet",		DP.tz,		-100},
	    {   "fwt",		DP.tz,		-100},
	    {   "met",		DP.tz,		-100},
	    {   "mewt",		DP.tz,		-100},
	    {   "swt",		DP.tz,		-100},
	    {   "n",		DP.tz,		-100},
	    {   "eet",		DP.tz,		-200},
	    {   "o",		DP.tz,		-200},
	    {   "bt",		DP.tz,		-300},
	    {   "p",		DP.tz,		-300},
	    {   "zp4",		DP.tz,		-400},
	    {   "q",		DP.tz,		-400},
	    {   "zp5",		DP.tz,		-500},
	    {   "r",		DP.tz,		-500},
	    {   "zp6",		DP.tz,		-600},
	    {   "s",		DP.tz,		-600},
	    {   "wast",		DP.tz,		-700},
	    {   "t",		DP.tz,		-700},
	    {   "cct",		DP.tz,		-800},
	    {   "u",		DP.tz,		-800},
	    {   "jst",		DP.tz,		-900},
	    {   "v",		DP.tz,		-900},
	    {   "east",		DP.tz,		-1000},
	    {   "gst",		DP.tz,		-1000},
	    {   "w",		DP.tz,		-1000},
	    {   "x",		DP.tz,		-1100},
	    {   "idle",		DP.tz,		-1200},
	    {   "nzst",		DP.tz,		-1200},
	    {   "nzt",		DP.tz,		-1200},
	    {   "y",		DP.tz,		-1200},

	    {   "bst",		DP.dsttz,	000},
	    {   "adt",		DP.dsttz,	+400},
	    {   "edt",		DP.dsttz,	+500},
	    {   "cdt",		DP.dsttz,	+600},
	    {   "mdt",		DP.dsttz,	+700},
	    {   "pdt",		DP.dsttz,	+800},
	    {   "ydt",		DP.dsttz,	+900},
	    {   "hdt",		DP.dsttz,	+1000},
	    {   "mest",		DP.dsttz,	-100},
	    {   "mesz",		DP.dsttz,	-100},
	    {   "sst",		DP.dsttz,	-100},
	    {   "fst",		DP.dsttz,	-100},
	    {   "wadt",		DP.dsttz,	-700},
	    {   "eadt",		DP.dsttz,	-1000},
	    {   "nzdt",		DP.dsttz,	-1200},

	    {   "dst",		DP.dst,		0},
	];

	//message(DTEXT("DateParse::classify('%s')\n"), buf);

	// Do a linear search. Yes, it would be faster with a binary
	// one.
	for (uint i = 0; i < dateidtab.length; i++)
	{
	    if (std.string.cmp(dateidtab[i].name, buf) == 0)
	    {
		number = dateidtab[i].value;
		return dateidtab[i].tok;
	    }
	}
	return DP.err;
    }

    int parseString(char[] s)
    {
	int n1;
	int dp;
	int sisave;
	int result;

	//message(DTEXT("DateParse::parseString('%ls')\n"), s);
	this.s = s;
	si = 0;
	dp = nextToken();
	for (;;)
	{
	    //message(DTEXT("\tdp = %d\n"), dp);
	    switch (dp)
	    {
		case DP.end:
		    result = 1;
		Lret:
		    return result;

		case DP.err:
		case_error:
		    //message(DTEXT("\terror\n"));
		default:
		    result = 0;
		    goto Lret;

		case DP.minus:
		    break;			// ignore spurious '-'

		case DP.weekday:
		    weekday = number;
		    break;

		case DP.month:		// month day, [year]
		    month = number;
		    dp = nextToken();
		    if (dp == DP.number)
		    {
			day = number;
			sisave = si;
			dp = nextToken();
			if (dp == DP.number)
			{
			    n1 = number;
			    dp = nextToken();
			    if (dp == DP.colon)
			    {   // back up, not a year
				si = sisave;
			    }
			    else
			    {   year = n1;
				continue;
			    }
			    break;
			}
		    }
		    continue;

		case DP.number:
		    n1 = number;
		    dp = nextToken();
		    switch (dp)
		    {
			case DP.end:
			    year = n1;
			    break;

			case DP.minus:
			case DP.slash:	// n1/ ? ? ?
			    dp = parseCalendarDate(n1);
			    if (dp == DP.err)
				goto case_error;
			    break;

		       case DP.colon:	// hh:mm [:ss] [am | pm]
			    dp = parseTimeOfDay(n1);
			    if (dp == DP.err)
				goto case_error;
			    break;

		       case DP.ampm:
			    hours = n1;
			    minutes = 0;
			    seconds = 0;
			    ampm = number;
			    break;

			case DP.month:
			    day = n1;
			    month = number;
			    dp = nextToken();
			    if (dp == DP.number)
			    {   // day month year
				year = number;
				dp = nextToken();
			    }
			    break;

			default:
			    year = n1;
			    break;
		    }
		    continue;
	    }
	    dp = nextToken();
	}
	assert(0);
    }

    int parseCalendarDate(int n1)
    {
	int n2;
	int n3;
	int dp;

	debug(dateparse) printf("DateParse.parseCalendarDate(%d)\n", n1);
	dp = nextToken();
	if (dp == DP.month)	// day/month
	{
	    day = n1;
	    month = number;
	    dp = nextToken();
	    if (dp == DP.number)
	    {   // day/month year
		year = number;
		dp = nextToken();
	    }
	    else if (dp == DP.minus || dp == DP.slash)
	    {   // day/month/year
		dp = nextToken();
		if (dp != DP.number)
		    goto case_error;
		year = number;
		dp = nextToken();
	    }
	    return dp;
	}
	if (dp != DP.number)
	    goto case_error;
	n2 = number;
	//message(DTEXT("\tn2 = %d\n"), n2);
	dp = nextToken();
	if (dp == DP.minus || dp == DP.slash)
	{
	    dp = nextToken();
	    if (dp != DP.number)
		goto case_error;
	    n3 = number;
	    //message(DTEXT("\tn3 = %d\n"), n3);
	    dp = nextToken();

	    // case1: year/month/day
	    // case2: month/day/year
	    int case1, case2;

	    case1 = (n1 > 12 ||
		     (n2 >= 1 && n2 <= 12) &&
		     (n3 >= 1 && n3 <= 31));
	    case2 = ((n1 >= 1 && n1 <= 12) &&
		     (n2 >= 1 && n2 <= 31) ||
		     n3 > 31);
	    if (case1 == case2)
		goto case_error;
	    if (case1)
	    {
		year = n1;
		month = n2;
		day = n3;
	    }
	    else
	    {
		month = n1;
		day = n2;
		year = n3;
	    }
	}
	else
	{   // must be month/day
	    month = n1;
	    day = n2;
	}
	return dp;

    case_error:
	return DP.err;
    }

    int parseTimeOfDay(int n1)
    {
	int dp;
	int sign;

	// 12am is midnight
	// 12pm is noon

	//message(DTEXT("DateParse::parseTimeOfDay(%d)\n"), n1);
	hours = n1;
	dp = nextToken();
	if (dp != DP.number)
	    goto case_error;
	minutes = number;
	dp = nextToken();
	if (dp == DP.colon)
	{
	    dp = nextToken();
	    if (dp != DP.number)
		goto case_error;
	    seconds = number;
	    dp = nextToken();
	}
	else
	    seconds = 0;

	if (dp == DP.ampm)
	{
	    ampm = number;
	    dp = nextToken();
	}
	else if (dp == DP.plus || dp == DP.minus)
	{
	Loffset:
	    sign = (dp == DP.minus) ? -1 : 1;
	    dp = nextToken();
	    if (dp != DP.number)
		goto case_error;
	    tzcorrection = -sign * number;
	    dp = nextToken();
	}
	else if (dp == DP.tz)
	{
	    tzcorrection = number;
	    dp = nextToken();
	    if (number == 0 && (dp == DP.plus || dp == DP.minus))
		goto Loffset;
	    if (dp == DP.dst)
	    {   tzcorrection += 100;
		dp = nextToken();
	    }
	}
	else if (dp == DP.dsttz)
	{
	    tzcorrection = number;
	    dp = nextToken();
	}

	return dp;

    case_error:
	return DP.err;
    }

}

unittest
{
    DateParse dp;
    Date d;

    dp.parse("March 10, 1959 12:00 -800", d);
    assert(d.year         == 1959);
    assert(d.month        == 3);
    assert(d.day          == 10);
    assert(d.hour         == 12);
    assert(d.minute       == 0);
    assert(d.second       == 0);
    assert(d.ms           == 0);
    assert(d.weekday      == 0);
    assert(d.tzcorrection == 800);

    dp.parse("Tue Apr 02 02:04:57 GMT-0800 1996", d);
    assert(d.year         == 1996);
    assert(d.month        == 4);
    assert(d.day          == 2);
    assert(d.hour         == 2);
    assert(d.minute       == 4);
    assert(d.second       == 57);
    assert(d.ms           == 0);
    assert(d.weekday      == 3);
    assert(d.tzcorrection == 800);

    dp.parse("March 14, -1980 21:14:50", d);
    assert(d.year         == 1980);
    assert(d.month        == 3);
    assert(d.day          == 14);
    assert(d.hour         == 21);
    assert(d.minute       == 14);
    assert(d.second       == 50);
    assert(d.ms           == 0);
    assert(d.weekday      == 0);
    assert(d.tzcorrection == int.min);

    dp.parse("Tue Apr 02 02:04:57 1996", d);
    assert(d.year         == 1996);
    assert(d.month        == 4);
    assert(d.day          == 2);
    assert(d.hour         == 2);
    assert(d.minute       == 4);
    assert(d.second       == 57);
    assert(d.ms           == 0);
    assert(d.weekday      == 3);
    assert(d.tzcorrection == int.min);

    dp.parse("Tue, 02 Apr 1996 02:04:57 G.M.T.", d);
    assert(d.year         == 1996);
    assert(d.month        == 4);
    assert(d.day          == 2);
    assert(d.hour         == 2);
    assert(d.minute       == 4);
    assert(d.second       == 57);
    assert(d.ms           == 0);
    assert(d.weekday      == 3);
    assert(d.tzcorrection == 0);

    dp.parse("December 31, 3000", d);
    assert(d.year         == 3000);
    assert(d.month        == 12);
    assert(d.day          == 31);
    assert(d.hour         == 0);
    assert(d.minute       == 0);
    assert(d.second       == 0);
    assert(d.ms           == 0);
    assert(d.weekday      == 0);
    assert(d.tzcorrection == int.min);

    dp.parse("Wed, 31 Dec 1969 16:00:00 GMT", d);
    assert(d.year         == 1969);
    assert(d.month        == 12);
    assert(d.day          == 31);
    assert(d.hour         == 16);
    assert(d.minute       == 0);
    assert(d.second       == 0);
    assert(d.ms           == 0);
    assert(d.weekday      == 4);
    assert(d.tzcorrection == 0);

    dp.parse("1/1/1999 12:30 AM", d);
    assert(d.year         == 1999);
    assert(d.month        == 1);
    assert(d.day          == 1);
    assert(d.hour         == 0);
    assert(d.minute       == 30);
    assert(d.second       == 0);
    assert(d.ms           == 0);
    assert(d.weekday      == 0);
    assert(d.tzcorrection == int.min);

    dp.parse("Tue, 20 May 2003 15:38:58 +0530", d);
    assert(d.year         == 2003);
    assert(d.month        == 5);
    assert(d.day          == 20);
    assert(d.hour         == 15);
    assert(d.minute       == 38);
    assert(d.second       == 58);
    assert(d.ms           == 0);
    assert(d.weekday      == 3);
    assert(d.tzcorrection == -530);

    debug(dateparse) printf("year = %d, month = %d, day = %d\n%02d:%02d:%02d.%03d\nweekday = %d, tzcorrection = %d\n",
	d.year, d.month, d.day,
	d.hour, d.minute, d.second, d.ms,
	d.weekday, d.tzcorrection);
}

