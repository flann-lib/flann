/*
Project: nn
*/

module util.timer;

import std.c.time;
import util.logger;


class StartStopTimer
{
	private:
	clock_t startTime;

	public float value;
	
	public this() {
		value = 0;
	}
	
	public void start() {
		startTime = clock();
	}
	
	public void stop() {
		value += (cast(float) clock() - startTime) / CLOCKS_PER_SEC;
	}
	
	public void reset() {
		value = 0;
	}

}