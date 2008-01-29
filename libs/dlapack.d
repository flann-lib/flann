// THIS FILE AUTOMATICALLY GENERATED FROM lapack.d USING wrapprotos.py
// date:  Thu Dec 14 04:22:58 2006

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

module dlapack;
import lapack;

// Prototypes for the raw Fortran interface to BLAS



version (FORTRAN_FLOAT_FUNCTIONS_RETURN_DOUBLE) {
} else {
}

/* LAPACK routines */

//--------------------------------------------------------
// ---- SIMPLE and DIVIDE AND CONQUER DRIVER routines ----
//---------------------------------------------------------

/// Solves a general system of linear equations AX=B.
void gesv(int n, int nrhs, float *a, int lda, int *ipiv, float *b, int ldb, inout int info) {
    sgesv_(&n, &nrhs, a, &lda, ipiv, b, &ldb, &info);
}
void gesv(int n, int nrhs, double *a, int lda, int *ipiv, double *b, int ldb, inout int info) {
    dgesv_(&n, &nrhs, a, &lda, ipiv, b, &ldb, &info);
}
void gesv(int n, int nrhs, cfloat *a, int lda, int *ipiv, cfloat *b, int ldb, inout int info) {
    cgesv_(&n, &nrhs, a, &lda, ipiv, b, &ldb, &info);
}
void gesv(int n, int nrhs, cdouble *a, int lda, int *ipiv, cdouble *b, int ldb, inout int info) {
    zgesv_(&n, &nrhs, a, &lda, ipiv, b, &ldb, &info);
}

/// Solves a general banded system of linear equations AX=B.
void gbsv(int n, int kl, int ku, int nrhs, float *ab, int ldab, int *ipiv, float *b, int ldb, inout int info) {
    sgbsv_(&n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info);
}
void gbsv(int n, int kl, int ku, int nrhs, double *ab, int ldab, int *ipiv, double *b, int ldb, inout int info) {
    dgbsv_(&n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info);
}
void gbsv(int n, int kl, int ku, int nrhs, cfloat *ab, int ldab, int *ipiv, cfloat *b, int ldb, inout int info) {
    cgbsv_(&n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info);
}
void gbsv(int n, int kl, int ku, int nrhs, cdouble *ab, int ldab, int *ipiv, cdouble *b, int ldb, inout int info) {
    zgbsv_(&n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info);
}

/// Solves a general tridiagonal system of linear equations AX=B.
void gtsv(int n, int nrhs, float *dl, float *d, float *du, float *b, int ldb, inout int info) {
    sgtsv_(&n, &nrhs, dl, d, du, b, &ldb, &info);
}
void gtsv(int n, int nrhs, double *dl, double *d, double *du, double *b, int ldb, inout int info) {
    dgtsv_(&n, &nrhs, dl, d, du, b, &ldb, &info);
}
void gtsv(int n, int nrhs, cfloat *dl, cfloat *d, cfloat *du, cfloat *b, int ldb, inout int info) {
    cgtsv_(&n, &nrhs, dl, d, du, b, &ldb, &info);
}
void gtsv(int n, int nrhs, cdouble *dl, cdouble *d, cdouble *du, cdouble *b, int ldb, inout int info) {
    zgtsv_(&n, &nrhs, dl, d, du, b, &ldb, &info);
}

/// Solves a symmetric positive definite system of linear
/// equations AX=B.
void posv(char uplo, int n, int nrhs, float *a, int lda, float *b, int ldb, inout int info) {
    sposv_(&uplo, &n, &nrhs, a, &lda, b, &ldb, &info, 1);
}
void posv(char uplo, int n, int nrhs, double *a, int lda, double *b, int ldb, inout int info) {
    dposv_(&uplo, &n, &nrhs, a, &lda, b, &ldb, &info, 1);
}
void posv(char uplo, int n, int nrhs, cfloat *a, int lda, cfloat *b, int ldb, inout int info) {
    cposv_(&uplo, &n, &nrhs, a, &lda, b, &ldb, &info, 1);
}
void posv(char uplo, int n, int nrhs, cdouble *a, int lda, cdouble *b, int ldb, inout int info) {
    zposv_(&uplo, &n, &nrhs, a, &lda, b, &ldb, &info, 1);
}

/// Solves a symmetric positive definite system of linear
/// equations AX=B, where A is held in packed storage.
void ppsv(char uplo, int n, int nrhs, float *ap, float *b, int ldb, inout int info) {
    sppsv_(&uplo, &n, &nrhs, ap, b, &ldb, &info, 1);
}
void ppsv(char uplo, int n, int nrhs, double *ap, double *b, int ldb, inout int info) {
    dppsv_(&uplo, &n, &nrhs, ap, b, &ldb, &info, 1);
}
void ppsv(char uplo, int n, int nrhs, cfloat *ap, cfloat *b, int ldb, inout int info) {
    cppsv_(&uplo, &n, &nrhs, ap, b, &ldb, &info, 1);
}
void ppsv(char uplo, int n, int nrhs, cdouble *ap, cdouble *b, int ldb, inout int info) {
    zppsv_(&uplo, &n, &nrhs, ap, b, &ldb, &info, 1);
}

/// Solves a symmetric positive definite banded system
/// of linear equations AX=B.
void pbsv(char uplo, int n, int kd, int nrhs, float *ab, int ldab, float *b, int ldb, inout int info) {
    spbsv_(&uplo, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1);
}
void pbsv(char uplo, int n, int kd, int nrhs, double *ab, int ldab, double *b, int ldb, inout int info) {
    dpbsv_(&uplo, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1);
}
void pbsv(char uplo, int n, int kd, int nrhs, cfloat *ab, int ldab, cfloat *b, int ldb, inout int info) {
    cpbsv_(&uplo, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1);
}
void pbsv(char uplo, int n, int kd, int nrhs, cdouble *ab, int ldab, cdouble *b, int ldb, inout int info) {
    zpbsv_(&uplo, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1);
}

/// Solves a symmetric positive definite tridiagonal system
/// of linear equations AX=B.
void ptsv(int n, int nrhs, float *d, float *e, float *b, int ldb, inout int info) {
    sptsv_(&n, &nrhs, d, e, b, &ldb, &info);
}
void ptsv(int n, int nrhs, double *d, double *e, double *b, int ldb, inout int info) {
    dptsv_(&n, &nrhs, d, e, b, &ldb, &info);
}
void ptsv(int n, int nrhs, float *d, cfloat *e, cfloat *b, int ldb, inout int info) {
    cptsv_(&n, &nrhs, d, e, b, &ldb, &info);
}
void ptsv(int n, int nrhs, double *d, cdouble *e, cdouble *b, int ldb, inout int info) {
    zptsv_(&n, &nrhs, d, e, b, &ldb, &info);
}


/// Solves a real symmetric indefinite system of linear equations AX=B.
void sysv(char uplo, int n, int nrhs, float *a, int lda, int *ipiv, float *b, int ldb, float *work, int lwork, inout int info) {
    ssysv_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, work, &lwork, &info, 1);
}
void sysv(char uplo, int n, int nrhs, double *a, int lda, int *ipiv, double *b, int ldb, double *work, int lwork, inout int info) {
    dsysv_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, work, &lwork, &info, 1);
}
void sysv(char uplo, int n, int nrhs, cfloat *a, int lda, int *ipiv, cfloat *b, int ldb, cfloat *work, int lwork, inout int info) {
    csysv_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, work, &lwork, &info, 1);
}
void sysv(char uplo, int n, int nrhs, cdouble *a, int lda, int *ipiv, cdouble *b, int ldb, cdouble *work, int lwork, inout int info) {
    zsysv_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, work, &lwork, &info, 1);
}

/// Solves a complex Hermitian indefinite system of linear equations AX=B.
void hesv(char uplo, int n, int nrhs, cfloat *a, int lda, int *ipiv, cfloat *b, int ldb, cfloat *work, int lwork, inout int info) {
    chesv_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, work, &lwork, &info, 1);
}
void hesv(char uplo, int n, int nrhs, cdouble *a, int lda, int *ipiv, cdouble *b, int ldb, cdouble *work, int lwork, inout int info) {
    zhesv_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, work, &lwork, &info, 1);
}

/// Solves a real symmetric indefinite system of linear equations AX=B,
/// where A is held in packed storage.
void spsv(char uplo, int n, int nrhs, float *ap, int *ipiv, float *b, int ldb, inout int info) {
    sspsv_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}
void spsv(char uplo, int n, int nrhs, double *ap, int *ipiv, double *b, int ldb, inout int info) {
    dspsv_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}
void spsv(char uplo, int n, int nrhs, cfloat *ap, int *ipiv, cfloat *b, int ldb, inout int info) {
    cspsv_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}
void spsv(char uplo, int n, int nrhs, cdouble *ap, int *ipiv, cdouble *b, int ldb, inout int info) {
    zspsv_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}

/// Solves a complex Hermitian indefinite system of linear equations AX=B,
/// where A is held in packed storage.
void hpsv(char uplo, int n, int nrhs, cfloat *ap, int *ipiv, cfloat *b, int ldb, inout int info) {
    chpsv_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}
void hpsv(char uplo, int n, int nrhs, cdouble *ap, int *ipiv, cdouble *b, int ldb, inout int info) {
    zhpsv_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}

/// Computes the least squares solution to an over-determined system
/// of linear equations, A X=B or A**H X=B,  or the minimum norm
/// solution of an under-determined system, where A is a general
/// rectangular matrix of full rank,  using a QR or LQ factorization
/// of A.
void gels(char *trans, int m, int n, int nrhs, float *a, int lda, float *b, int ldb, float *work, int lwork, inout int info) {
    sgels_(trans, &m, &n, &nrhs, a, &lda, b, &ldb, work, &lwork, &info, 1);
}
void gels(char *trans, int m, int n, int nrhs, double *a, int lda, double *b, int ldb, double *work, int lwork, inout int info) {
    dgels_(trans, &m, &n, &nrhs, a, &lda, b, &ldb, work, &lwork, &info, 1);
}
void gels(char *trans, int m, int n, int nrhs, cfloat *a, int lda, cfloat *b, int ldb, cfloat *work, int lwork, inout int info) {
    cgels_(trans, &m, &n, &nrhs, a, &lda, b, &ldb, work, &lwork, &info, 1);
}
void gels(char *trans, int m, int n, int nrhs, cdouble *a, int lda, cdouble *b, int ldb, cdouble *work, int lwork, inout int info) {
    zgels_(trans, &m, &n, &nrhs, a, &lda, b, &ldb, work, &lwork, &info, 1);
}

/// Computes the least squares solution to an over-determined system
/// of linear equations, A X=B or A**H X=B,  or the minimum norm
/// solution of an under-determined system, using a divide and conquer
/// method, where A is a general rectangular matrix of full rank,
/// using a QR or LQ factorization of A.
void gelsd(int m, int n, int nrhs, float *a, int lda, float *b, int ldb, float *s, float rcond, out int rank, float *work, int lwork, int *iwork, inout int info) {
    sgelsd_(&m, &n, &nrhs, a, &lda, b, &ldb, s, &rcond, &rank, work, &lwork, iwork, &info);
}
void gelsd(int m, int n, int nrhs, double *a, int lda, double *b, int ldb, double *s, double rcond, out int rank, double *work, int lwork, int *iwork, inout int info) {
    dgelsd_(&m, &n, &nrhs, a, &lda, b, &ldb, s, &rcond, &rank, work, &lwork, iwork, &info);
}
void gelsd(int m, int n, int nrhs, cfloat *a, int lda, cfloat *b, int ldb, float *s, float rcond, out int rank, cfloat *work, int lwork, float *rwork, int *iwork, inout int info) {
    cgelsd_(&m, &n, &nrhs, a, &lda, b, &ldb, s, &rcond, &rank, work, &lwork, rwork, iwork, &info);
}
void gelsd(int m, int n, int nrhs, cdouble *a, int lda, cdouble *b, int ldb, double *s, double rcond, out int rank, cdouble *work, int lwork, double *rwork, int *iwork, inout int info) {
    zgelsd_(&m, &n, &nrhs, a, &lda, b, &ldb, s, &rcond, &rank, work, &lwork, rwork, iwork, &info);
}

/// Solves the LSE (Constrained Linear Least Squares Problem) using
/// the GRQ (Generalized RQ) factorization
void gglse(int m, int n, int p, float *a, int lda, float *b, int ldb, float *c, float *d, float *x, float *work, int lwork, inout int info) {
    sgglse_(&m, &n, &p, a, &lda, b, &ldb, c, d, x, work, &lwork, &info);
}
void gglse(int m, int n, int p, double *a, int lda, double *b, int ldb, double *c, double *d, double *x, double *work, int lwork, inout int info) {
    dgglse_(&m, &n, &p, a, &lda, b, &ldb, c, d, x, work, &lwork, &info);
}
void gglse(int m, int n, int p, cfloat *a, int lda, cfloat *b, int ldb, cfloat *c, cfloat *d, cfloat *x, cfloat *work, int lwork, inout int info) {
    cgglse_(&m, &n, &p, a, &lda, b, &ldb, c, d, x, work, &lwork, &info);
}
void gglse(int m, int n, int p, cdouble *a, int lda, cdouble *b, int ldb, cdouble *c, cdouble *d, cdouble *x, cdouble *work, int lwork, inout int info) {
    zgglse_(&m, &n, &p, a, &lda, b, &ldb, c, d, x, work, &lwork, &info);
}

/// Solves the GLM (Generalized Linear Regression Model) using
/// the GQR (Generalized QR) factorization
void ggglm(int n, int m, int p, float *a, int lda, float *b, int ldb, float *d, float *x, float *y, float *work, int lwork, inout int info) {
    sggglm_(&n, &m, &p, a, &lda, b, &ldb, d, x, y, work, &lwork, &info);
}
void ggglm(int n, int m, int p, double *a, int lda, double *b, int ldb, double *d, double *x, double *y, double *work, int lwork, inout int info) {
    dggglm_(&n, &m, &p, a, &lda, b, &ldb, d, x, y, work, &lwork, &info);
}
void ggglm(int n, int m, int p, cfloat *a, int lda, cfloat *b, int ldb, cfloat *d, cfloat *x, cfloat *y, cfloat *work, int lwork, inout int info) {
    cggglm_(&n, &m, &p, a, &lda, b, &ldb, d, x, y, work, &lwork, &info);
}
void ggglm(int n, int m, int p, cdouble *a, int lda, cdouble *b, int ldb, cdouble *d, cdouble *x, cdouble *y, cdouble *work, int lwork, inout int info) {
    zggglm_(&n, &m, &p, a, &lda, b, &ldb, d, x, y, work, &lwork, &info);
}

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix.
void syev(char *jobz, char uplo, int n, float *a, int lda, float *w, float *work, int lwork, inout int info) {
    ssyev_(jobz, &uplo, &n, a, &lda, w, work, &lwork, &info, 1, 1);
}
void syev(char *jobz, char uplo, int n, double *a, int lda, double *w, double *work, int lwork, inout int info) {
    dsyev_(jobz, &uplo, &n, a, &lda, w, work, &lwork, &info, 1, 1);
}

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix.
void heev(char *jobz, char uplo, int n, cfloat *a, int lda, float *w, cfloat *work, int lwork, float *rwork, inout int info) {
    cheev_(jobz, &uplo, &n, a, &lda, w, work, &lwork, rwork, &info, 1, 1);
}
void heev(char *jobz, char uplo, int n, cdouble *a, int lda, double *w, cdouble *work, int lwork, double *rwork, inout int info) {
    zheev_(jobz, &uplo, &n, a, &lda, w, work, &lwork, rwork, &info, 1, 1);
}


/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix.  If eigenvectors are desired, it uses a divide
/// and conquer algorithm.
void syevd(char *jobz, char uplo, int n, float *a, int lda, float *w, float *work, int lwork, int *iwork, int liwork, inout int info) {
    ssyevd_(jobz, &uplo, &n, a, &lda, w, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void syevd(char *jobz, char uplo, int n, double *a, int lda, double *w, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dsyevd_(jobz, &uplo, &n, a, &lda, w, work, &lwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix.  If eigenvectors are desired, it uses a divide
/// and conquer algorithm.
void heevd(char *jobz, char uplo, int n, cfloat *a, int lda, float *w, cfloat *work, int lwork, float *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    cheevd_(jobz, &uplo, &n, a, &lda, w, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}
void heevd(char *jobz, char uplo, int n, cdouble *a, int lda, double *w, cdouble *work, int lwork, double *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    zheevd_(jobz, &uplo, &n, a, &lda, w, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix in packed storage.
void spev(char *jobz, char uplo, int n, float *ap, float *w, float *z, int ldz, float *work, inout int info) {
    sspev_(jobz, &uplo, &n, ap, w, z, &ldz, work, &info, 1, 1);
}
void spev(char *jobz, char uplo, int n, double *ap, double *w, double *z, int ldz, double *work, inout int info) {
    dspev_(jobz, &uplo, &n, ap, w, z, &ldz, work, &info, 1, 1);
}

/// Computes selected eigenvalues, and optionally, eigenvectors of a complex
/// Hermitian matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix in packed storage.
void hpev(char *jobz, char uplo, int n, cfloat *ap, float *w, cfloat *z, int ldz, cfloat *work, float *rwork, inout int info) {
    chpev_(jobz, &uplo, &n, ap, w, z, &ldz, work, rwork, &info, 1, 1);
}
void hpev(char *jobz, char uplo, int n, cdouble *ap, double *w, cdouble *z, int ldz, cdouble *work, double *rwork, inout int info) {
    zhpev_(jobz, &uplo, &n, ap, w, z, &ldz, work, rwork, &info, 1, 1);
}

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix in packed storage.  If eigenvectors are desired,
/// it uses a divide and conquer algorithm.
void spevd(char *jobz, char uplo, int n, float *ap, float *w, float *z, int ldz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    sspevd_(jobz, &uplo, &n, ap, w, z, &ldz, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void spevd(char *jobz, char uplo, int n, double *ap, double *w, double *z, int ldz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dspevd_(jobz, &uplo, &n, ap, w, z, &ldz, work, &lwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix in packed storage.  If eigenvectors are desired, it
/// uses a divide and conquer algorithm.
void hpevd(char *jobz, char uplo, int n, cfloat *ap, float *w, cfloat *z, int ldz, cfloat *work, int lwork, float *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    chpevd_(jobz, &uplo, &n, ap, w, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}
void hpevd(char *jobz, char uplo, int n, cdouble *ap, double *w, cdouble *z, int ldz, cdouble *work, int lwork, double *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    zhpevd_(jobz, &uplo, &n, ap, w, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric band matrix.
void sbev(char *jobz, char uplo, int n, int kd, float *ab, int ldab, float *w, float *z, int ldz, float *work, inout int info) {
    ssbev_(jobz, &uplo, &n, &kd, ab, &ldab, w, z, &ldz, work, &info, 1, 1);
}
void sbev(char *jobz, char uplo, int n, int kd, double *ab, int ldab, double *w, double *z, int ldz, double *work, inout int info) {
    dsbev_(jobz, &uplo, &n, &kd, ab, &ldab, w, z, &ldz, work, &info, 1, 1);
}

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian band matrix.
void hbev(char *jobz, char uplo, int n, int kd, cfloat *ab, int ldab, float *w, cfloat *z, int ldz, cfloat *work, float *rwork, inout int info) {
    chbev_(jobz, &uplo, &n, &kd, ab, &ldab, w, z, &ldz, work, rwork, &info, 1, 1);
}
void hbev(char *jobz, char uplo, int n, int kd, cdouble *ab, int ldab, double *w, cdouble *z, int ldz, cdouble *work, double *rwork, inout int info) {
    zhbev_(jobz, &uplo, &n, &kd, ab, &ldab, w, z, &ldz, work, rwork, &info, 1, 1);
}

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric band matrix.  If eigenvectors are desired, it uses a
/// divide and conquer algorithm.
void sbevd(char *jobz, char uplo, int n, int kd, float *ab, int ldab, float *w, float *z, int ldz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    ssbevd_(jobz, &uplo, &n, &kd, ab, &ldab, w, z, &ldz, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void sbevd(char *jobz, char uplo, int n, int kd, double *ab, int ldab, double *w, double *z, int ldz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dsbevd_(jobz, &uplo, &n, &kd, ab, &ldab, w, z, &ldz, work, &lwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian band matrix.  If eigenvectors are desired, it uses a divide
/// and conquer algorithm.
void hbevd(char *jobz, char uplo, int n, int kd, cfloat *ab, int ldab, float *w, cfloat *z, int ldz, cfloat *work, int lwork, float *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    chbevd_(jobz, &uplo, &n, &kd, ab, &ldab, w, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}
void hbevd(char *jobz, char uplo, int n, int kd, cdouble *ab, int ldab, double *w, cdouble *z, int ldz, cdouble *work, int lwork, double *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    zhbevd_(jobz, &uplo, &n, &kd, ab, &ldab, w, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric tridiagonal matrix.
void stev(char *jobz, int n, float *d, float *e, float *z, int ldz, float *work, inout int info) {
    sstev_(jobz, &n, d, e, z, &ldz, work, &info, 1);
}
void stev(char *jobz, int n, double *d, double *e, double *z, int ldz, double *work, inout int info) {
    dstev_(jobz, &n, d, e, z, &ldz, work, &info, 1);
}

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric tridiagonal matrix.  If eigenvectors are desired, it uses
/// a divide and conquer algorithm.
void stevd(char *jobz, int n, float *d, float *e, float *z, int ldz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    sstevd_(jobz, &n, d, e, z, &ldz, work, &lwork, iwork, &liwork, &info, 1);
}
void stevd(char *jobz, int n, double *d, double *e, double *z, int ldz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dstevd_(jobz, &n, d, e, z, &ldz, work, &lwork, iwork, &liwork, &info, 1);
}

/// Computes the eigenvalues and Schur factorization of a general
/// matrix, and orders the factorization so that selected eigenvalues
/// are at the top left of the Schur form.
void gees(char *jobvs, char *sort, FCB_SGEES_SELECT select, int n, float *a, int lda, int sdim, float *wr, float *wi, float *vs, int ldvs, float *work, int lwork, int bwork, inout int info) {
    sgees_(jobvs, sort, select, &n, a, &lda, &sdim, wr, wi, vs, &ldvs, work, &lwork, &bwork, &info, 1, 1);
}
void gees(char *jobvs, char *sort, FCB_DGEES_SELECT select, int n, double *a, int lda, int sdim, double *wr, double *wi, double *vs, int ldvs, double *work, int lwork, int bwork, inout int info) {
    dgees_(jobvs, sort, select, &n, a, &lda, &sdim, wr, wi, vs, &ldvs, work, &lwork, &bwork, &info, 1, 1);
}
void gees(char *jobvs, char *sort, FCB_CGEES_SELECT select, int n, cfloat *a, int lda, int sdim, cfloat *w, cfloat *vs, int ldvs, cfloat *work, int lwork, float *rwork, int bwork, inout int info) {
    cgees_(jobvs, sort, select, &n, a, &lda, &sdim, w, vs, &ldvs, work, &lwork, rwork, &bwork, &info, 1, 1);
}
void gees(char *jobvs, char *sort, FCB_ZGEES_SELECT select, int n, cdouble *a, int lda, int sdim, cdouble *w, cdouble *vs, int ldvs, cdouble *work, int lwork, double *rwork, int bwork, inout int info) {
    zgees_(jobvs, sort, select, &n, a, &lda, &sdim, w, vs, &ldvs, work, &lwork, rwork, &bwork, &info, 1, 1);
}

/// Computes the eigenvalues and left and right eigenvectors of
/// a general matrix.
void geev(char jobvl, char jobvr, int n, float *a, int lda, float *wr, float *wi, float *vl, int ldvl, float *vr, int ldvr, float *work, int lwork, inout int info) {
    sgeev_(&jobvl, &jobvr, &n, a, &lda, wr, wi, vl, &ldvl, vr, &ldvr, work, &lwork, &info, 1, 1);
}
void geev(char jobvl, char jobvr, int n, double *a, int lda, double *wr, double *wi, double *vl, int ldvl, double *vr, int ldvr, double *work, int lwork, inout int info) {
    dgeev_(&jobvl, &jobvr, &n, a, &lda, wr, wi, vl, &ldvl, vr, &ldvr, work, &lwork, &info, 1, 1);
}
void geev(char jobvl, char jobvr, int n, cfloat *a, int lda, cfloat *w, cfloat *vl, int ldvl, cfloat *vr, int ldvr, cfloat *work, int lwork, float *rwork, inout int info) {
    cgeev_(&jobvl, &jobvr, &n, a, &lda, w, vl, &ldvl, vr, &ldvr, work, &lwork, rwork, &info, 1, 1);
}
void geev(char jobvl, char jobvr, int n, cdouble *a, int lda, cdouble *w, cdouble *vl, int ldvl, cdouble *vr, int ldvr, cdouble *work, int lwork, double *rwork, inout int info) {
    zgeev_(&jobvl, &jobvr, &n, a, &lda, w, vl, &ldvl, vr, &ldvr, work, &lwork, rwork, &info, 1, 1);
}

/// Computes the singular value decomposition (SVD) of a general
/// rectangular matrix.
void gesvd(char *jobu, char *jobvt, int m, int n, float *a, int lda, float *s, float *u, int ldu, float *vt, int ldvt, float *work, int lwork, inout int info) {
    sgesvd_(jobu, jobvt, &m, &n, a, &lda, s, u, &ldu, vt, &ldvt, work, &lwork, &info, 1, 1);
}
void gesvd(char *jobu, char *jobvt, int m, int n, double *a, int lda, double *s, double *u, int ldu, double *vt, int ldvt, double *work, int lwork, inout int info) {
    dgesvd_(jobu, jobvt, &m, &n, a, &lda, s, u, &ldu, vt, &ldvt, work, &lwork, &info, 1, 1);
}
void gesvd(char *jobu, char *jobvt, int m, int n, cfloat *a, int lda, float *s, cfloat *u, int ldu, cfloat *vt, int ldvt, cfloat *work, int lwork, float *rwork, inout int info) {
    cgesvd_(jobu, jobvt, &m, &n, a, &lda, s, u, &ldu, vt, &ldvt, work, &lwork, rwork, &info, 1, 1);
}
void gesvd(char *jobu, char *jobvt, int m, int n, cdouble *a, int lda, double *s, cdouble *u, int ldu, cdouble *vt, int ldvt, cdouble *work, int lwork, double *rwork, inout int info) {
    zgesvd_(jobu, jobvt, &m, &n, a, &lda, s, u, &ldu, vt, &ldvt, work, &lwork, rwork, &info, 1, 1);
}

/// Computes the singular value decomposition (SVD) of a general
/// rectangular matrix using divide-and-conquer.
void gesdd(char *jobz, int m, int n, float *a, int lda, float *s, float *u, int ldu, float *vt, int ldvt, float *work, int lwork, int *iwork, inout int info) {
    sgesdd_(jobz, &m, &n, a, &lda, s, u, &ldu, vt, &ldvt, work, &lwork, iwork, &info, 1);
}
void gesdd(char *jobz, int m, int n, double *a, int lda, double *s, double *u, int ldu, double *vt, int ldvt, double *work, int lwork, int *iwork, inout int info) {
    dgesdd_(jobz, &m, &n, a, &lda, s, u, &ldu, vt, &ldvt, work, &lwork, iwork, &info, 1);
}
void gesdd(char *jobz, int m, int n, cfloat *a, int lda, float *s, cfloat *u, int ldu, cfloat *vt, int ldvt, cfloat *work, int lwork, float *rwork, int *iwork, inout int info) {
    cgesdd_(jobz, &m, &n, a, &lda, s, u, &ldu, vt, &ldvt, work, &lwork, rwork, iwork, &info, 1);
}
void gesdd(char *jobz, int m, int n, cdouble *a, int lda, double *s, cdouble *u, int ldu, cdouble *vt, int ldvt, cdouble *work, int lwork, double *rwork, int *iwork, inout int info) {
    zgesdd_(jobz, &m, &n, a, &lda, s, u, &ldu, vt, &ldvt, work, &lwork, rwork, iwork, &info, 1);
}

/// Computes all eigenvalues and the eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void sygv(int itype, char *jobz, char uplo, int n, float *a, int lda, float *b, int ldb, float *w, float *work, int lwork, inout int info) {
    ssygv_(&itype, jobz, &uplo, &n, a, &lda, b, &ldb, w, work, &lwork, &info, 1, 1);
}
void sygv(int itype, char *jobz, char uplo, int n, double *a, int lda, double *b, int ldb, double *w, double *work, int lwork, inout int info) {
    dsygv_(&itype, jobz, &uplo, &n, a, &lda, b, &ldb, w, work, &lwork, &info, 1, 1);
}

/// Computes all eigenvalues and the eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void hegv(int itype, char *jobz, char uplo, int n, cfloat *a, int lda, cfloat *b, int ldb, float *w, cfloat *work, int lwork, float *rwork, inout int info) {
    chegv_(&itype, jobz, &uplo, &n, a, &lda, b, &ldb, w, work, &lwork, rwork, &info, 1, 1);
}
void hegv(int itype, char *jobz, char uplo, int n, cdouble *a, int lda, cdouble *b, int ldb, double *w, cdouble *work, int lwork, double *rwork, inout int info) {
    zhegv_(&itype, jobz, &uplo, &n, a, &lda, b, &ldb, w, work, &lwork, rwork, &info, 1, 1);
}

/// Computes all eigenvalues and the eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void sygvd(int itype, char *jobz, char uplo, int n, float *a, int lda, float *b, int ldb, float *w, float *work, int lwork, int *iwork, int liwork, inout int info) {
    ssygvd_(&itype, jobz, &uplo, &n, a, &lda, b, &ldb, w, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void sygvd(int itype, char *jobz, char uplo, int n, double *a, int lda, double *b, int ldb, double *w, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dsygvd_(&itype, jobz, &uplo, &n, a, &lda, b, &ldb, w, work, &lwork, iwork, &liwork, &info, 1, 1);
}
/// Computes all eigenvalues and the eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void hegvd(int itype, char *jobz, char uplo, int n, cfloat *a, int lda, cfloat *b, int ldb, float *w, cfloat *work, int lwork, float *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    chegvd_(&itype, jobz, &uplo, &n, a, &lda, b, &ldb, w, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}
void hegvd(int itype, char *jobz, char uplo, int n, cdouble *a, int lda, cdouble *b, int ldb, double *w, cdouble *work, int lwork, double *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    zhegvd_(&itype, jobz, &uplo, &n, a, &lda, b, &ldb, w, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all eigenvalues and eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void spgv(int itype, char *jobz, char uplo, int n, float *ap, float *bp, float *w, float *z, int ldz, float *work, inout int info) {
    sspgv_(&itype, jobz, &uplo, &n, ap, bp, w, z, &ldz, work, &info, 1, 1);
}
void spgv(int itype, char *jobz, char uplo, int n, double *ap, double *bp, double *w, double *z, int ldz, double *work, inout int info) {
    dspgv_(&itype, jobz, &uplo, &n, ap, bp, w, z, &ldz, work, &info, 1, 1);
}

/// Computes all eigenvalues and eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void hpgv(int itype, char *jobz, char uplo, int n, cfloat *ap, cfloat *bp, float *w, cfloat *z, int ldz, cfloat *work, float *rwork, inout int info) {
    chpgv_(&itype, jobz, &uplo, &n, ap, bp, w, z, &ldz, work, rwork, &info, 1, 1);
}
void hpgv(int itype, char *jobz, char uplo, int n, cdouble *ap, cdouble *bp, double *w, cdouble *z, int ldz, cdouble *work, double *rwork, inout int info) {
    zhpgv_(&itype, jobz, &uplo, &n, ap, bp, w, z, &ldz, work, rwork, &info, 1, 1);
}

/// Computes all eigenvalues and eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void spgvd(int itype, char *jobz, char uplo, int n, float *ap, float *bp, float *w, float *z, int ldz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    sspgvd_(&itype, jobz, &uplo, &n, ap, bp, w, z, &ldz, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void spgvd(int itype, char *jobz, char uplo, int n, double *ap, double *bp, double *w, double *z, int ldz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dspgvd_(&itype, jobz, &uplo, &n, ap, bp, w, z, &ldz, work, &lwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all eigenvalues and eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void hpgvd(int itype, char *jobz, char uplo, int n, cfloat *ap, cfloat *bp, float *w, cfloat *z, int ldz, cfloat *work, int lwork, float *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    chpgvd_(&itype, jobz, &uplo, &n, ap, bp, w, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}
void hpgvd(int itype, char *jobz, char uplo, int n, cdouble *ap, cdouble *bp, double *w, cdouble *z, int ldz, cdouble *work, int lwork, double *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    zhpgvd_(&itype, jobz, &uplo, &n, ap, bp, w, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a real generalized symmetric-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be symmetric
/// and banded, and B is also positive definite.
void sbgv(char *jobz, char uplo, int n, int ka, int kb, float *ab, int ldab, float *bb, int ldbb, float *w, float *z, int ldz, float *work, inout int info) {
    ssbgv_(jobz, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, w, z, &ldz, work, &info, 1, 1);
}
void sbgv(char *jobz, char uplo, int n, int ka, int kb, double *ab, int ldab, double *bb, int ldbb, double *w, double *z, int ldz, double *work, inout int info) {
    dsbgv_(jobz, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, w, z, &ldz, work, &info, 1, 1);
}

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a complex generalized Hermitian-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be Hermitian
/// and banded, and B is also positive definite.
void hbgv(char *jobz, char uplo, int n, int ka, int kb, cfloat *ab, int ldab, cfloat *bb, int ldbb, float *w, cfloat *z, int ldz, cfloat *work, float *rwork, inout int info) {
    chbgv_(jobz, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, w, z, &ldz, work, rwork, &info, 1, 1);
}
void hbgv(char *jobz, char uplo, int n, int ka, int kb, cdouble *ab, int ldab, cdouble *bb, int ldbb, double *w, cdouble *z, int ldz, cdouble *work, double *rwork, inout int info) {
    zhbgv_(jobz, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, w, z, &ldz, work, rwork, &info, 1, 1);
}

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a real generalized symmetric-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be symmetric
/// and banded, and B is also positive definite.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void sbgvd(char *jobz, char uplo, int n, int ka, int kb, float *ab, int ldab, float *bb, int ldbb, float *w, float *z, int ldz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    ssbgvd_(jobz, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, w, z, &ldz, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void sbgvd(char *jobz, char uplo, int n, int ka, int kb, double *ab, int ldab, double *bb, int ldbb, double *w, double *z, int ldz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dsbgvd_(jobz, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, w, z, &ldz, work, &lwork, iwork, &liwork, &info, 1, 1);
}

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a complex generalized Hermitian-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be Hermitian
/// and banded, and B is also positive definite.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void hbgvd(char *jobz, char uplo, int n, int ka, int kb, cfloat *ab, int ldab, cfloat *bb, int ldbb, float *w, cfloat *z, int ldz, cfloat *work, int lwork, float *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    chbgvd_(jobz, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, w, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}
void hbgvd(char *jobz, char uplo, int n, int ka, int kb, cdouble *ab, int ldab, cdouble *bb, int ldbb, double *w, cdouble *z, int ldz, cdouble *work, int lwork, double *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    zhbgvd_(jobz, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, w, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1);
}

/// Computes the generalized eigenvalues, Schur form, and left and/or
/// right Schur vectors for a pair of nonsymmetric matrices
void gegs(char *jobvsl, char *jobvsr, int n, float *a, int lda, float *b, int ldb, float *alphar, float *alphai, float *betav, float *vsl, int ldvsl, float *vsr, int ldvsr, float *work, int lwork, inout int info) {
    sgegs_(jobvsl, jobvsr, &n, a, &lda, b, &ldb, alphar, alphai, betav, vsl, &ldvsl, vsr, &ldvsr, work, &lwork, &info, 1, 1);
}
void gegs(char *jobvsl, char *jobvsr, int n, double *a, int lda, double *b, int ldb, double *alphar, double *alphai, double *betav, double *vsl, int ldvsl, double *vsr, int ldvsr, double *work, int lwork, inout int info) {
    dgegs_(jobvsl, jobvsr, &n, a, &lda, b, &ldb, alphar, alphai, betav, vsl, &ldvsl, vsr, &ldvsr, work, &lwork, &info, 1, 1);
}
void gegs(char *jobvsl, char *jobvsr, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *alphav, cfloat *betav, cfloat *vsl, int ldvsl, cfloat *vsr, int ldvsr, cfloat *work, int lwork, float *rwork, inout int info) {
    cgegs_(jobvsl, jobvsr, &n, a, &lda, b, &ldb, alphav, betav, vsl, &ldvsl, vsr, &ldvsr, work, &lwork, rwork, &info, 1, 1);
}
void gegs(char *jobvsl, char *jobvsr, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *alphav, cdouble *betav, cdouble *vsl, int ldvsl, cdouble *vsr, int ldvsr, cdouble *work, int lwork, double *rwork, inout int info) {
    zgegs_(jobvsl, jobvsr, &n, a, &lda, b, &ldb, alphav, betav, vsl, &ldvsl, vsr, &ldvsr, work, &lwork, rwork, &info, 1, 1);
}

/// Computes the generalized eigenvalues, Schur form, and left and/or
/// right Schur vectors for a pair of nonsymmetric matrices
void gges(char *jobvsl, char *jobvsr, char *sort, FCB_SGGES_SELCTG selctg, int n, float *a, int lda, float *b, int ldb, int sdim, float *alphar, float *alphai, float *betav, float *vsl, int ldvsl, float *vsr, int ldvsr, float *work, int lwork, int bwork, inout int info) {
    sgges_(jobvsl, jobvsr, sort, selctg, &n, a, &lda, b, &ldb, &sdim, alphar, alphai, betav, vsl, &ldvsl, vsr, &ldvsr, work, &lwork, &bwork, &info, 1, 1, 1);
}
void gges(char *jobvsl, char *jobvsr, char *sort, FCB_DGGES_DELCTG delctg, int n, double *a, int lda, double *b, int ldb, int sdim, double *alphar, double *alphai, double *betav, double *vsl, int ldvsl, double *vsr, int ldvsr, double *work, int lwork, int bwork, inout int info) {
    dgges_(jobvsl, jobvsr, sort, delctg, &n, a, &lda, b, &ldb, &sdim, alphar, alphai, betav, vsl, &ldvsl, vsr, &ldvsr, work, &lwork, &bwork, &info, 1, 1, 1);
}
void gges(char *jobvsl, char *jobvsr, char *sort, FCB_CGGES_SELCTG selctg, int n, cfloat *a, int lda, cfloat *b, int ldb, int sdim, cfloat *alphav, cfloat *betav, cfloat *vsl, int ldvsl, cfloat *vsr, int ldvsr, cfloat *work, int lwork, float *rwork, int bwork, inout int info) {
    cgges_(jobvsl, jobvsr, sort, selctg, &n, a, &lda, b, &ldb, &sdim, alphav, betav, vsl, &ldvsl, vsr, &ldvsr, work, &lwork, rwork, &bwork, &info, 1, 1, 1);
}
void gges(char *jobvsl, char *jobvsr, char *sort, FCB_ZGGES_DELCTG delctg, int n, cdouble *a, int lda, cdouble *b, int ldb, int sdim, cdouble *alphav, cdouble *betav, cdouble *vsl, int ldvsl, cdouble *vsr, int ldvsr, cdouble *work, int lwork, double *rwork, int bwork, inout int info) {
    zgges_(jobvsl, jobvsr, sort, delctg, &n, a, &lda, b, &ldb, &sdim, alphav, betav, vsl, &ldvsl, vsr, &ldvsr, work, &lwork, rwork, &bwork, &info, 1, 1, 1);
}

/// Computes the generalized eigenvalues, and left and/or right
/// generalized eigenvectors for a pair of nonsymmetric matrices
void gegv(char jobvl, char jobvr, int n, float *a, int lda, float *b, int ldb, float *alphar, float *alphai, float *betav, float *vl, int ldvl, float *vr, int ldvr, float *work, int lwork, inout int info) {
    sgegv_(&jobvl, &jobvr, &n, a, &lda, b, &ldb, alphar, alphai, betav, vl, &ldvl, vr, &ldvr, work, &lwork, &info, 1, 1);
}
void gegv(char jobvl, char jobvr, int n, double *a, int lda, double *b, int ldb, double *alphar, double *alphai, double *betav, double *vl, int ldvl, double *vr, int ldvr, double *work, int lwork, inout int info) {
    dgegv_(&jobvl, &jobvr, &n, a, &lda, b, &ldb, alphar, alphai, betav, vl, &ldvl, vr, &ldvr, work, &lwork, &info, 1, 1);
}
void gegv(char jobvl, char jobvr, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *alphar, cfloat *betav, cfloat *vl, int ldvl, cfloat *vr, int ldvr, cfloat *work, int lwork, float *rwork, inout int info) {
    cgegv_(&jobvl, &jobvr, &n, a, &lda, b, &ldb, alphar, betav, vl, &ldvl, vr, &ldvr, work, &lwork, rwork, &info, 1, 1);
}
void gegv(char jobvl, char jobvr, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *alphar, cdouble *betav, cdouble *vl, int ldvl, cdouble *vr, int ldvr, cdouble *work, int lwork, double *rwork, inout int info) {
    zgegv_(&jobvl, &jobvr, &n, a, &lda, b, &ldb, alphar, betav, vl, &ldvl, vr, &ldvr, work, &lwork, rwork, &info, 1, 1);
}

/// Computes the generalized eigenvalues, and left and/or right
/// generalized eigenvectors for a pair of nonsymmetric matrices
void ggev(char jobvl, char jobvr, int n, float *a, int lda, float *b, int ldb, float *alphar, float *alphai, float *betav, float *vl, int ldvl, float *vr, int ldvr, float *work, int lwork, inout int info) {
    sggev_(&jobvl, &jobvr, &n, a, &lda, b, &ldb, alphar, alphai, betav, vl, &ldvl, vr, &ldvr, work, &lwork, &info, 1, 1);
}
void ggev(char jobvl, char jobvr, int n, double *a, int lda, double *b, int ldb, double *alphar, double *alphai, double *betav, double *vl, int ldvl, double *vr, int ldvr, double *work, int lwork, inout int info) {
    dggev_(&jobvl, &jobvr, &n, a, &lda, b, &ldb, alphar, alphai, betav, vl, &ldvl, vr, &ldvr, work, &lwork, &info, 1, 1);
}
void ggev(char jobvl, char jobvr, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *alphav, cfloat *betav, cfloat *vl, int ldvl, cfloat *vr, int ldvr, cfloat *work, int lwork, float *rwork, inout int info) {
    cggev_(&jobvl, &jobvr, &n, a, &lda, b, &ldb, alphav, betav, vl, &ldvl, vr, &ldvr, work, &lwork, rwork, &info, 1, 1);
}
void ggev(char jobvl, char jobvr, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *alphav, cdouble *betav, cdouble *vl, int ldvl, cdouble *vr, int ldvr, cdouble *work, int lwork, double *rwork, inout int info) {
    zggev_(&jobvl, &jobvr, &n, a, &lda, b, &ldb, alphav, betav, vl, &ldvl, vr, &ldvr, work, &lwork, rwork, &info, 1, 1);
}

/// Computes the Generalized Singular Value Decomposition
void ggsvd(char *jobu, char *jobv, char *jobq, int m, int n, int p, int k, int l, float *a, int lda, float *b, int ldb, float *alphav, float *betav, float *u, int ldu, float *v, int ldv, float *q, int ldq, float *work, int *iwork, inout int info) {
    sggsvd_(jobu, jobv, jobq, &m, &n, &p, &k, &l, a, &lda, b, &ldb, alphav, betav, u, &ldu, v, &ldv, q, &ldq, work, iwork, &info, 1, 1, 1);
}
void ggsvd(char *jobu, char *jobv, char *jobq, int m, int n, int p, int k, int l, double *a, int lda, double *b, int ldb, double *alphav, double *betav, double *u, int ldu, double *v, int ldv, double *q, int ldq, double *work, int *iwork, inout int info) {
    dggsvd_(jobu, jobv, jobq, &m, &n, &p, &k, &l, a, &lda, b, &ldb, alphav, betav, u, &ldu, v, &ldv, q, &ldq, work, iwork, &info, 1, 1, 1);
}
void ggsvd(char *jobu, char *jobv, char *jobq, int m, int n, int p, int k, int l, cfloat *a, int lda, cfloat *b, int ldb, float *alphav, float *betav, cfloat *u, int ldu, cfloat *v, int ldv, cfloat *q, int ldq, cfloat *work, float *rwork, int *iwork, inout int info) {
    cggsvd_(jobu, jobv, jobq, &m, &n, &p, &k, &l, a, &lda, b, &ldb, alphav, betav, u, &ldu, v, &ldv, q, &ldq, work, rwork, iwork, &info, 1, 1, 1);
}
void ggsvd(char *jobu, char *jobv, char *jobq, int m, int n, int p, int k, int l, cdouble *a, int lda, cdouble *b, int ldb, double *alphav, double *betav, cdouble *u, int ldu, cdouble *v, int ldv, cdouble *q, int ldq, cdouble *work, double *rwork, int *iwork, inout int info) {
    zggsvd_(jobu, jobv, jobq, &m, &n, &p, &k, &l, a, &lda, b, &ldb, alphav, betav, u, &ldu, v, &ldv, q, &ldq, work, rwork, iwork, &info, 1, 1, 1);
}

//-----------------------------------------------------
//       ---- EXPERT and RRR DRIVER routines ----
//-----------------------------------------------------

/// Solves a general system of linear equations AX=B, A**T X=B
/// or A**H X=B, and provides an estimate of the condition number
/// and error bounds on the solution.
void gesvx(char *fact, char *trans, int n, int nrhs, float *a, int lda, float *af, int ldaf, int *ipiv, char *equed, float *r, float *c, float *b, int ldb, float *x, int ldx, float rcond, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sgesvx_(fact, trans, &n, &nrhs, a, &lda, af, &ldaf, ipiv, equed, r, c, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void gesvx(char *fact, char *trans, int n, int nrhs, double *a, int lda, double *af, int ldaf, int *ipiv, char *equed, double *r, double *c, double *b, int ldb, double *x, int ldx, double rcond, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dgesvx_(fact, trans, &n, &nrhs, a, &lda, af, &ldaf, ipiv, equed, r, c, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void gesvx(char *fact, char *trans, int n, int nrhs, cfloat *a, int lda, cfloat *af, int ldaf, int *ipiv, char *equed, float *r, float *c, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cgesvx_(fact, trans, &n, &nrhs, a, &lda, af, &ldaf, ipiv, equed, r, c, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}
void gesvx(char *fact, char *trans, int n, int nrhs, cdouble *a, int lda, cdouble *af, int ldaf, int *ipiv, char *equed, double *r, double *c, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zgesvx_(fact, trans, &n, &nrhs, a, &lda, af, &ldaf, ipiv, equed, r, c, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}

/// Solves a general banded system of linear equations AX=B,
/// A**T X=B or A**H X=B, and provides an estimate of the condition
/// number and error bounds on the solution.
void gbsvx(char *fact, char *trans, int n, int kl, int ku, int nrhs, float *ab, int ldab, float *afb, int ldafb, int *ipiv, char *equed, float *r, float *c, float *b, int ldb, float *x, int ldx, float rcond, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sgbsvx_(fact, trans, &n, &kl, &ku, &nrhs, ab, &ldab, afb, &ldafb, ipiv, equed, r, c, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void gbsvx(char *fact, char *trans, int n, int kl, int ku, int nrhs, double *ab, int ldab, double *afb, int ldafb, int *ipiv, char *equed, double *r, double *c, double *b, int ldb, double *x, int ldx, double rcond, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dgbsvx_(fact, trans, &n, &kl, &ku, &nrhs, ab, &ldab, afb, &ldafb, ipiv, equed, r, c, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void gbsvx(char *fact, char *trans, int n, int kl, int ku, int nrhs, cfloat *ab, int ldab, cfloat *afb, int ldafb, int *ipiv, char *equed, float *r, float *c, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cgbsvx_(fact, trans, &n, &kl, &ku, &nrhs, ab, &ldab, afb, &ldafb, ipiv, equed, r, c, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}
void gbsvx(char *fact, char *trans, int n, int kl, int ku, int nrhs, cdouble *ab, int ldab, cdouble *afb, int ldafb, int *ipiv, char *equed, double *r, double *c, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zgbsvx_(fact, trans, &n, &kl, &ku, &nrhs, ab, &ldab, afb, &ldafb, ipiv, equed, r, c, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}

/// Solves a general tridiagonal system of linear equations AX=B,
/// A**T X=B or A**H X=B, and provides an estimate of the condition
/// number  and error bounds on the solution.
void gtsvx(char *fact, char *trans, int n, int nrhs, float *dl, float *d, float *du, float *dlf, float *df, float *duf, float *du2, int *ipiv, float *b, int ldb, float *x, int ldx, float rcond, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sgtsvx_(fact, trans, &n, &nrhs, dl, d, du, dlf, df, duf, du2, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1);
}
void gtsvx(char *fact, char *trans, int n, int nrhs, double *dl, double *d, double *du, double *dlf, double *df, double *duf, double *du2, int *ipiv, double *b, int ldb, double *x, int ldx, double rcond, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dgtsvx_(fact, trans, &n, &nrhs, dl, d, du, dlf, df, duf, du2, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1);
}
void gtsvx(char *fact, char *trans, int n, int nrhs, cfloat *dl, cfloat *d, cfloat *du, cfloat *dlf, cfloat *df, cfloat *duf, cfloat *du2, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cgtsvx_(fact, trans, &n, &nrhs, dl, d, du, dlf, df, duf, du2, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1);
}
void gtsvx(char *fact, char *trans, int n, int nrhs, cdouble *dl, cdouble *d, cdouble *du, cdouble *dlf, cdouble *df, cdouble *duf, cdouble *du2, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zgtsvx_(fact, trans, &n, &nrhs, dl, d, du, dlf, df, duf, du2, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1);
}

/// Solves a symmetric positive definite system of linear
/// equations AX=B, and provides an estimate of the condition number
/// and error bounds on the solution.
void posvx(char *fact, char uplo, int n, int nrhs, float *a, int lda, float *af, int ldaf, char *equed, float *s, float *b, int ldb, float *x, int ldx, float rcond, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sposvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void posvx(char *fact, char uplo, int n, int nrhs, double *a, int lda, double *af, int ldaf, char *equed, double *s, double *b, int ldb, double *x, int ldx, double rcond, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dposvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void posvx(char *fact, char uplo, int n, int nrhs, cfloat *a, int lda, cfloat *af, int ldaf, char *equed, float *s, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cposvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}
void posvx(char *fact, char uplo, int n, int nrhs, cdouble *a, int lda, cdouble *af, int ldaf, char *equed, double *s, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zposvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}

/// Solves a symmetric positive definite system of linear
/// equations AX=B, where A is held in packed storage, and provides
/// an estimate of the condition number and error bounds on the
/// solution.
void ppsvx(char *fact, char uplo, int n, int nrhs, float *ap, float *afp, char *equed, float *s, float *b, int ldb, float *x, int ldx, float rcond, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sppsvx_(fact, &uplo, &n, &nrhs, ap, afp, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void ppsvx(char *fact, char uplo, int n, int nrhs, double *ap, double *afp, char *equed, double *s, double *b, int ldb, double *x, int ldx, double rcond, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dppsvx_(fact, &uplo, &n, &nrhs, ap, afp, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void ppsvx(char *fact, char uplo, int n, int nrhs, cfloat *ap, cfloat *afp, char *equed, float *s, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cppsvx_(fact, &uplo, &n, &nrhs, ap, afp, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}
void ppsvx(char *fact, char uplo, int n, int nrhs, cdouble *ap, cdouble *afp, char *equed, double *s, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zppsvx_(fact, &uplo, &n, &nrhs, ap, afp, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}

/// Solves a symmetric positive definite banded system
/// of linear equations AX=B, and provides an estimate of the condition
/// number and error bounds on the solution.
void pbsvx(char *fact, char uplo, int n, int kd, int nrhs, float *ab, int ldab, float *afb, int ldafb, char *equed, float *s, float *b, int ldb, float *x, int ldx, float rcond, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    spbsvx_(fact, &uplo, &n, &kd, &nrhs, ab, &ldab, afb, &ldafb, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void pbsvx(char *fact, char uplo, int n, int kd, int nrhs, double *ab, int ldab, double *afb, int ldafb, char *equed, double *s, double *b, int ldb, double *x, int ldx, double rcond, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dpbsvx_(fact, &uplo, &n, &kd, &nrhs, ab, &ldab, afb, &ldafb, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void pbsvx(char *fact, char uplo, int n, int kd, int nrhs, cfloat *ab, int ldab, cfloat *afb, int ldafb, char *equed, float *s, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cpbsvx_(fact, &uplo, &n, &kd, &nrhs, ab, &ldab, afb, &ldafb, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}
void pbsvx(char *fact, char uplo, int n, int kd, int nrhs, cdouble *ab, int ldab, cdouble *afb, int ldafb, char *equed, double *s, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zpbsvx_(fact, &uplo, &n, &kd, &nrhs, ab, &ldab, afb, &ldafb, equed, s, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1, 1);
}

/// Solves a symmetric positive definite tridiagonal
/// system of linear equations AX=B, and provides an estimate of
/// the condition number and error bounds on the solution.
void ptsvx(char *fact, int n, int nrhs, float *d, float *e, float *df, float *ef, float *b, int ldb, float *x, int ldx, float rcond, float *ferr, float *berr, float *work, inout int info) {
    sptsvx_(fact, &n, &nrhs, d, e, df, ef, b, &ldb, x, &ldx, &rcond, ferr, berr, work, &info, 1);
}
void ptsvx(char *fact, int n, int nrhs, double *d, double *e, double *df, double *ef, double *b, int ldb, double *x, int ldx, double rcond, double *ferr, double *berr, double *work, inout int info) {
    dptsvx_(fact, &n, &nrhs, d, e, df, ef, b, &ldb, x, &ldx, &rcond, ferr, berr, work, &info, 1);
}
void ptsvx(char *fact, int n, int nrhs, float *d, cfloat *e, float *df, cfloat *ef, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cptsvx_(fact, &n, &nrhs, d, e, df, ef, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1);
}
void ptsvx(char *fact, int n, int nrhs, double *d, cdouble *e, double *df, cdouble *ef, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zptsvx_(fact, &n, &nrhs, d, e, df, ef, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1);
}

/// Solves a real symmetric
/// indefinite system  of linear equations AX=B, and provides an
/// estimate of the condition number and error bounds on the solution.
void sysvx(char *fact, char uplo, int n, int nrhs, float *a, int lda, float *af, int ldaf, int *ipiv, float *b, int ldb, float *x, int ldx, float rcond, float *ferr, float *berr, float *work, int lwork, int *iwork, inout int info) {
    ssysvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, &lwork, iwork, &info, 1, 1);
}
void sysvx(char *fact, char uplo, int n, int nrhs, double *a, int lda, double *af, int ldaf, int *ipiv, double *b, int ldb, double *x, int ldx, double rcond, double *ferr, double *berr, double *work, int lwork, int *iwork, inout int info) {
    dsysvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, &lwork, iwork, &info, 1, 1);
}
void sysvx(char *fact, char uplo, int n, int nrhs, cfloat *a, int lda, cfloat *af, int ldaf, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, int lwork, float *rwork, inout int info) {
    csysvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, &lwork, rwork, &info, 1, 1);
}
void sysvx(char *fact, char uplo, int n, int nrhs, cdouble *a, int lda, cdouble *af, int ldaf, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, int lwork, double *rwork, inout int info) {
    zsysvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, &lwork, rwork, &info, 1, 1);
}

/// Solves a complex Hermitian
/// indefinite system  of linear equations AX=B, and provides an
/// estimate of the condition number and error bounds on the solution.
void hesvx(char *fact, char uplo, int n, int nrhs, cfloat *a, int lda, cfloat *af, int ldaf, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, int lwork, float *rwork, inout int info) {
    chesvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, &lwork, rwork, &info, 1, 1);
}
void hesvx(char *fact, char uplo, int n, int nrhs, cdouble *a, int lda, cdouble *af, int ldaf, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, int lwork, double *rwork, inout int info) {
    zhesvx_(fact, &uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, &lwork, rwork, &info, 1, 1);
}

/// Solves a real symmetric
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, and provides an estimate of the condition
/// number and error bounds on the solution.
void spsvx(char *fact, char uplo, int n, int nrhs, float *ap, float *afp, int *ipiv, float *b, int ldb, float *x, int ldx, float rcond, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sspsvx_(fact, &uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1);
}
void spsvx(char *fact, char uplo, int n, int nrhs, double *ap, double *afp, int *ipiv, double *b, int ldb, double *x, int ldx, double rcond, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dspsvx_(fact, &uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, iwork, &info, 1, 1);
}
void spsvx(char *fact, char uplo, int n, int nrhs, cfloat *ap, cfloat *afp, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cspsvx_(fact, &uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1);
}
void spsvx(char *fact, char uplo, int n, int nrhs, cdouble *ap, cdouble *afp, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zspsvx_(fact, &uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1);
}

/// Solves a complex Hermitian
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, and provides an estimate of the condition
/// number and error bounds on the solution.
void hpsvx(char *fact, char uplo, int n, int nrhs, cfloat *ap, cfloat *afp, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float rcond, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    chpsvx_(fact, &uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1);
}
void hpsvx(char *fact, char uplo, int n, int nrhs, cdouble *ap, cdouble *afp, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double rcond, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zhpsvx_(fact, &uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, &rcond, ferr, berr, work, rwork, &info, 1, 1);
}

/// Computes the minimum norm least squares solution to an over-
/// or under-determined system of linear equations A X=B, using a
/// complete orthogonal factorization of A.
void gelsx(int m, int n, int nrhs, float *a, int lda, float *b, int ldb, int jpvt, float rcond, out int rank, float *work, inout int info) {
    sgelsx_(&m, &n, &nrhs, a, &lda, b, &ldb, &jpvt, &rcond, &rank, work, &info);
}
void gelsx(int m, int n, int nrhs, double *a, int lda, double *b, int ldb, int jpvt, double rcond, out int rank, double *work, inout int info) {
    dgelsx_(&m, &n, &nrhs, a, &lda, b, &ldb, &jpvt, &rcond, &rank, work, &info);
}
void gelsx(int m, int n, int nrhs, cfloat *a, int lda, cfloat *b, int ldb, int jpvt, float rcond, out int rank, cfloat *work, float *rwork, inout int info) {
    cgelsx_(&m, &n, &nrhs, a, &lda, b, &ldb, &jpvt, &rcond, &rank, work, rwork, &info);
}
void gelsx(int m, int n, int nrhs, cdouble *a, int lda, cdouble *b, int ldb, int jpvt, double rcond, out int rank, cdouble *work, double *rwork, inout int info) {
    zgelsx_(&m, &n, &nrhs, a, &lda, b, &ldb, &jpvt, &rcond, &rank, work, rwork, &info);
}

/// Computes the minimum norm least squares solution to an over-
/// or under-determined system of linear equations A X=B, using a
/// complete orthogonal factorization of A.
void gelsy(int m, int n, int nrhs, float *a, int lda, float *b, int ldb, int jpvt, float rcond, out int rank, float *work, int lwork, inout int info) {
    sgelsy_(&m, &n, &nrhs, a, &lda, b, &ldb, &jpvt, &rcond, &rank, work, &lwork, &info);
}
void gelsy(int m, int n, int nrhs, double *a, int lda, double *b, int ldb, int jpvt, double rcond, out int rank, double *work, int lwork, inout int info) {
    dgelsy_(&m, &n, &nrhs, a, &lda, b, &ldb, &jpvt, &rcond, &rank, work, &lwork, &info);
}
void gelsy(int m, int n, int nrhs, cfloat *a, int lda, cfloat *b, int ldb, int jpvt, float rcond, out int rank, cfloat *work, int lwork, float *rwork, inout int info) {
    cgelsy_(&m, &n, &nrhs, a, &lda, b, &ldb, &jpvt, &rcond, &rank, work, &lwork, rwork, &info);
}
void gelsy(int m, int n, int nrhs, cdouble *a, int lda, cdouble *b, int ldb, int jpvt, double rcond, out int rank, cdouble *work, int lwork, double *rwork, inout int info) {
    zgelsy_(&m, &n, &nrhs, a, &lda, b, &ldb, &jpvt, &rcond, &rank, work, &lwork, rwork, &info);
}

/// Computes the minimum norm least squares solution to an over-
/// or under-determined system of linear equations A X=B,  using
/// the singular value decomposition of A.
void gelss(int m, int n, int nrhs, float *a, int lda, float *b, int ldb, float *s, float rcond, out int rank, float *work, int lwork, inout int info) {
    sgelss_(&m, &n, &nrhs, a, &lda, b, &ldb, s, &rcond, &rank, work, &lwork, &info);
}
void gelss(int m, int n, int nrhs, double *a, int lda, double *b, int ldb, double *s, double rcond, out int rank, double *work, int lwork, inout int info) {
    dgelss_(&m, &n, &nrhs, a, &lda, b, &ldb, s, &rcond, &rank, work, &lwork, &info);
}
void gelss(int m, int n, int nrhs, cfloat *a, int lda, cfloat *b, int ldb, float *s, float rcond, out int rank, cfloat *work, int lwork, float *rwork, inout int info) {
    cgelss_(&m, &n, &nrhs, a, &lda, b, &ldb, s, &rcond, &rank, work, &lwork, rwork, &info);
}
void gelss(int m, int n, int nrhs, cdouble *a, int lda, cdouble *b, int ldb, double *s, double rcond, out int rank, cdouble *work, int lwork, double *rwork, inout int info) {
    zgelss_(&m, &n, &nrhs, a, &lda, b, &ldb, s, &rcond, &rank, work, &lwork, rwork, &info);
}

/// Computes selected eigenvalues and eigenvectors of a symmetric matrix.
void syevx(char *jobz, char *range, char uplo, int n, float *a, int lda, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, float *work, int lwork, int *iwork, int ifail, inout int info) {
    ssyevx_(jobz, range, &uplo, &n, a, &lda, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, &lwork, iwork, &ifail, &info, 1, 1, 1);
}
void syevx(char *jobz, char *range, char uplo, int n, double *a, int lda, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, double *work, int lwork, int *iwork, int ifail, inout int info) {
    dsyevx_(jobz, range, &uplo, &n, a, &lda, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, &lwork, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues and eigenvectors of a Hermitian matrix.
void heevx(char *jobz, char *range, char uplo, int n, cfloat *a, int lda, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, cfloat *z, int ldz, cfloat *work, int lwork, float *rwork, int *iwork, int ifail, inout int info) {
    cheevx_(jobz, range, &uplo, &n, a, &lda, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, &lwork, rwork, iwork, &ifail, &info, 1, 1, 1);
}
void heevx(char *jobz, char *range, char uplo, int n, cdouble *a, int lda, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, cdouble *z, int ldz, cdouble *work, int lwork, double *rwork, int *iwork, int ifail, inout int info) {
    zheevx_(jobz, range, &uplo, &n, a, &lda, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, &lwork, rwork, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
void syevr(char *jobz, char *range, char uplo, int n, float *a, int lda, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, int isuppz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    ssyevr_(jobz, range, &uplo, &n, a, &lda, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, iwork, &liwork, &info, 1, 1, 1);
}
void syevr(char *jobz, char *range, char uplo, int n, double *a, int lda, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, int isuppz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dsyevr_(jobz, range, &uplo, &n, a, &lda, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, iwork, &liwork, &info, 1, 1, 1);
}

/// Computes selected eigenvalues, and optionally, eigenvectors of a complex
/// Hermitian matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
void heevr(char *jobz, char *range, char uplo, int n, cfloat *a, int lda, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, cfloat *z, int ldz, int isuppz, cfloat *work, int lwork, float *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    cheevr_(jobz, range, &uplo, &n, a, &lda, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1, 1);
}
void heevr(char *jobz, char *range, char uplo, int n, cdouble *a, int lda, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, cdouble *z, int ldz, int isuppz, cdouble *work, int lwork, double *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    zheevr_(jobz, range, &uplo, &n, a, &lda, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1, 1, 1);
}


/// Computes selected eigenvalues, and optionally, the eigenvectors of
/// a generalized symmetric-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void sygvx(int itype, char *jobz, char *range, char uplo, int n, float *a, int lda, float *b, int ldb, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, float *work, int lwork, int *iwork, int ifail, inout int info) {
    ssygvx_(&itype, jobz, range, &uplo, &n, a, &lda, b, &ldb, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, &lwork, iwork, &ifail, &info, 1, 1, 1);
}
void sygvx(int itype, char *jobz, char *range, char uplo, int n, double *a, int lda, double *b, int ldb, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, double *work, int lwork, int *iwork, int ifail, inout int info) {
    dsygvx_(&itype, jobz, range, &uplo, &n, a, &lda, b, &ldb, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, &lwork, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues, and optionally, the eigenvectors of
/// a generalized Hermitian-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void hegvx(int itype, char *jobz, char *range, char uplo, int n, cfloat *a, int lda, cfloat *b, int ldb, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, cfloat *z, int ldz, cfloat *work, int lwork, float *rwork, int *iwork, int ifail, inout int info) {
    chegvx_(&itype, jobz, range, &uplo, &n, a, &lda, b, &ldb, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, &lwork, rwork, iwork, &ifail, &info, 1, 1, 1);
}
void hegvx(int itype, char *jobz, char *range, char uplo, int n, cdouble *a, int lda, cdouble *b, int ldb, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, cdouble *z, int ldz, cdouble *work, int lwork, double *rwork, int *iwork, int ifail, inout int info) {
    zhegvx_(&itype, jobz, range, &uplo, &n, a, &lda, b, &ldb, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, &lwork, rwork, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues and eigenvectors of a
/// symmetric matrix in packed storage.
void spevx(char *jobz, char *range, char uplo, int n, float *ap, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, float *work, int *iwork, int ifail, inout int info) {
    sspevx_(jobz, range, &uplo, &n, ap, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1, 1);
}
void spevx(char *jobz, char *range, char uplo, int n, double *ap, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, double *work, int *iwork, int ifail, inout int info) {
    dspevx_(jobz, range, &uplo, &n, ap, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues and eigenvectors of a
/// Hermitian matrix in packed storage.
void hpevx(char *jobz, char *range, char uplo, int n, cfloat *ap, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, cfloat *z, int ldz, cfloat *work, float *rwork, int *iwork, int ifail, inout int info) {
    chpevx_(jobz, range, &uplo, &n, ap, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, rwork, iwork, &ifail, &info, 1, 1, 1);
}
void hpevx(char *jobz, char *range, char uplo, int n, cdouble *ap, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, cdouble *z, int ldz, cdouble *work, double *rwork, int *iwork, int ifail, inout int info) {
    zhpevx_(jobz, range, &uplo, &n, ap, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, rwork, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues, and optionally, eigenvectors of
/// a generalized symmetric-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void spgvx(int itype, char *jobz, char *range, char uplo, int n, float *ap, float *bp, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, float *work, int *iwork, int ifail, inout int info) {
    sspgvx_(&itype, jobz, range, &uplo, &n, ap, bp, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1, 1);
}
void spgvx(int itype, char *jobz, char *range, char uplo, int n, double *ap, double *bp, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, double *work, int *iwork, int ifail, inout int info) {
    dspgvx_(&itype, jobz, range, &uplo, &n, ap, bp, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues, and optionally, the eigenvectors of
/// a generalized Hermitian-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void hpgvx(int itype, char *jobz, char *range, char uplo, int n, cfloat *ap, cfloat *bp, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, cfloat *z, int ldz, cfloat *work, float *rwork, int *iwork, int ifail, inout int info) {
    chpgvx_(&itype, jobz, range, &uplo, &n, ap, bp, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, rwork, iwork, &ifail, &info, 1, 1, 1);
}
void hpgvx(int itype, char *jobz, char *range, char uplo, int n, cdouble *ap, cdouble *bp, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, cdouble *z, int ldz, cdouble *work, double *rwork, int *iwork, int ifail, inout int info) {
    zhpgvx_(&itype, jobz, range, &uplo, &n, ap, bp, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, rwork, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues and eigenvectors of a
/// symmetric band matrix.
void sbevx(char *jobz, char *range, char uplo, int n, int kd, float *ab, int ldab, float *q, int ldq, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, float *work, int *iwork, int ifail, inout int info) {
    ssbevx_(jobz, range, &uplo, &n, &kd, ab, &ldab, q, &ldq, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1, 1);
}
void sbevx(char *jobz, char *range, char uplo, int n, int kd, double *ab, int ldab, double *q, int ldq, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, double *work, int *iwork, int ifail, inout int info) {
    dsbevx_(jobz, range, &uplo, &n, &kd, ab, &ldab, q, &ldq, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues and eigenvectors of a
/// Hermitian band matrix.
void hbevx(char *jobz, char *range, char uplo, int n, int kd, cfloat *ab, int ldab, cfloat *q, int ldq, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, cfloat *z, int ldz, cfloat *work, float *rwork, int *iwork, int ifail, inout int info) {
    chbevx_(jobz, range, &uplo, &n, &kd, ab, &ldab, q, &ldq, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, rwork, iwork, &ifail, &info, 1, 1, 1);
}
void hbevx(char *jobz, char *range, char uplo, int n, int kd, cdouble *ab, int ldab, cdouble *q, int ldq, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, cdouble *z, int ldz, cdouble *work, double *rwork, int *iwork, int ifail, inout int info) {
    zhbevx_(jobz, range, &uplo, &n, &kd, ab, &ldab, q, &ldq, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, rwork, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues, and optionally, the eigenvectors
/// of a real generalized symmetric-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be symmetric
/// and banded, and B is also positive definite.
void sbgvx(char *jobz, char *range, char uplo, int n, int ka, int kb, float *ab, int ldab, float *bb, int ldbb, float *q, int ldq, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, float *work, int *iwork, int ifail, inout int info) {
    ssbgvx_(jobz, range, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, q, &ldq, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1, 1);
}
void sbgvx(char *jobz, char *range, char uplo, int n, int ka, int kb, double *ab, int ldab, double *bb, int ldbb, double *q, int ldq, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, double *work, int *iwork, int ifail, inout int info) {
    dsbgvx_(jobz, range, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, q, &ldq, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues, and optionally, the eigenvectors
/// of a complex generalized Hermitian-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be Hermitian
/// and banded, and B is also positive definite.
void hbgvx(char *jobz, char *range, char uplo, int n, int ka, int kb, cfloat *ab, int ldab, cfloat *bb, int ldbb, cfloat *q, int ldq, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, cfloat *z, int ldz, cfloat *work, float *rwork, int *iwork, int ifail, inout int info) {
    chbgvx_(jobz, range, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, q, &ldq, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, rwork, iwork, &ifail, &info, 1, 1, 1);
}
void hbgvx(char *jobz, char *range, char uplo, int n, int ka, int kb, cdouble *ab, int ldab, cdouble *bb, int ldbb, cdouble *q, int ldq, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, cdouble *z, int ldz, cdouble *work, double *rwork, int *iwork, int ifail, inout int info) {
    zhbgvx_(jobz, range, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, q, &ldq, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, rwork, iwork, &ifail, &info, 1, 1, 1);
}

/// Computes selected eigenvalues and eigenvectors of a real
/// symmetric tridiagonal matrix.
void stevx(char *jobz, char *range, int n, float *d, float *e, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, float *work, int *iwork, int ifail, inout int info) {
    sstevx_(jobz, range, &n, d, e, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1);
}
void stevx(char *jobz, char *range, int n, double *d, double *e, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, double *work, int *iwork, int ifail, inout int info) {
    dstevx_(jobz, range, &n, d, e, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, work, iwork, &ifail, &info, 1, 1);
}

/// Computes selected eigenvalues, and optionally, eigenvectors of a real
/// symmetric tridiagonal matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
void stevr(char *jobz, char *range, int n, float *d, float *e, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, int isuppz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    sstevr_(jobz, range, &n, d, e, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void stevr(char *jobz, char *range, int n, double *d, double *e, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, int isuppz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dstevr_(jobz, range, &n, d, e, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, iwork, &liwork, &info, 1, 1);
}

/// Computes the eigenvalues and Schur factorization of a general
/// matrix, orders the factorization so that selected eigenvalues
/// are at the top left of the Schur form, and computes reciprocal
/// condition numbers for the average of the selected eigenvalues,
/// and for the associated right invariant subspace.
void geesx(char *jobvs, char *sort, FCB_SGEESX_SELECT select, char *sense, int n, float *a, int lda, int sdim, float *wr, float *wi, float *vs, int ldvs, float *rconde, float *rcondv, float *work, int lwork, int *iwork, int liwork, int bwork, inout int info) {
    sgeesx_(jobvs, sort, select, sense, &n, a, &lda, &sdim, wr, wi, vs, &ldvs, rconde, rcondv, work, &lwork, iwork, &liwork, &bwork, &info, 1, 1, 1);
}
void geesx(char *jobvs, char *sort, FCB_DGEESX_SELECT select, char *sense, int n, double *a, int lda, int sdim, double *wr, double *wi, double *vs, int ldvs, double *rconde, double *rcondv, double *work, int lwork, int *iwork, int liwork, int bwork, inout int info) {
    dgeesx_(jobvs, sort, select, sense, &n, a, &lda, &sdim, wr, wi, vs, &ldvs, rconde, rcondv, work, &lwork, iwork, &liwork, &bwork, &info, 1, 1, 1);
}
void geesx(char *jobvs, char *sort, FCB_CGEESX_SELECT select, char *sense, int n, cfloat *a, int lda, int sdim, cfloat *w, cfloat *vs, int ldvs, float *rconde, float *rcondv, cfloat *work, int lwork, float *rwork, int bwork, inout int info) {
    cgeesx_(jobvs, sort, select, sense, &n, a, &lda, &sdim, w, vs, &ldvs, rconde, rcondv, work, &lwork, rwork, &bwork, &info, 1, 1, 1);
}
void geesx(char *jobvs, char *sort, FCB_ZGEESX_SELECT select, char *sense, int n, cdouble *a, int lda, int sdim, cdouble *w, cdouble *vs, int ldvs, double *rconde, double *rcondv, cdouble *work, int lwork, double *rwork, int bwork, inout int info) {
    zgeesx_(jobvs, sort, select, sense, &n, a, &lda, &sdim, w, vs, &ldvs, rconde, rcondv, work, &lwork, rwork, &bwork, &info, 1, 1, 1);
}

/// Computes the generalized eigenvalues, the real Schur form, and,
/// optionally, the left and/or right matrices of Schur vectors.
void ggesx(char *jobvsl, char *jobvsr, char *sort, FCB_SGGESX_SELCTG selctg, char *sense, int n, float *a, int lda, float *b, int ldb, int sdim, float *alphar, float *alphai, float *betav, float *vsl, int ldvsl, float *vsr, int ldvsr, float *rconde, float *rcondv, float *work, int lwork, int *iwork, int liwork, int bwork, inout int info) {
    sggesx_(jobvsl, jobvsr, sort, selctg, sense, &n, a, &lda, b, &ldb, &sdim, alphar, alphai, betav, vsl, &ldvsl, vsr, &ldvsr, rconde, rcondv, work, &lwork, iwork, &liwork, &bwork, &info, 1, 1, 1, 1);
}
void ggesx(char *jobvsl, char *jobvsr, char *sort, FCB_DGGESX_DELCTG delctg, char *sense, int n, double *a, int lda, double *b, int ldb, int sdim, double *alphar, double *alphai, double *betav, double *vsl, int ldvsl, double *vsr, int ldvsr, double *rconde, double *rcondv, double *work, int lwork, int *iwork, int liwork, int bwork, inout int info) {
    dggesx_(jobvsl, jobvsr, sort, delctg, sense, &n, a, &lda, b, &ldb, &sdim, alphar, alphai, betav, vsl, &ldvsl, vsr, &ldvsr, rconde, rcondv, work, &lwork, iwork, &liwork, &bwork, &info, 1, 1, 1, 1);
}
void ggesx(char *jobvsl, char *jobvsr, char *sort, FCB_CGGESX_SELCTG selctg, char *sense, int n, cfloat *a, int lda, cfloat *b, int ldb, int sdim, cfloat *alphav, cfloat *betav, cfloat *vsl, int ldvsl, cfloat *vsr, int ldvsr, float *rconde, float *rcondv, cfloat *work, int lwork, float *rwork, int *iwork, int liwork, int bwork, inout int info) {
    cggesx_(jobvsl, jobvsr, sort, selctg, sense, &n, a, &lda, b, &ldb, &sdim, alphav, betav, vsl, &ldvsl, vsr, &ldvsr, rconde, rcondv, work, &lwork, rwork, iwork, &liwork, &bwork, &info, 1, 1, 1, 1);
}
void ggesx(char *jobvsl, char *jobvsr, char *sort, FCB_ZGGESX_DELCTG delctg, char *sense, int n, cdouble *a, int lda, cdouble *b, int ldb, int sdim, cdouble *alphav, cdouble *betav, cdouble *vsl, int ldvsl, cdouble *vsr, int ldvsr, double *rconde, double *rcondv, cdouble *work, int lwork, double *rwork, int *iwork, int liwork, int bwork, inout int info) {
    zggesx_(jobvsl, jobvsr, sort, delctg, sense, &n, a, &lda, b, &ldb, &sdim, alphav, betav, vsl, &ldvsl, vsr, &ldvsr, rconde, rcondv, work, &lwork, rwork, iwork, &liwork, &bwork, &info, 1, 1, 1, 1);
}

/// Computes the eigenvalues and left and right eigenvectors of
/// a general matrix,  with preliminary balancing of the matrix,
/// and computes reciprocal condition numbers for the eigenvalues
/// and right eigenvectors.
void geevx(char *balanc, char jobvl, char jobvr, char *sense, int n, float *a, int lda, float *wr, float *wi, float *vl, int ldvl, float *vr, int ldvr, int ilo, int ihi, float *scale, float *abnrm, float *rconde, float *rcondv, float *work, int lwork, int *iwork, inout int info) {
    sgeevx_(balanc, &jobvl, &jobvr, sense, &n, a, &lda, wr, wi, vl, &ldvl, vr, &ldvr, &ilo, &ihi, scale, abnrm, rconde, rcondv, work, &lwork, iwork, &info, 1, 1, 1, 1);
}
void geevx(char *balanc, char jobvl, char jobvr, char *sense, int n, double *a, int lda, double *wr, double *wi, double *vl, int ldvl, double *vr, int ldvr, int ilo, int ihi, double *scale, double *abnrm, double *rconde, double *rcondv, double *work, int lwork, int *iwork, inout int info) {
    dgeevx_(balanc, &jobvl, &jobvr, sense, &n, a, &lda, wr, wi, vl, &ldvl, vr, &ldvr, &ilo, &ihi, scale, abnrm, rconde, rcondv, work, &lwork, iwork, &info, 1, 1, 1, 1);
}
void geevx(char *balanc, char jobvl, char jobvr, char *sense, int n, cfloat *a, int lda, cfloat *w, cfloat *vl, int ldvl, cfloat *vr, int ldvr, int ilo, int ihi, float *scale, float *abnrm, float *rconde, float *rcondv, cfloat *work, int lwork, float *rwork, inout int info) {
    cgeevx_(balanc, &jobvl, &jobvr, sense, &n, a, &lda, w, vl, &ldvl, vr, &ldvr, &ilo, &ihi, scale, abnrm, rconde, rcondv, work, &lwork, rwork, &info, 1, 1, 1, 1);
}
void geevx(char *balanc, char jobvl, char jobvr, char *sense, int n, cdouble *a, int lda, cdouble *w, cdouble *vl, int ldvl, cdouble *vr, int ldvr, int ilo, int ihi, double *scale, double *abnrm, double *rconde, double *rcondv, cdouble *work, int lwork, double *rwork, inout int info) {
    zgeevx_(balanc, &jobvl, &jobvr, sense, &n, a, &lda, w, vl, &ldvl, vr, &ldvr, &ilo, &ihi, scale, abnrm, rconde, rcondv, work, &lwork, rwork, &info, 1, 1, 1, 1);
}

/// Computes the generalized eigenvalues, and optionally, the left
/// and/or right generalized eigenvectors.
void ggevx(char *balanc, char jobvl, char jobvr, char *sense, int n, float *a, int lda, float *b, int ldb, float *alphar, float *alphai, float *betav, float *vl, int ldvl, float *vr, int ldvr, int ilo, int ihi, float *lscale, float *rscale, float *abnrm, float *bbnrm, float *rconde, float *rcondv, float *work, int lwork, int *iwork, int bwork, inout int info) {
    sggevx_(balanc, &jobvl, &jobvr, sense, &n, a, &lda, b, &ldb, alphar, alphai, betav, vl, &ldvl, vr, &ldvr, &ilo, &ihi, lscale, rscale, abnrm, bbnrm, rconde, rcondv, work, &lwork, iwork, &bwork, &info, 1, 1, 1, 1);
}
void ggevx(char *balanc, char jobvl, char jobvr, char *sense, int n, double *a, int lda, double *b, int ldb, double *alphar, double *alphai, double *betav, double *vl, int ldvl, double *vr, int ldvr, int ilo, int ihi, double *lscale, double *rscale, double *abnrm, double *bbnrm, double *rconde, double *rcondv, double *work, int lwork, int *iwork, int bwork, inout int info) {
    dggevx_(balanc, &jobvl, &jobvr, sense, &n, a, &lda, b, &ldb, alphar, alphai, betav, vl, &ldvl, vr, &ldvr, &ilo, &ihi, lscale, rscale, abnrm, bbnrm, rconde, rcondv, work, &lwork, iwork, &bwork, &info, 1, 1, 1, 1);
}
void ggevx(char *balanc, char jobvl, char jobvr, char *sense, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *alphav, cfloat *betav, cfloat *vl, int ldvl, cfloat *vr, int ldvr, int ilo, int ihi, float *lscale, float *rscale, float *abnrm, float *bbnrm, float *rconde, float *rcondv, cfloat *work, int lwork, float *rwork, int *iwork, int bwork, inout int info) {
    cggevx_(balanc, &jobvl, &jobvr, sense, &n, a, &lda, b, &ldb, alphav, betav, vl, &ldvl, vr, &ldvr, &ilo, &ihi, lscale, rscale, abnrm, bbnrm, rconde, rcondv, work, &lwork, rwork, iwork, &bwork, &info, 1, 1, 1, 1);
}
void ggevx(char *balanc, char jobvl, char jobvr, char *sense, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *alphav, cdouble *betav, cdouble *vl, int ldvl, cdouble *vr, int ldvr, int ilo, int ihi, double *lscale, double *rscale, double *abnrm, double *bbnrm, double *rconde, double *rcondv, cdouble *work, int lwork, double *rwork, int *iwork, int bwork, inout int info) {
    zggevx_(balanc, &jobvl, &jobvr, sense, &n, a, &lda, b, &ldb, alphav, betav, vl, &ldvl, vr, &ldvr, &ilo, &ihi, lscale, rscale, abnrm, bbnrm, rconde, rcondv, work, &lwork, rwork, iwork, &bwork, &info, 1, 1, 1, 1);
}



//----------------------------------------
//    ---- COMPUTATIONAL routines ----
//----------------------------------------


/// Computes the singular value decomposition (SVD) of a real bidiagonal
/// matrix, using a divide and conquer method.
void bdsdc(char uplo, char *compq, int n, float *d, float *e, float *u, int ldu, float *vt, int ldvt, float *q, int iq, float *work, int *iwork, inout int info) {
    sbdsdc_(&uplo, compq, &n, d, e, u, &ldu, vt, &ldvt, q, &iq, work, iwork, &info, 1, 1);
}
void bdsdc(char uplo, char *compq, int n, double *d, double *e, double *u, int ldu, double *vt, int ldvt, double *q, int iq, double *work, int *iwork, inout int info) {
    dbdsdc_(&uplo, compq, &n, d, e, u, &ldu, vt, &ldvt, q, &iq, work, iwork, &info, 1, 1);
}

/// Computes the singular value decomposition (SVD) of a real bidiagonal
/// matrix, using the bidiagonal QR algorithm.
void bdsqr(char uplo, int n, int ncvt, int nru, int ncc, float *d, float *e, float *vt, int ldvt, float *u, int ldu, float *c, int ldc, float *work, inout int info) {
    sbdsqr_(&uplo, &n, &ncvt, &nru, &ncc, d, e, vt, &ldvt, u, &ldu, c, &ldc, work, &info, 1);
}
void bdsqr(char uplo, int n, int ncvt, int nru, int ncc, double *d, double *e, double *vt, int ldvt, double *u, int ldu, double *c, int ldc, double *work, inout int info) {
    dbdsqr_(&uplo, &n, &ncvt, &nru, &ncc, d, e, vt, &ldvt, u, &ldu, c, &ldc, work, &info, 1);
}
void bdsqr(char uplo, int n, int ncvt, int nru, int ncc, float *d, float *e, cfloat *vt, int ldvt, cfloat *u, int ldu, cfloat *c, int ldc, float *rwork, inout int info) {
    cbdsqr_(&uplo, &n, &ncvt, &nru, &ncc, d, e, vt, &ldvt, u, &ldu, c, &ldc, rwork, &info, 1);
}
void bdsqr(char uplo, int n, int ncvt, int nru, int ncc, double *d, double *e, cdouble *vt, int ldvt, cdouble *u, int ldu, cdouble *c, int ldc, double *rwork, inout int info) {
    zbdsqr_(&uplo, &n, &ncvt, &nru, &ncc, d, e, vt, &ldvt, u, &ldu, c, &ldc, rwork, &info, 1);
}

/// Computes the reciprocal condition numbers for the eigenvectors of a
/// real symmetric or complex Hermitian matrix or for the left or right
/// singular vectors of a general matrix.
void disna(char *job, int m, int n, float *d, float *sep, inout int info) {
    sdisna_(job, &m, &n, d, sep, &info, 1);
}
void disna(char *job, int m, int n, double *d, double *sep, inout int info) {
    ddisna_(job, &m, &n, d, sep, &info, 1);
}

/// Reduces a general band matrix to real upper bidiagonal form
/// by an orthogonal transformation.
void gbbrd(char *vect, int m, int n, int ncc, int kl, int ku, float *ab, int ldab, float *d, float *e, float *q, int ldq, float *pt, int ldpt, float *c, int ldc, float *work, inout int info) {
    sgbbrd_(vect, &m, &n, &ncc, &kl, &ku, ab, &ldab, d, e, q, &ldq, pt, &ldpt, c, &ldc, work, &info, 1);
}
void gbbrd(char *vect, int m, int n, int ncc, int kl, int ku, double *ab, int ldab, double *d, double *e, double *q, int ldq, double *pt, int ldpt, double *c, int ldc, double *work, inout int info) {
    dgbbrd_(vect, &m, &n, &ncc, &kl, &ku, ab, &ldab, d, e, q, &ldq, pt, &ldpt, c, &ldc, work, &info, 1);
}
void gbbrd(char *vect, int m, int n, int ncc, int kl, int ku, cfloat *ab, int ldab, float *d, float *e, cfloat *q, int ldq, cfloat *pt, int ldpt, cfloat *c, int ldc, cfloat *work, float *rwork, inout int info) {
    cgbbrd_(vect, &m, &n, &ncc, &kl, &ku, ab, &ldab, d, e, q, &ldq, pt, &ldpt, c, &ldc, work, rwork, &info, 1);
}
void gbbrd(char *vect, int m, int n, int ncc, int kl, int ku, cdouble *ab, int ldab, double *d, double *e, cdouble *q, int ldq, cdouble *pt, int ldpt, cdouble *c, int ldc, cdouble *work, double *rwork, inout int info) {
    zgbbrd_(vect, &m, &n, &ncc, &kl, &ku, ab, &ldab, d, e, q, &ldq, pt, &ldpt, c, &ldc, work, rwork, &info, 1);
}

/// Estimates the reciprocal of the condition number of a general
/// band matrix, in either the 1-norm or the infinity-norm, using
/// the LU factorization computed by SGBTRF.
void gbcon(char *norm, int n, int kl, int ku, float *ab, int ldab, int *ipiv, float *anorm, float rcond, float *work, int *iwork, inout int info) {
    sgbcon_(norm, &n, &kl, &ku, ab, &ldab, ipiv, anorm, &rcond, work, iwork, &info, 1);
}
void gbcon(char *norm, int n, int kl, int ku, double *ab, int ldab, int *ipiv, double *anorm, double rcond, double *work, int *iwork, inout int info) {
    dgbcon_(norm, &n, &kl, &ku, ab, &ldab, ipiv, anorm, &rcond, work, iwork, &info, 1);
}
void gbcon(char *norm, int n, int kl, int ku, cfloat *ab, int ldab, int *ipiv, float *anorm, float rcond, cfloat *work, float *rwork, inout int info) {
    cgbcon_(norm, &n, &kl, &ku, ab, &ldab, ipiv, anorm, &rcond, work, rwork, &info, 1);
}
void gbcon(char *norm, int n, int kl, int ku, cdouble *ab, int ldab, int *ipiv, double *anorm, double rcond, cdouble *work, double *rwork, inout int info) {
    zgbcon_(norm, &n, &kl, &ku, ab, &ldab, ipiv, anorm, &rcond, work, rwork, &info, 1);
}

/// Computes row and column scalings to equilibrate a general band
/// matrix and reduce its condition number.
void gbequ(int m, int n, int kl, int ku, float *ab, int ldab, float *r, float *c, float *rowcnd, float *colcnd, float *amax, inout int info) {
    sgbequ_(&m, &n, &kl, &ku, ab, &ldab, r, c, rowcnd, colcnd, amax, &info);
}
void gbequ(int m, int n, int kl, int ku, double *ab, int ldab, double *r, double *c, double *rowcnd, double *colcnd, double *amax, inout int info) {
    dgbequ_(&m, &n, &kl, &ku, ab, &ldab, r, c, rowcnd, colcnd, amax, &info);
}
void gbequ(int m, int n, int kl, int ku, cfloat *ab, int ldab, float *r, float *c, float *rowcnd, float *colcnd, float *amax, inout int info) {
    cgbequ_(&m, &n, &kl, &ku, ab, &ldab, r, c, rowcnd, colcnd, amax, &info);
}
void gbequ(int m, int n, int kl, int ku, cdouble *ab, int ldab, double *r, double *c, double *rowcnd, double *colcnd, double *amax, inout int info) {
    zgbequ_(&m, &n, &kl, &ku, ab, &ldab, r, c, rowcnd, colcnd, amax, &info);
}

/// Improves the computed solution to a general banded system of
/// linear equations AX=B, A**T X=B or A**H X=B, and provides forward
/// and backward error bounds for the solution.
void gbrfs(char *trans, int n, int kl, int ku, int nrhs, float *ab, int ldab, float *afb, int ldafb, int *ipiv, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sgbrfs_(trans, &n, &kl, &ku, &nrhs, ab, &ldab, afb, &ldafb, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void gbrfs(char *trans, int n, int kl, int ku, int nrhs, double *ab, int ldab, double *afb, int ldafb, int *ipiv, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dgbrfs_(trans, &n, &kl, &ku, &nrhs, ab, &ldab, afb, &ldafb, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void gbrfs(char *trans, int n, int kl, int ku, int nrhs, cfloat *ab, int ldab, cfloat *afb, int ldafb, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cgbrfs_(trans, &n, &kl, &ku, &nrhs, ab, &ldab, afb, &ldafb, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void gbrfs(char *trans, int n, int kl, int ku, int nrhs, cdouble *ab, int ldab, cdouble *afb, int ldafb, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zgbrfs_(trans, &n, &kl, &ku, &nrhs, ab, &ldab, afb, &ldafb, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Computes an LU factorization of a general band matrix, using
/// partial pivoting with row interchanges.
void gbtrf(int m, int n, int kl, int ku, float *ab, int ldab, int *ipiv, inout int info) {
    sgbtrf_(&m, &n, &kl, &ku, ab, &ldab, ipiv, &info);
}
void gbtrf(int m, int n, int kl, int ku, double *ab, int ldab, int *ipiv, inout int info) {
    dgbtrf_(&m, &n, &kl, &ku, ab, &ldab, ipiv, &info);
}
void gbtrf(int m, int n, int kl, int ku, cfloat *ab, int ldab, int *ipiv, inout int info) {
    cgbtrf_(&m, &n, &kl, &ku, ab, &ldab, ipiv, &info);
}
void gbtrf(int m, int n, int kl, int ku, cdouble *ab, int ldab, int *ipiv, inout int info) {
    zgbtrf_(&m, &n, &kl, &ku, ab, &ldab, ipiv, &info);
}

/// Solves a general banded system of linear equations AX=B,
/// A**T X=B or A**H X=B, using the LU factorization computed
/// by SGBTRF.
void gbtrs(char *trans, int n, int kl, int ku, int nrhs, float *ab, int ldab, int *ipiv, float *b, int ldb, inout int info) {
    sgbtrs_(trans, &n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info, 1);
}
void gbtrs(char *trans, int n, int kl, int ku, int nrhs, double *ab, int ldab, int *ipiv, double *b, int ldb, inout int info) {
    dgbtrs_(trans, &n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info, 1);
}
void gbtrs(char *trans, int n, int kl, int ku, int nrhs, cfloat *ab, int ldab, int *ipiv, cfloat *b, int ldb, inout int info) {
    cgbtrs_(trans, &n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info, 1);
}
void gbtrs(char *trans, int n, int kl, int ku, int nrhs, cdouble *ab, int ldab, int *ipiv, cdouble *b, int ldb, inout int info) {
    zgbtrs_(trans, &n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info, 1);
}

/// Transforms eigenvectors of a balanced matrix to those of the
/// original matrix supplied to SGEBAL.
void gebak(char *job, char side, int n, int ilo, int ihi, float *scale, int m, float *v, int ldv, inout int info) {
    sgebak_(job, &side, &n, &ilo, &ihi, scale, &m, v, &ldv, &info, 1, 1);
}
void gebak(char *job, char side, int n, int ilo, int ihi, double *scale, int m, double *v, int ldv, inout int info) {
    dgebak_(job, &side, &n, &ilo, &ihi, scale, &m, v, &ldv, &info, 1, 1);
}
void gebak(char *job, char side, int n, int ilo, int ihi, float *scale, int m, cfloat *v, int ldv, inout int info) {
    cgebak_(job, &side, &n, &ilo, &ihi, scale, &m, v, &ldv, &info, 1, 1);
}
void gebak(char *job, char side, int n, int ilo, int ihi, double *scale, int m, cdouble *v, int ldv, inout int info) {
    zgebak_(job, &side, &n, &ilo, &ihi, scale, &m, v, &ldv, &info, 1, 1);
}

/// Balances a general matrix in order to improve the accuracy
/// of computed eigenvalues.
void gebal(char *job, int n, float *a, int lda, int ilo, int ihi, float *scale, inout int info) {
    sgebal_(job, &n, a, &lda, &ilo, &ihi, scale, &info, 1);
}
void gebal(char *job, int n, double *a, int lda, int ilo, int ihi, double *scale, inout int info) {
    dgebal_(job, &n, a, &lda, &ilo, &ihi, scale, &info, 1);
}
void gebal(char *job, int n, cfloat *a, int lda, int ilo, int ihi, float *scale, inout int info) {
    cgebal_(job, &n, a, &lda, &ilo, &ihi, scale, &info, 1);
}
void gebal(char *job, int n, cdouble *a, int lda, int ilo, int ihi, double *scale, inout int info) {
    zgebal_(job, &n, a, &lda, &ilo, &ihi, scale, &info, 1);
}

/// Reduces a general rectangular matrix to real bidiagonal form
/// by an orthogonal transformation.
void gebrd(int m, int n, float *a, int lda, float *d, float *e, float *tauq, float *taup, float *work, int lwork, inout int info) {
    sgebrd_(&m, &n, a, &lda, d, e, tauq, taup, work, &lwork, &info);
}
void gebrd(int m, int n, double *a, int lda, double *d, double *e, double *tauq, double *taup, double *work, int lwork, inout int info) {
    dgebrd_(&m, &n, a, &lda, d, e, tauq, taup, work, &lwork, &info);
}
void gebrd(int m, int n, cfloat *a, int lda, float *d, float *e, cfloat *tauq, cfloat *taup, cfloat *work, int lwork, inout int info) {
    cgebrd_(&m, &n, a, &lda, d, e, tauq, taup, work, &lwork, &info);
}
void gebrd(int m, int n, cdouble *a, int lda, double *d, double *e, cdouble *tauq, cdouble *taup, cdouble *work, int lwork, inout int info) {
    zgebrd_(&m, &n, a, &lda, d, e, tauq, taup, work, &lwork, &info);
}

/// Estimates the reciprocal of the condition number of a general
/// matrix, in either the 1-norm or the infinity-norm, using the
/// LU factorization computed by SGETRF.
void gecon(char *norm, int n, float *a, int lda, float *anorm, float rcond, float *work, int *iwork, inout int info) {
    sgecon_(norm, &n, a, &lda, anorm, &rcond, work, iwork, &info, 1);
}
void gecon(char *norm, int n, double *a, int lda, double *anorm, double rcond, double *work, int *iwork, inout int info) {
    dgecon_(norm, &n, a, &lda, anorm, &rcond, work, iwork, &info, 1);
}
void gecon(char *norm, int n, cfloat *a, int lda, float *anorm, float rcond, cfloat *work, float *rwork, inout int info) {
    cgecon_(norm, &n, a, &lda, anorm, &rcond, work, rwork, &info, 1);
}
void gecon(char *norm, int n, cdouble *a, int lda, double *anorm, double rcond, cdouble *work, double *rwork, inout int info) {
    zgecon_(norm, &n, a, &lda, anorm, &rcond, work, rwork, &info, 1);
}

/// Computes row and column scalings to equilibrate a general
/// rectangular matrix and reduce its condition number.
void geequ(int m, int n, float *a, int lda, float *r, float *c, float *rowcnd, float *colcnd, float *amax, inout int info) {
    sgeequ_(&m, &n, a, &lda, r, c, rowcnd, colcnd, amax, &info);
}
void geequ(int m, int n, double *a, int lda, double *r, double *c, double *rowcnd, double *colcnd, double *amax, inout int info) {
    dgeequ_(&m, &n, a, &lda, r, c, rowcnd, colcnd, amax, &info);
}
void geequ(int m, int n, cfloat *a, int lda, float *r, float *c, float *rowcnd, float *colcnd, float *amax, inout int info) {
    cgeequ_(&m, &n, a, &lda, r, c, rowcnd, colcnd, amax, &info);
}
void geequ(int m, int n, cdouble *a, int lda, double *r, double *c, double *rowcnd, double *colcnd, double *amax, inout int info) {
    zgeequ_(&m, &n, a, &lda, r, c, rowcnd, colcnd, amax, &info);
}

/// Reduces a general matrix to upper Hessenberg form by an
/// orthogonal similarity transformation.
void gehrd(int n, int ilo, int ihi, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sgehrd_(&n, &ilo, &ihi, a, &lda, tau, work, &lwork, &info);
}
void gehrd(int n, int ilo, int ihi, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dgehrd_(&n, &ilo, &ihi, a, &lda, tau, work, &lwork, &info);
}
void gehrd(int n, int ilo, int ihi, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cgehrd_(&n, &ilo, &ihi, a, &lda, tau, work, &lwork, &info);
}
void gehrd(int n, int ilo, int ihi, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zgehrd_(&n, &ilo, &ihi, a, &lda, tau, work, &lwork, &info);
}

/// Computes an LQ factorization of a general rectangular matrix.
void gelqf(int m, int n, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sgelqf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void gelqf(int m, int n, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dgelqf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void gelqf(int m, int n, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cgelqf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void gelqf(int m, int n, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zgelqf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}

/// Computes a QL factorization of a general rectangular matrix.
void geqlf(int m, int n, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sgeqlf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void geqlf(int m, int n, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dgeqlf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void geqlf(int m, int n, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cgeqlf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void geqlf(int m, int n, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zgeqlf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}

/// Computes a QR factorization with column pivoting of a general
/// rectangular matrix using Level 3 BLAS.
void geqp3(int m, int n, float *a, int lda, int jpvt, float *tau, float *work, int lwork, inout int info) {
    sgeqp3_(&m, &n, a, &lda, &jpvt, tau, work, &lwork, &info);
}
void geqp3(int m, int n, double *a, int lda, int jpvt, double *tau, double *work, int lwork, inout int info) {
    dgeqp3_(&m, &n, a, &lda, &jpvt, tau, work, &lwork, &info);
}
void geqp3(int m, int n, cfloat *a, int lda, int jpvt, cfloat *tau, cfloat *work, int lwork, float *rwork, inout int info) {
    cgeqp3_(&m, &n, a, &lda, &jpvt, tau, work, &lwork, rwork, &info);
}
void geqp3(int m, int n, cdouble *a, int lda, int jpvt, cdouble *tau, cdouble *work, int lwork, double *rwork, inout int info) {
    zgeqp3_(&m, &n, a, &lda, &jpvt, tau, work, &lwork, rwork, &info);
}

/// Computes a QR factorization with column pivoting of a general
/// rectangular matrix.
void geqpf(int m, int n, float *a, int lda, int jpvt, float *tau, float *work, inout int info) {
    sgeqpf_(&m, &n, a, &lda, &jpvt, tau, work, &info);
}
void geqpf(int m, int n, double *a, int lda, int jpvt, double *tau, double *work, inout int info) {
    dgeqpf_(&m, &n, a, &lda, &jpvt, tau, work, &info);
}
void geqpf(int m, int n, cfloat *a, int lda, int jpvt, cfloat *tau, cfloat *work, float *rwork, inout int info) {
    cgeqpf_(&m, &n, a, &lda, &jpvt, tau, work, rwork, &info);
}
void geqpf(int m, int n, cdouble *a, int lda, int jpvt, cdouble *tau, cdouble *work, double *rwork, inout int info) {
    zgeqpf_(&m, &n, a, &lda, &jpvt, tau, work, rwork, &info);
}

/// Computes a QR factorization of a general rectangular matrix.
void geqrf(int m, int n, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sgeqrf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void geqrf(int m, int n, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dgeqrf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void geqrf(int m, int n, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cgeqrf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void geqrf(int m, int n, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zgeqrf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}

/// Improves the computed solution to a general system of linear
/// equations AX=B, A**T X=B or A**H X=B, and provides forward and
/// backward error bounds for the solution.
void gerfs(char *trans, int n, int nrhs, float *a, int lda, float *af, int ldaf, int *ipiv, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sgerfs_(trans, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void gerfs(char *trans, int n, int nrhs, double *a, int lda, double *af, int ldaf, int *ipiv, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dgerfs_(trans, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void gerfs(char *trans, int n, int nrhs, cfloat *a, int lda, cfloat *af, int ldaf, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cgerfs_(trans, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void gerfs(char *trans, int n, int nrhs, cdouble *a, int lda, cdouble *af, int ldaf, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zgerfs_(trans, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Computes an RQ factorization of a general rectangular matrix.
void gerqf(int m, int n, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sgerqf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void gerqf(int m, int n, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dgerqf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void gerqf(int m, int n, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cgerqf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void gerqf(int m, int n, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zgerqf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}

/// Computes an LU factorization of a general matrix, using partial
/// pivoting with row interchanges.
void getrf(int m, int n, float *a, int lda, int *ipiv, inout int info) {
    sgetrf_(&m, &n, a, &lda, ipiv, &info);
}
void getrf(int m, int n, double *a, int lda, int *ipiv, inout int info) {
    dgetrf_(&m, &n, a, &lda, ipiv, &info);
}
void getrf(int m, int n, cfloat *a, int lda, int *ipiv, inout int info) {
    cgetrf_(&m, &n, a, &lda, ipiv, &info);
}
void getrf(int m, int n, cdouble *a, int lda, int *ipiv, inout int info) {
    zgetrf_(&m, &n, a, &lda, ipiv, &info);
}

/// Computes the inverse of a general matrix, using the LU factorization
/// computed by SGETRF.
void getri(int n, float *a, int lda, int *ipiv, float *work, int lwork, inout int info) {
    sgetri_(&n, a, &lda, ipiv, work, &lwork, &info);
}
void getri(int n, double *a, int lda, int *ipiv, double *work, int lwork, inout int info) {
    dgetri_(&n, a, &lda, ipiv, work, &lwork, &info);
}
void getri(int n, cfloat *a, int lda, int *ipiv, cfloat *work, int lwork, inout int info) {
    cgetri_(&n, a, &lda, ipiv, work, &lwork, &info);
}
void getri(int n, cdouble *a, int lda, int *ipiv, cdouble *work, int lwork, inout int info) {
    zgetri_(&n, a, &lda, ipiv, work, &lwork, &info);
}

/// Solves a general system of linear equations AX=B, A**T X=B
/// or A**H X=B, using the LU factorization computed by SGETRF.
void getrs(char *trans, int n, int nrhs, float *a, int lda, int *ipiv, float *b, int ldb, inout int info) {
    sgetrs_(trans, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}
void getrs(char *trans, int n, int nrhs, double *a, int lda, int *ipiv, double *b, int ldb, inout int info) {
    dgetrs_(trans, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}
void getrs(char *trans, int n, int nrhs, cfloat *a, int lda, int *ipiv, cfloat *b, int ldb, inout int info) {
    cgetrs_(trans, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}
void getrs(char *trans, int n, int nrhs, cdouble *a, int lda, int *ipiv, cdouble *b, int ldb, inout int info) {
    zgetrs_(trans, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}

/// Forms the right or left eigenvectors of the generalized eigenvalue
/// problem by backward transformation on the computed eigenvectors of
/// the balanced pair of matrices output by SGGBAL.
void ggbak(char *job, char side, int n, int ilo, int ihi, float *lscale, float *rscale, int m, float *v, int ldv, inout int info) {
    sggbak_(job, &side, &n, &ilo, &ihi, lscale, rscale, &m, v, &ldv, &info, 1, 1);
}
void ggbak(char *job, char side, int n, int ilo, int ihi, double *lscale, double *rscale, int m, double *v, int ldv, inout int info) {
    dggbak_(job, &side, &n, &ilo, &ihi, lscale, rscale, &m, v, &ldv, &info, 1, 1);
}
void ggbak(char *job, char side, int n, int ilo, int ihi, float *lscale, float *rscale, int m, cfloat *v, int ldv, inout int info) {
    cggbak_(job, &side, &n, &ilo, &ihi, lscale, rscale, &m, v, &ldv, &info, 1, 1);
}
void ggbak(char *job, char side, int n, int ilo, int ihi, double *lscale, double *rscale, int m, cdouble *v, int ldv, inout int info) {
    zggbak_(job, &side, &n, &ilo, &ihi, lscale, rscale, &m, v, &ldv, &info, 1, 1);
}

/// Balances a pair of general real matrices for the generalized
/// eigenvalue problem A x = lambda B x.
void ggbal(char *job, int n, float *a, int lda, float *b, int ldb, int ilo, int ihi, float *lscale, float *rscale, float *work, inout int info) {
    sggbal_(job, &n, a, &lda, b, &ldb, &ilo, &ihi, lscale, rscale, work, &info, 1);
}
void ggbal(char *job, int n, double *a, int lda, double *b, int ldb, int ilo, int ihi, double *lscale, double *rscale, double *work, inout int info) {
    dggbal_(job, &n, a, &lda, b, &ldb, &ilo, &ihi, lscale, rscale, work, &info, 1);
}
void ggbal(char *job, int n, cfloat *a, int lda, cfloat *b, int ldb, int ilo, int ihi, float *lscale, float *rscale, float *work, inout int info) {
    cggbal_(job, &n, a, &lda, b, &ldb, &ilo, &ihi, lscale, rscale, work, &info, 1);
}
void ggbal(char *job, int n, cdouble *a, int lda, cdouble *b, int ldb, int ilo, int ihi, double *lscale, double *rscale, double *work, inout int info) {
    zggbal_(job, &n, a, &lda, b, &ldb, &ilo, &ihi, lscale, rscale, work, &info, 1);
}

/// Reduces a pair of real matrices to generalized upper
/// Hessenberg form using orthogonal transformations 
void gghrd(char *compq, char *compz, int n, int ilo, int ihi, float *a, int lda, float *b, int ldb, float *q, int ldq, float *z, int ldz, inout int info) {
    sgghrd_(compq, compz, &n, &ilo, &ihi, a, &lda, b, &ldb, q, &ldq, z, &ldz, &info, 1, 1);
}
void gghrd(char *compq, char *compz, int n, int ilo, int ihi, double *a, int lda, double *b, int ldb, double *q, int ldq, double *z, int ldz, inout int info) {
    dgghrd_(compq, compz, &n, &ilo, &ihi, a, &lda, b, &ldb, q, &ldq, z, &ldz, &info, 1, 1);
}
void gghrd(char *compq, char *compz, int n, int ilo, int ihi, cfloat *a, int lda, cfloat *b, int ldb, cfloat *q, int ldq, cfloat *z, int ldz, inout int info) {
    cgghrd_(compq, compz, &n, &ilo, &ihi, a, &lda, b, &ldb, q, &ldq, z, &ldz, &info, 1, 1);
}
void gghrd(char *compq, char *compz, int n, int ilo, int ihi, cdouble *a, int lda, cdouble *b, int ldb, cdouble *q, int ldq, cdouble *z, int ldz, inout int info) {
    zgghrd_(compq, compz, &n, &ilo, &ihi, a, &lda, b, &ldb, q, &ldq, z, &ldz, &info, 1, 1);
}

/// Computes a generalized QR factorization of a pair of matrices. 
void ggqrf(int n, int m, int p, float *a, int lda, float *taua, float *b, int ldb, float *taub, float *work, int lwork, inout int info) {
    sggqrf_(&n, &m, &p, a, &lda, taua, b, &ldb, taub, work, &lwork, &info);
}
void ggqrf(int n, int m, int p, double *a, int lda, double *taua, double *b, int ldb, double *taub, double *work, int lwork, inout int info) {
    dggqrf_(&n, &m, &p, a, &lda, taua, b, &ldb, taub, work, &lwork, &info);
}
void ggqrf(int n, int m, int p, cfloat *a, int lda, cfloat *taua, cfloat *b, int ldb, cfloat *taub, cfloat *work, int lwork, inout int info) {
    cggqrf_(&n, &m, &p, a, &lda, taua, b, &ldb, taub, work, &lwork, &info);
}
void ggqrf(int n, int m, int p, cdouble *a, int lda, cdouble *taua, cdouble *b, int ldb, cdouble *taub, cdouble *work, int lwork, inout int info) {
    zggqrf_(&n, &m, &p, a, &lda, taua, b, &ldb, taub, work, &lwork, &info);
}

/// Computes a generalized RQ factorization of a pair of matrices.
void ggrqf(int m, int p, int n, float *a, int lda, float *taua, float *b, int ldb, float *taub, float *work, int lwork, inout int info) {
    sggrqf_(&m, &p, &n, a, &lda, taua, b, &ldb, taub, work, &lwork, &info);
}
void ggrqf(int m, int p, int n, double *a, int lda, double *taua, double *b, int ldb, double *taub, double *work, int lwork, inout int info) {
    dggrqf_(&m, &p, &n, a, &lda, taua, b, &ldb, taub, work, &lwork, &info);
}
void ggrqf(int m, int p, int n, cfloat *a, int lda, cfloat *taua, cfloat *b, int ldb, cfloat *taub, cfloat *work, int lwork, inout int info) {
    cggrqf_(&m, &p, &n, a, &lda, taua, b, &ldb, taub, work, &lwork, &info);
}
void ggrqf(int m, int p, int n, cdouble *a, int lda, cdouble *taua, cdouble *b, int ldb, cdouble *taub, cdouble *work, int lwork, inout int info) {
    zggrqf_(&m, &p, &n, a, &lda, taua, b, &ldb, taub, work, &lwork, &info);
}

/// Computes orthogonal matrices as a preprocessing step
/// for computing the generalized singular value decomposition
void ggsvp(char *jobu, char *jobv, char *jobq, int m, int p, int n, float *a, int lda, float *b, int ldb, float *tola, float *tolb, int k, int l, float *u, int ldu, float *v, int ldv, float *q, int ldq, int *iwork, float *tau, float *work, inout int info) {
    sggsvp_(jobu, jobv, jobq, &m, &p, &n, a, &lda, b, &ldb, tola, tolb, &k, &l, u, &ldu, v, &ldv, q, &ldq, iwork, tau, work, &info, 1, 1, 1);
}
void ggsvp(char *jobu, char *jobv, char *jobq, int m, int p, int n, double *a, int lda, double *b, int ldb, double *tola, double *tolb, int k, int l, double *u, int ldu, double *v, int ldv, double *q, int ldq, int *iwork, double *tau, double *work, inout int info) {
    dggsvp_(jobu, jobv, jobq, &m, &p, &n, a, &lda, b, &ldb, tola, tolb, &k, &l, u, &ldu, v, &ldv, q, &ldq, iwork, tau, work, &info, 1, 1, 1);
}
void ggsvp(char *jobu, char *jobv, char *jobq, int m, int p, int n, cfloat *a, int lda, cfloat *b, int ldb, float *tola, float *tolb, int k, int l, cfloat *u, int ldu, cfloat *v, int ldv, cfloat *q, int ldq, int *iwork, float *rwork, cfloat *tau, cfloat *work, inout int info) {
    cggsvp_(jobu, jobv, jobq, &m, &p, &n, a, &lda, b, &ldb, tola, tolb, &k, &l, u, &ldu, v, &ldv, q, &ldq, iwork, rwork, tau, work, &info, 1, 1, 1);
}
void ggsvp(char *jobu, char *jobv, char *jobq, int m, int p, int n, cdouble *a, int lda, cdouble *b, int ldb, double *tola, double *tolb, int k, int l, cdouble *u, int ldu, cdouble *v, int ldv, cdouble *q, int ldq, int *iwork, double *rwork, cdouble *tau, cdouble *work, inout int info) {
    zggsvp_(jobu, jobv, jobq, &m, &p, &n, a, &lda, b, &ldb, tola, tolb, &k, &l, u, &ldu, v, &ldv, q, &ldq, iwork, rwork, tau, work, &info, 1, 1, 1);
}

/// Estimates the reciprocal of the condition number of a general
/// tridiagonal matrix, in either the 1-norm or the infinity-norm,
/// using the LU factorization computed by SGTTRF.
void gtcon(char *norm, int n, float *dl, float *d, float *du, float *du2, int *ipiv, float *anorm, float rcond, float *work, int *iwork, inout int info) {
    sgtcon_(norm, &n, dl, d, du, du2, ipiv, anorm, &rcond, work, iwork, &info, 1);
}
void gtcon(char *norm, int n, double *dl, double *d, double *du, double *du2, int *ipiv, double *anorm, double rcond, double *work, int *iwork, inout int info) {
    dgtcon_(norm, &n, dl, d, du, du2, ipiv, anorm, &rcond, work, iwork, &info, 1);
}
void gtcon(char *norm, int n, cfloat *dl, cfloat *d, cfloat *du, cfloat *du2, int *ipiv, float *anorm, float rcond, cfloat *work, inout int info) {
    cgtcon_(norm, &n, dl, d, du, du2, ipiv, anorm, &rcond, work, &info, 1);
}
void gtcon(char *norm, int n, cdouble *dl, cdouble *d, cdouble *du, cdouble *du2, int *ipiv, double *anorm, double rcond, cdouble *work, inout int info) {
    zgtcon_(norm, &n, dl, d, du, du2, ipiv, anorm, &rcond, work, &info, 1);
}

/// Improves the computed solution to a general tridiagonal system
/// of linear equations AX=B, A**T X=B or A**H X=B, and provides
/// forward and backward error bounds for the solution.
void gtrfs(char *trans, int n, int nrhs, float *dl, float *d, float *du, float *dlf, float *df, float *duf, float *du2, int *ipiv, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sgtrfs_(trans, &n, &nrhs, dl, d, du, dlf, df, duf, du2, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void gtrfs(char *trans, int n, int nrhs, double *dl, double *d, double *du, double *dlf, double *df, double *duf, double *du2, int *ipiv, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dgtrfs_(trans, &n, &nrhs, dl, d, du, dlf, df, duf, du2, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void gtrfs(char *trans, int n, int nrhs, cfloat *dl, cfloat *d, cfloat *du, cfloat *dlf, cfloat *df, cfloat *duf, cfloat *du2, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cgtrfs_(trans, &n, &nrhs, dl, d, du, dlf, df, duf, du2, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void gtrfs(char *trans, int n, int nrhs, cdouble *dl, cdouble *d, cdouble *du, cdouble *dlf, cdouble *df, cdouble *duf, cdouble *du2, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zgtrfs_(trans, &n, &nrhs, dl, d, du, dlf, df, duf, du2, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Computes an LU factorization of a general tridiagonal matrix,
/// using partial pivoting with row interchanges.
void gttrf(int n, float *dl, float *d, float *du, float *du2, int *ipiv, inout int info) {
    sgttrf_(&n, dl, d, du, du2, ipiv, &info);
}
void gttrf(int n, double *dl, double *d, double *du, double *du2, int *ipiv, inout int info) {
    dgttrf_(&n, dl, d, du, du2, ipiv, &info);
}
void gttrf(int n, cfloat *dl, cfloat *d, cfloat *du, cfloat *du2, int *ipiv, inout int info) {
    cgttrf_(&n, dl, d, du, du2, ipiv, &info);
}
void gttrf(int n, cdouble *dl, cdouble *d, cdouble *du, cdouble *du2, int *ipiv, inout int info) {
    zgttrf_(&n, dl, d, du, du2, ipiv, &info);
}

/// Solves a general tridiagonal system of linear equations AX=B,
/// A**T X=B or A**H X=B, using the LU factorization computed by
/// SGTTRF.
void gttrs(char *trans, int n, int nrhs, float *dl, float *d, float *du, float *du2, int *ipiv, float *b, int ldb, inout int info) {
    sgttrs_(trans, &n, &nrhs, dl, d, du, du2, ipiv, b, &ldb, &info, 1);
}
void gttrs(char *trans, int n, int nrhs, double *dl, double *d, double *du, double *du2, int *ipiv, double *b, int ldb, inout int info) {
    dgttrs_(trans, &n, &nrhs, dl, d, du, du2, ipiv, b, &ldb, &info, 1);
}
void gttrs(char *trans, int n, int nrhs, cfloat *dl, cfloat *d, cfloat *du, cfloat *du2, int *ipiv, cfloat *b, int ldb, inout int info) {
    cgttrs_(trans, &n, &nrhs, dl, d, du, du2, ipiv, b, &ldb, &info, 1);
}
void gttrs(char *trans, int n, int nrhs, cdouble *dl, cdouble *d, cdouble *du, cdouble *du2, int *ipiv, cdouble *b, int ldb, inout int info) {
    zgttrs_(trans, &n, &nrhs, dl, d, du, du2, ipiv, b, &ldb, &info, 1);
}

/// Implements a single-/double-shift version of the QZ method for
/// finding the generalized eigenvalues of the equation 
/// det(A - w(i) B) = 0
void hgeqz(char *job, char *compq, char *compz, int n, int ilo, int ihi, float *a, int lda, float *b, int ldb, float *alphar, float *alphai, float *betav, float *q, int ldq, float *z, int ldz, float *work, int lwork, inout int info) {
    shgeqz_(job, compq, compz, &n, &ilo, &ihi, a, &lda, b, &ldb, alphar, alphai, betav, q, &ldq, z, &ldz, work, &lwork, &info, 1, 1, 1);
}
void hgeqz(char *job, char *compq, char *compz, int n, int ilo, int ihi, double *a, int lda, double *b, int ldb, double *alphar, double *alphai, double *betav, double *q, int ldq, double *z, int ldz, double *work, int lwork, inout int info) {
    dhgeqz_(job, compq, compz, &n, &ilo, &ihi, a, &lda, b, &ldb, alphar, alphai, betav, q, &ldq, z, &ldz, work, &lwork, &info, 1, 1, 1);
}
void hgeqz(char *job, char *compq, char *compz, int n, int ilo, int ihi, cfloat *a, int lda, cfloat *b, int ldb, cfloat *alphav, cfloat *betav, cfloat *q, int ldq, cfloat *z, int ldz, cfloat *work, int lwork, float *rwork, inout int info) {
    chgeqz_(job, compq, compz, &n, &ilo, &ihi, a, &lda, b, &ldb, alphav, betav, q, &ldq, z, &ldz, work, &lwork, rwork, &info, 1, 1, 1);
}
void hgeqz(char *job, char *compq, char *compz, int n, int ilo, int ihi, cdouble *a, int lda, cdouble *b, int ldb, cdouble *alphav, cdouble *betav, cdouble *q, int ldq, cdouble *z, int ldz, cdouble *work, int lwork, double *rwork, inout int info) {
    zhgeqz_(job, compq, compz, &n, &ilo, &ihi, a, &lda, b, &ldb, alphav, betav, q, &ldq, z, &ldz, work, &lwork, rwork, &info, 1, 1, 1);
}

/// Computes specified right and/or left eigenvectors of an upper
/// Hessenberg matrix by inverse iteration.
void hsein(char side, char *eigsrc, char *initv, int select, int n, float *h, int ldh, float *wr, float *wi, float *vl, int ldvl, float *vr, int ldvr, int mm, int m, float *work, int ifaill, int ifailr, inout int info) {
    shsein_(&side, eigsrc, initv, &select, &n, h, &ldh, wr, wi, vl, &ldvl, vr, &ldvr, &mm, &m, work, &ifaill, &ifailr, &info, 1, 1, 1);
}
void hsein(char side, char *eigsrc, char *initv, int select, int n, double *h, int ldh, double *wr, double *wi, double *vl, int ldvl, double *vr, int ldvr, int mm, int m, double *work, int ifaill, int ifailr, inout int info) {
    dhsein_(&side, eigsrc, initv, &select, &n, h, &ldh, wr, wi, vl, &ldvl, vr, &ldvr, &mm, &m, work, &ifaill, &ifailr, &info, 1, 1, 1);
}
void hsein(char side, char *eigsrc, char *initv, int select, int n, cfloat *h, int ldh, cfloat *w, cfloat *vl, int ldvl, cfloat *vr, int ldvr, int mm, int m, cfloat *work, float *rwork, int ifaill, int ifailr, inout int info) {
    chsein_(&side, eigsrc, initv, &select, &n, h, &ldh, w, vl, &ldvl, vr, &ldvr, &mm, &m, work, rwork, &ifaill, &ifailr, &info, 1, 1, 1);
}
void hsein(char side, char *eigsrc, char *initv, int select, int n, cdouble *h, int ldh, cdouble *w, cdouble *vl, int ldvl, cdouble *vr, int ldvr, int mm, int m, cdouble *work, double *rwork, int ifaill, int ifailr, inout int info) {
    zhsein_(&side, eigsrc, initv, &select, &n, h, &ldh, w, vl, &ldvl, vr, &ldvr, &mm, &m, work, rwork, &ifaill, &ifailr, &info, 1, 1, 1);
}

/// Computes the eigenvalues and Schur factorization of an upper
/// Hessenberg matrix, using the multishift QR algorithm.
void hseqr(char *job, char *compz, int n, int ilo, int ihi, float *h, int ldh, float *wr, float *wi, float *z, int ldz, float *work, int lwork, inout int info) {
    shseqr_(job, compz, &n, &ilo, &ihi, h, &ldh, wr, wi, z, &ldz, work, &lwork, &info, 1, 1);
}
void hseqr(char *job, char *compz, int n, int ilo, int ihi, double *h, int ldh, double *wr, double *wi, double *z, int ldz, double *work, int lwork, inout int info) {
    dhseqr_(job, compz, &n, &ilo, &ihi, h, &ldh, wr, wi, z, &ldz, work, &lwork, &info, 1, 1);
}
void hseqr(char *job, char *compz, int n, int ilo, int ihi, cfloat *h, int ldh, cfloat *w, cfloat *z, int ldz, cfloat *work, int lwork, inout int info) {
    chseqr_(job, compz, &n, &ilo, &ihi, h, &ldh, w, z, &ldz, work, &lwork, &info, 1, 1);
}
void hseqr(char *job, char *compz, int n, int ilo, int ihi, cdouble *h, int ldh, cdouble *w, cdouble *z, int ldz, cdouble *work, int lwork, inout int info) {
    zhseqr_(job, compz, &n, &ilo, &ihi, h, &ldh, w, z, &ldz, work, &lwork, &info, 1, 1);
}

/// Generates the orthogonal transformation matrix from
/// a reduction to tridiagonal form determined by SSPTRD.
void opgtr(char uplo, int n, float *ap, float *tau, float *q, int ldq, float *work, inout int info) {
    sopgtr_(&uplo, &n, ap, tau, q, &ldq, work, &info, 1);
}
void opgtr(char uplo, int n, double *ap, double *tau, double *q, int ldq, double *work, inout int info) {
    dopgtr_(&uplo, &n, ap, tau, q, &ldq, work, &info, 1);
}

/// Generates the unitary transformation matrix from
/// a reduction to tridiagonal form determined by CHPTRD.
void upgtr(char uplo, int n, cfloat *ap, cfloat *tau, cfloat *q, int ldq, cfloat *work, inout int info) {
    cupgtr_(&uplo, &n, ap, tau, q, &ldq, work, &info, 1);
}
void upgtr(char uplo, int n, cdouble *ap, cdouble *tau, cdouble *q, int ldq, cdouble *work, inout int info) {
    zupgtr_(&uplo, &n, ap, tau, q, &ldq, work, &info, 1);
}


/// Multiplies a general matrix by the orthogonal
/// transformation matrix from a reduction to tridiagonal form
/// determined by SSPTRD.
void opmtr(char side, char uplo, char *trans, int m, int n, float *ap, float *tau, float *c, int ldc, float *work, inout int info) {
    sopmtr_(&side, &uplo, trans, &m, &n, ap, tau, c, &ldc, work, &info, 1, 1, 1);
}
void opmtr(char side, char uplo, char *trans, int m, int n, double *ap, double *tau, double *c, int ldc, double *work, inout int info) {
    dopmtr_(&side, &uplo, trans, &m, &n, ap, tau, c, &ldc, work, &info, 1, 1, 1);
}

/// Generates the orthogonal transformation matrices from
/// a reduction to bidiagonal form determined by SGEBRD.
void orgbr(char *vect, int m, int n, int k, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sorgbr_(vect, &m, &n, &k, a, &lda, tau, work, &lwork, &info, 1);
}
void orgbr(char *vect, int m, int n, int k, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dorgbr_(vect, &m, &n, &k, a, &lda, tau, work, &lwork, &info, 1);
}

/// Generates the unitary transformation matrices from
/// a reduction to bidiagonal form determined by CGEBRD.
void ungbr(char *vect, int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cungbr_(vect, &m, &n, &k, a, &lda, tau, work, &lwork, &info, 1);
}
void ungbr(char *vect, int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zungbr_(vect, &m, &n, &k, a, &lda, tau, work, &lwork, &info, 1);
}

/// Generates the orthogonal transformation matrix from
/// a reduction to Hessenberg form determined by SGEHRD.
void orghr(int n, int ilo, int ihi, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sorghr_(&n, &ilo, &ihi, a, &lda, tau, work, &lwork, &info);
}
void orghr(int n, int ilo, int ihi, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dorghr_(&n, &ilo, &ihi, a, &lda, tau, work, &lwork, &info);
}

/// Generates the unitary transformation matrix from
/// a reduction to Hessenberg form determined by CGEHRD.
void unghr(int n, int ilo, int ihi, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cunghr_(&n, &ilo, &ihi, a, &lda, tau, work, &lwork, &info);
}
void unghr(int n, int ilo, int ihi, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zunghr_(&n, &ilo, &ihi, a, &lda, tau, work, &lwork, &info);
}

/// Generates all or part of the orthogonal matrix Q from
/// an LQ factorization determined by SGELQF.
void orglq(int m, int n, int k, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sorglq_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}
void orglq(int m, int n, int k, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dorglq_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}

/// Generates all or part of the unitary matrix Q from
/// an LQ factorization determined by CGELQF.
void unglq(int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cunglq_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}
void unglq(int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zunglq_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}

/// Generates all or part of the orthogonal matrix Q from
/// a QL factorization determined by SGEQLF.
void orgql(int m, int n, int k, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sorgql_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}
void orgql(int m, int n, int k, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dorgql_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}

/// Generates all or part of the unitary matrix Q from
/// a QL factorization determined by CGEQLF.
void ungql(int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cungql_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}
void ungql(int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zungql_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}

/// Generates all or part of the orthogonal matrix Q from
/// a QR factorization determined by SGEQRF.
void orgqr(int m, int n, int k, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sorgqr_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}
void orgqr(int m, int n, int k, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dorgqr_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}

/// Generates all or part of the unitary matrix Q from
/// a QR factorization determined by CGEQRF.
void ungqr(int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cungqr_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}
void ungqr(int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zungqr_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}

/// Generates all or part of the orthogonal matrix Q from
/// an RQ factorization determined by SGERQF.
void orgrq(int m, int n, int k, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sorgrq_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}
void orgrq(int m, int n, int k, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dorgrq_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}

/// Generates all or part of the unitary matrix Q from
/// an RQ factorization determined by CGERQF.
void ungrq(int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cungrq_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}
void ungrq(int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zungrq_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);
}

/// Generates the orthogonal transformation matrix from
/// a reduction to tridiagonal form determined by SSYTRD.
void orgtr(char uplo, int n, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    sorgtr_(&uplo, &n, a, &lda, tau, work, &lwork, &info, 1);
}
void orgtr(char uplo, int n, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dorgtr_(&uplo, &n, a, &lda, tau, work, &lwork, &info, 1);
}

/// Generates the unitary transformation matrix from
/// a reduction to tridiagonal form determined by CHETRD.
void ungtr(char uplo, int n, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    cungtr_(&uplo, &n, a, &lda, tau, work, &lwork, &info, 1);
}
void ungtr(char uplo, int n, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zungtr_(&uplo, &n, a, &lda, tau, work, &lwork, &info, 1);
}

/// Multiplies a general matrix by one of the orthogonal
/// transformation  matrices from a reduction to bidiagonal form
/// determined by SGEBRD.
void ormbr(char *vect, char side, char *trans, int m, int n, int k, float *a, int lda, float *tau, float *c, int ldc, float *work, int lwork, inout int info) {
    sormbr_(vect, &side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1, 1);
}
void ormbr(char *vect, char side, char *trans, int m, int n, int k, double *a, int lda, double *tau, double *c, int ldc, double *work, int lwork, inout int info) {
    dormbr_(vect, &side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1, 1);
}

/// Multiplies a general matrix by one of the unitary
/// transformation matrices from a reduction to bidiagonal form
/// determined by CGEBRD.
void unmbr(char *vect, char side, char *trans, int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *c, int ldc, cfloat *work, int lwork, inout int info) {
    cunmbr_(vect, &side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1, 1);
}
void unmbr(char *vect, char side, char *trans, int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *c, int ldc, cdouble *work, int lwork, inout int info) {
    zunmbr_(vect, &side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1, 1);
}

/// Multiplies a general matrix by the orthogonal transformation
/// matrix from a reduction to Hessenberg form determined by SGEHRD.
void ormhr(char side, char *trans, int m, int n, int ilo, int ihi, float *a, int lda, float *tau, float *c, int ldc, float *work, int lwork, inout int info) {
    sormhr_(&side, trans, &m, &n, &ilo, &ihi, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void ormhr(char side, char *trans, int m, int n, int ilo, int ihi, double *a, int lda, double *tau, double *c, int ldc, double *work, int lwork, inout int info) {
    dormhr_(&side, trans, &m, &n, &ilo, &ihi, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiplies a general matrix by the unitary transformation
/// matrix from a reduction to Hessenberg form determined by CGEHRD.
void unmhr(char side, char *trans, int m, int n, int ilo, int ihi, cfloat *a, int lda, cfloat *tau, cfloat *c, int ldc, cfloat *work, int lwork, inout int info) {
    cunmhr_(&side, trans, &m, &n, &ilo, &ihi, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void unmhr(char side, char *trans, int m, int n, int ilo, int ihi, cdouble *a, int lda, cdouble *tau, cdouble *c, int ldc, cdouble *work, int lwork, inout int info) {
    zunmhr_(&side, trans, &m, &n, &ilo, &ihi, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiplies a general matrix by the orthogonal matrix
/// from an LQ factorization determined by SGELQF.
void ormlq(char side, char *trans, int m, int n, int k, float *a, int lda, float *tau, float *c, int ldc, float *work, int lwork, inout int info) {
    sormlq_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void ormlq(char side, char *trans, int m, int n, int k, double *a, int lda, double *tau, double *c, int ldc, double *work, int lwork, inout int info) {
    dormlq_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiplies a general matrix by the unitary matrix
/// from an LQ factorization determined by CGELQF.
void unmlq(char side, char *trans, int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *c, int ldc, cfloat *work, int lwork, inout int info) {
    cunmlq_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void unmlq(char side, char *trans, int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *c, int ldc, cdouble *work, int lwork, inout int info) {
    zunmlq_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiplies a general matrix by the orthogonal matrix
/// from a QL factorization determined by SGEQLF.
void ormql(char side, char *trans, int m, int n, int k, float *a, int lda, float *tau, float *c, int ldc, float *work, int lwork, inout int info) {
    sormql_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void ormql(char side, char *trans, int m, int n, int k, double *a, int lda, double *tau, double *c, int ldc, double *work, int lwork, inout int info) {
    dormql_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiplies a general matrix by the unitary matrix
/// from a QL factorization determined by CGEQLF.
void unmql(char side, char *trans, int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *c, int ldc, cfloat *work, int lwork, inout int info) {
    cunmql_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void unmql(char side, char *trans, int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *c, int ldc, cdouble *work, int lwork, inout int info) {
    zunmql_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiplies a general matrix by the orthogonal matrix
/// from a QR factorization determined by SGEQRF.
void ormqr(char side, char *trans, int m, int n, int k, float *a, int lda, float *tau, float *c, int ldc, float *work, int lwork, inout int info) {
    sormqr_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void ormqr(char side, char *trans, int m, int n, int k, double *a, int lda, double *tau, double *c, int ldc, double *work, int lwork, inout int info) {
    dormqr_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiplies a general matrix by the unitary matrix
/// from a QR factorization determined by CGEQRF.
void unmqr(char side, char *trans, int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *c, int ldc, cfloat *work, int lwork, inout int info) {
    cunmqr_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void unmqr(char side, char *trans, int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *c, int ldc, cdouble *work, int lwork, inout int info) {
    zunmqr_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiples a general matrix by the orthogonal matrix
/// from an RZ factorization determined by STZRZF.
void ormr3(char side, char *trans, int m, int n, int k, int l, float *a, int lda, float *tau, float *c, int ldc, float *work, inout int info) {
    sormr3_(&side, trans, &m, &n, &k, &l, a, &lda, tau, c, &ldc, work, &info, 1, 1);
}
void ormr3(char side, char *trans, int m, int n, int k, int l, double *a, int lda, double *tau, double *c, int ldc, double *work, inout int info) {
    dormr3_(&side, trans, &m, &n, &k, &l, a, &lda, tau, c, &ldc, work, &info, 1, 1);
}

/// Multiples a general matrix by the unitary matrix
/// from an RZ factorization determined by CTZRZF.
void unmr3(char side, char *trans, int m, int n, int k, int l, cfloat *a, int lda, cfloat *tau, cfloat *c, int ldc, cfloat *work, inout int info) {
    cunmr3_(&side, trans, &m, &n, &k, &l, a, &lda, tau, c, &ldc, work, &info, 1, 1);
}
void unmr3(char side, char *trans, int m, int n, int k, int l, cdouble *a, int lda, cdouble *tau, cdouble *c, int ldc, cdouble *work, inout int info) {
    zunmr3_(&side, trans, &m, &n, &k, &l, a, &lda, tau, c, &ldc, work, &info, 1, 1);
}

/// Multiplies a general matrix by the orthogonal matrix
/// from an RQ factorization determined by SGERQF.
void ormrq(char side, char *trans, int m, int n, int k, float *a, int lda, float *tau, float *c, int ldc, float *work, int lwork, inout int info) {
    sormrq_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void ormrq(char side, char *trans, int m, int n, int k, double *a, int lda, double *tau, double *c, int ldc, double *work, int lwork, inout int info) {
    dormrq_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiplies a general matrix by the unitary matrix
/// from an RQ factorization determined by CGERQF.
void unmrq(char side, char *trans, int m, int n, int k, cfloat *a, int lda, cfloat *tau, cfloat *c, int ldc, cfloat *work, int lwork, inout int info) {
    cunmrq_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void unmrq(char side, char *trans, int m, int n, int k, cdouble *a, int lda, cdouble *tau, cdouble *c, int ldc, cdouble *work, int lwork, inout int info) {
    zunmrq_(&side, trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiples a general matrix by the orthogonal matrix
/// from an RZ factorization determined by STZRZF.
void ormrz(char side, char *trans, int m, int n, int k, int l, float *a, int lda, float *tau, float *c, int ldc, float *work, int lwork, inout int info) {
    sormrz_(&side, trans, &m, &n, &k, &l, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void ormrz(char side, char *trans, int m, int n, int k, int l, double *a, int lda, double *tau, double *c, int ldc, double *work, int lwork, inout int info) {
    dormrz_(&side, trans, &m, &n, &k, &l, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiples a general matrix by the unitary matrix
/// from an RZ factorization determined by CTZRZF.
void unmrz(char side, char *trans, int m, int n, int k, int l, cfloat *a, int lda, cfloat *tau, cfloat *c, int ldc, cfloat *work, int lwork, inout int info) {
    cunmrz_(&side, trans, &m, &n, &k, &l, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}
void unmrz(char side, char *trans, int m, int n, int k, int l, cdouble *a, int lda, cdouble *tau, cdouble *c, int ldc, cdouble *work, int lwork, inout int info) {
    zunmrz_(&side, trans, &m, &n, &k, &l, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1);
}

/// Multiplies a general matrix by the orthogonal
/// transformation matrix from a reduction to tridiagonal form
/// determined by SSYTRD.
void ormtr(char side, char uplo, char *trans, int m, int n, float *a, int lda, float *tau, float *c, int ldc, float *work, int lwork, inout int info) {
    sormtr_(&side, &uplo, trans, &m, &n, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1, 1);
}
void ormtr(char side, char uplo, char *trans, int m, int n, double *a, int lda, double *tau, double *c, int ldc, double *work, int lwork, inout int info) {
    dormtr_(&side, &uplo, trans, &m, &n, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1, 1);
}

/// Multiplies a general matrix by the unitary
/// transformation matrix from a reduction to tridiagonal form
/// determined by CHETRD.
void unmtr(char side, char uplo, char *trans, int m, int n, cfloat *a, int lda, cfloat *tau, cfloat *c, int ldc, cfloat *work, int lwork, inout int info) {
    cunmtr_(&side, &uplo, trans, &m, &n, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1, 1);
}
void unmtr(char side, char uplo, char *trans, int m, int n, cdouble *a, int lda, cdouble *tau, cdouble *c, int ldc, cdouble *work, int lwork, inout int info) {
    zunmtr_(&side, &uplo, trans, &m, &n, a, &lda, tau, c, &ldc, work, &lwork, &info, 1, 1, 1);
}

/// Estimates the reciprocal of the condition number of a
/// symmetric positive definite band matrix, using the
/// Cholesky factorization computed by SPBTRF.
void pbcon(char uplo, int n, int kd, float *ab, int ldab, float *anorm, float rcond, float *work, int *iwork, inout int info) {
    spbcon_(&uplo, &n, &kd, ab, &ldab, anorm, &rcond, work, iwork, &info, 1);
}
void pbcon(char uplo, int n, int kd, double *ab, int ldab, double *anorm, double rcond, double *work, int *iwork, inout int info) {
    dpbcon_(&uplo, &n, &kd, ab, &ldab, anorm, &rcond, work, iwork, &info, 1);
}
void pbcon(char uplo, int n, int kd, cfloat *ab, int ldab, float *anorm, float rcond, cfloat *work, float *rwork, inout int info) {
    cpbcon_(&uplo, &n, &kd, ab, &ldab, anorm, &rcond, work, rwork, &info, 1);
}
void pbcon(char uplo, int n, int kd, cdouble *ab, int ldab, double *anorm, double rcond, cdouble *work, double *rwork, inout int info) {
    zpbcon_(&uplo, &n, &kd, ab, &ldab, anorm, &rcond, work, rwork, &info, 1);
}

/// Computes row and column scalings to equilibrate a symmetric
/// positive definite band matrix and reduce its condition number.
void pbequ(char uplo, int n, int kd, float *ab, int ldab, float *s, float *scond, float *amax, inout int info) {
    spbequ_(&uplo, &n, &kd, ab, &ldab, s, scond, amax, &info, 1);
}
void pbequ(char uplo, int n, int kd, double *ab, int ldab, double *s, double *scond, double *amax, inout int info) {
    dpbequ_(&uplo, &n, &kd, ab, &ldab, s, scond, amax, &info, 1);
}
void pbequ(char uplo, int n, int kd, cfloat *ab, int ldab, float *s, float *scond, float *amax, inout int info) {
    cpbequ_(&uplo, &n, &kd, ab, &ldab, s, scond, amax, &info, 1);
}
void pbequ(char uplo, int n, int kd, cdouble *ab, int ldab, double *s, double *scond, double *amax, inout int info) {
    zpbequ_(&uplo, &n, &kd, ab, &ldab, s, scond, amax, &info, 1);
}

/// Improves the computed solution to a symmetric positive
/// definite banded system of linear equations AX=B, and provides
/// forward and backward error bounds for the solution.
void pbrfs(char uplo, int n, int kd, int nrhs, float *ab, int ldab, float *afb, int ldafb, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    spbrfs_(&uplo, &n, &kd, &nrhs, ab, &ldab, afb, &ldafb, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void pbrfs(char uplo, int n, int kd, int nrhs, double *ab, int ldab, double *afb, int ldafb, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dpbrfs_(&uplo, &n, &kd, &nrhs, ab, &ldab, afb, &ldafb, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void pbrfs(char uplo, int n, int kd, int nrhs, cfloat *ab, int ldab, cfloat *afb, int ldafb, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cpbrfs_(&uplo, &n, &kd, &nrhs, ab, &ldab, afb, &ldafb, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void pbrfs(char uplo, int n, int kd, int nrhs, cdouble *ab, int ldab, cdouble *afb, int ldafb, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zpbrfs_(&uplo, &n, &kd, &nrhs, ab, &ldab, afb, &ldafb, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Computes a split Cholesky factorization of a real symmetric positive
/// definite band matrix.
void pbstf(char uplo, int n, int kd, float *ab, int ldab, inout int info) {
    spbstf_(&uplo, &n, &kd, ab, &ldab, &info, 1);
}
void pbstf(char uplo, int n, int kd, double *ab, int ldab, inout int info) {
    dpbstf_(&uplo, &n, &kd, ab, &ldab, &info, 1);
}
void pbstf(char uplo, int n, int kd, cfloat *ab, int ldab, inout int info) {
    cpbstf_(&uplo, &n, &kd, ab, &ldab, &info, 1);
}
void pbstf(char uplo, int n, int kd, cdouble *ab, int ldab, inout int info) {
    zpbstf_(&uplo, &n, &kd, ab, &ldab, &info, 1);
}

/// Computes the Cholesky factorization of a symmetric
/// positive definite band matrix.
void pbtrf(char uplo, int n, int kd, float *ab, int ldab, inout int info) {
    spbtrf_(&uplo, &n, &kd, ab, &ldab, &info, 1);
}
void pbtrf(char uplo, int n, int kd, double *ab, int ldab, inout int info) {
    dpbtrf_(&uplo, &n, &kd, ab, &ldab, &info, 1);
}
void pbtrf(char uplo, int n, int kd, cfloat *ab, int ldab, inout int info) {
    cpbtrf_(&uplo, &n, &kd, ab, &ldab, &info, 1);
}
void pbtrf(char uplo, int n, int kd, cdouble *ab, int ldab, inout int info) {
    zpbtrf_(&uplo, &n, &kd, ab, &ldab, &info, 1);
}

/// Solves a symmetric positive definite banded system
/// of linear equations AX=B, using the Cholesky factorization
/// computed by SPBTRF.
void pbtrs(char uplo, int n, int kd, int nrhs, float *ab, int ldab, float *b, int ldb, inout int info) {
    spbtrs_(&uplo, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1);
}
void pbtrs(char uplo, int n, int kd, int nrhs, double *ab, int ldab, double *b, int ldb, inout int info) {
    dpbtrs_(&uplo, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1);
}
void pbtrs(char uplo, int n, int kd, int nrhs, cfloat *ab, int ldab, cfloat *b, int ldb, inout int info) {
    cpbtrs_(&uplo, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1);
}
void pbtrs(char uplo, int n, int kd, int nrhs, cdouble *ab, int ldab, cdouble *b, int ldb, inout int info) {
    zpbtrs_(&uplo, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1);
}

/// Estimates the reciprocal of the condition number of a
/// symmetric positive definite matrix, using the
/// Cholesky factorization computed by SPOTRF.
void pocon(char uplo, int n, float *a, int lda, float *anorm, float rcond, float *work, int *iwork, inout int info) {
    spocon_(&uplo, &n, a, &lda, anorm, &rcond, work, iwork, &info, 1);
}
void pocon(char uplo, int n, double *a, int lda, double *anorm, double rcond, double *work, int *iwork, inout int info) {
    dpocon_(&uplo, &n, a, &lda, anorm, &rcond, work, iwork, &info, 1);
}
void pocon(char uplo, int n, cfloat *a, int lda, float *anorm, float rcond, cfloat *work, float *rwork, inout int info) {
    cpocon_(&uplo, &n, a, &lda, anorm, &rcond, work, rwork, &info, 1);
}
void pocon(char uplo, int n, cdouble *a, int lda, double *anorm, double rcond, cdouble *work, double *rwork, inout int info) {
    zpocon_(&uplo, &n, a, &lda, anorm, &rcond, work, rwork, &info, 1);
}

/// Computes row and column scalings to equilibrate a symmetric
/// positive definite matrix and reduce its condition number.
void poequ(int n, float *a, int lda, float *s, float *scond, float *amax, inout int info) {
    spoequ_(&n, a, &lda, s, scond, amax, &info);
}
void poequ(int n, double *a, int lda, double *s, double *scond, double *amax, inout int info) {
    dpoequ_(&n, a, &lda, s, scond, amax, &info);
}
void poequ(int n, cfloat *a, int lda, float *s, float *scond, float *amax, inout int info) {
    cpoequ_(&n, a, &lda, s, scond, amax, &info);
}
void poequ(int n, cdouble *a, int lda, double *s, double *scond, double *amax, inout int info) {
    zpoequ_(&n, a, &lda, s, scond, amax, &info);
}

/// Improves the computed solution to a symmetric positive
/// definite system of linear equations AX=B, and provides forward
/// and backward error bounds for the solution.
void porfs(char uplo, int n, int nrhs, float *a, int lda, float *af, int ldaf, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    sporfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void porfs(char uplo, int n, int nrhs, double *a, int lda, double *af, int ldaf, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dporfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void porfs(char uplo, int n, int nrhs, cfloat *a, int lda, cfloat *af, int ldaf, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cporfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void porfs(char uplo, int n, int nrhs, cdouble *a, int lda, cdouble *af, int ldaf, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zporfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Computes the Cholesky factorization of a symmetric
/// positive definite matrix.
void potrf(char uplo, int n, float *a, int lda, inout int info) {
    spotrf_(&uplo, &n, a, &lda, &info, 1);
}
void potrf(char uplo, int n, double *a, int lda, inout int info) {
    dpotrf_(&uplo, &n, a, &lda, &info, 1);
}
void potrf(char uplo, int n, cfloat *a, int lda, inout int info) {
    cpotrf_(&uplo, &n, a, &lda, &info, 1);
}
void potrf(char uplo, int n, cdouble *a, int lda, inout int info) {
    zpotrf_(&uplo, &n, a, &lda, &info, 1);
}

/// Computes the inverse of a symmetric positive definite
/// matrix, using the Cholesky factorization computed by SPOTRF.
void potri(char uplo, int n, float *a, int lda, inout int info) {
    spotri_(&uplo, &n, a, &lda, &info, 1);
}
void potri(char uplo, int n, double *a, int lda, inout int info) {
    dpotri_(&uplo, &n, a, &lda, &info, 1);
}
void potri(char uplo, int n, cfloat *a, int lda, inout int info) {
    cpotri_(&uplo, &n, a, &lda, &info, 1);
}
void potri(char uplo, int n, cdouble *a, int lda, inout int info) {
    zpotri_(&uplo, &n, a, &lda, &info, 1);
}

/// Solves a symmetric positive definite system of linear
/// equations AX=B, using the Cholesky factorization computed by
/// SPOTRF.
void potrs(char uplo, int n, int nrhs, float *a, int lda, float *b, int ldb, inout int info) {
    spotrs_(&uplo, &n, &nrhs, a, &lda, b, &ldb, &info, 1);
}
void potrs(char uplo, int n, int nrhs, double *a, int lda, double *b, int ldb, inout int info) {
    dpotrs_(&uplo, &n, &nrhs, a, &lda, b, &ldb, &info, 1);
}
void potrs(char uplo, int n, int nrhs, cfloat *a, int lda, cfloat *b, int ldb, inout int info) {
    cpotrs_(&uplo, &n, &nrhs, a, &lda, b, &ldb, &info, 1);
}
void potrs(char uplo, int n, int nrhs, cdouble *a, int lda, cdouble *b, int ldb, inout int info) {
    zpotrs_(&uplo, &n, &nrhs, a, &lda, b, &ldb, &info, 1);
}

/// Estimates the reciprocal of the condition number of a
/// symmetric positive definite matrix in packed storage,
/// using the Cholesky factorization computed by SPPTRF.
void ppcon(char uplo, int n, float *ap, float *anorm, float rcond, float *work, int *iwork, inout int info) {
    sppcon_(&uplo, &n, ap, anorm, &rcond, work, iwork, &info, 1);
}
void ppcon(char uplo, int n, double *ap, double *anorm, double rcond, double *work, int *iwork, inout int info) {
    dppcon_(&uplo, &n, ap, anorm, &rcond, work, iwork, &info, 1);
}
void ppcon(char uplo, int n, cfloat *ap, float *anorm, float rcond, cfloat *work, float *rwork, inout int info) {
    cppcon_(&uplo, &n, ap, anorm, &rcond, work, rwork, &info, 1);
}
void ppcon(char uplo, int n, cdouble *ap, double *anorm, double rcond, cdouble *work, double *rwork, inout int info) {
    zppcon_(&uplo, &n, ap, anorm, &rcond, work, rwork, &info, 1);
}

/// Computes row and column scalings to equilibrate a symmetric
/// positive definite matrix in packed storage and reduce its condition
/// number.
void ppequ(char uplo, int n, float *ap, float *s, float *scond, float *amax, inout int info) {
    sppequ_(&uplo, &n, ap, s, scond, amax, &info, 1);
}
void ppequ(char uplo, int n, double *ap, double *s, double *scond, double *amax, inout int info) {
    dppequ_(&uplo, &n, ap, s, scond, amax, &info, 1);
}
void ppequ(char uplo, int n, cfloat *ap, float *s, float *scond, float *amax, inout int info) {
    cppequ_(&uplo, &n, ap, s, scond, amax, &info, 1);
}
void ppequ(char uplo, int n, cdouble *ap, double *s, double *scond, double *amax, inout int info) {
    zppequ_(&uplo, &n, ap, s, scond, amax, &info, 1);
}

/// Improves the computed solution to a symmetric positive
/// definite system of linear equations AX=B, where A is held in
/// packed storage, and provides forward and backward error bounds
/// for the solution.
void pprfs(char uplo, int n, int nrhs, float *ap, float *afp, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    spprfs_(&uplo, &n, &nrhs, ap, afp, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void pprfs(char uplo, int n, int nrhs, double *ap, double *afp, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dpprfs_(&uplo, &n, &nrhs, ap, afp, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void pprfs(char uplo, int n, int nrhs, cfloat *ap, cfloat *afp, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cpprfs_(&uplo, &n, &nrhs, ap, afp, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void pprfs(char uplo, int n, int nrhs, cdouble *ap, cdouble *afp, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zpprfs_(&uplo, &n, &nrhs, ap, afp, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Computes the Cholesky factorization of a symmetric
/// positive definite matrix in packed storage.
void pptrf(char uplo, int n, float *ap, inout int info) {
    spptrf_(&uplo, &n, ap, &info, 1);
}
void pptrf(char uplo, int n, double *ap, inout int info) {
    dpptrf_(&uplo, &n, ap, &info, 1);
}
void pptrf(char uplo, int n, cfloat *ap, inout int info) {
    cpptrf_(&uplo, &n, ap, &info, 1);
}
void pptrf(char uplo, int n, cdouble *ap, inout int info) {
    zpptrf_(&uplo, &n, ap, &info, 1);
}

/// Computes the inverse of a symmetric positive definite
/// matrix in packed storage, using the Cholesky factorization computed
/// by SPPTRF.
void pptri(char uplo, int n, float *ap, inout int info) {
    spptri_(&uplo, &n, ap, &info, 1);
}
void pptri(char uplo, int n, double *ap, inout int info) {
    dpptri_(&uplo, &n, ap, &info, 1);
}
void pptri(char uplo, int n, cfloat *ap, inout int info) {
    cpptri_(&uplo, &n, ap, &info, 1);
}
void pptri(char uplo, int n, cdouble *ap, inout int info) {
    zpptri_(&uplo, &n, ap, &info, 1);
}

/// Solves a symmetric positive definite system of linear
/// equations AX=B, where A is held in packed storage, using the
/// Cholesky factorization computed by SPPTRF.
void pptrs(char uplo, int n, int nrhs, float *ap, float *b, int ldb, inout int info) {
    spptrs_(&uplo, &n, &nrhs, ap, b, &ldb, &info, 1);
}
void pptrs(char uplo, int n, int nrhs, double *ap, double *b, int ldb, inout int info) {
    dpptrs_(&uplo, &n, &nrhs, ap, b, &ldb, &info, 1);
}
void pptrs(char uplo, int n, int nrhs, cfloat *ap, cfloat *b, int ldb, inout int info) {
    cpptrs_(&uplo, &n, &nrhs, ap, b, &ldb, &info, 1);
}
void pptrs(char uplo, int n, int nrhs, cdouble *ap, cdouble *b, int ldb, inout int info) {
    zpptrs_(&uplo, &n, &nrhs, ap, b, &ldb, &info, 1);
}

/// Computes the reciprocal of the condition number of a
/// symmetric positive definite tridiagonal matrix,
/// using the LDL**H factorization computed by SPTTRF.
void ptcon(int n, float *d, float *e, float *anorm, float rcond, float *work, inout int info) {
    sptcon_(&n, d, e, anorm, &rcond, work, &info);
}
void ptcon(int n, double *d, double *e, double *anorm, double rcond, double *work, inout int info) {
    dptcon_(&n, d, e, anorm, &rcond, work, &info);
}
void ptcon(int n, float *d, cfloat *e, float *anorm, float rcond, float *rwork, inout int info) {
    cptcon_(&n, d, e, anorm, &rcond, rwork, &info);
}
void ptcon(int n, double *d, cdouble *e, double *anorm, double rcond, double *rwork, inout int info) {
    zptcon_(&n, d, e, anorm, &rcond, rwork, &info);
}

/// Computes all eigenvalues and eigenvectors of a real symmetric
/// positive definite tridiagonal matrix, by computing the SVD of
/// its bidiagonal Cholesky factor.
void pteqr(char *compz, int n, float *d, float *e, float *z, int ldz, float *work, inout int info) {
    spteqr_(compz, &n, d, e, z, &ldz, work, &info, 1);
}
void pteqr(char *compz, int n, double *d, double *e, double *z, int ldz, double *work, inout int info) {
    dpteqr_(compz, &n, d, e, z, &ldz, work, &info, 1);
}
void pteqr(char *compz, int n, float *d, float *e, cfloat *z, int ldz, float *work, inout int info) {
    cpteqr_(compz, &n, d, e, z, &ldz, work, &info, 1);
}
void pteqr(char *compz, int n, double *d, double *e, cdouble *z, int ldz, double *work, inout int info) {
    zpteqr_(compz, &n, d, e, z, &ldz, work, &info, 1);
}

/// Improves the computed solution to a symmetric positive
/// definite tridiagonal system of linear equations AX=B, and provides
/// forward and backward error bounds for the solution.
void ptrfs(int n, int nrhs, float *d, float *e, float *df, float *ef, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, inout int info) {
    sptrfs_(&n, &nrhs, d, e, df, ef, b, &ldb, x, &ldx, ferr, berr, work, &info);
}
void ptrfs(int n, int nrhs, double *d, double *e, double *df, double *ef, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, inout int info) {
    dptrfs_(&n, &nrhs, d, e, df, ef, b, &ldb, x, &ldx, ferr, berr, work, &info);
}
void ptrfs(char uplo, int n, int nrhs, float *d, cfloat *e, float *df, cfloat *ef, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cptrfs_(&uplo, &n, &nrhs, d, e, df, ef, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void ptrfs(char uplo, int n, int nrhs, double *d, cdouble *e, double *df, cdouble *ef, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zptrfs_(&uplo, &n, &nrhs, d, e, df, ef, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Computes the LDL**H factorization of a symmetric
/// positive definite tridiagonal matrix.
void pttrf(int n, float *d, float *e, inout int info) {
    spttrf_(&n, d, e, &info);
}
void pttrf(int n, double *d, double *e, inout int info) {
    dpttrf_(&n, d, e, &info);
}
void pttrf(int n, float *d, cfloat *e, inout int info) {
    cpttrf_(&n, d, e, &info);
}
void pttrf(int n, double *d, cdouble *e, inout int info) {
    zpttrf_(&n, d, e, &info);
}

/// Solves a symmetric positive definite tridiagonal
/// system of linear equations, using the LDL**H factorization
/// computed by SPTTRF.
void pttrs(int n, int nrhs, float *d, float *e, float *b, int ldb, inout int info) {
    spttrs_(&n, &nrhs, d, e, b, &ldb, &info);
}
void pttrs(int n, int nrhs, double *d, double *e, double *b, int ldb, inout int info) {
    dpttrs_(&n, &nrhs, d, e, b, &ldb, &info);
}
void pttrs(char uplo, int n, int nrhs, float *d, cfloat *e, cfloat *b, int ldb, inout int info) {
    cpttrs_(&uplo, &n, &nrhs, d, e, b, &ldb, &info, 1);
}
void pttrs(char uplo, int n, int nrhs, double *d, cdouble *e, cdouble *b, int ldb, inout int info) {
    zpttrs_(&uplo, &n, &nrhs, d, e, b, &ldb, &info, 1);
}

/// Reduces a real symmetric-definite banded generalized eigenproblem
/// A x = lambda B x to standard form, where B has been factorized by
/// SPBSTF (Crawford's algorithm).
void sbgst(char *vect, char uplo, int n, int ka, int kb, float *ab, int ldab, float *bb, int ldbb, float *x, int ldx, float *work, inout int info) {
    ssbgst_(vect, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, x, &ldx, work, &info, 1, 1);
}
void sbgst(char *vect, char uplo, int n, int ka, int kb, double *ab, int ldab, double *bb, int ldbb, double *x, int ldx, double *work, inout int info) {
    dsbgst_(vect, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, x, &ldx, work, &info, 1, 1);
}

/// Reduces a complex Hermitian-definite banded generalized eigenproblem
/// A x = lambda B x to standard form, where B has been factorized by
/// CPBSTF (Crawford's algorithm).
void hbgst(char *vect, char uplo, int n, int ka, int kb, cfloat *ab, int ldab, cfloat *bb, int ldbb, cfloat *x, int ldx, cfloat *work, float *rwork, inout int info) {
    chbgst_(vect, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, x, &ldx, work, rwork, &info, 1, 1);
}
void hbgst(char *vect, char uplo, int n, int ka, int kb, cdouble *ab, int ldab, cdouble *bb, int ldbb, cdouble *x, int ldx, cdouble *work, double *rwork, inout int info) {
    zhbgst_(vect, &uplo, &n, &ka, &kb, ab, &ldab, bb, &ldbb, x, &ldx, work, rwork, &info, 1, 1);
}

/// Reduces a symmetric band matrix to real symmetric
/// tridiagonal form by an orthogonal similarity transformation.
void sbtrd(char *vect, char uplo, int n, int kd, float *ab, int ldab, float *d, float *e, float *q, int ldq, float *work, inout int info) {
    ssbtrd_(vect, &uplo, &n, &kd, ab, &ldab, d, e, q, &ldq, work, &info, 1, 1);
}
void sbtrd(char *vect, char uplo, int n, int kd, double *ab, int ldab, double *d, double *e, double *q, int ldq, double *work, inout int info) {
    dsbtrd_(vect, &uplo, &n, &kd, ab, &ldab, d, e, q, &ldq, work, &info, 1, 1);
}

/// Reduces a Hermitian band matrix to real symmetric
/// tridiagonal form by a unitary similarity transformation.
void hbtrd(char *vect, char uplo, int n, int kd, cfloat *ab, int ldab, float *d, float *e, cfloat *q, int ldq, cfloat *work, inout int info) {
    chbtrd_(vect, &uplo, &n, &kd, ab, &ldab, d, e, q, &ldq, work, &info, 1, 1);
}
void hbtrd(char *vect, char uplo, int n, int kd, cdouble *ab, int ldab, double *d, double *e, cdouble *q, int ldq, cdouble *work, inout int info) {
    zhbtrd_(vect, &uplo, &n, &kd, ab, &ldab, d, e, q, &ldq, work, &info, 1, 1);
}

/// Estimates the reciprocal of the condition number of a
/// real symmetric indefinite
/// matrix in packed storage, using the factorization computed
/// by SSPTRF.
void spcon(char uplo, int n, float *ap, int *ipiv, float *anorm, float rcond, float *work, int *iwork, inout int info) {
    sspcon_(&uplo, &n, ap, ipiv, anorm, &rcond, work, iwork, &info, 1);
}
void spcon(char uplo, int n, double *ap, int *ipiv, double *anorm, double rcond, double *work, int *iwork, inout int info) {
    dspcon_(&uplo, &n, ap, ipiv, anorm, &rcond, work, iwork, &info, 1);
}
void spcon(char uplo, int n, cfloat *ap, int *ipiv, float *anorm, float rcond, cfloat *work, inout int info) {
    cspcon_(&uplo, &n, ap, ipiv, anorm, &rcond, work, &info, 1);
}
void spcon(char uplo, int n, cdouble *ap, int *ipiv, double *anorm, double rcond, cdouble *work, inout int info) {
    zspcon_(&uplo, &n, ap, ipiv, anorm, &rcond, work, &info, 1);
}

/// Estimates the reciprocal of the condition number of a
/// complex Hermitian indefinite
/// matrix in packed storage, using the factorization computed
/// by CHPTRF.
void hpcon(char uplo, int n, cfloat *ap, int *ipiv, float *anorm, float rcond, cfloat *work, inout int info) {
    chpcon_(&uplo, &n, ap, ipiv, anorm, &rcond, work, &info, 1);
}
void hpcon(char uplo, int n, cdouble *ap, int *ipiv, double *anorm, double rcond, cdouble *work, inout int info) {
    zhpcon_(&uplo, &n, ap, ipiv, anorm, &rcond, work, &info, 1);
}

/// Reduces a symmetric-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form,  where A and B are held in packed storage, and B has been
/// factorized by SPPTRF.
void spgst(int itype, char uplo, int n, float *ap, float *bp, inout int info) {
    sspgst_(&itype, &uplo, &n, ap, bp, &info, 1);
}
void spgst(int itype, char uplo, int n, double *ap, double *bp, inout int info) {
    dspgst_(&itype, &uplo, &n, ap, bp, &info, 1);
}

/// Reduces a Hermitian-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form,  where A and B are held in packed storage, and B has been
/// factorized by CPPTRF.
void hpgst(int itype, char uplo, int n, cfloat *ap, cfloat *bp, inout int info) {
    chpgst_(&itype, &uplo, &n, ap, bp, &info, 1);
}
void hpgst(int itype, char uplo, int n, cdouble *ap, cdouble *bp, inout int info) {
    zhpgst_(&itype, &uplo, &n, ap, bp, &info, 1);
}

/// Improves the computed solution to a real
/// symmetric indefinite system of linear equations
/// AX=B, where A is held in packed storage, and provides forward
/// and backward error bounds for the solution.
void sprfs(char uplo, int n, int nrhs, float *ap, float *afp, int *ipiv, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    ssprfs_(&uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void sprfs(char uplo, int n, int nrhs, double *ap, double *afp, int *ipiv, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dsprfs_(&uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void sprfs(char uplo, int n, int nrhs, cfloat *ap, cfloat *afp, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    csprfs_(&uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void sprfs(char uplo, int n, int nrhs, cdouble *ap, cdouble *afp, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zsprfs_(&uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Improves the computed solution to a complex
/// Hermitian indefinite system of linear equations
/// AX=B, where A is held in packed storage, and provides forward
/// and backward error bounds for the solution.
void hprfs(char uplo, int n, int nrhs, cfloat *ap, cfloat *afp, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    chprfs_(&uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void hprfs(char uplo, int n, int nrhs, cdouble *ap, cdouble *afp, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zhprfs_(&uplo, &n, &nrhs, ap, afp, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Reduces a symmetric matrix in packed storage to real
/// symmetric tridiagonal form by an orthogonal similarity
/// transformation.
void sptrd(char uplo, int n, float *ap, float *d, float *e, float *tau, inout int info) {
    ssptrd_(&uplo, &n, ap, d, e, tau, &info, 1);
}
void sptrd(char uplo, int n, double *ap, double *d, double *e, double *tau, inout int info) {
    dsptrd_(&uplo, &n, ap, d, e, tau, &info, 1);
}

/// Reduces a Hermitian matrix in packed storage to real
/// symmetric tridiagonal form by a unitary similarity
/// transformation.
void hptrd(char uplo, int n, cfloat *ap, float *d, float *e, cfloat *tau, inout int info) {
    chptrd_(&uplo, &n, ap, d, e, tau, &info, 1);
}
void hptrd(char uplo, int n, cdouble *ap, double *d, double *e, cdouble *tau, inout int info) {
    zhptrd_(&uplo, &n, ap, d, e, tau, &info, 1);
}

/// Computes the factorization of a real
/// symmetric-indefinite matrix in packed storage,
/// using the diagonal pivoting method.
void sptrf(char uplo, int n, float *ap, int *ipiv, inout int info) {
    ssptrf_(&uplo, &n, ap, ipiv, &info, 1);
}
void sptrf(char uplo, int n, double *ap, int *ipiv, inout int info) {
    dsptrf_(&uplo, &n, ap, ipiv, &info, 1);
}
void sptrf(char uplo, int n, cfloat *ap, int *ipiv, inout int info) {
    csptrf_(&uplo, &n, ap, ipiv, &info, 1);
}
void sptrf(char uplo, int n, cdouble *ap, int *ipiv, inout int info) {
    zsptrf_(&uplo, &n, ap, ipiv, &info, 1);
}

/// Computes the factorization of a complex
/// Hermitian-indefinite matrix in packed storage,
/// using the diagonal pivoting method.
void hptrf(char uplo, int n, cfloat *ap, int *ipiv, inout int info) {
    chptrf_(&uplo, &n, ap, ipiv, &info, 1);
}
void hptrf(char uplo, int n, cdouble *ap, int *ipiv, inout int info) {
    zhptrf_(&uplo, &n, ap, ipiv, &info, 1);
}

/// Computes the inverse of a real symmetric
/// indefinite matrix in packed storage, using the factorization
/// computed by SSPTRF.
void sptri(char uplo, int n, float *ap, int *ipiv, float *work, inout int info) {
    ssptri_(&uplo, &n, ap, ipiv, work, &info, 1);
}
void sptri(char uplo, int n, double *ap, int *ipiv, double *work, inout int info) {
    dsptri_(&uplo, &n, ap, ipiv, work, &info, 1);
}
void sptri(char uplo, int n, cfloat *ap, int *ipiv, cfloat *work, inout int info) {
    csptri_(&uplo, &n, ap, ipiv, work, &info, 1);
}
void sptri(char uplo, int n, cdouble *ap, int *ipiv, cdouble *work, inout int info) {
    zsptri_(&uplo, &n, ap, ipiv, work, &info, 1);
}

/// Computes the inverse of a complex
/// Hermitian indefinite matrix in packed storage, using the factorization
/// computed by CHPTRF.
void hptri(char uplo, int n, cfloat *ap, int *ipiv, cfloat *work, inout int info) {
    chptri_(&uplo, &n, ap, ipiv, work, &info, 1);
}
void hptri(char uplo, int n, cdouble *ap, int *ipiv, cdouble *work, inout int info) {
    zhptri_(&uplo, &n, ap, ipiv, work, &info, 1);
}

/// Solves a real symmetric
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, using the factorization computed
/// by SSPTRF.
void sptrs(char uplo, int n, int nrhs, float *ap, int *ipiv, float *b, int ldb, inout int info) {
    ssptrs_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}
void sptrs(char uplo, int n, int nrhs, double *ap, int *ipiv, double *b, int ldb, inout int info) {
    dsptrs_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}
void sptrs(char uplo, int n, int nrhs, cfloat *ap, int *ipiv, cfloat *b, int ldb, inout int info) {
    csptrs_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}
void sptrs(char uplo, int n, int nrhs, cdouble *ap, int *ipiv, cdouble *b, int ldb, inout int info) {
    zsptrs_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}

/// Solves a complex Hermitian
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, using the factorization computed
/// by CHPTRF.
void hptrs(char uplo, int n, int nrhs, cfloat *ap, int *ipiv, cfloat *b, int ldb, inout int info) {
    chptrs_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}
void hptrs(char uplo, int n, int nrhs, cdouble *ap, int *ipiv, cdouble *b, int ldb, inout int info) {
    zhptrs_(&uplo, &n, &nrhs, ap, ipiv, b, &ldb, &info, 1);
}

/// Computes selected eigenvalues of a real symmetric tridiagonal
/// matrix by bisection.
void stebz(char *range, char *order, int n, float *vl, float *vu, int il, int iu, float *abstol, float *d, float *e, int m, int nsplit, float *w, int iblock, int isplit, float *work, int *iwork, inout int info) {
    sstebz_(range, order, &n, vl, vu, &il, &iu, abstol, d, e, &m, &nsplit, w, &iblock, &isplit, work, iwork, &info, 1, 1);
}
void stebz(char *range, char *order, int n, double *vl, double *vu, int il, int iu, double *abstol, double *d, double *e, int m, int nsplit, double *w, int iblock, int isplit, double *work, int *iwork, inout int info) {
    dstebz_(range, order, &n, vl, vu, &il, &iu, abstol, d, e, &m, &nsplit, w, &iblock, &isplit, work, iwork, &info, 1, 1);
}

/// Computes all eigenvalues and, optionally, eigenvectors of a
/// symmetric tridiagonal matrix using the divide and conquer algorithm.
void stedc(char *compz, int n, float *d, float *e, float *z, int ldz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    sstedc_(compz, &n, d, e, z, &ldz, work, &lwork, iwork, &liwork, &info, 1);
}
void stedc(char *compz, int n, double *d, double *e, double *z, int ldz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dstedc_(compz, &n, d, e, z, &ldz, work, &lwork, iwork, &liwork, &info, 1);
}
void stedc(char *compz, int n, float *d, float *e, cfloat *z, int ldz, cfloat *work, int lwork, float *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    cstedc_(compz, &n, d, e, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1);
}
void stedc(char *compz, int n, double *d, double *e, cdouble *z, int ldz, cdouble *work, int lwork, double *rwork, int lrwork, int *iwork, int liwork, inout int info) {
    zstedc_(compz, &n, d, e, z, &ldz, work, &lwork, rwork, &lrwork, iwork, &liwork, &info, 1);
}

/// Computes selected eigenvalues and, optionally, eigenvectors of a
/// symmetric tridiagonal matrix.  The eigenvalues are computed by the
/// dqds algorithm, while eigenvectors are computed from various "good"
/// LDL^T representations (also known as Relatively Robust Representations.)
void stegr(char *jobz, char *range, int n, float *d, float *e, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, float *z, int ldz, int isuppz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    sstegr_(jobz, range, &n, d, e, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void stegr(char *jobz, char *range, int n, double *d, double *e, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, double *z, int ldz, int isuppz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dstegr_(jobz, range, &n, d, e, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void stegr(char *jobz, char *range, int n, float *d, float *e, float *vl, float *vu, int il, int iu, float *abstol, int m, float *w, cfloat *z, int ldz, int isuppz, float *work, int lwork, int *iwork, int liwork, inout int info) {
    cstegr_(jobz, range, &n, d, e, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void stegr(char *jobz, char *range, int n, double *d, double *e, double *vl, double *vu, int il, int iu, double *abstol, int m, double *w, cdouble *z, int ldz, int isuppz, double *work, int lwork, int *iwork, int liwork, inout int info) {
    zstegr_(jobz, range, &n, d, e, vl, vu, &il, &iu, abstol, &m, w, z, &ldz, &isuppz, work, &lwork, iwork, &liwork, &info, 1, 1);
}

/// Computes selected eigenvectors of a real symmetric tridiagonal
/// matrix by inverse iteration.
void stein(int n, float *d, float *e, int m, float *w, int iblock, int isplit, float *z, int ldz, float *work, int *iwork, int ifail, inout int info) {
    sstein_(&n, d, e, &m, w, &iblock, &isplit, z, &ldz, work, iwork, &ifail, &info);
}
void stein(int n, double *d, double *e, int m, double *w, int iblock, int isplit, double *z, int ldz, double *work, int *iwork, int ifail, inout int info) {
    dstein_(&n, d, e, &m, w, &iblock, &isplit, z, &ldz, work, iwork, &ifail, &info);
}
void stein(int n, float *d, float *e, int m, float *w, int iblock, int isplit, cfloat *z, int ldz, float *work, int *iwork, int ifail, inout int info) {
    cstein_(&n, d, e, &m, w, &iblock, &isplit, z, &ldz, work, iwork, &ifail, &info);
}
void stein(int n, double *d, double *e, int m, double *w, int iblock, int isplit, cdouble *z, int ldz, double *work, int *iwork, int ifail, inout int info) {
    zstein_(&n, d, e, &m, w, &iblock, &isplit, z, &ldz, work, iwork, &ifail, &info);
}

/// Computes all eigenvalues and eigenvectors of a real symmetric
/// tridiagonal matrix, using the implicit QL or QR algorithm.
void steqr(char *compz, int n, float *d, float *e, float *z, int ldz, float *work, inout int info) {
    ssteqr_(compz, &n, d, e, z, &ldz, work, &info, 1);
}
void steqr(char *compz, int n, double *d, double *e, double *z, int ldz, double *work, inout int info) {
    dsteqr_(compz, &n, d, e, z, &ldz, work, &info, 1);
}
void steqr(char *compz, int n, float *d, float *e, cfloat *z, int ldz, float *work, inout int info) {
    csteqr_(compz, &n, d, e, z, &ldz, work, &info, 1);
}
void steqr(char *compz, int n, double *d, double *e, cdouble *z, int ldz, double *work, inout int info) {
    zsteqr_(compz, &n, d, e, z, &ldz, work, &info, 1);
}

/// Computes all eigenvalues of a real symmetric tridiagonal matrix,
/// using a root-free variant of the QL or QR algorithm.
void sterf(int n, float *d, float *e, inout int info) {
    ssterf_(&n, d, e, &info);
}
void sterf(int n, double *d, double *e, inout int info) {
    dsterf_(&n, d, e, &info);
}

/// Estimates the reciprocal of the condition number of a
/// real symmetric indefinite matrix,
/// using the factorization computed by SSYTRF.
void sycon(char uplo, int n, float *a, int lda, int *ipiv, float *anorm, float rcond, float *work, int *iwork, inout int info) {
    ssycon_(&uplo, &n, a, &lda, ipiv, anorm, &rcond, work, iwork, &info, 1);
}
void sycon(char uplo, int n, double *a, int lda, int *ipiv, double *anorm, double rcond, double *work, int *iwork, inout int info) {
    dsycon_(&uplo, &n, a, &lda, ipiv, anorm, &rcond, work, iwork, &info, 1);
}
void sycon(char uplo, int n, cfloat *a, int lda, int *ipiv, float *anorm, float rcond, cfloat *work, inout int info) {
    csycon_(&uplo, &n, a, &lda, ipiv, anorm, &rcond, work, &info, 1);
}
void sycon(char uplo, int n, cdouble *a, int lda, int *ipiv, double *anorm, double rcond, cdouble *work, inout int info) {
    zsycon_(&uplo, &n, a, &lda, ipiv, anorm, &rcond, work, &info, 1);
}

/// Estimates the reciprocal of the condition number of a
/// complex Hermitian indefinite matrix,
/// using the factorization computed by CHETRF.
void hecon(char uplo, int n, cfloat *a, int lda, int *ipiv, float *anorm, float rcond, cfloat *work, inout int info) {
    checon_(&uplo, &n, a, &lda, ipiv, anorm, &rcond, work, &info, 1);
}
void hecon(char uplo, int n, cdouble *a, int lda, int *ipiv, double *anorm, double rcond, cdouble *work, inout int info) {
    zhecon_(&uplo, &n, a, &lda, ipiv, anorm, &rcond, work, &info, 1);
}

/// Reduces a symmetric-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form, where B has been factorized by SPOTRF.
void sygst(int itype, char uplo, int n, float *a, int lda, float *b, int ldb, inout int info) {
    ssygst_(&itype, &uplo, &n, a, &lda, b, &ldb, &info, 1);
}
void sygst(int itype, char uplo, int n, double *a, int lda, double *b, int ldb, inout int info) {
    dsygst_(&itype, &uplo, &n, a, &lda, b, &ldb, &info, 1);
}

/// Reduces a Hermitian-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form, where B has been factorized by CPOTRF.
void hegst(int itype, char uplo, int n, cfloat *a, int lda, cfloat *b, int ldb, inout int info) {
    chegst_(&itype, &uplo, &n, a, &lda, b, &ldb, &info, 1);
}
void hegst(int itype, char uplo, int n, cdouble *a, int lda, cdouble *b, int ldb, inout int info) {
    zhegst_(&itype, &uplo, &n, a, &lda, b, &ldb, &info, 1);
}

/// Improves the computed solution to a real
/// symmetric indefinite system of linear equations
/// AX=B, and provides forward and backward error bounds for the
/// solution.
void syrfs(char uplo, int n, int nrhs, float *a, int lda, float *af, int ldaf, int *ipiv, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    ssyrfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void syrfs(char uplo, int n, int nrhs, double *a, int lda, double *af, int ldaf, int *ipiv, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dsyrfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1);
}
void syrfs(char uplo, int n, int nrhs, cfloat *a, int lda, cfloat *af, int ldaf, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    csyrfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void syrfs(char uplo, int n, int nrhs, cdouble *a, int lda, cdouble *af, int ldaf, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zsyrfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Improves the computed solution to a complex
/// Hermitian indefinite system of linear equations
/// AX=B, and provides forward and backward error bounds for the
/// solution.
void herfs(char uplo, int n, int nrhs, cfloat *a, int lda, cfloat *af, int ldaf, int *ipiv, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    cherfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}
void herfs(char uplo, int n, int nrhs, cdouble *a, int lda, cdouble *af, int ldaf, int *ipiv, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    zherfs_(&uplo, &n, &nrhs, a, &lda, af, &ldaf, ipiv, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1);
}

/// Reduces a symmetric matrix to real symmetric tridiagonal
/// form by an orthogonal similarity transformation.
void sytrd(char uplo, int n, float *a, int lda, float *d, float *e, float *tau, float *work, int lwork, inout int info) {
    ssytrd_(&uplo, &n, a, &lda, d, e, tau, work, &lwork, &info, 1);
}
void sytrd(char uplo, int n, double *a, int lda, double *d, double *e, double *tau, double *work, int lwork, inout int info) {
    dsytrd_(&uplo, &n, a, &lda, d, e, tau, work, &lwork, &info, 1);
}

/// Reduces a Hermitian matrix to real symmetric tridiagonal
/// form by an orthogonal/unitary similarity transformation.
void hetrd(char uplo, int n, cfloat *a, int lda, float *d, float *e, cfloat *tau, cfloat *work, int lwork, inout int info) {
    chetrd_(&uplo, &n, a, &lda, d, e, tau, work, &lwork, &info, 1);
}
void hetrd(char uplo, int n, cdouble *a, int lda, double *d, double *e, cdouble *tau, cdouble *work, int lwork, inout int info) {
    zhetrd_(&uplo, &n, a, &lda, d, e, tau, work, &lwork, &info, 1);
}

/// Computes the factorization of a real symmetric-indefinite matrix,
/// using the diagonal pivoting method.
void sytrf(char uplo, int n, float *a, int lda, int *ipiv, float *work, int lwork, inout int info) {
    ssytrf_(&uplo, &n, a, &lda, ipiv, work, &lwork, &info, 1);
}
void sytrf(char uplo, int n, double *a, int lda, int *ipiv, double *work, int lwork, inout int info) {
    dsytrf_(&uplo, &n, a, &lda, ipiv, work, &lwork, &info, 1);
}
void sytrf(char uplo, int n, cfloat *a, int lda, int *ipiv, cfloat *work, int lwork, inout int info) {
    csytrf_(&uplo, &n, a, &lda, ipiv, work, &lwork, &info, 1);
}
void sytrf(char uplo, int n, cdouble *a, int lda, int *ipiv, cdouble *work, int lwork, inout int info) {
    zsytrf_(&uplo, &n, a, &lda, ipiv, work, &lwork, &info, 1);
}

/// Computes the factorization of a complex Hermitian-indefinite matrix,
/// using the diagonal pivoting method.
void hetrf(char uplo, int n, cfloat *a, int lda, int *ipiv, cfloat *work, int lwork, inout int info) {
    chetrf_(&uplo, &n, a, &lda, ipiv, work, &lwork, &info, 1);
}
void hetrf(char uplo, int n, cdouble *a, int lda, int *ipiv, cdouble *work, int lwork, inout int info) {
    zhetrf_(&uplo, &n, a, &lda, ipiv, work, &lwork, &info, 1);
}

/// Computes the inverse of a real symmetric indefinite matrix,
/// using the factorization computed by SSYTRF.
void sytri(char uplo, int n, float *a, int lda, int *ipiv, float *work, inout int info) {
    ssytri_(&uplo, &n, a, &lda, ipiv, work, &info, 1);
}
void sytri(char uplo, int n, double *a, int lda, int *ipiv, double *work, inout int info) {
    dsytri_(&uplo, &n, a, &lda, ipiv, work, &info, 1);
}
void sytri(char uplo, int n, cfloat *a, int lda, int *ipiv, cfloat *work, inout int info) {
    csytri_(&uplo, &n, a, &lda, ipiv, work, &info, 1);
}
void sytri(char uplo, int n, cdouble *a, int lda, int *ipiv, cdouble *work, inout int info) {
    zsytri_(&uplo, &n, a, &lda, ipiv, work, &info, 1);
}

/// Computes the inverse of a complex Hermitian indefinite matrix,
/// using the factorization computed by CHETRF.
void hetri(char uplo, int n, cfloat *a, int lda, int *ipiv, cfloat *work, inout int info) {
    chetri_(&uplo, &n, a, &lda, ipiv, work, &info, 1);
}
void hetri(char uplo, int n, cdouble *a, int lda, int *ipiv, cdouble *work, inout int info) {
    zhetri_(&uplo, &n, a, &lda, ipiv, work, &info, 1);
}

/// Solves a real symmetric indefinite system of linear equations AX=B,
/// using the factorization computed by SSPTRF.
void sytrs(char uplo, int n, int nrhs, float *a, int lda, int *ipiv, float *b, int ldb, inout int info) {
    ssytrs_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}
void sytrs(char uplo, int n, int nrhs, double *a, int lda, int *ipiv, double *b, int ldb, inout int info) {
    dsytrs_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}
void sytrs(char uplo, int n, int nrhs, cfloat *a, int lda, int *ipiv, cfloat *b, int ldb, inout int info) {
    csytrs_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}
void sytrs(char uplo, int n, int nrhs, cdouble *a, int lda, int *ipiv, cdouble *b, int ldb, inout int info) {
    zsytrs_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}

/// Solves a complex Hermitian indefinite system of linear equations AX=B,
/// using the factorization computed by CHPTRF.
void hetrs(char uplo, int n, int nrhs, cfloat *a, int lda, int *ipiv, cfloat *b, int ldb, inout int info) {
    chetrs_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}
void hetrs(char uplo, int n, int nrhs, cdouble *a, int lda, int *ipiv, cdouble *b, int ldb, inout int info) {
    zhetrs_(&uplo, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info, 1);
}

/// Estimates the reciprocal of the condition number of a triangular
/// band matrix, in either the 1-norm or the infinity-norm.
void tbcon(char *norm, char uplo, char diag, int n, int kd, float *ab, int ldab, float rcond, float *work, int *iwork, inout int info) {
    stbcon_(norm, &uplo, &diag, &n, &kd, ab, &ldab, &rcond, work, iwork, &info, 1, 1, 1);
}
void tbcon(char *norm, char uplo, char diag, int n, int kd, double *ab, int ldab, double rcond, double *work, int *iwork, inout int info) {
    dtbcon_(norm, &uplo, &diag, &n, &kd, ab, &ldab, &rcond, work, iwork, &info, 1, 1, 1);
}
void tbcon(char *norm, char uplo, char diag, int n, int kd, cfloat *ab, int ldab, float rcond, cfloat *work, float *rwork, inout int info) {
    ctbcon_(norm, &uplo, &diag, &n, &kd, ab, &ldab, &rcond, work, rwork, &info, 1, 1, 1);
}
void tbcon(char *norm, char uplo, char diag, int n, int kd, cdouble *ab, int ldab, double rcond, cdouble *work, double *rwork, inout int info) {
    ztbcon_(norm, &uplo, &diag, &n, &kd, ab, &ldab, &rcond, work, rwork, &info, 1, 1, 1);
}

/// Provides forward and backward error bounds for the solution
/// of a triangular banded system of linear equations AX=B,
/// A**T X=B or A**H X=B.
void tbrfs(char uplo, char *trans, char diag, int n, int kd, int nrhs, float *ab, int ldab, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    stbrfs_(&uplo, trans, &diag, &n, &kd, &nrhs, ab, &ldab, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void tbrfs(char uplo, char *trans, char diag, int n, int kd, int nrhs, double *ab, int ldab, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dtbrfs_(&uplo, trans, &diag, &n, &kd, &nrhs, ab, &ldab, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void tbrfs(char uplo, char *trans, char diag, int n, int kd, int nrhs, cfloat *ab, int ldab, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    ctbrfs_(&uplo, trans, &diag, &n, &kd, &nrhs, ab, &ldab, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1, 1, 1);
}
void tbrfs(char uplo, char *trans, char diag, int n, int kd, int nrhs, cdouble *ab, int ldab, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    ztbrfs_(&uplo, trans, &diag, &n, &kd, &nrhs, ab, &ldab, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1, 1, 1);
}

/// Solves a triangular banded system of linear equations AX=B,
/// A**T X=B or A**H X=B.
void tbtrs(char uplo, char *trans, char diag, int n, int kd, int nrhs, float *ab, int ldab, float *b, int ldb, inout int info) {
    stbtrs_(&uplo, trans, &diag, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1, 1, 1);
}
void tbtrs(char uplo, char *trans, char diag, int n, int kd, int nrhs, double *ab, int ldab, double *b, int ldb, inout int info) {
    dtbtrs_(&uplo, trans, &diag, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1, 1, 1);
}
void tbtrs(char uplo, char *trans, char diag, int n, int kd, int nrhs, cfloat *ab, int ldab, cfloat *b, int ldb, inout int info) {
    ctbtrs_(&uplo, trans, &diag, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1, 1, 1);
}
void tbtrs(char uplo, char *trans, char diag, int n, int kd, int nrhs, cdouble *ab, int ldab, cdouble *b, int ldb, inout int info) {
    ztbtrs_(&uplo, trans, &diag, &n, &kd, &nrhs, ab, &ldab, b, &ldb, &info, 1, 1, 1);
}

/// Computes some or all of the right and/or left generalized eigenvectors
/// of a pair of upper triangular matrices.
void tgevc(char side, char *howmny, int select, int n, float *a, int lda, float *b, int ldb, float *vl, int ldvl, float *vr, int ldvr, int mm, int m, float *work, inout int info) {
    stgevc_(&side, howmny, &select, &n, a, &lda, b, &ldb, vl, &ldvl, vr, &ldvr, &mm, &m, work, &info, 1, 1);
}
void tgevc(char side, char *howmny, int select, int n, double *a, int lda, double *b, int ldb, double *vl, int ldvl, double *vr, int ldvr, int mm, int m, double *work, inout int info) {
    dtgevc_(&side, howmny, &select, &n, a, &lda, b, &ldb, vl, &ldvl, vr, &ldvr, &mm, &m, work, &info, 1, 1);
}
void tgevc(char side, char *howmny, int select, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *vl, int ldvl, cfloat *vr, int ldvr, int mm, int m, cfloat *work, float *rwork, inout int info) {
    ctgevc_(&side, howmny, &select, &n, a, &lda, b, &ldb, vl, &ldvl, vr, &ldvr, &mm, &m, work, rwork, &info, 1, 1);
}
void tgevc(char side, char *howmny, int select, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *vl, int ldvl, cdouble *vr, int ldvr, int mm, int m, cdouble *work, double *rwork, inout int info) {
    ztgevc_(&side, howmny, &select, &n, a, &lda, b, &ldb, vl, &ldvl, vr, &ldvr, &mm, &m, work, rwork, &info, 1, 1);
}

/// Reorders the generalized real Schur decomposition of a real
/// matrix pair (A,B) using an orthogonal equivalence transformation
/// so that the diagonal block of (A,B) with row index IFST is moved
/// to row ILST.
void tgexc(int wantq, int wantz, int n, float *a, int lda, float *b, int ldb, float *q, int ldq, float *z, int ldz, int ifst, int ilst, float *work, int lwork, inout int info) {
    stgexc_(&wantq, &wantz, &n, a, &lda, b, &ldb, q, &ldq, z, &ldz, &ifst, &ilst, work, &lwork, &info);
}
void tgexc(int wantq, int wantz, int n, double *a, int lda, double *b, int ldb, double *q, int ldq, double *z, int ldz, int ifst, int ilst, double *work, int lwork, inout int info) {
    dtgexc_(&wantq, &wantz, &n, a, &lda, b, &ldb, q, &ldq, z, &ldz, &ifst, &ilst, work, &lwork, &info);
}
void tgexc(int wantq, int wantz, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *q, int ldq, cfloat *z, int ldz, int ifst, int ilst, inout int info) {
    ctgexc_(&wantq, &wantz, &n, a, &lda, b, &ldb, q, &ldq, z, &ldz, &ifst, &ilst, &info);
}
void tgexc(int wantq, int wantz, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *q, int ldq, cdouble *z, int ldz, int ifst, int ilst, inout int info) {
    ztgexc_(&wantq, &wantz, &n, a, &lda, b, &ldb, q, &ldq, z, &ldz, &ifst, &ilst, &info);
}

/// Reorders the generalized real Schur decomposition of a real
/// matrix pair (A, B) so that a selected cluster of eigenvalues
/// appears in the leading diagonal blocks of the upper quasi-triangular
/// matrix A and the upper triangular B.
void tgsen(int ijob, int wantq, int wantz, int select, int n, float *a, int lda, float *b, int ldb, float *alphar, float *alphai, float *betav, float *q, int ldq, float *z, int ldz, int m, float *pl, float *pr, float *dif, float *work, int lwork, int *iwork, int liwork, inout int info) {
    stgsen_(&ijob, &wantq, &wantz, &select, &n, a, &lda, b, &ldb, alphar, alphai, betav, q, &ldq, z, &ldz, &m, pl, pr, dif, work, &lwork, iwork, &liwork, &info);
}
void tgsen(int ijob, int wantq, int wantz, int select, int n, double *a, int lda, double *b, int ldb, double *alphar, double *alphai, double *betav, double *q, int ldq, double *z, int ldz, int m, double *pl, double *pr, double *dif, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dtgsen_(&ijob, &wantq, &wantz, &select, &n, a, &lda, b, &ldb, alphar, alphai, betav, q, &ldq, z, &ldz, &m, pl, pr, dif, work, &lwork, iwork, &liwork, &info);
}
void tgsen(int ijob, int wantq, int wantz, int select, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *alphav, cfloat *betav, cfloat *q, int ldq, cfloat *z, int ldz, int m, float *pl, float *pr, float *dif, cfloat *work, int lwork, int *iwork, int liwork, inout int info) {
    ctgsen_(&ijob, &wantq, &wantz, &select, &n, a, &lda, b, &ldb, alphav, betav, q, &ldq, z, &ldz, &m, pl, pr, dif, work, &lwork, iwork, &liwork, &info);
}
void tgsen(int ijob, int wantq, int wantz, int select, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *alphav, cdouble *betav, cdouble *q, int ldq, cdouble *z, int ldz, int m, double *pl, double *pr, double *dif, cdouble *work, int lwork, int *iwork, int liwork, inout int info) {
    ztgsen_(&ijob, &wantq, &wantz, &select, &n, a, &lda, b, &ldb, alphav, betav, q, &ldq, z, &ldz, &m, pl, pr, dif, work, &lwork, iwork, &liwork, &info);
}

/// Computes the generalized singular value decomposition of two real
/// upper triangular (or trapezoidal) matrices as output by SGGSVP.
void tgsja(char *jobu, char *jobv, char *jobq, int m, int p, int n, int k, int l, float *a, int lda, float *b, int ldb, float *tola, float *tolb, float *alphav, float *betav, float *u, int ldu, float *v, int ldv, float *q, int ldq, float *work, int ncycle, inout int info) {
    stgsja_(jobu, jobv, jobq, &m, &p, &n, &k, &l, a, &lda, b, &ldb, tola, tolb, alphav, betav, u, &ldu, v, &ldv, q, &ldq, work, &ncycle, &info, 1, 1, 1);
}
void tgsja(char *jobu, char *jobv, char *jobq, int m, int p, int n, int k, int l, double *a, int lda, double *b, int ldb, double *tola, double *tolb, double *alphav, double *betav, double *u, int ldu, double *v, int ldv, double *q, int ldq, double *work, int ncycle, inout int info) {
    dtgsja_(jobu, jobv, jobq, &m, &p, &n, &k, &l, a, &lda, b, &ldb, tola, tolb, alphav, betav, u, &ldu, v, &ldv, q, &ldq, work, &ncycle, &info, 1, 1, 1);
}
void tgsja(char *jobu, char *jobv, char *jobq, int m, int p, int n, int k, int l, cfloat *a, int lda, cfloat *b, int ldb, float *tola, float *tolb, float *alphav, float *betav, cfloat *u, int ldu, cfloat *v, int ldv, cfloat *q, int ldq, cfloat *work, int ncycle, inout int info) {
    ctgsja_(jobu, jobv, jobq, &m, &p, &n, &k, &l, a, &lda, b, &ldb, tola, tolb, alphav, betav, u, &ldu, v, &ldv, q, &ldq, work, &ncycle, &info, 1, 1, 1);
}
void tgsja(char *jobu, char *jobv, char *jobq, int m, int p, int n, int k, int l, cdouble *a, int lda, cdouble *b, int ldb, double *tola, double *tolb, double *alphav, double *betav, cdouble *u, int ldu, cdouble *v, int ldv, cdouble *q, int ldq, cdouble *work, int ncycle, inout int info) {
    ztgsja_(jobu, jobv, jobq, &m, &p, &n, &k, &l, a, &lda, b, &ldb, tola, tolb, alphav, betav, u, &ldu, v, &ldv, q, &ldq, work, &ncycle, &info, 1, 1, 1);
}

/// Estimates reciprocal condition numbers for specified
/// eigenvalues and/or eigenvectors of a matrix pair (A, B) in
/// generalized real Schur canonical form, as returned by SGGES.
void tgsna(char *job, char *howmny, int select, int n, float *a, int lda, float *b, int ldb, float *vl, int ldvl, float *vr, int ldvr, float *s, float *dif, int mm, int m, float *work, int lwork, int *iwork, inout int info) {
    stgsna_(job, howmny, &select, &n, a, &lda, b, &ldb, vl, &ldvl, vr, &ldvr, s, dif, &mm, &m, work, &lwork, iwork, &info, 1, 1);
}
void tgsna(char *job, char *howmny, int select, int n, double *a, int lda, double *b, int ldb, double *vl, int ldvl, double *vr, int ldvr, double *s, double *dif, int mm, int m, double *work, int lwork, int *iwork, inout int info) {
    dtgsna_(job, howmny, &select, &n, a, &lda, b, &ldb, vl, &ldvl, vr, &ldvr, s, dif, &mm, &m, work, &lwork, iwork, &info, 1, 1);
}
void tgsna(char *job, char *howmny, int select, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *vl, int ldvl, cfloat *vr, int ldvr, float *s, float *dif, int mm, int m, cfloat *work, int lwork, int *iwork, inout int info) {
    ctgsna_(job, howmny, &select, &n, a, &lda, b, &ldb, vl, &ldvl, vr, &ldvr, s, dif, &mm, &m, work, &lwork, iwork, &info, 1, 1);
}
void tgsna(char *job, char *howmny, int select, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *vl, int ldvl, cdouble *vr, int ldvr, double *s, double *dif, int mm, int m, cdouble *work, int lwork, int *iwork, inout int info) {
    ztgsna_(job, howmny, &select, &n, a, &lda, b, &ldb, vl, &ldvl, vr, &ldvr, s, dif, &mm, &m, work, &lwork, iwork, &info, 1, 1);
}

/// Solves the generalized Sylvester equation.
void tgsyl(char *trans, int ijob, int m, int n, float *a, int lda, float *b, int ldb, float *c, int ldc, float *d, int ldd, float *e, int lde, float *f, int ldf, float *scale, float *dif, float *work, int lwork, int *iwork, inout int info) {
    stgsyl_(trans, &ijob, &m, &n, a, &lda, b, &ldb, c, &ldc, d, &ldd, e, &lde, f, &ldf, scale, dif, work, &lwork, iwork, &info, 1);
}
void tgsyl(char *trans, int ijob, int m, int n, double *a, int lda, double *b, int ldb, double *c, int ldc, double *d, int ldd, double *e, int lde, double *f, int ldf, double *scale, double *dif, double *work, int lwork, int *iwork, inout int info) {
    dtgsyl_(trans, &ijob, &m, &n, a, &lda, b, &ldb, c, &ldc, d, &ldd, e, &lde, f, &ldf, scale, dif, work, &lwork, iwork, &info, 1);
}
void tgsyl(char *trans, int ijob, int m, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *c, int ldc, cfloat *d, int ldd, cfloat *e, int lde, cfloat *f, int ldf, float *scale, float *dif, cfloat *work, int lwork, int *iwork, inout int info) {
    ctgsyl_(trans, &ijob, &m, &n, a, &lda, b, &ldb, c, &ldc, d, &ldd, e, &lde, f, &ldf, scale, dif, work, &lwork, iwork, &info, 1);
}
void tgsyl(char *trans, int ijob, int m, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *c, int ldc, cdouble *d, int ldd, cdouble *e, int lde, cdouble *f, int ldf, double *scale, double *dif, cdouble *work, int lwork, int *iwork, inout int info) {
    ztgsyl_(trans, &ijob, &m, &n, a, &lda, b, &ldb, c, &ldc, d, &ldd, e, &lde, f, &ldf, scale, dif, work, &lwork, iwork, &info, 1);
}

/// Estimates the reciprocal of the condition number of a triangular
/// matrix in packed storage, in either the 1-norm or the infinity-norm.
void tpcon(char *norm, char uplo, char diag, int n, float *ap, float rcond, float *work, int *iwork, inout int info) {
    stpcon_(norm, &uplo, &diag, &n, ap, &rcond, work, iwork, &info, 1, 1, 1);
}
void tpcon(char *norm, char uplo, char diag, int n, double *ap, double rcond, double *work, int *iwork, inout int info) {
    dtpcon_(norm, &uplo, &diag, &n, ap, &rcond, work, iwork, &info, 1, 1, 1);
}
void tpcon(char *norm, char uplo, char diag, int n, cfloat *ap, float rcond, cfloat *work, float *rwork, inout int info) {
    ctpcon_(norm, &uplo, &diag, &n, ap, &rcond, work, rwork, &info, 1, 1, 1);
}
void tpcon(char *norm, char uplo, char diag, int n, cdouble *ap, double rcond, cdouble *work, double *rwork, inout int info) {
    ztpcon_(norm, &uplo, &diag, &n, ap, &rcond, work, rwork, &info, 1, 1, 1);
}

/// Provides forward and backward error bounds for the solution
/// of a triangular system of linear equations AX=B, A**T X=B or
/// A**H X=B, where A is held in packed storage.
void tprfs(char uplo, char *trans, char diag, int n, int nrhs, float *ap, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    stprfs_(&uplo, trans, &diag, &n, &nrhs, ap, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void tprfs(char uplo, char *trans, char diag, int n, int nrhs, double *ap, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dtprfs_(&uplo, trans, &diag, &n, &nrhs, ap, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void tprfs(char uplo, char *trans, char diag, int n, int nrhs, cfloat *ap, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    ctprfs_(&uplo, trans, &diag, &n, &nrhs, ap, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1, 1, 1);
}
void tprfs(char uplo, char *trans, char diag, int n, int nrhs, cdouble *ap, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    ztprfs_(&uplo, trans, &diag, &n, &nrhs, ap, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1, 1, 1);
}

///  Computes the inverse of a triangular matrix in packed storage.
void tptri(char uplo, char diag, int n, float *ap, inout int info) {
    stptri_(&uplo, &diag, &n, ap, &info, 1, 1);
}
void tptri(char uplo, char diag, int n, double *ap, inout int info) {
    dtptri_(&uplo, &diag, &n, ap, &info, 1, 1);
}
void tptri(char uplo, char diag, int n, cfloat *ap, inout int info) {
    ctptri_(&uplo, &diag, &n, ap, &info, 1, 1);
}
void tptri(char uplo, char diag, int n, cdouble *ap, inout int info) {
    ztptri_(&uplo, &diag, &n, ap, &info, 1, 1);
}

/// Solves a triangular system of linear equations AX=B,
/// A**T X=B or A**H X=B, where A is held in packed storage.
void tptrs(char uplo, char *trans, char diag, int n, int nrhs, float *ap, float *b, int ldb, inout int info) {
    stptrs_(&uplo, trans, &diag, &n, &nrhs, ap, b, &ldb, &info, 1, 1, 1);
}
void tptrs(char uplo, char *trans, char diag, int n, int nrhs, double *ap, double *b, int ldb, inout int info) {
    dtptrs_(&uplo, trans, &diag, &n, &nrhs, ap, b, &ldb, &info, 1, 1, 1);
}
void tptrs(char uplo, char *trans, char diag, int n, int nrhs, cfloat *ap, cfloat *b, int ldb, inout int info) {
    ctptrs_(&uplo, trans, &diag, &n, &nrhs, ap, b, &ldb, &info, 1, 1, 1);
}
void tptrs(char uplo, char *trans, char diag, int n, int nrhs, cdouble *ap, cdouble *b, int ldb, inout int info) {
    ztptrs_(&uplo, trans, &diag, &n, &nrhs, ap, b, &ldb, &info, 1, 1, 1);
}

/// Estimates the reciprocal of the condition number of a triangular
/// matrix, in either the 1-norm or the infinity-norm.
void trcon(char *norm, char uplo, char diag, int n, float *a, int lda, float rcond, float *work, int *iwork, inout int info) {
    strcon_(norm, &uplo, &diag, &n, a, &lda, &rcond, work, iwork, &info, 1, 1, 1);
}
void trcon(char *norm, char uplo, char diag, int n, double *a, int lda, double rcond, double *work, int *iwork, inout int info) {
    dtrcon_(norm, &uplo, &diag, &n, a, &lda, &rcond, work, iwork, &info, 1, 1, 1);
}
void trcon(char *norm, char uplo, char diag, int n, cfloat *a, int lda, float rcond, cfloat *work, float *rwork, inout int info) {
    ctrcon_(norm, &uplo, &diag, &n, a, &lda, &rcond, work, rwork, &info, 1, 1, 1);
}
void trcon(char *norm, char uplo, char diag, int n, cdouble *a, int lda, double rcond, cdouble *work, double *rwork, inout int info) {
    ztrcon_(norm, &uplo, &diag, &n, a, &lda, &rcond, work, rwork, &info, 1, 1, 1);
}

/// Computes some or all of the right and/or left eigenvectors of
/// an upper quasi-triangular matrix.
void trevc(char side, char *howmny, int select, int n, float *t, int ldt, float *vl, int ldvl, float *vr, int ldvr, int mm, int m, float *work, inout int info) {
    strevc_(&side, howmny, &select, &n, t, &ldt, vl, &ldvl, vr, &ldvr, &mm, &m, work, &info, 1, 1);
}
void trevc(char side, char *howmny, int select, int n, double *t, int ldt, double *vl, int ldvl, double *vr, int ldvr, int mm, int m, double *work, inout int info) {
    dtrevc_(&side, howmny, &select, &n, t, &ldt, vl, &ldvl, vr, &ldvr, &mm, &m, work, &info, 1, 1);
}
void trevc(char side, char *howmny, int select, int n, cfloat *t, int ldt, cfloat *vl, int ldvl, cfloat *vr, int ldvr, int mm, int m, cfloat *work, float *rwork, inout int info) {
    ctrevc_(&side, howmny, &select, &n, t, &ldt, vl, &ldvl, vr, &ldvr, &mm, &m, work, rwork, &info, 1, 1);
}
void trevc(char side, char *howmny, int select, int n, cdouble *t, int ldt, cdouble *vl, int ldvl, cdouble *vr, int ldvr, int mm, int m, cdouble *work, double *rwork, inout int info) {
    ztrevc_(&side, howmny, &select, &n, t, &ldt, vl, &ldvl, vr, &ldvr, &mm, &m, work, rwork, &info, 1, 1);
}

/// Reorders the Schur factorization of a matrix by an orthogonal
/// similarity transformation.
void trexc(char *compq, int n, float *t, int ldt, float *q, int ldq, int ifst, int ilst, float *work, inout int info) {
    strexc_(compq, &n, t, &ldt, q, &ldq, &ifst, &ilst, work, &info, 1);
}
void trexc(char *compq, int n, double *t, int ldt, double *q, int ldq, int ifst, int ilst, double *work, inout int info) {
    dtrexc_(compq, &n, t, &ldt, q, &ldq, &ifst, &ilst, work, &info, 1);
}
void trexc(char *compq, int n, cfloat *t, int ldt, cfloat *q, int ldq, int ifst, int ilst, inout int info) {
    ctrexc_(compq, &n, t, &ldt, q, &ldq, &ifst, &ilst, &info, 1);
}
void trexc(char *compq, int n, cdouble *t, int ldt, cdouble *q, int ldq, int ifst, int ilst, inout int info) {
    ztrexc_(compq, &n, t, &ldt, q, &ldq, &ifst, &ilst, &info, 1);
}

/// Provides forward and backward error bounds for the solution
/// of a triangular system of linear equations A X=B, A**T X=B or
/// A**H X=B.
void trrfs(char uplo, char *trans, char diag, int n, int nrhs, float *a, int lda, float *b, int ldb, float *x, int ldx, float *ferr, float *berr, float *work, int *iwork, inout int info) {
    strrfs_(&uplo, trans, &diag, &n, &nrhs, a, &lda, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void trrfs(char uplo, char *trans, char diag, int n, int nrhs, double *a, int lda, double *b, int ldb, double *x, int ldx, double *ferr, double *berr, double *work, int *iwork, inout int info) {
    dtrrfs_(&uplo, trans, &diag, &n, &nrhs, a, &lda, b, &ldb, x, &ldx, ferr, berr, work, iwork, &info, 1, 1, 1);
}
void trrfs(char uplo, char *trans, char diag, int n, int nrhs, cfloat *a, int lda, cfloat *b, int ldb, cfloat *x, int ldx, float *ferr, float *berr, cfloat *work, float *rwork, inout int info) {
    ctrrfs_(&uplo, trans, &diag, &n, &nrhs, a, &lda, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1, 1, 1);
}
void trrfs(char uplo, char *trans, char diag, int n, int nrhs, cdouble *a, int lda, cdouble *b, int ldb, cdouble *x, int ldx, double *ferr, double *berr, cdouble *work, double *rwork, inout int info) {
    ztrrfs_(&uplo, trans, &diag, &n, &nrhs, a, &lda, b, &ldb, x, &ldx, ferr, berr, work, rwork, &info, 1, 1, 1);
}

/// Reorders the Schur factorization of a matrix in order to find
/// an orthonormal basis of a right invariant subspace corresponding
/// to selected eigenvalues, and returns reciprocal condition numbers
/// (sensitivities) of the average of the cluster of eigenvalues
/// and of the invariant subspace.
void trsen(char *job, char *compq, int select, int n, float *t, int ldt, float *q, int ldq, float *wr, float *wi, int m, float *s, float *sep, float *work, int lwork, int *iwork, int liwork, inout int info) {
    strsen_(job, compq, &select, &n, t, &ldt, q, &ldq, wr, wi, &m, s, sep, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void trsen(char *job, char *compq, int select, int n, double *t, int ldt, double *q, int ldq, double *wr, double *wi, int m, double *s, double *sep, double *work, int lwork, int *iwork, int liwork, inout int info) {
    dtrsen_(job, compq, &select, &n, t, &ldt, q, &ldq, wr, wi, &m, s, sep, work, &lwork, iwork, &liwork, &info, 1, 1);
}
void trsen(char *job, char *compq, int select, int n, cfloat *t, int ldt, cfloat *q, int ldq, cfloat *w, int m, float *s, float *sep, cfloat *work, int lwork, inout int info) {
    ctrsen_(job, compq, &select, &n, t, &ldt, q, &ldq, w, &m, s, sep, work, &lwork, &info, 1, 1);
}
void trsen(char *job, char *compq, int select, int n, cdouble *t, int ldt, cdouble *q, int ldq, cdouble *w, int m, double *s, double *sep, cdouble *work, int lwork, inout int info) {
    ztrsen_(job, compq, &select, &n, t, &ldt, q, &ldq, w, &m, s, sep, work, &lwork, &info, 1, 1);
}

/// Estimates the reciprocal condition numbers (sensitivities)
/// of selected eigenvalues and eigenvectors of an upper
/// quasi-triangular matrix.
void trsna(char *job, char *howmny, int select, int n, float *t, int ldt, float *vl, int ldvl, float *vr, int ldvr, float *s, float *sep, int mm, int m, float *work, int ldwork, int *iwork, inout int info) {
    strsna_(job, howmny, &select, &n, t, &ldt, vl, &ldvl, vr, &ldvr, s, sep, &mm, &m, work, &ldwork, iwork, &info, 1, 1);
}
void trsna(char *job, char *howmny, int select, int n, double *t, int ldt, double *vl, int ldvl, double *vr, int ldvr, double *s, double *sep, int mm, int m, double *work, int ldwork, int *iwork, inout int info) {
    dtrsna_(job, howmny, &select, &n, t, &ldt, vl, &ldvl, vr, &ldvr, s, sep, &mm, &m, work, &ldwork, iwork, &info, 1, 1);
}
void trsna(char *job, char *howmny, int select, int n, cfloat *t, int ldt, cfloat *vl, int ldvl, cfloat *vr, int ldvr, float *s, float *sep, int mm, int m, cfloat *work, int ldwork, float *rwork, inout int info) {
    ctrsna_(job, howmny, &select, &n, t, &ldt, vl, &ldvl, vr, &ldvr, s, sep, &mm, &m, work, &ldwork, rwork, &info, 1, 1);
}
void trsna(char *job, char *howmny, int select, int n, cdouble *t, int ldt, cdouble *vl, int ldvl, cdouble *vr, int ldvr, double *s, double *sep, int mm, int m, cdouble *work, int ldwork, double *rwork, inout int info) {
    ztrsna_(job, howmny, &select, &n, t, &ldt, vl, &ldvl, vr, &ldvr, s, sep, &mm, &m, work, &ldwork, rwork, &info, 1, 1);
}

/// Solves the Sylvester matrix equation A X +/- X B=C where A
/// and B are upper quasi-triangular, and may be transposed.
void trsyl(char *trana, char *tranb, int isgn, int m, int n, float *a, int lda, float *b, int ldb, float *c, int ldc, float *scale, inout int info) {
    strsyl_(trana, tranb, &isgn, &m, &n, a, &lda, b, &ldb, c, &ldc, scale, &info, 1, 1);
}
void trsyl(char *trana, char *tranb, int isgn, int m, int n, double *a, int lda, double *b, int ldb, double *c, int ldc, double *scale, inout int info) {
    dtrsyl_(trana, tranb, &isgn, &m, &n, a, &lda, b, &ldb, c, &ldc, scale, &info, 1, 1);
}
void trsyl(char *trana, char *tranb, int isgn, int m, int n, cfloat *a, int lda, cfloat *b, int ldb, cfloat *c, int ldc, float *scale, inout int info) {
    ctrsyl_(trana, tranb, &isgn, &m, &n, a, &lda, b, &ldb, c, &ldc, scale, &info, 1, 1);
}
void trsyl(char *trana, char *tranb, int isgn, int m, int n, cdouble *a, int lda, cdouble *b, int ldb, cdouble *c, int ldc, double *scale, inout int info) {
    ztrsyl_(trana, tranb, &isgn, &m, &n, a, &lda, b, &ldb, c, &ldc, scale, &info, 1, 1);
}

/// Computes the inverse of a triangular matrix.
void trtri(char uplo, char diag, int n, float *a, int lda, inout int info) {
    strtri_(&uplo, &diag, &n, a, &lda, &info, 1, 1);
}
void trtri(char uplo, char diag, int n, double *a, int lda, inout int info) {
    dtrtri_(&uplo, &diag, &n, a, &lda, &info, 1, 1);
}
void trtri(char uplo, char diag, int n, cfloat *a, int lda, inout int info) {
    ctrtri_(&uplo, &diag, &n, a, &lda, &info, 1, 1);
}
void trtri(char uplo, char diag, int n, cdouble *a, int lda, inout int info) {
    ztrtri_(&uplo, &diag, &n, a, &lda, &info, 1, 1);
}

/// Solves a triangular system of linear equations AX=B,
/// A**T X=B or A**H X=B.
void trtrs(char uplo, char *trans, char diag, int n, int nrhs, float *a, int lda, float *b, int ldb, inout int info) {
    strtrs_(&uplo, trans, &diag, &n, &nrhs, a, &lda, b, &ldb, &info, 1, 1, 1);
}
void trtrs(char uplo, char *trans, char diag, int n, int nrhs, double *a, int lda, double *b, int ldb, inout int info) {
    dtrtrs_(&uplo, trans, &diag, &n, &nrhs, a, &lda, b, &ldb, &info, 1, 1, 1);
}
void trtrs(char uplo, char *trans, char diag, int n, int nrhs, cfloat *a, int lda, cfloat *b, int ldb, inout int info) {
    ctrtrs_(&uplo, trans, &diag, &n, &nrhs, a, &lda, b, &ldb, &info, 1, 1, 1);
}
void trtrs(char uplo, char *trans, char diag, int n, int nrhs, cdouble *a, int lda, cdouble *b, int ldb, inout int info) {
    ztrtrs_(&uplo, trans, &diag, &n, &nrhs, a, &lda, b, &ldb, &info, 1, 1, 1);
}

/// Computes an RQ factorization of an upper trapezoidal matrix.
void tzrqf(int m, int n, float *a, int lda, float *tau, inout int info) {
    stzrqf_(&m, &n, a, &lda, tau, &info);
}
void tzrqf(int m, int n, double *a, int lda, double *tau, inout int info) {
    dtzrqf_(&m, &n, a, &lda, tau, &info);
}
void tzrqf(int m, int n, cfloat *a, int lda, cfloat *tau, inout int info) {
    ctzrqf_(&m, &n, a, &lda, tau, &info);
}
void tzrqf(int m, int n, cdouble *a, int lda, cdouble *tau, inout int info) {
    ztzrqf_(&m, &n, a, &lda, tau, &info);
}

/// Computes an RZ factorization of an upper trapezoidal matrix
/// (blocked version of STZRQF).
void tzrzf(int m, int n, float *a, int lda, float *tau, float *work, int lwork, inout int info) {
    stzrzf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void tzrzf(int m, int n, double *a, int lda, double *tau, double *work, int lwork, inout int info) {
    dtzrzf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void tzrzf(int m, int n, cfloat *a, int lda, cfloat *tau, cfloat *work, int lwork, inout int info) {
    ctzrzf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}
void tzrzf(int m, int n, cdouble *a, int lda, cdouble *tau, cdouble *work, int lwork, inout int info) {
    ztzrzf_(&m, &n, a, &lda, tau, work, &lwork, &info);
}


/// Multiplies a general matrix by the unitary
/// transformation matrix from a reduction to tridiagonal form
/// determined by CHPTRD.
void upmtr(char side, char uplo, char *trans, int m, int n, cfloat *ap, cfloat *tau, cfloat *c, int ldc, cfloat *work, inout int info) {
    cupmtr_(&side, &uplo, trans, &m, &n, ap, tau, c, &ldc, work, &info, 1, 1, 1);
}
void upmtr(char side, char uplo, char *trans, int m, int n, cdouble *ap, cdouble *tau, cdouble *c, int ldc, cdouble *work, inout int info) {
    zupmtr_(&side, &uplo, trans, &m, &n, ap, tau, c, &ldc, work, &info, 1, 1, 1);
}


//------------------------------------
//     ----- MISC routines -----
//------------------------------------

int ilaenv(int ispec, char *name, char *opts, int n1, int n2, int n3, int n4, int len_name, int len_opts) {
    return ilaenv_(&ispec, name, opts, &n1, &n2, &n3, &n4, len_name, len_opts);
}
void ilaenvset(int ispec, char *name, char *opts, int n1, int n2, int n3, int n4, int nvalue, inout int info, int len_name, int len_opts) {
    // hmm this doesn't seem to exist in the lib in -g debug builds for some reason
    //ilaenvset_(&ispec, name, opts, &n1, &n2, &n3, &n4, &nvalue, &info, len_name, len_opts);
}

///
float lamch(char *cmach) {
    return slamch_(cmach, 1);
}
double lamch(char *cmach) {
    return dlamch_(cmach, 1);
}

///
lapack_float_ret_t second() {
    return second_();
}
double secnd() {
    return dsecnd_();
}


