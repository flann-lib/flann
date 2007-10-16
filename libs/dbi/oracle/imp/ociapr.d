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
module dbi.oracle.imp.ociapr;

private import dbi.oracle.imp.ocidfn, dbi.oracle.imp.oratypes;

/**
 *
 *
 * Params:
 *	cursor =
 *	opcode =
 *	sqlvar =
 *	sqlvl =
 *	pvctx =
 *	progvl =
 *	ftype =
 *	scale =
 *	indp =
 *	alen =
 *	arcode =
 *	pv_skip =
 *	ind_skip =
 *	alen_skip =
 *	rc_skip =
 *	maxsiz =
 *	cursiz =
 *	fmt =
 *	fmtl =
 *	fmtt =
 *
 * Returns:
 *
 */
extern (C) sword obindps (cda_def* cursor, ub1 opcode, OraText* sqlvar, sb4 sqlvl, ub1* pvctx, sb4 progvl, sword ftype, sword scale, sb2* indp, ub2* alen, ub2* arcode, sb4 pv_skip, sb4 ind_skip, sb4 alen_skip, sb4 rc_skip, ub4 maxsiz, ub4* cursiz, OraText* fmt, sb4 fmtl, sword fmtt);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) sword obreak (cda_def* lda);

/**
 *
 *
 * Params:
 *	cursor =
 *
 * Returns:
 *
 */
extern (C) sword ocan (cda_def* cursor);

/**
 *
 *
 * Params:
 *	cursor =
 *
 * Returns:
 *
 */
extern (C) sword oclose (cda_def* cursor);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) sword ocof (cda_def* lda);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) sword ocom (cda_def* lda);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) sword ocon (cda_def* lda);

/**
 *
 *
 * Params:
 *	cursor =
 *	opcode =
 *	pos =
 *	bufctx =
 *	buf1 =
 *	ftype =
 *	scale =
 *	indp =
 *	fmt =
 *	fmtl =
 *	fmtt =
 *	rlen =
 *	rcode =
 *	pv_skip =
 *	ind_skip =
 *	alen_skip =
 *	rc_skip =
 *
 * Returns:
 *
 */
extern (C) sword odefinps (cda_def* cursor, ub1 opcode, sword pos, ub1* bufctx, sb4 bufl, sword ftype, sword scale, sb2* indp, OraText* fmt, sb4 fmtl, sword fmtt, ub2* rlen, ub2* rcode, sb4 pv_skip, sb4 ind_skip, sb4 alen_skip, sb4 rc_skip);

/**
 *
 *
 * Params:
 *	cursor =
 *	objnam =
 *	onlen =
 *	rsv1 =
 *	rsv1ln =
 *	rsv2 =
 *	rsv2ln =
 *	ovrld =
 *	pos =
 *	level =
 *	argnam =
 *	arnlen =
 *	dtype =
 *	defsup =
 *	mode =
 *	dtsiz =
 *	prec =
 *	scale =
 *	radix =
 *	spare =
 *	arrsiz =
 *
 * Returns:
 *
 */
extern (C) sword odessp (cda_def* cursor, OraText* objnam, size_t onlen, ub1* rsv1, size_t rsv1ln, ub1* rsv2, size_t rsv2ln, ub2* ovrld, ub2* pos, ub2* level, OraText** argnam, ub2* arnlen, ub2* dtype, ub1* defsup, ub1* mode, ub4* dtsiz, sb2* prec, sb2* scale, ub1* radix, ub4* spare, ub4* arrsiz);

/**
 *
 *
 * Params:
 *	cursor =
 *	pos =
 *	dbsize =
 *	dbtype =
 *	cbuf =
 *	cbufl =
 *	dsize =
 *	prec =
 *	scale =
 *	nullok =
 *
 * Returns:
 *
 */
extern (C) sword odescr (cda_def* cursor, sword pos, sb4* dbsize, sb2* dbtype, sb1* cbuf, sb4* cbufl, sb4* dsize, sb2* prec, sb2* scale, sb2* nullok);

/**
 *
 *
 * Params:
 *	lda =
 *	rcode =
 *	buf =
 *	bufsiz =
 *
 * Returns:
 *
 */
extern (C) sword oerhms (cda_def* lda, sb2 rcode, OraText* buf, sword bufsiz);

/**
 *
 *
 * Params:
 *	rcode =
 *	buf =
 *
 * Returns:
 *
 */
extern (C) sword oermsg (sb2 rcode, OraText* buf);

/**
 *
 *
 * Params:
 *	cursor =
 *
 * Returns:
 *
 */
extern (C) sword oexec (cda_def* cursor);

/**
 *
 *
 * Params:
 *	cursor =
 *	nrows =
 *	cancel =
 *	exact =
 *
 * Returns:
 *
 */
extern (C) sword oexfet (cda_def* cursor, ub4 nrows, sword cancel, sword exact);

/**
 *
 *
 * Params:
 *	cursor =
 *	iters =
 *	rowoff =
 *
 * Returns:
 *
 */
extern (C) sword oexn (cda_def* cursor, sword iters, sword rowoff);

/**
 *
 *
 * Params:
 *	cursor =
 *	nrows =
 *
 * Returns:
 *
 */
extern (C) sword ofen (cda_def* cursor, sword nrows);

/**
 *
 *
 * Params:
 *	cursor =
 *
 * Returns:
 *
 */
extern (C) sword ofetch (cda_def* cursor);

/**
 *
 *
 * Params:
 *	cursor =
 *	pos =
 *	buf =
 *	bufl =
 *	dtype =
 *	retl =
 *	offset =
 *
 * Returns:
 *
 */
extern (C) sword oflng (cda_def* cursor, sword pos, ub1* buf, sb4 bufl, sword dtype, ub4* retl, sb4 offset);

/**
 *
 *
 * Params:
 *	cursor =
 *	piecep =
 *	ctxpp =
 *	iterp =
 *	indexp =
 *
 * Returns:
 *
 */
extern (C) sword ogetpi (cda_def* cursor, ub1* piecep, dvoid** ctxpp, ub4* iterp, ub4* indexp);

/**
 *
 *
 * Params:
 *	cursor =
 *	rbopt =
 *	waitopt =
 *
 * Returns:
 *
 */
extern (C) sword oopt (cda_def* cursor, sword rbopt, sword waitopt);

/**
 *
 *
 * Params:
 *	mode =
 *
 * Returns:
 *
 */
extern (C) sword opinit (ub4 mode);

/**
 *
 *
 * Params:
 *	lda =
 *	hda =
 *	uid =
 *	uidl =
 *	pswd =
 *	pswdl =
 *	conn =
 *	connl =
 *	mode =
 *
 * Returns:
 *
 */
extern (C) sword olog (cda_def* lda, ub1* hda, OraText* uid, sword uidl, OraText* pswd, sword pswdl, OraText* conn, sword connl, ub4 mode);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) sword ologof (cda_def* lda);

/**
 *
 *
 * Params:
 *	cursor =
 *	lda =
 *	dbn =
 *	dbnl =
 *	arsize =
 *	uid =
 *	uidl =
 *
 * Returns:
 *
 */
extern (C) sword oopen (cda_def* cursor, cda_def* lda, OraText* dbn, sword dbnl, sword arsize, OraText* uid, sword uidl);

/**
 *
 *
 * Params:
 *	cursor =
 *	sqlstm =
 *	sqllen =
 *	defflg =
 *	lngflg =
 *
 * Returns:
 *
 */
extern (C) sword oparse (cda_def* cursor, OraText* sqlstm, sb4 sqllen, sword defflg, ub4 lngflg);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) sword orol (cda_def* lda);

/**
 *
 *
 * Params:
 *	cursor =
 *	piece =
 *	bufp =
 *	lenp =
 *
 * Returns:
 *
 */
extern (C) sword osetpi (cda_def* cursor, ub1 piece, dvoid* bufp, ub4* lenp);

/**
 *
 *
 * Params:
 *	lda =
 *	cname =
 *	cnlen =
 *
 * Returns:
 *
 */
extern (C) void sqlld2 (cda_def* lda, OraText* cname, sb4* cnlen);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) void sqllda (cda_def* lda);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) sword onbset (cda_def* lda);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) sword onbtst (cda_def* lda);

/**
 *
 *
 * Params:
 *	lda =
 *
 * Returns:
 *
 */
extern (C) sword onbclr (cda_def* lda);

/**
 *
 *
 * Params:
 *	lda =
 *	fdp =
 *
 * Returns:
 *
 */
extern (C) sword ognfd (cda_def* lda, dvoid* fdp);

/**
 *
 *
 * Params:
 *	cursor =
 *	sqlvar =
 *	sqlvl =
 *	progv =
 *	progvl =
 *	ftype =
 *	scale =
 *	indp =
 *	alen =
 *	arcode =
 *	maxsize =
 *	cursiz =
 *	fmt =
 *	fmtl =
 *	fmtt =
 *
 * Returns:
 *
 */
deprecated extern (C) sword obndra (cda_def* cursor, OraText* sqlvar, sword sqlvl, ub1* progv, sword progvl, sword ftype, sword scale, sb2* indp, ub2* alen, ub2* arcode, ub4 maxsiz, ub4* cursiz, OraText* fmt, sword fmtl, sword fmtt);

/**
 *
 *
 * Params:
 *	cursor =
 *	sqlvn =
 *	progv =
 *	progvl =
 *	ftype =
 *	scale =
 *	indp =
 *	fmt =
 *	fmtl =
 *	fmtt =
 *
 * Returns:
 *
 */
deprecated extern (C) sword obndrn (cda_def* cursor, sword sqlvn, ub1* progv, sword progvl, sword ftype, sword scale, sb2* indp, OraText* fmt, sword fmtl, sword fmtt);

/**
 *
 *
 * Params:
 *	cursor =
 *	sqlvar =
 *	sqlvl =
 *	progv =
 *	progvl =
 *	ftype =
 *	scale =
 *	indp =
 *	fmt =
 *	fmtl =
 *	fmtt =
 *
 * Returns:
 *
 */
deprecated extern (C) sword obndrv  (cda_def* cursor, OraText* sqlvar, sword sqlvl, ub1* progv, sword progvl, sword ftype, sword scale, sb2* indp, OraText* fmt, sword fmtl, sword fmtt);

/**
 *
 *
 * Params:
 *	cursor =
 *	pos =
 *	buf =
 *	bufl =
 *	ftype =
 *	scale =
 *	indp =
 *	fmt =
 *	fmtl =
 *	fmtt =
 *	rlen =
 *	rcode =
 *
 * Returns:
 *
 */
deprecated extern (C) sword odefin (cda_def* cursor, sword pos, ub1* buf, sword bufl, sword ftype, sword scale, sb2* indp, OraText* fmt, sword fmtl, sword fmtt, ub2* rlen, ub2* rcode);

/**
 *
 *
 * Params:
 *	cursor =
 *	pos =
 *	tbuf =
 *	tbufl =
 *	buf =
 *	bufl =
 *
 * Returns:
 *
 */
deprecated extern (C) sword oname (cda_def* cursor, sword pos, sb1* tbuf, sb2* tbufl, sb1* buf, sb2* bufl);

/**
 *
 *
 * Params:
 *	lda =
 *	hda =
 *	uid =
 *	uidl =
 *	pswd =
 *	pswdl =
 *	audit =
 *
 * Returns:
 *
 */
deprecated extern (C) sword orlon (cda_def* lda, ub1* hda, OraText* uid, sword uidl, OraText* pswd, sword pswdl, sword audit);

/**
 *
 *
 * Params:
 *	lda =
 *	uid =
 *	uidl =
 *	pswd =
 *	pswdl =
 *	audit =
 *
 * Returns:
 *
 */
deprecated extern (C) sword olon (cda_def* lda, OraText* uid, sword uidl, OraText* pswd, sword pswdl, sword audit);

/**
 *
 *
 * Params:
 *	cda =
 *	sqlstm =
 *	sqllen =
 *
 * Returns:
 *
 */
deprecated extern (C) sword osql3 (cda_def* cda, OraText* sqlstm, sword sqllen);

/**
 *
 *
 * Params:
 *	cursor =
 *	pos =
 *	dbsize =
 *	fsize =
 *	rcode =
 *	dtype =
 *	buf =
 *	bufl =
 *	dsize =
 *
 * Returns:
 *
 */
deprecated extern (C) sword odsc (cda_def* cursor, sword pos, sb2* dbsize, sb2* fsize, sb2* rcode, sb2* dtype, sb1* buf, sb2* bufl, sb2* dsize);