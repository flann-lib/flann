

module util.profiler;


import util.timer;


private StartStopTimer timer;

static this() {
	timer = new StartStopTimer();
}


void startProfiler()
{
	timer.start();
}


void stopProfiler()
{
	timer.stop();
}

void profile( void delegate() action)
{
	timer.start;
	action();
	timer.stop;
}

float getProfilerTime()
{
	return timer.value;
}