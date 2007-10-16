/**
 * Oracle import library.
 *
 * Part of the D DBI project.
 *
 * Version:
 *	Oracle 10g revision 2
 *
 *	Import library version 0.04
 *
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.oracle.imp.orl;

private import dbi.oracle.imp.oci, dbi.oracle.imp.oratypes, dbi.oracle.imp.oro, dbi.oracle.imp.ort;

const uint OCI_NUMBER_SIZE		= 22;		/// The number of bytes in an OCINumber.

/**
 * OCI Number mapping in C.
 *
 * The OTS types: NUMBER, NUMERIC, INT, SHORTINT, REAL, DOUBLE PRECISION,
 * FLOAT and DECIMAL are represented by OCINumber.
 *
 * The contents of OCINumber is opaque to clients.
 *
 * For binding variables of type OCINumber in OCI calls (OCIBindByName(),
 * OCIBindByPos(), and OCIDefineByPos()) use the type code SQLT_VNU.
 */
struct OCINumber {
	ub1[OCI_NUMBER_SIZE] OCINumberPart;
}

/**
 * Increment a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the positive OCI _number to increment.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberInc (OCIError* err, OCINumber* number);

/**
 * Decrement a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the positive OCI _number to decrement.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberDec (OCIError* err, OCINumber* number);

/**
 * Set a _number to 0.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to set to 0.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) void OCINumberSetZero (OCIError* err, OCINumber* num);

/**
 * Set a _number to pi.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to set to pi.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) void OCINumberSetPi (OCIError *err, OCINumber *num);

/**
 * Add one number to another.
 *
 * Params:
 *	err = OCI error handle.
 *	number1 = A pointer to the OCI number of the first operand.
 *	number2 = A pointer to the OCI number of the second operand.
 *	result = A pointer to the OCI number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberAdd (OCIError* err, OCINumber* number1, OCINumber* number2, OCINumber* result);

/**
 * Subtract one number from another.
 *
 * Params:
 *	err = OCI error handle.
 *	number1 = A pointer to the OCI number of the first operand.
 *	number2 = A pointer to the OCI number of the second operand.
 *	result = A pointer to the OCI number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberSub (OCIError* err, OCINumber* number1, OCINumber* number2, OCINumber* result);

/**
 * Multiply one number by another.
 *
 * Params:
 *	err = OCI error handle.
 *	number1 = A pointer to the OCI number of the first operand.
 *	number2 = A pointer to the OCI number of the second operand.
 *	result = A pointer to the OCI number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberMul (OCIError* err, OCINumber* number1, OCINumber* number2, OCINumber* result);

/**
 * Divide one number by another.
 *
 * Params:
 *	err = OCI error handle.
 *	number1 = A pointer to the OCI number of the first operand.
 *	number2 = A pointer to the OCI number of the second operand.
 *	result = A pointer to the OCI number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberDiv (OCIError* err, OCINumber* number1, OCINumber* number2, OCINumber* result);

/**
 * The remainder when one number is divided by another.
 *
 * Params:
 *	err = OCI error handle.
 *	number1 = A pointer to the OCI number of the first operand.
 *	number2 = A pointer to the OCI number of the second operand.
 *	result = A pointer to the OCI number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberMod (OCIError* err, OCINumber* number1, OCINumber* number2, OCINumber* result);

/**
 * Raise a number to an integral power.
 *
 * Params:
 *	err = OCI error handle.
 *	base = A pointer to the OCI number of the first operand.
 *	exp = The second operand.
 *	result = A pointer to the OCI number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberIntPower (OCIError* err, OCINumber* base, sword exp, OCINumber* result);

/**
 * Multiply a _number by a power of 10.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number of the first operand.
 *	nDig = The number of repetitions.
 *	result = A pointer to the OCI number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberShift (OCIError* err, OCINumber* number, sword nDig, OCINumber* result);

/**
 * Negate a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to negate.
 *	result = A pointer to the OCI number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberNeg (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Convert a _number to a string.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to convert.
 *	fmt = The conversion format.
 *	fmt_length = The length of fmt.
 *	nls_params = The NLS format specification.  Use 0 for default.
 *	nls_p_length = The length of nls_params.
 *	buf_size = The size of the buffer, used as both input and output.
 *	buf = A buffer to place the result of the conversion in.
 *
 * See_Also:
 *	Refer to the Oracle SQL Language Reference Manual for more details on fmt and nls_params.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberToText (OCIError* err, OCINumber* number, oratext* fmt, ub4 fmt_length, oratext* nls_params, ub4 nls_p_length, ub4* buf_size, oratext* buf);

/**
 * Convert a string to a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	str = The string to convert.
 *	str_length = The length of str.
 *	fmt = The conversion format.
 *	fmt_length = The length of fmt.
 *	nls_params = The NLS format specification.  Use 0 for default.
 *	nls_p_length = The length of nls_params.
 *	number = A pointer to the OCI _number to put the _result in.
 *
 * See_Also:
 *	Refer to the Oracle SQL Language Reference Manual for more details on fmt and nls_params.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberFromText (OCIError* err, oratext* str, ub4 str_length, oratext* fmt, ub4 fmt_length, oratext* nls_params, ub4 nls_p_length, OCINumber* number);

const uint OCI_NUMBER_UNSIGNED		= 0;		/// Unsigned type -- ubX.
const uint OCI_NUMBER_SIGNED		= 2;		/// Signed type -- sbX.

/**
 * Convert a _number to an integer.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to convert.
 *	rsl_length = The number of bytes in rsl.
 *	rsl_s_flag = Either OCI_NUMBER_UNSIGNED or OCI_NUMBER_SIGNED.
 *	rsl = A pointer to space for the result.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberToInt (OCIError* err, OCINumber* number, uword rsl_length, uword rsl_flag, dvoid* rsl);

/**
 * Convert an integer to a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	inum = A pointer to the integer to convert.
 *	inum_length = The number of bytes in inum.
 *	inum_s_flag = Either OCI_NUMBER_UNSIGNED or OCI_NUMBER_SIGNED.
 *	number = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberFromInt (OCIError* err, dvoid* inum, uword inum_length, uword inum_s_flag, OCINumber* number);

/**
 * Convert a _number to a real.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to convert.
 *	rsl_length = The number of bytes in the result.
 *	rsl = A pointer to space for the result.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberToReal (OCIError* err, OCINumber* number, uword rsl_length, dvoid* rsl);

/**
 * Convert an array of _number to an array of reals.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the array of OCI numbers to convert.
 *	elems = The number of OCI numbers to convert.
 *	rsl_length = The number of bytes in the result.
 *	rsl = A pointer to space for the result.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberToRealArray (OCIError* err, OCINumber** number, uword elems, uword rsl_length, dvoid* rsl);

/**
 * Convert a real to a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	rnum = A pointer to the real to convert.
 *	rnum_length = The number of bytes in the rnum.
 *	number = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberFromReal (OCIError* err, dvoid* rnum, uword rnum_length, OCINumber* number);

/**
 * Compare two numbers.
 *
 * Params:
 *	err = OCI error handle.
 *	number1 = A pointer to the first OCI number.
 *	number2 = A pointer to the second OCI number.
 *	result = The _result.  0 if equal, negative if less than, or positive if greater than.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberCmp (OCIError* err, OCINumber* number1, OCINumber* number2, sword* result);

/**
 * Get the sign of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to check.
 *	result = The _result.  0 if 0, -1 if negative, or 1 if positive.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberSign (OCIError* err, OCINumber* number, sword* result);

/**
 * Check if a _number is 0.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to check.
 *	result = TRUE if it is or FALSE otherwise.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberIsZero (OCIError* err, OCINumber* number, boolean* result);

/**
 * Check if a _number is an integer.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to check.
 *	result = TRUE if it is or FALSE otherwise.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberIsInt (OCIError* err, OCINumber* number, boolean* result);

/**
 * Copy a number.
 *
 * Params:
 *	err = OCI error handle.
 *	from = A pointer _to the source OCI number.
 *	to = A pointer _to the target OCI number.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberAssign (OCIError* err, OCINumber* from, OCINumber* to);

/**
 * Get the absolute value of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the absolute value of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberAbs (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Round a _number up.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to round.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberCeil (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Round a _number down.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to round.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberFloor (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the square root of a _number..
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to square root.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberSqrt (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Truncate a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to truncate
 *	decplace = The _number of digits to the right of the decimal to keep.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberTrunc (OCIError* err, OCINumber* number, sword decplace, OCINumber* result);

/**
 * Raise a _number to a power.
 *
 * Params:
 *	err = OCI error handle.
 *	base = A pointer to the OCI _number to raise to number.
 *	number = A pointer to the OCI _number of the exponent.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberPower (OCIError* err, OCINumber* base, OCINumber* number, OCINumber* result);

/**
 * Round a _number to a specified decimal place.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to round.
 *	decplace = The _number of digits to the right of the decimal to keep.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberRound (OCIError* err, OCINumber* number, sword decplace, OCINumber* result);

/**
 * Round a _number to a specified decimal place.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to round.
 *	decplace = The _number of digits to keep.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberPrec (OCIError* err, OCINumber* number, eword nDigs, OCINumber* result);

/**
 * Take the sine of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the sine of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberSin (OCIError *err, OCINumber* number, OCINumber* result);

/**
 * Take the inverse sine of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the inverse sine of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberArcSin (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the hyperbolic sine of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the hyperbolic sine of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberHypSin (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the cosine of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the cosine of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberCos (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the inverse cosine of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the inverse cosine of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberArcCos (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the hyperbolic cosine of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the hyperbolic cosine of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberHypCos (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the tangent of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the tangent of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberTan (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the inverse tangent of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the inverse tangent of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberArcTan (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the inverse tangent of a number.
 *
 * Params:
 *	err = OCI error handle.
 *	number1 = A pointer to the OCI number of the numerator.
 *	number2 = A pointer to the OCI number of the denominator.
 *	result = A pointer to the OCI number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberArcTan2 (OCIError* err, OCINumber* number1, OCINumber* number2, OCINumber* result);

/**
 * Take the hyperbolic tangent of a _number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the hyperbolic tangent of.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberHypTan (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Raise e to a power.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number of the exponent.
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberExp (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the natural logarithm of a number.
 *
 * Params:
 *	err = OCI error handle.
 *	number = A pointer to the OCI _number to take the natural logarithm of..
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberLn (OCIError* err, OCINumber* number, OCINumber* result);

/**
 * Take the logarithm of a number in any base.
 *
 * Params:
 *	err = OCI error handle.
 *	base = A pointer to the OCI _number representing the base.
 *	number = A pointer to the OCI _number to take the logarithm of..
 *	result = A pointer to the OCI _number to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCINumberLog (OCIError* err, OCINumber* base, OCINumber* number, OCINumber* result);

/**
 * OCI time portion of date.
 *
 * This structure should be treated as an opaque structure as the format
 * of this structure may change. Use OCIDateGetTime/OCIDateSetTime
 * to manipulate time portion of OCIDate.
 */
struct OCITime {
	ub1 OCITimeHH;					/// Hours; range is 0 <= hours <= 23.
	ub1 OCITimeMI;					/// Minutes; range is 0 <= minutes <= 59.
	ub1 OCITimeSS;					/// Seconds; range is 0 <= seconds <= 59.
}

/**
 * OCI date representation.
 *
 * This structure should be treated as an opaque structure as the format
 * of this structure may change. Use OCIDateGetDate/OCIDateSetDate
 * to access/initialize OCIDate.
 *
 * For binding variables of type OCIDate in OCI calls (OCIBindByName(),
 * OCIBindByPos(), and OCIDefineByPos()) use the type code SQLT_ODT.
 */
struct OCIDate {
	sb2 OCIDateYYYY;				/// Gregorian year; range is -4712 <= year <= 9999.
	ub1 OCIDateMM;					/// Month; range is 1 <= month <= 12.
	ub1 OCIDateDD;					/// Day; range is 1 <= day <= 31.
	OCITime OCIDateTime;				/// Time.
}

/**
 * Get the time portion of a _date.
 *
 * Params:
 *	date = A pointer to the OCI _date to get the time from.
 *	hour = The _hour portion of date.
 *	min = The minute portion of date.
 *	sec = The second portion of date.
 */
void OCIDateGetTime (OCIDate* date, ub1* hour, ub1* min, ub1* sec) {
	*hour = date.OCIDateTime.OCITimeHH;
	*min = date.OCIDateTime.OCITimeMI;
	*sec = date.OCIDateTime.OCITimeSS;
}

/**
 * Get the _date portion of a _date.
 *
 * Params:
 *	date = A pointer to the OCI _date to get the time from.
 *	year = The _year portion of date.
 *	month = The _month portion of date.
 *	day = The _day portion of date.
 */
void OCIDateGetDate (OCIDate* date, sb2* year, ub1* month, ub1* day) {
	*year = date.OCIDateYYYY;
	*month = date.OCIDateMM;
	*day = date.OCIDateDD;
}

/**
 * Set the time portion of a _date.
 *
 * Params:
 *	date = A pointer to the OCI _date to set the time of.
 *	hour = The _hour portion of date.
 *	min = The minute portion of date.
 *	sec = The second portion of date.
 */
void OCIDateSetTime (OCIDate* date, ub1 hour, ub1 min, ub1 sec) {
	date.OCIDateTime.OCITimeHH = hour;
	date.OCIDateTime.OCITimeMI = min;
	date.OCIDateTime.OCITimeSS = sec;
}

/**
 * Set the _date portion of a _date.
 *
 * Params:
 *	date = A pointer to the OCI _date to set the time of.
 *	year = The _year portion of date.
 *	month = The _month portion of date.
 *	day = The _day portion of date.
 */
void OCIDateSetDate (OCIDate* date, sb2 year, ub1 month, ub1 day) {
	date.OCIDateYYYY = year;
	date.OCIDateMM = month;
	date.OCIDateDD = day;
}

/**
 * Copy a date.
 *
 * Params:
 *	err = OCI error handle.
 *	from = A pointer _to the source OCI date.
 *	to = A pointer _to the target OCI date.
 *
 * Returns:
 *	OCI_SUCCESS.
 */
extern (C) sword OCIDateAssign (OCIError* err, OCIDate* from, OCIDate* to);

/**
 * Convert a _date to a string.
 *
 * Params:
 *	err = OCI error handle.
 *	date = A pointer to the OCI _date to convert.
 *	fmt = The conversion format.  Defaults to "DD-Mon-YY."
 *	fmt_length = The length of fmt.
 *	lang_name = The language to use for names.  Defaults to the session language.
 *	lang_length = The length of lang_name
 *	buf_size = The size of the buffer, used as both input and output.
 *	buf = A buffer to place the result of the conversion in.
 *
 * See_Also:
 *	Refer to the Oracle SQL Language Reference Manual for more details on fmt and nls_params.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateToText (OCIError* err, OCIDate* date, oratext* fmt, ub1 fmt_length, oratext* lang_name, ub4 lang_length, ub4* buf_size, oratext* buf);

/**
 * Convert a string to a _date.
 *
 * Params:
 *	err = OCI error handle.
 *	date_str = The string to convert.
 *	d_str_length = The length of str.
 *	fmt = The conversion format.  Defaults to "DD-Mon-YY."
 *	fmt_length = The length of fmt.
 *	lang_name = The language to use for names.  Defaults to the session language.
 *	lang_length = The length of lang_name
 *	date = A pointer to the OCI _date to place the result of the conversion in.
 *
 * See_Also:
 *	Refer to the Oracle SQL Language Reference Manual for more details on fmt and nls_params.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateFromText (OCIError* err, oratext* date_str, ub4 d_str_length, oratext* fmt, ub1 fmt_length, oratext* lang_name, ub4 lang_length, OCIDate* date);

/**
 * Compare two dates.
 *
 * Params:
 *	err = OCI error handle.
 *	date1 = A pointer to the first OCI date.
 *	date2 = A pointer to the second OCI date.
 *	result = The _result.  0 if equal, -1 if less than, or 1 if greater than.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateCompare (OCIError* err, OCIDate* date1, OCIDate* date2, sword* result);

/**
 * Add months to a _date.
 *
 * Params:
 *	err = OCI error handle.
 *	date = A pointer to the OCI date to add to.
 *	num_months = The number of months to move.
 *	result = A pointer to the OCI _date to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateAddMonths (OCIError* err, OCIDate* date, sb4 num_months, OCIDate* result);

/**
 * Add days to a _date.
 *
 * Params:
 *	err = OCI error handle.
 *	date = A pointer to the OCI date to add to.
 *	num_days = The number of days to move.
 *	result = A pointer to the OCI _date to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateAddDays (OCIError* err, OCIDate* date, sb4 num_days, OCIDate* result);

/**
 * Get the last day of the current month of a _date.
 *
 * Params:
 *	err = OCI error handle.
 *	date = A pointer to the OCI date to use.
 *	last_day = A pointer to the OCI _date to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateLastDay (OCIError* err, OCIDate* date, OCIDate* last_day);

/**
 * Get the number of days between two dates.
 *
 * Params:
 *	err = OCI error handle.
 *	date1 = A pointer to the first OCI date.
 *	date2 = A pointer to the second OCI date.
 *	num_days = The number of days between date1 and date2.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateDaysBetween (OCIError* err, OCIDate* date1, OCIDate* date2, sb4* num_days);

/**
 * Change a date from one time zone to another.
 *
 * Params:
 *	err = OCI error handle.
 *	date1 = A pointer to the OCI date in time zone zon1.
 *	zon1 = The time zone of date1.
 *	zon1_length = The length of zon1.
 *	zon2 = The time zone of date2.
 *	zon2_length = The length of zon2.
 *	date2 = A pointer to the OCI _date to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateZoneToZone (OCIError* err, OCIDate* date1, oratext* zon1, ub4 zon1_length, oratext* zon2, ub4 zon2_length, OCIDate* date2);

/**
 * Find the next occurance of a _day after a certain _date.
 *
 * Params:
 *	err = OCI error handle.
 *	date = A pointer to the OCI _date to start at.
 *	day_p = The day to go to.
 *	day_length = The length of day_p.
 *	next_day = A pointer to the OCI _date to put the _result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateNextDay (OCIError* err, OCIDate* date, oratext* day_p, ub4 day_length, OCIDate* next_day);

const uint OCI_DATE_INVALID_DAY		= 0x1;		/// Bad day.
const uint OCI_DATE_DAY_BELOW_VALID	= 0x2;		/// Bad day low/high bit (1=low).
const uint OCI_DATE_INVALID_MONTH	= 0x4;		/// Bad month.
const uint OCI_DATE_MONTH_BELOW_VALID	= 0x8;		/// Bad month low/high bit (1=low).
const uint OCI_DATE_INVALID_YEAR	= 0x10;		/// Bad year.
const uint OCI_DATE_YEAR_BELOW_VALID	= 0x20;		/// Bad year low/high bit (1=low).
const uint OCI_DATE_INVALID_HOUR	= 0x40;		/// Bad hour.
const uint OCI_DATE_HOUR_BELOW_VALID	= 0x80;		/// Bad hour low/high bit (1=low).
const uint OCI_DATE_INVALID_MINUTE	= 0x100;	/// Bad minute.
const uint OCI_DATE_MINUTE_BELOW_VALID	= 0x200;	/// Bad minute low/high bit (1=low).
const uint OCI_DATE_INVALID_SECOND	= 0x400;	/// Bad second.
const uint OCI_DATE_SECOND_BELOW_VALID	= 0x800;	/// Bad second low/high bit (1=low).
const uint OCI_DATE_DAY_MISSING_FROM_1582 = 0x1000;	/// Day is one of those "missing" from 1582.
const uint OCI_DATE_YEAR_ZERO		= 0x2000;	/// Year may not equal zero.
const uint OCI_DATE_INVALID_FORMAT	= 0x8000;	/// Bad date format input.

/**
 * Check if a _date is _valid.
 *
 * Params:
 *	err = OCI error handle.
 *	date = A pointer to the OCI _date to check.
 *	valid = An ORed combination of error bits.  The names start with OCI_DATE_.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateCheck (OCIError* err, OCIDate* date, uword* valid);

/**
 * Get the current system _date.
 *
 * Params:
 *	err = OCI error handle.
 *	sys_date = A pointer to the OCI _date to put the result in.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIDateSysDate (OCIError* err, OCIDate* sys_date);

/**
 * The variable-length string is represented in C as a pointer to OCIString
 * structure. The OCIString structure is opaque to the user. Functions are
 * provided to allow the user to manipulate a variable-length string.
 *
 * A variable-length string can be declared as:
 *
 * OCIString* vstr;
 *
 * For binding variables of type OCIString* in OCI calls (OCIBindByName(),
 * OCIBindByPos() and OCIDefineByPos()) use the external type code SQLT_VST.
 *
 * Warning:
 *	OCIString is implicitly null terminated.
 */
struct OCIString {
}

/**
 * Copy a string.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	rhs = A pointer to the source OCI string.
 *	lhs = A pointer to a pointer to the target OCI string.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIStringAssign (OCIEnv* env, OCIError* err, OCIString* rhs, OCIString** lhs);

/**
 * Assign a C string to a string.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	rhs = A pointer to the source string.
 *	rhs_length = The length of rhs.
 *	lhs = A pointer to a pointer to the target OCI string.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIStringAssignText (OCIEnv* env, OCIError* err, oratext* rhs, ub4 rhs_len, OCIString** lhs);

/**
 * Resize a string.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	new_size = The length to make str.
 *	str = A pointer to a pointer to the OCI string.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIStringResize (OCIEnv* env, OCIError* err, ub4 new_size, OCIString** str);

/**
 * Get the size of a string.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	vs = A pointer to the OCI string to check.
 *
 * Returns:
 *	The length of vs in bytes.
 */
extern (C) ub4 OCIStringSize (OCIEnv* env, OCIString* vs);

/**
 * Get a string in C string format.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	vs = A pointer to the OCI string to convert.
 *
 * Returns:
 *	vs as a C string.
 */
extern (C) oratext* OCIStringPtr (OCIEnv* env, OCIString* vs);

/**
 * Get the allocated size of a string.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	vs = A pointer to the OCI string to check.
 *	allocsize = The allocated size of vs.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIStringAllocSize (OCIEnv* env, OCIError* err, OCIString* vs, ub4* allocsize);

/**
 * The variable-length raw is represented in C as a pointer to OCIRaw
 * structure. The OCIRaw structure is opaque to the user. Functions are
 * provided to allow the user to manipulate a variable-length raw.
 *
 * A variable-length raw can be declared as:
 *
 * OCIRaw* raw;
 *
 * For binding variables of type OCIRaw* in OCI calls (OCIBindByName(),
 * OCIBindByPos() and OCIDefineByPos()) use the external type code SQLT_LVB.
 */
struct OCIRaw {
}

/**
 * Copy a variable-length raw.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	rhs = A pointer to the source OCI variable-length raw.
 *	lhs = A pointer to a pointer to the target OCI variable-length raw.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIRawAssignRaw (OCIEnv* env, OCIError* err, OCIRaw* rhs, OCIRaw** lhs);

/**
 * Assign bytes to a variable-length raw.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	rhs = A pointer to the source bytes.
 *	rhs_len = The length of rhs.
 *	lhs = A pointer to a pointer to the target OCI variable-length raw.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIRawAssignBytes (OCIEnv* env, OCIError* err, ub1* rhs, ub4 rhs_len, OCIRaw** lhs);

/**
 * Resize a variable-length _raw.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	new_size = The size to make raw.
 *	raw = A pointer to a pointer to the OCI variable-length _raw to resize.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIRawResize (OCIEnv *env, OCIError* err, ub4 new_size, OCIRaw** raw);

/**
 * Get the size of a variable-length _raw.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	raw = A pointer to the OCI variable-length _raw to check.
 *
 * Returns:
 *	The number of bytes in raw.
 */
extern (C) ub4 OCIRawSize (OCIEnv* env, OCIRaw* raw);

/**
 * Return a variable-length _raw as an array of bytes.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	raw = A pointer to the OCI variable-length _raw to return.
 *
 * Returns:
 *	raw as an array of bytes.
 */
extern (C) ub1* OCIRawPtr (OCIEnv* env, OCIRaw* raw);

/**
 * Get the allocated size of a variable-length _raw.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	raw = A pointer to the OCI variable-length _raw to check.
 *	allocsize = The allocated size of raw
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIRawAllocSize (OCIEnv* env, OCIError* err, OCIRaw* raw, ub4* allocsize);

/**
 * Clear an object reference.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	ref = A pointer to the OCI object reference to clear.
 */
extern (C) void OCIRefClear (OCIEnv* env, OCIRef* ref);

/**
 * Copy an object reference.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	source = A pointer to the _source OCI object reference.
 *	target = A pointer to a pointer to the _target OCI object reference.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIRefAssign (OCIEnv* env, OCIError* err, OCIRef* source, OCIRef** target);

/**
 * Test two object references for equality.
 *
 * Two null object references are not considered equal.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	x = A pointer to the first OCI object reference to test.
 *	y = A pointer to the second OCI object reference to test.
 *
 * Returns:
 *	TRUE if they are equal or FALSE otherwise.
 */
extern (C) boolean OCIRefIsEqual (OCIEnv* env, OCIRef* x, OCIRef* y);

/**
 * Test if an object reference is null.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	ref = A pointer to the OCI object reference to test.
 *
 * Returns:
 *	TRUE if it is null or false otherwise.
 */
extern (C) boolean OCIRefIsNull (OCIEnv* env, OCIRef* ref);

/**
 * Get the size of an object reference.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	ref = A pointer to the OCI object reference to test.
 *
 * Returns:
 *	The size of ref.
 */
extern (C) ub4 OCIRefHexSize (OCIEnv* env, OCIRef* ref);

/**
 * Convert a hexadecimal string to an object reference.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	svc = OCI service context handle.
 *	hex = The source hexadecimal string.
 *	hex_length = The length of hex.
 *	ref = A pointer to a pointer to the resulting OCI object reference.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIRefFromHex (OCIEnv* env, OCIError* err, OCISvcCtx* svc, oratext* hex, ub4 length, OCIRef** ref);

/**
 * Convert an object reference into a hexadecimal string.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	ref = A pointer to the source OCI object reference.
 *	hex = A pointer to the resulting hexadecimal string.
 *	hex_length = The length of hex.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIRefToHex (OCIEnv* env, OCIError* err, OCIRef* ref, oratext* hex, ub4* hex_length);

/**
 * Generic collection type.
 */
struct OCIColl {
}

/**
 * Varray collection type.
 */
alias OCIColl OCIArray;

/**
 * Nested table collection type.
 */
alias OCIColl OCITable;

/**
 * Collection iterator.
 */
struct OCIIter {
}

/**
 * Get the size of a collection.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	coll = A pointer to the OCI collection to check.
 *	size = The current number of elements in coll.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCICollSize (OCIEnv* env, OCIError* err, OCIColl* coll, sb4* size);

/**
 * Get the maximum size of a collection.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	coll = A pointer to the OCI collection to check.
 *
 * Returns:
 *	The maximum size of coll if there is one or 0 if there isn't.
 */
extern (C) sb4 OCICollMax (OCIEnv* env, OCIColl* coll);

/**
 * Get the pointer to an element of a collection by _index.
 *
 * Optionally, you can get the address of the element's null indictator.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	coll = A pointer to the OCI collection to retrieve the pointer from.
 *	index = The _index of the element to return the pointer of.
 *	exists = FALSE if there is nothing at index or TRUE if there is.
 *	elem = The pointer to the element at index.  The type is a pointer to the desired type.
 *	elemind = The address of the null indicator for elem unless null is passed.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCICollGetElem (OCIEnv* env, OCIError* err, OCIColl* coll, sb4 index, boolean* exists, dvoid** elem, dvoid** elemind);

/**
 * Get the pointer to an array of elements of a collection by _index.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	coll = A pointer to the OCI collection to retrieve the pointer from.
 *	index = The _index of the first element to return the pointer of.
 *	exists = FALSE if there is nothing at index or TRUE if there is.
 *	elem = The pointer to the element at index.  The type is a pointer to the desired type.
 *	elemind = The address of the null indicator for elem unless null is passed.
 *	nelems = The number of elements to retrieve.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCICollGetElemArray (OCIEnv* env, OCIError* err, OCIColl* coll, sb4 index, boolean* exists, dvoid** elem, dvoid** elemind, uword* nelems);

/**
 * Assign an element to a collection.
 *
 * elem is assigned to coll[index] with a null indictator of elemind.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	index = The _index of the element to to change.
 *	elem = A pointer to the source OCI element.
 *	elemind = The null indicator for elem unless null is passed.
 *	coll = A pointer to the target OCI collection.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCICollAssignElem (OCIEnv* env, OCIError* err, sb4 index, dvoid* elem, dvoid* elemind, OCIColl* coll);

/**
 * Copy a collection.
 *
 * lhs and rhs must be the same type of collection.  rhs must have at least as many
 * elements as rhs.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	rhs = A pointer to the source OCI collection.
 *	lhs = A pointer to the target OCI collection.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCICollAssign (OCIEnv* env, OCIError* err, OCIColl* rhs, OCIColl* lhs);

/**
 * Append an element to a collection.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	elem = A pointer to the source OCI element.
 *	elemind = The null indicator for elem unless null is passed.
 *	coll = A pointer to the target OCI collection.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCICollAppend (OCIEnv* env, OCIError* err, dvoid* elem, dvoid* elemind, OCIColl* coll);

/**
 * Remove elements from the end of a collection.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	trim_num = The number of OCI elemenets to remove.
 *	coll = A pointer to the target OCI collection.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCICollTrim (OCIEnv* env, OCIError* err, sb4 trim_num, OCIColl* coll);

/**
 * Test if a collection is a locator.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	coll = A pointer to the target OCI collection.
 *	result = TRUE is coll is a locator and FALSE if it isn't.
 *
 * Returns:
 *	OCI_SUCCESS on success or OCI_INVALID_HANDLE on invalid parameters.
 */
extern (C) sword OCICollIsLocator (OCIEnv* env, OCIError* err, OCIColl* coll, boolean* result);


extern (C) sword OCIIterCreate (OCIEnv* env, OCIError* err, OCIColl* coll, OCIIter** itr);
/*
   NAME: OCIIterCreate - OCIColl Create an ITerator to scan the collection
                      elements
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        coll (IN) - collection which will be scanned; the different
                collection types are varray and nested table
        itr (OUT) - address to the allocated collection iterator is
                returned by this function
   DESCRIPTION:
        Create an iterator to scan the elements of the collection. The
        iterator is created in the object cache. The iterator is initialized
        to point to the beginning of the collection.

        If the next function (OCIIterNext) is called immediately
        after creating the iterator then the first element of the collection
        is returned.
        If the previous function (OCIIterPrev) is called immediately after
        creating the iterator then "at beginning of collection" error is
        returned.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          any of the input parameters is null
          out of memory error
 */

extern (C) sword OCIIterDelete (OCIEnv* env, OCIError* err, OCIIter** itr);
/*
   NAME: OCIIterDelete - OCIColl Delete ITerator
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        itr (IN/OUT) - the allocated collection iterator is destroyed and
                the 'itr' is set to NULL prior to returning
   DESCRIPTION:
        Delete the iterator which was previously created by a call to
        OCIIterCreate.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          any of the input parameters is null
          to be discovered
 */

extern (C) sword OCIIterInit (OCIEnv* env, OCIError* err, OCIColl* coll, OCIIter* itr);
/*
   NAME: OCIIterInit - OCIColl Initialize ITerator to scan the given
                   collection
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        coll (IN) - collection which will be scanned; the different
                collection types are varray and nested table
        itr (IN/OUT) - pointer to an allocated  collection iterator
   DESCRIPTION:
        Initializes the given iterator to point to the beginning of the
        given collection. This function can be used to:

        a. reset an iterator to point back to the beginning of the collection
        b. reuse an allocated iterator to scan a different collection
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          any of the input parameters is null
 */

extern (C) sword OCIIterGetCurrent (OCIEnv* env, OCIError* err, OCIIter* itr, dvoid** elem, dvoid** elemind);
/*
   NAME: OCIIterGetCurrent - OCIColl Iterator based, get CURrent collection
                    element
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        itr (IN) - iterator which points to the current element
        elem (OUT) - address of the element pointed by the iterator is returned
        elemind (OUT) [optional] - address of the element's null indicator
                information is returned; if (elemind == NULL) then the null
                indicator information will NOT be returned
   DESCRIPTION:
        Returns pointer to the current element and its corresponding null
        information.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          any of the input parameters is null
 */

extern (C) sword OCIIterNext (OCIEnv* env, OCIError* err, OCIIter* itr, dvoid** elem, dvoid** elemind, boolean* eoc);
/*
   NAME: OCIIterNext - OCIColl Iterator based, get NeXT collection element
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        itr (IN/OUT) - iterator is updated to point to the next element
        elem (OUT) - after updating the iterator to point to the next element,
                address of the element is returned
        elemind (OUT) [optional] - address of the element's null indicator
                information is returned; if (elemind == NULL) then the null
                indicator information will NOT be returned
        eoc (OUT) - TRUE if iterator is at End Of Collection (i.e. next
                element does not exist) else FALSE
   DESCRIPTION:
        Returns pointer to the next element and its corresponding null
        information. The iterator is updated to point to the next element.

        If the iterator is pointing to the last element of the collection
        prior to executing this function, then calling this function will
        set eoc flag to TRUE. The iterator will be left unchanged in this
        situation.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          any of the input parameters is null
 */

extern (C) sword OCIIterPrev (OCIEnv* env, OCIError* err, OCIIter* itr, dvoid** elem, dvoid** elemind, boolean* boc);
/*
   NAME: OCIIterPrev - OCIColl Iterator based, get PReVious collection element
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        itr (IN/OUT) - iterator is updated to point to the previous
                element
        elem (OUT) - after updating the iterator to point to the previous
                element, address of the element is returned
        elemind (OUT) [optional] - address of the element's null indicator
                information is returned; if (elemind == NULL) then the null
                indicator information will NOT be returned
        boc (OUT) - TRUE if iterator is at Beginning Of Collection (i.e.
                previous element does not exist) else FALSE.
   DESCRIPTION:
        Returns pointer to the previous element and its corresponding null
        information. The iterator is updated to point to the previous element.

        If the iterator is pointing to the first element of the collection
        prior to executing this function, then calling this function will
        set 'boc' to TRUE. The iterator will be left unchanged in this
        situation.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          any of the input parameters is null
 */

extern (C) sword OCITableSize (OCIEnv* env, OCIError* err, OCITable* tbl, sb4* size);
/*
   NAME: OCITableSize - OCITable return current SIZe of the given
                   nested table (not including deleted elements)
   PARAMETERS:
        env(IN) - pointer to OCI environment handle
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tbl (IN) - nested table whose number of elements is returned
        size (OUT) - current number of elements in the nested table. The count
                does not include deleted elements.
   DESCRIPTION:
        Returns the count of elements in the given nested table.

        The count returned by OCITableSize() will be decremented upon
        deleting elements from the nested table. So, this count DOES NOT
        includes any "holes" created by deleting elements.
        For example:

            OCITableSize(...);
            // assume 'size' returned is equal to 5
            OCITableDelete(...); // delete one element
            OCITableSize(...);
            // 'size' returned will be equal to 4

        To get the count plus the count of deleted elements use
        OCICollSize(). Continuing the above example,

            OCICollSize(...)
            // 'size' returned will still be equal to 5
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          error during loading of nested table into object cache
          any of the input parameters is null
 */

extern (C) sword OCITableExists (OCIEnv* env, OCIError* err, OCITable* tbl, sb4 index, boolean* exists);
/*
   NAME: OCITableExists - OCITable test whether element at the given index
                    EXIsts
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tbl (IN) - table in which the given index is checked
        index (IN) - index of the element which is checked for existence
        exists (OUT) - set to TRUE if element at given 'index' exists
                else set to FALSE
   DESCRIPTION:
        Test whether an element exists at the given 'index'.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          any of the input parameters is null
 */

extern (C) sword OCITableDelete (OCIEnv* env, OCIError* err, sb4 index, OCITable* tbl);
/*
   NAME: OCITableDelete - OCITable DELete element at the specified index
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        index (IN) - index of the element which must be deleted
        tbl (IN) - table whose element is deleted
   DESCRIPTION:
        Delete the element at the given 'index'. Note that the position
        ordinals of the remaining elements of the table is not changed by the
        delete operation. So delete creates "holes" in the table.

        An error is returned if the element at the specified 'index' has
        been previously deleted.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          any of the input parameters is null
          given index is not valid
 */

extern (C) sword OCITableFirst (OCIEnv* env, OCIError* err, OCITable* tbl, sb4* index);
/*
   NAME: OCITableFirst - OCITable return FirST index of table
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tbl (IN) - table which is scanned
        index (OUT) - first index of the element which exists in the given
                table is returned
   DESCRIPTION:
        Return the first index of the element which exists in the given
        table.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          table is empty
 */

extern (C) sword OCITableLast (OCIEnv* env, OCIError* err, OCITable* tbl, sb4* index);
/*
   NAME: OCITableFirst - OCITable return LaST index of table
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tbl (IN) - table which is scanned
        index (OUT) - last index of the element which exists in the given
                table is returned
   DESCRIPTION:
        Return the last index of the element which exists in the given
        table.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          table is empty
 */

extern (C) sword OCITableNext (OCIEnv* env, OCIError* err, sb4 index, OCITable* tbl, sb4* next_index, boolean* exists);
/*
   NAME: OCITableNext - OCITable return NeXT available index of table
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        index (IN) - starting at 'index' the index of the next element
                which exists is returned
        tbl (IN) - table which is scanned
        next_index (OUT) - index of the next element which exists
                is returned
        exists (OUT) - FALSE if no next index available else TRUE
   DESCRIPTION:
        Return the smallest position j, greater than 'index', such that
        exists(j) is TRUE.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          no next index available
 */

extern (C) sword OCITablePrev (OCIEnv* env, OCIError* err, sb4 index, OCITable* tbl, sb4* prev_index, boolean* exists);
/*
   NAME: OCITablePrev - OCITable return PReVious available index of table
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode.
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        index (IN) - starting at 'index' the index of the previous element
                which exists is returned
        tbl (IN) - table which is scanned
        prev_index (OUT) - index of the previous element which exists
                is returned
        exists (OUT) - FALSE if no next index available else TRUE
   DESCRIPTION:
        Return the largest position j, less than 'index', such that
        exists(j) is TRUE.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is NULL.
        OCI_ERROR if
          no previous index available
 */
/+
deprecated lnxnum_t* OCINumberToLnx (OCINumber* num) {
	return cast(lnxnum_t*)num;
}
/*
   NAME:   OCINumberToLnx
   PARAMETERS:
           num (IN) - OCINumber to convert ;
   DESCRIPTION:
           Converts OCINumber to its internal lnx format
           This is not to be used in Public interfaces , but
           has been provided due to special requirements from
           SQLPLUS development group as they require to call
           Core funtions directly .
*/
+/
/**
 * OCI representation of XMLType.
 */
struct OCIXMLType {
}

/**
 * OCI representation of OCIDomDocument.
 */
struct OCIDOMDocument {
}