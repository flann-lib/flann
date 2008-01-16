/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.text.locale.Win32;

alias tango.text.locale.Win32 nativeMethods;

extern (Windows)
private {
  void GetSystemTimeAsFileTime(out ulong lpSystemTimeAsFileTime);
  uint GetUserDefaultLCID();
  uint GetThreadLocale();
  bool SetThreadLocale(uint Locale);
  int MultiByteToWideChar(uint CodePage, uint dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);
  int CompareStringW(uint Locale, uint dwCmpFlags, wchar* lpString1, int cchCount1, wchar* lpString2, int cchCount2);

}

int getUserCulture() {
  return GetUserDefaultLCID();
}

void setUserCulture(int lcid) {
  SetThreadLocale(lcid);
}

ulong getUtcTime() {
  ulong ticks;
  GetSystemTimeAsFileTime(ticks);
  return ticks;
}

int compareString(int lcid, char[] stringA, uint offsetA, uint lengthA, char[] stringB, uint offsetB, uint lengthB, bool ignoreCase) {

  wchar[] toUnicode(char[] string, uint offset, uint length, out int translated) {
    char* chars = string.ptr + offset;
    int required = MultiByteToWideChar(0, 0, chars, length, null, 0);
    wchar[] result = new wchar[required];
    translated = MultiByteToWideChar(0, 0, chars, length, result.ptr, required);
    return result;
  }

  int sortId = (lcid >> 16) & 0xF;
  sortId = (sortId == 0) ? lcid : (lcid | (sortId << 16));

  int len1, len2;
  wchar[] string1 = toUnicode(stringA, offsetA, lengthA, len1);
  wchar[] string2 = toUnicode(stringB, offsetB, lengthB, len2);

  return CompareStringW(sortId, ignoreCase ? 0x1 : 0x0, string1.ptr, len1, string2.ptr, len2) - 2;
}
