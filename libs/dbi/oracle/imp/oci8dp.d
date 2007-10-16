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
module dbi.oracle.imp.oci8dp;

private import dbi.oracle.imp.ocidfn, dbi.oracle.imp.oci, dbi.oracle.imp.oratypes;

/**
 * Context.
 */
struct OCIDirPathCtx {
}

/**
 * Function context.
 */
struct OCIDirPathFuncCtx {
}

/**
 * Column array.
 */
struct OCIDirPathColArray {
}

/**
 * Stream.
 */
struct OCIDirPathStream {
}

/**
 * Direct path descriptor.
 */
struct OCIDirPathDesc {
}

const uint OCI_DIRPATH_LOAD		= 1;		/// Direct path load operation.
const uint OCI_DIRPATH_UNLOAD		= 2;		/// Direct path unload operation.
const uint OCI_DIRPATH_CONVERT		= 3;		/// Direct path convert only operation.

const uint OCI_DIRPATH_INDEX_MAINT_SINGLE_ROW = 1;	///

const uint OCI_DIRPATH_INDEX_MAINT_SKIP_UNUSABLE = 2;	///
const uint OCI_DIRPATH_INDEX_MAINT_DONT_SKIP_UNUSABLE = 3; ///
const uint OCI_DIRPATH_INDEX_MAINT_SKIP_ALL = 4;	///

const uint OCI_DIRPATH_NORMAL		= 1;		/// Can accept rows, last row complete.
const uint OCI_DIRPATH_PARTIAL		= 2;		/// Last row was partial.
const uint OCI_DIRPATH_NOT_PREPARED	= 3;		/// Direct path context is not prepared.

const uint OCI_DIRPATH_COL_COMPLETE	= 0;		/// Column data is complete.
const uint OCI_DIRPATH_COL_NULL		= 1;		/// Column is null.
const uint OCI_DIRPATH_COL_PARTIAL	= 2;		/// Column data is partial.
const uint OCI_DIRPATH_COL_ERROR	= 3;		/// Column error, ignore row.

const uint OCI_DIRPATH_DATASAVE_SAVEONLY= 0;		/// Data save point only.
const uint OCI_DIRPATH_DATASAVE_FINISH	= 1;		/// Execute finishing logic.

const uint OCI_DIRPATH_DATASAVE_PARTIAL	= 2;		/// Save portion of input data (before space error occurred) and finish.

const uint OCI_DIRPATH_EXPR_OBJ_CONSTR	= 1;		/// NAME is an object constructor.
const uint OCI_DIRPATH_EXPR_SQL		= 2;		/// NAME is an opaque or sql function.
const uint OCI_DIRPATH_EXPR_REF_TBLNAME	= 3;		/// NAME is table name if ref is scoped.

/**
 * Abort a direct path operation.
 *
 * Upon successful completion the direct path context is no longer valid.
 *
 * Params:
 *	dpctx =
 *	errhp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathAbort (OCIDirPathCtx* dpctx, OCIError* errhp);

/**
 * Execute a data save point.
 *
 * Params:
 *	dpctx =
 *	errhp =
 *	action =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathDataSave (OCIDirPathCtx* dpctx, OCIError* errhp, ub4 action);

/**
 * Finish a direct path operation.
 *
 * Params:
 *	dpctx =
 *	errhp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathFinish (OCIDirPathCtx* dpctx, OCIError* errhp);

/**
 * Flush a partial row from the server.
 *
 * Params:
 *	dpctx =
 *	errhp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathFlushRow (OCIDirPathCtx* dpctx, OCIError* errhp);

/**
 * Prepare a direct path operation.
 *
 * Params:
 *	dpctx =
 *	svchp =
 *	errhp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathPrepare (OCIDirPathCtx* dpctx, OCISvcCtx* svchp, OCIError* errhp);

/**
 * Load a direct path stream.
 *
 * Params:
 *	dpctx =
 *	dpstr =
 *	errhp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathLoadStream (OCIDirPathCtx* dpctx, OCIDirPathStream* dpstr, OCIError* errhp);

/**
 * Get column array entry.
 *
 * Deprecated:
 *	Use OCIDirPathColArrayRowGet instead.
 *
 * Params:
 *	dpca =
 *	errhp =
 *	rownum =
 *	colIdx =
 *	cvalpp =
 *	clenp =
 *	cflgp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathColArrayEntryGet (OCIDirPathColArray* dpca, OCIError* errhp, ub4 rownum, ub2 colIdx, ub1** cvalpp, ub4* clenp, ub1* cflgp);

/**
 * Set column array entry.
 *
 * Deprecated:
 *	Use OCIDirPathColArrayRowGet instead.
 *
 * Params:
 *	dpca =
 *	errhp =
 *	rownum =
 *	colIdx =
 *	cvalp =
 *	clenp =
 *	clen =
 *	cflgp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathColArrayEntrySet (OCIDirPathColArray* dpca, OCIError* errhp, ub4 rownum, ub2 colIdx, ub1* cvalp, ub4 clen, ub1 cflg);

/**
 * Get column array row pointers.
 *
 * Params:
 *	dpca =
 *	errhp =
 *	rownum =
 *	cvalppp =
 *	clenpp =
 *	cflgpp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathColArrayRowGet (OCIDirPathColArray* dpca, OCIError* errhp, ub4 rownum, ub1*** cvalppp, ub4** clenpp, ub1** cflgpp);

/**
 * Reset column array state.
 *
 * Resetting the column array state is necessary when piecing in a large
 * column and an error occurs in the middle of loading the column.
 *
 * Params:
 *	dpca =
 *	errhp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathColArrayReset (OCIDirPathColArray* dpca, OCIError* errhp);

/**
 * Convert column array to stream format.
 *
 * Params:
 *	dpca =
 *	dpctx =
 *	dpstr =
 *	errhp =
 *	rowcnt =
 *	rowoff =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathColArrayToStream (OCIDirPathColArray* dpca, OCIDirPathCtx* dpctx, OCIDirPathStream* dpstr, OCIError* errhp, ub4 rowcnt, ub4 rowoff);

/**
 *
 *
 * Params:
 *	dpstr =
 *	errhp =
 *
 * Returns:
 *	An OCI error code.
 */
extern (C) sword OCIDirPathStreamReset (OCIDirPathStream* dpstr, OCIError* errhp);