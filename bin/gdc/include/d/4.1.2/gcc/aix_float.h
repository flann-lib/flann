/* Can't #include <float.h> because it will pick up the one
   set up by GCC rather than the one in /usr/include.  Hopefully,
   these won't change. */
#ifndef FP_PLUS_NORM
#define FP_PLUS_NORM      0
#define FP_MINUS_NORM     1
#define FP_PLUS_ZERO      2
#define FP_MINUS_ZERO     3
#define FP_PLUS_INF       4
#define FP_MINUS_INF      5
#define FP_PLUS_DENORM    6
#define FP_MINUS_DENORM   7
#define FP_SNAN           8
#define FP_QNAN           9
#endif
