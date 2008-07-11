/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.text.locale.Convert;

private import  tango.time.WallClock;

private import  tango.core.Exception;

private import  tango.text.locale.Core;

private import  tango.time.chrono.Calendar;

private import  Integer = tango.text.convert.Integer;

/******************************************************************************

******************************************************************************/

private struct Result
{
        private uint    index;
        private char[]  target_;

        /**********************************************************************

        **********************************************************************/

        private static Result opCall (char[] target)
        {
                Result result;

                result.target_ = target;
                return result;
        }

        /**********************************************************************

        **********************************************************************/

        private void opCatAssign (char[] rhs)
        {
                uint end = index + rhs.length;

                target_[index .. end] = rhs;
                index = end;
        }

        /**********************************************************************

        **********************************************************************/

        private void opCatAssign (char rhs)
        {
                target_[index++] = rhs;
        }

        /**********************************************************************

        **********************************************************************/

        private char[] get ()
        {
                return target_[0 .. index];
        }

        /**********************************************************************

        **********************************************************************/

        private char[] scratch ()
        {
                return target_;
        }
}


/******************************************************************************

   * Converts the value of this instance to its equivalent string representation using the specified _format and culture-specific formatting information.
   * Params: 
   *   format = A _format string.
   *   formatService = An IFormatService that provides culture-specific formatting information.
   * Returns: A string representation of the value of this instance as specified by format and formatService.
   * Remarks: See $(LINK2 datetimeformat.html, Time Formatting) for more information about date and time formatting.
   * Examples:
   * ---
   * import tango.io.Print, tango.text.locale.Core, tango.time.WallClock;
   *
   * void main() {
   *   Culture culture = Culture.current;
   *   Time now = WallClock.now;
   *
   *   Println("Current date and time: %s", now.toString());
   *   Println();
   *
   *   // Format the current date and time in a number of ways.
   *   Println("Culture: %s", culture.englishName);
   *   Println();
   *
   *   Println("Short date:              %s", now.toString("d"));
   *   Println("Long date:               %s", now.toString("D"));
   *   Println("Short time:              %s", now.toString("t"));
   *   Println("Long time:               %s", now.toString("T"));
   *   Println("General date short time: %s", now.toString("g"));
   *   Println("General date long time:  %s", now.toString("G"));
   *   Println("Month:                   %s", now.toString("M"));
   *   Println("RFC1123:                 %s", now.toString("R"));
   *   Println("Sortable:                %s", now.toString("s"));
   *   Println("Year:                    %s", now.toString("Y"));
   *   Println();
   *
   *   // Display the same values using a different culture.
   *   culture = Culture.getCulture("fr-FR");
   *   Println("Culture: %s", culture.englishName);
   *   Println();
   *
   *   Println("Short date:              %s", now.toString("d", culture));
   *   Println("Long date:               %s", now.toString("D", culture));
   *   Println("Short time:              %s", now.toString("t", culture));
   *   Println("Long time:               %s", now.toString("T", culture));
   *   Println("General date short time: %s", now.toString("g", culture));
   *   Println("General date long time:  %s", now.toString("G", culture));
   *   Println("Month:                   %s", now.toString("M", culture));
   *   Println("RFC1123:                 %s", now.toString("R", culture));
   *   Println("Sortable:                %s", now.toString("s", culture));
   *   Println("Year:                    %s", now.toString("Y", culture));
   *   Println();
   * }
   *
   * // Produces the following output:
   * // Current date and time: 26/05/2006 10:04:57 AM
   * //
   * // Culture: English (United Kingdom)
   * //
   * // Short date:              26/05/2006
   * // Long date:               26 May 2006
   * // Short time:              10:04
   * // Long time:               10:04:57 AM
   * // General date short time: 26/05/2006 10:04
   * // General date long time:  26/05/2006 10:04:57 AM
   * // Month:                   26 May
   * // RFC1123:                 Fri, 26 May 2006 10:04:57 GMT
   * // Sortable:                2006-05-26T10:04:57
   * // Year:                    May 2006
   * //
   * // Culture: French (France)
   * //
   * // Short date:              26/05/2006
   * // Long date:               vendredi 26 mai 2006
   * // Short time:              10:04
   * // Long time:               10:04:57
   * // General date short time: 26/05/2006 10:04
   * // General date long time:  26/05/2006 10:04:57
   * // Month:                   26 mai
   * // RFC1123:                 ven., 26 mai 2006 10:04:57 GMT
   * // Sortable:                2006-05-26T10:04:57
   * // Year:                    mai 2006
   * ---

******************************************************************************/

public char[] formatDateTime (char[] output, Time dateTime, char[] format, IFormatService formatService = null) 
{
    return formatDateTime (output, dateTime, format, DateTimeFormat.getInstance(formatService));
}

char[] formatDateTime (char[] output, Time dateTime, char[] format, DateTimeFormat dtf)
{
        /**********************************************************************

        **********************************************************************/

        char[] expandKnownFormat(char[] format, inout Time dateTime)
        {
                char[] f;

                switch (format[0])
                       {
                       case 'd':
                            f = dtf.shortDatePattern;
                            break;
                       case 'D':
                            f = dtf.longDatePattern;
                            break;
                       case 'f':
                            f = dtf.longDatePattern ~ " " ~ dtf.shortTimePattern;
                            break;
                       case 'F':
                            f = dtf.fullDateTimePattern;
                            break;
                       case 'g':
                            f = dtf.generalShortTimePattern;
                            break;
                       case 'G':
                            f = dtf.generalLongTimePattern;
                            break;
                       case 'm':
                       case 'M':
                            f = dtf.monthDayPattern;
                            break;
                       case 'r':
                       case 'R':
                            f = dtf.rfc1123Pattern;
                            break;
                       case 's':
                            f = dtf.sortableDateTimePattern;
                            break;
                       case 't':
                            f = dtf.shortTimePattern;
                            break;
                       case 'T':
                            f = dtf.longTimePattern;
                            break;
version (Full)
{
                       case 'u':
                            dateTime = dateTime.toUniversalTime();
                            dtf = DateTimeFormat.invariantFormat;
                            f = dtf.universalSortableDateTimePattern;
                            break;
                       case 'U':
                            dtf = cast(DateTimeFormat) dtf.clone();
                            dateTime = dateTime.toUniversalTime();
                            if (typeid(typeof(dtf.calendar)) !is typeid(Gregorian))
                                dtf.calendar = Gregorian.generic;
                            f = dtf.fullDateTimePattern;
                            break;
}
                       case 'y':
                       case 'Y':
                            f = dtf.yearMonthPattern;
                            break;
                       default:
                           throw new IllegalArgumentException("Invalid date format.");
                       }

                return f;
        }

        /**********************************************************************

        **********************************************************************/

        char[] formatCustom (inout Result result, Time dateTime, char[] format)
        {

                int parseRepeat(char[] format, int pos, char c)
                {
                        int n = pos + 1;
                        while (n < format.length && format[n] is c)
                                n++;
                        return n - pos;
                }

                char[] formatDayOfWeek(Calendar.DayOfWeek dayOfWeek, int rpt)
                {
                        if (rpt is 3)
                                return dtf.getAbbreviatedDayName(dayOfWeek);
                        return dtf.getDayName(dayOfWeek);
                }

                char[] formatMonth(int month, int rpt)
                {
                        if (rpt is 3)
                                return dtf.getAbbreviatedMonthName(month);
                        return dtf.getMonthName(month);
                }

                char[] formatInt (char[] tmp, int v, int minimum)
                {
                        auto num = Integer.format (tmp, v, Integer.Style.Unsigned);
                        if ((minimum -= num.length) > 0)
                           {
                           auto p = tmp.ptr + tmp.length - num.length;
                           while (minimum--)
                                  *--p = '0';
                           num = tmp [p-tmp.ptr .. $];
                           }
                        return num;
                }

                int parseQuote(char[] format, int pos, out char[] result)
                {
                        int start = pos;
                        char chQuote = format[pos++];
                        bool found;
                        while (pos < format.length)
                              {
                              char c = format[pos++];
                              if (c is chQuote)
                                 {
                                 found = true;
                                 break;
                                 }
                              else
                                 if (c is '\\')
                                    { // escaped
                                    if (pos < format.length)
                                        result ~= format[pos++];
                                    }
                                 else
                                    result ~= c;
                              }
                        return pos - start;
                }


                Calendar calendar = dtf.calendar;
                bool justTime = true;
                int index, len;
                char[10] tmp;

                if (format[0] is '%')
                    {
                    // specifiers for both standard format strings and custom ones
                    const char[] commonSpecs = "dmMsty";
                    foreach (c; commonSpecs)
                        if (format[1] is c)
                            {
                            index += 1;
                            break;
                            }
                    }

                while (index < format.length)
                      {
                      char c = format[index];
                      auto time = dateTime.time;

                      switch (c)
                             {
                             case 'd':  // day
                                  len = parseRepeat(format, index, c);
                                  if (len <= 2)
                                     {
                                     int day = calendar.getDayOfMonth(dateTime);
                                     result ~= formatInt (tmp, day, len);
                                     }
                                  else
                                     result ~= formatDayOfWeek(calendar.getDayOfWeek(dateTime), len);
                                  justTime = false;
                                  break;

                             case 'M':  // month
                                  len = parseRepeat(format, index, c);
                                  int month = calendar.getMonth(dateTime);
                                  if (len <= 2)
                                      result ~= formatInt (tmp, month, len);
                                  else
                                     result ~= formatMonth(month, len);
                                  justTime = false;
                                  break;
                             case 'y':  // year
                                  len = parseRepeat(format, index, c);
                                  int year = calendar.getYear(dateTime);
                                  // Two-digit years for Japanese
                                  if (calendar.id is Calendar.JAPAN)
                                      result ~= formatInt (tmp, year, 2);
                                  else
                                     {
                                     if (len <= 2)
                                         result ~= formatInt (tmp, year % 100, len);
                                     else
                                        result ~= formatInt (tmp, year, len);
                                     }
                                  justTime = false;
                                  break;
                             case 'h':  // hour (12-hour clock)
                                  len = parseRepeat(format, index, c);
                                  int hour = time.hours % 12;
                                  if (hour is 0)
                                      hour = 12;
                                  result ~= formatInt (tmp, hour, len);
                                  break;
                             case 'H':  // hour (24-hour clock)
                                  len = parseRepeat(format, index, c);
                                  result ~= formatInt (tmp, time.hours, len);
                                  break;
                             case 'm':  // minute
                                  len = parseRepeat(format, index, c);
                                  result ~= formatInt (tmp, time.minutes, len);
                                  break;
                             case 's':  // second
                                  len = parseRepeat(format, index, c);
                                  result ~= formatInt (tmp, time.seconds, len);
                                  break;
                             case 't':  // AM/PM
                                  len = parseRepeat(format, index, c);
                                  if (len is 1)
                                     {
                                     if (time.hours < 12)
                                        {
                                        if (dtf.amDesignator.length != 0)
                                            result ~= dtf.amDesignator[0];
                                        }
                                     else
                                        {
                                        if (dtf.pmDesignator.length != 0)
                                            result ~= dtf.pmDesignator[0];
                                        }
                                     }
                                  else
                                     result ~= (time.hours < 12) ? dtf.amDesignator : dtf.pmDesignator;
                                  break;
                             case 'z':  // timezone offset
                                  len = parseRepeat(format, index, c);
version (Full)
{
                                  TimeSpan offset = (justTime && dateTime.ticks < TICKS_PER_DAY)
                                                     ? TimeZone.current.getUtcOffset(WallClock.now)
                                                     : TimeZone.current.getUtcOffset(dateTime);
                                  int hours = offset.hours;
                                  int minutes = offset.minutes;
                                  result ~= (offset.backward) ? '-' : '+';
}
else
{
                                  auto minutes = cast(int) (WallClock.zone.minutes);
                                  if (minutes < 0)
                                      minutes = -minutes, result ~= '-';
                                  else
                                     result ~= '+';
                                  int hours = minutes / 60;
                                  minutes %= 60;
}
                                  if (len is 1)
                                      result ~= formatInt (tmp, hours, 1);
                                  else
                                     if (len is 2)
                                         result ~= formatInt (tmp, hours, 2);
                                     else
                                        {
                                        result ~= formatInt (tmp, hours, 2);
                                        result ~= ':';
                                        result ~= formatInt (tmp, minutes, 2);
                                        }
                                  break;
                             case ':':  // time separator
                                  len = 1;
                                  result ~= dtf.timeSeparator;
                                  break;
                             case '/':  // date separator
                                  len = 1;
                                  result ~= dtf.dateSeparator;
                                  break;
                             case '\"':  // string literal
                             case '\'':  // char literal
                                  char[] quote;
                                  len = parseQuote(format, index, quote);
                                  result ~= quote;
                                  break;
                             default:
                                 len = 1;
                                 result ~= c;
                                 break;
                             }
                      index += len;
                      }
                return result.get;
        }


        auto result = Result (output);

        if (format is null)
            format = "G"; // Default to general format.

        if (format.length is 1) // It might be one of our shortcuts.
            format = expandKnownFormat (format, dateTime);

        return formatCustom (result, dateTime, format);
}



/*******************************************************************************

*******************************************************************************/

private extern (C) private char* ecvt(double d, int digits, out int decpt, out bool sign);

/*******************************************************************************

*******************************************************************************/

// Must match NumberFormat.decimalPositivePattern
package const   char[] positiveNumberFormat = "#";

// Must match NumberFormat.decimalNegativePattern
package const   char[][] negativeNumberFormats =
                [
                "(#)", "-#", "- #", "#-", "# -"
                ];

// Must match NumberFormat.currencyPositivePattern
package const   char[][] positiveCurrencyFormats =
                [
                "$#", "#$", "$ #", "# $"
                ];

// Must match NumberFormat.currencyNegativePattern
package const   char[][] negativeCurrencyFormats =
                [
                "($#)", "-$#", "$-#", "$#-", "(#$)",
                "-#$", "#-$", "#$-", "-# $", "-$ #",
                "# $-", "$ #-", "$ -#", "#- $", "($ #)", "(# $)"
                ];

/*******************************************************************************

*******************************************************************************/

package template charTerm (T)
{
        package int charTerm(T* s)
        {
                int i;
                while (*s++ != '\0')
                        i++;
                return i;
        }
}

/*******************************************************************************

*******************************************************************************/

char[] longToString (char[] buffer, long value, int digits, char[] negativeSign)
{
        if (digits < 1)
            digits = 1;

        int n = buffer.length;
        ulong uv = (value >= 0) ? value : cast(ulong) -value;

        if (uv > uint.max)
           {
           while (--digits >= 0 || uv != 0)
                 {
                 buffer[--n] = uv % 10 + '0';
                 uv /= 10;
                 }
           }
        else
           {
           uint v = cast(uint) uv;
           while (--digits >= 0 || v != 0)
                 {
                 buffer[--n] = v % 10 + '0';
                 v /= 10;
                 }
           }


        if (value < 0)
           {
           for (int i = negativeSign.length - 1; i >= 0; i--)
                buffer[--n] = negativeSign[i];
           }

        return buffer[n .. $];
}

/*******************************************************************************

*******************************************************************************/

char[] longToHexString (char[] buffer, ulong value, int digits, char format)
{
        if (digits < 1)
            digits = 1;

        int n = buffer.length;
        while (--digits >= 0 || value != 0)
              {
              auto v = cast(uint) value & 0xF;
              buffer[--n] = (v < 10) ? v + '0' : v + format - ('X' - 'A' + 10);
              value >>= 4;
              }

        return buffer[n .. $];
}

/*******************************************************************************

*******************************************************************************/

char[] longToBinString (char[] buffer, ulong value, int digits)
{
        if (digits < 1)
            digits = 1;

        int n = buffer.length;
        while (--digits >= 0 || value != 0)
              {
              buffer[--n] = (value & 1) + '0';
              value >>= 1;
              }

        return buffer[n .. $];
}

/*******************************************************************************

*******************************************************************************/

char parseFormatSpecifier (char[] format, out int length)
{
        int     i = -1;
        char    specifier;

        if (format.length)
           {
           auto s = format[0];

           if (s >= 'A' && s <= 'Z' || s >= 'a' && s <= 'z')
              {
              specifier = s;

              foreach (c; format [1..$])
                       if (c >= '0' && c <= '9')
                          {
                          c -= '0';
                          if (i < 0)
                             i = c;
                          else
                             i = i * 10 + c;
                          }
                       else
                          break;
              }
           }
        else
           specifier = 'G';

        length = i;
        return specifier;
}

/*******************************************************************************

*******************************************************************************/

char[] formatInteger (char[] output, long value, char[] format, NumberFormat nf)
{
        int     length;
        auto    specifier = parseFormatSpecifier (format, length);

        switch (specifier)
               {
               case 'g':
               case 'G':
                    if (length > 0)
                        break;
                    // Fall through.

               case 'd':
               case 'D':
                    return longToString (output, value, length, nf.negativeSign);

               case 'x':
               case 'X':
                    return longToHexString (output, cast(ulong)value, length, specifier);

               case 'b':
               case 'B':
                    return longToBinString (output, cast(ulong)value, length);

               default:
                    break;
               }

        Result result = Result (output);
        Number number = Number (value);
        if (specifier != char.init)
            return toString (number, result, specifier, length, nf);

        return number.toStringFormat (result, format, nf);
}

/*******************************************************************************

*******************************************************************************/

private enum {
             EXP = 0x7ff,
             NAN_FLAG = 0x80000000,
             INFINITY_FLAG = 0x7fffffff,
             }

char[] formatDouble (char[] output, double value, char[] format, NumberFormat nf)
{
        int length;
        int precision = 6;
        Result result = Result (output);
        char specifier = parseFormatSpecifier (format, length);

        switch (specifier)
               {
               case 'r':
               case 'R':
                    Number number = Number (value, 15);

                    if (number.scale == NAN_FLAG)
                        return nf.nanSymbol;

                    if (number.scale == INFINITY_FLAG)
                        return number.sign ? nf.negativeInfinitySymbol
                                           : nf.positiveInfinitySymbol;

                    double d;
                    number.toDouble(d);
                    if (d == value)
                        return toString (number, result, 'G', 15, nf);

                    number = Number(value, 17);
                    return toString (number, result, 'G', 17, nf);

               case 'g':
               case 'G':
                    if (length > 15)
                        precision = 17;
                    // Fall through.

               default:
                    break;
        }

        Number number = Number(value, precision);

        if (number.scale == NAN_FLAG)
            return nf.nanSymbol;

        if (number.scale == INFINITY_FLAG)
            return number.sign ? nf.negativeInfinitySymbol
                               : nf.positiveInfinitySymbol;

        if (specifier != char.init)
            return toString (number, result, specifier, length, nf);

        return number.toStringFormat (result, format, nf);
}

/*******************************************************************************

*******************************************************************************/

void formatGeneral (inout Number number, inout Result target, int length, char format, NumberFormat nf)
{
        int pos = number.scale;

        auto p = number.digits.ptr;
        if (pos > 0)
           {
           while (pos > 0)
                 {
                 target ~= (*p != '\0') ? *p++ : '0';
                 pos--;
                 }
           }
        else
           target ~= '0';

        if (*p != '\0')
           {
           target ~= nf.numberDecimalSeparator;
           while (pos < 0)
                 {
                 target ~= '0';
                 pos++;
                 }

           while (*p != '\0')
                  target ~= *p++;
           }
}

/*******************************************************************************

*******************************************************************************/

void formatNumber (inout Number number, inout Result target, int length, NumberFormat nf)
{
        char[] format = number.sign ? negativeNumberFormats[nf.numberNegativePattern]
                                    : positiveNumberFormat;

        // Parse the format.
        foreach (c; format)
                {
                switch (c)
                       {
                       case '#':
                            formatFixed (number, target, length, nf.numberGroupSizes,
                                         nf.numberDecimalSeparator, nf.numberGroupSeparator);
                            break;

                       case '-':
                            target ~= nf.negativeSign;
                            break;

                       default:
                            target ~= c;
                            break;
                       }
                }
}

/*******************************************************************************

*******************************************************************************/

void formatCurrency (inout Number number, inout Result target, int length, NumberFormat nf)
{
        char[] format = number.sign ? negativeCurrencyFormats[nf.currencyNegativePattern]
                                    : positiveCurrencyFormats[nf.currencyPositivePattern];

        // Parse the format.
        foreach (c; format)
                {
                switch (c)
                       {
                       case '#':
                            formatFixed (number, target, length, nf.currencyGroupSizes,
                                         nf.currencyDecimalSeparator, nf.currencyGroupSeparator);
                            break;

                       case '-':
                            target ~= nf.negativeSign;
                            break;

                       case '$':
                            target ~= nf.currencySymbol;
                            break;

                       default:
                            target ~= c;
                            break;
                       }
                }
}

/*******************************************************************************

*******************************************************************************/

void formatFixed (inout Number number, inout Result target, int length,
                  int[] groupSizes, char[] decimalSeparator, char[] groupSeparator)
{
        int pos = number.scale;
        auto p = number.digits.ptr;

        if (pos > 0)
           {
           if (groupSizes.length != 0)
              {
              // Calculate whether we have enough digits to format.
              int count = groupSizes[0];
              int index, size;

              while (pos > count)
                    {
                    size = groupSizes[index];
                    if (size == 0)
                        break;

                    if (index < groupSizes.length - 1)
                       index++;

                    count += groupSizes[index];
                    }

              size = (count == 0) ? 0 : groupSizes[0];

              // Insert the separator according to groupSizes.
              int end = charTerm(p);
              int start = (pos < end) ? pos : end;


              char[] separator = groupSeparator;
              index = 0;

              // questionable: use the back end of the output buffer to
              // format the separators, and then copy back to start
              char[] temp = target.scratch;
              uint ii = temp.length;

              for (int c, i = pos - 1; i >= 0; i--)
                  {
                  temp[--ii] = (i < start) ? number.digits[i] : '0';
                  if (size > 0)
                     {
                     c++;
                     if (c == size && i != 0)
                        {
                        uint iii = ii - separator.length;
                        temp[iii .. ii] = separator;
                        ii = iii;

                        if (index < groupSizes.length - 1)
                            size = groupSizes[++index];

                        c = 0;
                        }
                     }
                  }
              target ~= temp[ii..$];
              p += start;
              }
           else
              {
              while (pos > 0)
                    {
                    target ~= (*p != '\0') ? *p++ : '0';
                    pos--;
                    }
              }
           }
        else
           // Negative scale.
           target ~= '0';

        if (length > 0)
           {
           target ~= decimalSeparator;
           while (pos < 0 && length > 0)
                 {
                 target ~= '0';
                 pos++;
                 length--;
                 }

           while (length > 0)
                 {
                 target ~= (*p != '\0') ? *p++ : '0';
                 length--;
                 }
           }
}

/******************************************************************************

******************************************************************************/

char[] toString (inout Number number, inout Result result, char format, int length, NumberFormat nf)
{
        switch (format)
               {
               case 'c':
               case 'C':
                     // Currency
                     if (length < 0)
                         length = nf.currencyDecimalDigits;

                     number.round(number.scale + length);
                     formatCurrency (number, result, length, nf);
                     break;

               case 'f':
               case 'F':
                     // Fixed
                     if (length < 0)
                         length = nf.numberDecimalDigits;

                     number.round(number.scale + length);
                     if (number.sign)
                         result ~= nf.negativeSign;

                     formatFixed (number, result, length, null, nf.numberDecimalSeparator, null);
                     break;

               case 'n':
               case 'N':
                     // Number
                        if (length < 0)
                            length = nf.numberDecimalDigits;

                     number.round (number.scale + length);
                     formatNumber (number, result, length, nf);
                     break;

               case 'g':
               case 'G':
                     // General
                     if (length < 1)
                         length = number.precision;

                     number.round(length);
                     if (number.sign)
                         result ~= nf.negativeSign;

                     formatGeneral (number, result, length, (format == 'g') ? 'e' : 'E', nf);
                     break;

               default:
                     return "{invalid FP format specifier '" ~ format ~ "'}";
               }
        return result.get;
}


/*******************************************************************************

*******************************************************************************/

private struct Number
{
        int scale;
        bool sign;
        int precision;
        char[32] digits = void;

        /**********************************************************************

        **********************************************************************/

        private static Number opCall (long value)
        {
                Number number;
                number.precision = 20;

                if (value < 0)
                   {
                   number.sign = true;
                   value = -value;
                   }

                char[20] buffer = void;
                int n = buffer.length;

                while (value != 0)
                      {
                      buffer[--n] = value % 10 + '0';
                      value /= 10;
                      }

                int end = number.scale = -(n - buffer.length);
                number.digits[0 .. end] = buffer[n .. n + end];
                number.digits[end] = '\0';

                return number;
        }

        /**********************************************************************

        **********************************************************************/

        private static Number opCall (double value, int precision)
        {
                Number number;
                number.precision = precision;

                auto p = number.digits.ptr;
                long bits = *cast(long*) & value;
                long mant = bits & 0x000FFFFFFFFFFFFFL;
                int exp = cast(int)((bits >> 52) & EXP);

                if (exp == EXP)
                   {
                   number.scale = (mant != 0) ? NAN_FLAG : INFINITY_FLAG;
                   if (((bits >> 63) & 1) != 0)
                         number.sign = true;
                   }
                else
                   {
                   // Get the digits, decimal point and sign.
                   char* chars = ecvt(value, number.precision, number.scale, number.sign);
                   if (*chars != '\0')
                      {
                      while (*chars != '\0')
                             *p++ = *chars++;
                      }
                   }

                *p = '\0';
                return number;
        }

        /**********************************************************************

        **********************************************************************/

        private bool toDouble(out double value)
        {
                const   ulong[] pow10 =
                        [
                        0xa000000000000000UL,
                        0xc800000000000000UL,
                        0xfa00000000000000UL,
                        0x9c40000000000000UL,
                        0xc350000000000000UL,
                        0xf424000000000000UL,
                        0x9896800000000000UL,
                        0xbebc200000000000UL,
                        0xee6b280000000000UL,
                        0x9502f90000000000UL,
                        0xba43b74000000000UL,
                        0xe8d4a51000000000UL,
                        0x9184e72a00000000UL,
                        0xb5e620f480000000UL,
                        0xe35fa931a0000000UL,
                        0xcccccccccccccccdUL,
                        0xa3d70a3d70a3d70bUL,
                        0x83126e978d4fdf3cUL,
                        0xd1b71758e219652eUL,
                        0xa7c5ac471b478425UL,
                        0x8637bd05af6c69b7UL,
                        0xd6bf94d5e57a42beUL,
                        0xabcc77118461ceffUL,
                        0x89705f4136b4a599UL,
                        0xdbe6fecebdedd5c2UL,
                        0xafebff0bcb24ab02UL,
                        0x8cbccc096f5088cfUL,
                        0xe12e13424bb40e18UL,
                        0xb424dc35095cd813UL,
                        0x901d7cf73ab0acdcUL,
                        0x8e1bc9bf04000000UL,
                        0x9dc5ada82b70b59eUL,
                        0xaf298d050e4395d6UL,
                        0xc2781f49ffcfa6d4UL,
                        0xd7e77a8f87daf7faUL,
                        0xefb3ab16c59b14a0UL,
                        0x850fadc09923329cUL,
                        0x93ba47c980e98cdeUL,
                        0xa402b9c5a8d3a6e6UL,
                        0xb616a12b7fe617a8UL,
                        0xca28a291859bbf90UL,
                        0xe070f78d39275566UL,
                        0xf92e0c3537826140UL,
                        0x8a5296ffe33cc92cUL,
                        0x9991a6f3d6bf1762UL,
                        0xaa7eebfb9df9de8aUL,
                        0xbd49d14aa79dbc7eUL,
                        0xd226fc195c6a2f88UL,
                        0xe950df20247c83f8UL,
                        0x81842f29f2cce373UL,
                        0x8fcac257558ee4e2UL,
                        ];

                const   uint[] pow10Exp =
                        [
                        4, 7, 10, 14, 17, 20, 24, 27, 30, 34,
                        37, 40, 44, 47, 50, 54, 107, 160, 213, 266,
                        319, 373, 426, 479, 532, 585, 638, 691, 745, 798,
                        851, 904, 957, 1010, 1064, 1117
                        ];

                uint getDigits(char* p, int len)
                {
                        char* end = p + len;
                        uint r = *p - '0';
                        p++;
                        while (p < end)
                              {
                              r = 10 * r + *p - '0';
                              p++;
                              }
                        return r;
                }

                ulong mult64(uint val1, uint val2)
                {
                        return cast(ulong)val1 * cast(ulong)val2;
                }

                ulong mult64L(ulong val1, ulong val2)
                {
                        ulong v = mult64(cast(uint)(val1 >> 32), cast(uint)(val2 >> 32));
                        v += mult64(cast(uint)(val1 >> 32), cast(uint)val2) >> 32;
                        v += mult64(cast(uint)val1, cast(uint)(val2 >> 32)) >> 32;
                        return v;
                }

                auto p = digits.ptr;
                int count = charTerm(p);
                int left = count;

                while (*p == '0')
                      {
                      left--;
                      p++;
                      }

                // If the digits consist of nothing but zeros...
                if (left == 0)
                   {
                   value = 0.0;
                   return true;
                   }

                // Get digits, 9 at a time.
                int n = (left > 9) ? 9 : left;
                left -= n;
                ulong bits = getDigits(p, n);
                if (left > 0)
                   {
                   n = (left > 9) ? 9 : left;
                   left -= n;
                   bits = mult64(cast(uint)bits, cast(uint)(pow10[n - 1] >>> (64 - pow10Exp[n - 1])));
                   bits += getDigits(p + 9, n);
                   }

                int scale = this.scale - (count - left);
                int s = (scale < 0) ? -scale : scale;

                if (s >= 352)
                   {
                   *cast(long*)&value = (scale > 0) ? 0x7FF0000000000000 : 0;
                   return false;
                   }

                // Normalise mantissa and bits.
                int bexp = 64;
                int nzero;
                if ((bits >> 32) != 0)
                     nzero = 32;

                if ((bits >> (16 + nzero)) != 0)
                     nzero += 16;

                if ((bits >> (8 + nzero)) != 0)
                     nzero += 8;

                if ((bits >> (4 + nzero)) != 0)
                     nzero += 4;

                if ((bits >> (2 + nzero)) != 0)
                     nzero += 2;

                if ((bits >> (1 + nzero)) != 0)
                     nzero++;

                if ((bits >> nzero) != 0)
                     nzero++;

                bits <<= 64 - nzero;
                bexp -= 64 - nzero;

                // Get decimal exponent.
                if ((s & 15) != 0)
                   {
                   int expMult = pow10Exp[(s & 15) - 1];
                   bexp += (scale < 0) ? ( -expMult + 1) : expMult;
                   bits = mult64L(bits, pow10[(s & 15) + ((scale < 0) ? 15 : 0) - 1]);
                   if ((bits & 0x8000000000000000L) == 0)
                      {
                      bits <<= 1;
                      bexp--;
                      }
                   }

                if ((s >> 4) != 0)
                   {
                   int expMult = pow10Exp[15 + ((s >> 4) - 1)];
                   bexp += (scale < 0) ? ( -expMult + 1) : expMult;
                   bits = mult64L(bits, pow10[30 + ((s >> 4) + ((scale < 0) ? 21 : 0) - 1)]);
                   if ((bits & 0x8000000000000000L) == 0)
                      {
                      bits <<= 1;
                      bexp--;
                      }
                   }

                // Round and scale.
                if (cast(uint)bits & (1 << 10) != 0)
                   {
                   bits += (1 << 10) - 1 + (bits >>> 11) & 1;
                   bits >>= 11;
                   if (bits == 0)
                       bexp++;
                   }
                else
                   bits >>= 11;

                bexp += 1022;
                if (bexp <= 0)
                   {
                   if (bexp < -53)
                       bits = 0;
                   else
                      bits >>= ( -bexp + 1);
                   }
                bits = (cast(ulong)bexp << 52) + (bits & 0x000FFFFFFFFFFFFFL);

                if (sign)
                    bits |= 0x8000000000000000L;

                value = *cast(double*) & bits;
                return true;
        }



        /**********************************************************************

        **********************************************************************/

        private char[] toStringFormat (inout Result result, char[] format, NumberFormat nf)
        {
                bool hasGroups;
                int groupCount;
                int groupPos = -1, pointPos = -1;
                int first = int.max, last, count;
                bool scientific;
                int n;
                char c;

                while (n < format.length)
                      {
                      c = format[n++];
                      switch (c)
                             {
                             case '#':
                                  count++;
                                  break;

                             case '0':
                                  if (first == int.max)
                                      first = count;
                                  count++;
                                  last = count;
                                  break;

                             case '.':
                                  if (pointPos < 0)
                                      pointPos = count;
                                  break;

                             case ',':
                                  if (count > 0 && pointPos < 0)
                                     {
                                     if (groupPos >= 0)
                                        {
                                        if (groupPos == count)
                                           {
                                           groupCount++;
                                           break;
                                           }
                                        hasGroups = true;
                                        }
                                     groupPos = count;
                                     groupCount = 1;
                                     }
                                  break;

                             case '\'':
                             case '\"':
                                   while (n < format.length && format[n++] != c)
                                         {}
                                   break;

                             case '\\':
                                  if (n < format.length)
                                      n++;
                                  break;

                             default:
                                  break;
                             }
                      }

                if (pointPos < 0)
                    pointPos = count;

                int adjust;
                if (groupPos >= 0)
                   {
                   if (groupPos == pointPos)
                       adjust -= groupCount * 3;
                   else
                      hasGroups = true;
                   }

                if (digits[0] != '\0')
                   {
                   scale += adjust;
                   round(scientific ? count : scale + count - pointPos);
                   }

                first = (first < pointPos) ? pointPos - first : 0;
                last = (last > pointPos) ? pointPos - last : 0;

                int pos = pointPos;
                int extra;
                if (!scientific)
                   {
                   pos = (scale > pointPos) ? scale : pointPos;
                   extra = scale - pointPos;
                   }

                char[] groupSeparator = nf.numberGroupSeparator;
                char[] decimalSeparator = nf.numberDecimalSeparator;

                // Work out the positions of the group separator.
                int[] groupPositions;
                int groupIndex = -1;
                if (hasGroups)
                   {
                   if (nf.numberGroupSizes.length == 0)
                       hasGroups = false;
                   else
                      {
                      int groupSizesTotal = nf.numberGroupSizes[0];
                      int groupSize = groupSizesTotal;
                      int digitsTotal = pos + ((extra < 0) ? extra : 0);
                      int digitCount = (first > digitsTotal) ? first : digitsTotal;

                      int sizeIndex;
                      while (digitCount > groupSizesTotal)
                            {
                            if (groupSize == 0)
                                break;

                            groupPositions ~= groupSizesTotal;
                            groupIndex++;

                            if (sizeIndex < nf.numberGroupSizes.length - 1)
                                groupSize = nf.numberGroupSizes[++sizeIndex];

                            groupSizesTotal += groupSize;
                            }
                      }
                }

                //char[] result;
                if (sign)
                    result ~= nf.negativeSign;

                auto p = digits.ptr;
                n = 0;
                bool pointWritten;

                while (n < format.length)
                      {
                      c = format[n++];
                      if (extra > 0 && (c == '#' || c == '0' || c == '.'))
                         {
                         while (extra > 0)
                               {
                               result ~= (*p != '\0') ? *p++ : '0';

                               if (hasGroups && pos > 1 && groupIndex >= 0)
                                  {
                                  if (pos == groupPositions[groupIndex] + 1)
                                     {
                                     result ~= groupSeparator;
                                     groupIndex--;
                                     }
                                  }
                               pos--;
                               extra--;
                               }
                         }

                      switch (c)
                             {
                             case '#':
                             case '0':
                                  if (extra < 0)
                                     {
                                     extra++;
                                     c = (pos <= first) ? '0' : char.init;
                                     }
                                  else
                                     c = (*p != '\0') ? *p++ : pos > last ? '0' : char.init;

                                  if (c != char.init)
                                     {
                                     result ~= c;

                                     if (hasGroups && pos > 1 && groupIndex >= 0)
                                        {
                                        if (pos == groupPositions[groupIndex] + 1)
                                           {
                                           result ~= groupSeparator;
                                           groupIndex--;
                                           }
                                        }
                                     }
                                  pos--;
                                  break;

                             case '.':
                                  if (pos != 0 || pointWritten)
                                      break;
                                  if (last < 0 || (pointPos < count && *p != '\0'))
                                     {
                                     result ~= decimalSeparator;
                                     pointWritten = true;
                                     }
                                  break;

                             case ',':
                                  break;

                             case '\'':
                             case '\"':
                                  if (n < format.length)
                                      n++;
                                  break;

                             case '\\':
                                  if (n < format.length)
                                      result ~= format[n++];
                                  break;

                             default:
                                  result ~= c;
                                  break;
                             }
                      }
                return result.get;
        }

        /**********************************************************************

        **********************************************************************/

        private void round (int pos)
        {
                int index;
                while (index < pos && digits[index] != '\0')
                       index++;

                if (index == pos && digits[index] >= '5')
                   {
                   while (index > 0 && digits[index - 1] == '9')
                          index--;

                   if (index > 0)
                       digits[index - 1]++;
                   else
                      {
                      scale++;
                      digits[0] = '1';
                      index = 1;
                      }
                   }
                else
                   while (index > 0 && digits[index - 1] == '0')
                          index--;

                if (index == 0)
                   {
                   scale = 0;
                   sign = false;
                   }

                digits[index] = '\0';
        }
}
