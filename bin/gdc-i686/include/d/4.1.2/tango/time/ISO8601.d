/*******************************************************************************

        Copyright:      Copyright (c) 2007-2008 Matti Niemenmaa.
                        All rights reserved
        License:        BSD style: $(LICENSE)
        Version:        Aug 2007: Initial release
                        Feb 2008: Retooled
        Author:         Matti Niemenmaa

        This module is based on the ISO 8601:2004 standard, and has functions
        for parsing (almost) every date/time format specified therein. (The
        ones not supported are intervals, durations, and recurring intervals.)

        Refer to the standard for a full description of the formats supported.

        The functions (parseTime, parseDate, and parseDateAndTime) are
        overloaded into two different versions of each: one updates a given
        Time, and the other updates a given ExtendedDate struct. The purpose of
        this struct is to support more detailed information which the Time data
        type does not (and, given its simple integer nature, cannot) support.

        Times with specified time zones are simply converted into UTC: this may
        lead to the date changing when only a time was parsed: e.g. "01:00+03"
        is the same as "22:00", except that when the former is parsed, one is
        subtracted from the day.

*******************************************************************************/

module tango.time.ISO8601;

public import tango.time.Time;
public import tango.time.chrono.Gregorian;

import tango.core.Exception : IllegalArgumentException;

private alias Time DT;
private alias ExtendedDate FullDate;

/** An extended date type, wrapping a Time together with some additional
 * information. */
public struct ExtendedDate {
   /** The Time value, containing the information it can. */
   DT val;

   private int year_;

   /** Returns the year part of the date: a value in the range
    * [-1_000_000_000,-1] ∪ [1,999_999_999], where -1 is the year 1 BCE.
    *
    * Do not use val.year directly unless you are absolutely sure that it is in
    * the range a Time can hold (-10000 to 9999).
    */
   int year()
   out(val) {
      assert (  (val >= -1_000_000_000 && val <=          -1)
             || (val >=              1 && val <= 999_999_999));
   } body {
      if (year_)
         return year_;

      auto era = Gregorian.generic.getEra(val);
      if (era == Gregorian.AD_ERA)
         return Gregorian.generic.getYear(val);
      else
         return -Gregorian.generic.getYear(val);
   }

   // y may be zero: if so, it refers to the year 1 BCE
   private void year(int y) {
      if (DTyear(y)) {
         year_ = 0;
         // getYear returns uint: be careful with promotion to unsigned
         int toAdd = y - Gregorian.generic.getYear(val);
         val = Gregorian.generic.addYears(val, toAdd);
      } else
         year_ = y < 0 ? y-1 : y;
   }

   private byte mask; // leap second and endofday

   /** Returns the seconds part of the date: may be 60 if a leap second
    * occurred. In such a case, val's seconds part is 59.
    */
   uint seconds() { return val.time.seconds + ((mask >>> 0) & 1); }
   alias seconds secs, second, sec;

   /** Whether the ISO 8601 representation of this hour is 24 or 00: whether
    * this instant of midnight is to be considered the end of the previous day
    * or the start of the next.
    *
    * If the time of val is not exactly 00:00:00.000, this value is undefined.
    */
   bool endOfDay() { return 1 ==              ((mask >>> 1) & 1); }

   private void setLeap    () { mask |= 1 << 0; }
   private void setEndOfDay() { mask |= 1 << 1; }

   debug (Tango_ISO8601) private char[] toStr() {
      return Stdout.layout.convert(
         "{:d} and {:d}-{:d2}-{:d2} :: {:d2}:{:d2}:{:d2}.{:d3} and {:d2}, {}",
         year_, years(*this), months(*this), days(*this),
         hours(*this), mins(*this), .secs(*this), ms(*this),
         this.seconds, this.endOfDay);
   }
}

/** Parses a date in a format specified in ISO 8601:2004.
 *
 * Returns the number of characters used to compose a valid date: 0 if no date
 * can be composed.
 *
 * Fields in dt will either be correct (e.g. months will be >= 1 and <= 12) or
 * the default, which is 1 for year, month, and day, and 0 for all other
 * fields. Unless one is absolutely sure that 0001-01-01 can never be
 * encountered, one should check the return value to be sure that the parsing
 * succeeded as expected.
 *
 * A third parameter is available for the ExtendedDate version: this allows for
 * parsing expanded year representations. The parameter is the number of extra
 * year digits beyond four, and defaults to zero. It must be within the range
 * [0,5]: this allows for a maximum year of 999 999 999, which should be enough
 * for now.
 *
 * When using expanded year representations, be careful to use
 * ExtendedDate.year instead of the Time's year value.
 *
 * Examples:
 * ---
 * Time t;
 * ExtendedDate ed;
 * 
 * parseDate("19",             t);    // January 1st, 1900
 * parseDate("1970",           t);    // January 1st, 1970
 * parseDate("1970-02",        t);    // February 1st, 1970
 * parseDate("19700203",       t);    // February 3rd, 1970
 * parseDate("+19700203",     ed, 2); // March 1st, 197002
 * parseDate("-197002-04-01", ed, 2); // April 1st, -197003 (197003 BCE)
 * parseDate("00000101",       t);    // January 1st, -1 (1 BCE)
 * parseDate("1700-W14-2",     t);    // April 6th, 1700
 * parseDate("2008W01",        t);    // December 31st, 2007
 * parseDate("1987-221",       t);    // August 9th, 1987
 * parseDate("1234abcd",       t);    // January 1st, 1234; return value is 4
 * parseDate("12abcdef",       t);    // January 1st, 1200; return value is 2
 * parseDate("abcdefgh",       t);    // January 1st, 0001; return value is 0
 * ---
 */
public size_t parseDate(T)(T[] src, inout DT dt) {
   auto fd = FullDate(dt);

   auto ret = parseDate(src, fd);
   dt = fd.val;
   return ret;
}
/** ditto */
public size_t parseDate(T)(T[] src, inout FullDate fd, ubyte expanded = 0) {
   ubyte dummy = void;
   T* p = src.ptr;
   return doIso8601Date(p, src, fd, expanded, dummy);
}

private size_t doIso8601Date(T)(

   inout T* p, T[] src,
   inout FullDate fd,
   ubyte expanded,
   out ubyte separators

) {
   if (expanded > 5)
      throw new IllegalArgumentException(
         "ISO8601 :: year expanded by more than 5 digits does not fit in int");

   size_t eaten() { return p - src.ptr; }
   bool done(T[] s) { return .done(eaten(), src.length, *p, s); }

   if (!parseYear(p, expanded, fd))
      return 0;

   auto onlyYear = eaten();

   // /([+-]Y{expanded})?(YYYY|YY)/
   if (done("-0123W"))
      return onlyYear;

   if (accept(p, '-'))
      separators = true;

   if (accept(p, 'W')) {
      // (year)-Www-D

      T* p2 = p;

      int i = parseIntLimited(p, cast(size_t)3);

      if (i) if (p - p2 == 2) {

         // (year)-Www
         if (done("-")) {
            if (getMonthAndDayFromWeek(fd, i))
               return eaten();

         // (year)-Www-D
         } else if (demand(p, '-'))
            if (getMonthAndDayFromWeek(fd, i, *p++ - '0'))
               return eaten();

      } else if (p - p2 == 3)
         // (year)WwwD
         if (getMonthAndDayFromWeek(fd, i / 10, i % 10))
            return eaten();

      return onlyYear;
   }

   // next up, MM or MM[-]DD or DDD

   T* p2 = p;

   int i = parseInt(p);
   if (!i)
      return onlyYear;

   switch (p - p2) {
      case 2:
         // MM or MM-DD

         if (i >= 1 && i <= 12)
            addMonths(fd, i);
         else
            return onlyYear;

         auto onlyMonth = eaten();

         // (year)-MM
         if (done("-") || !demand(p, '-'))
            return onlyMonth;

         int day = parseIntLimited(p, cast(size_t)2);

         // (year)-MM-DD
         if (day && day <= daysPerMonth(months(fd), fd.year))
            addDays(fd, day);
         else
            return onlyMonth;

         break;

      case 4:
         // e.g. 20010203, i = 203 now

         int month = i / 100;
         int day   = i % 100;

         // (year)MMDD
         if (
            month >= 1 && month <= 12 &&
            day   >= 1 && day   <= daysPerMonth(month, fd.year)
         ) {
            addMonths(fd, month);
            addDays  (fd, day);
         } else
            return onlyYear;

         break;

      case 3:
         // (year)-DDD
         // i is the ordinal of the day within the year

         if (i > 365 + isLeapYear(fd.year))
            return onlyYear;

         addDays(fd, i);

      default: break;
   }

   return eaten();
}

/** Parses a time of day in a format specified in ISO 8601:2004.
 *
 * Returns the number of characters used to compose a valid time: 0 if no time
 * can be composed.
 *
 * Fields in dt will either be correct or the default, which is 0 for all
 * time-related fields. fields. Unless one is absolutely sure that midnight
 * can never be encountered, one should check the return value to be sure that
 * the parsing succeeded as expected.
 *
 * Extra fields in ExtendedDate:
 *
 * Seconds may be 60 if the hours and minutes are 23 and 59, as leap seconds
 * are occasionally added to UTC time. A Time's seconds will be 59 in this
 * case.
 *
 * Hours may be 0 or 24: the latter marks the end of a day and the former the
 * beginning, although they both refer to the same instant in time. A Time
 * will be precisely 00:00 in either case.
 *
 * Examples:
 * ---
 * Time t;
 * ExtendedDate ed;
 *
 * // ",000" omitted for clarity
 * parseTime("20",             t); // 20:00:00
 * parseTime("2004",           t); // 20:04:00
 * parseTime("20:04:06",       t); // 20:04:06
 * parseTime("16:49:30,001",   t); // 16:49:30,001
 * parseTime("16:49:30,1",     t); // 16:49:30,100
 * parseTime("16:49,4",        t); // 16:49:24
 * parseTime("23:59:60",      ed); // 23:59:60
 * parseTime("24:00:01",       t); // 00:00:00; return value is 5
 * parseTime("24:00:01",      ed); // 00:00:00; return value is 5; endOfDay
 * parseTime("30",             t); // 00:00:00; return value is 0
 * parseTime("21:32:43-12:34", t); // 10:06:43; day increased by one
 * ---
 */
public size_t parseTime(T)(T[] src, inout DT dt) {
   auto fd = FullDate(dt);

   auto ret = parseTime(src, fd);
   dt = fd.val;
   return ret;
}
/** ditto */
public size_t parseTime(T)(T[] src, inout FullDate fd) {
   bool dummy = void;
   T* p = src.ptr;
   return doIso8601Time(p, src, fd, WHATEVER, dummy);
}

// separators
private enum : ubyte { NO = 0, YES = 1, WHATEVER }

// bothValid is used only to get parseDateAndTime() to catch errors correctly
private size_t doIso8601Time(T)(

   inout T* p, T[] src,
   inout FullDate fd,
   ubyte separators,
   out bool bothValid

) {
   size_t eaten() { return p - src.ptr; }
   bool done(T[] s) { return .done(eaten(), src.length, *p, s); }

   bool checkColon() {
      if (separators == WHATEVER)
         accept(p, ':');

      else if (accept(p, ':') != separators)
         return false;

      return true;
   }

   byte getTimeZone() { return .getTimeZone(p, fd, separators, &done); }

   if (separators == WHATEVER)
      accept(p, 'T');

   int hour = void;
   if (parseIntLimited(p, cast(size_t)2, hour) != 2 || hour > 24)
      return 0;

   if (hour == 24)
      fd.setEndOfDay();
   else
      addHours(fd, hour);

   auto onlyHour = eaten();

   // hh
   if (done("+,-.012345:"))
      return onlyHour;

   switch (getDecimal(p, fd, HOUR)) {
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

   if (!checkColon())
      return onlyHour;

   int min = void;
   if (
      parseIntLimited(p, cast(size_t)2, min) != 2 ||
      min > 59 ||
      // end of day is only for 24:00:00
      (fd.endOfDay && min != 0)
   )
      return onlyHour;

   addMins(fd, min);

   auto onlyMinute = eaten();

   // hh:mm
   if (done("+,-.0123456:")) {
      bothValid = true;
      return onlyMinute;
   }

   switch (getDecimal(p, fd, MINUTE)) {
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

   if (!checkColon())
      return onlyMinute;

   int sec = void;
   if (
      parseIntLimited(p, cast(size_t)2, sec) != 2 ||
      sec > 60 ||
      (fd.endOfDay && sec != 0)
   )
      return onlyMinute;

   if (sec == 60) {
      if (hours(fd) != 23 && mins(fd) != 59)
         return onlyMinute;

      fd.setLeap();
      --sec;
   }
   addSecs(fd, sec);

   auto onlySecond = eaten();

   // hh:mm:ss
   if (done("+,-.Z")) {
      bothValid = true;
      return onlySecond;
   }

   switch (getDecimal(p, fd, SECOND)) {
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

/** Parses a combined date and time in a format specified in ISO 8601:2004.
 *
 * Returns the number of characters used to compose a valid date and time.
 * Zero is returned if a complete date and time cannot be extracted. In that
 * case, the value of the resulting Time or ExtendedDate is undefined.
 *
 * This function is stricter than just calling parseDate followed by
 * parseTime: there are no allowances for expanded years or reduced dates
 * (two-digit years), and separator usage must be consistent.
 *
 * Although the standard allows for omitting the T between the date and the
 * time, this function requires it.
 *
 * Examples:
 * ---
 * Time t;
 *
 * // January 1st, 2008 00:01:00
 * parseDateAndTime("2007-12-31T23:01-01", t); 
 *
 * // April 12th, 1985 23:50:30,042
 * parseDateAndTime("1985W155T235030,042", t); 
 *
 * // Invalid time: returns zero
 * parseDateAndTime("1902-03-04T10:1a", t);
 *
 * // Separating T omitted: returns zero
 * parseDateAndTime("1985-04-1210:15:30+04:00", t);
 *
 * // Inconsistent separators: all return zero
 * parseDateAndTime("200512-01T10:02",          t);
 * parseDateAndTime("1985-04-12T10:15:30+0400", t);
 * parseDateAndTime("1902-03-04T050607",        t);
 * ---
 */
public size_t parseDateAndTime(T)(T[] src, inout DT dt) {
   FullDate fd;
   auto ret = parseDateAndTime(src, fd);
   dt = fd.val;
   return ret;
}
/** ditto */
public size_t parseDateAndTime(T)(T[] src, inout FullDate fd) {
   T* p = src.ptr;
   ubyte sep;
   bool bothValid = false;

   if (
      doIso8601Date(p, src, fd, cast(ubyte)0, sep) &&

      // by mutual agreement this T may be omitted
      // but this is just a convenience method for date+time anyway
      demand(p, 'T') &&

      doIso8601Time(p, src, fd, sep, bothValid) &&
      bothValid
   )
      return p - src.ptr;
   else
      return 0;
}

/+ +++++++++++++++++++++++++++++++++++++++ +\

   Privates used by date

\+ +++++++++++++++++++++++++++++++++++++++ +/

private:

// /([+-]Y{expanded})?(YYYY|YY)/
bool parseYear(T)(inout T* p, ubyte expanded, inout FullDate fd) {

   int year = void;

   bool doParse() {
      T* p2 = p;

      if (!parseIntLimited(p, cast(size_t)(expanded + 4), year))
         return false;

      // it's Y{expanded}YY, Y{expanded}YYYY, or unacceptable

      if (p - p2 - expanded == 2)
         year *= 100;
      else if (p - p2 - expanded != 4)
         return false;

      return true;
   }

   if (accept(p, '-')) {
      if (!doParse() || year < 0)
         return false;
      year = -year;
   } else {
      accept(p, '+');
      if (!doParse() || year < 0)
         return false;
   }

   fd.year = year;

   return true;
}

// find the month and day given a calendar week and the day of the week
// uses fd.year for leap year calculations
// returns false if week and fd.year are incompatible
bool getMonthAndDayFromWeek(inout FullDate fd, int week, int day = 1) {
   if (week < 1 || week > 53 || day < 1 || day > 7)
      return false;

   int year = fd.year;

   // only years starting with Thursday and leap years starting with Wednesday
   // have 53 weeks
   if (week == 53) {
      int startingDay = dayOfWeek(year, 1, 1);

      if (!(startingDay == 4 || (isLeapYear(year) && startingDay == 3)))
         return false;
   }

   // XXX
   // days since year-01-04, plus 4 (?)...
   /* This is a bit scary, actually: I have ***no idea why this works***. I
    * came up with this completely by accident. It seems to work though -
    * unless it fails in some (very) obscure case which isn't represented in
    * the unit tests.
   */
   addDays(fd, 7*(week - 1) + day - dayOfWeek(year, 1, 4) + 4);

   return true;
}

bool isLeapYear(int year) {
   return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

int dayOfWeek(int year, int month, int day)
in {
   assert (month  >= 1 && month  <= 12);
   assert (day    >= 1 && day    <= 31);
} out(result) {
   assert (result >= 1 && result <= 7);
} body {
   uint era = erafy(year);

   int result =
      Gregorian.generic.getDayOfWeek(
         Gregorian.generic.toTime(year, month, day, 0, 0, 0, 0, era));

   if (result == Gregorian.DayOfWeek.Sunday)
      return 7;
   else
      return result;
}

/+ +++++++++++++++++++++++++++++++++++++++ +\

   Privates used by time

\+ +++++++++++++++++++++++++++++++++++++++ +/

enum : ubyte { HOUR, MINUTE, SECOND }
enum :  byte { BAD, FOUND, NOTFOUND }

byte getDecimal(T)(inout T* p, inout FullDate fd, ubyte which) {
   if (!(accept(p, ',') || accept(p, '.')))
      return NOTFOUND;

   T* p2 = p;

   int i = void;
   auto iLen = parseInt(p, i);

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
         addMins(fd, 6 * i / pow);
         addSecs(fd, 6 * i % pow);
         break;
      case MINUTE:
         addSecs(fd, 6    * i / pow);
         addMs  (fd, 6000 * i / pow % 1000);
         break;
      case SECOND:
         addMs(fd, 100 * i / pow);
         break;

      default: assert (false);
   }

   return FOUND;
}

// the DT is always UTC, so this just adds the offset to the date fields
// another option would be to add time zone fields to DT and have this fill them

byte getTimeZone(T)(inout T* p, inout FullDate fd, ubyte separators, bool delegate(T[]) done) {
   if (accept(p, 'Z'))
      return FOUND;

   int factor = -1;

   if (accept(p, '-'))
      factor = 1;
   else if (!accept(p, '+'))
      return NOTFOUND;

   int hour = void;
   if (parseIntLimited(p, cast(size_t)2, hour) != 2 || hour > 12 || (hour == 0 && factor == 1))
      return BAD;

   addHours(fd, factor * hour);

   // if we go forward in time to midnight, it's 24:00
   if (
      factor > 0 &&
      hours(fd) == 0 && mins(fd) == 0 && secs(fd) == 0 && ms(fd) == 0
   )
      fd.setEndOfDay();

   if (done("012345:"))
      return FOUND;

   if (separators == WHATEVER)
      accept(p, ':');
   else if (accept(p, ':') != separators)
      return BAD;

   int minute = void;
   if (parseIntLimited(p, cast(size_t)2, minute) != 2)
      return BAD;

   addMins(fd, factor * minute);

   // as above
   if (
      factor > 0 &&
      hours(fd) == 0 && mins(fd) == 0 && secs(fd) == 0 && ms(fd) == 0
   )
      fd.setEndOfDay();

   return FOUND;
}

/+ +++++++++++++++++++++++++++++++++++++++ +\

   Privates used by both date and time

\+ +++++++++++++++++++++++++++++++++++++++ +/

bool accept(T)(inout T* p, char c) {
   if (*p == c) {
      ++p;
      return true;
   }
   return false;
}

bool demand(T)(inout T* p, char c) {
   return (*p++ == c);
}

bool done(T)(size_t eaten, size_t srcLen, T p, T[] s) {
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

int daysPerMonth(int month, int year) {
   uint era = erafy(year);
   return Gregorian.generic.getDaysInMonth(year, month, era);
}

uint erafy(inout int year) {
   if (year < 0) {
      year *= -1;
      return Gregorian.BC_ERA;
   } else
      return Gregorian.AD_ERA;
}

/+ +++++++++++++++++++++++++++++++++++++++ +\

   Extract an integer from the input

\+ +++++++++++++++++++++++++++++++++++++++ +/

// note: code relies on these always being positive, failing if *p == '-'

int parseInt(T)(inout T* p) {
   int value = 0;
   while (*p >= '0' && *p <= '9')
      value = value * 10 + *p++ - '0';
   return value;
}

// ... but accept no more than max digits

int parseIntLimited(T)(inout T* p, size_t max) {
   size_t i = 0;
   int value = 0;
   while (p[i] >= '0' && p[i] <= '9' && i < max)
      value = value * 10 + p[i++] - '0';
   p += i;
   return value;
}

// ... and return the amount of digits processed

size_t parseInt(T)(inout T* p, out int i) {
   T* p2 = p;
   i = parseInt(p);
   return p - p2;
}

size_t parseIntLimited(T)(inout T* p, size_t max, out int i) {
   T* p2 = p;
   i = parseIntLimited(p, max);
   return p - p2;
}


/+ +++++++++++++++++++++++++++++++++++++++ +\

   Helpers for DT/FullDate manipulation

\+ +++++++++++++++++++++++++++++++++++++++ +/

// as documented in tango.time.Time
bool DTyear(int year) { return year >= -10000 && year <= 9999; }

void addMonths(inout FullDate d, int n) { d.val = Gregorian.generic.addMonths(d.val, n-1); } // -1 due to initial being 1
void addDays  (inout FullDate d, int n) { d.val += TimeSpan.days   (n-1); } // ditto
void addHours (inout FullDate d, int n) { d.val += TimeSpan.hours  (n); }
void addMins  (inout FullDate d, int n) { d.val += TimeSpan.minutes(n); }
void addSecs  (inout FullDate d, int n) { d.val += TimeSpan.seconds(n); }
void addMs    (inout FullDate d, int n) { d.val += TimeSpan.millis (n); }

// years and secs always just get the DT value
int years (FullDate d) { return Gregorian.generic.getYear      (d.val); }
int months(FullDate d) { return Gregorian.generic.getMonth     (d.val); }
int days  (FullDate d) { return Gregorian.generic.getDayOfMonth(d.val); }
int hours (FullDate d) { return d.val.time.hours;   }
int mins  (FullDate d) { return d.val.time.minutes; }
int secs  (FullDate d) { return d.val.time.seconds; }
int ms    (FullDate d) { return d.val.time.millis;  }

////////////////////

// Unit tests

debug (UnitTest) {
   // void main() {}

   unittest {
      FullDate fd;

      // date

      size_t d(char[] s, ubyte e = 0) {
         fd = fd.init;
         return parseDate(s, fd, e);
      }

      auto
         INIT_YEAR  = years (FullDate.init),
         INIT_MONTH = months(FullDate.init),
         INIT_DAY   = days  (FullDate.init);

      assert (d("20abc") == 2);
      assert (years(fd) == 2000);

      assert (d("2004") == 4);
      assert (years(fd) == 2004);

      assert (d("+0019", 2) == 5);
      assert (years(fd) == 1900);

      assert (d("+111985", 2) == 7);
      assert (years(fd) == INIT_YEAR);
      assert (fd.year   == 111985);

      assert (d("+111985", 1) == 6);
      assert (years(fd) == INIT_YEAR);
      assert (fd.year   == 11198);

      assert (d("+111985", 3) == 0);
      assert (years(fd) == INIT_YEAR);
      assert (fd.year   == INIT_YEAR);

      assert (d("+111985", 4) == 7);
      assert (years(fd) == INIT_YEAR);
      assert (fd.year   == 11198500);

      assert (d("-111985", 5) == 0);
      assert (years(fd) == INIT_YEAR);
      assert (fd.year   == INIT_YEAR);

      assert (d("+999999999", 5) == 10);
      assert (years(fd) == INIT_YEAR);
      assert (fd.year == 999_999_999);

      try {
         d("+10000000000", 6);
         assert (false);
      } catch (IllegalArgumentException) {
         assert (years(fd) == INIT_YEAR);
         assert (fd.year   == INIT_YEAR);
      }

      assert (d("-999999999", 5) == 10);
      assert (years(fd) == INIT_YEAR);
      assert (fd.year == -1_000_000_000);

      assert (d("0001") == 4);
      assert (years(fd) == 1);
      assert (fd.year   == 1);

      assert (d("0000") == 4);
      assert (fd.year   == -1);

      assert (d("-0001") == 5);
      assert (fd.year   == -2);

      assert (d("abc") == 0);
      assert (years(fd) == INIT_YEAR);
      assert (fd.year   == INIT_YEAR);

      assert (d("abc123") == 0);
      assert (years(fd) == INIT_YEAR);
      assert (fd.year   == INIT_YEAR);

      assert (d("2007-08") == 7);
      assert (years(fd)  == 2007);
      assert (months(fd) ==    8);

      assert (d("+001985-04", 2) == 10);
      assert (years(fd)  == 1985);
      assert (months(fd) ==    4);

      assert (d("2007-08-07") == 10);
      assert (years(fd)  == 2007);
      assert (months(fd) ==    8);
      assert (days(fd)   ==    7);

      assert (d("2008-20-30") == 4);
      assert (years(fd)  == 2008);
      assert (months(fd) == INIT_MONTH);

      assert (d("2007-02-30") == 7);
      assert (years(fd)  == 2007);
      assert (months(fd) ==    2);

      assert (d("20060708") == 8);
      assert (years(fd)  == 2006);
      assert (months(fd) ==    7);
      assert (days(fd)   ==    8);

      assert (d("19953080") == 4);
      assert (years(fd)  == 1995);
      assert (months(fd) == INIT_MONTH);

      assert (d("+001985-04-12", 2) == 13);
      assert (years(fd)  == 1985);
      assert (fd.year    == 1985);
      assert (months(fd) ==    4);
      assert (days(fd)   ==   12);

      assert (d("-0123450607", 2) == 11);
      assert (years(fd)  == INIT_YEAR);
      assert (fd.year    == -12346);
      assert (months(fd) ==      6);
      assert (days(fd)   ==      7);

      assert (d("1985W15") == 7);
      assert (years(fd)  == 1985);
      assert (months(fd) ==    4);
      assert (days(fd)   ==    8);

      assert (d("2008-W01") == 8);
      assert (years(fd)  == 2007);
      assert (months(fd) ==   12);
      assert (days(fd)   ==   31);

      assert (d("2008-W01-2") == 10);
      assert (years(fd)  == 2008);
      assert (months(fd) ==    1);
      assert (days(fd)   ==    1);

      assert (d("2009-W53-4") == 10);
      assert (years(fd)  == 2009);
      assert (months(fd) ==   12);
      assert (days(fd)   ==   31);

      assert (d("2009-W01-1") == 10);
      assert (years(fd)  == 2008);
      assert (months(fd) ==   12);
      assert (days(fd)   ==   29);

      assert (d("2009W537") == 8);
      assert (years(fd)  == 2010);
      assert (months(fd) ==    1);
      assert (days(fd)   ==    3);

      assert (d("2010W537") == 4);
      assert (years(fd)  == 2010);
      assert (months(fd) == INIT_MONTH);

      assert (d("2009-W01-3") == 10);
      assert (years(fd)  == 2008);
      assert (months(fd) ==   12);
      assert (days(fd)   ==   31);

      assert (d("2009-W01-4") == 10);
      assert (years(fd)  == 2009);
      assert (months(fd) ==    1);
      assert (days(fd)   ==    1);

      assert (d("2004-W53-6") == 10);
      assert (years(fd)  == 2005);
      assert (months(fd) ==    1);
      assert (days(fd)   ==    1);

      assert (d("2004-W53-7") == 10);
      assert (years(fd)  == 2005);
      assert (months(fd) ==    1);
      assert (days(fd)   ==    2);

      assert (d("2005-W52-6") == 10);
      assert (years(fd)  == 2005);
      assert (months(fd) ==   12);
      assert (days(fd)   ==   31);

      assert (d("2007-W01-1") == 10);
      assert (years(fd)  == 2007);
      assert (months(fd) ==    1);
      assert (days(fd)   ==    1);

      assert (d("1000-W07-7") == 10);
      assert (years(fd)  == 1000);
      assert (months(fd) ==    2);
      assert (days(fd)   ==   16);

      assert (d("1500-W11-1") == 10);
      assert (years(fd)  == 1500);
      assert (months(fd) ==    3);
      assert (days(fd)   ==   12);

      assert (d("1700-W14-2") == 10);
      assert (years(fd)  == 1700);
      assert (months(fd) ==    4);
      assert (days(fd)   ==    6);

      assert (d("1800-W19-3") == 10);
      assert (years(fd)  == 1800);
      assert (months(fd) ==    5);
      assert (days(fd)   ==    7);

      assert (d("1900-W25-4") == 10);
      assert (years(fd)  == 1900);
      assert (months(fd) ==    6);
      assert (days(fd)   ==   21);

      assert (d("0900-W27-5") == 10);
      assert (years(fd)  ==  900);
      assert (months(fd) ==    7);
      assert (days(fd)   ==    9);

      assert (d("0800-W33-6") == 10);
      assert (years(fd)  ==  800);
      assert (months(fd) ==    8);
      assert (days(fd)   ==   19);

      assert (d("0700-W37-7") == 10);
      assert (years(fd)  ==  700);
      assert (months(fd) ==    9);
      assert (days(fd)   ==   16);

      assert (d("0600-W41-4") == 10);
      assert (years(fd)  ==  600);
      assert (months(fd) ==   10);
      assert (days(fd)   ==    9);

      assert (d("0500-W45-7") == 10);
      assert (years(fd)  ==  500);
      assert (months(fd) ==   11);
      assert (days(fd)   ==   14);

      assert (d("2000-W55") == 4);
      assert (years(fd) == 2000);

      assert (d("1980-002") == 8);
      assert (years(fd)  == 1980);
      assert (months(fd) ==    1);
      assert (days(fd)   ==    2);

      assert (d("1981-034") == 8);
      assert (years(fd)  == 1981);
      assert (months(fd) ==    2);
      assert (days(fd)   ==    3);

      assert (d("1982-063") == 8);
      assert (years(fd)  == 1982);
      assert (months(fd) ==    3);
      assert (days(fd)   ==    4);

      assert (d("1983-095") == 8);
      assert (years(fd)  == 1983);
      assert (months(fd) ==    4);
      assert (days(fd)   ==    5);

      assert (d("1984-127") == 8);
      assert (years(fd)  == 1984);
      assert (months(fd) ==    5);
      assert (days(fd)   ==    6);

      assert (d("1985-158") == 8);
      assert (years(fd)  == 1985);
      assert (months(fd) ==    6);
      assert (days(fd)   ==    7);

      assert (d("1986-189") == 8);
      assert (years(fd)  == 1986);
      assert (months(fd) ==    7);
      assert (days(fd)   ==    8);

      assert (d("1987-221") == 8);
      assert (years(fd)  == 1987);
      assert (months(fd) ==    8);
      assert (days(fd)   ==    9);

      assert (d("1988-254") == 8);
      assert (years(fd)  == 1988);
      assert (months(fd) ==    9);
      assert (days(fd)   ==   10);

      assert (d("1989-284") == 8);
      assert (years(fd)  == 1989);
      assert (months(fd) ==   10);
      assert (days(fd)   ==   11);

      assert (d("1990316") == 7);
      assert (years(fd)  == 1990);
      assert (months(fd) ==   11);
      assert (days(fd)   ==   12);

      assert (d("1991-347") == 8);
      assert (years(fd)  == 1991);
      assert (months(fd) ==   12);
      assert (days(fd)   ==   13);

      assert (d("1992-000") == 4);
      assert (years(fd) == 1992);

      assert (d("1993-370") == 4);
      assert (years(fd) == 1993);

      // time

      size_t t(char[] s) {
         fd = fd.init;
         return parseTime(s, fd);
      }

      assert (t("20") == 2);
      assert (hours(fd) == 20);
      assert (mins(fd)  ==  0);
      assert (secs(fd)  ==  0);

      assert (t("30") == 0);

      assert (t("2004") == 4);
      assert (hours(fd) == 20);
      assert (mins(fd)  ==  4);
      assert (secs(fd)  ==  0);

      assert (t("200406") == 6);
      assert (hours(fd) == 20);
      assert (mins(fd)  ==  4);
      assert (secs(fd)  ==  6);

      assert (t("24:00") == 5);
      assert (fd.endOfDay);
      assert (days(fd)  == INIT_DAY);
      assert (hours(fd) == 0);
      assert (mins(fd)  == 0);
      assert (secs(fd)  == 0);

      assert (t("00:00") == 5);
      assert (hours(fd) == 0);
      assert (mins(fd)  == 0);
      assert (secs(fd)  == 0);

      assert (t("23:59:60") == 8);
      assert (hours(fd)  == 23);
      assert (mins(fd)   == 59);
      assert (secs(fd)   == 59);
      assert (fd.seconds == 60);

      assert (t("16:49:30,001") == 12);
      assert (hours(fd) == 16);
      assert (mins(fd)  == 49);
      assert (secs(fd)  == 30);
      assert (ms(fd)    ==  1);

      assert (t("15:48:29,1") == 10);
      assert (hours(fd) ==  15);
      assert (mins(fd)  ==  48);
      assert (secs(fd)  ==  29);
      assert (ms(fd)    == 100);

      assert (t("02:10:34,a") ==  8);
      assert (hours(fd) ==  2);
      assert (mins(fd)  == 10);
      assert (secs(fd)  == 34);

      assert (t("14:50,5") == 7);
      assert (hours(fd) == 14);
      assert (mins(fd)  == 50);
      assert (secs(fd)  == 30);

      assert (t("1540,4") == 6);
      assert (hours(fd) == 15);
      assert (mins(fd)  == 40);
      assert (secs(fd)  == 24);

      assert (t("1250,") == 4);
      assert (hours(fd) == 12);
      assert (mins(fd)  == 50);

      assert (t("14,5") == 4);
      assert (hours(fd) == 14);
      assert (mins(fd)  == 30);

      assert (t("12,") == 2);
      assert (hours(fd) == 12);
      assert (mins(fd)  ==  0);

      assert (t("24:00:01") == 5);
      assert (fd.endOfDay);
      assert (hours(fd) == 0);
      assert (mins(fd)  == 0);
      assert (secs(fd)  == 0);

      assert (t("12:34+:56") == 5);
      assert (hours(fd) == 12);
      assert (mins(fd)  == 34);
      assert (secs(fd)  ==  0);

      // time zones

      assert (t("14:45:15Z") == 9);
      assert (hours(fd) == 14);
      assert (mins(fd)  == 45);
      assert (secs(fd)  == 15);

      assert (t("23Z") == 3);
      assert (hours(fd) == 23);
      assert (mins(fd)  ==  0);
      assert (secs(fd)  ==  0);

      assert (t("21:32:43-12:34") == 14);
      assert (days(fd)  == INIT_DAY + 1);
      assert (hours(fd) == 10);
      assert (mins(fd)  ==  6);
      assert (secs(fd)  == 43);

      assert (t("12:34,5+0000") == 12);
      assert (hours(fd) == 12);
      assert (mins(fd)  == 34);
      assert (secs(fd)  == 30);

      assert (t("03:04+07") == 8);
      assert (hours(fd) == 20);
      assert (mins(fd)  ==  4);
      assert (secs(fd)  ==  0);

      assert (t("11,5+") == 4);
      assert (hours(fd) == 11);
      assert (mins(fd)  == 30);

      assert (t("07-") == 2);
      assert (hours(fd) == 7);

      assert (t("06:12,7-") == 7);
      assert (hours(fd) ==  6);
      assert (mins(fd)  == 12);
      assert (secs(fd)  == 42);

      assert (t("050403,2+") == 8);
      assert (hours(fd) ==   5);
      assert (mins(fd)  ==   4);
      assert (secs(fd)  ==   3);
      assert (ms(fd)    == 200);

      assert (t("061656-") == 6);
      assert (hours(fd) ==  6);
      assert (mins(fd)  == 16);
      assert (secs(fd)  == 56);

      // date and time together

      size_t b(char[] s) {
         fd = fd.init;
         return parseDateAndTime(s, fd);
      }

      assert (b("2007-08-09T12:34:56") == 19);
      assert (years(fd)  == 2007);
      assert (months(fd) ==    8);
      assert (days(fd)   ==    9);
      assert (hours(fd)  ==   12);
      assert (mins(fd)   ==   34);
      assert (secs(fd)   ==   56);

      assert (b("1985W155T235030,768") == 19);
      assert (years(fd)  == 1985);
      assert (months(fd) ==    4);
      assert (days(fd)   ==   12);
      assert (hours(fd)  ==   23);
      assert (mins(fd)   ==   50);
      assert (secs(fd)   ==   30);
      assert (ms(fd)     ==  768);

      // time zones

      assert (b("2009-08-07T01:02:03Z") == 20);
      assert (years(fd)  == 2009);
      assert (months(fd) ==    8);
      assert (days(fd)   ==    7);
      assert (hours(fd)  ==    1);
      assert (mins(fd)   ==    2);
      assert (secs(fd)   ==    3);

      assert (b("2007-08-09T03:02,5+04:56") == 24);
      assert (years(fd)  == 2007);
      assert (months(fd) ==    8);
      assert (days(fd)   ==    8);
      assert (hours(fd)  ==   22);
      assert (mins(fd)   ==    6);
      assert (secs(fd)   ==   30);

      assert (b("20000228T2330-01") == 16);
      assert (years(fd)  == 2000);
      assert (months(fd) ==    2);
      assert (days(fd)   ==   29);
      assert (hours(fd)  ==    0);
      assert (mins(fd)   ==   30);
      assert (secs(fd)   ==    0);

      assert (b("2007-01-01T00:00+01") == 19);
      assert (years(fd)  == 2006);
      assert (months(fd) ==   12);
      assert (days(fd)   ==   31);
      assert (hours(fd)  ==   23);
      assert (mins(fd)   ==    0);
      assert (secs(fd)   ==    0);

      assert (b("2007-12-31T23:00-01") == 19);
      assert (fd.endOfDay);
      assert (years(fd)  == 2008);
      assert (months(fd) ==    1);
      assert (days(fd)   ==    1);
      assert (hours(fd)  ==    0);
      assert (mins(fd)   ==    0);
      assert (secs(fd)   ==    0);

      assert (b("2007-12-31T23:01-01") == 19);
      assert (!fd.endOfDay);
      assert (years(fd)  == 2008);
      assert (months(fd) ==    1);
      assert (days(fd)   ==    1);
      assert (hours(fd)  ==    0);
      assert (mins(fd)   ==    1);
      assert (secs(fd)   ==    0);

      assert (b("1902-03-04T1a") == 0);
      assert (b("1902-03-04T10:aa") == 0);
      assert (b("1902-03-04T10:1aa") == 0);
      assert (b("200512-01T10:02") == 0);
      assert (b("1985-04-1210:15:30+04:00") == 0);
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
