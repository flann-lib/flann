/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.dirent;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for ino_t

extern (C):

//
// Required
//
/*
DIR

struct dirent
{
    char[] d_name;
}

int     closedir(DIR*);
DIR*    opendir(char*);
dirent* readdir(DIR*);
void    rewinddir(DIR*);
*/

version( linux )
{
    // NOTE: The following constants are non-standard Linux definitions
    //       for dirent.d_type.
    enum
    {
        DT_UNKNOWN  = 0,
        DT_FIFO     = 1,
        DT_CHR      = 2,
        DT_DIR      = 4,
        DT_BLK      = 6,
        DT_REG      = 8,
        DT_LNK      = 10,
        DT_SOCK     = 12,
        DT_WHT      = 14
    }

    struct dirent
    {
        ino_t       d_ino;
        off_t       d_off;
        ushort      d_reclen;
        ubyte       d_type;
        char[256]   d_name;
    }

    struct DIR
    {
        // Managed by OS
    }

    dirent* readdir(DIR*);
}
else version( darwin )
{
    enum
    {
        DT_UNKNOWN  = 0,
        DT_FIFO     = 1,
        DT_CHR      = 2,
        DT_DIR      = 4,
        DT_BLK      = 6,
        DT_REG      = 8,
        DT_LNK      = 10,
        DT_SOCK     = 12,
        DT_WHT      = 14
    }

    align(4)
    struct dirent
    {
        ino_t       d_ino;
        ushort      d_reclen;
        ubyte       d_type;
        ubyte       d_namlen;
        char[256]   d_name;
    }

    struct DIR
    {
        // Managed by OS
    }

    dirent* readdir(DIR*);
}
else
{
    dirent* readdir(DIR*);
}

int     closedir(DIR*);
DIR*    opendir(char*);
//dirent* readdir(DIR*);
void    rewinddir(DIR*);

//
// Thread-Safe Functions (TSF)
//
/*
int readdir_r(DIR*, dirent*, dirent**);
*/

int readdir_r(DIR*, dirent*, dirent**);

//
// XOpen (XSI)
//
/*
void   seekdir(DIR*, c_long);
c_long telldir(DIR*);
*/

version( linux )
{
    void   seekdir(DIR*, c_long);
    c_long telldir(DIR*);
}
