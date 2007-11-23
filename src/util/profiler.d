module util.profiler;

import util.timer;

float profile( void delegate() action)
{
	StartStopTimer t = new StartStopTimer();
	t.start;
	action();
	t.stop;
	return t.value;
}

