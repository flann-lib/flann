/**
 * This module provides an implementation of the classical thread-pool model.
 *
 * Copyright: Copyright (C) 2007-2008 Anders Halager. All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Author:    Anders Halager
 */

module tango.core.ThreadPool;

private import  tango.core.Thread,
                tango.core.Atomic;

private import  tango.core.sync.Mutex,
                tango.core.sync.Condition;

/**
 * A thread pool is a way to process multiple jobs in parallel without creating
 * a new thread for each job. This way the overhead of creating a thread is
 * only paid once, and not once for each job and you can limit the maximum
 * number of threads active at any one point.
 *
 * In this case a "job" is simply a delegate and some parameters the delegate
 * will be called with after having been added to the thread pool's queue.
 *
 * Example:
 * --------------------
 * // create a new pool with two threads
 * auto pool = new ThreadPool!(int)(2);
 * void delegate(int) f = (int x) { Stdout(x).newline; };
 *
 * // Now we have three ways of telling the pool to execute our jobs
 * // First we can say we just want it done at some later point
 * pool.append(f, 1);
 * // Secondly we can ask for a job to be done as soon as possible, blocking
 * // until it is started by some thread
 * pool.assign(f, 2);
 * // Finally we can say we either want it done immediately or not at all
 * if (pool.tryAssign(f, 3))
 *     Stdout("Someone took the job!").newline;
 * else
 *     Stdout("No one was available to do the job right now").newline;
 * // After giving the pool some jobs to do, we need to give it a chance to
 * // finish, so we can do one of two things.
 * // Choice no. 1 is to finish what has already been assigned to the threads,
 * // but ignore any remaining queued jobs
 * //   pool.shutdown();
 * // The other choice is to finish all jobs currently executing or in queue:
 * pool.finish();
 * --------------------
 *
 * If append isn't called there should be no additional heap allocations after
 * initialization.
 */

class ThreadPool(Args...)
{
    /// An alias for the type of delegates this thread pool considers a job
    alias void delegate(Args) JobD;

    /**
     * Create a new ThreadPool.
     *
     * Params:
     *   workers = The amount of threads to spawn
     *   q_size  = The expected size of the queue (how many elements are
     *   preallocated)
     */
    this(size_t workers, size_t q_size = 0)
    {
        // pre-allocate memory for q_size jobs in the queue
        q.length = q_size;
        q.length = 0;

        m = new Mutex;
        poolActivity = new Condition(m);
        workerActivity = new Condition(m);

        priority_job.store(cast(Job*)null);
        active_jobs.store(0u);
        done.store(false);

        for (size_t i = 0; i < workers; i++)
        {
            auto thread = new Thread(&doJob);
            // Allow the OS to kill the threads if we exit the program without
            // handling them our selves
            thread.isDaemon = true;
            thread.start();
            pool ~= thread;
        }
    }

    /**
      Assign the given job to a thread immediately or block until one is
      available
     */
    void assign(JobD job, Args args)
    {
        m.lock();
        scope(exit) m.unlock();
        auto j = Job(job, args);
        priority_job.store(&j);
        poolActivity.notify();
        // Wait until someone has taken the job
        while (priority_job.load() !is null)
            workerActivity.wait();
    }

    /**
      Assign the given job to a thread immediately or return false if none is
      available. (Returns true if one was available)
     */
    bool tryAssign(JobD job, Args args)
    {
        if (active_jobs.load() >= pool.length)
            return false;
        assign(job, args);
        return true;
    }

    /**
      Put a job into the pool for eventual execution.

      Warning: Acts as a stack, not a queue as you would expect
     */
    void append(JobD job, Args args)
    {
        m.lock();
        q ~= Job(job, args);
        m.unlock();
        poolActivity.notify();
    }

    /// Get the number of jobs waiting to be executed
    size_t pendingJobs()
    {
        m.lock(); scope(exit) m.unlock();
        return q.length;
    }

    /// Get the number of jobs being executed
    size_t activeJobs()
    {
        return active_jobs.load();
    }

    /// Finish currently executing jobs and drop all pending.
    void shutdown()
    {
        done.store(true);
        m.lock();
        q.length = 0;
        m.unlock();
        poolActivity.notifyAll();
        foreach (thread; pool)
            thread.join();
        m.lock();
        m.unlock();
    }

    /// Complete all pending jobs and shutdown.
    void finish()
    {
        m.lock();
        while (q.length > 0 || active_jobs.load() > 0)
            workerActivity.wait();
        m.unlock();
        shutdown();
    }

private:
    // Our list of threads -- only used during startup and shutdown
    Thread[] pool;
    struct Job
    {
        JobD dg;
        Args args;
    }
    // Used for storing queued jobs that will be executed eventually
    Job[] q;

    // This is to store a single job for immediate execution, which hopefully
    // means that any program using only assign and tryAssign wont need any
    // heap allocations after startup.
    Atomic!(Job*) priority_job;

    // This should be used when accessing the job queue
    Mutex m;

    // Notify is called on this condition whenever we have activity in the pool
    // that the workers might want to know about.
    Condition poolActivity;

    // Worker threads call notify on this when they are done with a job or are
    // completely done.
    // This allows a graceful shut down and is necessary since assign has to
    // wait for a job to become available
    Condition workerActivity;

    // Are we in the shutdown phase?
    Atomic!(bool) done;

    // Counter for the number of jobs currently being calculated
    Atomic!(size_t) active_jobs;

    // Thread delegate:
    void doJob()
    {
        while (!done.load())
        {
            m.lock();
            while (q.length == 0 && priority_job.load() is null && !done.load())
                poolActivity.wait();
            if (done.load()) {
                m.unlock(); // not using scope(exit), need to manually unlock
                break;
            }
            Job job;
            Job* jobPtr = priority_job.load();
            if (jobPtr !is null)
            {
                job = *jobPtr;
                priority_job.store(cast(Job*)null);
                workerActivity.notify();
            }
            else
            {
                // A stack -- should be a queue
                job = q[$ - 1];
                q.length = q.length - 1;
            }

            // Make sure we unlock before we start doing the calculations
            m.unlock();

            // Do the actual job
            active_jobs.increment();
            try {
                job.dg(job.args);
            } catch (Exception ex) { }
            active_jobs.decrement();

            // Tell the pool that we are done with something
            m.lock();
            workerActivity.notify();
            m.unlock();
        }
        // Tell the pool that we are now done
        m.lock();
        workerActivity.notify();
        m.unlock();
    }
}



/*******************************************************************************

*******************************************************************************/

debug (ThreadPool)
{
        import tango.util.log.Trace;
        import Integer = tango.text.convert.Integer;

        void main(char[][] args)
        {
                long job(long val)
                {
                        // a 'big job'
                        Thread.sleep (3.0/val);
                        return val;
                }

                void hashJob(char[] file)
                {
                        // If we don't catch exceptions the thread-pool will still
                        // work, but the job will fail silently
                        try {
                            long n = Integer.parse(file);
                            Trace.formatln("job({}) = {}", n, job(n));
                            } catch (Exception ex) {
                                    Trace.formatln("Exception: {}", ex.msg);
                                    }
                }

                // Create new thread pool with one worker thread per file given
                auto thread_pool = new ThreadPool!(char[])(args.length - 1);

                Thread.sleep(1);
                Trace.formatln ("starting");

                foreach (file; args[1 .. args.length])
                         thread_pool.assign(&hashJob, file);

                thread_pool.finish();
        }
}
