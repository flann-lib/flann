/*
Project: nn
*/

module util.timer;

import std.c.time;
import util.logger;
version (Unix) {
	import std.c.unix.unix;
}

class StartStopTimer
{
	private:
	long startTime;

	public float value;
	
	public this() {
		value = 0;
	}
	
	public void start() {
		version(Unix) {
			timeval t;
			gettimeofday(&t, null);
			startTime = t.tv_sec * 1000 + t.tv_usec / 1000;
		}
		else {
			startTime = clock();
		}
	}
	
	public void stop() {
		version (Unix) {
			timeval t;
			gettimeofday(&t, null);
			value += (cast(float)(t.tv_sec * 1000 + t.tv_usec / 1000) - startTime) / 1000;
		}
		else {
			value += (cast(float) clock() - startTime) / CLOCKS_PER_SEC;
		}
	}
	
	public void reset() {
		value = 0;
	}

}