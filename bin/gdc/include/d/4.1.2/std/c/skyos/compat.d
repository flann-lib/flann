module std.c.skyos.compat;
private import std.c.unix.unix;
private import std.c.skyos.skyos;

enum {
    TASK_CREATE_FLAG_WANT_WAIT_FOR = 0x00002000
}

// libpthread pthread_create has problems?
int pthread_create(pthread_t * pth, pthread_attr_t * attr, void*  fn, void * arg)
{
    int tid = ThreadCreate("thread", TASK_CREATE_FLAG_WANT_WAIT_FOR,
	cast(void *) fn, cast(uint) arg, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    if (tid) {
	*pth = tid;
	return 0;
    } else {
	return EAGAIN;
    }
}
int pthread_join(pthread_t thread, void ** result)
{
    int v;
    int r = ThreadWait(thread, & v);
    if (r == thread) {
	if (result)
	    *result = null;
	return 0;
    } else
	return -1;
}

pthread_t pthread_self() { return cast(pthread_t) ThreadGetPid(); }
int pthread_equal(pthread_t a, pthread_t b) { return a == b; }
int pthread_kill(pthread_t pth, int sig) { return kill(cast(pid_t) pth, sig); }
alias ThreadYield sched_yield;

int pthread_suspend_np(pthread_t p) { return ThreadSuspend(p) == 0 ? 0 : -1; }
int pthread_continue_np(pthread_t p) { return ThreadResume(p) == 0 ? 0 : -1; }
