/************************************************************************
 * Profiling functionality.
 *
 * This module contains classes and helper functions used throughout
 * the application to measure execution times.  
 * 
 * Authors: Marius Muja, mariusm@cs.ubc.ca
 * 
 * Version: 0.9
 * 
 * History:
 * 
 * License:
 * 
 *************************************************************************/
module util.Profile;

version (Posix) {
 	import tango.stdc.posix.sys.time;
	import tango.stdc.posix.unistd;
	
 	struct tms {
      clock_t tms_utime;  /* user time */
      clock_t tms_stime;  /* system time */
      clock_t tms_cutime; /* user time of children */
      clock_t tms_cstime; /* system time of children */
	}

	extern(C) clock_t times(tms *buf);
}
else {
	import tango.stdc.time;
}

/**
 * A start-stop timer class.
 * 
 * Can be used to time portions of code in a similar way to 
 * how a start-stop timer is used:
 * ---
 * auto timer = new StartStopTimer()
 * timer.start()
 * ...
 * timer.stop()
 * float duration = timer.value;
 * ---
 */
class StartStopTimer
{
	private:
	version (Posix) {
		tms startTime;
		int clk_tck;
	}
	else {
		long startTime;
	}

	/**
	 * Value of the timer.
	 */
	public double value;
	
	
	/**
	 * Constructor.
	 */
	public this() {
		version (Posix) {
			clk_tck = sysconf(_SC_CLK_TCK);
		}
		reset();
	}
	
	/**
	 * Starts the timer.
	 */
	public void start() {
		version(Posix) {
			times(&startTime);
		}
		else {
			startTime = clock();
		}
	}
	
	/**
	 * Stops the timer ans updates timer value.
	 */
	public void stop() {
		version (Posix) {
			tms stopTime;
			times(&stopTime);
			value += (cast(typeof(value))(stopTime.tms_utime+stopTime.tms_stime-(startTime.tms_utime+startTime.tms_stime)))/clk_tck;
		}
		else {
			value += (cast(typeof(value)) clock() - startTime) / CLOCKS_PER_SEC;
		}
	}
	
	/**
	 * Resets the timer value to 0.
	 */
	public void reset() {
		value = 0;
	}

}

/**
 * Helper function used to profile short pieces of code
 * Params:
 *     action = a delegate containing the code to be profiled
 *	   minTime = minimum time the delegate execution should take. If
 *			the delegate executes faster it is executed again util the minTime
 *			duration is exceeded. This is needed in order to get a reliable time 
 *			measurement for the routines that take very little time to execute,
 *			but it requires that the delegate execution produces no side-effects
 *			(so that it can be executed multiple times).
 * Returns: the execution time of the delegate
 * ---
 * float duration = profille(
 * {
 * 		// some code here
 * 		...
 * }
 * );
 * ---
 */
float profile( void delegate() action, float minTime = -1)
{
	scope StartStopTimer t = new StartStopTimer();
	
	if (minTime < 0) {
		t.start();
		action();
		t.stop();
		return t.value;
	} else {
		int count = 0;
		while (t.value<minTime) {
			t.start();
			action();
			t.stop();
			count++;
		}
		return t.value/count;
	}
}

