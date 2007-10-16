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
module dbi.oracle.imp.oci1;

private import dbi.oracle.imp.ociap, dbi.oracle.imp.oratypes;

/**
 *
 */
ub1 OCIFormatUb1 (ub1 variable) {
	return cast(ub1)(OCIFormatTUb1() & variable);
}

/**
 *
 */
ub2 OCIFormatUb2 (ub2 variable) {
	return cast(ub2)(OCIFormatTUb2() & variable);
}

/**
 *
 */
ub4 OCIFormatUb4 (ub4 variable) {
	return cast(ub4)(OCIFormatTUb4() & variable);
}

/**
 *
 */
uword OCIFormatUword (uword variable) {
	return cast(uword)(OCIFormatTUword() & variable);
}

/**
 *
 */
ubig_ora OCIFormatUbig_ora (ubig_ora variable) {
	return cast(ubig_ora)(OCIFormatTUbig_ora() & variable);
}

/**
 *
 */
sb1 OCIFormatSb1 (sb1 variable) {
	return cast(sb1)(OCIFormatTSb1() & variable);
}

/**
 *
 */
sb2 OCIFormatSb2 (sb2 variable) {
	return cast(sb2)(OCIFormatTSb2() & variable);
}

/**
 *
 */
sb4 OCIFormatSb4 (sb4 variable) {
	return cast(sb4)(OCIFormatTSb4() & variable);
}

/**
 *
 */
sword OCIFormatSword (sword variable) {
	return cast(sword)(OCIFormatTSword() & variable);
}

/**
 *
 */
sbig_ora OCIFormatSbig_ora (sbig_ora variable) {
	return cast(sbig_ora)(OCIFormatTSbig_ora() & variable);
}

/**
 *
 */
eb1 OCIFormatEb1 (eb1 variable) {
	return cast(eb1)(OCIFormatTEb1() & variable);
}

/**
 *
 */
eb2 OCIFormatEb2 (eb2 variable) {
	return cast(eb2)(OCIFormatTEb2() & variable);
}

/**
 *
 */
eb4 OCIFormatEb4 (eb4 variable) {
	return cast(eb4)(OCIFormatTEb4() & variable);
}

/**
 *
 */
eword OCIFormatEword (eword variable) {
	return cast(eword)(OCIFormatTEword() & variable);
}

/**
 *
 */
char OCIFormatChar (char variable) {
	return cast(char)(OCIFormatTChar() & variable);
}

/**
 *
 */
text OCIFormatText (text variable) {
	return cast(text)(OCIFormatTText() & variable);
}

/**
 *
 */
double OCIFormatDouble (double variable) {
	return cast(double)(OCIFormatTDouble() & cast(ptrdiff_t)cast(void*)variable);
}

/**
 *
 */
dvoid* OCIFormatDvoid (dvoid* variable) {
	return cast(dvoid*)(OCIFormatTDvoid() & cast(ptrdiff_t)variable);
}

/**
 *
 */
alias OCIFormatTEnd OCIFormatEnd;

const uint OCIFormatDP			= 6;		///

const uint OCI_FILE_READ_ONLY		= 1;		/// Open for read only.
const uint OCI_FILE_WRITE_ONLY		= 2;		/// Open for write only.
const uint OCI_FILE_READ_WRITE		= 3;		/// Open for read & write.

const uint OCI_FILE_EXIST		= 0;		/// The file should exist.
const uint OCI_FILE_CREATE		= 1;		/// Create if the file doesn't exist.
const uint OCI_FILE_EXCL		= 2;		/// The file should not exist.
const uint OCI_FILE_TRUNCATE		= 4;		/// Create if the file doesn't exist, else truncate file the file to 0.
const uint OCI_FILE_APPEND		= 8;		/// Open the file in append mode.

const uint OCI_FILE_SEEK_BEGINNING	= 1;		/// Seek from the beginning of the file.
const uint OCI_FILE_SEEK_CURRENT	= 2;		/// Seek from the current position.
const uint OCI_FILE_SEEK_END		= 3;		/// Seek from the end of the file.

const uint OCI_FILE_FORWARD		= 1;		/// Seek forward.
const uint OCI_FILE_BACKWARD		= 2;		/// Seek backward.

const uint OCI_FILE_BIN			= 0;		/// Binary file.
const uint OCI_FILE_TEXT		= 1;		/// Text file.
const uint OCI_FILE_STDIN		= 2;		/// Standard i/p.
const uint OCI_FILE_STDOUT		= 3;		/// Standard o/p.
const uint OCI_FILE_STDERR		= 4;		/// Standard error.

/**
 * Represents an open file.
 */
struct OCIFileObject {
}

/**
 * OCIThread Context.
 */
struct OCIThreadContext {
}

/**
 * OCIThread Mutual Exclusion Lock.
 */
struct OCIThreadMutex {
}

/**
 * OCIThread Key for Thread-Specific Data.
 */
struct OCIThreadKey {
}

/**
 * OCIThread Thread ID.
 */
struct OCIThreadId {
}

/**
 * OCIThread Thread Handle.
 */
struct OCIThreadHandle {
}

/**
 * OCIThread Key Destructor Function Type.
 */
alias void function(dvoid*) OCIThreadKeyDestFunc;

const uint OCI_EXTRACT_CASE_SENSITIVE	= 0x1;		/// Matching is case sensitive.
const uint OCI_EXTRACT_UNIQUE_ABBREVS	= 0x2;		/// Unique abbreviations for keys are allowed.
const uint OCI_EXTRACT_APPEND_VALUES	= 0x4;		/// If multiple values for a key exist, this determines if the new value should be appended to (or replace) the current list of values.

const uint OCI_EXTRACT_MULTIPLE		= 0x8;		/// Key can accept multiple values.
const uint OCI_EXTRACT_TYPE_BOOLEAN	= 1;		/// Key type is boolean.
const uint OCI_EXTRACT_TYPE_STRING	= 2;		/// Key type is string.
const uint OCI_EXTRACT_TYPE_INTEGER	= 3;		/// Key type is integer.
const uint OCI_EXTRACT_TYPE_OCINUM	= 4;		/// Key type is ocinum.