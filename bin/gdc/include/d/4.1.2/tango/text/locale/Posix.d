/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.text.locale.Posix;

version (Posix)
{
alias tango.text.locale.Posix nativeMethods;

private import tango.core.Exception;
private import tango.text.locale.Data;
private import tango.stdc.ctype;
private import tango.stdc.posix.stdlib;
private import tango.stdc.string;
private import tango.stdc.time;
private import tango.stdc.locale;
private import tango.stdc.posix.time;

/*private extern(C) char* setlocale(int type, char* locale);
private extern(C) void putenv(char*);

private enum {LC_CTYPE, LC_NUMERIC, LC_TIME, LC_COLLATE, LC_MONETARY, LC_MESSAGES, LC_ALL, LC_PAPER, LC_NAME, LC_ADDRESS, LC_TELEPHONE, LC_MEASUREMENT, LC_IDENTIFICATION};*/

int getUserCulture() {
  char* env = getenv("LC_ALL");
  if (!env || *env == '\0') {
    env = getenv("LANG");
    if (!env || *env == '\0')
      throw new LocaleException("Neither LANG nor LC_ALL were found to be set. Please set for locale formatting to function.");
  }

  // getenv returns a string of the form <language>_<region>.
  // Therefore we need to replace underscores with hyphens.
  char* p = env;
  int len;
  while (*p) {
    if (*p == '.'){
      break;
    }
    if (*p == '_'){
      *p = '-';
    }
    p++;
    len++;
  }

  char[] s = env[0 .. len];
  foreach (entry; CultureData.cultureDataTable) {
    // todo: there is also a local compareString defined. Is it correct that here 
    // we use tango.text.locale.Data, which matches the signature?
    if (tango.text.locale.Data.compareString(entry.name, s) == 0)
	// todo: here was entry.id returned, which does not exist. Is lcid correct?
      return entry.lcid;
  }
  return 0;
}

void setUserCulture(int lcid) {
  char[] name;
  try {
    name = CultureData.getDataFromCultureID(lcid).name ~ ".utf-8";
  }
  catch(Exception e) {
    return;
  }
  
  for(int i = 0; i < name.length; i++) {
    if(name[i] == '.') break;
    if(name[i] == '-') name[i] = '_';
  }
  
  putenv(("LANG=" ~ name).ptr);
  setlocale(LC_CTYPE, name.ptr);
  setlocale(LC_NUMERIC, name.ptr);
  setlocale(LC_TIME, name.ptr);
  setlocale(LC_COLLATE, name.ptr);
  setlocale(LC_MONETARY, name.ptr);

  version (GNU) {} else {
/*      setlocale(LC_MESSAGES, name.ptr); */
  }

  setlocale(LC_PAPER, name.ptr);
  setlocale(LC_NAME, name.ptr);
  setlocale(LC_ADDRESS, name.ptr);
  setlocale(LC_TELEPHONE, name.ptr);
  setlocale(LC_MEASUREMENT, name.ptr);
  setlocale(LC_IDENTIFICATION, name.ptr);
}

ulong getUtcTime() {
   int t;
   time(&t);
   gmtime(&t);
   return cast(ulong)((cast(long)t * 10000000L) + 116444736000000000L);
}

int compareString(int lcid, char[] stringA, uint offsetA, uint lengthA, char[] stringB, uint offsetB, uint lengthB, bool ignoreCase) {

  void strToLower(char[] string) {
    for(int i = 0; i < string.length; i++) {
      string[i] = cast(char)(tolower(cast(int)string[i]));
    }
  }

  char* tempCol = setlocale(LC_COLLATE, null), tempCType = setlocale(LC_CTYPE, null);
  char[] locale;
  try {
    locale = CultureData.getDataFromCultureID(lcid).name ~ ".utf-8";
  }
  catch(Exception e) {
    return 0;
  }
  
  setlocale(LC_COLLATE, locale.ptr);
  setlocale(LC_CTYPE, locale.ptr);
  
  char[] s1 = stringA[offsetA..offsetA+lengthA].dup,
         s2 = stringB[offsetB..offsetB+lengthB].dup;
  if(ignoreCase) {
    strToLower(s1);
    strToLower(s2);
  }
  
  int ret = strcoll(s1[offsetA..offsetA+lengthA].ptr, s2[offsetB..offsetB+lengthB].ptr);
  
  setlocale(LC_COLLATE, tempCol);
  setlocale(LC_CTYPE, tempCType);
  
  return ret;
}

debug(UnitTest)
{
    unittest
    {
        int c = getUserCulture();
        assert(compareString(c, "Alphabet", 0, 8, "Alphabet", 0, 8, false) == 0);
        assert(compareString(c, "Alphabet", 0, 8, "alphabet", 0, 8, true) == 0);
        assert(compareString(c, "Alphabet", 0, 8, "alphabet", 0, 8, false) != 0);
        assert(compareString(c, "lphabet", 0, 7, "alphabet", 0, 8, true) != 0);
        assert(compareString(c, "Alphabet", 0, 8, "lphabet", 0, 7, true) != 0);
    }
}
}
