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
module dbi.oracle.imp.xa;

const uint XIDDATASIZE			= 128;		/// Size in bytes.
const uint MAXGTRIDSIZE			= 64;		/// Maximum size in bytes of gtrid.
const uint MAXBQUALSIZE			= 64;		/// Maximum size in bytes of bqual.

/**
 * Transaction branch identification: XID and NULLXID:
 *
 * A value of -1 in formatID means that the XID is null.
 */
struct xid_t {
	int formatID;					/// Format identifier.
	int gtrid_length;				/// Value from 1 through 64.
	int bqual_length;				/// Value from 1 through 64.
	char[XIDDATASIZE] data;				/// Transaction data.
}
alias xid_t XID;

/**
 * Declarations of routines by which RMs call TMs:
 */
extern (C) int ax_reg (int, XID*, int);

/**
 * ditto
 */
extern (C) int ax_unreg (int, int);

const uint RMNAMESZ			= 32;		/// Length of resource manager name,  including the null terminator.
const uint MAXINFOSIZE			= 256;		/// Maximum size in bytes of xa_info strings, including the null terminator.

/*
 * XA Switch Data Structure.
 */
struct xa_switch_t {
	char[RMNAMESZ] name;				/// Name of resource manager.
	int flags;					/// Resource manager specific options.
	int xaversion;					/// Must be 0.
	extern (C) int function(char*, int, int) xa_open_entry; ///
	extern (C) int function(char*, int, int) xa_close_entry; ///
	extern (C) int function(XID*, int, int) xa_start_entry; ///
	extern (C) int function(XID*, int, int) xa_end_entry; ///
	extern (C) int function(XID*, int, int) xa_rollback_entry; ///
	extern (C) int function(XID*, int, int) xa_prepare_entry; ///
	extern (C) int function(XID*, int, int) xa_commit_entry; ///
	extern (C) int function(XID*, int, int, int) xa_recover_entry; ///
	extern (C) int function(XID*, int, int) xa_forget_entry; ///
	extern (C) int function(int*, int*, int, int) xa_complete_entry; ///
}

const ulong TMNOFLAGS			= 0x00000000;	/// No resource manager features selected.
const ulong TMREGISTER			= 0x00000001;	/// Resource manager dynamically registers.
const ulong TMNOMIGRATE			= 0x00000002;	/// Resource manager does not support association migration.
const ulong TMUSEASYNC			= 0x00000004;	/// Resource manager supports asynchronous operations.
const ulong TMASYNC			= 0x80000000;	/// Perform routine asynchronously.
const ulong TMONEPHASE			= 0x40000000;	/// Caller is using one-phase commit optimization.
const ulong TMFAIL			= 0x20000000;	/// Dissociates caller and marks transaction branch rollback-only.
const ulong TMNOWAIT			= 0x10000000;	/// Return if blocking condition exists.
const ulong TMRESUME			= 0x08000000;	/// Caller is resuming association with suspended transaction branch.
const ulong TMSUCCESS			= 0x04000000;	/// Dissociate caller from transaction branch.
const ulong TMSUSPEND			= 0x02000000;	/// Caller is suspending, not ending, association.
const ulong TMSTARTRSCAN		= 0x01000000;	/// Start a recovery scan.
const ulong TMENDRSCAN			= 0x00800000;	/// End a recovery scan.
const ulong TMMULTIPLE			= 0x00400000;	/// Wait for any asynchronous operation.
const ulong TMJOIN			= 0x00200000;	/// Caller is joining existing transaction branch.
const ulong TMMIGRATE			= 0x00100000;	/// Caller intends to perform migration.

const ulong TM_JOIN			= 2;		/// Caller is joining existing transaction branch .
const ulong TM_RESUME			= 1;		/// Caller is resuming association with suspended transaction branch.
const ulong TM_OK			= 0;		/// Normal execution.
const long TMER_TMERR			= -1;		/// An error occurred in the transaction manager.
const long TMER_INVAL			= -2;		/// Invalid arguments were given.
const long TMER_PROTO			= -3;		/// Routine invoked in an improper context.

const ulong XA_RBBASE			= 100;		/// The inclusive lower bound of the rollback codes.
const ulong XA_RBROLLBACK		= XA_RBBASE;	/// The rollback was caused by an unspecified reason.
const ulong XA_RBCOMMFAIL		= XA_RBBASE + 1;/// The rollback was caused by a communication failure.
const ulong XA_RBDEADLOCK		= XA_RBBASE + 2;/// A deadlock was detected.
const ulong XA_RBINTEGRITY		= XA_RBBASE + 3;/// A condition that violates the integrity of the resources was detected.
const ulong XA_RBOTHER			= XA_RBBASE + 4;/// The resource manager rolled back the transaction for a reason not on this list.
const ulong XA_RBPROTO			= XA_RBBASE + 5;/// A protocal error occurred in the resource manager.
const ulong XA_RBTIMEOUT		= XA_RBBASE + 6;/// A transaction branch took too long.
const ulong XA_RBTRANSIENT		= XA_RBBASE + 7;/// May retry the transaction branch.
const ulong XA_RBEND			= XA_RBTRANSIENT; /// The inclusive upper bound of the rollback codes.

const ulong XA_NOMIGRATE		= 9;		/// Resumption must occur where suspension occurred.
const ulong XA_HEURHAZ			= 8;		/// The transaction branch may have been heuristically completed.
const ulong XA_HEURCOM			= 7;		/// The transaction branch has been heuristically comitted.
const ulong XA_HEURRB			= 6;		/// The transaction branch has been heuristically rolled back.
const ulong XA_HEURMIX			= 5;		/// The transaction branch has been heuristically committed and rolled back.
const ulong XA_RETRY			= 4;		/// Routine returned with no effect and may be re-issued.
const ulong XA_RDONLY			= 3;		/// The transaction was read-only and has been committed.
const ulong XA_OK			= 0;		/// Normal execution.
const long XAER_ASYNC			= -2;		/// Asynchronous operation already outstanding.
const long XAER_RMERR			= -3;		/// A resource manager error occurred in the transaction branch.
const long XAER_NOTA			= -4;		/// The XID is not valid.
const long XAER_INVAL			= -5;		/// Invalid arguments were given.
const long XAER_PROTO			= -6;		/// Routine invoked in an improper context.
const long XAER_RMFAIL			= -7;		/// Resource manager unavailable.
const long XAER_DUPID			= -8;		/// The XID already exists.
const long XAER_OUTSIDE			= -9;		/// Resource manager doing work outside global transaction.