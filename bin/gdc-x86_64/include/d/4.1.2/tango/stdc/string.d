/**
 * D header file for C99.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: ISO/IEC 9899:1999 (E)
 */
module tango.stdc.string;

private import tango.stdc.stddef;

extern (C):

void* memchr(void* s, int c, size_t n);
int   memcmp(void* s1, void* s2, size_t n);
void* memcpy(void* s1, void* s2, size_t n);
void* memmove(void* s1, void* s2, size_t n);
void* memset(void* s, int c, size_t n);

char*  strcpy(char* s1, char* s2);
char*  strncpy(char* s1, char* s2, size_t n);
char*  strcat(char* s1, char* s2);
char*  strncat(char* s1, char* s2, size_t n);
int    strcmp(char* s1, char* s2);
int    strcoll(char* s1, char* s2);
int    strncmp(char* s1, char* s2, size_t n);
size_t strxfrm(char* s1, char* s2, size_t n);
char*  strchr(char* s, int c);
size_t strcspn(char* s1, char* s2);
char*  strpbrk(char* s1, char* s2);
char*  strrchr(char* s, int c);
size_t strspn(char* s1, char* s2);
char*  strstr(char* s1, char* s2);
char*  strtok(char* s1, char* s2);
char*  strerror(int errnum);
size_t strlen(char* s);

version( Posix )
{
    char* strdup(char*);
}

wchar_t* wmemchr(wchar_t* s, wchar_t c, size_t n);
int      wmemcmp(wchar_t* s1, wchar_t* s2, size_t n);
wchar_t* wmemcpy(wchar_t* s1, wchar_t* s2, size_t n);
wchar_t* wmemmove(wchar_t*s1, wchar_t*s2, size_t n);
wchar_t* wmemset(wchar_t* s, wchar_t c, size_t n);

wchar_t* wcscpy(wchar_t* s1, wchar_t* s2);
wchar_t* wcsncpy(wchar_t* s1, wchar_t* s2, size_t n);
wchar_t* wcscat(wchar_t* s1, wchar_t* s2);
wchar_t* wcsncat(wchar_t* s1, wchar_t* s2, size_t n);
int      wcscmp(wchar_t*s1, wchar_t*s2);
int      wcscoll(wchar_t*s1, wchar_t*s2);
int      wcsncmp(wchar_t*s1, wchar_t*s2, size_t n);
size_t   wcsxfrm(wchar_t* s1, wchar_t* s2, size_t n);
wchar_t* wcschr(wchar_t* s, wchar_t c);
size_t   wcscspn(wchar_t*s1, wchar_t*s2);
wchar_t* wcspbrk(wchar_t*s1, wchar_t*s2);
wchar_t* wcsrchr(wchar_t* s, wchar_t c);
size_t   wcsspn(wchar_t*s1, wchar_t*s2);
wchar_t* wcsstr(wchar_t*s1, wchar_t*s2);
wchar_t* wcstok(wchar_t* s1, wchar_t* s2, wchar_t** ptr);
size_t   wcslen(wchar_t* s);

alias int mbstate_t;

wint_t btowc(int c);
int    wctob(wint_t c);
int    mbsinit(mbstate_t*ps);
size_t mbrlen(char* s, size_t n, mbstate_t* ps);
size_t mbrtowc(wchar_t* pwc, char* s, size_t n, mbstate_t* ps);
size_t wcrtomb(char* s, wchar_t wc, mbstate_t* ps);
size_t mbsrtowcs(wchar_t* dst, char** src, size_t len, mbstate_t* ps);
size_t wcsrtombs(char* dst, wchar_t** src, size_t len, mbstate_t* ps);
