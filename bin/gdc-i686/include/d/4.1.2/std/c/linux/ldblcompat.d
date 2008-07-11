/* In C, the stdio/stdlib function to use are determined by a test in cdefs.h.
   Not exactly sure how math funcs are handled.   */

module std.c.linux.ldblcompat;

version (GNU_WantLongDoubleFormat128)
    version = GNU_UseLongDoubleFormat128;
else version (GNU_WantLongDoubleFormat64)
    { }
else
{
    version (GNU_LongDouble128)
	version = GNU_UseLongDoubleFormat128;
}

version (GNU_UseLongDoubleFormat128)
{
    static const bool __No_Long_Double_Math = false;
    const char[] __LDBL_COMPAT_PFX = "";
}
else
{
    static const bool __No_Long_Double_Math = true;
    const char[] __LDBL_COMPAT_PFX = "__nldbl_";
}
