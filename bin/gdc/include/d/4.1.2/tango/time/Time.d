/******************************************************************************

        copyright:      Copyright (c) 2007 Tango. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        mid 2005: Initial release
                        Apr 2007: heavily reshaped
                        Dec 2007: moved to tango.time

        author:         John Chapman, Kris, scheivguy

******************************************************************************/

module tango.time.Time;

/******************************************************************************

    This struct represents a length of time.  The underlying representation is
    in units of 100ns.  This allows the length of time to span to roughly
    +/- 10000 years.
    
    Notably missing from this is a representation of weeks, months and years.
    This is because weeks, months, and years vary according to local calendars.
    Use tango.time.chrono.* to deal with these concepts.

    Note: nobody should change this struct without really good reason as it is
    required to be a part of some interfaces.  It should be treated as a builtin 
    type. Also note that there is deliberately no opCall constructor here, since 
    it tends to produce too much overhead. 

    Example:
    -------------------
    Time start = Clock.now;
    Thread.sleep(0.150);
    Stdout.formatln("slept for {} ms", (Clock.now-start).millis);
    -------------------

    See_Also: tango.core.Thread, tango.time.Clock

******************************************************************************/

struct TimeSpan
{
        // this is the only member of the struct.
        package long ticks_;

        // useful constants.  Shouldn't be used in normal code, use the
        // static TimeSpan members below instead.  i.e. instead of
        // TimeSpan.TicksPerSecond, use TimeSpan.second.ticks
        //
        enum : long 
        {
                /// basic tick values
                NanosecondsPerTick  = 100,
                TicksPerMicrosecond = 1000 / NanosecondsPerTick,
                TicksPerMillisecond = 1000 * TicksPerMicrosecond,
                TicksPerSecond      = 1000 * TicksPerMillisecond,
                TicksPerMinute      = 60 * TicksPerSecond,
                TicksPerHour        = 60 * TicksPerMinute,
                TicksPerDay         = 24 * TicksPerHour,

                // millisecond counts
                MillisPerSecond     = 1000,
                MillisPerMinute     = MillisPerSecond * 60,
                MillisPerHour       = MillisPerMinute * 60,
                MillisPerDay        = MillisPerHour * 24,

                /// day counts
                DaysPerYear         = 365,
                DaysPer4Years       = DaysPerYear * 4 + 1,
                DaysPer100Years     = DaysPer4Years * 25 - 1,
                DaysPer400Years     = DaysPer100Years * 4 + 1,

                // epoch counts
                Epoch1601           = DaysPer400Years * 4 * TicksPerDay,
                Epoch1970           = Epoch1601 + TicksPerSecond * 11644473600L,
        }

        /**
         * Minimum TimeSpan
         */
        static const TimeSpan min = {long.min};

        /**
         * Maximum TimeSpan
         */
        static const TimeSpan max = {long.max};

        /**
         * Zero TimeSpan.  Useful for comparisons.
         */
        static const TimeSpan zero = {0};

        /**
         * Get the number of ticks that this timespan represents.
         */
        long ticks()
        {
                return ticks_;
        }

        /**
         * Determines whether two TimeSpan values are equal
         */
        bool opEquals(TimeSpan t)
        {
                return ticks_ is t.ticks_;
        }

        /**
         * Compares this object against another TimeSpan value.
         */
        int opCmp(TimeSpan t)
        {
                if (ticks_ < t.ticks_)
                    return -1;

                if (ticks_ > t.ticks_)
                    return 1;

                return 0;
        }

        /**
         * Add the TimeSpan given to this TimeSpan returning a new TimeSpan.
         *
         * Params: t = A TimeSpan value to add
         * Returns: A TimeSpan value that is the sum of this instance and t.
         */
        TimeSpan opAdd(TimeSpan t)
        {
                return TimeSpan(ticks_ + t.ticks_);
        }

        /**
         * Add the specified TimeSpan to this TimeSpan, assigning the result
         * to this instance.
         *
         * Params: t = A TimeSpan value to add
         * Returns: a copy of this instance after adding t.
         */
        TimeSpan opAddAssign(TimeSpan t)
        {
                ticks_ += t.ticks_;
                return *this;
        }

        /**
         * Subtract the specified TimeSpan from this TimeSpan.
         *
         * Params: t = A TimeSpan to subtract
         * Returns: A new timespan which is the difference between this
         * instance and t
         */
        TimeSpan opSub(TimeSpan t)
        {
                return TimeSpan(ticks_ - t.ticks_);
        }

        /**
         *
         * Subtract the specified TimeSpan from this TimeSpan and assign the
         * value to this TimeSpan.
         *
         * Params: t = A TimeSpan to subtract
         * Returns: A copy of this instance after subtracting t.
         */
        TimeSpan opSubAssign(TimeSpan t)
        {
                ticks_ -= t.ticks_;
                return *this;
        }

        /**
         * Scale the TimeSpan by the specified amount.  This should not be
         * used to convert to a different unit.  Use the unit accessors
         * instead.  This should only be used as a scaling mechanism.  For
         * example, if you have a timeout and you want to sleep for twice the
         * timeout, you would use timeout * 2.
         *
         * Params: v = A multiplier to use for scaling this time span.
         * Returns: A new TimeSpan that is scaled by v
         */
        TimeSpan opMul(long v)
        {
                return TimeSpan(ticks_ * v);
        }

        /**
         * Scales this TimeSpan and assigns the result to this instance.
         *
         * Params: v = A multipler to use for scaling
         * Returns: A copy of this instance after scaling
         */
        TimeSpan opMulAssign(long v)
        {
                ticks_ *= v;
                return *this;
        }

        /**
         * Divide the TimeSpan by the specified amount.  This should not be
         * used to convert to a different unit.  Use the unit accessors
         * instead.  This should only be used as a scaling mechanism.  For
         * example, if you have a timeout and you want to sleep for half the
         * timeout, you would use timeout / 2.
         *
         *
         * Params: v = A divisor to use for scaling this time span.
         * Returns: A new TimeSpan that is divided by v
         */
        TimeSpan opDiv(long v)
        {
                return TimeSpan(ticks_ / v);
        }

        /**
         * Divides this TimeSpan and assigns the result to this instance.
         *
         * Params: v = A multipler to use for dividing
         * Returns: A copy of this instance after dividing
         */
        TimeSpan opDivAssign(long v)
        {
                ticks_ /= v;
                return *this;
        }

        /**
         * Perform integer division with the given time span.
         *
         * Params: t = A divisor used for dividing
         * Returns: The result of integer division between this instance and
         * t.
         */
        long opDiv(TimeSpan t)
        {
                return ticks_ / t.ticks;
        }

        /**
         * Negate a time span
         *
         * Returns: The negative equivalent to this time span
         */
        TimeSpan opNeg()
        {
                return TimeSpan(-ticks_);
        }

        /**
         * Convert to nanoseconds
         *
         * Note: this may incur loss of data because nanoseconds cannot
         * represent the range of data a TimeSpan can represent.
         *
         * Returns: The number of nanoseconds that this TimeSpan represents.
         */
        long nanos()
        {
                return ticks_ * NanosecondsPerTick;
        }

        /**
         * Convert to microseconds
         *
         * Returns: The number of microseconds that this TimeSpan represents.
         */
        long micros()
        {
                return ticks_ / TicksPerMicrosecond;
        }

        /**
         * Convert to milliseconds
         *
         * Returns: The number of milliseconds that this TimeSpan represents.
         */
        long millis()
        {
                return ticks_ / TicksPerMillisecond;
        }

        /**
         * Convert to seconds
         *
         * Returns: The number of seconds that this TimeSpan represents.
         */
        long seconds()
        {
                return ticks_ / TicksPerSecond;
        }

        /**
         * Convert to minutes
         *
         * Returns: The number of minutes that this TimeSpan represents.
         */
        long minutes()
        {
                return ticks_ / TicksPerMinute;
        }

        /**
         * Convert to hours
         *
         * Returns: The number of hours that this TimeSpan represents.
         */
        long hours()
        {
                return ticks_ / TicksPerHour;
        }

        /**
         * Convert to days
         *
         * Returns: The number of days that this TimeSpan represents.
         */
        long days()
        {
                return ticks_ / TicksPerDay;
        }

        /**
         * Convert to a floating point interval representing seconds.
         *
         * Note: This may cause a loss of precision as a double cannot exactly
         * represent some fractional values.
         *
         * Returns: An interval representing the seconds and fractional
         * seconds that this TimeSpan represents.
         */
        double interval()
        {
                return (cast(double) ticks_) / TicksPerSecond;
        }

        /**
         * Convert to TimeOfDay
         *
         * Returns: the TimeOfDay this TimeSpan represents.
         */
        TimeOfDay time()
        {
                return TimeOfDay(ticks_);
        }

        /**
         * Construct a TimeSpan from the given number of nanoseconds
         *
         * Note: This may cause a loss of data since a TimeSpan's resolution
         * is in 100ns increments.
         *
         * Params: value = The number of nanoseconds.
         * Returns: A TimeSpan representing the given number of nanoseconds.
         */
        static TimeSpan nanos(long value)
        {
                return TimeSpan(value / NanosecondsPerTick);
        }

        /**
         * Construct a TimeSpan from the given number of microseconds
         *
         * Params: value = The number of microseconds.
         * Returns: A TimeSpan representing the given number of microseconds.
         */
        static TimeSpan micros(long value)
        {
                return TimeSpan(TicksPerMicrosecond * value);
        }

        /**
         * Construct a TimeSpan from the given number of milliseconds
         *
         * Params: value = The number of milliseconds.
         * Returns: A TimeSpan representing the given number of milliseconds.
         */
        static TimeSpan millis(long value)
        {
                return TimeSpan(TicksPerMillisecond * value);
        }

        /**
         * Construct a TimeSpan from the given number of seconds
         *
         * Params: value = The number of seconds.
         * Returns: A TimeSpan representing the given number of seconds.
         */
        static TimeSpan seconds(long value)
        {
                return TimeSpan(TicksPerSecond * value);
        }

        /**
         * Construct a TimeSpan from the given number of minutes
         *
         * Params: value = The number of minutes.
         * Returns: A TimeSpan representing the given number of minutes.
         */
        static TimeSpan minutes(long value)
        {
                return TimeSpan(TicksPerMinute * value);
        }

        /**
         * Construct a TimeSpan from the given number of hours
         *
         * Params: value = The number of hours.
         * Returns: A TimeSpan representing the given number of hours.
         */
        static TimeSpan hours(long value)
        {
                return TimeSpan(TicksPerHour * value);
        }

        /**
         * Construct a TimeSpan from the given number of days
         *
         * Params: value = The number of days.
         * Returns: A TimeSpan representing the given number of days.
         */
        static TimeSpan days(long value)
        {
                return TimeSpan(TicksPerDay * value);
        }

        /**
         * Construct a TimeSpan from the given interval.  The interval
         * represents seconds as a double.  This allows both whole and
         * fractional seconds to be passed in.
         *
         * Params: value = The interval to convert in seconds.
         * Returns: A TimeSpan representing the given interval.
         */
        static TimeSpan interval(double sec)
        {
                return TimeSpan(cast(long)(sec * TicksPerSecond + .1));
        }
}


/******************************************************************************

        Represents a point in time.

        Remarks: Time represents dates and times between 12:00:00 
        midnight on January 1, 10000 BC and 11:59:59 PM on December 31, 
        9999 AD.

        Time values are measured in 100-nanosecond intervals, or ticks. 
        A date value is the number of ticks that have elapsed since 
        12:00:00 midnight on January 1, 0001 AD in the Gregorian 
        calendar.
        
        Negative Time values are offsets from that same reference point, 
        but backwards in history.  Time values are not specific to any 
        calendar, but for an example, the beginning of December 31, 1 BC 
        in the Gregorian calendar is Time.epoch - TimeSpan.days(1).

******************************************************************************/

struct Time 
{
        private long ticks_;

        private enum : long
        {
                maximum = (TimeSpan.DaysPer400Years * 25 - 366) * TimeSpan.TicksPerDay - 1,
                minimum = -((TimeSpan.DaysPer400Years * 25 - 366) * TimeSpan.TicksPerDay - 1),
        }

        /// Represents the smallest and largest Time value.
        static const Time min       = {minimum},
                          max       = {maximum},
                          epoch     = {0},
                          epoch1601 = {TimeSpan.Epoch1601},
                          epoch1970 = {TimeSpan.Epoch1970};

        /**********************************************************************

                $(I Property.) Retrieves the number of ticks for this Time

                Returns: A long represented by the time of this 
                         instance.

        **********************************************************************/

        long ticks ()
        {
                return ticks_;
        }

        /**********************************************************************

                Determines whether two Time values are equal.

                Params:  value = A Time _value.
                Returns: true if both instances are equal; otherwise, false

        **********************************************************************/

        int opEquals (Time t) 
        {
                return ticks_ is t.ticks_;
        }

        /**********************************************************************

                Compares two Time values.

        **********************************************************************/

        int opCmp (Time t) 
        {
                if (ticks_ < t.ticks_)
                    return -1;

                if (ticks_ > t.ticks_)
                    return 1;

                return 0;
        }

        /**********************************************************************

                Adds the specified time span to the time, returning a new
                time.
                
                Params:  t = A TimeSpan value.
                Returns: A Time that is the sum of this instance and t.

        **********************************************************************/

        Time opAdd (TimeSpan t) 
        {
                return Time (ticks_ + t.ticks_);
        }

        /**********************************************************************

                Adds the specified time span to the time, assigning 
                the result to this instance.

                Params:  t = A TimeSpan value.
                Returns: The current Time instance, with t added to the 
                         time.

        **********************************************************************/

        Time opAddAssign (TimeSpan t) 
        {
                ticks_ += t.ticks_;
                return *this;
        }

        /**********************************************************************

                Subtracts the specified time span from the time, 
                returning a new time.

                Params:  t = A TimeSpan value.
                Returns: A Time whose value is the value of this instance 
                         minus the value of t.

        **********************************************************************/

        Time opSub (TimeSpan t) 
        {
                return Time (ticks_ - t.ticks_);
        }

        /**********************************************************************

                Returns a time span which represents the difference in time
                between this and the given Time.

                Params:  t = A Time value.
                Returns: A TimeSpan which represents the difference between
                         this and t.

        **********************************************************************/

        TimeSpan opSub (Time t)
        {
                return TimeSpan(ticks_ - t.ticks_);
        }

        /**********************************************************************

                Subtracts the specified time span from the time, 
                assigning the result to this instance.

                Params:  t = A TimeSpan value.
                Returns: The current Time instance, with t subtracted 
                         from the time.

        **********************************************************************/

        Time opSubAssign (TimeSpan t) 
        {
                ticks_ -= t.ticks_;
                return *this;
        }

        /**********************************************************************

                $(I Property.) Retrieves the date component.

                Returns: A new Time instance with the same date as 
                         this instance, but with the time trucated.

        **********************************************************************/

        Time date () 
        {
                return *this - TimeOfDay.modulo24(ticks_);
        }

        /**********************************************************************

                $(I Property.) Retrieves the time of day.

                Returns: A TimeOfDay representing the fraction of the day 
                         elapsed since midnight.

        **********************************************************************/

        TimeOfDay time () 
        {
                return TimeOfDay (ticks_);
        }

        /**********************************************************************

                $(I Property.) Retrieves the equivalent TimeSpan.

                Returns: A TimeSpan representing this Time.

        **********************************************************************/

        TimeSpan span () 
        {
                return TimeSpan (ticks_);
        }
}


/******************************************************************************

        Represents a time of day. This is different from TimeSpan in that 
        each component is represented within the limits of everyday time, 
        rather than from the start of the Epoch. Effectively, the TimeOfDay
        epoch is the first second of each day.

        This is handy for dealing strictly with a 24-hour clock instead of
        potentially thousands of years. For example:
        ---
        auto time = Clock.now.time;
        assert (time.millis < 1000);
        assert (time.seconds < 60);
        assert (time.minutes < 60);
        assert (time.hours < 24);
        ---

        You can create a TimeOfDay from an existing Time or TimeSpan instance
        via the respective time() method. To convert back to a TimeSpan, use
        the span() method

******************************************************************************/

struct TimeOfDay 
{
        public uint     hours,
                        minutes,
                        seconds,
                        millis;

        /**
         * constructor.
         * Params: hours = number of hours since midnight
         *         minutes = number of minutes into the hour
         *         seconds = number of seconds into the minute
         *         millis = number of milliseconds into the second
         *
         * Returns: a TimeOfDay representing the given time fields.
         */
        static TimeOfDay opCall (uint hours, uint minutes, uint seconds, uint millis=0)
        {
                TimeOfDay t = void;
                t.hours   = hours;
                t.minutes = minutes;
                t.seconds = seconds;
                t.millis  = millis;
                return t;
        }

        /**
         * constructor.
         * Params: ticks = ticks representing a Time value.  This is normalized 
         * so that it represent a time of day (modulo-24 etc)
         *
         * Returns: a TimeOfDay value that corresponds to the time of day of
         * the given number of ticks.
         */
        static TimeOfDay opCall (long ticks)
        {       
                TimeOfDay t = void;
                ticks = modulo24(ticks).ticks_;
                t.millis  = cast(uint) (ticks / TimeSpan.TicksPerMillisecond); 
                t.seconds = (t.millis / 1_000) % 60;
                t.minutes = (t.millis / 60_000) % 60;
                t.hours   = (t.millis / 3_600_000) % 24;
                t.millis %= 1000;
                return t;
        }

        /**
         * construct a TimeSpan from the current fields
         *
         * Returns: a TimeOfDay representing the field values.
         *
         * Note: that fields are not checked against a valid range, so
         * setting 60 for minutes is allowed, and will just add 1 to the hour
         * component, and set the minute component to 0.  The result is
         * normalized, so the hours wrap.  If you pass in 25 hours, the
         * resulting TimeOfDay will have a hour component of 1.
         */
        TimeSpan span ()
        {
                return TimeSpan.hours(hours) +
                       TimeSpan.minutes(minutes) + 
                       TimeSpan.seconds(seconds) + 
                       TimeSpan.millis(millis);
        }

        /**
         * internal routine to adjust ticks by one day. Also adjusts for
         * offsets in the BC era
         */
        package static TimeSpan modulo24 (long ticks)
        {
                ticks %= TimeSpan.TicksPerDay;
                if (ticks < 0)
                    ticks += TimeSpan.TicksPerDay;
                return TimeSpan (ticks);
        }
}

/******************************************************************************

    Generic Date representation

******************************************************************************/

struct Date
{
        public uint         era,            /// AD, BC
                            day,            /// 1 .. 31
                            year,           /// 0 to 9999
                            month,          /// 1 .. 12
                            dow,            /// 0 .. 6
                            doy;            /// 1 .. 366
}


/******************************************************************************

    Combination of a Date and a TimeOfDay

******************************************************************************/

struct DateTime
{
        public Date         date;       /// date representation
        public TimeOfDay    time;       /// time representation
}




/******************************************************************************

******************************************************************************/

debug (UnitTest)
{
        unittest
        {
                assert(TimeSpan.zero > TimeSpan.min);
                assert(TimeSpan.max  > TimeSpan.zero);
                assert(TimeSpan.max  > TimeSpan.min);
                assert(TimeSpan.zero >= TimeSpan.zero);
                assert(TimeSpan.zero <= TimeSpan.zero);
                assert(TimeSpan.max >= TimeSpan.max);
                assert(TimeSpan.max <= TimeSpan.max);
                assert(TimeSpan.min >= TimeSpan.min);
                assert(TimeSpan.min <= TimeSpan.min);

                assert (TimeSpan.seconds(50).seconds is 50);
                assert (TimeSpan.seconds(5000).seconds is 5000);
                assert (TimeSpan.minutes(50).minutes is 50);
                assert (TimeSpan.minutes(5000).minutes is 5000);
                assert (TimeSpan.hours(23).hours is 23);
                assert (TimeSpan.hours(5000).hours is 5000);
                assert (TimeSpan.days(6).days is 6);
                assert (TimeSpan.days(5000).days is 5000);

                assert (TimeSpan.seconds(50).time.seconds is 50);
                assert (TimeSpan.seconds(5000).time.seconds is 5000 % 60);
                assert (TimeSpan.minutes(50).time.minutes is 50);
                assert (TimeSpan.minutes(5000).time.minutes is 5000 % 60);
                assert (TimeSpan.hours(23).time.hours is 23);
                assert (TimeSpan.hours(5000).time.hours is 5000 % 24);

                auto tod = TimeOfDay (25, 2, 3, 4);
                tod = tod.span.time;
                assert (tod.hours is 1);
                assert (tod.minutes is 2);
                assert (tod.seconds is 3);
                assert (tod.millis is 4);
        }
}


/*******************************************************************************

*******************************************************************************/

debug (Time)
{
        import tango.io.Stdout;
        import tango.time.Clock;
        import tango.time.chrono.Gregorian;

        Time foo() 
        {
                auto d = Time(10);
                auto e = TimeSpan(20);

                return d + e;
        }

        void main()
        {
                auto c = foo();
                Stdout (c.ticks).newline;


                auto t = TimeSpan(1);
                auto h = t.hours;
                auto m = t.time.minutes;

                auto now = Clock.now;
                auto time = now.time;
                auto date = Gregorian.generic.toDate (now);
                now = Gregorian.generic.toTime (date, time);
        }
}

