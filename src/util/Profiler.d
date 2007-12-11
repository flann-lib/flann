module util.profiler;

version (Posix) {
 	import tango.stdc.posix.sys.time;
}
else {
	import tango.stdc.time;
}

class StartStopTimer
{
	private:
	long startTime;

	public double value;
	
	public this() {
		value = 0;
	}
	
	public void start() {
		version(Posix) {
			timeval t;
			gettimeofday(&t, null);
			startTime = t.tv_sec * 1000 + t.tv_usec / 1000;
		}
		else {
			startTime = clock();
		}
	}
	
	public void stop() {
		version (Posix) {
			timeval t;
			gettimeofday(&t, null);
			long endTime = t.tv_sec * 1000 + t.tv_usec / 1000;
			value += cast(typeof(value))(endTime - startTime) / 1000;
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
	StartStopTimer t = new StartStopTimer();
	t.start;
	action();
	t.stop;
	return t.value;
}

