/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.time.chrono.Calendar;

public  import tango.time.Time;

private import tango.core.Exception;



/**
 * $(ANCHOR _Calendar)
 * Represents time in week, month and year divisions.
 * Remarks: Calendar is the abstract base class for the following Calendar implementations: 
 *   $(LINK2 #Gregorian, Gregorian), $(LINK2 #Hebrew, Hebrew), $(LINK2 #Hijri, Hijri),
 *   $(LINK2 #Japanese, Japanese), $(LINK2 #Korean, Korean), $(LINK2 #Taiwan, Taiwan) and
 *   $(LINK2 #ThaiBuddhist, ThaiBuddhist).
 */
public abstract class Calendar 
{
        /**
        * Indicates the current era of the calendar.
        */
        package enum {CURRENT_ERA = 0};

        // Corresponds to Win32 calendar IDs
        package enum 
        {
                GREGORIAN = 1,
                GREGORIAN_US = 2,
                JAPAN = 3,
                TAIWAN = 4,
                KOREA = 5,
                HIJRI = 6,
                THAI = 7,
                HEBREW = 8,
                GREGORIAN_ME_FRENCH = 9,
                GREGORIAN_ARABIC = 10,
                GREGORIAN_XLIT_ENGLISH = 11,
                GREGORIAN_XLIT_FRENCH = 12
        }

        package enum WeekRule 
        {
                FirstDay,         /// Indicates that the first week of the year is the first week containing the first day of the year.
                FirstFullWeek,    /// Indicates that the first week of the year is the first full week following the first day of the year.
                FirstFourDayWeek  /// Indicates that the first week of the year is the first week containing at least four days.
        }

        package enum DatePart
        {
                Year,
                Month,
                Day,
                DayOfYear
        }

        public enum DayOfWeek 
        {
                Sunday,    /// Indicates _Sunday.
                Monday,    /// Indicates _Monday.
                Tuesday,   /// Indicates _Tuesday.
                Wednesday, /// Indicates _Wednesday.
                Thursday,  /// Indicates _Thursday.
                Friday,    /// Indicates _Friday.
                Saturday   /// Indicates _Saturday.
        }


        /**
         * Get the components of a Time structure using the rules of the
         * calendar.  This is useful if you want more than one of the given
         * components.  Note that this doesn't handle the time of day, as that
         * is calculated directly from the Time struct.
         *
         * The default implemenation is to call all the other accessors
         * directly, a derived class may override if it has a more efficient
         * method.
         */
        Date toDate (Time time)
        {
                Date d;
                split (time, d.year, d.month, d.day, d.doy, d.dow, d.era);
                return d;
        }

        /**
         * Get the components of a Time structure using the rules of the
         * calendar.  This is useful if you want more than one of the given
         * components.  Note that this doesn't handle the time of day, as that
         * is calculated directly from the Time struct.
         *
         * The default implemenation is to call all the other accessors
         * directly, a derived class may override if it has a more efficient
         * method.
         */
        void split (Time time, ref uint year, ref uint month, ref uint day, ref uint doy, ref uint dow, ref uint era)
        {
            year = getYear(time);
            month = getMonth(time);
            day = getDayOfMonth(time);
            doy = getDayOfYear(time);
            dow = getDayOfWeek(time);
            era = getEra(time);
        }

        /**
        * Returns a Time value set to the specified date and time in the current era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        *   day = An integer representing the _day.
        *   hour = An integer representing the _hour.
        *   minute = An integer representing the _minute.
        *   second = An integer representing the _second.
        *   millisecond = An integer representing the _millisecond.
        * Returns: The Time set to the specified date and time.
        */
        Time toTime (uint year, uint month, uint day, uint hour, uint minute, uint second, uint millisecond=0) 
        {
                return toTime (year, month, day, hour, minute, second, millisecond, CURRENT_ERA);
        }

        Time toTime (Date d) 
        {
                return toTime (d.year, d.month, d.day, 0, 0, 0, 0, d.era);
        }

        Time toTime (DateTime dt) 
        {
                return toTime (dt.date, dt.time);
        }

        Time toTime (Date d, TimeOfDay t) 
        {
                return toTime (d.year, d.month, d.day, t.hours, t.minutes, t.seconds, t.millis, d.era);
        }

        /**
        * When overridden, returns a Time value set to the specified date and time in the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        *   day = An integer representing the _day.
        *   hour = An integer representing the _hour.
        *   minute = An integer representing the _minute.
        *   second = An integer representing the _second.
        *   millisecond = An integer representing the _millisecond.
        *   era = An integer representing the _era.
        * Returns: A Time set to the specified date and time.
        */
        abstract Time toTime (uint year, uint month, uint day, uint hour, uint minute, uint second, uint millisecond, uint era);

        /**
        * When overridden, returns the day of the week in the specified Time.
        * Params: time = A Time value.
        * Returns: A DayOfWeek value representing the day of the week of time.
        */
        abstract DayOfWeek getDayOfWeek (Time time);

        /**
        * When overridden, returns the day of the month in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the day of the month of time.
        */
        abstract uint getDayOfMonth (Time time);

        /**
        * When overridden, returns the day of the year in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the day of the year of time.
        */
        abstract uint getDayOfYear (Time time);

        /**
        * When overridden, returns the month in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the month in time.
        */
        abstract uint getMonth (Time time);

        /**
        * When overridden, returns the year in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the year in time.
        */
        abstract uint getYear (Time time);

        /**
        * When overridden, returns the era in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the ear in time.
        */
        abstract uint getEra (Time time);

        /**
        * Returns the number of days in the specified _year and _month of the current era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        * Returns: The number of days in the specified _year and _month of the current era.
        */
        uint getDaysInMonth (uint year, uint month) 
        {
                return getDaysInMonth (year, month, CURRENT_ERA);
        }

        /**
        * When overridden, returns the number of days in the specified _year and _month of the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        *   era = An integer representing the _era.
        * Returns: The number of days in the specified _year and _month of the specified _era.
        */
        abstract uint getDaysInMonth (uint year, uint month, uint era);

        /**
        * Returns the number of days in the specified _year of the current era.
        * Params: year = An integer representing the _year.
        * Returns: The number of days in the specified _year in the current era.
        */
        uint getDaysInYear (uint year) 
        {
                return getDaysInYear (year, CURRENT_ERA);
        }

        /**
        * When overridden, returns the number of days in the specified _year of the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   era = An integer representing the _era.
        * Returns: The number of days in the specified _year in the specified _era.
        */
        abstract uint getDaysInYear (uint year, uint era);

        /**
        * Returns the number of months in the specified _year of the current era.
        * Params: year = An integer representing the _year.
        * Returns: The number of months in the specified _year in the current era.
        */
        uint getMonthsInYear (uint year) 
        {
                return getMonthsInYear (year, CURRENT_ERA);
        }

        /**
        * When overridden, returns the number of months in the specified _year of the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   era = An integer representing the _era.
        * Returns: The number of months in the specified _year in the specified _era.
        */
        abstract uint getMonthsInYear (uint year, uint era);

        /**
        * Returns the week of the year that includes the specified Time.
        * Params:
        *   time = A Time value.
        *   rule = A WeekRule value defining a calendar week.
        *   firstDayOfWeek = A DayOfWeek value representing the first day of the week.
        * Returns: An integer representing the week of the year that includes the date in time.
        */
        uint getWeekOfYear (Time time, WeekRule rule, DayOfWeek firstDayOfWeek) 
        {
                auto year = getYear (time);
                auto jan1 = cast(int) getDayOfWeek (toTime (year, 1, 1, 0, 0, 0, 0));

                switch (rule) 
                       {
                       case WeekRule.FirstDay:
                            int n = jan1 - cast(int) firstDayOfWeek;
                            if (n < 0)
                                n += 7;
                            return (getDayOfYear (time) + n - 1) / 7 + 1;

                       case WeekRule.FirstFullWeek:
                       case WeekRule.FirstFourDayWeek:
                            int fullDays = (rule is WeekRule.FirstFullWeek) ? 7 : 4;
                            int n = cast(int) firstDayOfWeek - jan1;
                            if (n != 0) 
                               {
                               if (n < 0)
                                   n += 7;
                               else 
                                  if (n >= fullDays)
                                      n -= 7;
                               }

                            int day = getDayOfYear (time) - n;
                            if (day > 0)
                                return (day - 1) / 7 + 1;
                            year = getYear(time) - 1;
                            int month = getMonthsInYear (year);
                            day = getDaysInMonth (year, month);
                            return getWeekOfYear(toTime(year, month, day, 0, 0, 0, 0), rule, firstDayOfWeek);

                       default:
                            break;
                       }
                throw new IllegalArgumentException("Value was out of range.");
        }

        /**
        * Indicates whether the specified _year in the current era is a leap _year.
        * Params: year = An integer representing the _year.
        * Returns: true is the specified _year is a leap _year; otherwise, false.
        */
        bool isLeapYear(uint year) 
        {
                return isLeapYear(year, CURRENT_ERA);
        }

        /**
        * When overridden, indicates whether the specified _year in the specified _era is a leap _year.
        * Params: year = An integer representing the _year.
        * Params: era = An integer representing the _era.
        * Returns: true is the specified _year is a leap _year; otherwise, false.
        */
        abstract bool isLeapYear(uint year, uint era);

        /**
        * $(I Property.) When overridden, retrieves the list of eras in the current calendar.
        * Returns: An integer array representing the eras in the current calendar.
        */
        abstract uint[] eras();

        /**
        * $(I Property.) Retrieves the identifier associated with the current calendar.
        * Returns: An integer representing the identifier of the current calendar.
        */
        uint id() 
        {
                return -1;
        }

        package static long getTimeTicks (uint hour, uint minute, uint second) 
        {
                return (TimeSpan.hours(hour) + TimeSpan.minutes(minute) + TimeSpan.seconds(second)).ticks;
        }
}
