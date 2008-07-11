/* /////////////////////////////////////////////////////////////////////////////
 * File:        perf.d
 *
 * Purpose:     Performance measurement classes. These classes were ported
 *              over to D from the STLSoft (http://stlsoft.org/) C++ libraries,
 *              which were documented in the article "Win32 Performance
 *              Measurement Option", May 2003 issue of Windows Develper Network
 *              (http://www.windevnet.com/documents/win0305a/).
 *
 * Created      19th March 2004
 * Updated:     18th July 2004
 *
 * www:         http://www.digitalmars.com/
 *
 * Copyright (C) 2004 by Digital Mars
 * All Rights Reserved
 * Written by Matthew Wilson
 * www.digitalmars.com
 * License for redistribution is by either the Artistic License in artistic.txt,
 * or the LGPL
 *
 * ////////////////////////////////////////////////////////////////////////// */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2004
*/


/** \file std/perf.d This file contains platform-independent performance classes */

module std.perf;

/// \brief Performance counter scope class generating template
///
/// This template declares the class PerformanceCounterScope which manages a
/// performance counter instance, scoping its measurement interval by virtue of
/// its supporting the RAII mechanism.

auto class PerformanceCounterScope(T)
{
    /// \name Construction
    /// @{
    public:
	/// Constructs an instance of the PerformanceCounterScope using a reference 
	/// to the parameterising performance counter class, whose measurement is
	/// to be scoped. The measurement interval is commenced with a call to 
	/// <b>start()</b> on the managed counter instance.
	this(T counter)
	in
	{
	    assert(null !is counter);
	}
	body
	{
	    m_counter = counter;

	    m_counter.start();
	}
	/// The measurement interval is completed with a call to <b>stop()</b> on the 
	/// managed counter instance.
	~this()
	{
	    m_counter.stop();
	}

	/// Calls <b>stop()</b> on the managed counter instance, so that intermediate
	/// timings can be taken.
	void stop()
	{
	    m_counter.stop();
	}

	/// Returns a reference to the managed counter instance.
	T counter()
	{
	    return m_counter;
	}
    /// @}

    /// \name Members
    /// @{
    private:
	T   m_counter;
    /// @}

    // Not to be implemented
    private:
	this(PerformanceCounterScope rhs);
}

version(Unix)
{

    version (GNU) {
	private import std.c.unix.unix;
    }
    else version (linux) {
	extern (C)
	{
	    private struct timeval
	    {
		int tv_sec;    /*!< The number of seconds, since Jan. 1, 1970, in the time value. */
		int tv_usec;   /*!< The number of microseconds in the time value. */
	    };
	    private struct timezone
	    {
		int tz_minuteswest; /*!< minutes west of Greenwich. */
		int tz_dsttime;     /*!< type of dst corrections to apply. */
	    };
	    private void gettimeofday(timeval *tv, timezone *tz);
	}
    }

    /* ////////////////////////////////////////////////////////////////////////// */

    /// \brief A performance counter that uses the most accurate measurement APIs available on the host machine
    ///
    /// This class attempts to use the high performance hardware counter as its measurement resource, but failing 
    /// that it defaults to less accurate resources in order to guarantee that meaningful measurements are always
    /// available to application code
    ///
    /// \ingroup group_synsoft_linux_perf
    class PerformanceCounter
    {
    /// \name Types
    /// @{
    private:
	alias   timeval epoch_type;
    public:
	/// \brief The interval type
	///
	/// The type of the interval measurement, a 64-bit signed integer
	alias   long    interval_type;

	/// \brief The scope type
	///
	/// The type with which instances of the counter class can be subject to the RAII mechanism in order
	/// to scope particular measurement intervals
	alias PerformanceCounterScope!(PerformanceCounter)  scope_type;
    /// @}

    /// \name Operations
    /// @{
    public:
	/// \brief Starts measurement
	///
	/// Begins the measurement period
	void start()
	{
	    timezone tz;

	    gettimeofday(&m_start, &tz);
	}

	/// \brief Ends measurement
	///
	/// Ends the measurement period
	void stop()
	{
	    timezone tz;

	    gettimeofday(&m_end, &tz);
	}
    /// @}

    /// \name Attributes
    /// @{
    public:
	/// \brief The elapsed count in the measurement period
	///
	/// This represents the extent, in machine-specific increments, of the measurement period
	interval_type periodCount()
	{
	    return microseconds;
	}

	/// \brief The number of whole seconds in the measurement period
	///
	/// This represents the extent, in whole seconds, of the measurement period
	interval_type seconds()
	{
	    interval_type   start   =   cast(interval_type)m_start.tv_sec + cast(interval_type)m_start.tv_usec / (1000 * 1000);
	    interval_type   end     =   cast(interval_type)m_end.tv_sec   + cast(interval_type)m_end.tv_usec   / (1000 * 1000);

	    return end - start;
	}

	/// \brief The number of whole milliseconds in the measurement period
	///
	/// This represents the extent, in whole milliseconds, of the measurement period
	interval_type milliseconds()
	{
	    interval_type   start   =   cast(interval_type)m_start.tv_sec * 1000 + cast(interval_type)m_start.tv_usec / 1000;
	    interval_type   end     =   cast(interval_type)m_end.tv_sec   * 1000 + cast(interval_type)m_end.tv_usec   / 1000;

	    return end - start;
	}

	/// \brief The number of whole microseconds in the measurement period
	///
	/// This represents the extent, in whole microseconds, of the measurement period
	interval_type microseconds()
	{
	    interval_type   start   =   cast(interval_type)m_start.tv_sec * 1000 * 1000 + cast(interval_type)m_start.tv_usec;
	    interval_type   end     =   cast(interval_type)m_end.tv_sec   * 1000 * 1000 + cast(interval_type)m_end.tv_usec;

	    return end - start;
	}
    /// @}

    /// \name Members
    /// @{
    private:
	epoch_type  m_start;    // start of measurement period
	epoch_type  m_end;      // End of measurement period
    /// @}
    }

    unittest
    {
	alias PerformanceCounter    counter_type;

	counter_type    counter = new counter_type();

	counter.start();
	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us1 =   counter.microseconds();
	counter_type.interval_type  ms1 =   counter.milliseconds();
	counter_type.interval_type  s1  =   counter.seconds();

	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us2 =   counter.microseconds();
	counter_type.interval_type  ms2 =   counter.milliseconds();
	counter_type.interval_type  s2  =   counter.seconds();

	assert(us2 >= us1);
	assert(ms2 >= ms1);
	assert(s2 >= s1);
    }

    /* ////////////////////////////////////////////////////////////////////////// */
}
else version(Windows)
{

    private import std.c.windows.windows;

    /* ////////////////////////////////////////////////////////////////////////// */

    /// \defgroup group_synsoft_win32_perf synsoft.win32.perf
    /// \ingroup group_synsoft_win32
    /// \brief This library provides Win32 Performance facilities

    /* ////////////////////////////////////////////////////////////////////////// */

    /// \brief A performance counter that uses the high performance hardware counter on the host machine
    ///
    /// This class provides high-resolution performance monitoring using the host machine's high performance
    /// hardware counter. This class does not provide meaningful timing information on operating systems
    /// that do not provide a high performance hardware counter.
    ///
    /// \ingroup group_synsoft_win32_perf
    class HighPerformanceCounter
    {
    /// \name Types
    /// @{
    private:
	alias   long    epoch_type;
    public:
	/// \brief The interval type
	///
	/// The type of the interval measurement, a 64-bit signed integer
	alias   long    interval_type;

	/// \brief The scope type
	///
	/// The type with which instances of the counter class can be subject to the RAII mechanism in order
	/// to scope particular measurement intervals
	alias PerformanceCounterScope!(HighPerformanceCounter)  scope_type;
    /// @}

    /// \name Construction
    /// @{
    private:
	static this()
	{
	    if(!QueryPerformanceFrequency(&sm_freq))
	    {
		sm_freq = 0x7fffffffffffffffL;
	    }
	}
    /// @}

    /// \name Operations
    /// @{
    public:
	/// \brief Starts measurement
	///
	/// Begins the measurement period
	void start()
	{
	    QueryPerformanceCounter(&m_start);
	}

	/// \brief Ends measurement
	///
	/// Ends the measurement period
	void stop()
	{
	    QueryPerformanceCounter(&m_end);
	}
    /// @}

    /// \name Attributes
    /// @{
    public:
	/// \brief The elapsed count in the measurement period
	///
	/// This represents the extent, in machine-specific increments, of the measurement period
	interval_type periodCount()
	{
	    return m_end - m_start;
	}

	/// \brief The number of whole seconds in the measurement period
	///
	/// This represents the extent, in whole seconds, of the measurement period
	interval_type seconds()
	{
	    return periodCount() / sm_freq;
	}

	/// \brief The number of whole milliseconds in the measurement period
	///
	/// This represents the extent, in whole milliseconds, of the measurement period
	interval_type milliseconds()
	{
	    interval_type   result;
	    interval_type   count   =   periodCount();

	    if(count < 0x20C49BA5E353F7L)
	    {
		result = (count * 1000) / sm_freq;
	    }
	    else
	    {
		result = (count / sm_freq) * 1000;
	    }

	    return result;
	}

	/// \brief The number of whole microseconds in the measurement period
	///
	/// This represents the extent, in whole microseconds, of the measurement period
	interval_type microseconds()
	{
	    interval_type   result;
	    interval_type   count   =   periodCount();

	    if(count < 0x8637BD05AF6L)
	    {
		result = (count * 1000000) / sm_freq;
	    }
	    else
	    {
		result = (count / sm_freq) * 1000000;
	    }

	    return result;
	}
    /// @}

    /// \name Members
    /// @{
    private:
	epoch_type              m_start;    // start of measurement period
	epoch_type              m_end;      // End of measurement period
	static interval_type    sm_freq;    // Frequency
    /// @}
    }

    unittest
    {
	alias   HighPerformanceCounter  counter_type;

	counter_type    counter = new counter_type();

	counter.start();
	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us1 =   counter.microseconds();
	counter_type.interval_type  ms1 =   counter.milliseconds();
	counter_type.interval_type  s1  =   counter.seconds();

	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us2 =   counter.microseconds();
	counter_type.interval_type  ms2 =   counter.milliseconds();
	counter_type.interval_type  s2  =   counter.seconds();

	assert(us2 >= us1);
	assert(ms2 >= ms1);
	assert(s2 >= s1);
    }

    /* ////////////////////////////////////////////////////////////////////////// */

    /// \brief A low-cost, low-resolution performance counter
    ///
    /// This class provides low-resolution, but low-latency, performance monitoring
    /// and is guaranteed to be meaningful on all operating systems.
    ///
    /// \ingroup group_synsoft_win32_perf
    class TickCounter
    {
    /// \name Types
    /// @{
    private:
	alias   long    epoch_type;
    public:
	/// \brief The interval type
	///
	/// The type of the interval measurement, a 64-bit signed integer
	alias   long    interval_type;

	/// \brief The scope type
	///
	/// The type with which instances of the counter class can be subject to the RAII mechanism in order
	/// to scope particular measurement intervals
	alias PerformanceCounterScope!(TickCounter) scope_type;
    /// @}

    /// \name Construction
    /// @{
    public:
    /// @}

    /// \name Operations
    /// @{
    public:
	/// \brief Starts measurement
	///
	/// Begins the measurement period
	void start()
	{
	    m_start = GetTickCount();
	}

	/// \brief Ends measurement
	///
	/// Ends the measurement period
	void stop()
	{
	    m_end = GetTickCount();
	}
    /// @}

    /// \name Attributes
    /// @{
    public:
	/// \brief The elapsed count in the measurement period
	///
	/// This represents the extent, in machine-specific increments, of the measurement period
	interval_type periodCount()
	{
	    return m_end - m_start;
	}

	/// \brief The number of whole seconds in the measurement period
	///
	/// This represents the extent, in whole seconds, of the measurement period
	interval_type seconds()
	{
	    return periodCount() / 1000;
	}

	/// \brief The number of whole milliseconds in the measurement period
	///
	/// This represents the extent, in whole milliseconds, of the measurement period
	interval_type milliseconds()
	{
	    return periodCount();
	}

	/// \brief The number of whole microseconds in the measurement period
	///
	/// This represents the extent, in whole microseconds, of the measurement period
	interval_type microseconds()
	{
	    return periodCount() * 1000;
	}
    /// @}

    /// \name Members
    /// @{
    private:
	uint    m_start;    // start of measurement period
	uint    m_end;      // End of measurement period
    /// @}
    }

    unittest
    {
	alias TickCounter   counter_type;

	counter_type    counter = new counter_type();

	counter.start();
	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us1 =   counter.microseconds();
	counter_type.interval_type  ms1 =   counter.milliseconds();
	counter_type.interval_type  s1  =   counter.seconds();

	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us2 =   counter.microseconds();
	counter_type.interval_type  ms2 =   counter.milliseconds();
	counter_type.interval_type  s2  =   counter.seconds();

	assert(us2 >= us1);
	assert(ms2 >= ms1);
	assert(s2 >= s1);
    }

    /* ////////////////////////////////////////////////////////////////////////// */

    /// \brief A performance counter that provides thread-specific performance timings
    ///
    /// This class uses the operating system's performance monitoring facilities to provide timing 
    /// information pertaining to the calling thread only, irrespective of the activities of other
    /// threads on the system. This class does not provide meaningful timing information on operating
    /// systems that do not provide thread-specific monitoring.
    ///
    /// \ingroup group_synsoft_win32_perf
    class ThreadTimesCounter
    {
    /// \name Types
    /// @{
    private:
	alias   long    epoch_type;
    public:
	/// \brief The interval type
	///
	/// The type of the interval measurement, a 64-bit signed integer
	alias   long    interval_type;

	/// \brief The scope type
	///
	/// The type with which instances of the counter class can be subject to the RAII mechanism in order
	/// to scope particular measurement intervals
	alias PerformanceCounterScope!(ThreadTimesCounter)  scope_type;
    /// @}

    /// \name Construction
    /// @{
    public:
	/// \brief Constructor
	///
	/// Creates an instance of the class, and caches the thread token so that measurements will
	/// be taken with respect to the thread in which the class was created.
	this()
	{
	    m_thread = GetCurrentThread();
	}
    /// @}

    /// \name Operations
    /// @{
    public:
	/// \brief Starts measurement
	///
	/// Begins the measurement period
	void start()
	{
	    FILETIME    creationTime;
	    FILETIME    exitTime;

	    GetThreadTimes(m_thread, &creationTime, &exitTime, cast(FILETIME*)&m_kernelStart, cast(FILETIME*)&m_userStart);
	}

	/// \brief Ends measurement
	///
	/// Ends the measurement period
	void stop()
	{
	    FILETIME    creationTime;
	    FILETIME    exitTime;

	    GetThreadTimes(m_thread, &creationTime, &exitTime, cast(FILETIME*)&m_kernelEnd, cast(FILETIME*)&m_userEnd);
	}
    /// @}

    /// \name Attributes
    /// @{
    public:
	/// \name Kernel
	/// @{

	/// \brief The elapsed count in the measurement period for kernel mode activity
	///
	/// This represents the extent, in machine-specific increments, of the measurement period for kernel mode activity
	interval_type kernelPeriodCount()
	{
	    return m_kernelEnd - m_kernelStart;
	}
	/// \brief The number of whole seconds in the measurement period for kernel mode activity
	///
	/// This represents the extent, in whole seconds, of the measurement period for kernel mode activity
	interval_type kernelSeconds()
	{
	    return kernelPeriodCount() / 10000000;
	}
	/// \brief The number of whole milliseconds in the measurement period for kernel mode activity
	///
	/// This represents the extent, in whole milliseconds, of the measurement period for kernel mode activity
	interval_type kernelMilliseconds()
	{
	    return kernelPeriodCount() / 10000;
	}
	/// \brief The number of whole microseconds in the measurement period for kernel mode activity
	///
	/// This represents the extent, in whole microseconds, of the measurement period for kernel mode activity
	interval_type kernelMicroseconds()
	{
	    return kernelPeriodCount() / 10;
	}
	/// @}

	/// \name User
	/// @{

	/// \brief The elapsed count in the measurement period for user mode activity
	///
	/// This represents the extent, in machine-specific increments, of the measurement period for user mode activity
	interval_type userPeriodCount()
	{
	    return m_userEnd - m_userStart;
	}
	/// \brief The number of whole seconds in the measurement period for user mode activity
	///
	/// This represents the extent, in whole seconds, of the measurement period for user mode activity
	interval_type userSeconds()
	{
	    return userPeriodCount() / 10000000;
	}
	/// \brief The number of whole milliseconds in the measurement period for user mode activity
	///
	/// This represents the extent, in whole milliseconds, of the measurement period for user mode activity
	interval_type userMilliseconds()
	{
	    return userPeriodCount() / 10000;
	}
	/// \brief The number of whole microseconds in the measurement period for user mode activity
	///
	/// This represents the extent, in whole microseconds, of the measurement period for user mode activity
	interval_type userMicroseconds()
	{
	    return userPeriodCount() / 10;
	}
	/// @}

	/// \name Total
	/// @{

	/// \brief The elapsed count in the measurement period
	///
	/// This represents the extent, in machine-specific increments, of the measurement period
	interval_type periodCount()
	{
	    return kernelPeriodCount() + userPeriodCount();
	}

	/// \brief The number of whole seconds in the measurement period
	///
	/// This represents the extent, in whole seconds, of the measurement period
	interval_type seconds()
	{
	    return periodCount() / 10000000;
	}

	/// \brief The number of whole milliseconds in the measurement period
	///
	/// This represents the extent, in whole milliseconds, of the measurement period
	interval_type milliseconds()
	{
	    return periodCount() / 10000;
	}

	/// \brief The number of whole microseconds in the measurement period
	///
	/// This represents the extent, in whole microseconds, of the measurement period
	interval_type microseconds()
	{
	    return periodCount() / 10;
	}
	/// @}
    /// @}

    /// \name Members
    /// @{
    private:
	epoch_type  m_kernelStart;
	epoch_type  m_kernelEnd;
	epoch_type  m_userStart;
	epoch_type  m_userEnd;
	HANDLE      m_thread;
    /// @}
    }

    unittest
    {
	alias ThreadTimesCounter    counter_type;

	counter_type    counter = new counter_type();

	counter.start();
	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us1 =   counter.microseconds();
	counter_type.interval_type  ms1 =   counter.milliseconds();
	counter_type.interval_type  s1  =   counter.seconds();

	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us2 =   counter.microseconds();
	counter_type.interval_type  ms2 =   counter.milliseconds();
	counter_type.interval_type  s2  =   counter.seconds();

	assert(us2 >= us1);
	assert(ms2 >= ms1);
	assert(s2 >= s1);
    }

    /* ////////////////////////////////////////////////////////////////////////// */

    /// \brief A performance counter that provides process-specific performance timings
    ///
    /// This class uses the operating system's performance monitoring facilities to provide timing 
    /// information pertaining to the calling process only, irrespective of the activities of other
    /// processes on the system. This class does not provide meaningful timing information on operating
    /// systems that do not provide process-specific monitoring.
    ///
    /// \ingroup group_synsoft_win32_perf
    class ProcessTimesCounter
    {
    /// \name Types
    /// @{
    private:
	alias   long    epoch_type;
    public:
	/// \brief The interval type
	///
	/// The type of the interval measurement, a 64-bit signed integer
	alias   long    interval_type;

	/// \brief The scope type
	///
	/// The type with which instances of the counter class can be subject to the RAII mechanism in order
	/// to scope particular measurement intervals
	alias PerformanceCounterScope!(ProcessTimesCounter) scope_type;
    /// @}

    /// \name Construction
    /// @{
    private:
	/// \brief Class constructor
	///
	/// Detects availability of the high performance hardware counter, and if
	/// not available adjusts 
	static this()
	{
	    sm_process = GetCurrentProcess();
	}
    /// @}

    /// \name Operations
    /// @{
    public:
	/// \brief Starts measurement
	///
	/// Begins the measurement period
	void start()
	{
	    FILETIME    creationTime;
	    FILETIME    exitTime;

	    GetProcessTimes(sm_process, &creationTime, &exitTime, cast(FILETIME*)&m_kernelStart, cast(FILETIME*)&m_userStart);
	}

	/// \brief Ends measurement
	///
	/// Ends the measurement period
	void stop()
	{
	    FILETIME    creationTime;
	    FILETIME    exitTime;

	    GetProcessTimes(sm_process, &creationTime, &exitTime, cast(FILETIME*)&m_kernelEnd, cast(FILETIME*)&m_userEnd);
	}
    /// @}

    /// \name Attributes
    /// @{
    public:
	/// \name Kernel
	/// @{

	/// \brief The elapsed count in the measurement period for kernel mode activity
	///
	/// This represents the extent, in machine-specific increments, of the measurement period for kernel mode activity
	interval_type kernelPeriodCount()
	{
	    return m_kernelEnd - m_kernelStart;
	}
	/// \brief The number of whole seconds in the measurement period for kernel mode activity
	///
	/// This represents the extent, in whole seconds, of the measurement period for kernel mode activity
	interval_type kernelSeconds()
	{
	    return kernelPeriodCount() / 10000000;
	}
	/// \brief The number of whole milliseconds in the measurement period for kernel mode activity
	///
	/// This represents the extent, in whole milliseconds, of the measurement period for kernel mode activity
	interval_type kernelMilliseconds()
	{
	    return kernelPeriodCount() / 10000;
	}
	/// \brief The number of whole microseconds in the measurement period for kernel mode activity
	///
	/// This represents the extent, in whole microseconds, of the measurement period for kernel mode activity
	interval_type kernelMicroseconds()
	{
	    return kernelPeriodCount() / 10;
	}
	/// @}

	/// \name User
	/// @{

	/// \brief The elapsed count in the measurement period for user mode activity
	///
	/// This represents the extent, in machine-specific increments, of the measurement period for user mode activity
	interval_type userPeriodCount()
	{
	    return m_userEnd - m_userStart;
	}
	/// \brief The number of whole seconds in the measurement period for user mode activity
	///
	/// This represents the extent, in whole seconds, of the measurement period for user mode activity
	interval_type userSeconds()
	{
	    return userPeriodCount() / 10000000;
	}
	/// \brief The number of whole milliseconds in the measurement period for user mode activity
	///
	/// This represents the extent, in whole milliseconds, of the measurement period for user mode activity
	interval_type userMilliseconds()
	{
	    return userPeriodCount() / 10000;
	}
	/// \brief The number of whole microseconds in the measurement period for user mode activity
	///
	/// This represents the extent, in whole microseconds, of the measurement period for user mode activity
	interval_type userMicroseconds()
	{
	    return userPeriodCount() / 10;
	}
	/// @}

	/// \name Total
	/// @{

	/// \brief The elapsed count in the measurement period
	///
	/// This represents the extent, in machine-specific increments, of the measurement period
	interval_type periodCount()
	{
	    return kernelPeriodCount() + userPeriodCount();
	}

	/// \brief The number of whole seconds in the measurement period
	///
	/// This represents the extent, in whole seconds, of the measurement period
	interval_type seconds()
	{
	    return periodCount() / 10000000;
	}

	/// \brief The number of whole milliseconds in the measurement period
	///
	/// This represents the extent, in whole milliseconds, of the measurement period
	interval_type milliseconds()
	{
	    return periodCount() / 10000;
	}

	/// \brief The number of whole microseconds in the measurement period
	///
	/// This represents the extent, in whole microseconds, of the measurement period
	interval_type microseconds()
	{
	    return periodCount() / 10;
	}
	/// @}
    /// @}

    /// \name Members
    /// @{
    private:
	epoch_type      m_kernelStart;
	epoch_type      m_kernelEnd;
	epoch_type      m_userStart;
	epoch_type      m_userEnd;
	static HANDLE   sm_process;
    /// @}
    }

    unittest
    {
	alias ProcessTimesCounter   counter_type;

	counter_type    counter = new counter_type();

	counter.start();
	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us1 =   counter.microseconds();
	counter_type.interval_type  ms1 =   counter.milliseconds();
	counter_type.interval_type  s1  =   counter.seconds();

	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us2 =   counter.microseconds();
	counter_type.interval_type  ms2 =   counter.milliseconds();
	counter_type.interval_type  s2  =   counter.seconds();

	assert(us2 >= us1);
	assert(ms2 >= ms1);
	assert(s2 >= s1);
    }

    /* ////////////////////////////////////////////////////////////////////////// */

    /// \brief A performance counter that uses the most accurate measurement APIs available on the host machine
    ///
    /// This class attempts to use the high performance hardware counter as its measurement resource, but failing 
    /// that it defaults to less accurate resources in order to guarantee that meaningful measurements are always
    /// available to application code
    ///
    /// \ingroup group_synsoft_win32_perf
    class PerformanceCounter
    {
    /// \name Types
    /// @{
    private:
	alias   long    epoch_type;
    public:
	/// \brief The interval type
	///
	/// The type of the interval measurement, a 64-bit signed integer
	alias   long    interval_type;

	/// \brief The scope type
	///
	/// The type with which instances of the counter class can be subject to the RAII mechanism in order
	/// to scope particular measurement intervals
	alias PerformanceCounterScope!(PerformanceCounter)    scope_type;
    /// @}

    /// \name Constructors
    /// @{
    private:
	/// \brief Class constructor
	///
	/// Detects availability of the high performance hardware counter, and if
	/// not available adjusts 
	static this()
	{
	    if(QueryPerformanceFrequency(&sm_freq))
	    {
		sm_fn   =   &_qpc;
	    }
	    else
	    {
		sm_freq =   1000;
		sm_fn   =   &_qtc;
	    }
	}
    /// @}

    /// \name Operations
    /// @{
    public:
	/// \brief Starts measurement
	///
	/// Begins the measurement period
	void start()
	{
	    sm_fn(m_start);
	}

	/// \brief Ends measurement
	///
	/// Ends the measurement period
	void stop()
	{
	    sm_fn(m_end);
	}
    /// @}

    /// \name Attributes
    /// @{
    public:
	/// \brief The elapsed count in the measurement period
	///
	/// This represents the extent, in machine-specific increments, of the measurement period
	interval_type periodCount()
	{
	    return m_end - m_start;
	}

	/// \brief The number of whole seconds in the measurement period
	///
	/// This represents the extent, in whole seconds, of the measurement period
	interval_type seconds()
	{
	    return periodCount() / sm_freq;
	}

	/// \brief The number of whole milliseconds in the measurement period
	///
	/// This represents the extent, in whole milliseconds, of the measurement period
	interval_type milliseconds()
	{
	    interval_type   result;
	    interval_type   count   =   periodCount();

	    if(count < 0x20C49BA5E353F7L)
	    {
		result = (count * 1000) / sm_freq;
	    }
	    else
	    {
		result = (count / sm_freq) * 1000;
	    }

	    return result;
	}

	/// \brief The number of whole microseconds in the measurement period
	///
	/// This represents the extent, in whole microseconds, of the measurement period
	interval_type microseconds()
	{
	    interval_type   result;
	    interval_type   count   =   periodCount();

	    if(count < 0x8637BD05AF6L)
	    {
		result = (count * 1000000) / sm_freq;
	    }
	    else
	    {
		result = (count / sm_freq) * 1000000;
	    }

	    return result;
	}
    /// @}

    /// \name Implementation
    /// @{
    private:
	alias void function(out epoch_type interval)    measure_func;

	static void _qpc(out epoch_type interval)
	{
	    QueryPerformanceCounter(&interval);
	}

	static void _qtc(out epoch_type interval)
	{
	    interval = GetTickCount();
	}
    /// @}

    /// \name Members
    /// @{
    private:
	epoch_type              m_start;    // start of measurement period
	epoch_type              m_end;      // End of measurement period
	static interval_type    sm_freq;    // Frequency
	static measure_func     sm_fn;      // Measurement function
    /// @}
    }

    unittest
    {
	alias PerformanceCounter    counter_type;

	counter_type    counter = new counter_type();

	counter.start();
	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us1 =   counter.microseconds();
	counter_type.interval_type  ms1 =   counter.milliseconds();
	counter_type.interval_type  s1  =   counter.seconds();

	volatile for(int i = 0; i < 10000000; ++i)
	{   }
	counter.stop();

	counter_type.interval_type  us2 =   counter.microseconds();
	counter_type.interval_type  ms2 =   counter.milliseconds();
	counter_type.interval_type  s2  =   counter.seconds();

	assert(us2 >= us1);
	assert(ms2 >= ms1);
	assert(s2 >= s1);
    }

    /* ////////////////////////////////////////////////////////////////////////// */
}
else
{
    const int platform_not_supported = 0;

    static assert(platform_not_supported);
}
