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
module dbi.oracle.imp.orid;

private import dbi.oracle.imp.oci, dbi.oracle.imp.oratypes, dbi.oracle.imp.oro, dbi.oracle.imp.ort;

/**
 * Set an attribute of an object.
 *
 * Params:
 *	env = The OCI enviroment handle initialized in object mode.
 *	err = The error handle.
 *	instance = An _instance of an ADT structure.
 *	null_struct = The null structure of instance.
 *	tdo = The TDO of the object.
 *	names = An array of attribute names specifying the names of the attributes in a path expression.
 *	lengths = The lengths of the elements in names.
 *	name_count = The number of elements in names.
 *	indexes = Not currently used.  Pass 0.
 *	index_count = Not currently used.  Pass 0.
 *	attr_null_status = The null status of the attribute if it is a primitive.
 *	attr_null_struct = The null structure of an ADT structure of collection attribute.
 *	attr_value = The attribute value.
 *
 * Returns:
 *	An OROSTA structure.
 */
extern (C) sword OCIObjectSetAttr (OCIEnv* env, OCIError* err, dvoid* instance, dvoid* null_struct, OCIType* tdo, oratext** names, ub4* lengths, ub4 name_count, ub4* indexes, ub4 index_count, OCIInd null_status, dvoid* attr_null_struct, dvoid* attr_value);

/**
 * Get an attribute of an object.
 *
 * Params:
 *	env = The OCI enviroment handle initialized in object mode.
 *	err = The error handle.
 *	instance = An _instance of an ADT structure.
 *	null_struct = The null structure of instance.
 *	tdo = The TDO of the object.
 *	names = An array of attribute names specifying the names of the attributes in a path expression.
 *	lengths = The lengths of the elements in names.
 *	name_count = The number of elements in names.
 *	indexes = Not currently used.  Pass 0.
 *	index_count = Not currently used.  Pass 0.
 *	attr_null_status = The null status of the attribute if it is a primitive.
 *	attr_null_struct = The null structure of an ADT structure of collection attribute.
 *	attr_value = The attribute value.
 *	attr_tdo = The TDO of the attribute.
 *
 * Returns:
 *	An OROSTA structure.
 */
extern (C) sword OCIObjectGetAttr (OCIEnv* env, OCIError* err, dvoid* instance, dvoid* null_struct, OCIType* tdo, oratext** names, ub4* lengths, ub4 name_count,  ub4* indexes, ub4 index_count, OCIInd* attr_null_status, dvoid** attr_null_struct, dvoid** attr_value, OCIType** attr_tdo);