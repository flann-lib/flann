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
module dbi.oracle.imp.ocidem;

private import dbi.oracle.imp.ocidfn, dbi.oracle.imp.oratypes;

const uint VARCHAR2_TYPE		= 1;		///
const uint NUMBER_TYPE			= 2;		///
const uint INT_TYPE			= 3;		///
const uint FLOAT_TYPE			= 4;		///
const uint STRING_TYPE			= 5;		///
const uint ROWID_TYPE			= 11;		///
const uint DATE_TYPE			= 12;		///

const uint VAR_NOT_IN_LIST		= 1007;		///
const uint NO_DATA_FOUND		= 1403;		///
const uint NULL_VALUE_RETURNED		= 1405;		///

const uint FT_INSERT			= 3;		///
const uint FT_SELECT			= 4;		///
const uint FT_UPDATE			= 5;		///
const uint FT_DELETE			= 9;		///

const uint FC_OOPEN			= 14;		///

/**
 * OCI function code labels, corresponding to the fc numbers in the cursor data area.
 */
text*[] oci_func_tab = [
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"OSQL",				///
	cast(text*)"not used",				///
	cast(text*)"OEXEC, OEXN",			///
	cast(text*)"not used",				///
	cast(text*)"OBIND",				///
	cast(text*)"not used",				///
	cast(text*)"ODEFIN",				///
	cast(text*)"not used",				///
	cast(text*)"ODSRBN",				///
	cast(text*)"not used",				///
	cast(text*)"OFETCH, OFEN",			///
	cast(text*)"not used",				///
	cast(text*)"OOPEN",				///
	cast(text*)"not used",				///
	cast(text*)"OCLOSE",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"ODSC",				///
	cast(text*)"not used",				///
	cast(text*)"ONAME",				///
	cast(text*)"not used",				///
	cast(text*)"OSQL3",				///
	cast(text*)"not used",				///
	cast(text*)"OBNDRV",				///
	cast(text*)"not used",				///
	cast(text*)"OBNDRN",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"OOPT",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"not used",				///
	cast(text*)"OCAN",				///
	cast(text*)"not used",				///
	cast(text*)"OPARSE",				///
	cast(text*)"not used",				///
	cast(text*)"OEXFET",				///
	cast(text*)"not used",				///
	cast(text*)"OFLNG",				///
	cast(text*)"not used",				///
	cast(text*)"ODESCR",				///
	cast(text*)"not used",				///
	cast(text*)"OBNDRA",				///
	cast(text*)"OBINDPS",				///
	cast(text*)"ODEFINPS",				///
	cast(text*)"OGETPI",				///
	cast(text*)"OSETPI"				///
];