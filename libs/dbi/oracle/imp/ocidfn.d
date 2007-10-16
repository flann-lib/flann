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
module dbi.oracle.imp.ocidfn;

private import dbi.oracle.imp.oratypes;

/**
 * The cda_head struct is strictly PRIVATE.  It is used internally only.
 * Do not use this struct in OCI programs!
 */
package struct cda_head {
	sb2 v2_rc;					/// V2 return code.
	ub2 ft;						/// SQL function type.
	ub4 rpc;					/// Rows processed count.
	ub2 peo;					/// Parse error offset.
	ub1 fc;						/// OCI function code.
	ub1 rcs1;					/// Filler area.
	ub2 rc;						/// V7 return code.
	ub1 wrn;					/// Warning flags.
	ub1 rcs2;					/// Reserved.
	sword rcs3;					/// Reserved.
	struct rid {					/// Rowid structure.
		struct rd {				///
			ub4 rcs4;			///
			ub2 rcs5;			///
			ub1 rcs6;			///
		}
		ub4 rcs7;				///
		ub2 rcs8;				///
	}
	sword ose;					/// OSD dependent error.
	ub1 chk;					///
	dvoid* rcsp;					/// Pointer to reserved area.
}

/**
 * Size of HDA area:
 *
 * 512 for 64 bit architectures
 * 256 for 32 bit architectures
 */
version (X86) {
	const auto HDA_SIZE = 256;
	const auto CDA_SIZE = 64;
} else version (X86_64) {
	const auto HDA_SIZE = 512;
	const auto CDA_SIZE = 88;
} else {
	static assert (0);
}

/**
 * The real CDA, padded to CDA_SIZE bytes in size.
 */
struct cda_def {
	sb2 v2_rc;					/// V2 return code.
	ub2 ft;						/// SQL function type.
	ub4 rpc;					/// Rows processed count.
	ub2 peo;					/// Parse error offset.
	ub1 fc;						/// OCI function code.
	ub1 rcs1;					/// Filler area.
	ub2 rc;						/// V7 return code.
	ub1 wrn;					/// Warning flags.
	ub1 rcs2;					/// Reserved.
	sword rcs3;					/// Reserved.
	struct rid {					/// Rowid structure.
		struct rd {				///
			ub4 rcs4;			///
			ub2 rcs5;			///
			ub1 rcs6;			///
		}
		ub4 rcs7;				///
		ub2 rcs8;				///
	}
	sword ose;					/// OSD dependent error.
	ub1 chk;					///
	dvoid* rcsp;					/// Pointer to reserved area.
	ub1[CDA_SIZE - cda_head.sizeof] rcs9;		/// Filler.
}
alias cda_def Cda_Def;
alias cda_def Lda_Def;

const uint OCI_EV_DEF			= 0;		/// Default single-threaded environment.
const uint OCI_EV_TSF			= 1;		/// Thread-safe environment.

const uint OCI_LM_DEF			= 0;		/// Default login.
const uint OCI_LM_NBL			= 1;		/// Non-blocking logon.

const uint OCI_ONE_PIECE		= 0;		/// There or this is the only piece.
const uint OCI_FIRST_PIECE		= 1;		/// The first of many pieces.
const uint OCI_NEXT_PIECE		= 2;		/// The next of many pieces.
const uint OCI_LAST_PIECE		= 3;		/// The last piece of this column.

const uint SQLT_CHR			= 1;		/// (ORANET TYPE) character string.
const uint SQLT_NUM			= 2;		/// (ORANET TYPE) oracle numeric.
const uint SQLT_INT			= 3;		/// (ORANET TYPE) integer.
const uint SQLT_FLT			= 4;		/// (ORANET TYPE) Floating point number.
const uint SQLT_STR			= 5;		/// Zero terminated string.
const uint SQLT_VNU			= 6;		/// NUM with preceding length byte.
const uint SQLT_PDN			= 7;		/// (ORANET TYPE) Packed Decimal Numeric.
const uint SQLT_LNG			= 8;		/// Long.
const uint SQLT_VCS			= 9;		/// Variable character string.
const uint SQLT_NON			= 10;		/// Null/empty PCC Descriptor entry.
const uint SQLT_RID			= 11;		/// Rowid.
const uint SQLT_DAT			= 12;		/// Date in oracle format.
const uint SQLT_VBI			= 15;		/// Binary in VCS format.
const uint SQLT_BFLOAT			= 21;		/// Native binary float.
const uint SQLT_BDOUBLE			= 22;		/// Native binary double.
const uint SQLT_BIN			= 23;		/// Binary data(DTYBIN).
const uint SQLT_LBI			= 24;		/// Long binary.
const uint SQLT_UIN			= 68;		/// Unsigned integer.
const uint SQLT_SLS			= 91;		/// Display sign leading separate.
const uint SQLT_LVC			= 94;		/// Longer longs (char).
const uint SQLT_LVB			= 95;		/// Longer long binary.
const uint SQLT_AFC			= 96;		/// Ansi fixed char.
const uint SQLT_AVC			= 97;		/// Ansi Var char.
const uint SQLT_IBFLOAT			= 100;		/// Binary float canonical.
const uint SQLT_IBDOUBLE		= 101;		/// Binary double canonical.
const uint SQLT_CUR			= 102;		/// Cursor  type.
const uint SQLT_RDD			= 104;		/// Rowid descriptor.
const uint SQLT_LAB			= 105;		/// Label type.
const uint SQLT_OSL			= 106;		/// Oslabel type.

const uint SQLT_NTY			= 108;		/// Named object type.
const uint SQLT_REF			= 110;		/// Ref type.
const uint SQLT_CLOB			= 112;		/// Character lob.
const uint SQLT_BLOB			= 113;		/// Binary lob.
const uint SQLT_BFILEE			= 114;		/// Binary file lob.
const uint SQLT_CFILEE			= 115;		/// Character file lob.
const uint SQLT_RSET			= 116;		/// Result set type.
const uint SQLT_NCO			= 122;		/// Named collection type (varray or nested table).
const uint SQLT_VST			= 155;		/// OCIString type.
const uint SQLT_ODT			= 156;		/// OCIDate type.

const uint SQLT_DATE			= 184;		/// ANSI Date.
const uint SQLT_TIME			= 185;		/// TIME.
const uint SQLT_TIME_TZ			= 186;		/// TIME WITH TIME ZONE.
const uint SQLT_TIMESTAMP		= 187;		/// TIMESTAMP.
const uint SQLT_TIMESTAMP_TZ		= 188;		/// TIMESTAMP WITH TIME ZONE.
const uint SQLT_INTERVAL_YM		= 189;		/// INTERVAL YEAR TO MONTH.
const uint SQLT_INTERVAL_DS		= 190;		/// INTERVAL DAY TO SECOND.
const uint SQLT_TIMESTAMP_LTZ		= 232;		/// TIMESTAMP WITH LOCAL TZ.

const uint SQLT_PNTY			= 241;		/// pl/sql representation of named types.

deprecated const uint SQLT_FILE		= SQLT_BFILEE;	/// Binary file lob.
deprecated const uint SQLT_CFILE	= SQLT_CFILEE;	/// Character file lob.
deprecated const uint SQLT_BFILE	= SQLT_BFILEE;	/// Binary File lob.

const uint SQLCS_IMPLICIT		= 1;		/// For CHAR, VARCHAR2, CLOB w/o a specified set.
const uint SQLCS_NCHAR			= 2;		/// For NCHAR, NCHAR VARYING, NCLOB.
const uint SQLCS_EXPLICIT		= 3;		/// For CHAR, etc, with "CHARACTER SET ..." syntax.
const uint SQLCS_FLEXIBLE		= 4;		/// For PL/SQL "flexible" parameters.
const uint SQLCS_LIT_NULL		= 5;		/// F4/29/2006or typecheck of null and empty_clob() lits.