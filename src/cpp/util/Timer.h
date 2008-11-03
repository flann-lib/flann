#ifndef TIMER_H
#define TIMER_H

#include <time.h>

/**
 * A start-stop timer class.
 * 
 * Can be used to time portions of code.
 */
class StartStopTimer
{
    clock_t startTime;
 
public:
    /**
     * Value of the timer.
     */
    double value;
    
    
    /**
     * Constructor.
     */
    StartStopTimer() 
    {
        reset();
    }
    
    /**
     * Starts the timer.
     */
    void start() {
        startTime = clock();
    }
    
    /**
     * Stops the timer and updates timer value.
     */
    void stop() {
        clock_t stopTime = clock();
        value += ( (double)stopTime - startTime) / CLOCKS_PER_SEC;
    }
    
    /**
     * Resets the timer value to 0.
     */
    void reset() {
        value = 0;
    }

};

#endif // TIMER_H
