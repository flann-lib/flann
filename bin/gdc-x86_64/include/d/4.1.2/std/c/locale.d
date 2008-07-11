/**
 * C's &lt;locale.h&gt;
 * License: Public Domain
 * Standards:
 *	ISO/IEC 9899:1999 7.11 
 * Macros:
 *	WIKI=Phobos/StdCLocale
 */
module std.c.locale;

extern(C):

/// Structure giving information about numeric and monetary notation.
struct lconv{
	/// The decimal-point character used to format nonmonetary quantities.
	char* decimal_point;

	/** The character used to separate groups of digits before the
	 * decimal-point character in formatted nonmonetary quantities.
	 **/
	char* thousands_sep;

	/** A string whose elements indicate the size of each group of digits
	 * in formatted nonmonetary quantities.
	 **/
	char* grouping;

	/** The international currency symbol applicable to the current locale.
	 * The first three characters contain the alphabetic international
	 * currency symbol in accordance with those specified in ISO 4217.
	 * The fourth character	(immediately preceding the null character)
	 * is the character used to separate the international currency symbol
	 * from the monetary quantity.
	 **/
	char* int_curr_symbol;

	/// The local currency symbol applicable to the current locale.
	char* currency_symbol;

	/// The decimal-point used to format monetary quantities.
	char* mon_decimal_point;

	/** The separator for groups of digits before the decimal-point in
	 * formatted monetary quantities.
	 **/
	char* mon_thousands_sep;

	/** A string whose elements indicate the size of each group of digits
	 * in formatted monetary quantities.
	 **/
	char* mon_grouping;

	/** The string used to indicate a nonnegative-valued formatted
	 * monetary quantity.
	 **/
	char* positive_sign;

	/** The string used to indicate a negative-valued formatted monetary
	 * quantity.
	 **/
	char* negative_sign;

	/** The number of fractional digits (those after the decimal-point) to
	 * be displayed in an internationally formatted monetary quantity.
	 **/
	char int_frac_digits;

	/** The number of fractional digits (those after the decimal-point) to
	 * be displayed in a locally formatted monetary quantity.
	 **/
	char frac_digits;

	/// 1 if currency_symbol precedes a positive value, 0 if succeeds.
	char p_cs_precedes;
	
	/// 1 if a space separates currency_symbol from a positive value.
	char p_sep_by_space;
	
	/// 1 if currency_symbol precedes a negative value, 0 if succeeds.
	char n_cs_precedes;

	/// 1 if a space separates currency_symbol from a negative value.
	char n_sep_by_space;

  /* Positive and negative sign positions:
     0 Parentheses surround the quantity and currency_symbol.
     1 The sign string precedes the quantity and currency_symbol.
     2 The sign string follows the quantity and currency_symbol.
     3 The sign string immediately precedes the currency_symbol.
     4 The sign string immediately follows the currency_symbol.  */
  char p_sign_posn;
  char n_sign_posn;
  
	/// 1 if int_curr_symbol precedes a positive value, 0 if succeeds.
	char int_p_cs_precedes;
	
	/// 1 iff a space separates int_curr_symbol from a positive value.
	char int_p_sep_by_space;
	
	/// 1 if int_curr_symbol precedes a negative value, 0 if succeeds.
	char int_n_cs_precedes;
	
	/// 1 iff a space separates int_curr_symbol from a negative value.
	char int_n_sep_by_space;

  /* Positive and negative sign positions:
     0 Parentheses surround the quantity and int_curr_symbol.
     1 The sign string precedes the quantity and int_curr_symbol.
     2 The sign string follows the quantity and int_curr_symbol.
     3 The sign string immediately precedes the int_curr_symbol.
     4 The sign string immediately follows the int_curr_symbol.  */
  char int_p_sign_posn;
  char int_n_sign_posn;
}

/** Affects the behavior of C's character handling functions and C's multibyte
 * and wide character functions.
 **/
const LC_CTYPE = 0; 

/** Affects the decimal-point character for C's formatted input/output functions
 * and C's string conversion functions, as well as C's nonmonetary formatting
 * information returned by the localeconv function.
 **/
const LC_NUMERIC = 1;

/// Affects the behavior of the strftime and wcsftime functions.
const LC_TIME = 2;

/// Affects the behavior of the strcoll and strxfrm functions.
const LC_COLLATE = 3;

/** Affects the monetary formatting information returned by the localeconv
 * function.
 **/
const LC_MONETARY = 4;

/// The program's entire locale.
const LC_ALL = 6;

/** The setlocale function selects the appropriate portion of the program's
 * locale as specified by the category and locale arguments.
 **/
char* setlocale(int category, char* locale);

/** The localeconv function sets the components of an object with type
 * lconv with values appropriate for the formatting of numeric quantities
 * (monetary and otherwise) according to the rules of the current locale.
 **/
lconv* localeconv();

