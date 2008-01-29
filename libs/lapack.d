/*
  Copyright (C) 2006 William V. Baxter III

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any
  damages arising from the use of this software.

  Permission is granted to anyone to use this software for any
  purpose, including commercial applications, and to alter it and
  redistribute it freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must
     not claim that you wrote the original software. If you use this
     software in a product, an acknowledgment in the product
     documentation would be appreciated but is not required.

  2. Altered source versions must be plainly marked as such, and must
     not be misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  William Baxter wbaxter@gmail.com
*/

module lapack;

version(Windows) {
    pragma(lib, "blaslapackdll.lib");
}


// Prototypes for the raw Fortran interface to BLAS
extern(C):

alias int function(cfloat *) FCB_CGEES_SELECT;
alias int function(cfloat *) FCB_CGEESX_SELECT;
alias int function(cfloat *, cfloat *) FCB_CGGES_SELCTG;
alias int function(cfloat *, cfloat *) FCB_CGGESX_SELCTG;
alias int function(double *, double *) FCB_DGEES_SELECT;
alias int function(double *, double *) FCB_DGEESX_SELECT;
alias int function(double *, double *, double *) FCB_DGGES_DELCTG;
alias int function(double *, double *, double *) FCB_DGGESX_DELCTG;
alias int function(float *, float *) FCB_SGEES_SELECT;
alias int function(float *, float *) FCB_SGEESX_SELECT;
alias int function(float *, float *, float *) FCB_SGGES_SELCTG;
alias int function(float *, float *, float *) FCB_SGGESX_SELCTG;
alias int function(cdouble *) FCB_ZGEES_SELECT;
alias int function(cdouble *) FCB_ZGEESX_SELECT;
alias int function(cdouble *, cdouble *) FCB_ZGGES_DELCTG;
alias int function(cdouble *, cdouble *) FCB_ZGGESX_DELCTG;

version (FORTRAN_FLOAT_FUNCTIONS_RETURN_DOUBLE) {
    alias double lapack_float_ret_t;
} else {
    alias float lapack_float_ret_t;
}

/* LAPACK routines */

//--------------------------------------------------------
// ---- SIMPLE and DIVIDE AND CONQUER DRIVER routines ----
//---------------------------------------------------------

/// Solves a general system of linear equations AX=B.
void sgesv_(int *n, int *nrhs, float *a, int *lda, int *ipiv, float *b, int *ldb, int *info);
void dgesv_(int *n, int *nrhs, double *a, int *lda, int *ipiv, double *b, int *ldb, int *info);
void cgesv_(int *n, int *nrhs, cfloat *a, int *lda, int *ipiv, cfloat *b, int *ldb, int *info);
void zgesv_(int *n, int *nrhs, cdouble *a, int *lda, int *ipiv, cdouble *b, int *ldb, int *info);

/// Solves a general banded system of linear equations AX=B.
void sgbsv_(int *n, int *kl, int *ku, int *nrhs, float *ab, int *ldab, int *ipiv, float *b, int *ldb, int *info);
void dgbsv_(int *n, int *kl, int *ku, int *nrhs, double *ab, int *ldab, int *ipiv, double *b, int *ldb, int *info);
void cgbsv_(int *n, int *kl, int *ku, int *nrhs, cfloat *ab, int *ldab, int *ipiv, cfloat *b, int *ldb, int *info);
void zgbsv_(int *n, int *kl, int *ku, int *nrhs, cdouble *ab, int *ldab, int *ipiv, cdouble *b, int *ldb, int *info);

/// Solves a general tridiagonal system of linear equations AX=B.
void sgtsv_(int *n, int *nrhs, float *dl, float *d, float *du, float *b, int *ldb, int *info);
void dgtsv_(int *n, int *nrhs, double *dl, double *d, double *du, double *b, int *ldb, int *info);
void cgtsv_(int *n, int *nrhs, cfloat *dl, cfloat *d, cfloat *du, cfloat *b, int *ldb, int *info);
void zgtsv_(int *n, int *nrhs, cdouble *dl, cdouble *d, cdouble *du, cdouble *b, int *ldb, int *info);

/// Solves a symmetric positive definite system of linear
/// equations AX=B.
void sposv_(char *uplo, int *n, int *nrhs, float *a, int *lda, float *b, int *ldb, int *info, int uplo_len);
void dposv_(char *uplo, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, int *info, int uplo_len);
void cposv_(char *uplo, int *n, int *nrhs, cfloat *a, int *lda, cfloat *b, int *ldb, int *info, int uplo_len);
void zposv_(char *uplo, int *n, int *nrhs, cdouble *a, int *lda, cdouble *b, int *ldb, int *info, int uplo_len);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, where A is held in packed storage.
void sppsv_(char *uplo, int *n, int *nrhs, float *ap, float *b, int *ldb, int *info, int uplo_len);
void dppsv_(char *uplo, int *n, int *nrhs, double *ap, double *b, int *ldb, int *info, int uplo_len);
void cppsv_(char *uplo, int *n, int *nrhs, cfloat *ap, cfloat *b, int *ldb, int *info, int uplo_len);
void zppsv_(char *uplo, int *n, int *nrhs, cdouble *ap, cdouble *b, int *ldb, int *info, int uplo_len);

/// Solves a symmetric positive definite banded system
/// of linear equations AX=B.
void spbsv_(char *uplo, int *n, int *kd, int *nrhs, float *ab, int *ldab, float *b, int *ldb, int *info, int uplo_len);
void dpbsv_(char *uplo, int *n, int *kd, int *nrhs, double *ab, int *ldab, double *b, int *ldb, int *info, int uplo_len);
void cpbsv_(char *uplo, int *n, int *kd, int *nrhs, cfloat *ab, int *ldab, cfloat *b, int *ldb, int *info, int uplo_len);
void zpbsv_(char *uplo, int *n, int *kd, int *nrhs, cdouble *ab, int *ldab, cdouble *b, int *ldb, int *info, int uplo_len);

/// Solves a symmetric positive definite tridiagonal system
/// of linear equations AX=B.
void sptsv_(int *n, int *nrhs, float *d, float *e, float *b, int *ldb, int *info);
void dptsv_(int *n, int *nrhs, double *d, double *e, double *b, int *ldb, int *info);
void cptsv_(int *n, int *nrhs, float *d, cfloat *e, cfloat *b, int *ldb, int *info);
void zptsv_(int *n, int *nrhs, double *d, cdouble *e, cdouble *b, int *ldb, int *info);


/// Solves a real symmetric indefinite system of linear equations AX=B.
void ssysv_(char *uplo, int *n, int *nrhs, float *a, int *lda, int *ipiv, float *b, int *ldb, float *work, int *lwork, int *info, int uplo_len);
void dsysv_(char *uplo, int *n, int *nrhs, double *a, int *lda, int *ipiv, double *b, int *ldb, double *work, int *lwork, int *info, int uplo_len);
void csysv_(char *uplo, int *n, int *nrhs, cfloat *a, int *lda, int *ipiv, cfloat *b, int *ldb, cfloat *work, int *lwork, int *info, int uplo_len);
void zsysv_(char *uplo, int *n, int *nrhs, cdouble *a, int *lda, int *ipiv, cdouble *b, int *ldb, cdouble *work, int *lwork, int *info, int uplo_len);

/// Solves a complex Hermitian indefinite system of linear equations AX=B.
void chesv_(char *uplo, int *n, int *nrhs, cfloat *a, int *lda, int *ipiv, cfloat *b, int *ldb, cfloat *work, int *lwork, int *info, int uplo_len);
void zhesv_(char *uplo, int *n, int *nrhs, cdouble *a, int *lda, int *ipiv, cdouble *b, int *ldb, cdouble *work, int *lwork, int *info, int uplo_len);

/// Solves a real symmetric indefinite system of linear equations AX=B,
/// where A is held in packed storage.
void sspsv_(char *uplo, int *n, int *nrhs, float *ap, int *ipiv, float *b, int *ldb, int *info, int uplo_len);
void dspsv_(char *uplo, int *n, int *nrhs, double *ap, int *ipiv, double *b, int *ldb, int *info, int uplo_len);
void cspsv_(char *uplo, int *n, int *nrhs, cfloat *ap, int *ipiv, cfloat *b, int *ldb, int *info, int uplo_len);
void zspsv_(char *uplo, int *n, int *nrhs, cdouble *ap, int *ipiv, cdouble *b, int *ldb, int *info, int uplo_len);

/// Solves a complex Hermitian indefinite system of linear equations AX=B,
/// where A is held in packed storage.
void chpsv_(char *uplo, int *n, int *nrhs, cfloat *ap, int *ipiv, cfloat *b, int *ldb, int *info, int uplo_len);
void zhpsv_(char *uplo, int *n, int *nrhs, cdouble *ap, int *ipiv, cdouble *b, int *ldb, int *info, int uplo_len);

/// Computes the least squares solution to an over-determined system
/// of linear equations, A X=B or A**H X=B,  or the minimum norm
/// solution of an under-determined system, where A is a general
/// rectangular matrix of full rank,  using a QR or LQ factorization
/// of A.
void sgels_(char *trans, int *m, int *n, int *nrhs, float *a, int *lda, float *b, int *ldb, float *work, int *lwork, int *info, int trans_len);
void dgels_(char *trans, int *m, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, double *work, int *lwork, int *info, int trans_len);
void cgels_(char *trans, int *m, int *n, int *nrhs, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *work, int *lwork, int *info, int trans_len);
void zgels_(char *trans, int *m, int *n, int *nrhs, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *work, int *lwork, int *info, int trans_len);

/// Computes the least squares solution to an over-determined system
/// of linear equations, A X=B or A**H X=B,  or the minimum norm
/// solution of an under-determined system, using a divide and conquer
/// method, where A is a general rectangular matrix of full rank,
/// using a QR or LQ factorization of A.
void sgelsd_(int *m, int *n, int *nrhs, float *a, int *lda, float *b, int *ldb, float *s, float *rcond, int *rank, float *work, int *lwork, int *iwork, int *info);
void dgelsd_(int *m, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, double *s, double *rcond, int *rank, double *work, int *lwork, int *iwork, int *info);
void cgelsd_(int *m, int *n, int *nrhs, cfloat *a, int *lda, cfloat *b, int *ldb, float *s, float *rcond, int *rank, cfloat *work, int *lwork, float *rwork, int *iwork, int *info);
void zgelsd_(int *m, int *n, int *nrhs, cdouble *a, int *lda, cdouble *b, int *ldb, double *s, double *rcond, int *rank, cdouble *work, int *lwork, double *rwork, int *iwork, int *info);

/// Solves the LSE (Constrained Linear Least Squares Problem) using
/// the GRQ (Generalized RQ) factorization
void sgglse_(int *m, int *n, int *p, float *a, int *lda, float *b, int *ldb, float *c, float *d, float *x, float *work, int *lwork, int *info);
void dgglse_(int *m, int *n, int *p, double *a, int *lda, double *b, int *ldb, double *c, double *d, double *x, double *work, int *lwork, int *info);
void cgglse_(int *m, int *n, int *p, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *c, cfloat *d, cfloat *x, cfloat *work, int *lwork, int *info);
void zgglse_(int *m, int *n, int *p, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *c, cdouble *d, cdouble *x, cdouble *work, int *lwork, int *info);

/// Solves the GLM (Generalized Linear Regression Model) using
/// the GQR (Generalized QR) factorization
void sggglm_(int *n, int *m, int *p, float *a, int *lda, float *b, int *ldb, float *d, float *x, float *y, float *work, int *lwork, int *info);
void dggglm_(int *n, int *m, int *p, double *a, int *lda, double *b, int *ldb, double *d, double *x, double *y, double *work, int *lwork, int *info);
void cggglm_(int *n, int *m, int *p, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *d, cfloat *x, cfloat *y, cfloat *work, int *lwork, int *info);
void zggglm_(int *n, int *m, int *p, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *d, cdouble *x, cdouble *y, cdouble *work, int *lwork, int *info);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix.
void ssyev_(char *jobz, char *uplo, int *n, float *a, int *lda, float *w, float *work, int *lwork, int *info, int jobz_len, int uplo_len);
void dsyev_(char *jobz, char *uplo, int *n, double *a, int *lda, double *w, double *work, int *lwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix.
void cheev_(char *jobz, char *uplo, int *n, cfloat *a, int *lda, float *w, cfloat *work, int *lwork, float *rwork, int *info, int jobz_len, int uplo_len);
void zheev_(char *jobz, char *uplo, int *n, cdouble *a, int *lda, double *w, cdouble *work, int *lwork, double *rwork, int *info, int jobz_len, int uplo_len);


/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix.  If eigenvectors are desired, it uses a divide
/// and conquer algorithm.
void ssyevd_(char *jobz, char *uplo, int *n, float *a, int *lda, float *w, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void dsyevd_(char *jobz, char *uplo, int *n, double *a, int *lda, double *w, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix.  If eigenvectors are desired, it uses a divide
/// and conquer algorithm.
void cheevd_(char *jobz, char *uplo, int *n, cfloat *a, int *lda, float *w, cfloat *work, int *lwork, float *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void zheevd_(char *jobz, char *uplo, int *n, cdouble *a, int *lda, double *w, cdouble *work, int *lwork, double *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix in packed storage.
void sspev_(char *jobz, char *uplo, int *n, float *ap, float *w, float *z, int *ldz, float *work, int *info, int jobz_len, int uplo_len);
void dspev_(char *jobz, char *uplo, int *n, double *ap, double *w, double *z, int *ldz, double *work, int *info, int jobz_len, int uplo_len);

/// Computes selected eigenvalues, and optionally, eigenvectors of a complex
/// Hermitian matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix in packed storage.
void chpev_(char *jobz, char *uplo, int *n, cfloat *ap, float *w, cfloat *z, int *ldz, cfloat *work, float *rwork, int *info, int jobz_len, int uplo_len);
void zhpev_(char *jobz, char *uplo, int *n, cdouble *ap, double *w, cdouble *z, int *ldz, cdouble *work, double *rwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix in packed storage.  If eigenvectors are desired,
/// it uses a divide and conquer algorithm.
void sspevd_(char *jobz, char *uplo, int *n, float *ap, float *w, float *z, int *ldz, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void dspevd_(char *jobz, char *uplo, int *n, double *ap, double *w, double *z, int *ldz, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix in packed storage.  If eigenvectors are desired, it
/// uses a divide and conquer algorithm.
void chpevd_(char *jobz, char *uplo, int *n, cfloat *ap, float *w, cfloat *z, int *ldz, cfloat *work, int *lwork, float *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void zhpevd_(char *jobz, char *uplo, int *n, cdouble *ap, double *w, cdouble *z, int *ldz, cdouble *work, int *lwork, double *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric band matrix.
void ssbev_(char *jobz, char *uplo, int *n, int *kd, float *ab, int *ldab, float *w, float *z, int *ldz, float *work, int *info, int jobz_len, int uplo_len);
void dsbev_(char *jobz, char *uplo, int *n, int *kd, double *ab, int *ldab, double *w, double *z, int *ldz, double *work, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian band matrix.
void chbev_(char *jobz, char *uplo, int *n, int *kd, cfloat *ab, int *ldab, float *w, cfloat *z, int *ldz, cfloat *work, float *rwork, int *info, int jobz_len, int uplo_len);
void zhbev_(char *jobz, char *uplo, int *n, int *kd, cdouble *ab, int *ldab, double *w, cdouble *z, int *ldz, cdouble *work, double *rwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric band matrix.  If eigenvectors are desired, it uses a
/// divide and conquer algorithm.
void ssbevd_(char *jobz, char *uplo, int *n, int *kd, float *ab, int *ldab, float *w, float *z, int *ldz, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void dsbevd_(char *jobz, char *uplo, int *n, int *kd, double *ab, int *ldab, double *w, double *z, int *ldz, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian band matrix.  If eigenvectors are desired, it uses a divide
/// and conquer algorithm.
void chbevd_(char *jobz, char *uplo, int *n, int *kd, cfloat *ab, int *ldab, float *w, cfloat *z, int *ldz, cfloat *work, int *lwork, float *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void zhbevd_(char *jobz, char *uplo, int *n, int *kd, cdouble *ab, int *ldab, double *w, cdouble *z, int *ldz, cdouble *work, int *lwork, double *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric tridiagonal matrix.
void sstev_(char *jobz, int *n, float *d, float *e, float *z, int *ldz, float *work, int *info, int jobz_len);
void dstev_(char *jobz, int *n, double *d, double *e, double *z, int *ldz, double *work, int *info, int jobz_len);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric tridiagonal matrix.  If eigenvectors are desired, it uses
/// a divide and conquer algorithm.
void sstevd_(char *jobz, int *n, float *d, float *e, float *z, int *ldz, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len);
void dstevd_(char *jobz, int *n, double *d, double *e, double *z, int *ldz, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len);

/// Computes the eigenvalues and Schur factorization of a general
/// matrix, and orders the factorization so that selected eigenvalues
/// are at the top left of the Schur form.
void sgees_(char *jobvs, char *sort, FCB_SGEES_SELECT select, int *n, float *a, int *lda, int *sdim, float *wr, float *wi, float *vs, int *ldvs, float *work, int *lwork, int *bwork, int *info, int jobvs_len, int sort_len);
void dgees_(char *jobvs, char *sort, FCB_DGEES_SELECT select, int *n, double *a, int *lda, int *sdim, double *wr, double *wi, double *vs, int *ldvs, double *work, int *lwork, int *bwork, int *info, int jobvs_len, int sort_len);
void cgees_(char *jobvs, char *sort, FCB_CGEES_SELECT select, int *n, cfloat *a, int *lda, int *sdim, cfloat *w, cfloat *vs, int *ldvs, cfloat *work, int *lwork, float *rwork, int *bwork, int *info, int jobvs_len, int sort_len);
void zgees_(char *jobvs, char *sort, FCB_ZGEES_SELECT select, int *n, cdouble *a, int *lda, int *sdim, cdouble *w, cdouble *vs, int *ldvs, cdouble *work, int *lwork, double *rwork, int *bwork, int *info, int jobvs_len, int sort_len);

/// Computes the eigenvalues and left and right eigenvectors of
/// a general matrix.
void sgeev_(char *jobvl, char *jobvr, int *n, float *a, int *lda, float *wr, float *wi, float *vl, int *ldvl, float *vr, int *ldvr, float *work, int *lwork, int *info, int jobvl_len, int jobvr_len);
void dgeev_(char *jobvl, char *jobvr, int *n, double *a, int *lda, double *wr, double *wi, double *vl, int *ldvl, double *vr, int *ldvr, double *work, int *lwork, int *info, int jobvl_len, int jobvr_len);
void cgeev_(char *jobvl, char *jobvr, int *n, cfloat *a, int *lda, cfloat *w, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, cfloat *work, int *lwork, float *rwork, int *info, int jobvl_len, int jobvr_len);
void zgeev_(char *jobvl, char *jobvr, int *n, cdouble *a, int *lda, cdouble *w, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, cdouble *work, int *lwork, double *rwork, int *info, int jobvl_len, int jobvr_len);

/// Computes the singular value decomposition (SVD) of a general
/// rectangular matrix.
void sgesvd_(char *jobu, char *jobvt, int *m, int *n, float *a, int *lda, float *s, float *u, int *ldu, float *vt, int *ldvt, float *work, int *lwork, int *info, int jobu_len, int jobvt_len);
void dgesvd_(char *jobu, char *jobvt, int *m, int *n, double *a, int *lda, double *s, double *u, int *ldu, double *vt, int *ldvt, double *work, int *lwork, int *info, int jobu_len, int jobvt_len);
void cgesvd_(char *jobu, char *jobvt, int *m, int *n, cfloat *a, int *lda, float *s, cfloat *u, int *ldu, cfloat *vt, int *ldvt, cfloat *work, int *lwork, float *rwork, int *info, int jobu_len, int jobvt_len);
void zgesvd_(char *jobu, char *jobvt, int *m, int *n, cdouble *a, int *lda, double *s, cdouble *u, int *ldu, cdouble *vt, int *ldvt, cdouble *work, int *lwork, double *rwork, int *info, int jobu_len, int jobvt_len);

/// Computes the singular value decomposition (SVD) of a general
/// rectangular matrix using divide-and-conquer.
void sgesdd_(char *jobz, int *m, int *n, float *a, int *lda, float *s, float *u, int *ldu, float *vt, int *ldvt, float *work, int *lwork, int *iwork, int *info, int jobz_len);
void dgesdd_(char *jobz, int *m, int *n, double *a, int *lda, double *s, double *u, int *ldu, double *vt, int *ldvt, double *work, int *lwork, int *iwork, int *info, int jobz_len);
void cgesdd_(char *jobz, int *m, int *n, cfloat *a, int *lda, float *s, cfloat *u, int *ldu, cfloat *vt, int *ldvt, cfloat *work, int *lwork, float *rwork, int *iwork, int *info, int jobz_len);
void zgesdd_(char *jobz, int *m, int *n, cdouble *a, int *lda, double *s, cdouble *u, int *ldu, cdouble *vt, int *ldvt, cdouble *work, int *lwork, double *rwork, int *iwork, int *info, int jobz_len);

/// Computes all eigenvalues and the eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void ssygv_(int *itype, char *jobz, char *uplo, int *n, float *a, int *lda, float *b, int *ldb, float *w, float *work, int *lwork, int *info, int jobz_len, int uplo_len);
void dsygv_(int *itype, char *jobz, char *uplo, int *n, double *a, int *lda, double *b, int *ldb, double *w, double *work, int *lwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and the eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void chegv_(int *itype, char *jobz, char *uplo, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, float *w, cfloat *work, int *lwork, float *rwork, int *info, int jobz_len, int uplo_len);
void zhegv_(int *itype, char *jobz, char *uplo, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, double *w, cdouble *work, int *lwork, double *rwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and the eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void ssygvd_(int *itype, char *jobz, char *uplo, int *n, float *a, int *lda, float *b, int *ldb, float *w, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void dsygvd_(int *itype, char *jobz, char *uplo, int *n, double *a, int *lda, double *b, int *ldb, double *w, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
/// Computes all eigenvalues and the eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void chegvd_(int *itype, char *jobz, char *uplo, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, float *w, cfloat *work, int *lwork, float *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void zhegvd_(int *itype, char *jobz, char *uplo, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, double *w, cdouble *work, int *lwork, double *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void sspgv_(int *itype, char *jobz, char *uplo, int *n, float *ap, float *bp, float *w, float *z, int *ldz, float *work, int *info, int jobz_len, int uplo_len);
void dspgv_(int *itype, char *jobz, char *uplo, int *n, double *ap, double *bp, double *w, double *z, int *ldz, double *work, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void chpgv_(int *itype, char *jobz, char *uplo, int *n, cfloat *ap, cfloat *bp, float *w, cfloat *z, int *ldz, cfloat *work, float *rwork, int *info, int jobz_len, int uplo_len);
void zhpgv_(int *itype, char *jobz, char *uplo, int *n, cdouble *ap, cdouble *bp, double *w, cdouble *z, int *ldz, cdouble *work, double *rwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void sspgvd_(int *itype, char *jobz, char *uplo, int *n, float *ap, float *bp, float *w, float *z, int *ldz, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void dspgvd_(int *itype, char *jobz, char *uplo, int *n, double *ap, double *bp, double *w, double *z, int *ldz, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all eigenvalues and eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void chpgvd_(int *itype, char *jobz, char *uplo, int *n, cfloat *ap, cfloat *bp, float *w, cfloat *z, int *ldz, cfloat *work, int *lwork, float *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void zhpgvd_(int *itype, char *jobz, char *uplo, int *n, cdouble *ap, cdouble *bp, double *w, cdouble *z, int *ldz, cdouble *work, int *lwork, double *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a real generalized symmetric-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be symmetric
/// and banded, and B is also positive definite.
void ssbgv_(char *jobz, char *uplo, int *n, int *ka, int *kb, float *ab, int *ldab, float *bb, int *ldbb, float *w, float *z, int *ldz, float *work, int *info, int jobz_len, int uplo_len);
void dsbgv_(char *jobz, char *uplo, int *n, int *ka, int *kb, double *ab, int *ldab, double *bb, int *ldbb, double *w, double *z, int *ldz, double *work, int *info, int jobz_len, int uplo_len);

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a complex generalized Hermitian-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be Hermitian
/// and banded, and B is also positive definite.
void chbgv_(char *jobz, char *uplo, int *n, int *ka, int *kb, cfloat *ab, int *ldab, cfloat *bb, int *ldbb, float *w, cfloat *z, int *ldz, cfloat *work, float *rwork, int *info, int jobz_len, int uplo_len);
void zhbgv_(char *jobz, char *uplo, int *n, int *ka, int *kb, cdouble *ab, int *ldab, cdouble *bb, int *ldbb, double *w, cdouble *z, int *ldz, cdouble *work, double *rwork, int *info, int jobz_len, int uplo_len);

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a real generalized symmetric-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be symmetric
/// and banded, and B is also positive definite.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void ssbgvd_(char *jobz, char *uplo, int *n, int *ka, int *kb, float *ab, int *ldab, float *bb, int *ldbb, float *w, float *z, int *ldz, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void dsbgvd_(char *jobz, char *uplo, int *n, int *ka, int *kb, double *ab, int *ldab, double *bb, int *ldbb, double *w, double *z, int *ldz, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a complex generalized Hermitian-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be Hermitian
/// and banded, and B is also positive definite.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void chbgvd_(char *jobz, char *uplo, int *n, int *ka, int *kb, cfloat *ab, int *ldab, cfloat *bb, int *ldbb, float *w, cfloat *z, int *ldz, cfloat *work, int *lwork, float *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);
void zhbgvd_(char *jobz, char *uplo, int *n, int *ka, int *kb, cdouble *ab, int *ldab, cdouble *bb, int *ldbb, double *w, cdouble *z, int *ldz, cdouble *work, int *lwork, double *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int uplo_len);

/// Computes the generalized eigenvalues, Schur form, and left and/or
/// right Schur vectors for a pair of nonsymmetric matrices
void sgegs_(char *jobvsl, char *jobvsr, int *n, float *a, int *lda, float *b, int *ldb, float *alphar, float *alphai, float *betav, float *vsl, int *ldvsl, float *vsr, int *ldvsr, float *work, int *lwork, int *info, int jobvsl_len, int jobvsr_len);
void dgegs_(char *jobvsl, char *jobvsr, int *n, double *a, int *lda, double *b, int *ldb, double *alphar, double *alphai, double *betav, double *vsl, int *ldvsl, double *vsr, int *ldvsr, double *work, int *lwork, int *info, int jobvsl_len, int jobvsr_len);
void cgegs_(char *jobvsl, char *jobvsr, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *alphav, cfloat *betav, cfloat *vsl, int *ldvsl, cfloat *vsr, int *ldvsr, cfloat *work, int *lwork, float *rwork, int *info, int jobvsl_len, int jobvsr_len);
void zgegs_(char *jobvsl, char *jobvsr, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *alphav, cdouble *betav, cdouble *vsl, int *ldvsl, cdouble *vsr, int *ldvsr, cdouble *work, int *lwork, double *rwork, int *info, int jobvsl_len, int jobvsr_len);

/// Computes the generalized eigenvalues, Schur form, and left and/or
/// right Schur vectors for a pair of nonsymmetric matrices
void sgges_(char *jobvsl, char *jobvsr, char *sort, FCB_SGGES_SELCTG selctg, int *n, float *a, int *lda, float *b, int *ldb, int *sdim, float *alphar, float *alphai, float *betav, float *vsl, int *ldvsl, float *vsr, int *ldvsr, float *work, int *lwork, int *bwork, int *info, int jobvsl_len, int jobvsr_len, int sort_len);
void dgges_(char *jobvsl, char *jobvsr, char *sort, FCB_DGGES_DELCTG delctg, int *n, double *a, int *lda, double *b, int *ldb, int *sdim, double *alphar, double *alphai, double *betav, double *vsl, int *ldvsl, double *vsr, int *ldvsr, double *work, int *lwork, int *bwork, int *info, int jobvsl_len, int jobvsr_len, int sort_len);
void cgges_(char *jobvsl, char *jobvsr, char *sort, FCB_CGGES_SELCTG selctg, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, int *sdim, cfloat *alphav, cfloat *betav, cfloat *vsl, int *ldvsl, cfloat *vsr, int *ldvsr, cfloat *work, int *lwork, float *rwork, int *bwork, int *info, int jobvsl_len, int jobvsr_len, int sort_len);
void zgges_(char *jobvsl, char *jobvsr, char *sort, FCB_ZGGES_DELCTG delctg, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, int *sdim, cdouble *alphav, cdouble *betav, cdouble *vsl, int *ldvsl, cdouble *vsr, int *ldvsr, cdouble *work, int *lwork, double *rwork, int *bwork, int *info, int jobvsl_len, int jobvsr_len, int sort_len);

/// Computes the generalized eigenvalues, and left and/or right
/// generalized eigenvectors for a pair of nonsymmetric matrices
void sgegv_(char *jobvl, char *jobvr, int *n, float *a, int *lda, float *b, int *ldb, float *alphar, float *alphai, float *betav, float *vl, int *ldvl, float *vr, int *ldvr, float *work, int *lwork, int *info, int jobvl_len, int jobvr_len);
void dgegv_(char *jobvl, char *jobvr, int *n, double *a, int *lda, double *b, int *ldb, double *alphar, double *alphai, double *betav, double *vl, int *ldvl, double *vr, int *ldvr, double *work, int *lwork, int *info, int jobvl_len, int jobvr_len);
void cgegv_(char *jobvl, char *jobvr, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *alphar, cfloat *betav, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, cfloat *work, int *lwork, float *rwork, int *info, int jobvl_len, int jobvr_len);
void zgegv_(char *jobvl, char *jobvr, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *alphar, cdouble *betav, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, cdouble *work, int *lwork, double *rwork, int *info, int jobvl_len, int jobvr_len);

/// Computes the generalized eigenvalues, and left and/or right
/// generalized eigenvectors for a pair of nonsymmetric matrices
void sggev_(char *jobvl, char *jobvr, int *n, float *a, int *lda, float *b, int *ldb, float *alphar, float *alphai, float *betav, float *vl, int *ldvl, float *vr, int *ldvr, float *work, int *lwork, int *info, int jobvl_len, int jobvr_len);
void dggev_(char *jobvl, char *jobvr, int *n, double *a, int *lda, double *b, int *ldb, double *alphar, double *alphai, double *betav, double *vl, int *ldvl, double *vr, int *ldvr, double *work, int *lwork, int *info, int jobvl_len, int jobvr_len);
void cggev_(char *jobvl, char *jobvr, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *alphav, cfloat *betav, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, cfloat *work, int *lwork, float *rwork, int *info, int jobvl_len, int jobvr_len);
void zggev_(char *jobvl, char *jobvr, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *alphav, cdouble *betav, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, cdouble *work, int *lwork, double *rwork, int *info, int jobvl_len, int jobvr_len);

/// Computes the Generalized Singular Value Decomposition
void sggsvd_(char *jobu, char *jobv, char *jobq, int *m, int *n, int *p, int *k, int *l, float *a, int *lda, float *b, int *ldb, float *alphav, float *betav, float *u, int *ldu, float *v, int *ldv, float *q, int *ldq, float *work, int *iwork, int *info, int jobu_len, int jobv_len, int jobq_len);
void dggsvd_(char *jobu, char *jobv, char *jobq, int *m, int *n, int *p, int *k, int *l, double *a, int *lda, double *b, int *ldb, double *alphav, double *betav, double *u, int *ldu, double *v, int *ldv, double *q, int *ldq, double *work, int *iwork, int *info, int jobu_len, int jobv_len, int jobq_len);
void cggsvd_(char *jobu, char *jobv, char *jobq, int *m, int *n, int *p, int *k, int *l, cfloat *a, int *lda, cfloat *b, int *ldb, float *alphav, float *betav, cfloat *u, int *ldu, cfloat *v, int *ldv, cfloat *q, int *ldq, cfloat *work, float *rwork, int *iwork, int *info, int jobu_len, int jobv_len, int jobq_len);
void zggsvd_(char *jobu, char *jobv, char *jobq, int *m, int *n, int *p, int *k, int *l, cdouble *a, int *lda, cdouble *b, int *ldb, double *alphav, double *betav, cdouble *u, int *ldu, cdouble *v, int *ldv, cdouble *q, int *ldq, cdouble *work, double *rwork, int *iwork, int *info, int jobu_len, int jobv_len, int jobq_len);

//-----------------------------------------------------
//       ---- EXPERT and RRR DRIVER routines ----
//-----------------------------------------------------

/// Solves a general system of linear equations AX=B, A**T X=B
/// or A**H X=B, and provides an estimate of the condition number
/// and error bounds on the solution.
void sgesvx_(char *fact, char *trans, int *n, int *nrhs, float *a, int *lda, float *af, int *ldaf, int *ipiv, char *equed, float *r, float *c, float *b, int *ldb, float *x, int *ldx, float *rcond, float *ferr, float *berr, float *work, int *iwork, int *info, int fact_len, int trans_len, int equed_len);
void dgesvx_(char *fact, char *trans, int *n, int *nrhs, double *a, int *lda, double *af, int *ldaf, int *ipiv, char *equed, double *r, double *c, double *b, int *ldb, double *x, int *ldx, double *rcond, double *ferr, double *berr, double *work, int *iwork, int *info, int fact_len, int trans_len, int equed_len);
void cgesvx_(char *fact, char *trans, int *n, int *nrhs, cfloat *a, int *lda, cfloat *af, int *ldaf, int *ipiv, char *equed, float *r, float *c, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int fact_len, int trans_len, int equed_len);
void zgesvx_(char *fact, char *trans, int *n, int *nrhs, cdouble *a, int *lda, cdouble *af, int *ldaf, int *ipiv, char *equed, double *r, double *c, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int fact_len, int trans_len, int equed_len);

/// Solves a general banded system of linear equations AX=B,
/// A**T X=B or A**H X=B, and provides an estimate of the condition
/// number and error bounds on the solution.
void sgbsvx_(char *fact, char *trans, int *n, int *kl, int *ku, int *nrhs, float *ab, int *ldab, float *afb, int *ldafb, int *ipiv, char *equed, float *r, float *c, float *b, int *ldb, float *x, int *ldx, float *rcond, float *ferr, float *berr, float *work, int *iwork, int *info, int fact_len, int trans_len, int equed_len);
void dgbsvx_(char *fact, char *trans, int *n, int *kl, int *ku, int *nrhs, double *ab, int *ldab, double *afb, int *ldafb, int *ipiv, char *equed, double *r, double *c, double *b, int *ldb, double *x, int *ldx, double *rcond, double *ferr, double *berr, double *work, int *iwork, int *info, int fact_len, int trans_len, int equed_len);
void cgbsvx_(char *fact, char *trans, int *n, int *kl, int *ku, int *nrhs, cfloat *ab, int *ldab, cfloat *afb, int *ldafb, int *ipiv, char *equed, float *r, float *c, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int fact_len, int trans_len, int equed_len);
void zgbsvx_(char *fact, char *trans, int *n, int *kl, int *ku, int *nrhs, cdouble *ab, int *ldab, cdouble *afb, int *ldafb, int *ipiv, char *equed, double *r, double *c, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int fact_len, int trans_len, int equed_len);

/// Solves a general tridiagonal system of linear equations AX=B,
/// A**T X=B or A**H X=B, and provides an estimate of the condition
/// number  and error bounds on the solution.
void sgtsvx_(char *fact, char *trans, int *n, int *nrhs, float *dl, float *d, float *du, float *dlf, float *df, float *duf, float *du2, int *ipiv, float *b, int *ldb, float *x, int *ldx, float *rcond, float *ferr, float *berr, float *work, int *iwork, int *info, int fact_len, int trans_len);
void dgtsvx_(char *fact, char *trans, int *n, int *nrhs, double *dl, double *d, double *du, double *dlf, double *df, double *duf, double *du2, int *ipiv, double *b, int *ldb, double *x, int *ldx, double *rcond, double *ferr, double *berr, double *work, int *iwork, int *info, int fact_len, int trans_len);
void cgtsvx_(char *fact, char *trans, int *n, int *nrhs, cfloat *dl, cfloat *d, cfloat *du, cfloat *dlf, cfloat *df, cfloat *duf, cfloat *du2, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int fact_len, int trans_len);
void zgtsvx_(char *fact, char *trans, int *n, int *nrhs, cdouble *dl, cdouble *d, cdouble *du, cdouble *dlf, cdouble *df, cdouble *duf, cdouble *du2, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int fact_len, int trans_len);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, and provides an estimate of the condition number
/// and error bounds on the solution.
void sposvx_(char *fact, char *uplo, int *n, int *nrhs, float *a, int *lda, float *af, int *ldaf, char *equed, float *s, float *b, int *ldb, float *x, int *ldx, float *rcond, float *ferr, float *berr, float *work, int *iwork, int *info, int fact_len, int uplo_len, int equed_len);
void dposvx_(char *fact, char *uplo, int *n, int *nrhs, double *a, int *lda, double *af, int *ldaf, char *equed, double *s, double *b, int *ldb, double *x, int *ldx, double *rcond, double *ferr, double *berr, double *work, int *iwork, int *info, int fact_len, int uplo_len, int equed_len);
void cposvx_(char *fact, char *uplo, int *n, int *nrhs, cfloat *a, int *lda, cfloat *af, int *ldaf, char *equed, float *s, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int fact_len, int uplo_len, int equed_len);
void zposvx_(char *fact, char *uplo, int *n, int *nrhs, cdouble *a, int *lda, cdouble *af, int *ldaf, char *equed, double *s, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int fact_len, int uplo_len, int equed_len);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, where A is held in packed storage, and provides
/// an estimate of the condition number and error bounds on the
/// solution.
void sppsvx_(char *fact, char *uplo, int *n, int *nrhs, float *ap, float *afp, char *equed, float *s, float *b, int *ldb, float *x, int *ldx, float *rcond, float *ferr, float *berr, float *work, int *iwork, int *info, int fact_len, int uplo_len, int equed_len);
void dppsvx_(char *fact, char *uplo, int *n, int *nrhs, double *ap, double *afp, char *equed, double *s, double *b, int *ldb, double *x, int *ldx, double *rcond, double *ferr, double *berr, double *work, int *iwork, int *info, int fact_len, int uplo_len, int equed_len);
void cppsvx_(char *fact, char *uplo, int *n, int *nrhs, cfloat *ap, cfloat *afp, char *equed, float *s, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int fact_len, int uplo_len, int equed_len);
void zppsvx_(char *fact, char *uplo, int *n, int *nrhs, cdouble *ap, cdouble *afp, char *equed, double *s, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int fact_len, int uplo_len, int equed_len);

/// Solves a symmetric positive definite banded system
/// of linear equations AX=B, and provides an estimate of the condition
/// number and error bounds on the solution.
void spbsvx_(char *fact, char *uplo, int *n, int *kd, int *nrhs, float *ab, int *ldab, float *afb, int *ldafb, char *equed, float *s, float *b, int *ldb, float *x, int *ldx, float *rcond, float *ferr, float *berr, float *work, int *iwork, int *info, int fact_len, int uplo_len, int equed_len);
void dpbsvx_(char *fact, char *uplo, int *n, int *kd, int *nrhs, double *ab, int *ldab, double *afb, int *ldafb, char *equed, double *s, double *b, int *ldb, double *x, int *ldx, double *rcond, double *ferr, double *berr, double *work, int *iwork, int *info, int fact_len, int uplo_len, int equed_len);
void cpbsvx_(char *fact, char *uplo, int *n, int *kd, int *nrhs, cfloat *ab, int *ldab, cfloat *afb, int *ldafb, char *equed, float *s, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int fact_len, int uplo_len, int equed_len);
void zpbsvx_(char *fact, char *uplo, int *n, int *kd, int *nrhs, cdouble *ab, int *ldab, cdouble *afb, int *ldafb, char *equed, double *s, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int fact_len, int uplo_len, int equed_len);

/// Solves a symmetric positive definite tridiagonal
/// system of linear equations AX=B, and provides an estimate of
/// the condition number and error bounds on the solution.
void sptsvx_(char *fact, int *n, int *nrhs, float *d, float *e, float *df, float *ef, float *b, int *ldb, float *x, int *ldx, float *rcond, float *ferr, float *berr, float *work, int *info, int fact_len);
void dptsvx_(char *fact, int *n, int *nrhs, double *d, double *e, double *df, double *ef, double *b, int *ldb, double *x, int *ldx, double *rcond, double *ferr, double *berr, double *work, int *info, int fact_len);
void cptsvx_(char *fact, int *n, int *nrhs, float *d, cfloat *e, float *df, cfloat *ef, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int fact_len);
void zptsvx_(char *fact, int *n, int *nrhs, double *d, cdouble *e, double *df, cdouble *ef, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int fact_len);

/// Solves a real symmetric
/// indefinite system  of linear equations AX=B, and provides an
/// estimate of the condition number and error bounds on the solution.
void ssysvx_(char *fact, char *uplo, int *n, int *nrhs, float *a, int *lda, float *af, int *ldaf, int *ipiv, float *b, int *ldb, float *x, int *ldx, float *rcond, float *ferr, float *berr, float *work, int *lwork, int *iwork, int *info, int fact_len, int uplo_len);
void dsysvx_(char *fact, char *uplo, int *n, int *nrhs, double *a, int *lda, double *af, int *ldaf, int *ipiv, double *b, int *ldb, double *x, int *ldx, double *rcond, double *ferr, double *berr, double *work, int *lwork, int *iwork, int *info, int fact_len, int uplo_len);
void csysvx_(char *fact, char *uplo, int *n, int *nrhs, cfloat *a, int *lda, cfloat *af, int *ldaf, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, int *lwork, float *rwork, int *info, int fact_len, int uplo_len);
void zsysvx_(char *fact, char *uplo, int *n, int *nrhs, cdouble *a, int *lda, cdouble *af, int *ldaf, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, int *lwork, double *rwork, int *info, int fact_len, int uplo_len);

/// Solves a complex Hermitian
/// indefinite system  of linear equations AX=B, and provides an
/// estimate of the condition number and error bounds on the solution.
void chesvx_(char *fact, char *uplo, int *n, int *nrhs, cfloat *a, int *lda, cfloat *af, int *ldaf, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, int *lwork, float *rwork, int *info, int fact_len, int uplo_len);
void zhesvx_(char *fact, char *uplo, int *n, int *nrhs, cdouble *a, int *lda, cdouble *af, int *ldaf, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, int *lwork, double *rwork, int *info, int fact_len, int uplo_len);

/// Solves a real symmetric
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, and provides an estimate of the condition
/// number and error bounds on the solution.
void sspsvx_(char *fact, char *uplo, int *n, int *nrhs, float *ap, float *afp, int *ipiv, float *b, int *ldb, float *x, int *ldx, float *rcond, float *ferr, float *berr, float *work, int *iwork, int *info, int fact_len, int uplo_len);
void dspsvx_(char *fact, char *uplo, int *n, int *nrhs, double *ap, double *afp, int *ipiv, double *b, int *ldb, double *x, int *ldx, double *rcond, double *ferr, double *berr, double *work, int *iwork, int *info, int fact_len, int uplo_len);
void cspsvx_(char *fact, char *uplo, int *n, int *nrhs, cfloat *ap, cfloat *afp, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int fact_len, int uplo_len);
void zspsvx_(char *fact, char *uplo, int *n, int *nrhs, cdouble *ap, cdouble *afp, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int fact_len, int uplo_len);

/// Solves a complex Hermitian
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, and provides an estimate of the condition
/// number and error bounds on the solution.
void chpsvx_(char *fact, char *uplo, int *n, int *nrhs, cfloat *ap, cfloat *afp, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *rcond, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int fact_len, int uplo_len);
void zhpsvx_(char *fact, char *uplo, int *n, int *nrhs, cdouble *ap, cdouble *afp, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *rcond, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int fact_len, int uplo_len);

/// Computes the minimum norm least squares solution to an over-
/// or under-determined system of linear equations A X=B, using a
/// complete orthogonal factorization of A.
void sgelsx_(int *m, int *n, int *nrhs, float *a, int *lda, float *b, int *ldb, int *jpvt, float *rcond, int *rank, float *work, int *info);
void dgelsx_(int *m, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, int *jpvt, double *rcond, int *rank, double *work, int *info);
void cgelsx_(int *m, int *n, int *nrhs, cfloat *a, int *lda, cfloat *b, int *ldb, int *jpvt, float *rcond, int *rank, cfloat *work, float *rwork, int *info);
void zgelsx_(int *m, int *n, int *nrhs, cdouble *a, int *lda, cdouble *b, int *ldb, int *jpvt, double *rcond, int *rank, cdouble *work, double *rwork, int *info);

/// Computes the minimum norm least squares solution to an over-
/// or under-determined system of linear equations A X=B, using a
/// complete orthogonal factorization of A.
void sgelsy_(int *m, int *n, int *nrhs, float *a, int *lda, float *b, int *ldb, int *jpvt, float *rcond, int *rank, float *work, int *lwork, int *info);
void dgelsy_(int *m, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, int *jpvt, double *rcond, int *rank, double *work, int *lwork, int *info);
void cgelsy_(int *m, int *n, int *nrhs, cfloat *a, int *lda, cfloat *b, int *ldb, int *jpvt, float *rcond, int *rank, cfloat *work, int *lwork, float *rwork, int *info);
void zgelsy_(int *m, int *n, int *nrhs, cdouble *a, int *lda, cdouble *b, int *ldb, int *jpvt, double *rcond, int *rank, cdouble *work, int *lwork, double *rwork, int *info);

/// Computes the minimum norm least squares solution to an over-
/// or under-determined system of linear equations A X=B,  using
/// the singular value decomposition of A.
void sgelss_(int *m, int *n, int *nrhs, float *a, int *lda, float *b, int *ldb, float *s, float *rcond, int *rank, float *work, int *lwork, int *info);
void dgelss_(int *m, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, double *s, double *rcond, int *rank, double *work, int *lwork, int *info);
void cgelss_(int *m, int *n, int *nrhs, cfloat *a, int *lda, cfloat *b, int *ldb, float *s, float *rcond, int *rank, cfloat *work, int *lwork, float *rwork, int *info);
void zgelss_(int *m, int *n, int *nrhs, cdouble *a, int *lda, cdouble *b, int *ldb, double *s, double *rcond, int *rank, cdouble *work, int *lwork, double *rwork, int *info);

/// Computes selected eigenvalues and eigenvectors of a symmetric matrix.
void ssyevx_(char *jobz, char *range, char *uplo, int *n, float *a, int *lda, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, float *work, int *lwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void dsyevx_(char *jobz, char *range, char *uplo, int *n, double *a, int *lda, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, double *work, int *lwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues and eigenvectors of a Hermitian matrix.
void cheevx_(char *jobz, char *range, char *uplo, int *n, cfloat *a, int *lda, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, cfloat *z, int *ldz, cfloat *work, int *lwork, float *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void zheevx_(char *jobz, char *range, char *uplo, int *n, cdouble *a, int *lda, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, cdouble *z, int *ldz, cdouble *work, int *lwork, double *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
void ssyevr_(char *jobz, char *range, char *uplo, int *n, float *a, int *lda, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, int *isuppz, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len, int uplo_len);
void dsyevr_(char *jobz, char *range, char *uplo, int *n, double *a, int *lda, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, int *isuppz, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues, and optionally, eigenvectors of a complex
/// Hermitian matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
void cheevr_(char *jobz, char *range, char *uplo, int *n, cfloat *a, int *lda, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, cfloat *z, int *ldz, int *isuppz, cfloat *work, int *lwork, float *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len, int uplo_len);
void zheevr_(char *jobz, char *range, char *uplo, int *n, cdouble *a, int *lda, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, cdouble *z, int *ldz, int *isuppz, cdouble *work, int *lwork, double *rwork, int *lrwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len, int uplo_len);


/// Computes selected eigenvalues, and optionally, the eigenvectors of
/// a generalized symmetric-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void ssygvx_(int *itype, char *jobz, char *range, char *uplo, int *n, float *a, int *lda, float *b, int *ldb, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, float *work, int *lwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void dsygvx_(int *itype, char *jobz, char *range, char *uplo, int *n, double *a, int *lda, double *b, int *ldb, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, double *work, int *lwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues, and optionally, the eigenvectors of
/// a generalized Hermitian-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void chegvx_(int *itype, char *jobz, char *range, char *uplo, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, cfloat *z, int *ldz, cfloat *work, int *lwork, float *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void zhegvx_(int *itype, char *jobz, char *range, char *uplo, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, cdouble *z, int *ldz, cdouble *work, int *lwork, double *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues and eigenvectors of a
/// symmetric matrix in packed storage.
void sspevx_(char *jobz, char *range, char *uplo, int *n, float *ap, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, float *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void dspevx_(char *jobz, char *range, char *uplo, int *n, double *ap, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, double *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues and eigenvectors of a
/// Hermitian matrix in packed storage.
void chpevx_(char *jobz, char *range, char *uplo, int *n, cfloat *ap, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, cfloat *z, int *ldz, cfloat *work, float *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void zhpevx_(char *jobz, char *range, char *uplo, int *n, cdouble *ap, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, cdouble *z, int *ldz, cdouble *work, double *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues, and optionally, eigenvectors of
/// a generalized symmetric-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void sspgvx_(int *itype, char *jobz, char *range, char *uplo, int *n, float *ap, float *bp, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, float *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void dspgvx_(int *itype, char *jobz, char *range, char *uplo, int *n, double *ap, double *bp, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, double *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues, and optionally, the eigenvectors of
/// a generalized Hermitian-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void chpgvx_(int *itype, char *jobz, char *range, char *uplo, int *n, cfloat *ap, cfloat *bp, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, cfloat *z, int *ldz, cfloat *work, float *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void zhpgvx_(int *itype, char *jobz, char *range, char *uplo, int *n, cdouble *ap, cdouble *bp, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, cdouble *z, int *ldz, cdouble *work, double *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues and eigenvectors of a
/// symmetric band matrix.
void ssbevx_(char *jobz, char *range, char *uplo, int *n, int *kd, float *ab, int *ldab, float *q, int *ldq, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, float *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void dsbevx_(char *jobz, char *range, char *uplo, int *n, int *kd, double *ab, int *ldab, double *q, int *ldq, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, double *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues and eigenvectors of a
/// Hermitian band matrix.
void chbevx_(char *jobz, char *range, char *uplo, int *n, int *kd, cfloat *ab, int *ldab, cfloat *q, int *ldq, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, cfloat *z, int *ldz, cfloat *work, float *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void zhbevx_(char *jobz, char *range, char *uplo, int *n, int *kd, cdouble *ab, int *ldab, cdouble *q, int *ldq, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, cdouble *z, int *ldz, cdouble *work, double *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues, and optionally, the eigenvectors
/// of a real generalized symmetric-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be symmetric
/// and banded, and B is also positive definite.
void ssbgvx_(char *jobz, char *range, char *uplo, int *n, int *ka, int *kb, float *ab, int *ldab, float *bb, int *ldbb, float *q, int *ldq, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, float *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void dsbgvx_(char *jobz, char *range, char *uplo, int *n, int *ka, int *kb, double *ab, int *ldab, double *bb, int *ldbb, double *q, int *ldq, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, double *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues, and optionally, the eigenvectors
/// of a complex generalized Hermitian-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be Hermitian
/// and banded, and B is also positive definite.
void chbgvx_(char *jobz, char *range, char *uplo, int *n, int *ka, int *kb, cfloat *ab, int *ldab, cfloat *bb, int *ldbb, cfloat *q, int *ldq, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, cfloat *z, int *ldz, cfloat *work, float *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);
void zhbgvx_(char *jobz, char *range, char *uplo, int *n, int *ka, int *kb, cdouble *ab, int *ldab, cdouble *bb, int *ldbb, cdouble *q, int *ldq, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, cdouble *z, int *ldz, cdouble *work, double *rwork, int *iwork, int *ifail, int *info, int jobz_len, int range_len, int uplo_len);

/// Computes selected eigenvalues and eigenvectors of a real
/// symmetric tridiagonal matrix.
void sstevx_(char *jobz, char *range, int *n, float *d, float *e, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, float *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len);
void dstevx_(char *jobz, char *range, int *n, double *d, double *e, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, double *work, int *iwork, int *ifail, int *info, int jobz_len, int range_len);

/// Computes selected eigenvalues, and optionally, eigenvectors of a real
/// symmetric tridiagonal matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
void sstevr_(char *jobz, char *range, int *n, float *d, float *e, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, int *isuppz, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len);
void dstevr_(char *jobz, char *range, int *n, double *d, double *e, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, int *isuppz, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len);

/// Computes the eigenvalues and Schur factorization of a general
/// matrix, orders the factorization so that selected eigenvalues
/// are at the top left of the Schur form, and computes reciprocal
/// condition numbers for the average of the selected eigenvalues,
/// and for the associated right invariant subspace.
void sgeesx_(char *jobvs, char *sort, FCB_SGEESX_SELECT select, char *sense, int *n, float *a, int *lda, int *sdim, float *wr, float *wi, float *vs, int *ldvs, float *rconde, float *rcondv, float *work, int *lwork, int *iwork, int *liwork, int *bwork, int *info, int jobvs_len, int sort_len, int sense_len);
void dgeesx_(char *jobvs, char *sort, FCB_DGEESX_SELECT select, char *sense, int *n, double *a, int *lda, int *sdim, double *wr, double *wi, double *vs, int *ldvs, double *rconde, double *rcondv, double *work, int *lwork, int *iwork, int *liwork, int *bwork, int *info, int jobvs_len, int sort_len, int sense_len);
void cgeesx_(char *jobvs, char *sort, FCB_CGEESX_SELECT select, char *sense, int *n, cfloat *a, int *lda, int *sdim, cfloat *w, cfloat *vs, int *ldvs, float *rconde, float *rcondv, cfloat *work, int *lwork, float *rwork, int *bwork, int *info, int jobvs_len, int sort_len, int sense_len);
void zgeesx_(char *jobvs, char *sort, FCB_ZGEESX_SELECT select, char *sense, int *n, cdouble *a, int *lda, int *sdim, cdouble *w, cdouble *vs, int *ldvs, double *rconde, double *rcondv, cdouble *work, int *lwork, double *rwork, int *bwork, int *info, int jobvs_len, int sort_len, int sense_len);

/// Computes the generalized eigenvalues, the real Schur form, and,
/// optionally, the left and/or right matrices of Schur vectors.
void sggesx_(char *jobvsl, char *jobvsr, char *sort, FCB_SGGESX_SELCTG selctg, char *sense, int *n, float *a, int *lda, float *b, int *ldb, int *sdim, float *alphar, float *alphai, float *betav, float *vsl, int *ldvsl, float *vsr, int *ldvsr, float *rconde, float *rcondv, float *work, int *lwork, int *iwork, int *liwork, int *bwork, int *info, int jobvsl_len, int jobvsr_len, int sort_len, int sense_len);
void dggesx_(char *jobvsl, char *jobvsr, char *sort, FCB_DGGESX_DELCTG delctg, char *sense, int *n, double *a, int *lda, double *b, int *ldb, int *sdim, double *alphar, double *alphai, double *betav, double *vsl, int *ldvsl, double *vsr, int *ldvsr, double *rconde, double *rcondv, double *work, int *lwork, int *iwork, int *liwork, int *bwork, int *info, int jobvsl_len, int jobvsr_len, int sort_len, int sense_len);
void cggesx_(char *jobvsl, char *jobvsr, char *sort, FCB_CGGESX_SELCTG selctg, char *sense, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, int *sdim, cfloat *alphav, cfloat *betav, cfloat *vsl, int *ldvsl, cfloat *vsr, int *ldvsr, float *rconde, float *rcondv, cfloat *work, int *lwork, float *rwork, int *iwork, int *liwork, int *bwork, int *info, int jobvsl_len, int jobvsr_len, int sort_len, int sense_len);
void zggesx_(char *jobvsl, char *jobvsr, char *sort, FCB_ZGGESX_DELCTG delctg, char *sense, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, int *sdim, cdouble *alphav, cdouble *betav, cdouble *vsl, int *ldvsl, cdouble *vsr, int *ldvsr, double *rconde, double *rcondv, cdouble *work, int *lwork, double *rwork, int *iwork, int *liwork, int *bwork, int *info, int jobvsl_len, int jobvsr_len, int sort_len, int sense_len);

/// Computes the eigenvalues and left and right eigenvectors of
/// a general matrix,  with preliminary balancing of the matrix,
/// and computes reciprocal condition numbers for the eigenvalues
/// and right eigenvectors.
void sgeevx_(char *balanc, char *jobvl, char *jobvr, char *sense, int *n, float *a, int *lda, float *wr, float *wi, float *vl, int *ldvl, float *vr, int *ldvr, int *ilo, int *ihi, float *scale, float *abnrm, float *rconde, float *rcondv, float *work, int *lwork, int *iwork, int *info, int balanc_len, int jobvl_len, int jobvr_len, int sense_len);
void dgeevx_(char *balanc, char *jobvl, char *jobvr, char *sense, int *n, double *a, int *lda, double *wr, double *wi, double *vl, int *ldvl, double *vr, int *ldvr, int *ilo, int *ihi, double *scale, double *abnrm, double *rconde, double *rcondv, double *work, int *lwork, int *iwork, int *info, int balanc_len, int jobvl_len, int jobvr_len, int sense_len);
void cgeevx_(char *balanc, char *jobvl, char *jobvr, char *sense, int *n, cfloat *a, int *lda, cfloat *w, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, int *ilo, int *ihi, float *scale, float *abnrm, float *rconde, float *rcondv, cfloat *work, int *lwork, float *rwork, int *info, int balanc_len, int jobvl_len, int jobvr_len, int sense_len);
void zgeevx_(char *balanc, char *jobvl, char *jobvr, char *sense, int *n, cdouble *a, int *lda, cdouble *w, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, int *ilo, int *ihi, double *scale, double *abnrm, double *rconde, double *rcondv, cdouble *work, int *lwork, double *rwork, int *info, int balanc_len, int jobvl_len, int jobvr_len, int sense_len);

/// Computes the generalized eigenvalues, and optionally, the left
/// and/or right generalized eigenvectors.
void sggevx_(char *balanc, char *jobvl, char *jobvr, char *sense, int *n, float *a, int *lda, float *b, int *ldb, float *alphar, float *alphai, float *betav, float *vl, int *ldvl, float *vr, int *ldvr, int *ilo, int *ihi, float *lscale, float *rscale, float *abnrm, float *bbnrm, float *rconde, float *rcondv, float *work, int *lwork, int *iwork, int *bwork, int *info, int balanc_len, int jobvl_len, int jobvr_len, int sense_len);
void dggevx_(char *balanc, char *jobvl, char *jobvr, char *sense, int *n, double *a, int *lda, double *b, int *ldb, double *alphar, double *alphai, double *betav, double *vl, int *ldvl, double *vr, int *ldvr, int *ilo, int *ihi, double *lscale, double *rscale, double *abnrm, double *bbnrm, double *rconde, double *rcondv, double *work, int *lwork, int *iwork, int *bwork, int *info, int balanc_len, int jobvl_len, int jobvr_len, int sense_len);
void cggevx_(char *balanc, char *jobvl, char *jobvr, char *sense, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *alphav, cfloat *betav, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, int *ilo, int *ihi, float *lscale, float *rscale, float *abnrm, float *bbnrm, float *rconde, float *rcondv, cfloat *work, int *lwork, float *rwork, int *iwork, int *bwork, int *info, int balanc_len, int jobvl_len, int jobvr_len, int sense_len);
void zggevx_(char *balanc, char *jobvl, char *jobvr, char *sense, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *alphav, cdouble *betav, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, int *ilo, int *ihi, double *lscale, double *rscale, double *abnrm, double *bbnrm, double *rconde, double *rcondv, cdouble *work, int *lwork, double *rwork, int *iwork, int *bwork, int *info, int balanc_len, int jobvl_len, int jobvr_len, int sense_len);



//----------------------------------------
//    ---- COMPUTATIONAL routines ----
//----------------------------------------


/// Computes the singular value decomposition (SVD) of a real bidiagonal
/// matrix, using a divide and conquer method.
void sbdsdc_(char *uplo, char *compq, int *n, float *d, float *e, float *u, int *ldu, float *vt, int *ldvt, float *q, int *iq, float *work, int *iwork, int *info, int uplo_len, int compq_len);
void dbdsdc_(char *uplo, char *compq, int *n, double *d, double *e, double *u, int *ldu, double *vt, int *ldvt, double *q, int *iq, double *work, int *iwork, int *info, int uplo_len, int compq_len);

/// Computes the singular value decomposition (SVD) of a real bidiagonal
/// matrix, using the bidiagonal QR algorithm.
void sbdsqr_(char *uplo, int *n, int *ncvt, int *nru, int *ncc, float *d, float *e, float *vt, int *ldvt, float *u, int *ldu, float *c, int *ldc, float *work, int *info, int uplo_len);
void dbdsqr_(char *uplo, int *n, int *ncvt, int *nru, int *ncc, double *d, double *e, double *vt, int *ldvt, double *u, int *ldu, double *c, int *ldc, double *work, int *info, int uplo_len);
void cbdsqr_(char *uplo, int *n, int *ncvt, int *nru, int *ncc, float *d, float *e, cfloat *vt, int *ldvt, cfloat *u, int *ldu, cfloat *c, int *ldc, float *rwork, int *info, int uplo_len);
void zbdsqr_(char *uplo, int *n, int *ncvt, int *nru, int *ncc, double *d, double *e, cdouble *vt, int *ldvt, cdouble *u, int *ldu, cdouble *c, int *ldc, double *rwork, int *info, int uplo_len);

/// Computes the reciprocal condition numbers for the eigenvectors of a
/// real symmetric or complex Hermitian matrix or for the left or right
/// singular vectors of a general matrix.
void sdisna_(char *job, int *m, int *n, float *d, float *sep, int *info, int job_len);
void ddisna_(char *job, int *m, int *n, double *d, double *sep, int *info, int job_len);

/// Reduces a general band matrix to real upper bidiagonal form
/// by an orthogonal transformation.
void sgbbrd_(char *vect, int *m, int *n, int *ncc, int *kl, int *ku, float *ab, int *ldab, float *d, float *e, float *q, int *ldq, float *pt, int *ldpt, float *c, int *ldc, float *work, int *info, int vect_len);
void dgbbrd_(char *vect, int *m, int *n, int *ncc, int *kl, int *ku, double *ab, int *ldab, double *d, double *e, double *q, int *ldq, double *pt, int *ldpt, double *c, int *ldc, double *work, int *info, int vect_len);
void cgbbrd_(char *vect, int *m, int *n, int *ncc, int *kl, int *ku, cfloat *ab, int *ldab, float *d, float *e, cfloat *q, int *ldq, cfloat *pt, int *ldpt, cfloat *c, int *ldc, cfloat *work, float *rwork, int *info, int vect_len);
void zgbbrd_(char *vect, int *m, int *n, int *ncc, int *kl, int *ku, cdouble *ab, int *ldab, double *d, double *e, cdouble *q, int *ldq, cdouble *pt, int *ldpt, cdouble *c, int *ldc, cdouble *work, double *rwork, int *info, int vect_len);

/// Estimates the reciprocal of the condition number of a general
/// band matrix, in either the 1-norm or the infinity-norm, using
/// the LU factorization computed by SGBTRF.
void sgbcon_(char *norm, int *n, int *kl, int *ku, float *ab, int *ldab, int *ipiv, float *anorm, float *rcond, float *work, int *iwork, int *info, int norm_len);
void dgbcon_(char *norm, int *n, int *kl, int *ku, double *ab, int *ldab, int *ipiv, double *anorm, double *rcond, double *work, int *iwork, int *info, int norm_len);
void cgbcon_(char *norm, int *n, int *kl, int *ku, cfloat *ab, int *ldab, int *ipiv, float *anorm, float *rcond, cfloat *work, float *rwork, int *info, int norm_len);
void zgbcon_(char *norm, int *n, int *kl, int *ku, cdouble *ab, int *ldab, int *ipiv, double *anorm, double *rcond, cdouble *work, double *rwork, int *info, int norm_len);

/// Computes row and column scalings to equilibrate a general band
/// matrix and reduce its condition number.
void sgbequ_(int *m, int *n, int *kl, int *ku, float *ab, int *ldab, float *r, float *c, float *rowcnd, float *colcnd, float *amax, int *info);
void dgbequ_(int *m, int *n, int *kl, int *ku, double *ab, int *ldab, double *r, double *c, double *rowcnd, double *colcnd, double *amax, int *info);
void cgbequ_(int *m, int *n, int *kl, int *ku, cfloat *ab, int *ldab, float *r, float *c, float *rowcnd, float *colcnd, float *amax, int *info);
void zgbequ_(int *m, int *n, int *kl, int *ku, cdouble *ab, int *ldab, double *r, double *c, double *rowcnd, double *colcnd, double *amax, int *info);

/// Improves the computed solution to a general banded system of
/// linear equations AX=B, A**T X=B or A**H X=B, and provides forward
/// and backward error bounds for the solution.
void sgbrfs_(char *trans, int *n, int *kl, int *ku, int *nrhs, float *ab, int *ldab, float *afb, int *ldafb, int *ipiv, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int trans_len);
void dgbrfs_(char *trans, int *n, int *kl, int *ku, int *nrhs, double *ab, int *ldab, double *afb, int *ldafb, int *ipiv, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int trans_len);
void cgbrfs_(char *trans, int *n, int *kl, int *ku, int *nrhs, cfloat *ab, int *ldab, cfloat *afb, int *ldafb, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int trans_len);
void zgbrfs_(char *trans, int *n, int *kl, int *ku, int *nrhs, cdouble *ab, int *ldab, cdouble *afb, int *ldafb, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int trans_len);

/// Computes an LU factorization of a general band matrix, using
/// partial pivoting with row interchanges.
void sgbtrf_(int *m, int *n, int *kl, int *ku, float *ab, int *ldab, int *ipiv, int *info);
void dgbtrf_(int *m, int *n, int *kl, int *ku, double *ab, int *ldab, int *ipiv, int *info);
void cgbtrf_(int *m, int *n, int *kl, int *ku, cfloat *ab, int *ldab, int *ipiv, int *info);
void zgbtrf_(int *m, int *n, int *kl, int *ku, cdouble *ab, int *ldab, int *ipiv, int *info);

/// Solves a general banded system of linear equations AX=B,
/// A**T X=B or A**H X=B, using the LU factorization computed
/// by SGBTRF.
void sgbtrs_(char *trans, int *n, int *kl, int *ku, int *nrhs, float *ab, int *ldab, int *ipiv, float *b, int *ldb, int *info, int trans_len);
void dgbtrs_(char *trans, int *n, int *kl, int *ku, int *nrhs, double *ab, int *ldab, int *ipiv, double *b, int *ldb, int *info, int trans_len);
void cgbtrs_(char *trans, int *n, int *kl, int *ku, int *nrhs, cfloat *ab, int *ldab, int *ipiv, cfloat *b, int *ldb, int *info, int trans_len);
void zgbtrs_(char *trans, int *n, int *kl, int *ku, int *nrhs, cdouble *ab, int *ldab, int *ipiv, cdouble *b, int *ldb, int *info, int trans_len);

/// Transforms eigenvectors of a balanced matrix to those of the
/// original matrix supplied to SGEBAL.
void sgebak_(char *job, char *side, int *n, int *ilo, int *ihi, float *scale, int *m, float *v, int *ldv, int *info, int job_len, int side_len);
void dgebak_(char *job, char *side, int *n, int *ilo, int *ihi, double *scale, int *m, double *v, int *ldv, int *info, int job_len, int side_len);
void cgebak_(char *job, char *side, int *n, int *ilo, int *ihi, float *scale, int *m, cfloat *v, int *ldv, int *info, int job_len, int side_len);
void zgebak_(char *job, char *side, int *n, int *ilo, int *ihi, double *scale, int *m, cdouble *v, int *ldv, int *info, int job_len, int side_len);

/// Balances a general matrix in order to improve the accuracy
/// of computed eigenvalues.
void sgebal_(char *job, int *n, float *a, int *lda, int *ilo, int *ihi, float *scale, int *info, int job_len);
void dgebal_(char *job, int *n, double *a, int *lda, int *ilo, int *ihi, double *scale, int *info, int job_len);
void cgebal_(char *job, int *n, cfloat *a, int *lda, int *ilo, int *ihi, float *scale, int *info, int job_len);
void zgebal_(char *job, int *n, cdouble *a, int *lda, int *ilo, int *ihi, double *scale, int *info, int job_len);

/// Reduces a general rectangular matrix to real bidiagonal form
/// by an orthogonal transformation.
void sgebrd_(int *m, int *n, float *a, int *lda, float *d, float *e, float *tauq, float *taup, float *work, int *lwork, int *info);
void dgebrd_(int *m, int *n, double *a, int *lda, double *d, double *e, double *tauq, double *taup, double *work, int *lwork, int *info);
void cgebrd_(int *m, int *n, cfloat *a, int *lda, float *d, float *e, cfloat *tauq, cfloat *taup, cfloat *work, int *lwork, int *info);
void zgebrd_(int *m, int *n, cdouble *a, int *lda, double *d, double *e, cdouble *tauq, cdouble *taup, cdouble *work, int *lwork, int *info);

/// Estimates the reciprocal of the condition number of a general
/// matrix, in either the 1-norm or the infinity-norm, using the
/// LU factorization computed by SGETRF.
void sgecon_(char *norm, int *n, float *a, int *lda, float *anorm, float *rcond, float *work, int *iwork, int *info, int norm_len);
void dgecon_(char *norm, int *n, double *a, int *lda, double *anorm, double *rcond, double *work, int *iwork, int *info, int norm_len);
void cgecon_(char *norm, int *n, cfloat *a, int *lda, float *anorm, float *rcond, cfloat *work, float *rwork, int *info, int norm_len);
void zgecon_(char *norm, int *n, cdouble *a, int *lda, double *anorm, double *rcond, cdouble *work, double *rwork, int *info, int norm_len);

/// Computes row and column scalings to equilibrate a general
/// rectangular matrix and reduce its condition number.
void sgeequ_(int *m, int *n, float *a, int *lda, float *r, float *c, float *rowcnd, float *colcnd, float *amax, int *info);
void dgeequ_(int *m, int *n, double *a, int *lda, double *r, double *c, double *rowcnd, double *colcnd, double *amax, int *info);
void cgeequ_(int *m, int *n, cfloat *a, int *lda, float *r, float *c, float *rowcnd, float *colcnd, float *amax, int *info);
void zgeequ_(int *m, int *n, cdouble *a, int *lda, double *r, double *c, double *rowcnd, double *colcnd, double *amax, int *info);

/// Reduces a general matrix to upper Hessenberg form by an
/// orthogonal similarity transformation.
void sgehrd_(int *n, int *ilo, int *ihi, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dgehrd_(int *n, int *ilo, int *ihi, double *a, int *lda, double *tau, double *work, int *lwork, int *info);
void cgehrd_(int *n, int *ilo, int *ihi, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zgehrd_(int *n, int *ilo, int *ihi, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Computes an LQ factorization of a general rectangular matrix.
void sgelqf_(int *m, int *n, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dgelqf_(int *m, int *n, double *a, int *lda, double *tau, double *work, int *lwork, int *info);
void cgelqf_(int *m, int *n, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zgelqf_(int *m, int *n, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Computes a QL factorization of a general rectangular matrix.
void sgeqlf_(int *m, int *n, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dgeqlf_(int *m, int *n, double *a, int *lda, double *tau, double *work, int *lwork, int *info);
void cgeqlf_(int *m, int *n, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zgeqlf_(int *m, int *n, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Computes a QR factorization with column pivoting of a general
/// rectangular matrix using Level 3 BLAS.
void sgeqp3_(int *m, int *n, float *a, int *lda, int *jpvt, float *tau, float *work, int *lwork, int *info);
void dgeqp3_(int *m, int *n, double *a, int *lda, int *jpvt, double *tau, double *work, int *lwork, int *info);
void cgeqp3_(int *m, int *n, cfloat *a, int *lda, int *jpvt, cfloat *tau, cfloat *work, int *lwork, float *rwork, int *info);
void zgeqp3_(int *m, int *n, cdouble *a, int *lda, int *jpvt, cdouble *tau, cdouble *work, int *lwork, double *rwork, int *info);

/// Computes a QR factorization with column pivoting of a general
/// rectangular matrix.
void sgeqpf_(int *m, int *n, float *a, int *lda, int *jpvt, float *tau, float *work, int *info);
void dgeqpf_(int *m, int *n, double *a, int *lda, int *jpvt, double *tau, double *work, int *info);
void cgeqpf_(int *m, int *n, cfloat *a, int *lda, int *jpvt, cfloat *tau, cfloat *work, float *rwork, int *info);
void zgeqpf_(int *m, int *n, cdouble *a, int *lda, int *jpvt, cdouble *tau, cdouble *work, double *rwork, int *info);

/// Computes a QR factorization of a general rectangular matrix.
void sgeqrf_(int *m, int *n, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dgeqrf_(int *m, int *n, double *a, int *lda, double *tau, double *work, int *lwork, int *info);
void cgeqrf_(int *m, int *n, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zgeqrf_(int *m, int *n, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Improves the computed solution to a general system of linear
/// equations AX=B, A**T X=B or A**H X=B, and provides forward and
/// backward error bounds for the solution.
void sgerfs_(char *trans, int *n, int *nrhs, float *a, int *lda, float *af, int *ldaf, int *ipiv, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int trans_len);
void dgerfs_(char *trans, int *n, int *nrhs, double *a, int *lda, double *af, int *ldaf, int *ipiv, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int trans_len);
void cgerfs_(char *trans, int *n, int *nrhs, cfloat *a, int *lda, cfloat *af, int *ldaf, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int trans_len);
void zgerfs_(char *trans, int *n, int *nrhs, cdouble *a, int *lda, cdouble *af, int *ldaf, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int trans_len);

/// Computes an RQ factorization of a general rectangular matrix.
void sgerqf_(int *m, int *n, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dgerqf_(int *m, int *n, double *a, int *lda, double *tau, double *work, int *lwork, int *info);
void cgerqf_(int *m, int *n, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zgerqf_(int *m, int *n, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Computes an LU factorization of a general matrix, using partial
/// pivoting with row interchanges.
void sgetrf_(int *m, int *n, float *a, int *lda, int *ipiv, int *info);
void dgetrf_(int *m, int *n, double *a, int *lda, int *ipiv, int *info);
void cgetrf_(int *m, int *n, cfloat *a, int *lda, int *ipiv, int *info);
void zgetrf_(int *m, int *n, cdouble *a, int *lda, int *ipiv, int *info);

/// Computes the inverse of a general matrix, using the LU factorization
/// computed by SGETRF.
void sgetri_(int *n, float *a, int *lda, int *ipiv, float *work, int *lwork, int *info);
void dgetri_(int *n, double *a, int *lda, int *ipiv, double *work, int *lwork, int *info);
void cgetri_(int *n, cfloat *a, int *lda, int *ipiv, cfloat *work, int *lwork, int *info);
void zgetri_(int *n, cdouble *a, int *lda, int *ipiv, cdouble *work, int *lwork, int *info);

/// Solves a general system of linear equations AX=B, A**T X=B
/// or A**H X=B, using the LU factorization computed by SGETRF.
void sgetrs_(char *trans, int *n, int *nrhs, float *a, int *lda, int *ipiv, float *b, int *ldb, int *info, int trans_len);
void dgetrs_(char *trans, int *n, int *nrhs, double *a, int *lda, int *ipiv, double *b, int *ldb, int *info, int trans_len);
void cgetrs_(char *trans, int *n, int *nrhs, cfloat *a, int *lda, int *ipiv, cfloat *b, int *ldb, int *info, int trans_len);
void zgetrs_(char *trans, int *n, int *nrhs, cdouble *a, int *lda, int *ipiv, cdouble *b, int *ldb, int *info, int trans_len);

/// Forms the right or left eigenvectors of the generalized eigenvalue
/// problem by backward transformation on the computed eigenvectors of
/// the balanced pair of matrices output by SGGBAL.
void sggbak_(char *job, char *side, int *n, int *ilo, int *ihi, float *lscale, float *rscale, int *m, float *v, int *ldv, int *info, int job_len, int side_len);
void dggbak_(char *job, char *side, int *n, int *ilo, int *ihi, double *lscale, double *rscale, int *m, double *v, int *ldv, int *info, int job_len, int side_len);
void cggbak_(char *job, char *side, int *n, int *ilo, int *ihi, float *lscale, float *rscale, int *m, cfloat *v, int *ldv, int *info, int job_len, int side_len);
void zggbak_(char *job, char *side, int *n, int *ilo, int *ihi, double *lscale, double *rscale, int *m, cdouble *v, int *ldv, int *info, int job_len, int side_len);

/// Balances a pair of general real matrices for the generalized
/// eigenvalue problem A x = lambda B x.
void sggbal_(char *job, int *n, float *a, int *lda, float *b, int *ldb, int *ilo, int *ihi, float *lscale, float *rscale, float *work, int *info, int job_len);
void dggbal_(char *job, int *n, double *a, int *lda, double *b, int *ldb, int *ilo, int *ihi, double *lscale, double *rscale, double *work, int *info, int job_len);
void cggbal_(char *job, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, int *ilo, int *ihi, float *lscale, float *rscale, float *work, int *info, int job_len);
void zggbal_(char *job, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, int *ilo, int *ihi, double *lscale, double *rscale, double *work, int *info, int job_len);

/// Reduces a pair of real matrices to generalized upper
/// Hessenberg form using orthogonal transformations 
void sgghrd_(char *compq, char *compz, int *n, int *ilo, int *ihi, float *a, int *lda, float *b, int *ldb, float *q, int *ldq, float *z, int *ldz, int *info, int compq_len, int compz_len);
void dgghrd_(char *compq, char *compz, int *n, int *ilo, int *ihi, double *a, int *lda, double *b, int *ldb, double *q, int *ldq, double *z, int *ldz, int *info, int compq_len, int compz_len);
void cgghrd_(char *compq, char *compz, int *n, int *ilo, int *ihi, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *q, int *ldq, cfloat *z, int *ldz, int *info, int compq_len, int compz_len);
void zgghrd_(char *compq, char *compz, int *n, int *ilo, int *ihi, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *q, int *ldq, cdouble *z, int *ldz, int *info, int compq_len, int compz_len);

/// Computes a generalized QR factorization of a pair of matrices. 
void sggqrf_(int *n, int *m, int *p, float *a, int *lda, float *taua, float *b, int *ldb, float *taub, float *work, int *lwork, int *info);
void dggqrf_(int *n, int *m, int *p, double *a, int *lda, double *taua, double *b, int *ldb, double *taub, double *work, int *lwork, int *info);
void cggqrf_(int *n, int *m, int *p, cfloat *a, int *lda, cfloat *taua, cfloat *b, int *ldb, cfloat *taub, cfloat *work, int *lwork, int *info);
void zggqrf_(int *n, int *m, int *p, cdouble *a, int *lda, cdouble *taua, cdouble *b, int *ldb, cdouble *taub, cdouble *work, int *lwork, int *info);

/// Computes a generalized RQ factorization of a pair of matrices.
void sggrqf_(int *m, int *p, int *n, float *a, int *lda, float *taua, float *b, int *ldb, float *taub, float *work, int *lwork, int *info);
void dggrqf_(int *m, int *p, int *n, double *a, int *lda, double *taua, double *b, int *ldb, double *taub, double *work, int *lwork, int *info);
void cggrqf_(int *m, int *p, int *n, cfloat *a, int *lda, cfloat *taua, cfloat *b, int *ldb, cfloat *taub, cfloat *work, int *lwork, int *info);
void zggrqf_(int *m, int *p, int *n, cdouble *a, int *lda, cdouble *taua, cdouble *b, int *ldb, cdouble *taub, cdouble *work, int *lwork, int *info);

/// Computes orthogonal matrices as a preprocessing step
/// for computing the generalized singular value decomposition
void sggsvp_(char *jobu, char *jobv, char *jobq, int *m, int *p, int *n, float *a, int *lda, float *b, int *ldb, float *tola, float *tolb, int *k, int *l, float *u, int *ldu, float *v, int *ldv, float *q, int *ldq, int *iwork, float *tau, float *work, int *info, int jobu_len, int jobv_len, int jobq_len);
void dggsvp_(char *jobu, char *jobv, char *jobq, int *m, int *p, int *n, double *a, int *lda, double *b, int *ldb, double *tola, double *tolb, int *k, int *l, double *u, int *ldu, double *v, int *ldv, double *q, int *ldq, int *iwork, double *tau, double *work, int *info, int jobu_len, int jobv_len, int jobq_len);
void cggsvp_(char *jobu, char *jobv, char *jobq, int *m, int *p, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, float *tola, float *tolb, int *k, int *l, cfloat *u, int *ldu, cfloat *v, int *ldv, cfloat *q, int *ldq, int *iwork, float *rwork, cfloat *tau, cfloat *work, int *info, int jobu_len, int jobv_len, int jobq_len);
void zggsvp_(char *jobu, char *jobv, char *jobq, int *m, int *p, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, double *tola, double *tolb, int *k, int *l, cdouble *u, int *ldu, cdouble *v, int *ldv, cdouble *q, int *ldq, int *iwork, double *rwork, cdouble *tau, cdouble *work, int *info, int jobu_len, int jobv_len, int jobq_len);

/// Estimates the reciprocal of the condition number of a general
/// tridiagonal matrix, in either the 1-norm or the infinity-norm,
/// using the LU factorization computed by SGTTRF.
void sgtcon_(char *norm, int *n, float *dl, float *d, float *du, float *du2, int *ipiv, float *anorm, float *rcond, float *work, int *iwork, int *info, int norm_len);
void dgtcon_(char *norm, int *n, double *dl, double *d, double *du, double *du2, int *ipiv, double *anorm, double *rcond, double *work, int *iwork, int *info, int norm_len);
void cgtcon_(char *norm, int *n, cfloat *dl, cfloat *d, cfloat *du, cfloat *du2, int *ipiv, float *anorm, float *rcond, cfloat *work, int *info, int norm_len);
void zgtcon_(char *norm, int *n, cdouble *dl, cdouble *d, cdouble *du, cdouble *du2, int *ipiv, double *anorm, double *rcond, cdouble *work, int *info, int norm_len);

/// Improves the computed solution to a general tridiagonal system
/// of linear equations AX=B, A**T X=B or A**H X=B, and provides
/// forward and backward error bounds for the solution.
void sgtrfs_(char *trans, int *n, int *nrhs, float *dl, float *d, float *du, float *dlf, float *df, float *duf, float *du2, int *ipiv, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int trans_len);
void dgtrfs_(char *trans, int *n, int *nrhs, double *dl, double *d, double *du, double *dlf, double *df, double *duf, double *du2, int *ipiv, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int trans_len);
void cgtrfs_(char *trans, int *n, int *nrhs, cfloat *dl, cfloat *d, cfloat *du, cfloat *dlf, cfloat *df, cfloat *duf, cfloat *du2, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int trans_len);
void zgtrfs_(char *trans, int *n, int *nrhs, cdouble *dl, cdouble *d, cdouble *du, cdouble *dlf, cdouble *df, cdouble *duf, cdouble *du2, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int trans_len);

/// Computes an LU factorization of a general tridiagonal matrix,
/// using partial pivoting with row interchanges.
void sgttrf_(int *n, float *dl, float *d, float *du, float *du2, int *ipiv, int *info);
void dgttrf_(int *n, double *dl, double *d, double *du, double *du2, int *ipiv, int *info);
void cgttrf_(int *n, cfloat *dl, cfloat *d, cfloat *du, cfloat *du2, int *ipiv, int *info);
void zgttrf_(int *n, cdouble *dl, cdouble *d, cdouble *du, cdouble *du2, int *ipiv, int *info);

/// Solves a general tridiagonal system of linear equations AX=B,
/// A**T X=B or A**H X=B, using the LU factorization computed by
/// SGTTRF.
void sgttrs_(char *trans, int *n, int *nrhs, float *dl, float *d, float *du, float *du2, int *ipiv, float *b, int *ldb, int *info, int trans_len);
void dgttrs_(char *trans, int *n, int *nrhs, double *dl, double *d, double *du, double *du2, int *ipiv, double *b, int *ldb, int *info, int trans_len);
void cgttrs_(char *trans, int *n, int *nrhs, cfloat *dl, cfloat *d, cfloat *du, cfloat *du2, int *ipiv, cfloat *b, int *ldb, int *info, int trans_len);
void zgttrs_(char *trans, int *n, int *nrhs, cdouble *dl, cdouble *d, cdouble *du, cdouble *du2, int *ipiv, cdouble *b, int *ldb, int *info, int trans_len);

/// Implements a single-/double-shift version of the QZ method for
/// finding the generalized eigenvalues of the equation 
/// det(A - w(i) B) = 0
void shgeqz_(char *job, char *compq, char *compz, int *n, int *ilo, int *ihi, float *a, int *lda, float *b, int *ldb, float *alphar, float *alphai, float *betav, float *q, int *ldq, float *z, int *ldz, float *work, int *lwork, int *info, int job_len, int compq_len, int compz_len);
void dhgeqz_(char *job, char *compq, char *compz, int *n, int *ilo, int *ihi, double *a, int *lda, double *b, int *ldb, double *alphar, double *alphai, double *betav, double *q, int *ldq, double *z, int *ldz, double *work, int *lwork, int *info, int job_len, int compq_len, int compz_len);
void chgeqz_(char *job, char *compq, char *compz, int *n, int *ilo, int *ihi, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *alphav, cfloat *betav, cfloat *q, int *ldq, cfloat *z, int *ldz, cfloat *work, int *lwork, float *rwork, int *info, int job_len, int compq_len, int compz_len);
void zhgeqz_(char *job, char *compq, char *compz, int *n, int *ilo, int *ihi, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *alphav, cdouble *betav, cdouble *q, int *ldq, cdouble *z, int *ldz, cdouble *work, int *lwork, double *rwork, int *info, int job_len, int compq_len, int compz_len);

/// Computes specified right and/or left eigenvectors of an upper
/// Hessenberg matrix by inverse iteration.
void shsein_(char *side, char *eigsrc, char *initv, int *select, int *n, float *h, int *ldh, float *wr, float *wi, float *vl, int *ldvl, float *vr, int *ldvr, int *mm, int *m, float *work, int *ifaill, int *ifailr, int *info, int side_len, int eigsrc_len, int initv_len);
void dhsein_(char *side, char *eigsrc, char *initv, int *select, int *n, double *h, int *ldh, double *wr, double *wi, double *vl, int *ldvl, double *vr, int *ldvr, int *mm, int *m, double *work, int *ifaill, int *ifailr, int *info, int side_len, int eigsrc_len, int initv_len);
void chsein_(char *side, char *eigsrc, char *initv, int *select, int *n, cfloat *h, int *ldh, cfloat *w, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, int *mm, int *m, cfloat *work, float *rwork, int *ifaill, int *ifailr, int *info, int side_len, int eigsrc_len, int initv_len);
void zhsein_(char *side, char *eigsrc, char *initv, int *select, int *n, cdouble *h, int *ldh, cdouble *w, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, int *mm, int *m, cdouble *work, double *rwork, int *ifaill, int *ifailr, int *info, int side_len, int eigsrc_len, int initv_len);

/// Computes the eigenvalues and Schur factorization of an upper
/// Hessenberg matrix, using the multishift QR algorithm.
void shseqr_(char *job, char *compz, int *n, int *ilo, int *ihi, float *h, int *ldh, float *wr, float *wi, float *z, int *ldz, float *work, int *lwork, int *info, int job_len, int compz_len);
void dhseqr_(char *job, char *compz, int *n, int *ilo, int *ihi, double *h, int *ldh, double *wr, double *wi, double *z, int *ldz, double *work, int *lwork, int *info, int job_len, int compz_len);
void chseqr_(char *job, char *compz, int *n, int *ilo, int *ihi, cfloat *h, int *ldh, cfloat *w, cfloat *z, int *ldz, cfloat *work, int *lwork, int *info, int job_len, int compz_len);
void zhseqr_(char *job, char *compz, int *n, int *ilo, int *ihi, cdouble *h, int *ldh, cdouble *w, cdouble *z, int *ldz, cdouble *work, int *lwork, int *info, int job_len, int compz_len);

/// Generates the orthogonal transformation matrix from
/// a reduction to tridiagonal form determined by SSPTRD.
void sopgtr_(char *uplo, int *n, float *ap, float *tau, float *q, int *ldq, float *work, int *info, int uplo_len);
void dopgtr_(char *uplo, int *n, double *ap, double *tau, double *q, int *ldq, double *work, int *info, int uplo_len);

/// Generates the unitary transformation matrix from
/// a reduction to tridiagonal form determined by CHPTRD.
void cupgtr_(char *uplo, int *n, cfloat *ap, cfloat *tau, cfloat *q, int *ldq, cfloat *work, int *info, int uplo_len);
void zupgtr_(char *uplo, int *n, cdouble *ap, cdouble *tau, cdouble *q, int *ldq, cdouble *work, int *info, int uplo_len);


/// Multiplies a general matrix by the orthogonal
/// transformation matrix from a reduction to tridiagonal form
/// determined by SSPTRD.
void sopmtr_(char *side, char *uplo, char *trans, int *m, int *n, float *ap, float *tau, float *c, int *ldc, float *work, int *info, int side_len, int uplo_len, int trans_len);
void dopmtr_(char *side, char *uplo, char *trans, int *m, int *n, double *ap, double *tau, double *c, int *ldc, double *work, int *info, int side_len, int uplo_len, int trans_len);

/// Generates the orthogonal transformation matrices from
/// a reduction to bidiagonal form determined by SGEBRD.
void sorgbr_(char *vect, int *m, int *n, int *k, float *a, int *lda, float *tau, float *work, int *lwork, int *info, int vect_len);
void dorgbr_(char *vect, int *m, int *n, int *k, double *a, int *lda, double *tau, double *work, int *lwork, int *info, int vect_len);

/// Generates the unitary transformation matrices from
/// a reduction to bidiagonal form determined by CGEBRD.
void cungbr_(char *vect, int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info, int vect_len);
void zungbr_(char *vect, int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info, int vect_len);

/// Generates the orthogonal transformation matrix from
/// a reduction to Hessenberg form determined by SGEHRD.
void sorghr_(int *n, int *ilo, int *ihi, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dorghr_(int *n, int *ilo, int *ihi, double *a, int *lda, double *tau, double *work, int *lwork, int *info);

/// Generates the unitary transformation matrix from
/// a reduction to Hessenberg form determined by CGEHRD.
void cunghr_(int *n, int *ilo, int *ihi, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zunghr_(int *n, int *ilo, int *ihi, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Generates all or part of the orthogonal matrix Q from
/// an LQ factorization determined by SGELQF.
void sorglq_(int *m, int *n, int *k, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dorglq_(int *m, int *n, int *k, double *a, int *lda, double *tau, double *work, int *lwork, int *info);

/// Generates all or part of the unitary matrix Q from
/// an LQ factorization determined by CGELQF.
void cunglq_(int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zunglq_(int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Generates all or part of the orthogonal matrix Q from
/// a QL factorization determined by SGEQLF.
void sorgql_(int *m, int *n, int *k, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dorgql_(int *m, int *n, int *k, double *a, int *lda, double *tau, double *work, int *lwork, int *info);

/// Generates all or part of the unitary matrix Q from
/// a QL factorization determined by CGEQLF.
void cungql_(int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zungql_(int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Generates all or part of the orthogonal matrix Q from
/// a QR factorization determined by SGEQRF.
void sorgqr_(int *m, int *n, int *k, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dorgqr_(int *m, int *n, int *k, double *a, int *lda, double *tau, double *work, int *lwork, int *info);

/// Generates all or part of the unitary matrix Q from
/// a QR factorization determined by CGEQRF.
void cungqr_(int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zungqr_(int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Generates all or part of the orthogonal matrix Q from
/// an RQ factorization determined by SGERQF.
void sorgrq_(int *m, int *n, int *k, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dorgrq_(int *m, int *n, int *k, double *a, int *lda, double *tau, double *work, int *lwork, int *info);

/// Generates all or part of the unitary matrix Q from
/// an RQ factorization determined by CGERQF.
void cungrq_(int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void zungrq_(int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);

/// Generates the orthogonal transformation matrix from
/// a reduction to tridiagonal form determined by SSYTRD.
void sorgtr_(char *uplo, int *n, float *a, int *lda, float *tau, float *work, int *lwork, int *info, int uplo_len);
void dorgtr_(char *uplo, int *n, double *a, int *lda, double *tau, double *work, int *lwork, int *info, int uplo_len);

/// Generates the unitary transformation matrix from
/// a reduction to tridiagonal form determined by CHETRD.
void cungtr_(char *uplo, int *n, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info, int uplo_len);
void zungtr_(char *uplo, int *n, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info, int uplo_len);

/// Multiplies a general matrix by one of the orthogonal
/// transformation  matrices from a reduction to bidiagonal form
/// determined by SGEBRD.
void sormbr_(char *vect, char *side, char *trans, int *m, int *n, int *k, float *a, int *lda, float *tau, float *c, int *ldc, float *work, int *lwork, int *info, int vect_len, int side_len, int trans_len);
void dormbr_(char *vect, char *side, char *trans, int *m, int *n, int *k, double *a, int *lda, double *tau, double *c, int *ldc, double *work, int *lwork, int *info, int vect_len, int side_len, int trans_len);

/// Multiplies a general matrix by one of the unitary
/// transformation matrices from a reduction to bidiagonal form
/// determined by CGEBRD.
void cunmbr_(char *vect, char *side, char *trans, int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *lwork, int *info, int vect_len, int side_len, int trans_len);
void zunmbr_(char *vect, char *side, char *trans, int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *lwork, int *info, int vect_len, int side_len, int trans_len);

/// Multiplies a general matrix by the orthogonal transformation
/// matrix from a reduction to Hessenberg form determined by SGEHRD.
void sormhr_(char *side, char *trans, int *m, int *n, int *ilo, int *ihi, float *a, int *lda, float *tau, float *c, int *ldc, float *work, int *lwork, int *info, int side_len, int trans_len);
void dormhr_(char *side, char *trans, int *m, int *n, int *ilo, int *ihi, double *a, int *lda, double *tau, double *c, int *ldc, double *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the unitary transformation
/// matrix from a reduction to Hessenberg form determined by CGEHRD.
void cunmhr_(char *side, char *trans, int *m, int *n, int *ilo, int *ihi, cfloat *a, int *lda, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *lwork, int *info, int side_len, int trans_len);
void zunmhr_(char *side, char *trans, int *m, int *n, int *ilo, int *ihi, cdouble *a, int *lda, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the orthogonal matrix
/// from an LQ factorization determined by SGELQF.
void sormlq_(char *side, char *trans, int *m, int *n, int *k, float *a, int *lda, float *tau, float *c, int *ldc, float *work, int *lwork, int *info, int side_len, int trans_len);
void dormlq_(char *side, char *trans, int *m, int *n, int *k, double *a, int *lda, double *tau, double *c, int *ldc, double *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the unitary matrix
/// from an LQ factorization determined by CGELQF.
void cunmlq_(char *side, char *trans, int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *lwork, int *info, int side_len, int trans_len);
void zunmlq_(char *side, char *trans, int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the orthogonal matrix
/// from a QL factorization determined by SGEQLF.
void sormql_(char *side, char *trans, int *m, int *n, int *k, float *a, int *lda, float *tau, float *c, int *ldc, float *work, int *lwork, int *info, int side_len, int trans_len);
void dormql_(char *side, char *trans, int *m, int *n, int *k, double *a, int *lda, double *tau, double *c, int *ldc, double *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the unitary matrix
/// from a QL factorization determined by CGEQLF.
void cunmql_(char *side, char *trans, int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *lwork, int *info, int side_len, int trans_len);
void zunmql_(char *side, char *trans, int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the orthogonal matrix
/// from a QR factorization determined by SGEQRF.
void sormqr_(char *side, char *trans, int *m, int *n, int *k, float *a, int *lda, float *tau, float *c, int *ldc, float *work, int *lwork, int *info, int side_len, int trans_len);
void dormqr_(char *side, char *trans, int *m, int *n, int *k, double *a, int *lda, double *tau, double *c, int *ldc, double *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the unitary matrix
/// from a QR factorization determined by CGEQRF.
void cunmqr_(char *side, char *trans, int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *lwork, int *info, int side_len, int trans_len);
void zunmqr_(char *side, char *trans, int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiples a general matrix by the orthogonal matrix
/// from an RZ factorization determined by STZRZF.
void sormr3_(char *side, char *trans, int *m, int *n, int *k, int *l, float *a, int *lda, float *tau, float *c, int *ldc, float *work, int *info, int side_len, int trans_len);
void dormr3_(char *side, char *trans, int *m, int *n, int *k, int *l, double *a, int *lda, double *tau, double *c, int *ldc, double *work, int *info, int side_len, int trans_len);

/// Multiples a general matrix by the unitary matrix
/// from an RZ factorization determined by CTZRZF.
void cunmr3_(char *side, char *trans, int *m, int *n, int *k, int *l, cfloat *a, int *lda, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *info, int side_len, int trans_len);
void zunmr3_(char *side, char *trans, int *m, int *n, int *k, int *l, cdouble *a, int *lda, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the orthogonal matrix
/// from an RQ factorization determined by SGERQF.
void sormrq_(char *side, char *trans, int *m, int *n, int *k, float *a, int *lda, float *tau, float *c, int *ldc, float *work, int *lwork, int *info, int side_len, int trans_len);
void dormrq_(char *side, char *trans, int *m, int *n, int *k, double *a, int *lda, double *tau, double *c, int *ldc, double *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the unitary matrix
/// from an RQ factorization determined by CGERQF.
void cunmrq_(char *side, char *trans, int *m, int *n, int *k, cfloat *a, int *lda, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *lwork, int *info, int side_len, int trans_len);
void zunmrq_(char *side, char *trans, int *m, int *n, int *k, cdouble *a, int *lda, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiples a general matrix by the orthogonal matrix
/// from an RZ factorization determined by STZRZF.
void sormrz_(char *side, char *trans, int *m, int *n, int *k, int *l, float *a, int *lda, float *tau, float *c, int *ldc, float *work, int *lwork, int *info, int side_len, int trans_len);
void dormrz_(char *side, char *trans, int *m, int *n, int *k, int *l, double *a, int *lda, double *tau, double *c, int *ldc, double *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiples a general matrix by the unitary matrix
/// from an RZ factorization determined by CTZRZF.
void cunmrz_(char *side, char *trans, int *m, int *n, int *k, int *l, cfloat *a, int *lda, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *lwork, int *info, int side_len, int trans_len);
void zunmrz_(char *side, char *trans, int *m, int *n, int *k, int *l, cdouble *a, int *lda, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *lwork, int *info, int side_len, int trans_len);

/// Multiplies a general matrix by the orthogonal
/// transformation matrix from a reduction to tridiagonal form
/// determined by SSYTRD.
void sormtr_(char *side, char *uplo, char *trans, int *m, int *n, float *a, int *lda, float *tau, float *c, int *ldc, float *work, int *lwork, int *info, int side_len, int uplo_len, int trans_len);
void dormtr_(char *side, char *uplo, char *trans, int *m, int *n, double *a, int *lda, double *tau, double *c, int *ldc, double *work, int *lwork, int *info, int side_len, int uplo_len, int trans_len);

/// Multiplies a general matrix by the unitary
/// transformation matrix from a reduction to tridiagonal form
/// determined by CHETRD.
void cunmtr_(char *side, char *uplo, char *trans, int *m, int *n, cfloat *a, int *lda, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *lwork, int *info, int side_len, int uplo_len, int trans_len);
void zunmtr_(char *side, char *uplo, char *trans, int *m, int *n, cdouble *a, int *lda, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *lwork, int *info, int side_len, int uplo_len, int trans_len);

/// Estimates the reciprocal of the condition number of a
/// symmetric positive definite band matrix, using the
/// Cholesky factorization computed by SPBTRF.
void spbcon_(char *uplo, int *n, int *kd, float *ab, int *ldab, float *anorm, float *rcond, float *work, int *iwork, int *info, int uplo_len);
void dpbcon_(char *uplo, int *n, int *kd, double *ab, int *ldab, double *anorm, double *rcond, double *work, int *iwork, int *info, int uplo_len);
void cpbcon_(char *uplo, int *n, int *kd, cfloat *ab, int *ldab, float *anorm, float *rcond, cfloat *work, float *rwork, int *info, int uplo_len);
void zpbcon_(char *uplo, int *n, int *kd, cdouble *ab, int *ldab, double *anorm, double *rcond, cdouble *work, double *rwork, int *info, int uplo_len);

/// Computes row and column scalings to equilibrate a symmetric
/// positive definite band matrix and reduce its condition number.
void spbequ_(char *uplo, int *n, int *kd, float *ab, int *ldab, float *s, float *scond, float *amax, int *info, int uplo_len);
void dpbequ_(char *uplo, int *n, int *kd, double *ab, int *ldab, double *s, double *scond, double *amax, int *info, int uplo_len);
void cpbequ_(char *uplo, int *n, int *kd, cfloat *ab, int *ldab, float *s, float *scond, float *amax, int *info, int uplo_len);
void zpbequ_(char *uplo, int *n, int *kd, cdouble *ab, int *ldab, double *s, double *scond, double *amax, int *info, int uplo_len);

/// Improves the computed solution to a symmetric positive
/// definite banded system of linear equations AX=B, and provides
/// forward and backward error bounds for the solution.
void spbrfs_(char *uplo, int *n, int *kd, int *nrhs, float *ab, int *ldab, float *afb, int *ldafb, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int uplo_len);
void dpbrfs_(char *uplo, int *n, int *kd, int *nrhs, double *ab, int *ldab, double *afb, int *ldafb, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int uplo_len);
void cpbrfs_(char *uplo, int *n, int *kd, int *nrhs, cfloat *ab, int *ldab, cfloat *afb, int *ldafb, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len);
void zpbrfs_(char *uplo, int *n, int *kd, int *nrhs, cdouble *ab, int *ldab, cdouble *afb, int *ldafb, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len);

/// Computes a split Cholesky factorization of a real symmetric positive
/// definite band matrix.
void spbstf_(char *uplo, int *n, int *kd, float *ab, int *ldab, int *info, int uplo_len);
void dpbstf_(char *uplo, int *n, int *kd, double *ab, int *ldab, int *info, int uplo_len);
void cpbstf_(char *uplo, int *n, int *kd, cfloat *ab, int *ldab, int *info, int uplo_len);
void zpbstf_(char *uplo, int *n, int *kd, cdouble *ab, int *ldab, int *info, int uplo_len);

/// Computes the Cholesky factorization of a symmetric
/// positive definite band matrix.
void spbtrf_(char *uplo, int *n, int *kd, float *ab, int *ldab, int *info, int uplo_len);
void dpbtrf_(char *uplo, int *n, int *kd, double *ab, int *ldab, int *info, int uplo_len);
void cpbtrf_(char *uplo, int *n, int *kd, cfloat *ab, int *ldab, int *info, int uplo_len);
void zpbtrf_(char *uplo, int *n, int *kd, cdouble *ab, int *ldab, int *info, int uplo_len);

/// Solves a symmetric positive definite banded system
/// of linear equations AX=B, using the Cholesky factorization
/// computed by SPBTRF.
void spbtrs_(char *uplo, int *n, int *kd, int *nrhs, float *ab, int *ldab, float *b, int *ldb, int *info, int uplo_len);
void dpbtrs_(char *uplo, int *n, int *kd, int *nrhs, double *ab, int *ldab, double *b, int *ldb, int *info, int uplo_len);
void cpbtrs_(char *uplo, int *n, int *kd, int *nrhs, cfloat *ab, int *ldab, cfloat *b, int *ldb, int *info, int uplo_len);
void zpbtrs_(char *uplo, int *n, int *kd, int *nrhs, cdouble *ab, int *ldab, cdouble *b, int *ldb, int *info, int uplo_len);

/// Estimates the reciprocal of the condition number of a
/// symmetric positive definite matrix, using the
/// Cholesky factorization computed by SPOTRF.
void spocon_(char *uplo, int *n, float *a, int *lda, float *anorm, float *rcond, float *work, int *iwork, int *info, int uplo_len);
void dpocon_(char *uplo, int *n, double *a, int *lda, double *anorm, double *rcond, double *work, int *iwork, int *info, int uplo_len);
void cpocon_(char *uplo, int *n, cfloat *a, int *lda, float *anorm, float *rcond, cfloat *work, float *rwork, int *info, int uplo_len);
void zpocon_(char *uplo, int *n, cdouble *a, int *lda, double *anorm, double *rcond, cdouble *work, double *rwork, int *info, int uplo_len);

/// Computes row and column scalings to equilibrate a symmetric
/// positive definite matrix and reduce its condition number.
void spoequ_(int *n, float *a, int *lda, float *s, float *scond, float *amax, int *info);
void dpoequ_(int *n, double *a, int *lda, double *s, double *scond, double *amax, int *info);
void cpoequ_(int *n, cfloat *a, int *lda, float *s, float *scond, float *amax, int *info);
void zpoequ_(int *n, cdouble *a, int *lda, double *s, double *scond, double *amax, int *info);

/// Improves the computed solution to a symmetric positive
/// definite system of linear equations AX=B, and provides forward
/// and backward error bounds for the solution.
void sporfs_(char *uplo, int *n, int *nrhs, float *a, int *lda, float *af, int *ldaf, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int uplo_len);
void dporfs_(char *uplo, int *n, int *nrhs, double *a, int *lda, double *af, int *ldaf, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int uplo_len);
void cporfs_(char *uplo, int *n, int *nrhs, cfloat *a, int *lda, cfloat *af, int *ldaf, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len);
void zporfs_(char *uplo, int *n, int *nrhs, cdouble *a, int *lda, cdouble *af, int *ldaf, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len);

/// Computes the Cholesky factorization of a symmetric
/// positive definite matrix.
void spotrf_(char *uplo, int *n, float *a, int *lda, int *info, int uplo_len);
void dpotrf_(char *uplo, int *n, double *a, int *lda, int *info, int uplo_len);
void cpotrf_(char *uplo, int *n, cfloat *a, int *lda, int *info, int uplo_len);
void zpotrf_(char *uplo, int *n, cdouble *a, int *lda, int *info, int uplo_len);

/// Computes the inverse of a symmetric positive definite
/// matrix, using the Cholesky factorization computed by SPOTRF.
void spotri_(char *uplo, int *n, float *a, int *lda, int *info, int uplo_len);
void dpotri_(char *uplo, int *n, double *a, int *lda, int *info, int uplo_len);
void cpotri_(char *uplo, int *n, cfloat *a, int *lda, int *info, int uplo_len);
void zpotri_(char *uplo, int *n, cdouble *a, int *lda, int *info, int uplo_len);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, using the Cholesky factorization computed by
/// SPOTRF.
void spotrs_(char *uplo, int *n, int *nrhs, float *a, int *lda, float *b, int *ldb, int *info, int uplo_len);
void dpotrs_(char *uplo, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, int *info, int uplo_len);
void cpotrs_(char *uplo, int *n, int *nrhs, cfloat *a, int *lda, cfloat *b, int *ldb, int *info, int uplo_len);
void zpotrs_(char *uplo, int *n, int *nrhs, cdouble *a, int *lda, cdouble *b, int *ldb, int *info, int uplo_len);

/// Estimates the reciprocal of the condition number of a
/// symmetric positive definite matrix in packed storage,
/// using the Cholesky factorization computed by SPPTRF.
void sppcon_(char *uplo, int *n, float *ap, float *anorm, float *rcond, float *work, int *iwork, int *info, int uplo_len);
void dppcon_(char *uplo, int *n, double *ap, double *anorm, double *rcond, double *work, int *iwork, int *info, int uplo_len);
void cppcon_(char *uplo, int *n, cfloat *ap, float *anorm, float *rcond, cfloat *work, float *rwork, int *info, int uplo_len);
void zppcon_(char *uplo, int *n, cdouble *ap, double *anorm, double *rcond, cdouble *work, double *rwork, int *info, int uplo_len);

/// Computes row and column scalings to equilibrate a symmetric
/// positive definite matrix in packed storage and reduce its condition
/// number.
void sppequ_(char *uplo, int *n, float *ap, float *s, float *scond, float *amax, int *info, int uplo_len);
void dppequ_(char *uplo, int *n, double *ap, double *s, double *scond, double *amax, int *info, int uplo_len);
void cppequ_(char *uplo, int *n, cfloat *ap, float *s, float *scond, float *amax, int *info, int uplo_len);
void zppequ_(char *uplo, int *n, cdouble *ap, double *s, double *scond, double *amax, int *info, int uplo_len);

/// Improves the computed solution to a symmetric positive
/// definite system of linear equations AX=B, where A is held in
/// packed storage, and provides forward and backward error bounds
/// for the solution.
void spprfs_(char *uplo, int *n, int *nrhs, float *ap, float *afp, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int uplo_len);
void dpprfs_(char *uplo, int *n, int *nrhs, double *ap, double *afp, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int uplo_len);
void cpprfs_(char *uplo, int *n, int *nrhs, cfloat *ap, cfloat *afp, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len);
void zpprfs_(char *uplo, int *n, int *nrhs, cdouble *ap, cdouble *afp, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len);

/// Computes the Cholesky factorization of a symmetric
/// positive definite matrix in packed storage.
void spptrf_(char *uplo, int *n, float *ap, int *info, int uplo_len);
void dpptrf_(char *uplo, int *n, double *ap, int *info, int uplo_len);
void cpptrf_(char *uplo, int *n, cfloat *ap, int *info, int uplo_len);
void zpptrf_(char *uplo, int *n, cdouble *ap, int *info, int uplo_len);

/// Computes the inverse of a symmetric positive definite
/// matrix in packed storage, using the Cholesky factorization computed
/// by SPPTRF.
void spptri_(char *uplo, int *n, float *ap, int *info, int uplo_len);
void dpptri_(char *uplo, int *n, double *ap, int *info, int uplo_len);
void cpptri_(char *uplo, int *n, cfloat *ap, int *info, int uplo_len);
void zpptri_(char *uplo, int *n, cdouble *ap, int *info, int uplo_len);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, where A is held in packed storage, using the
/// Cholesky factorization computed by SPPTRF.
void spptrs_(char *uplo, int *n, int *nrhs, float *ap, float *b, int *ldb, int *info, int uplo_len);
void dpptrs_(char *uplo, int *n, int *nrhs, double *ap, double *b, int *ldb, int *info, int uplo_len);
void cpptrs_(char *uplo, int *n, int *nrhs, cfloat *ap, cfloat *b, int *ldb, int *info, int uplo_len);
void zpptrs_(char *uplo, int *n, int *nrhs, cdouble *ap, cdouble *b, int *ldb, int *info, int uplo_len);

/// Computes the reciprocal of the condition number of a
/// symmetric positive definite tridiagonal matrix,
/// using the LDL**H factorization computed by SPTTRF.
void sptcon_(int *n, float *d, float *e, float *anorm, float *rcond, float *work, int *info);
void dptcon_(int *n, double *d, double *e, double *anorm, double *rcond, double *work, int *info);
void cptcon_(int *n, float *d, cfloat *e, float *anorm, float *rcond, float *rwork, int *info);
void zptcon_(int *n, double *d, cdouble *e, double *anorm, double *rcond, double *rwork, int *info);

/// Computes all eigenvalues and eigenvectors of a real symmetric
/// positive definite tridiagonal matrix, by computing the SVD of
/// its bidiagonal Cholesky factor.
void spteqr_(char *compz, int *n, float *d, float *e, float *z, int *ldz, float *work, int *info, int compz_len);
void dpteqr_(char *compz, int *n, double *d, double *e, double *z, int *ldz, double *work, int *info, int compz_len);
void cpteqr_(char *compz, int *n, float *d, float *e, cfloat *z, int *ldz, float *work, int *info, int compz_len);
void zpteqr_(char *compz, int *n, double *d, double *e, cdouble *z, int *ldz, double *work, int *info, int compz_len);

/// Improves the computed solution to a symmetric positive
/// definite tridiagonal system of linear equations AX=B, and provides
/// forward and backward error bounds for the solution.
void sptrfs_(int *n, int *nrhs, float *d, float *e, float *df, float *ef, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *info);
void dptrfs_(int *n, int *nrhs, double *d, double *e, double *df, double *ef, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *info);
void cptrfs_(char *uplo, int *n, int *nrhs, float *d, cfloat *e, float *df, cfloat *ef, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len);
void zptrfs_(char *uplo, int *n, int *nrhs, double *d, cdouble *e, double *df, cdouble *ef, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len);

/// Computes the LDL**H factorization of a symmetric
/// positive definite tridiagonal matrix.
void spttrf_(int *n, float *d, float *e, int *info);
void dpttrf_(int *n, double *d, double *e, int *info);
void cpttrf_(int *n, float *d, cfloat *e, int *info);
void zpttrf_(int *n, double *d, cdouble *e, int *info);

/// Solves a symmetric positive definite tridiagonal
/// system of linear equations, using the LDL**H factorization
/// computed by SPTTRF.
void spttrs_(int *n, int *nrhs, float *d, float *e, float *b, int *ldb, int *info);
void dpttrs_(int *n, int *nrhs, double *d, double *e, double *b, int *ldb, int *info);
void cpttrs_(char *uplo, int *n, int *nrhs, float *d, cfloat *e, cfloat *b, int *ldb, int *info, int uplo_len);
void zpttrs_(char *uplo, int *n, int *nrhs, double *d, cdouble *e, cdouble *b, int *ldb, int *info, int uplo_len);

/// Reduces a real symmetric-definite banded generalized eigenproblem
/// A x = lambda B x to standard form, where B has been factorized by
/// SPBSTF (Crawford's algorithm).
void ssbgst_(char *vect, char *uplo, int *n, int *ka, int *kb, float *ab, int *ldab, float *bb, int *ldbb, float *x, int *ldx, float *work, int *info, int vect_len, int uplo_len);
void dsbgst_(char *vect, char *uplo, int *n, int *ka, int *kb, double *ab, int *ldab, double *bb, int *ldbb, double *x, int *ldx, double *work, int *info, int vect_len, int uplo_len);

/// Reduces a complex Hermitian-definite banded generalized eigenproblem
/// A x = lambda B x to standard form, where B has been factorized by
/// CPBSTF (Crawford's algorithm).
void chbgst_(char *vect, char *uplo, int *n, int *ka, int *kb, cfloat *ab, int *ldab, cfloat *bb, int *ldbb, cfloat *x, int *ldx, cfloat *work, float *rwork, int *info, int vect_len, int uplo_len);
void zhbgst_(char *vect, char *uplo, int *n, int *ka, int *kb, cdouble *ab, int *ldab, cdouble *bb, int *ldbb, cdouble *x, int *ldx, cdouble *work, double *rwork, int *info, int vect_len, int uplo_len);

/// Reduces a symmetric band matrix to real symmetric
/// tridiagonal form by an orthogonal similarity transformation.
void ssbtrd_(char *vect, char *uplo, int *n, int *kd, float *ab, int *ldab, float *d, float *e, float *q, int *ldq, float *work, int *info, int vect_len, int uplo_len);
void dsbtrd_(char *vect, char *uplo, int *n, int *kd, double *ab, int *ldab, double *d, double *e, double *q, int *ldq, double *work, int *info, int vect_len, int uplo_len);

/// Reduces a Hermitian band matrix to real symmetric
/// tridiagonal form by a unitary similarity transformation.
void chbtrd_(char *vect, char *uplo, int *n, int *kd, cfloat *ab, int *ldab, float *d, float *e, cfloat *q, int *ldq, cfloat *work, int *info, int vect_len, int uplo_len);
void zhbtrd_(char *vect, char *uplo, int *n, int *kd, cdouble *ab, int *ldab, double *d, double *e, cdouble *q, int *ldq, cdouble *work, int *info, int vect_len, int uplo_len);

/// Estimates the reciprocal of the condition number of a
/// real symmetric indefinite
/// matrix in packed storage, using the factorization computed
/// by SSPTRF.
void sspcon_(char *uplo, int *n, float *ap, int *ipiv, float *anorm, float *rcond, float *work, int *iwork, int *info, int uplo_len);
void dspcon_(char *uplo, int *n, double *ap, int *ipiv, double *anorm, double *rcond, double *work, int *iwork, int *info, int uplo_len);
void cspcon_(char *uplo, int *n, cfloat *ap, int *ipiv, float *anorm, float *rcond, cfloat *work, int *info, int uplo_len);
void zspcon_(char *uplo, int *n, cdouble *ap, int *ipiv, double *anorm, double *rcond, cdouble *work, int *info, int uplo_len);

/// Estimates the reciprocal of the condition number of a
/// complex Hermitian indefinite
/// matrix in packed storage, using the factorization computed
/// by CHPTRF.
void chpcon_(char *uplo, int *n, cfloat *ap, int *ipiv, float *anorm, float *rcond, cfloat *work, int *info, int uplo_len);
void zhpcon_(char *uplo, int *n, cdouble *ap, int *ipiv, double *anorm, double *rcond, cdouble *work, int *info, int uplo_len);

/// Reduces a symmetric-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form,  where A and B are held in packed storage, and B has been
/// factorized by SPPTRF.
void sspgst_(int *itype, char *uplo, int *n, float *ap, float *bp, int *info, int uplo_len);
void dspgst_(int *itype, char *uplo, int *n, double *ap, double *bp, int *info, int uplo_len);

/// Reduces a Hermitian-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form,  where A and B are held in packed storage, and B has been
/// factorized by CPPTRF.
void chpgst_(int *itype, char *uplo, int *n, cfloat *ap, cfloat *bp, int *info, int uplo_len);
void zhpgst_(int *itype, char *uplo, int *n, cdouble *ap, cdouble *bp, int *info, int uplo_len);

/// Improves the computed solution to a real
/// symmetric indefinite system of linear equations
/// AX=B, where A is held in packed storage, and provides forward
/// and backward error bounds for the solution.
void ssprfs_(char *uplo, int *n, int *nrhs, float *ap, float *afp, int *ipiv, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int uplo_len);
void dsprfs_(char *uplo, int *n, int *nrhs, double *ap, double *afp, int *ipiv, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int uplo_len);
void csprfs_(char *uplo, int *n, int *nrhs, cfloat *ap, cfloat *afp, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len);
void zsprfs_(char *uplo, int *n, int *nrhs, cdouble *ap, cdouble *afp, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len);

/// Improves the computed solution to a complex
/// Hermitian indefinite system of linear equations
/// AX=B, where A is held in packed storage, and provides forward
/// and backward error bounds for the solution.
void chprfs_(char *uplo, int *n, int *nrhs, cfloat *ap, cfloat *afp, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len);
void zhprfs_(char *uplo, int *n, int *nrhs, cdouble *ap, cdouble *afp, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len);

/// Reduces a symmetric matrix in packed storage to real
/// symmetric tridiagonal form by an orthogonal similarity
/// transformation.
void ssptrd_(char *uplo, int *n, float *ap, float *d, float *e, float *tau, int *info, int uplo_len);
void dsptrd_(char *uplo, int *n, double *ap, double *d, double *e, double *tau, int *info, int uplo_len);

/// Reduces a Hermitian matrix in packed storage to real
/// symmetric tridiagonal form by a unitary similarity
/// transformation.
void chptrd_(char *uplo, int *n, cfloat *ap, float *d, float *e, cfloat *tau, int *info, int uplo_len);
void zhptrd_(char *uplo, int *n, cdouble *ap, double *d, double *e, cdouble *tau, int *info, int uplo_len);

/// Computes the factorization of a real
/// symmetric-indefinite matrix in packed storage,
/// using the diagonal pivoting method.
void ssptrf_(char *uplo, int *n, float *ap, int *ipiv, int *info, int uplo_len);
void dsptrf_(char *uplo, int *n, double *ap, int *ipiv, int *info, int uplo_len);
void csptrf_(char *uplo, int *n, cfloat *ap, int *ipiv, int *info, int uplo_len);
void zsptrf_(char *uplo, int *n, cdouble *ap, int *ipiv, int *info, int uplo_len);

/// Computes the factorization of a complex
/// Hermitian-indefinite matrix in packed storage,
/// using the diagonal pivoting method.
void chptrf_(char *uplo, int *n, cfloat *ap, int *ipiv, int *info, int uplo_len);
void zhptrf_(char *uplo, int *n, cdouble *ap, int *ipiv, int *info, int uplo_len);

/// Computes the inverse of a real symmetric
/// indefinite matrix in packed storage, using the factorization
/// computed by SSPTRF.
void ssptri_(char *uplo, int *n, float *ap, int *ipiv, float *work, int *info, int uplo_len);
void dsptri_(char *uplo, int *n, double *ap, int *ipiv, double *work, int *info, int uplo_len);
void csptri_(char *uplo, int *n, cfloat *ap, int *ipiv, cfloat *work, int *info, int uplo_len);
void zsptri_(char *uplo, int *n, cdouble *ap, int *ipiv, cdouble *work, int *info, int uplo_len);

/// Computes the inverse of a complex
/// Hermitian indefinite matrix in packed storage, using the factorization
/// computed by CHPTRF.
void chptri_(char *uplo, int *n, cfloat *ap, int *ipiv, cfloat *work, int *info, int uplo_len);
void zhptri_(char *uplo, int *n, cdouble *ap, int *ipiv, cdouble *work, int *info, int uplo_len);

/// Solves a real symmetric
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, using the factorization computed
/// by SSPTRF.
void ssptrs_(char *uplo, int *n, int *nrhs, float *ap, int *ipiv, float *b, int *ldb, int *info, int uplo_len);
void dsptrs_(char *uplo, int *n, int *nrhs, double *ap, int *ipiv, double *b, int *ldb, int *info, int uplo_len);
void csptrs_(char *uplo, int *n, int *nrhs, cfloat *ap, int *ipiv, cfloat *b, int *ldb, int *info, int uplo_len);
void zsptrs_(char *uplo, int *n, int *nrhs, cdouble *ap, int *ipiv, cdouble *b, int *ldb, int *info, int uplo_len);

/// Solves a complex Hermitian
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, using the factorization computed
/// by CHPTRF.
void chptrs_(char *uplo, int *n, int *nrhs, cfloat *ap, int *ipiv, cfloat *b, int *ldb, int *info, int uplo_len);
void zhptrs_(char *uplo, int *n, int *nrhs, cdouble *ap, int *ipiv, cdouble *b, int *ldb, int *info, int uplo_len);

/// Computes selected eigenvalues of a real symmetric tridiagonal
/// matrix by bisection.
void sstebz_(char *range, char *order, int *n, float *vl, float *vu, int *il, int *iu, float *abstol, float *d, float *e, int *m, int *nsplit, float *w, int *iblock, int *isplit, float *work, int *iwork, int *info, int range_len, int order_len);
void dstebz_(char *range, char *order, int *n, double *vl, double *vu, int *il, int *iu, double *abstol, double *d, double *e, int *m, int *nsplit, double *w, int *iblock, int *isplit, double *work, int *iwork, int *info, int range_len, int order_len);

/// Computes all eigenvalues and, optionally, eigenvectors of a
/// symmetric tridiagonal matrix using the divide and conquer algorithm.
void sstedc_(char *compz, int *n, float *d, float *e, float *z, int *ldz, float *work, int *lwork, int *iwork, int *liwork, int *info, int compz_len);
void dstedc_(char *compz, int *n, double *d, double *e, double *z, int *ldz, double *work, int *lwork, int *iwork, int *liwork, int *info, int compz_len);
void cstedc_(char *compz, int *n, float *d, float *e, cfloat *z, int *ldz, cfloat *work, int *lwork, float *rwork, int *lrwork, int *iwork, int *liwork, int *info, int compz_len);
void zstedc_(char *compz, int *n, double *d, double *e, cdouble *z, int *ldz, cdouble *work, int *lwork, double *rwork, int *lrwork, int *iwork, int *liwork, int *info, int compz_len);

/// Computes selected eigenvalues and, optionally, eigenvectors of a
/// symmetric tridiagonal matrix.  The eigenvalues are computed by the
/// dqds algorithm, while eigenvectors are computed from various "good"
/// LDL^T representations (also known as Relatively Robust Representations.)
void sstegr_(char *jobz, char *range, int *n, float *d, float *e, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, float *z, int *ldz, int *isuppz, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len);
void dstegr_(char *jobz, char *range, int *n, double *d, double *e, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, double *z, int *ldz, int *isuppz, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len);
void cstegr_(char *jobz, char *range, int *n, float *d, float *e, float *vl, float *vu, int *il, int *iu, float *abstol, int *m, float *w, cfloat *z, int *ldz, int *isuppz, float *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len);
void zstegr_(char *jobz, char *range, int *n, double *d, double *e, double *vl, double *vu, int *il, int *iu, double *abstol, int *m, double *w, cdouble *z, int *ldz, int *isuppz, double *work, int *lwork, int *iwork, int *liwork, int *info, int jobz_len, int range_len);

/// Computes selected eigenvectors of a real symmetric tridiagonal
/// matrix by inverse iteration.
void sstein_(int *n, float *d, float *e, int *m, float *w, int *iblock, int *isplit, float *z, int *ldz, float *work, int *iwork, int *ifail, int *info);
void dstein_(int *n, double *d, double *e, int *m, double *w, int *iblock, int *isplit, double *z, int *ldz, double *work, int *iwork, int *ifail, int *info);
void cstein_(int *n, float *d, float *e, int *m, float *w, int *iblock, int *isplit, cfloat *z, int *ldz, float *work, int *iwork, int *ifail, int *info);
void zstein_(int *n, double *d, double *e, int *m, double *w, int *iblock, int *isplit, cdouble *z, int *ldz, double *work, int *iwork, int *ifail, int *info);

/// Computes all eigenvalues and eigenvectors of a real symmetric
/// tridiagonal matrix, using the implicit QL or QR algorithm.
void ssteqr_(char *compz, int *n, float *d, float *e, float *z, int *ldz, float *work, int *info, int compz_len);
void dsteqr_(char *compz, int *n, double *d, double *e, double *z, int *ldz, double *work, int *info, int compz_len);
void csteqr_(char *compz, int *n, float *d, float *e, cfloat *z, int *ldz, float *work, int *info, int compz_len);
void zsteqr_(char *compz, int *n, double *d, double *e, cdouble *z, int *ldz, double *work, int *info, int compz_len);

/// Computes all eigenvalues of a real symmetric tridiagonal matrix,
/// using a root-free variant of the QL or QR algorithm.
void ssterf_(int *n, float *d, float *e, int *info);
void dsterf_(int *n, double *d, double *e, int *info);

/// Estimates the reciprocal of the condition number of a
/// real symmetric indefinite matrix,
/// using the factorization computed by SSYTRF.
void ssycon_(char *uplo, int *n, float *a, int *lda, int *ipiv, float *anorm, float *rcond, float *work, int *iwork, int *info, int uplo_len);
void dsycon_(char *uplo, int *n, double *a, int *lda, int *ipiv, double *anorm, double *rcond, double *work, int *iwork, int *info, int uplo_len);
void csycon_(char *uplo, int *n, cfloat *a, int *lda, int *ipiv, float *anorm, float *rcond, cfloat *work, int *info, int uplo_len);
void zsycon_(char *uplo, int *n, cdouble *a, int *lda, int *ipiv, double *anorm, double *rcond, cdouble *work, int *info, int uplo_len);

/// Estimates the reciprocal of the condition number of a
/// complex Hermitian indefinite matrix,
/// using the factorization computed by CHETRF.
void checon_(char *uplo, int *n, cfloat *a, int *lda, int *ipiv, float *anorm, float *rcond, cfloat *work, int *info, int uplo_len);
void zhecon_(char *uplo, int *n, cdouble *a, int *lda, int *ipiv, double *anorm, double *rcond, cdouble *work, int *info, int uplo_len);

/// Reduces a symmetric-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form, where B has been factorized by SPOTRF.
void ssygst_(int *itype, char *uplo, int *n, float *a, int *lda, float *b, int *ldb, int *info, int uplo_len);
void dsygst_(int *itype, char *uplo, int *n, double *a, int *lda, double *b, int *ldb, int *info, int uplo_len);

/// Reduces a Hermitian-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form, where B has been factorized by CPOTRF.
void chegst_(int *itype, char *uplo, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, int *info, int uplo_len);
void zhegst_(int *itype, char *uplo, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, int *info, int uplo_len);

/// Improves the computed solution to a real
/// symmetric indefinite system of linear equations
/// AX=B, and provides forward and backward error bounds for the
/// solution.
void ssyrfs_(char *uplo, int *n, int *nrhs, float *a, int *lda, float *af, int *ldaf, int *ipiv, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int uplo_len);
void dsyrfs_(char *uplo, int *n, int *nrhs, double *a, int *lda, double *af, int *ldaf, int *ipiv, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int uplo_len);
void csyrfs_(char *uplo, int *n, int *nrhs, cfloat *a, int *lda, cfloat *af, int *ldaf, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len);
void zsyrfs_(char *uplo, int *n, int *nrhs, cdouble *a, int *lda, cdouble *af, int *ldaf, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len);

/// Improves the computed solution to a complex
/// Hermitian indefinite system of linear equations
/// AX=B, and provides forward and backward error bounds for the
/// solution.
void cherfs_(char *uplo, int *n, int *nrhs, cfloat *a, int *lda, cfloat *af, int *ldaf, int *ipiv, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len);
void zherfs_(char *uplo, int *n, int *nrhs, cdouble *a, int *lda, cdouble *af, int *ldaf, int *ipiv, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len);

/// Reduces a symmetric matrix to real symmetric tridiagonal
/// form by an orthogonal similarity transformation.
void ssytrd_(char *uplo, int *n, float *a, int *lda, float *d, float *e, float *tau, float *work, int *lwork, int *info, int uplo_len);
void dsytrd_(char *uplo, int *n, double *a, int *lda, double *d, double *e, double *tau, double *work, int *lwork, int *info, int uplo_len);

/// Reduces a Hermitian matrix to real symmetric tridiagonal
/// form by an orthogonal/unitary similarity transformation.
void chetrd_(char *uplo, int *n, cfloat *a, int *lda, float *d, float *e, cfloat *tau, cfloat *work, int *lwork, int *info, int uplo_len);
void zhetrd_(char *uplo, int *n, cdouble *a, int *lda, double *d, double *e, cdouble *tau, cdouble *work, int *lwork, int *info, int uplo_len);

/// Computes the factorization of a real symmetric-indefinite matrix,
/// using the diagonal pivoting method.
void ssytrf_(char *uplo, int *n, float *a, int *lda, int *ipiv, float *work, int *lwork, int *info, int uplo_len);
void dsytrf_(char *uplo, int *n, double *a, int *lda, int *ipiv, double *work, int *lwork, int *info, int uplo_len);
void csytrf_(char *uplo, int *n, cfloat *a, int *lda, int *ipiv, cfloat *work, int *lwork, int *info, int uplo_len);
void zsytrf_(char *uplo, int *n, cdouble *a, int *lda, int *ipiv, cdouble *work, int *lwork, int *info, int uplo_len);

/// Computes the factorization of a complex Hermitian-indefinite matrix,
/// using the diagonal pivoting method.
void chetrf_(char *uplo, int *n, cfloat *a, int *lda, int *ipiv, cfloat *work, int *lwork, int *info, int uplo_len);
void zhetrf_(char *uplo, int *n, cdouble *a, int *lda, int *ipiv, cdouble *work, int *lwork, int *info, int uplo_len);

/// Computes the inverse of a real symmetric indefinite matrix,
/// using the factorization computed by SSYTRF.
void ssytri_(char *uplo, int *n, float *a, int *lda, int *ipiv, float *work, int *info, int uplo_len);
void dsytri_(char *uplo, int *n, double *a, int *lda, int *ipiv, double *work, int *info, int uplo_len);
void csytri_(char *uplo, int *n, cfloat *a, int *lda, int *ipiv, cfloat *work, int *info, int uplo_len);
void zsytri_(char *uplo, int *n, cdouble *a, int *lda, int *ipiv, cdouble *work, int *info, int uplo_len);

/// Computes the inverse of a complex Hermitian indefinite matrix,
/// using the factorization computed by CHETRF.
void chetri_(char *uplo, int *n, cfloat *a, int *lda, int *ipiv, cfloat *work, int *info, int uplo_len);
void zhetri_(char *uplo, int *n, cdouble *a, int *lda, int *ipiv, cdouble *work, int *info, int uplo_len);

/// Solves a real symmetric indefinite system of linear equations AX=B,
/// using the factorization computed by SSPTRF.
void ssytrs_(char *uplo, int *n, int *nrhs, float *a, int *lda, int *ipiv, float *b, int *ldb, int *info, int uplo_len);
void dsytrs_(char *uplo, int *n, int *nrhs, double *a, int *lda, int *ipiv, double *b, int *ldb, int *info, int uplo_len);
void csytrs_(char *uplo, int *n, int *nrhs, cfloat *a, int *lda, int *ipiv, cfloat *b, int *ldb, int *info, int uplo_len);
void zsytrs_(char *uplo, int *n, int *nrhs, cdouble *a, int *lda, int *ipiv, cdouble *b, int *ldb, int *info, int uplo_len);

/// Solves a complex Hermitian indefinite system of linear equations AX=B,
/// using the factorization computed by CHPTRF.
void chetrs_(char *uplo, int *n, int *nrhs, cfloat *a, int *lda, int *ipiv, cfloat *b, int *ldb, int *info, int uplo_len);
void zhetrs_(char *uplo, int *n, int *nrhs, cdouble *a, int *lda, int *ipiv, cdouble *b, int *ldb, int *info, int uplo_len);

/// Estimates the reciprocal of the condition number of a triangular
/// band matrix, in either the 1-norm or the infinity-norm.
void stbcon_(char *norm, char *uplo, char *diag, int *n, int *kd, float *ab, int *ldab, float *rcond, float *work, int *iwork, int *info, int norm_len, int uplo_len, int diag_len);
void dtbcon_(char *norm, char *uplo, char *diag, int *n, int *kd, double *ab, int *ldab, double *rcond, double *work, int *iwork, int *info, int norm_len, int uplo_len, int diag_len);
void ctbcon_(char *norm, char *uplo, char *diag, int *n, int *kd, cfloat *ab, int *ldab, float *rcond, cfloat *work, float *rwork, int *info, int norm_len, int uplo_len, int diag_len);
void ztbcon_(char *norm, char *uplo, char *diag, int *n, int *kd, cdouble *ab, int *ldab, double *rcond, cdouble *work, double *rwork, int *info, int norm_len, int uplo_len, int diag_len);

/// Provides forward and backward error bounds for the solution
/// of a triangular banded system of linear equations AX=B,
/// A**T X=B or A**H X=B.
void stbrfs_(char *uplo, char *trans, char *diag, int *n, int *kd, int *nrhs, float *ab, int *ldab, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int uplo_len, int trans_len, int diag_len);
void dtbrfs_(char *uplo, char *trans, char *diag, int *n, int *kd, int *nrhs, double *ab, int *ldab, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int uplo_len, int trans_len, int diag_len);
void ctbrfs_(char *uplo, char *trans, char *diag, int *n, int *kd, int *nrhs, cfloat *ab, int *ldab, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len, int trans_len, int diag_len);
void ztbrfs_(char *uplo, char *trans, char *diag, int *n, int *kd, int *nrhs, cdouble *ab, int *ldab, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len, int trans_len, int diag_len);

/// Solves a triangular banded system of linear equations AX=B,
/// A**T X=B or A**H X=B.
void stbtrs_(char *uplo, char *trans, char *diag, int *n, int *kd, int *nrhs, float *ab, int *ldab, float *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);
void dtbtrs_(char *uplo, char *trans, char *diag, int *n, int *kd, int *nrhs, double *ab, int *ldab, double *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);
void ctbtrs_(char *uplo, char *trans, char *diag, int *n, int *kd, int *nrhs, cfloat *ab, int *ldab, cfloat *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);
void ztbtrs_(char *uplo, char *trans, char *diag, int *n, int *kd, int *nrhs, cdouble *ab, int *ldab, cdouble *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);

/// Computes some or all of the right and/or left generalized eigenvectors
/// of a pair of upper triangular matrices.
void stgevc_(char *side, char *howmny, int *select, int *n, float *a, int *lda, float *b, int *ldb, float *vl, int *ldvl, float *vr, int *ldvr, int *mm, int *m, float *work, int *info, int side_len, int howmny_len);
void dtgevc_(char *side, char *howmny, int *select, int *n, double *a, int *lda, double *b, int *ldb, double *vl, int *ldvl, double *vr, int *ldvr, int *mm, int *m, double *work, int *info, int side_len, int howmny_len);
void ctgevc_(char *side, char *howmny, int *select, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, int *mm, int *m, cfloat *work, float *rwork, int *info, int side_len, int howmny_len);
void ztgevc_(char *side, char *howmny, int *select, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, int *mm, int *m, cdouble *work, double *rwork, int *info, int side_len, int howmny_len);

/// Reorders the generalized real Schur decomposition of a real
/// matrix pair (A,B) using an orthogonal equivalence transformation
/// so that the diagonal block of (A,B) with row index IFST is moved
/// to row ILST.
void stgexc_(int *wantq, int *wantz, int *n, float *a, int *lda, float *b, int *ldb, float *q, int *ldq, float *z, int *ldz, int *ifst, int *ilst, float *work, int *lwork, int *info);
void dtgexc_(int *wantq, int *wantz, int *n, double *a, int *lda, double *b, int *ldb, double *q, int *ldq, double *z, int *ldz, int *ifst, int *ilst, double *work, int *lwork, int *info);
void ctgexc_(int *wantq, int *wantz, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *q, int *ldq, cfloat *z, int *ldz, int *ifst, int *ilst, int *info);
void ztgexc_(int *wantq, int *wantz, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *q, int *ldq, cdouble *z, int *ldz, int *ifst, int *ilst, int *info);

/// Reorders the generalized real Schur decomposition of a real
/// matrix pair (A, B) so that a selected cluster of eigenvalues
/// appears in the leading diagonal blocks of the upper quasi-triangular
/// matrix A and the upper triangular B.
void stgsen_(int *ijob, int *wantq, int *wantz, int *select, int *n, float *a, int *lda, float *b, int *ldb, float *alphar, float *alphai, float *betav, float *q, int *ldq, float *z, int *ldz, int *m, float *pl, float *pr, float *dif, float *work, int *lwork, int *iwork, int *liwork, int *info);
void dtgsen_(int *ijob, int *wantq, int *wantz, int *select, int *n, double *a, int *lda, double *b, int *ldb, double *alphar, double *alphai, double *betav, double *q, int *ldq, double *z, int *ldz, int *m, double *pl, double *pr, double *dif, double *work, int *lwork, int *iwork, int *liwork, int *info);
void ctgsen_(int *ijob, int *wantq, int *wantz, int *select, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *alphav, cfloat *betav, cfloat *q, int *ldq, cfloat *z, int *ldz, int *m, float *pl, float *pr, float *dif, cfloat *work, int *lwork, int *iwork, int *liwork, int *info);
void ztgsen_(int *ijob, int *wantq, int *wantz, int *select, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *alphav, cdouble *betav, cdouble *q, int *ldq, cdouble *z, int *ldz, int *m, double *pl, double *pr, double *dif, cdouble *work, int *lwork, int *iwork, int *liwork, int *info);

/// Computes the generalized singular value decomposition of two real
/// upper triangular (or trapezoidal) matrices as output by SGGSVP.
void stgsja_(char *jobu, char *jobv, char *jobq, int *m, int *p, int *n, int *k, int *l, float *a, int *lda, float *b, int *ldb, float *tola, float *tolb, float *alphav, float *betav, float *u, int *ldu, float *v, int *ldv, float *q, int *ldq, float *work, int *ncycle, int *info, int jobu_len, int jobv_len, int jobq_len);
void dtgsja_(char *jobu, char *jobv, char *jobq, int *m, int *p, int *n, int *k, int *l, double *a, int *lda, double *b, int *ldb, double *tola, double *tolb, double *alphav, double *betav, double *u, int *ldu, double *v, int *ldv, double *q, int *ldq, double *work, int *ncycle, int *info, int jobu_len, int jobv_len, int jobq_len);
void ctgsja_(char *jobu, char *jobv, char *jobq, int *m, int *p, int *n, int *k, int *l, cfloat *a, int *lda, cfloat *b, int *ldb, float *tola, float *tolb, float *alphav, float *betav, cfloat *u, int *ldu, cfloat *v, int *ldv, cfloat *q, int *ldq, cfloat *work, int *ncycle, int *info, int jobu_len, int jobv_len, int jobq_len);
void ztgsja_(char *jobu, char *jobv, char *jobq, int *m, int *p, int *n, int *k, int *l, cdouble *a, int *lda, cdouble *b, int *ldb, double *tola, double *tolb, double *alphav, double *betav, cdouble *u, int *ldu, cdouble *v, int *ldv, cdouble *q, int *ldq, cdouble *work, int *ncycle, int *info, int jobu_len, int jobv_len, int jobq_len);

/// Estimates reciprocal condition numbers for specified
/// eigenvalues and/or eigenvectors of a matrix pair (A, B) in
/// generalized real Schur canonical form, as returned by SGGES.
void stgsna_(char *job, char *howmny, int *select, int *n, float *a, int *lda, float *b, int *ldb, float *vl, int *ldvl, float *vr, int *ldvr, float *s, float *dif, int *mm, int *m, float *work, int *lwork, int *iwork, int *info, int job_len, int howmny_len);
void dtgsna_(char *job, char *howmny, int *select, int *n, double *a, int *lda, double *b, int *ldb, double *vl, int *ldvl, double *vr, int *ldvr, double *s, double *dif, int *mm, int *m, double *work, int *lwork, int *iwork, int *info, int job_len, int howmny_len);
void ctgsna_(char *job, char *howmny, int *select, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, float *s, float *dif, int *mm, int *m, cfloat *work, int *lwork, int *iwork, int *info, int job_len, int howmny_len);
void ztgsna_(char *job, char *howmny, int *select, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, double *s, double *dif, int *mm, int *m, cdouble *work, int *lwork, int *iwork, int *info, int job_len, int howmny_len);

/// Solves the generalized Sylvester equation.
void stgsyl_(char *trans, int *ijob, int *m, int *n, float *a, int *lda, float *b, int *ldb, float *c, int *ldc, float *d, int *ldd, float *e, int *lde, float *f, int *ldf, float *scale, float *dif, float *work, int *lwork, int *iwork, int *info, int trans_len);
void dtgsyl_(char *trans, int *ijob, int *m, int *n, double *a, int *lda, double *b, int *ldb, double *c, int *ldc, double *d, int *ldd, double *e, int *lde, double *f, int *ldf, double *scale, double *dif, double *work, int *lwork, int *iwork, int *info, int trans_len);
void ctgsyl_(char *trans, int *ijob, int *m, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *c, int *ldc, cfloat *d, int *ldd, cfloat *e, int *lde, cfloat *f, int *ldf, float *scale, float *dif, cfloat *work, int *lwork, int *iwork, int *info, int trans_len);
void ztgsyl_(char *trans, int *ijob, int *m, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *c, int *ldc, cdouble *d, int *ldd, cdouble *e, int *lde, cdouble *f, int *ldf, double *scale, double *dif, cdouble *work, int *lwork, int *iwork, int *info, int trans_len);

/// Estimates the reciprocal of the condition number of a triangular
/// matrix in packed storage, in either the 1-norm or the infinity-norm.
void stpcon_(char *norm, char *uplo, char *diag, int *n, float *ap, float *rcond, float *work, int *iwork, int *info, int norm_len, int uplo_len, int diag_len);
void dtpcon_(char *norm, char *uplo, char *diag, int *n, double *ap, double *rcond, double *work, int *iwork, int *info, int norm_len, int uplo_len, int diag_len);
void ctpcon_(char *norm, char *uplo, char *diag, int *n, cfloat *ap, float *rcond, cfloat *work, float *rwork, int *info, int norm_len, int uplo_len, int diag_len);
void ztpcon_(char *norm, char *uplo, char *diag, int *n, cdouble *ap, double *rcond, cdouble *work, double *rwork, int *info, int norm_len, int uplo_len, int diag_len);

/// Provides forward and backward error bounds for the solution
/// of a triangular system of linear equations AX=B, A**T X=B or
/// A**H X=B, where A is held in packed storage.
void stprfs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, float *ap, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int uplo_len, int trans_len, int diag_len);
void dtprfs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, double *ap, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int uplo_len, int trans_len, int diag_len);
void ctprfs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, cfloat *ap, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len, int trans_len, int diag_len);
void ztprfs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, cdouble *ap, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len, int trans_len, int diag_len);

///  Computes the inverse of a triangular matrix in packed storage.
void stptri_(char *uplo, char *diag, int *n, float *ap, int *info, int uplo_len, int diag_len);
void dtptri_(char *uplo, char *diag, int *n, double *ap, int *info, int uplo_len, int diag_len);
void ctptri_(char *uplo, char *diag, int *n, cfloat *ap, int *info, int uplo_len, int diag_len);
void ztptri_(char *uplo, char *diag, int *n, cdouble *ap, int *info, int uplo_len, int diag_len);

/// Solves a triangular system of linear equations AX=B,
/// A**T X=B or A**H X=B, where A is held in packed storage.
void stptrs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, float *ap, float *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);
void dtptrs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, double *ap, double *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);
void ctptrs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, cfloat *ap, cfloat *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);
void ztptrs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, cdouble *ap, cdouble *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);

/// Estimates the reciprocal of the condition number of a triangular
/// matrix, in either the 1-norm or the infinity-norm.
void strcon_(char *norm, char *uplo, char *diag, int *n, float *a, int *lda, float *rcond, float *work, int *iwork, int *info, int norm_len, int uplo_len, int diag_len);
void dtrcon_(char *norm, char *uplo, char *diag, int *n, double *a, int *lda, double *rcond, double *work, int *iwork, int *info, int norm_len, int uplo_len, int diag_len);
void ctrcon_(char *norm, char *uplo, char *diag, int *n, cfloat *a, int *lda, float *rcond, cfloat *work, float *rwork, int *info, int norm_len, int uplo_len, int diag_len);
void ztrcon_(char *norm, char *uplo, char *diag, int *n, cdouble *a, int *lda, double *rcond, cdouble *work, double *rwork, int *info, int norm_len, int uplo_len, int diag_len);

/// Computes some or all of the right and/or left eigenvectors of
/// an upper quasi-triangular matrix.
void strevc_(char *side, char *howmny, int *select, int *n, float *t, int *ldt, float *vl, int *ldvl, float *vr, int *ldvr, int *mm, int *m, float *work, int *info, int side_len, int howmny_len);
void dtrevc_(char *side, char *howmny, int *select, int *n, double *t, int *ldt, double *vl, int *ldvl, double *vr, int *ldvr, int *mm, int *m, double *work, int *info, int side_len, int howmny_len);
void ctrevc_(char *side, char *howmny, int *select, int *n, cfloat *t, int *ldt, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, int *mm, int *m, cfloat *work, float *rwork, int *info, int side_len, int howmny_len);
void ztrevc_(char *side, char *howmny, int *select, int *n, cdouble *t, int *ldt, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, int *mm, int *m, cdouble *work, double *rwork, int *info, int side_len, int howmny_len);

/// Reorders the Schur factorization of a matrix by an orthogonal
/// similarity transformation.
void strexc_(char *compq, int *n, float *t, int *ldt, float *q, int *ldq, int *ifst, int *ilst, float *work, int *info, int compq_len);
void dtrexc_(char *compq, int *n, double *t, int *ldt, double *q, int *ldq, int *ifst, int *ilst, double *work, int *info, int compq_len);
void ctrexc_(char *compq, int *n, cfloat *t, int *ldt, cfloat *q, int *ldq, int *ifst, int *ilst, int *info, int compq_len);
void ztrexc_(char *compq, int *n, cdouble *t, int *ldt, cdouble *q, int *ldq, int *ifst, int *ilst, int *info, int compq_len);

/// Provides forward and backward error bounds for the solution
/// of a triangular system of linear equations A X=B, A**T X=B or
/// A**H X=B.
void strrfs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, float *a, int *lda, float *b, int *ldb, float *x, int *ldx, float *ferr, float *berr, float *work, int *iwork, int *info, int uplo_len, int trans_len, int diag_len);
void dtrrfs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, double *x, int *ldx, double *ferr, double *berr, double *work, int *iwork, int *info, int uplo_len, int trans_len, int diag_len);
void ctrrfs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *x, int *ldx, float *ferr, float *berr, cfloat *work, float *rwork, int *info, int uplo_len, int trans_len, int diag_len);
void ztrrfs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *x, int *ldx, double *ferr, double *berr, cdouble *work, double *rwork, int *info, int uplo_len, int trans_len, int diag_len);

/// Reorders the Schur factorization of a matrix in order to find
/// an orthonormal basis of a right invariant subspace corresponding
/// to selected eigenvalues, and returns reciprocal condition numbers
/// (sensitivities) of the average of the cluster of eigenvalues
/// and of the invariant subspace.
void strsen_(char *job, char *compq, int *select, int *n, float *t, int *ldt, float *q, int *ldq, float *wr, float *wi, int *m, float *s, float *sep, float *work, int *lwork, int *iwork, int *liwork, int *info, int job_len, int compq_len);
void dtrsen_(char *job, char *compq, int *select, int *n, double *t, int *ldt, double *q, int *ldq, double *wr, double *wi, int *m, double *s, double *sep, double *work, int *lwork, int *iwork, int *liwork, int *info, int job_len, int compq_len);
void ctrsen_(char *job, char *compq, int *select, int *n, cfloat *t, int *ldt, cfloat *q, int *ldq, cfloat *w, int *m, float *s, float *sep, cfloat *work, int *lwork, int *info, int job_len, int compq_len);
void ztrsen_(char *job, char *compq, int *select, int *n, cdouble *t, int *ldt, cdouble *q, int *ldq, cdouble *w, int *m, double *s, double *sep, cdouble *work, int *lwork, int *info, int job_len, int compq_len);

/// Estimates the reciprocal condition numbers (sensitivities)
/// of selected eigenvalues and eigenvectors of an upper
/// quasi-triangular matrix.
void strsna_(char *job, char *howmny, int *select, int *n, float *t, int *ldt, float *vl, int *ldvl, float *vr, int *ldvr, float *s, float *sep, int *mm, int *m, float *work, int *ldwork, int *iwork, int *info, int job_len, int howmny_len);
void dtrsna_(char *job, char *howmny, int *select, int *n, double *t, int *ldt, double *vl, int *ldvl, double *vr, int *ldvr, double *s, double *sep, int *mm, int *m, double *work, int *ldwork, int *iwork, int *info, int job_len, int howmny_len);
void ctrsna_(char *job, char *howmny, int *select, int *n, cfloat *t, int *ldt, cfloat *vl, int *ldvl, cfloat *vr, int *ldvr, float *s, float *sep, int *mm, int *m, cfloat *work, int *ldwork, float *rwork, int *info, int job_len, int howmny_len);
void ztrsna_(char *job, char *howmny, int *select, int *n, cdouble *t, int *ldt, cdouble *vl, int *ldvl, cdouble *vr, int *ldvr, double *s, double *sep, int *mm, int *m, cdouble *work, int *ldwork, double *rwork, int *info, int job_len, int howmny_len);

/// Solves the Sylvester matrix equation A X +/- X B=C where A
/// and B are upper quasi-triangular, and may be transposed.
void strsyl_(char *trana, char *tranb, int *isgn, int *m, int *n, float *a, int *lda, float *b, int *ldb, float *c, int *ldc, float *scale, int *info, int trana_len, int tranb_len);
void dtrsyl_(char *trana, char *tranb, int *isgn, int *m, int *n, double *a, int *lda, double *b, int *ldb, double *c, int *ldc, double *scale, int *info, int trana_len, int tranb_len);
void ctrsyl_(char *trana, char *tranb, int *isgn, int *m, int *n, cfloat *a, int *lda, cfloat *b, int *ldb, cfloat *c, int *ldc, float *scale, int *info, int trana_len, int tranb_len);
void ztrsyl_(char *trana, char *tranb, int *isgn, int *m, int *n, cdouble *a, int *lda, cdouble *b, int *ldb, cdouble *c, int *ldc, double *scale, int *info, int trana_len, int tranb_len);

/// Computes the inverse of a triangular matrix.
void strtri_(char *uplo, char *diag, int *n, float *a, int *lda, int *info, int uplo_len, int diag_len);
void dtrtri_(char *uplo, char *diag, int *n, double *a, int *lda, int *info, int uplo_len, int diag_len);
void ctrtri_(char *uplo, char *diag, int *n, cfloat *a, int *lda, int *info, int uplo_len, int diag_len);
void ztrtri_(char *uplo, char *diag, int *n, cdouble *a, int *lda, int *info, int uplo_len, int diag_len);

/// Solves a triangular system of linear equations AX=B,
/// A**T X=B or A**H X=B.
void strtrs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, float *a, int *lda, float *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);
void dtrtrs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);
void ctrtrs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, cfloat *a, int *lda, cfloat *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);
void ztrtrs_(char *uplo, char *trans, char *diag, int *n, int *nrhs, cdouble *a, int *lda, cdouble *b, int *ldb, int *info, int uplo_len, int trans_len, int diag_len);

/// Computes an RQ factorization of an upper trapezoidal matrix.
void stzrqf_(int *m, int *n, float *a, int *lda, float *tau, int *info);
void dtzrqf_(int *m, int *n, double *a, int *lda, double *tau, int *info);
void ctzrqf_(int *m, int *n, cfloat *a, int *lda, cfloat *tau, int *info);
void ztzrqf_(int *m, int *n, cdouble *a, int *lda, cdouble *tau, int *info);

/// Computes an RZ factorization of an upper trapezoidal matrix
/// (blocked version of STZRQF).
void stzrzf_(int *m, int *n, float *a, int *lda, float *tau, float *work, int *lwork, int *info);
void dtzrzf_(int *m, int *n, double *a, int *lda, double *tau, double *work, int *lwork, int *info);
void ctzrzf_(int *m, int *n, cfloat *a, int *lda, cfloat *tau, cfloat *work, int *lwork, int *info);
void ztzrzf_(int *m, int *n, cdouble *a, int *lda, cdouble *tau, cdouble *work, int *lwork, int *info);


/// Multiplies a general matrix by the unitary
/// transformation matrix from a reduction to tridiagonal form
/// determined by CHPTRD.
void cupmtr_(char *side, char *uplo, char *trans, int *m, int *n, cfloat *ap, cfloat *tau, cfloat *c, int *ldc, cfloat *work, int *info, int side_len, int uplo_len, int trans_len);
void zupmtr_(char *side, char *uplo, char *trans, int *m, int *n, cdouble *ap, cdouble *tau, cdouble *c, int *ldc, cdouble *work, int *info, int side_len, int uplo_len, int trans_len);


//------------------------------------
//     ----- MISC routines -----
//------------------------------------

int ilaenv_(int *ispec, char *name, char *opts, int *n1, int *n2, int *n3, int *n4, int len_name, int len_opts);
void ilaenvset_(int *ispec, char *name, char *opts, int *n1, int *n2, int *n3, int *n4, int *nvalue, int *info, int len_name, int len_opts);

///
float slamch_(char *cmach, int cmach_len);
double dlamch_(char *cmach, int cmach_len);

///
lapack_float_ret_t second_();
double dsecnd_();


