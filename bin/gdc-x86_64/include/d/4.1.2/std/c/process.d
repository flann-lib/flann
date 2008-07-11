
/**
 * C's &lt;process.h&gt;
 * Authors: Walter Bright, Digital Mars, www.digitalmars.com
 * License: Public Domain
 * Macros:
 *	WIKI=Phobos/StdCProcess
 */

module std.c.process;

private import std.c.stddef;

extern (C):

void exit(int);
void _c_exit();
void _cexit();
void _exit(int);
void abort();
void _dodtors();
int getpid();

int system(char *);

enum { _P_WAIT, _P_NOWAIT, _P_OVERLAY };

int execl(char *, char *,...);
int execle(char *, char *,...);
int execlp(char *, char *,...);
int execlpe(char *, char *,...);
int execv(char *, char **);
int execve(char *, char **, char **);
int execvp(char *, char **);
int execvpe(char *, char **, char **);


enum { WAIT_CHILD, WAIT_GRANDCHILD }

int cwait(int *,int,int);
int wait(int *);

version (Windows)
{
    uint _beginthread(void function(void *),uint,void *);

    extern (Windows) alias uint (*stdfp)(void *);

    uint _beginthreadex(void* security, uint stack_size,
	    stdfp start_addr, void* arglist, uint initflag,
	    uint* thrdaddr);

    void _endthread();
    void _endthreadex(uint);

    int spawnl(int, char *, char *,...);
    int spawnle(int, char *, char *,...);
    int spawnlp(int, char *, char *,...);
    int spawnlpe(int, char *, char *,...);
    int spawnv(int, char *, char **);
    int spawnve(int, char *, char **, char **);
    int spawnvp(int, char *, char **);
    int spawnvpe(int, char *, char **, char **);


    int _wsystem(wchar_t *);
    int _wspawnl(int, wchar_t *, wchar_t *, ...);
    int _wspawnle(int, wchar_t *, wchar_t *, ...);
    int _wspawnlp(int, wchar_t *, wchar_t *, ...);
    int _wspawnlpe(int, wchar_t *, wchar_t *, ...);
    int _wspawnv(int, wchar_t *, wchar_t **);
    int _wspawnve(int, wchar_t *, wchar_t **, wchar_t **);
    int _wspawnvp(int, wchar_t *, wchar_t **);
    int _wspawnvpe(int, wchar_t *, wchar_t **, wchar_t **);

    int _wexecl(wchar_t *, wchar_t *, ...);
    int _wexecle(wchar_t *, wchar_t *, ...);
    int _wexeclp(wchar_t *, wchar_t *, ...);
    int _wexeclpe(wchar_t *, wchar_t *, ...);
    int _wexecv(wchar_t *, wchar_t **);
    int _wexecve(wchar_t *, wchar_t **, wchar_t **);
    int _wexecvp(wchar_t *, wchar_t **);
    int _wexecvpe(wchar_t *, wchar_t **, wchar_t **);
}


