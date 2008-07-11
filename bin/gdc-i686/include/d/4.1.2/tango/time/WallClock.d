/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Apr 2007: split away from utc

        author:         Kris

*******************************************************************************/

module tango.time.WallClock;

public  import  tango.time.Time;

private import  tango.time.Clock;

private import  tango.sys.Common;

/******************************************************************************

        Exposes wall-time relative to Jan 1st, 1 AD. These values are
        based upon a clock-tick of 100ns, giving them a span of greater
        than 10,000 years. These Units of time are the foundation of most
        time and date functionality in Tango.

        Please note that conversion between UTC and Wall time is performed
        in accordance with the OS facilities. In particular, Win32 systems
        behave differently to Posix when calculating daylight-savings time
        (Win32 calculates with respect to the time of the call, whereas a
        Posix system calculates based on a provided point in time). Posix
        systems should typically have the TZ environment variable set to 
        a valid descriptor.

*******************************************************************************/

struct WallClock
{
        version (Win32)
        {
                /***************************************************************

                        Return the current local time

                ***************************************************************/

                static Time now ()
                {
                        return Clock.now - localBias;
                }

                /***************************************************************

                        Return the timezone relative to GMT. The value is 
                        negative when west of GMT

                ***************************************************************/

                static TimeSpan zone ()
                {
                        TIME_ZONE_INFORMATION tz = void;

                        auto tmp = GetTimeZoneInformation (&tz);
                        return TimeSpan.minutes(-tz.Bias);
                }

                /***************************************************************

                        Set fields to represent a local version of the 
                        current UTC time. All values must fall within 
                        the domain supported by the OS

                ***************************************************************/

                static DateTime toDate ()
                {
                        return toDate (Clock.now);
                }

                /***************************************************************

                        Set fields to represent a local version of the 
                        provided UTC time. All values must fall within 
                        the domain supported by the OS

                ***************************************************************/

                static DateTime toDate (Time utc)
                {
                        return Clock.toDate (utc - localBias);
                }

                /***************************************************************

                        Convert Date fields to local time

                ***************************************************************/

                static Time fromDate (inout DateTime date)
                {
                        return (Clock.fromDate(date) + localBias);
                }

                /***************************************************************

                        Retrieve the local bias, including DST adjustment.
                        Note that Win32 calculates DST at the time of call
                        rather than based upon a point in time represented
                        by an argument.
                         
                ***************************************************************/

                private static TimeSpan localBias () 
                { 
                       int bias; 
                       TIME_ZONE_INFORMATION tz = void; 

                       switch (GetTimeZoneInformation (&tz)) 
                              { 
                              default: 
                                   bias = tz.Bias; 
                                   break; 
                              case 1: 
                                   bias = tz.Bias + tz.StandardBias; 
                                   break; 
                              case 2: 
                                   bias = tz.Bias + tz.DaylightBias; 
                                   break; 
                              } 

                       return TimeSpan.minutes(bias); 
               }
        }

        version (Posix)
        {
                /***************************************************************

                        Return the current local time

                ***************************************************************/

                static Time now ()
                {
                        tm t = void;
                        timeval tv = void;
                        gettimeofday (&tv, null);
                        localtime_r (&tv.tv_sec, &t);
                        tv.tv_sec = timegm (&t);
                        return Clock.convert (tv);
                }

                /***************************************************************

                        Return the timezone relative to GMT. The value is 
                        negative when west of GMT

                ***************************************************************/

                static TimeSpan zone ()
                {
                        version (darwin)
                                {
                                timezone_t tz = void;
                                gettimeofday (null, &tz);
                                return TimeSpan.minutes(-tz.tz_minuteswest);
                                }
                             else
                                return TimeSpan.seconds(-timezone);
                }

                /***************************************************************

                        Set fields to represent a local version of the 
                        current UTC time. All values must fall within 
                        the domain supported by the OS

                ***************************************************************/

                static DateTime toDate ()
                {
                        return toDate (Clock.now);
                }

                /***************************************************************

                        Set fields to represent a local version of the 
                        provided UTC time. All values must fall within 
                        the domain supported by the OS

                ***************************************************************/

                static DateTime toDate (Time utc)
                {
                        DateTime dt = void;
                        auto timeval = Clock.convert (utc);
                        dt.time.millis = timeval.tv_usec / 1000;

                        tm t = void;
                        localtime_r (&timeval.tv_sec, &t);
        
                        dt.date.year    = t.tm_year + 1900;
                        dt.date.month   = t.tm_mon + 1;
                        dt.date.day     = t.tm_mday;
                        dt.date.dow     = t.tm_wday;
                        dt.date.doy     = 0;
                        dt.date.era     = 0;
                        dt.time.hours   = t.tm_hour;
                        dt.time.minutes = t.tm_min;
                        dt.time.seconds = t.tm_sec;
                        return dt;
                }

                /***************************************************************

                        Convert Date fields to local time

                ***************************************************************/

                static Time fromDate (inout DateTime dt)
                {
                        tm t = void;

                        t.tm_year = dt.date.year - 1900;
                        t.tm_mon  = dt.date.month - 1;
                        t.tm_mday = dt.date.day;
                        t.tm_hour = dt.time.hours;
                        t.tm_min  = dt.time.minutes;
                        t.tm_sec  = dt.time.seconds;

                        auto seconds = mktime (&t);
                        return Time.epoch1970 + TimeSpan.seconds(seconds) 
                                              + TimeSpan.millis(dt.time.millis);
                }
        }

        /***********************************************************************

        ***********************************************************************/
        
        static Time toLocal (Time utc)
        {
                auto mod = utc.ticks % TimeSpan.TicksPerMillisecond;
                return Clock.fromDate(toDate(utc)) + TimeSpan(mod);
        }

        /***********************************************************************

        ***********************************************************************/
        
        static Time toUtc (Time wall)
        {
                auto mod = wall.ticks % TimeSpan.TicksPerMillisecond;
                return fromDate(Clock.toDate(wall)) + TimeSpan(mod);
        }
}


version (Posix)
{
    version (darwin) {}
    else
    {
        static this()
        {
            tzset();
        }
    }
}
