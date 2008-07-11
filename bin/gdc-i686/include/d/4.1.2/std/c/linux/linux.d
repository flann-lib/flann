// This is a backwards compatibility module for the DMD std.c.linux.linux

module std.c.linux.linux;

public import std.c.unix.unix;
public import std.c.dirent;
public import std.c.linux.linuxextern;

extern (C)
{
    /* From <dlfcn.h>
     * See http://www.opengroup.org/onlinepubs/007908799/xsh/dlsym.html
     */

    const int RTLD_NOW = 0x00002;	// Correct for Red Hat 8

    void* dlopen(in char* file, int mode);
    int   dlclose(void* handle);
    void* dlsym(void* handle, char* name);
    char* dlerror();
}
