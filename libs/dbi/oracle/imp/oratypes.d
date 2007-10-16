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
module dbi.oracle.imp.oratypes;

alias ubyte	ub1;					///
alias byte	sb1;					///
alias byte	b1;					///
alias ushort	ub2;					///
alias short	sb2;					///
alias short	b2;					///
alias uint	ub4;					///
alias int	sb4;					///
alias int	b4;					///
alias ulong	ub8;					///
alias long	sb8;					///
alias ulong	oraub8;					///
alias long	orasb8;					///
alias size_t	sbig_ora;				///
alias ptrdiff_t	ubig_ora;				///

alias char	text;					///
alias char	oratext;				///
alias char	OraText;				///
alias ushort	utext;					///
alias char*	string;					///

alias byte	eb1;					///
alias short	eb2;					///
alias int	eb4;					///
alias uint	uword;					///
alias int	sword;					///
alias int	eword;					///

alias void	dvoid;					///
alias int	boolean;				///

const bool TRUE = true;					///
const bool FALSE = false;				///

deprecated ub1 UB1MAXVAL		= ub1.max;	///
deprecated ub1 UB1MINVAL		= ub1.min;	///
deprecated sb1 SB1MAXVAL		= sb1.max;	///
deprecated sb1 SB1MINVAL		= sb1.min;	///
deprecated b1 B1MAXVAL			= b1.max;	///
deprecated b1 B1MINVAL			= b1.min;	///
deprecated ub1 MINUB1MAXVAL		= 255;		///
deprecated ub1 MAXUB1MINVAL		= 0;		///
deprecated sb1 MINSB1MAXVAL		= 127;		///
deprecated sb1 MAXSB1MINVAL		= -127;		///

deprecated ub2 UB2MAXVAL		= ub2.max;	///
deprecated ub2 UB2MINVAL		= ub2.min;	///
deprecated sb2 SB2MAXVAL		= sb2.max;	///
deprecated sb2 SB2MINVAL		= sb2.min;	///
deprecated b2 B2MAXVAL			= b2.max;	///
deprecated b2 B2MINVAL			= b2.min;	///
deprecated ub2 MINUB2MAXVAL		= 65535;	///
deprecated ub2 MAXUB2MINVAL		= 0;		///
deprecated sb2 MINSB2MAXVAL		= 32767;	///
deprecated sb2 MAXSB2MINVAL		= -32767;	///

deprecated ub4 UB4MAXVAL		= ub4.max;	///
deprecated ub4 UB4MINVAL		= ub4.min;	///
deprecated sb4 SB4MAXVAL		= sb4.max;	///
deprecated sb4 SB4MINVAL		= sb4.min;	///
deprecated b4 B4MAXVAL			= b4.max;	///
deprecated b4 B4MINVAL			= b4.min;	///
deprecated ub4 MINUB4MAXVAL		= 4294967295;	///
deprecated ub4 MAXUB4MINVAL		= 0;		///
deprecated sb4 MINSB4MAXVAL		= 2147483647;	///
deprecated sb4 MAXSB4MINVAL		= -2147483647;	///

deprecated oraub8 ORAUB8MAXVAL		= oraub8.max;	///
deprecated oraub8 ORAUB8MINVAL		= oraub8.min;	///
deprecated orasb8 ORASB8MAXVAL		= orasb8.max;	///
deprecated orasb8 ORASB8MINVAL		= orasb8.min;	///
deprecated oraub8 MINORAUB8MAXVAL	= 18446744073709551615u; ///
deprecated oraub8 MAXORAUB8MINVAL	= 0;		///
deprecated orasb8 MINORASB8MAXVAL	= 9223372036854775807; ///
deprecated orasb8 MAXORASB8MINVAL	= -9223372036854775807; ///

deprecated ubig_ora UBIG_ORAMAXVAL	= ubig_ora.max;	///
deprecated ubig_ora UBIG_ORAMINVAL	= ubig_ora.min;	///
deprecated sbig_ora SBIG_ORAMAXVAL	= sbig_ora.max;	///
deprecated sbig_ora SBIG_ORAMINVAL	= sbig_ora.min;	///
deprecated ubig_ora MINUBIG_ORAMAXVAL	= 4294967295u;	///
deprecated ubig_ora MAXUBIG_ORAMINVAL	= 0;		///
deprecated sbig_ora MINSBIG_ORAMAXVAL	= 2147483647;	///
deprecated sbig_ora MAXSBIG_ORAMINVAL	= -2147483647;	///

deprecated eb1 EB1MAXVAL		= eb1.max;	///
deprecated eb1 EB1MINVAL		= eb1.min;	///
deprecated eb2 EB2MAXVAL		= eb2.max;	///
deprecated eb2 EB2MINVAL		= eb2.min;	///
deprecated eb4 EB4MAXVAL		= eb4.max;	///
deprecated eb4 EB4MINVAL		= eb4.min;	///
deprecated eb1 MINEB1MAXVAL		= 127;		///
deprecated eb1 MAXEB1MINVAL		= 0;		///
deprecated eb2 MINEB2MAXVAL		= 32767;	///
deprecated eb2 MAXEB2MINVAL		= 0;		///
deprecated eb4 MINEB4MAXVAL		= 2147483647;	///
deprecated eb4 MAXEB4MINVAL		= 0;		///

deprecated eword EWORDMAXVAL		= eword.max;	///
deprecated eword EWORDMINVAL		= eword.min;	///
deprecated uword UWORDMAXVAL		= uword.max;	///
deprecated uword UWORDMINVAL		= uword.min;	///
deprecated sword SWORDMAXVAL		= sword.max;	///
deprecated sword SWORDMINVAL		= sword.min;	///
deprecated eword MINEWORDMAXVAL		= 2147483647;	///
deprecated eword MAXEWORDMINVAL		= 0;		///
deprecated uword MINUWORDMAXVAL		= 4294967295;	///
deprecated uword MAXUWORDMINVAL		= 0;		///
deprecated sword MINSWORDMAXVAL		= 2147483647;	///
deprecated sword MAXSWORDMINVAL		= -2147483647;	///

deprecated size_t SIZE_TMAXVAL		= size_t.max;	///
deprecated size_t MINSIZE_TMAXVAL	= 4294967295;	///
deprecated ub1 UB1BITS			= ub1.sizeof * 8; ///
deprecated ubig_ora UBIGORABITS		= ubig_ora.sizeof * 8; ///

uword UB1MASK				= 1 << 8 - 1;	///

alias void function() lgenfp_t;				///