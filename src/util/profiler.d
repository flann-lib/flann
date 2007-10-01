

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

float getProfilerTime()
{
	return timer.value;
}


float profile( void delegate() action)
{
	StartStopTimer t = new StartStopTimer();
	t.start;
	action();
	t.stop;
	return t.value;
}

