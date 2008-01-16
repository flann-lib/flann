/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.dlfcn;

private import tango.stdc.posix.config;

extern (C):

//
// XOpen (XSI)
//
/*
RTLD_LAZY
RTLD_NOW
RTLD_GLOBAL
RTLD_LOCAL

int   dlclose(void*);
char* dlerror();
void* dlopen(char*, int);
void* dlsym(void*, char*);
*/

version( linux )
{
    const RTLD_LAZY     = 0x00001;
    const RTLD_NOW      = 0x00002;
    const RTLD_GLOBAL   = 0x00100;
    const RTLD_LOCAL    = 0x00000;

    int   dlclose(void*);
    char* dlerror();
    void* dlopen(char*, int);
    void* dlsym(void*, char*);
}
else version( darwin )
{
    const RTLD_LAZY     = 0x00001;
    const RTLD_NOW      = 0x00002;
    const RTLD_GLOBAL   = 0x00100;
    const RTLD_LOCAL    = 0x00000;

    int   dlclose(void*);
    char* dlerror();
    void* dlopen(char*, int);
    void* dlsym(void*, char*);
}
