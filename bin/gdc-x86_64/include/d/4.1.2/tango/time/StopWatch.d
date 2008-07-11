/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Feb 2007: Initial release
        
        author:         Kris

*******************************************************************************/

module tango.time.StopWatch;

private import tango.core.Exception;

/*******************************************************************************

*******************************************************************************/

version (Win32)
{
        private extern (Windows) 
        {
        int QueryPerformanceCounter   (ulong *count);
        int QueryPerformanceFrequency (ulong *frequency);
        }
}

version (Posix)
{
        private import tango.stdc.posix.sys.time;
}

/*******************************************************************************

        Timer for measuring small intervals, such as the duration of a 
        subroutine or other reasonably small period.
        ---
        StopWatch elapsed;

        elapsed.start;

        // do something
        // ...

        double i = elapsed.stop;
        ---

        The measured interval is in units of seconds, using floating-
        point to represent fractions. This approach is more flexible 
        than integer arithmetic since it migrates trivially to more
        capable timer hardware (there no implicit granularity to the
        measurable intervals, except the limits of fp representation)

        StopWatch is accurate to the extent of what the underlying OS
        supports. On linux systems, this accuracy is typically 1 us at 
        best. Win32 is generally more precise. 

        There is some minor overhead in using StopWatch, so take that into 
        account

*******************************************************************************/

public struct StopWatch
{
        private ulong  started;
        private static double multiplier = 1.0 / 1_000_000.0;

        version (Win32)
                 private static double microsecond;

        /***********************************************************************
                
                Start the timer

        ***********************************************************************/
        
        void start ()
        {
                started = timer;
        }

        /***********************************************************************
                
                Stop the timer and return elapsed duration since start()

        ***********************************************************************/
        
        double stop ()
        {
                return multiplier * (timer - started);
        }

        /***********************************************************************
                
                Return elapsed time since the last start() as microseconds

        ***********************************************************************/
        
        ulong microsec ()
        {
                version (Posix)
                         return (timer - started);

                version (Win32)
                         return cast(ulong) ((timer - started) * microsecond);
        }

        /***********************************************************************
                
                Setup timing information for later use

        ***********************************************************************/

        static this()
        {
                version (Win32)
                {
                        ulong freq;

                        QueryPerformanceFrequency (&freq);
                        microsecond = 1_000_000.0 / freq;       
                        multiplier = 1.0 / freq;       
                }
        }

        /***********************************************************************
                
                Return the current time as an Interval

        ***********************************************************************/

        private static ulong timer ()
        {
                version (Posix)       
                {
                        timeval tv;
                        if (gettimeofday (&tv, null))
                            throw new PlatformException ("Timer :: linux timer is not available");

                        return (cast(ulong) tv.tv_sec * 1_000_000) + tv.tv_usec;
                }

                version (Win32)
                {
                        ulong now;

                        if (! QueryPerformanceCounter (&now))
                              throw new PlatformException ("high-resolution timer is not available");

                        return now;
                }
        }
}


/*******************************************************************************

*******************************************************************************/

debug (StopWatch)
{
        import tango.io.Stdout;

        void main() 
        {
                StopWatch t;
                t.start;

                for (int i=0; i < 100_000_000; ++i)
                    {}
                Stdout.format ("{:f9}", t.stop).newline;
        }
}
