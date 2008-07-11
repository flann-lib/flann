module std.c.skyos.skyos;

extern(C):

int ThreadCreate (char *ucName, uint uiFlags, void *fpFunction, uint arg1, uint arg2, uint arg3, uint arg4, uint arg5, uint arg6, uint arg7, uint arg8, uint arg9, uint arg10);
int ThreadWait (int iPid, int *iStatus);
int ThreadGetPid ();
int ThreadSuspend (int iPid);
int ThreadResume (int iPid);
void ThreadYield ();
int ThreadSleep (uint uiMilliseconds);
