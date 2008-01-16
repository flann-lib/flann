/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris, schveiguy

******************************************************************************/

module tango.time.chrono.Gregorian;

private import tango.time.chrono.Calendar;

/**
 * $(ANCHOR _Gregorian)
 * Represents the Gregorian calendar.
 *
 * Note that this is the Proleptic Gregorian calendar.  Most calendars assume
 * that dates before 9/14/1752 were Julian Dates.  Julian differs from
 * Gregorian in that leap years occur every 4 years, even on 100 year
 * increments.  The Proleptic Gregorian calendar applies the Gregorian leap
 * year rules to dates before 9/14/1752, making the calculation of dates much
 * easier.
 */
class Gregorian : Calendar 
{
        // import baseclass toTime()
        alias Calendar.toTime toTime;

        /// static shared instance
        public static Gregorian generic;

        enum Type 
        {
                Localized = 1,               /// Refers to the localized version of the Gregorian calendar.
                USEnglish = 2,               /// Refers to the US English version of the Gregorian calendar.
                MiddleEastFrench = 9,        /// Refers to the Middle East French version of the Gregorian calendar.
                Arabic = 10,                 /// Refers to the _Arabic version of the Gregorian calendar.
                TransliteratedEnglish = 11,  /// Refers to the transliterated English version of the Gregorian calendar.
                TransliteratedFrench = 12    /// Refers to the transliterated French version of the Gregorian calendar.
        }

        private Type type_;                 

        /**
        * Represents the current era.
        */
        enum {AD_ERA = 1, BC_ERA = 2, MAX_YEAR = 9999};

        private static final uint[] DaysToMonthCommon = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];

        private static final uint[] DaysToMonthLeap   = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366];

        /**
        * create a generic instance of this calendar
        */
        static this()
        {       
                generic = new Gregorian;
        }

        /**
        * Initializes an instance of the Gregorian class using the specified GregorianTypes value. If no value is 
        * specified, the default is Gregorian.Types.Localized.
        */
        this (Type type = Type.Localized) 
        {
                type_ = type;
        }

        /**
        * Overridden. Returns a Time value set to the specified date and time in the specified _era.
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
        override Time toTime (uint year, uint month, uint day, uint hour, uint minute, uint second, uint millisecond, uint era)
        {
                return Time (getDateTicks(year, month, day, era) + getTimeTicks(hour, minute, second)) + TimeSpan.millis(millisecond);
        }

        /**
        * Overridden. Returns the day of the week in the specified Time.
        * Params: time = A Time value.
        * Returns: A DayOfWeek value representing the day of the week of time.
        */
        override DayOfWeek getDayOfWeek(Time time) 
        {
                int dow;
                if(time.ticks < 0)
                {
                        dow = ((time.ticks + 1) / TimeSpan.TicksPerDay) % 7;
                        if(dow < 0)
                                dow += 7;
                }
                else
                        dow = (time.ticks / TimeSpan.TicksPerDay + 1) % 7;
                return cast(DayOfWeek)dow;
        }

        /**
        * Overridden. Returns the day of the month in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the day of the month of time.
        */
        override uint getDayOfMonth(Time time) 
        {
                return extractPart(time.ticks, DatePart.Day);
        }

        /**
        * Overridden. Returns the day of the year in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the day of the year of time.
        */
        override uint getDayOfYear(Time time) 
        {
                return extractPart(time.ticks, DatePart.DayOfYear);
        }

        /**
        * Overridden. Returns the month in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the month in time.
        */
        override uint getMonth(Time time) 
        {
                return extractPart(time.ticks, DatePart.Month);
        }

        /**
        * Overridden. Returns the year in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the year in time.
        */
        override uint getYear(Time time) 
        {
                return extractPart(time.ticks, DatePart.Year);
        }

        /**
        * Overridden. Returns the era in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the era in time.
        */
        override uint getEra(Time time) 
        {
                if(time < time.epoch)
                        return BC_ERA;
                else
                        return AD_ERA;
        }

        /**
        * Overridden. Returns the number of days in the specified _year and _month of the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        *   era = An integer representing the _era.
        * Returns: The number of days in the specified _year and _month of the specified _era.
        */
        override uint getDaysInMonth(uint year, uint month, uint era) 
        {
                auto monthDays = isLeapYear(year, era) ? DaysToMonthLeap : DaysToMonthCommon;
                return monthDays[month] - monthDays[month - 1];
        }

        /**
        * Overridden. Returns the number of days in the specified _year of the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   era = An integer representing the _era.
        * Returns: The number of days in the specified _year in the specified _era.
        */
        override uint getDaysInYear(uint year, uint era) 
        {
                return isLeapYear(year, era) ? 366 : 365;
        }

        /**
        * Overridden. Returns the number of months in the specified _year of the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   era = An integer representing the _era.
        * Returns: The number of months in the specified _year in the specified _era.
        */
        override uint getMonthsInYear(uint year, uint era) 
        {
                return 12;
        }

        /**
        * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
        * Params: year = An integer representing the _year.
        * Params: era = An integer representing the _era.
        * Returns: true is the specified _year is a leap _year; otherwise, false.
        */
        override bool isLeapYear(uint year, uint era) 
        {
                return staticIsLeapYear(year, era);
        }

        /**
        * $(I Property.) Retrieves the GregorianTypes value indicating the language version of the Gregorian.
        * Returns: The Gregorian.Type value indicating the language version of the Gregorian.
        */
        Type calendarType() 
        {
                return type_;
        }

        /**
        * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
        * Returns: An integer array representing the eras in the current calendar.
        */
        override uint[] eras() 
        {       
                uint[] tmp = [AD_ERA, BC_ERA];
                return tmp.dup;
        }

        /**
        * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
        * Returns: An integer representing the identifier of the current calendar.
        */
        override uint id() 
        {
                return cast(int) type_;
        }

        override void split(Time time, ref uint year, ref uint month, ref uint day, ref uint doy, ref uint dow, ref uint era)
        {
            splitDate(time.ticks, year, month, day, doy, era);
            dow = getDayOfWeek(time);
        }

        package static void splitDate (long ticks, ref uint year, ref uint month, ref uint day, ref uint dayOfYear, ref uint era) 
        {
                int numDays;

                void calculateYear()
                {
                        auto whole400Years = numDays / cast(int) TimeSpan.DaysPer400Years;
                        numDays -= whole400Years * cast(int) TimeSpan.DaysPer400Years;
                        auto whole100Years = numDays / cast(int) TimeSpan.DaysPer100Years;
                        if (whole100Years == 4)
                                whole100Years = 3;

                        numDays -= whole100Years * cast(int) TimeSpan.DaysPer100Years;
                        auto whole4Years = numDays / cast(int) TimeSpan.DaysPer4Years;
                        numDays -= whole4Years * cast(int) TimeSpan.DaysPer4Years;
                        auto wholeYears = numDays / cast(int) TimeSpan.DaysPerYear;
                        if (wholeYears == 4)
                                wholeYears = 3;

                        year = whole400Years * 400 + whole100Years * 100 + whole4Years * 4 + wholeYears + era;
                        numDays -= wholeYears * TimeSpan.DaysPerYear;
                }

                if(ticks < 0)
                {
                        // in the BC era
                        era = BC_ERA;
                        //
                        // set up numDays to be like AD.  AD days start at
                        // year 1.  However, in BC, year 1 is like AD year 0,
                        // so we must subtract one year.
                        //
                        numDays = cast(int)((-ticks - 1) / TimeSpan.TicksPerDay);
                        if(numDays < 366)
                        {
                                // in the year 1 B.C.  This is a special case
                                // leap year
                                year = 1;
                        }
                        else
                        {
                                numDays -= 366;
                                calculateYear;
                        }
                        //
                        // numDays is the number of days back from the end of
                        // the year, because the original ticks were negative
                        //
                        numDays = (staticIsLeapYear(year, era) ? 366 : 365) - numDays - 1;
                }
                else
                {
                        era = AD_ERA;
                        numDays = cast(int)(ticks / TimeSpan.TicksPerDay);
                        calculateYear;
                }
                dayOfYear = numDays + 1;

                auto monthDays = staticIsLeapYear(year, era) ? DaysToMonthLeap : DaysToMonthCommon;
                month = numDays >> 5 + 1;
                while (numDays >= monthDays[month])
                       month++;

                day = numDays - monthDays[month - 1] + 1;
        }

        package static uint extractPart (long ticks, DatePart part) 
        {
                uint year, month, day, dayOfYear, era;

                splitDate(ticks, year, month, day, dayOfYear, era);

                if (part is DatePart.Year)
                    return year;

                if (part is DatePart.Month)
                    return month;

                if (part is DatePart.DayOfYear)
                    return dayOfYear;

                return day;
        }

        package static long getDateTicks (uint year, uint month, uint day, uint era) 
        {
                auto monthDays = staticIsLeapYear(year, era) ? DaysToMonthLeap : DaysToMonthCommon;
                if(era == BC_ERA)
                {
                        year += 2;
                        return -cast(long)( (year - 3) * 365 + year / 4 - year / 100 + year / 400 + monthDays[12] - (monthDays[month - 1] + day - 1)) * TimeSpan.TicksPerDay;
                }
                else
                {
                        year--;
                        return (year * 365 + year / 4 - year / 100 + year / 400 + monthDays[month - 1] + day - 1) * TimeSpan.TicksPerDay;
                }
        }

        package static bool staticIsLeapYear(uint year, uint era)
        {
                if(era == BC_ERA)
                        return staticIsLeapYear(year - 1, AD_ERA);
                if(era == AD_ERA)
                        return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
                return false;
        }
}

debug(Gregorian)
{
        import tango.io.Stdout;

        void output(Time t)
        {
                Date d = Gregorian.generic.toDate(t);
                TimeOfDay tod = t.time;
                Stdout.format("{}/{}/{:d4} {} {}:{:d2}:{:d2}.{:d3} dow:{}",
                                d.month, d.day, d.year, d.era == Gregorian.AD_ERA ? "AD" : "BC",
                                tod.hours, tod.minutes, tod.seconds, tod.millis, d.dow).newline;
        }

        void main()
        {
                Time t = Time(365 * TimeSpan.TicksPerDay);
                output(t);
                for(int i = 0; i < 366 + 365; i++)
                {
                        t -= TimeSpan.days(1);
                        output(t);
                }
        }
}

debug(UnitTest)
{
        debug(Gregorian)
        {
        }
        else
        {
                void main() {}
        }

        unittest
        {
                //
                // check Gregorian date handles positive time.
                //
                Time t = Time.epoch + TimeSpan.days(365);
                Date d = Gregorian.generic.toDate(t);
                assert(d.year == 2);
                assert(d.month == 1);
                assert(d.day == 1);
                assert(d.era == Gregorian.AD_ERA);
                assert(d.doy == 1);
                //
                // note that this is in disagreement with the Julian Calendar
                //
                assert(d.dow == Gregorian.DayOfWeek.Tuesday);

                //
                // check that it handles negative time
                //
                t = Time.epoch - TimeSpan.days(366);
                d = Gregorian.generic.toDate(t);
                assert(d.year == 1);
                assert(d.month == 1);
                assert(d.day == 1);
                assert(d.era == Gregorian.BC_ERA);
                assert(d.doy == 1);
                assert(d.dow == Gregorian.DayOfWeek.Saturday);

        }
}
