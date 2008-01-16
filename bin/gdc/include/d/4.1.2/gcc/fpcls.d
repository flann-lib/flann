module gcc.fpcls;
import gcc.config.config;

// Implementation may be internal/ieee_fpcls.d or gcc/cbridge_math.c

static if (Use_IEEE_fpsb)
{
    // This must be kept in sync with internal/ieee_fpcls.d
    enum
    {
	FP_NAN = 1,
	FP_INFINITE,
	FP_ZERO,
	FP_SUBNORMAL,
	FP_NORMAL,
    }
}
else
    public import gcc.config.fpcls;
	
int signbit(float f);
int signbit(double f);
int signbit(real f);

int fpclassify(float f);
int fpclassify(double f);
int fpclassify(real f);
