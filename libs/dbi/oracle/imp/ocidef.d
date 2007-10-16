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
module dbi.oracle.imp.ocidef;

deprecated:

/*
#include <upidef.h>
#include <riddef.h>		No longer necessary???
*/
private import dbi.oracle.imp.ociapr, dbi.oracle.imp.oratypes;

/**
 * The necessary part of riddef.h?
 */
struct riddef {
	ub4 ridobjnum;					///
	ub2 ridfilenum;					///
	ub1 filler;					///
	ub4 ridblocknum;				///
	ub2 ridslotnum;					///
}

const uint CSRCHECK			= 172;		/// csrdef is a cursor.
const uint LDACHECK			= 202;		/// csrdef is a login data area.

/**
 *
 */
struct csrdef {
	b2 csrrc;					/// Return code: v2 codes, v4 codes negative.
	ub2 csrft;					/// Function type.
	ub4 csrrpc;					/// Rows processed count.
	ub2 csrpeo;					/// Parse error offset.
	ub1 csrfc;					/// Function code.
	ub1 csrlfl;					/// Lda flag to indicate type of login.
	ub2 csrarc;					/// Actual untranslated return code.
	ub1 csrwrn;					/// Warning flags.
	ub1 csrflg;					/// Error action.
	eword csrcn;					/// Cursor number.
	riddef csrrid;					/// Rowid structure.
	eword csrose;					/// OS dependent error code.
	ub1 csrchk;					/// Check byte = CSRCHECK - in cursor.
//	hstdef* csrhst;					/// Pointer to the hst.
}
alias csrdef ldadef;

const uint LDAFLG			= 1;		/// ...Via ologon.
const uint LDAFLO			= 2;		/// ...Via olon or orlon.
const uint LDANBL			= 3;		/// ...Nonblocking logon in progress.
const uint csrfpa			= 2;		/// ...OSQL.
const uint csrfex			= 4;		/// ...OEXEC.
const uint csrfbi			= 6;		/// ...OBIND.
const uint csrfdb			= 8;		/// ...ODFINN.
const uint csrfdi			= 10;		/// ...ODSRBN.
const uint csrffe			= 12;		/// ...OFETCH.
const uint csrfop			= 14;		/// ...OOPEN.
const uint csrfcl			= 16;		/// ...OCLOSE.
const uint csrfds			= 22;		/// ...ODSC.
const uint csrfnm			= 24;		/// ...ONAME.
const uint csrfp3			= 26;		/// ...OSQL3.
const uint csrfbr			= 28;		/// ...OBNDRV.
const uint csrfbx			= 30;		/// ...OBNDRN.
const uint csrfso			= 34;		/// ...OOPT.
const uint csrfre			= 36;		/// ...ORESUM.
const uint csrfbn			= 50;		/// ...OBINDN.
const uint csrfca			= 52;		/// ...OCANCEL.
const uint csrfsd			= 54;		/// ...OSQLD.
const uint csrfef			= 56;		/// ...OEXFEN.
const uint csrfln			= 58;		/// ...OFLNG.
const uint csrfdp			= 60;		/// ...ODSCSP.
const uint csrfba			= 62;		/// ...OBNDRA.
const uint csrfbps			= 63;		/// ...OBINDPS.
const uint csrfdps			= 64;		/// ...ODEFINPS.
const uint csrfgpi			= 65;		/// ...OGETPI.
const uint csrfspi			= 66;		/// ...OSETPI.

const uint CSRWANY			= 0x01;		/// There is a warning flag set.
const uint CSRWTRUN			= 0x02;		/// A data item was truncated.
const uint CSRWNVIC			= 0x04;		/// Null values were used in an aggregate function.
const uint CSRWITCE			= 0x08;		/// Column count not equal to into list count.
const uint CSRWUDNW			= 0x10;		/// Update or delete without where clause.
const uint CSRWRSV0			= 0x20;		///
const uint CSRWROLL			= 0x40;		/// Rollback required.
const uint CSRWRCHG			= 0x80;		/// Change after query start on select for update.

const uint CSRFSPND			= 0x01;		/// Current operation suspended.
const uint CSRFATAL			= 0x02;		/// Fatal operation: transaction rolled back.
const uint CSRFBROW			= 0x04;		/// Current row backed out.
const uint CSRFREFC			= 0x08;		/// Ref cursor type CRSCHK disabled for this cursor.
const uint CSRFNOAR			= 0x10;		/// Ref cursor type binds, so no array bind/execute.

const uint OTYCTB			= 1;		/// Create table.
const uint OTYSER			= 2;		/// Set role.
const uint OTYINS			= 3;		/// Insert.
const uint OTYSEL			= 4;		/// Select.
const uint OTYUPD			= 5;		/// Update.
const uint OTYDRO			= 6;		/// Drop role.
const uint OTYDVW			= 7;		/// Drop view.
const uint OTYDTB			= 8;		/// Drop table.
const uint OTYDEL			= 9;		/// Delete.
const uint OTYCVW			= 10;		/// Create view.
const uint OTYDUS			= 11;		/// Drop user.
const uint OTYCRO			= 12;		/// Create role.
const uint OTYCSQ			= 13;		/// Create sequence.
const uint OTYASQ			= 14;		/// Alter sequence.
const uint OTYACL			= 15;		/// Alter cluster.
const uint OTYDSQ			= 16;		/// Drop sequence.
const uint OTYCSC			= 17;		/// Create schema.
const uint OTYCCL			= 18;		/// Create cluster.
const uint OTYCUS			= 19;		/// Create user.
const uint OTYCIX			= 20;		/// Create index.
const uint OTYDIX			= 21;		/// Drop index.
const uint OTYDCL			= 22;		/// Drop cluster.
const uint OTYVIX			= 23;		/// Validate index.
const uint OTYCPR			= 24;		/// Create procedure.
const uint OTYAPR			= 25;		/// Alter procedure.
const uint OTYATB			= 26;		/// Alter table.
const uint OTYXPL			= 27;		/// Explain.
const uint OTYGRA			= 28;		/// Grant.
const uint OTYREV			= 29;		/// Revoke.
const uint OTYCSY			= 30;		/// Create synonym.
const uint OTYDSY			= 31;		/// Drop synonym.
const uint OTYASY			= 32;		/// Alter system switch log.
const uint OTYSET			= 33;		/// Set transaction.
const uint OTYPLS			= 34;		/// PL/SQL execute.
const uint OTYLTB			= 35;		/// Lock.
const uint OTYNOP			= 36;		/// Noop.
const uint OTYRNM			= 37;		/// Rename.
const uint OTYCMT			= 38;		/// Comment.
const uint OTYAUD			= 39;		/// Audit.
const uint OTYNOA			= 40;		/// No audit.
const uint OTYAIX			= 41;		/// Alter index.
const uint OTYCED			= 42;		/// Create external database.
const uint OTYDED			= 43;		/// Drop external database.
const uint OTYCDB			= 44;		/// Create database.
const uint OTYADB			= 45;		/// Alter database.
const uint OTYCRS			= 46;		/// Create rollback segment.
const uint OTYARS			= 47;		/// Alter rollback segment.
const uint OTYDRS			= 48;		/// Drop rollback segment.
const uint OTYCTS			= 49;		/// Create tablespace.
const uint OTYATS			= 50;		/// Alter tablespace.
const uint OTYDTS			= 51;		/// Drop tablespace.
const uint OTYASE			= 52;		/// Alter session.
const uint OTYAUR			= 53;		/// Alter user.
const uint OTYCWK			= 54;		/// Commit (work).
const uint OTYROL			= 55;		/// Rollback.
const uint OTYSPT			= 56;		/// Savepoint.

const uint OTYDEV			= 10;		/// Old DEFINE VIEW = create view.

const uint OCLFPA			= 2;		/// Parse - OSQL.
const uint OCLFEX			= 4;		/// Execute - OEXEC.
const uint OCLFBI			= 6;		/// Bind by name - OBIND.
const uint OCLFDB			= 8;		/// Define buffer -  ODEFIN.
const uint OCLFDI			= 10;		/// Describe item - ODSC.
const uint OCLFFE			= 12;		/// Fetch - OFETCH.
const uint OCLFOC			= 14;		/// Open cursor - OOPEN.
const uint OCLFLI			= 14;		/// Old name for open cursor - OOPEN.
const uint OCLFCC			= 16;		/// Close cursor - OCLOSE.
const uint OCLFLO			= 16;		/// Old name for close cursor - OCLOSE.
const uint OCLFDS			= 22;		/// Describe - ODSC.
const uint OCLFON			= 24;		/// Get table and column names - ONAME.
const uint OCLFP3 			= 26;		/// Parse - OSQL3.
const uint OCLFBR			= 28;		/// Bind reference by name - OBNDRV.
const uint OCLFBX			= 30;		/// Bind reference numeric - OBNDRN.
const uint OCLFSO			= 34;		/// Special function - OOPT.
const uint OCLFRE			= 36;		/// Resume - ORESUM.
const uint OCLFBN			= 50;		/// Bindn.
const uint OCLFMX			= 52;		/// Maximum function number.

deprecated const uint OCLFLK		= 18;		/// Open  for kernel operations.
deprecated const uint OCLFEK		= 20;		/// Execute kernel operations.
deprecated const uint OCLFOK		= 22;		/// Kernel close.
deprecated const uint OCLFIN		= 28;		/// Logon to oracle.
deprecated const uint OCLFOF		= 30;		/// Logoff from oracle.
deprecated const uint OCLFAX		= 32;		/// Allocate a context area.
deprecated const uint OCLFPI		= 34;		/// Page in context area.
deprecated const uint OCLFIS		= 36;		/// Special system logon.
deprecated const uint OCLFCO		= 38;		/// Cancel the current operation.
deprecated const uint OCLFGI		= 40;		/// Get database id.
deprecated const uint OCLFJN		= 42;		/// Journal operation.
deprecated const uint OCLFCL		= 44;		/// Cleanup prior execute operation.
deprecated const uint OCLFMC		= 46;		/// Map a cursor area.
deprecated const uint OCLFUC		= 48;		/// Unmap cursor and restore user maping.
/+
const uint OCIEVDEF			= UPIEVDEF;	/// Default : non-thread safe enivronment.
const uint OCIEVTSF			= UPIEVTSF;	/// Thread-safe environment.

const uint OCILMDEF			= UPILMDEF;	/// Default, regular login.
const uint OCILMNBL			= UPILMNBL;	/// Non-blocking logon.
const uint OCILMESY			= UPILMESY;	/// Thread safe but external sync.
const uint OCILMISY			= UPILMISY;	/// Internal sync, we do it.
const uint OCILMTRY			= UPILMTRY;	/// Try to, but do not block on mutex.
+/
/**
 * Define return code pairs for version 2 to 3 conversions.
 */
struct ocitab {
	b2 ocitv3;					/// Version 3/4 return code.
	b2 ocitv2;					/// Version 2 equivalent return code.
}

extern (C) ocitab[] ocitbl;				///
/+
/**
 *
 */
sword CRSCHK (csrdef c) {
	if (c.csrchk != CSRCHECK && !(c.csrflg && CSRFREFC)) {
		return ocir32(c, CSRFREFC);
	} else {
		return 0;
	}
}

/**
 *
 */
b2 ldaerr (csrdef l, ub2 e) {
	l.csrarc = e;
	l.csrrc = -e;
	return l.csrrc;
}

/**
 *
 */
b2 LDACHK (csrdef l) {
	if (l.csrchk != LDACHECK) {
		return ldaerr(1, OER(1001));
	} else {
		return 0;
	}
}
+/

//extern (C) sword ocilog (ldadef* lda, hstdef* hst, oratext* uid, sword uidl, oratext* psw, sword pswl, oratext* conn, sword connl, ub4 mode);

extern (C) sword ocilon (ldadef* lda, oratext* uid, sword uidl, oratext* psw, sword pswl, sword audit);

extern (C) sword ocilgi (ldadef* lda, b2 areacount);

//extern (C) sword ocirlo (ldadef* lda, hstdef* hst, oratext* uid, sword uidl, oratext* psw, sword pswl, sword audit);
     /* ocilon - logon to oracle
     ** ocilgi - version 2 compatible ORACLE logon call.
     **          no login to ORACLE is performed: the LDA is initialized
     ** ocirlo - version 5 compatible ORACLE Remote Login call,
     **          oracle login is executed.
     **   lda     - pointer to ldadef
     **   uid     - user id [USER[/PASSWORD]]
     **   uidl    - length of uid, if -1 strlen(uid) is used
     **   psw     - password string; ignored if specified in uid
     **   pswl    - length of psw, if -1 strlen(psw) is used
     **   audit   - is not supported; the only permissible value is 0
     **   areacount - unused
     */

extern (C) sword ocilof (ldadef* lda);
     /*
     ** ocilof - disconnect from ORACLE
     **   lda     - pointer to ldadef
     */

extern (C) sword ocierr (ldadef* lda, b2 rcode, oratext* buffer, sword bufl);
extern (C) sword ocidhe (b2 rcode, oratext* buffer);
    /*
    ** Move the text explanation for an ORACLE error to a user defined buffer
    **  ocierr - will return the message associated with the hstdef stored
    **           in the lda.
    **  ocidhe - will return the message associated with the default host.
    **    lda    - lda associated with the login session
    **    rcode  - error code as returned by V3 call interface
    **    buffer - address of a user buffer of at least 132 characters
    */

extern (C) sword ociope (csrdef* cursor, ldadef* lda, oratext* dbn, sword dbnl, sword areasize, oratext* uid, sword uidl);

extern (C) sword ociclo (csrdef* cursor);
   /*
   ** open or close a cursor.
   **   cursor - pointer to csrdef
   **   ldadef - pointer to ldadef
   **   dbn    - unused
   **   dbnl   - unused
   **   areasize - if (areasize == -1)  areasize <- system default initial size
   **              else if (areasize IN [1..256]) areasize <- areasize * 1024;
   **              most applications should use the default size since context
   **              areas are extended as needed until memory is exhausted.
   **   uid    - user id
   **   uidl   - userid length
   */

extern (C) sword ocibre (ldadef* lda);
   /*
   **  ocibrk - Oracle Call Interface send BReaK Sends a break to
   **  oracle.  If oracle is  active,  the  current  operation  is
   **  cancelled.  May be called  asynchronously.   DOES  NOT  SET
   **  OERRCD in the hst.  This is because ocibrk  may  be  called
   **  asynchronously.  Callers must test the return code.
   **    lda  - pointer to a ldadef
   */

extern (C) sword ocican (csrdef* cursor);
   /*
   **  cancel the operation on the cursor, no additional OFETCH calls
   **  will be issued for the existing cursor without an intervening
   **  OEXEC call.
   **   cursor  - pointer to csrdef
   */

extern (C) sword ocisfe (csrdef* cursor, sword erropt, sword waitopt);
   /*
   ** ocisfe - user interface set error options
   ** set the error and cursor options.
   ** allows user to set the options for dealing with fatal dml errors
   ** and other cursor related options
   ** see oerdef for valid settings
   **   cursor  - pointer to csrdef
   **   erropt  - error optionsn
   **   waitopr - wait options
   */

extern (C) sword ocicom (ldadef* lda);
extern (C) sword ocirol (ldadef* lda);
   /*
   ** ocicom - commit the current transaction
   ** ocirol - roll back the current transaction
   */

extern (C) sword ocicon (ldadef* lda);
extern (C) sword ocicof (ldadef* lda);
   /*
   ** ocicon - auto Commit ON
   ** ocicof - auto Commit OFf
   */

extern (C) sword ocisq3 (csrdef* cursor, oratext* sqlstm, sword sqllen);
   /*
   ** ocisq3 - user interface parse sql statement
   **   cursor - pointer to csrdef
   **   sqlstm - pointer to SQL statement
   **   sqllen - length of SQL statement.  if -1, strlen(sqlstm) is used
   */

const uint OCI_PCWS			= 0;		/// For ocibndps and ocidfnps.
const uint OCI_SKIP			= 1;		/// ditto

extern (C) sword ocibin (csrdef* cursor, oratext* sqlvar, sword sqlvl, ub1* progv, sword progvl, sword ftype, sword scale, oratext* fmt, sword fmtl, sword fmtt);

extern (C) sword ocibrv (csrdef* cursor, oratext* sqlvar, sword sqlvl, ub1* progv, sword progvl, sword ftype, sword scale, b2* indp, oratext* fmt, sword fmtl, sword fmtt);

extern (C) sword ocibra (csrdef* cursor, oratext* sqlvar, sword sqlvl, ub1* progv, sword progvl, sword ftype, sword scale, b2* indp, ub2* aln, ub2* rcp, ub4 mal, ub4* cal, oratext* fmt, sword fmtl, sword fmtt);

extern (C) sword ocibndps (csrdef* cursor, ub1 opcode, oratext* sqlvar, sb4 sqlvl, ub1* progv, sb4 progvl, sword ftype, sword scale, b2* indp, ub2* aln, ub2* rcp, sb4 pv_skip, sb4 ind_skip, sb4 len_skip, sb4 rc_skip, ub4 mal, ub4* cal, oratext* fmt, sb4 fmtl, sword fmtt);

extern (C) sword ocibnn (csrdef* cursor, ub2 sqlvn, ub1* progv, sword progvl, sword ftype, sword scale, oratext* fmt, sword fmtl, sword fmtt);

extern (C) sword ocibrn (csrdef* cursor, sword sqlvn, ub1* progv, sword progvl, sword ftype, sword scale, b2* indp, oratext* fmt, sword fmtl, sword fmtt);
    /*
    ** ocibin - bind by value by name
    ** ocibrv - bind by reference by name
    ** ocibra - bind by reference by name (array)
    ** ocibndps - bind by reference by name (array) piecewise or with skips
    ** ocibnn - bind by value numeric
    ** ocibrn - bind by reference numeric
    **
    ** the contents of storage specified in bind-by-value calls are
    ** evaluated immediately.
    ** the addresses of storage specified in bind-by-reference calls are
    ** remembered, and the contents are examined at every execute.
    **
    **  cursor  - pointer to csrdef
    **  sqlvn   - the number represented by the name of the bind variables
    **            for variables of the form :n or &n for n in [1..256)
    **            (i.e. &1, :234).  unnecessarily using larger numbers
    **            in the range wastes space.
    **  sqlvar  - the name of the bind variable (:name or &name)
    **  sqlval  - the length of the name;
    **            in bindif -1, strlen(bvname) is used
    **  progv   - pointer to the object to bind.
    **  progvl  - length of object to bind.
    **            in bind-by-value if specified as -1 then strlen(bfa) is
    **              used (really only makes sends with character types)
    **            in bind-by-value, if specified as -1 then UB2MAXVAL
    **              is used.  Again this really makes sense only with
    **              SQLT_STR.
    **  ftype   - datatype of object
    **  indp    - pointer to indicator variable.
    **              -1     means to ignore bfa/bfl and bind NULL;
    **              not -1 means to bind the contents of bfa/bfl
    **              bind the contents pointed to by bfa
    **  aln     - Alternate length pointer
    **  rcp     - Return code pointer
    **  mal     - Maximum array length
    **  cal     - Current array length pointer
    **  fmt     - format string
    **  fmtl    - length of format string; if -1, strlen(fmt) is used
    **  fmtt    - desired output type after applying forat mask. Not
    **            really yet implemented
    **  scale   - number of decimal digits in a cobol packed decimal (type 7)
    **
    ** Note that the length of bfa when bound as SQLT_STR is reduced
    ** to strlen(bfa).
    ** Note that trailing blanks are stripped of storage of SQLT_STR.
    */

extern (C) sword ocidsc (csrdef* cursor, sword pos, b2* dbsize, b2* fsize, b2* rcode, b2* dtype, b1* buf, b2* bufl, b2* dsize);

extern (C) sword ocidsr (csrdef* cursor, sword pos, b2* dbsize, b2* dtype, b2* fsize);

extern (C) sword ocinam (csrdef* cursor, sword pos, b1* tbuf, b2* tbufl, b1* buf, b2* bufl);
    /*
    **  ocidsc, ocidsr: Obtain information about a column
    **  ocinam : get the name of a column
    **   cursor  - pointer to csrdef
    **   pos     - position in select list from [1..N]
    **   dbsize  - place to store the database size
    **   fsize   - place to store the fetched size
    **   rcode   - place to store the fetched column returned code
    **   dtype   - place to store the data type
    **   buf     - array to store the column name
    **   bufl    - place to store the column name length
    **   dsize   - maximum display size
    **   tbuf    - place to store the table name
    **   tbufl   - place to store the table name length
    */

extern (C) sword ocidsp (csrdef* cursor, sword pos, sb4* dbsize, sb2* dbtype, sb1* cbuf, sb4* cbufl, sb4* dsize, sb2* pre, sb2* scl, sb2* nul);

extern (C) sword ocidpr (ldadef* lda, oratext* object_name, size_t object_length, ptrdiff_t reserved1, size_t reserved1_length, ptrdiff_t reserved2, size_t reserved2_length, ub2* overload, ub2* position, ub2* level, oratext** argument_name, ub2* argument_length, ub2* datatype, ub1* default_supplied, ub1* in_out, ub4* length, sb2* precision, sb2* scale, ub1* radix, ub4* spare, ub4* total_elements);
   /*
   ** OCIDPR - User Program Interface: Describe Stored Procedure
   **
   ** This routine is used to obtain information about the calling
   ** arguments of a stored procedure.  The client provides the
   ** name of the procedure using "object_name" and "database_name"
   ** (database name is optional).  The client also supplies the
   ** arrays for OCIDPR to return the values and indicates the
   ** length of array via the "total_elements" parameter.  Upon return
   ** the number of elements used in the arrays is returned in the
   ** "total_elements" parameter.  If the array is too small then
   ** an error will be returned and the contents of the return arrays
   ** are invalid.
   **
   **
   **   EXAMPLE :
   **
   **   Client provides -
   **
   **   object_name    - SCOTT.ACCOUNT_UPDATE@BOSTON
   **   total_elements - 100
   **
   **
   **   ACCOUNT_UPDATE is an overloaded function with specification :
   **
   **     type number_table is table of number index by binary_integer;
   **     table account (account_no number, person_id number,
   **                    balance number(7,2))
   **     table person  (person_id number(4), person_nm varchar2(10))
   **
   **      function ACCOUNT_UPDATE (account number,
   **         person person%rowtype, amounts number_table,
   **         trans_date date) return accounts.balance%type;
   **
   **      function ACCOUNT_UPDATE (account number,
   **         person person%rowtype, amounts number_table,
   **         trans_no number) return accounts.balance%type;
   **
   **
   **   Values returned -
   **
   **   overload position   argument  level  datatype length prec scale rad
   **   -------------------------------------------------------------------
   **          0        0                0   NUMBER     22    7     2   10
   **          0        1   ACCOUNT      0   NUMBER     22    0     0    0
   **          0        2   PERSON       0   RECORD      0    0     0    0
   **          0        2     PERSON_ID  1   NUMBER     22    4     0   10
   **          0        2     PERSON_NM  1   VARCHAR2   10    0     0    0
   **          0        3   AMOUNTS      0   TABLE       0    0     0    0
   **          0        3                1   NUMBER     22    0     0    0
   **          0        4   TRANS_NO     0   NUMBER     22    0     0    0
   **
   **          1        0                0   NUMBER     22    7     2   10
   **          1        1   ACCOUNT      0   NUMBER     22    0     0    0
   **          1        2   PERSON       0   RECORD      0    0     0    0
   **          1        2    PERSON_ID   1   NUMBER     22    4     0   10
   **          1        2    PERSON_NM   1   VARCHAR2   10    0     0    0
   **          1        3   AMOUNTS      0   TABLE       0    0     0    0
   **          1        3                1   NUMBER     22    0     0    0
   **          1        4   TRANS_DATE   0   NUMBER     22    0     0    0
   **
   **
   **  OCIDPR Argument Descriptions -
   **
   **  ldadef           - pointer to ldadef
   **  object_name      - object name, synonyms are also accepted and will
   **                     be translate, currently only procedure and function
   **                     names are accepted, also NLS names are accepted.
   **                     Currently, the accepted format of a name is
   **                     [[part1.]part2.]part3[@dblink] (required)
   **  object_length    - object name length (required)
   **  reserved1        - reserved for future use
   **  reserved1_length - reserved for future use
   **  reserved2        - reserved for future use
   **  reserved2_length - reserved for future use
   **  overload         - array indicating overloaded procedure # (returned)
   **  position         - array of argument positions, position 0 is a
   **                     function return argument (returned)
   **  level            - array of argument type levels, used to describe
   **                     sub-datatypes of data structures like records
   **                     and arrays (returned)
   **  argument_name    - array of argument names, only returns first
   **                     30 characters of argument names, note storage
   **                     for 30 characters is allocated by client (returned)
   **  argument_length  - array of argument name lengths (returned)
   **  datatype         - array of oracle datatypes (returned)
   **  default_supplied - array indicating parameter has default (returned)
   **                     0 = no default, 1 = default supplied
   **  in_out           - array indicating if argument is IN or OUT (returned
   **                     0 = IN param, 1 = OUT param, 2 = IN/OUT param
   **  length           - array of argument lengths (returned)
   **  precision        - array of precisions (if number type)(returned)
   **  scale            - array of scales (if number type)(returned)
   **  radix            - array of radix (if number type)(returned)
   **  spare            - array of spares.
   **  total_elements   - size of arrays supplied by client (required),
   **                     total number of elements filled (returned)
   */

extern (C) sword ocidfi (csrdef* cursor, sword pos, ub1* buf, sword bufl, sword ftype, b2* rc, sword scale);

extern (C) sword ocidfn (csrdef* cursor, sword pos, ub1* buf, sword bufl, sword ftype, sword scale, b2* indp, oratext* fmt, sword fmtl, sword fmtt, ub2* rl, ub2* rc);

extern (C) sword ocidfnps (csrdef* cursor, ub1 opcode, sword pos, ub1* buf, sb4 bufl, sword ftype, sword scale, b2* indp, oratext* fmt, sb4 fmtl, sword fmtt, ub2* rl, ub2* rc, sb4 pv_skip, sb4 ind_skip, sb4 len_skip, sb4 rc_skip);


   /*  Define a user data buffer using upidfn
   **   cursor  - pointer to csrdef
   **   pos     - position of a field or exp in the select list of a query
   **   bfa/bfl - address and length of client-supplied storage
                  to receive data
   **   ftype   - user datatype
   **   scale   - number of fractional digits for cobol packed decimals
   **   indp    - place to store the length of the returned value. If returned
   **             value is:
   **             negative, the field fetched was NULL
   **             zero    , the field fetched was same length or shorter than
   **               the buffer provided
   **             positive, the field fetched was truncated
   **   fmt    - format string
   **   fmtl   - length of format string, if -1 strlent(fmt) used
   **   rl     - place to store column length after each fetch
   **   rc     - place to store column error code after each fetch
   **   fmtt   - fomat type
   */

extern (C) sword ocigetpi (csrdef* cursor, ub1* piecep, dvoid** ctxpp, ub4* iterp, ub4* indexp);
extern (C) sword ocisetpi (csrdef* cursor, ub1 piece, dvoid* bufp, ub4* lenp);


extern (C) sword ociexe (csrdef* cursor);
extern (C) sword ociexn (csrdef* cursor, sword iters, sword roff);
extern (C) sword ociefn (csrdef* cursor, ub4 nrows, sword can, sword exact);
    /*
    ** ociexe  - execute a cursor
    ** ociexn  - execute a cursosr N times
    **  cursor   - pointer to a csrdef
    **  iters    - number of times to execute cursor
    **  roff     - offset within the bind variable array at which to begin
    **             operations.
    */

extern (C) sword ocifet (csrdef* cursor);
extern (C) sword ocifen (csrdef* cursor, sword nrows);
    /* ocifet - fetch the next row
    ** ocifen - fetch n rows
    ** cursor   - pointer to csrdef
    ** nrows    - number of rows to be fetched
    */

extern (C) sword ocilng (csrdef* cursor, sword posit, ub1* bfa, sb4 bfl, sword dty, ub4* rln, sb4 off);

extern (C) sword ocic32 (csrdef* cursor);
    /*
    **   Convert selected version 3 return codes to the equivalent
    **   version 2 code.
    **   csrdef->csrrc is set to the converted code
    **   csrdef->csrft is set to v2 oracle statment type
    **   csrdef->csrrpc is set to the rows processed count
    **   csrdef->csrpeo is set to error postion
    **
    **     cursor - pointer to csrdef
    */


extern (C) sword ocir32 (csrdef* cursor, sword retcode);
   /*
   ** Convert selected version 3 return codes to the equivalent version 2
   ** code.
   **
   **    cursor - pointer to csrdef
   **    retcode - place to store the return code
   */


extern (C) dvoid ociscn (sword** arglst, char* mask_addr, sword** newlst);
   /*
   ** Convert call-by-ref to call-by-value:
   ** takes an arg list and a mask address, determines which args need
   ** conversion to a value, and creates a new list begging at the address
   ** of newlst.
   **
   **    arglst    - list of arguments
   **    mast_addr _ mask address determines args needing conversion
   **    newlst    - new list of args
   */

extern (C) eword ocistf (eword typ, eword bufl, eword rdig, oratext* fmt, csrdef* cursor, sword* err);
/*  Convert a packed  decimal buffer  length  (bytes) and scale to a format
**  string of the form mm.+/-nn, where  mm is the number of packed
**  decimal digits, and nn is the scaling factor.   A positive scale name
**  nn digits to the rights of the decimal; a negative scale means nn zeros
**  should be supplied to the left of the decimal.
**     bufl   - length of the packed decimal buffer
**     rdig   - number of fractional digits
**     fmt    - pointer to a string holding the conversion format
**     cursor - pointer to csrdef
**     err    - pointer to word storing error code
*/

extern (C) sword ocinbs (ldadef* lda);  /* set a connection to non-blocking   */
extern (C) sword ocinbt (ldadef* lda);  /* test if connection is non-blocking */
extern (C) sword ocinbc (ldadef* lda);  /* clear a connection to blocking     */
//extern (C) sword ocinlo (ldadef* lda, hstdef* hst, oratext* conn, sword connl, oratext* uid, sword uidl, oratext* psw, sword pswl, sword audit);  /* logon in non-blocking fashion */
/* ocinlo allows an application to logon in non-blocking fashion.
**   lda     - pointer to ldadef
**   hst     - pointer to a 256 byte area, must be cleared to zero before call
**   conn    - the database link (if specified @LINK in uid will be ignored)
**   connl   - length of conn; if -1 strlen(conn) is used
**   uid     - user id [USER[/PASSWORD][@LINK]]
**   uidl    - length of uid, if -1 strlen(uid) is used
**   psw     - password string; ignored if specified in uid
**   pswl    - length of psw, if -1 strlen(psw) is used
**   audit   - is not supported; the only permissible value is 0
*/

/* Note: The following routines are used in Pro*C and have the
   same interface as their couterpart in OCI.
   Althought the interface follows for more details please refer
   to the above routines */
extern (C) sword ocipin (ub4 mode);

extern (C) sword ologin (ldadef* lda, b2 areacount);
extern (C) sword ologon (ldadef* lda, b2 areacount);

/*
** ocisqd - oci delayed parse (Should be used only with deferred upi/oci)
** FUNCTION: Call upidpr to delay the parse of the sql statement till the
**           time that a call needs to be made to the kernel (execution or
**           describe time )
** RETURNS: Oracle return code.
*/
extern (C) sword ocisq7 (csrdef* cursor, oratext* sqlstm, sb4 sqllen, sword defflg, ub4 sqlt);

extern (C) sword obind (csrdef* cursor, oratext* sqlvar, sword sqlvl, ub1* progv, sword progvl, sword ftype, sword scale, oratext* fmt, sword fmtl, sword fmtt);

extern (C) sword obindn (csrdef* cursor, ub2 sqlvn, ub1* progv, sword progvl, sword ftype, sword scale, oratext* fmt, sword fmtl, sword fmtt);

extern (C) sword odfinn (csrdef* cursor, sword pos, ub1* buf, sword bufl, sword ftype, b2* rc, sword scale);

extern (C) sword odsrbn (csrdef* cursor, sword pos, b2* dbsize, b2* dtype, b2* fsize);

//extern (C) sword onblon (ldadef* lda, hstdef* hst, oratext* conn, sword connl, oratext* uid, sword uidl, oratext* psw, sword pswl, sword audit); /* logon in non-blocking fashion */

extern (C) sword ocignfd (ldadef* lda, dvoid* nfdp);           /* get native fd */

extern (C) ub2 ocigft_getFcnType (ub2 oertyp);      /* get sql function code */