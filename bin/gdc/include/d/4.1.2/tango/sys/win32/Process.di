/*
 * Written by Sean Kelly
 * Placed into Public Domain
 */

module tango.sys.win32.Process;


private
{
    import tango.stdc.stdint;
    import tango.stdc.stddef;
}

extern (C):

enum
{
    P_WAIT,
    P_NOWAIT,
    P_OVERLAY,
    P_NOWAITO,
    P_DETACH,
}

enum
{
    WAIT_CHILD,
    WAIT_GRANDCHILD,
}

private
{
    extern (C) alias void function(void*) bt_fptr;
    extern (Windows) alias uint function(void*) btex_fptr;
}

uintptr_t _beginthread(bt_fptr, uint, void*);
void _endthread();
uintptr_t _beginthreadex(void*, uint, btex_fptr, void*, uint, uint *);
void _endthreadex(uint);

void abort();
void exit(int);
void _exit(int);
void _cexit();
void _c_exit();

intptr_t cwait(int*, intptr_t, int);
intptr_t wait(int*);

int getpid();
int system(char*);

intptr_t spawnl(int, char*, char*, ...);
intptr_t spawnle(int, char*, char*, ...);
intptr_t spawnlp(int, char*, char*, ...);
intptr_t spawnlpe(int, char*, char*, ...);
intptr_t spawnv(int, char*, char**);
intptr_t spawnve(int, char*, char**, char**);
intptr_t spawnvp(int, char*, char**);
intptr_t spawnvpe(int, char*, char**, char**);

intptr_t execl(char*, char*, ...);
intptr_t execle(char*, char*, ...);
intptr_t execlp(char*, char*, ...);
intptr_t execlpe(char*, char*, ...);
intptr_t execv(char*, char**);
intptr_t execve(char*, char**, char**);
intptr_t execvp(char*, char**);
intptr_t execvpe(char*, char**, char**);

int _wsystem(wchar_t*);

intptr_t _wspawnl(int, wchar_t*, wchar_t*, ...);
intptr_t _wspawnle(int, wchar_t*, wchar_t*, ...);
intptr_t _wspawnlp(int, wchar_t*, wchar_t*, ...);
intptr_t _wspawnlpe(int, wchar_t*, wchar_t*, ...);
intptr_t _wspawnv(int, wchar_t*, wchar_t**);
intptr_t _wspawnve(int, wchar_t*, wchar_t**, wchar_t**);
intptr_t _wspawnvp(int, wchar_t*, wchar_t**);
intptr_t _wspawnvpe(int, wchar_t*, wchar_t**, wchar_t**);

intptr_t _wexecl(wchar_t*, wchar_t*, ...);
intptr_t _wexecle(wchar_t*, wchar_t*, ...);
intptr_t _wexeclp(wchar_t*, wchar_t*, ...);
intptr_t _wexeclpe(wchar_t*, wchar_t*, ...);
intptr_t _wexecv(wchar_t*, wchar_t**);
intptr_t _wexecve(wchar_t*, wchar_t**, wchar_t**);
intptr_t _wexecvp(wchar_t*, wchar_t**);
intptr_t _wexecvpe(wchar_t*, wchar_t**, wchar_t**);
