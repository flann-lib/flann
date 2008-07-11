/* In C, the stdio/stdlib function to use are determined by a test in cdefs.h.
   There is another test for math functions in architecture/ppc/math.h which
   is reproduced, in spirit, here.  This one test controls both stdio/stdlib and
   math functions for D. */

module std.c.darwin.ldblcompat;

version (PPC)
{
    version (GNU_WantLongDoubleFormat128)
	version = GNU_UseLongDoubleFormat128;
    else version (GNU_WantLongDoubleFormat64)
	{ }
    else
    {
	version (GNU_LongDouble128)
	    version = GNU_UseLongDoubleFormat128;
    }
}

version (GNU_UseLongDoubleFormat128)
{
    // Currently, the following test from cdefs.h is not supported:
    //# if __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__-0 < 1040
    version (all)
	const string __DARWIN_LDBL_COMPAT  = "$LDBL128";
    else
	const string __DARWIN_LDBL_COMPAT  = "$LDBLStub";
    const string __DARWIN_LDBL_COMPAT2 = "$LDBL128";
    
    const string __LIBMLDBL_COMPAT = "$LDBL128";
}
else
{
    const string __DARWIN_LDBL_COMPAT  = "";
    const string __DARWIN_LDBL_COMPAT2 = "";
    
    const string __LIBMLDBL_COMPAT = "";
}
