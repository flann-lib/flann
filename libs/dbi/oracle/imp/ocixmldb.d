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
module dbi.oracle.imp.ocixmldb;

private import dbi.oracle.imp.oci, dbi.oracle.imp.oratypes;

/**
 *
 */
struct xmlctx {
}

/**
 *
 */
enum ocixmldbpname {
	XCTXINIT_OCIDUR  = 1,				///
	XCTXINIT_ERRHDL  = 2				///
}

/**
 *
 */
struct ocixmldbparam {
	ocixmldbpname name_ocixmldbparam;		///
	void* value_ocixmldbparam;			///
}

const uint NUM_OCIXMLDBPARAMS		= 2;		///

/**
 * Get a xmlctx structure initialized with error-handler and XDB callbacks.
 *
 * Params:
 *	envhp = The OCI environment handle.
 *	svchp = The OCI service handle.
 *	errhp = The OCI error handle.
 *	params = Contains the following optional parameters :
 *		(a) OCIDuration dur
 *			The OCI Duration.  Defaults to OCI_DURATION_SESSION.
 *		(b) void function(sword, oratext*) err_handler
 *			Pointer to the error handling function.  Defaults to null.
 *
 * Returns:
 *	A pointer to an xmlctx structure, with xdb context, error handler and callbacks
 *	populated with appropriate values. This is later used for all API calls.  null
 *	if no database connection is available.
 */
extern (C) xmlctx* OCIXmlDbInitXmlCtx (OCIEnv* envhp, OCISvcCtx* svchp, OCIError* err, ocixmldbparam* params, int num_params);

/**
 * Free any allocations done during OCIXmlDbInitXmlCtx.
 *
 * Params:
 *	xctx = The xmlctx to terminate.
 */
extern (C) void OCIXmlDbFreeXmlCtx (xmlctx* xctx);