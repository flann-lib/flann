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
module dbi.oracle.imp.ociextp;

private import dbi.oracle.imp.oci, dbi.oracle.imp.oratypes;

const uint OCIEXTPROC_SUCCESS		= 0;		/// The external procedure failed.
const uint OCIEXTPROC_ERROR		= 1;		/// The external procedure succeeded.

/**
 * The C callable interface to PL/SQL External Procedures require the
 * With-Context parameter to be passed. The type of this structure is
 * OCIExtProcContext is is opaque to the user.
 *
 * The user can declare the With-Context parameter in the application as
 *
 * OCIExtProcContext* with_context;
 */
struct OCIExtProcContext {
}

/**
 * Allocate memory for the duration of the External Procedure.
 *
 * Memory thus allocated will be freed by PL/SQL upon return from the
 * External Procedure. You must not use any kind of 'free' function on
 * memory allocated by OCIExtProcAllocCallMemory.
 *
 * Params:
 *	with_context = The OCI context.
 *	amount = The number of bytes to allocate.
 *
 * Returns:
 *	A pointer to the allocated memory on success and 0 on failure.
 */
extern (C) dvoid* ociepacm (OCIExtProcContext* with_context, size_t amount);
alias ociepacm OCIExtProcAllocCallMemory;

/**
 * Raise an Exception to PL/SQL.
 *
 * Calling this function signals an exception back to PL/SQL. After a
 * successful return from this function, the External Procedure must start
 * its exit handling and return back to PL/SQL. Once an exception is
 * signalled to PL/SQL, INOUT and OUT arguments, if any, are not processed
 * at all.
 *
 * Params:
 *	with_context = The OCI context.
 *	errnum = The Oracle error number to signal to PL/SQL. errnum must be in the range 1 to MAX_OEN/
 * Return :
 *	OCI_SUCCESS on success and OCI_ERROR on failure.
 */
extern (C) size_t ocieperr (OCIExtProcContext* with_context, int error_number);
alias ocieperr OCIExtProcRaiseExcp;

/**
 * Raise an exception to PL/SQL. In addition, substitute the
 * following error message string within the standard Oracle error
 * message string. See note for OCIExtProcRaiseExcp
 *
 * Params:
 *	with_context = The OCI context.
 *	errnum = The Oracle error number to signal to PL/SQL. errnum must be in the range 1 to MAX_OEN.
 *	errmsg = The error message associated with the errnum.
 *	len = The length of the error message 0 for anull terminated string.
 *
 * Returns:
 *	OCI_SUCCESS on success and OCI_ERROR on failure.
 *
 */
extern (C) size_t ociepmsg (OCIExtProcContext* with_context, int error_number, oratext* error_message, size_t len);
alias ociepmsg OCIExtProcRaiseExcpWithMsg;

/**
 * Get the OCI environment.
 *
 * Params:
 *	with_context = The OCI context.
 *	envh = The OCI environment handle.
 *	svch = The OCI service handle.
 *	errh = The OCI error handle.
 *
 * Returns:
 *	OCI_SUCCESS on success and OCI_ERROR on failure.
 */
extern (C) sword ociepgoe (OCIExtProcContext* with_context, OCIEnv** envh, OCISvcCtx** svch, OCIError** errh);
alias ociepgoe OCIExtProcGetEnv;

/**
 * Initialize a statement handle.
 *
 * Params:
 *	with_context = The OCI context.
 *	cursorno = The cursor number for which we need to initialize the statement handle.
 *	svch = The OCI service handle.
 *	stmthp = The OCI statement handle.
 *	errh = The OCI error handle.
 *
 * Returns:
 *	OCI_SUCCESS on success and OCI_ERROR on failure.
 *
 * Bugs:
 *	The parameter types were guessed.  This should be fixed in future releases.
 */
extern (C) sword ociepish (OCIExtProcContext* with_context, int cursorno, OCISvcCtx** svch, OCIStmt** stmthp, OCIError** errh);
alias ociepish OCIInitializeStatementHandle;