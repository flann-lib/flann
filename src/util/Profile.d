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

	public double value;
	
	public this() {
		value = 0;
		version (Posix) {
			clk_tck = sysconf(_SC_CLK_TCK);
		}
	}
	
	public void start() {
		version(Posix) {
			times(&startTime);
		}
		else {
			startTime = clock();
		}
	}
	
	public void stop() {
		version (Posix) {
			tms stopTime;
			times(&stopTime);
			value += (cast(typeof(value))(stopTime.tms_utime-startTime.tms_utime))/clk_tck;
		}
		else {
			value += (cast(typeof(value)) clock() - startTime) / CLOCKS_PER_SEC;
		}
	}
	
	public void reset() {
		value = 0;
	}

}

float profile( void delegate() action)
{
	scope StartStopTimer t = new StartStopTimer();
	t.start;
	action();
	t.stop;
	return t.value;
}

