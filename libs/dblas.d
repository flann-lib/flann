// THIS FILE AUTOMATICALLY GENERATED FROM blas.d USING wrapprotos.py
// date:  Thu Dec 14 05:52:21 2006

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

module dblas;
import blas;

// For a good description of issues calling Fortran from C see
//    http://www.math.utah.edu/software/c-with-fortran.html
// Namely the wierdness with char* arguments and complex return types.


// Prototypes for the raw Fortran interface to BLAS

version (FORTRAN_FLOAT_FUNCTIONS_RETURN_DOUBLE) {
} else {
}

/* BLAS routines */

/** Level 1 BLAS */

/** Generate plane (Givens) rotation
    Given a and b, compute the elements of a rotation matrix such that
          _      _     _   _    _   _
          | c  s |     | a |    | r |
          |-s  c | *   | b | =  | 0 |
          -      -     -   -    -   -
     where
     r = +/- sqrt (a^2  + b^2 ) and c^2 + s^2  = 1   (real case)
     or
     r = (a/sqrt(conj(a)*a  + conj(b)*b)) * sqrt(conj(a)*a + conj(b)*b)
*/
void rotg(inout float a, inout float b, out float c, out float s) {
    srotg_(&a, &b, &c, &s);
}
void rotg(inout double a, inout double b, out double c, out double s) {
    drotg_(&a, &b, &c, &s);
}
void rotg(inout cfloat a, inout cfloat b, out float c, out cfloat s) {
    crotg_(&a, &b, &c, &s);
}
void rotg(inout cdouble a, inout cdouble b, out double c, out cdouble s) {
    zrotg_(&a, &b, &c, &s);
}

/// Generate modified plane (Givens) rotation
void rotmg(inout double d1, inout double d2, inout double b1, inout double b2, double *param) {
    drotmg_(&d1, &d2, &b1, &b2, param);
}
void rotmg(inout float d1, inout float d2, inout float b1, inout float b2, float *param) {
    srotmg_(&d1, &d2, &b1, &b2, param);
}

/// Apply plane (Givens) rotation
///             _      _
///     x_i  := | c  s | * x_i
///     y_i     |-s  c |   y_i
///             -      -
void rot(int n, float *x, int incx, float *y, int incy, float c, float s) {
    srot_(&n, x, &incx, y, &incy, &c, &s);
}
void rot(int n, double *x, int incx, double *y, int incy, double c, double s) {
    drot_(&n, x, &incx, y, &incy, &c, &s);
}
void rot(int n, cfloat *x, int incx, cfloat *y, int incy, float c, float s) {
    csrot_(&n, x, &incx, y, &incy, &c, &s);
}
void rot(int n, cdouble *x, int incx, cdouble *y, int incy, double c, double s) {
    zdrot_(&n, x, &incx, y, &incy, &c, &s);
}

/// Apply modified plane (Givens) rotation
void rotm(int n, float *x, int incx, float *y, int incy, float *param) {
    srotm_(&n, x, &incx, y, &incy, param);
}
void rotm(int n, double *x, int incx, double *y, int incy, double *param) {
    drotm_(&n, x, &incx, y, &incy, param);
}

/// Swap the values contained in x and y 
///     x <-> y
void swap(int n, float *x, int incx, float *y, int incy) {
    sswap_(&n, x, &incx, y, &incy);
}
void swap(int n, double *x, int incx, double *y, int incy) {
    dswap_(&n, x, &incx, y, &incy);
}
void swap(int n, cfloat *x, int incx, cfloat *y, int incy) {
    cswap_(&n, x, &incx, y, &incy);
}
void swap(int n, cdouble *x, int incx, cdouble *y, int incy) {
    zswap_(&n, x, &incx, y, &incy);
}

/// x := alpha * x
void scal(int n, float alpha, float *x, int incx) {
    sscal_(&n, &alpha, x, &incx);
}
void scal(int n, double alpha, double *x, int incx) {
    dscal_(&n, &alpha, x, &incx);
}
void scal(int n, cfloat alpha, cfloat *x, int incx) {
    cscal_(&n, &alpha, x, &incx);
}
void scal(int n, float alpha, cfloat *x, int incx) {
    csscal_(&n, &alpha, x, &incx);
}
void scal(int n, cdouble alpha, cdouble *x, int incx) {
    zscal_(&n, &alpha, x, &incx);
}
void scal(int n, double alpha, cdouble *x, int incx) {
    zdscal_(&n, &alpha, x, &incx);
}

/// y := x
void copy(int n, float *x, int incx, float *y, int incy) {
    scopy_(&n, x, &incx, y, &incy);
}
void copy(int n, double *x, int incx, double *y, int incy) {
    dcopy_(&n, x, &incx, y, &incy);
}
void copy(int n, cfloat *x, int incx, cfloat *y, int incy) {
    ccopy_(&n, x, &incx, y, &incy);
}
void copy(int n, cdouble *x, int incx, cdouble *y, int incy) {
    zcopy_(&n, x, &incx, y, &incy);
}

/// y := alpha * x + y
void axpy(int n, float alpha, float *x, int incx, float *y, int incy) {
    saxpy_(&n, &alpha, x, &incx, y, &incy);
}
void axpy(int n, double alpha, double *x, int incx, double *y, int incy) {
    daxpy_(&n, &alpha, x, &incx, y, &incy);
}
void axpy(int n, cfloat alpha, cfloat *x, int incx, cfloat *y, int incy) {
    caxpy_(&n, &alpha, x, &incx, y, &incy);
}
void axpy(int n, cdouble alpha, cdouble *x, int incx, cdouble *y, int incy) {
    zaxpy_(&n, &alpha, x, &incx, y, &incy);
}


/// ret := x.T * y
float_ret_t dot(int n, float *x, int incx, float *y, int incy) {
    return sdot_(&n, x, &incx, y, &incy);
}
double dot(int n, double *x, int incx, double *y, int incy) {
    return ddot_(&n, x, &incx, y, &incy);
}
double ddot(int n, float *sx, int incx, float *sy, int incy) {
    return dsdot_(&n, sx, &incx, sy, &incy);
}
cfloat dotu(int n, cfloat *x, int incx, cfloat *y, int incy) {
    cfloat ret_val;
    cdotu_(&ret_val, &n, x, &incx, y, &incy);
    return ret_val;
}
cdouble dotu(int n, cdouble *x, int incx, cdouble *y, int incy) {
    cdouble ret_val;
    zdotu_(&ret_val, &n, x, &incx, y, &incy);
    return ret_val;
}
//cfloat cdotu_(cfloat *ret_val, int *n, cfloat *x, int *incx, cfloat *y, int *incy);
//cdouble zdotu_(cdouble *ret_val, int *n, cdouble *x, int *incx, cdouble *y, int *incy);

/// ret := x.H * y
cfloat dotc(int n, cfloat *x, int incx, cfloat *y, int incy) {
    cfloat ret_val;
    cdotc_(&ret_val, &n, x,  &incx, y, &incy);
    return ret_val;
}
cdouble dotc(int n, cdouble *x, int incx, cdouble *y, int incy) {
    cdouble ret_val;
    zdotc_(&ret_val, &n, x, &incx, y, &incy);
    return ret_val;
}
//cfloat cdotc_(cfloat *ret_val, int *n, cfloat *x, int *incx, cfloat *y, int *incy);
//cdouble zdotc_(cdouble *ret_val, int *n, cdouble *x, int *incx, cdouble *y, int *incy);

/// ret := b + x.T * y
float_ret_t dsdot(int n, float *b, float *x, int incx, float *y, int incy) {
    return sdsdot_(&n, b, x, &incx, y, &incy);
}

/// ret := sqrt( x.T * x )
float_ret_t nrm2(int n, cfloat *x, int incx) {
    return scnrm2_(&n, x, &incx);
}
float_ret_t nrm2(int n, float *x, int incx) {
    return snrm2_(&n, x, &incx);
}
double nrm2(int n, double *x, int incx) {
    return dnrm2_(&n, x, &incx);
}
double nrm2(int n, cdouble *x, int incx) {
    return dznrm2_(&n, x, &incx);
}

/// ret := |x|_1
float_ret_t asum(int n, float *x, int incx) {
    return sasum_(&n, x, &incx);
}
double asum(int n, double *x, int incx) {
    return dasum_(&n, x, &incx);
}


/// ret := |re(x)|_1 + |im(x)|_1
float_ret_t asum(int n, cfloat *x, int incx) {
    return scasum_(&n, x, &incx);
}
double asum(int n, cdouble *x, int incx) {
    return dzasum_(&n, x, &incx);
}

/// ret := argmax(abs(x_i))
int isamax(int n, float *x, int incx) {
    return isamax_(&n, x, &incx);
}
int idamax(int n, double *x, int incx) {
    return idamax_(&n, x, &incx);
}

/// ret := argmax( abs(re(x_i))+abs(im(x_i)) )
int icamax(int n, cfloat *x, int incx) {
    return icamax_(&n, x, &incx);
}
int izamax(int n, cdouble *x, int incx) {
    return izamax_(&n, x, &incx);
}


/// Level 2 BLAS

/** matrix vector multiply
        y = alpha*A*x + beta*y
   OR   y = alpha*A.T*x + beta*y
   OR   y = alpha*A.H*x + beta*y,  with A an mxn matrix
*/
void gemv(char trans, int m, int n, float alpha, float *A, int lda, float *x, int incx, float beta, float *y, int incy) {
    sgemv_(&trans, &m, &n, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void gemv(char trans, int m, int n, double alpha, double *A, int lda, double *x, int incx, double beta, double *y, int incy) {
    dgemv_(&trans, &m, &n, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void gemv(char trans, int m, int n, cfloat alpha, cfloat *A, int lda, cfloat *x, int incx, cfloat beta, cfloat *y, int incy) {
    cgemv_(&trans, &m, &n, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void gemv(char trans, int m, int n, cdouble alpha, cdouble *A, int lda, cdouble *x, int incx, cdouble beta, cdouble *y, int incy) {
    zgemv_(&trans, &m, &n, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}

/** banded matrix vector multiply
        y = alpha*A*x   + beta*y 
    OR  y = alpha*A.T*x + beta*y
    OR  y = alpha*A.H*x + beta*y,  with A a banded mxn matrix
*/
void gbmv(char trans, int m, int n, int kl, int ku, float alpha, float *A, int lda, float *x, int incx, float beta, float *y, int incy) {
    sgbmv_(&trans, &m, &n, &kl, &ku, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void gbmv(char trans, int m, int n, int kl, int ku, double alpha, double *A, int lda, double *x, int incx, double beta, double *y, int incy) {
    dgbmv_(&trans, &m, &n, &kl, &ku, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void gbmv(char trans, int m, int n, int kl, int ku, cfloat alpha, cfloat *A, int lda, cfloat *x, int incx, cfloat beta, cfloat *y, int incy) {
    cgbmv_(&trans, &m, &n, &kl, &ku, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void gbmv(char trans, int m, int n, int kl, int ku, cdouble alpha, cdouble *A, int lda, cdouble *x, int incx, cdouble beta, cdouble *y, int incy) {
    zgbmv_(&trans, &m, &n, &kl, &ku, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}

/** hermitian matrix vector multiply
 */
void hemv(char uplo, int n, cfloat alpha, cfloat *A, int lda, cfloat *x, int incx, cfloat beta, cfloat *y, int incy) {
    chemv_(&uplo, &n, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void hemv(char uplo, int n, cdouble alpha, cdouble *A, int lda, cdouble *x, int incx, cdouble beta, cdouble *y, int incy) {
    zhemv_(&uplo, &n, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}

/// hermitian banded matrix vector multiply
void hbmv(char uplo, int n, int k, cfloat alpha, cfloat *A, int lda, cfloat *x, int incx, cfloat beta, cfloat *y, int incy) {
    chbmv_(&uplo, &n, &k, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void hbmv(char uplo, int n, int k, cdouble alpha, cdouble *A, int lda, cdouble *x, int incx, cdouble beta, cdouble *y, int incy) {
    zhbmv_(&uplo, &n, &k, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}

/// hermitian packed matrix vector multiply
void hpmv(char uplo, int n, cfloat alpha, cfloat *A, cfloat *x, int incx, cfloat beta, cfloat *y, int incy) {
    chpmv_(&uplo, &n, &alpha, A, x, &incx, &beta, y, &incy, 1);
}
void hpmv(char uplo, int n, cdouble alpha, cdouble *A, cdouble *x, int incx, cdouble beta, cdouble *y, int incy) {
    zhpmv_(&uplo, &n, &alpha, A, x, &incx, &beta, y, &incy, 1);
}

/** symmetric matrix vector multiply
    y := alpha * A * x + beta * y
 */
void symv(char uplo, int n, float alpha, float *A, int lda, float *x, int incx, float beta, float *y, int incy) {
    ssymv_(&uplo, &n, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void symv(char uplo, int n, double alpha, double *A, int lda, double *x, int incx, double beta, double *y, int incy) {
    dsymv_(&uplo, &n, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}

/** symmetric banded matrix vector multiply
    y := alpha * A * x + beta * y
 */
void sbmv(char uplo, int n, int k, float alpha, float *A, int lda, float *x, int incx, float beta, float *y, int incy) {
    ssbmv_(&uplo, &n, &k, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}
void sbmv(char uplo, int n, int k, double alpha, double *A, int lda, double *x, int incx, double beta, double *y, int incy) {
    dsbmv_(&uplo, &n, &k, &alpha, A, &lda, x, &incx, &beta, y, &incy, 1);
}

/** symmetric packed matrix vector multiply
    y := alpha * A * x + beta * y
 */
void spmv(char uplo, int n, float alpha, float *ap, float *x, int incx, float beta, float *y, int incy) {
    sspmv_(&uplo, &n, &alpha, ap, x, &incx, &beta, y, &incy, 1);
}
void spmv(char uplo, int n, double alpha, double *ap, double *x, int incx, double beta, double *y, int incy) {
    dspmv_(&uplo, &n, &alpha, ap, x, &incx, &beta, y, &incy, 1);
}

/** triangular matrix vector multiply
        x := A * x
    OR  x := A.T * x
    OR  x := A.H * x
 */
void trmv(char uplo, char trans, char diag, int n, float *A, int lda, float *x, int incx) {
    strmv_(&uplo, &trans, &diag, &n, A, &lda, x, &incx, 1, 1, 1);
}
void trmv(char uplo, char trans, char diag, int n, double *A, int lda, double *x, int incx) {
    dtrmv_(&uplo, &trans, &diag, &n, A, &lda, x, &incx, 1, 1, 1);
}
void trmv(char uplo, char trans, char diag, int n, cfloat *A, int lda, cfloat *x, int incx) {
    ctrmv_(&uplo, &trans, &diag, &n, A, &lda, x, &incx, 1, 1, 1);
}
void trmv(char uplo, char trans, char diag, int n, cdouble *A, int lda, cdouble *x, int incx) {
    ztrmv_(&uplo, &trans, &diag, &n, A, &lda, x, &incx, 1, 1, 1);
}

/** triangular banded matrix vector multiply
        x := A * x
    OR  x := A.T * x
    OR  x := A.H * x
 */
void tbmv(char uplo, char trans, char diag, int n, int k, float *A, int lda, float *x, int incx) {
    stbmv_(&uplo, &trans, &diag, &n, &k, A, &lda, x, &incx, 1, 1, 1);
}
void tbmv(char uplo, char trans, char diag, int n, int k, double *A, int lda, double *x, int incx) {
    dtbmv_(&uplo, &trans, &diag, &n, &k, A, &lda, x, &incx, 1, 1, 1);
}
void tbmv(char uplo, char trans, char diag, int n, int k, cfloat *A, int lda, cfloat *x, int incx) {
    ctbmv_(&uplo, &trans, &diag, &n, &k, A, &lda, x, &incx, 1, 1, 1);
}
void tbmv(char uplo, char trans, char diag, int n, int k, cdouble *A, int lda, cdouble *x, int incx) {
    ztbmv_(&uplo, &trans, &diag, &n, &k, A, &lda, x, &incx, 1, 1, 1);
}

/** triangular packed matrix vector multiply
        x := A * x
    OR  x := A.T * x
    OR  x := A.H * x
 */
void tpmv(char uplo, char trans, char diag, int n, float *ap, float *x, int incx) {
    stpmv_(&uplo, &trans, &diag, &n, ap, x, &incx, 1, 1, 1);
}
void tpmv(char uplo, char trans, char diag, int n, double *ap, double *x, int incx) {
    dtpmv_(&uplo, &trans, &diag, &n, ap, x, &incx, 1, 1, 1);
}
void tpmv(char uplo, char trans, char diag, int n, cfloat *ap, cfloat *x, int incx) {
    ctpmv_(&uplo, &trans, &diag, &n, ap, x, &incx, 1, 1, 1);
}
void tpmv(char uplo, char trans, char diag, int n, cdouble *ap, cdouble *x, int incx) {
    ztpmv_(&uplo, &trans, &diag, &n, ap, x, &incx, 1, 1, 1);
}

/** solving triangular matrix problems
        x := A.inv * x
    OR  x := A.inv.T * x
    OR  x := A.inv.H * x
 */
void trsv(char uplo, char trans, char diag, int n, float *A, int lda, float *x, int incx) {
    strsv_(&uplo, &trans, &diag, &n, A, &lda, x, &incx, 1, 1, 1);
}
void trsv(char uplo, char trans, char diag, int n, double *A, int lda, double *x, int incx) {
    dtrsv_(&uplo, &trans, &diag, &n, A, &lda, x, &incx, 1, 1, 1);
}
void trsv(char uplo, char trans, char diag, int n, cfloat *A, int lda, cfloat *x, int incx) {
    ctrsv_(&uplo, &trans, &diag, &n, A, &lda, x, &incx, 1, 1, 1);
}
void trsv(char uplo, char trans, char diag, int n, cdouble *A, int lda, cdouble *x, int incx) {
    ztrsv_(&uplo, &trans, &diag, &n, A, &lda, x, &incx, 1, 1, 1);
}

/** solving triangular banded matrix problems
        x := A.inv * x
    OR  x := A.inv.T * x
    OR  x := A.inv.H * x
 */
void tbsv(char uplo, char trans, char diag, int n, int k, float *A, int lda, float *x, int incx) {
    stbsv_(&uplo, &trans, &diag, &n, &k, A, &lda, x, &incx, 1, 1, 1);
}
void tbsv(char uplo, char trans, char diag, int n, int k, double *A, int lda, double *x, int incx) {
    dtbsv_(&uplo, &trans, &diag, &n, &k, A, &lda, x, &incx, 1, 1, 1);
}
void tbsv(char uplo, char trans, char diag, int n, int k, cfloat *A, int lda, cfloat *x, int incx) {
    ctbsv_(&uplo, &trans, &diag, &n, &k, A, &lda, x, &incx, 1, 1, 1);
}
void tbsv(char uplo, char trans, char diag, int n, int k, cdouble *A, int lda, cdouble *x, int incx) {
    ztbsv_(&uplo, &trans, &diag, &n, &k, A, &lda, x, &incx, 1, 1, 1);
}

/** solving triangular packed matrix problems
        x := A.inv * x
    OR  x := A.inv.T * x
    OR  x := A.inv.H * x
 */
void tpsv(char uplo, char trans, char diag, int n, float *ap, float *x, int incx) {
    stpsv_(&uplo, &trans, &diag, &n, ap, x, &incx, 1, 1, 1);
}
void tpsv(char uplo, char trans, char diag, int n, double *ap, double *x, int incx) {
    dtpsv_(&uplo, &trans, &diag, &n, ap, x, &incx, 1, 1, 1);
}
void tpsv(char uplo, char trans, char diag, int n, cfloat *ap, cfloat *x, int incx) {
    ctpsv_(&uplo, &trans, &diag, &n, ap, x, &incx, 1, 1, 1);
}
void tpsv(char uplo, char trans, char diag, int n, cdouble *ap, cdouble *x, int incx) {
    ztpsv_(&uplo, &trans, &diag, &n, ap, x, &incx, 1, 1, 1);
}

/// performs the rank 1 operation 
///    A := A + alpha*x*y.T
void ger(int m, int n, float alpha, float *x, int incx, float *y, int incy, float *A, int lda) {
    sger_(&m, &n, &alpha, x, &incx, y, &incy, A, &lda);
}
void ger(int m, int n, double alpha, double *x, int incx, double *y, int incy, double *A, int lda) {
    dger_(&m, &n, &alpha, x, &incx, y, &incy, A, &lda);
}

/// performs the rank 1 operation 
///    A := A + alpha*x*y.T
void geru(int m, int n, cfloat alpha, cfloat *x, int incx, cfloat *y, int incy, cfloat *A, int lda) {
    cgeru_(&m, &n, &alpha, x, &incx, y, &incy, A, &lda);
}
void geru(int m, int n, cdouble alpha, cdouble *x, int incx, cdouble *y, int incy, cdouble *A, int lda) {
    zgeru_(&m, &n, &alpha, x, &incx, y, &incy, A, &lda);
}

/// performs the rank 1 operation 
///    A := A + alpha*x*y.H
void gerc(int m, int n, cfloat alpha, cfloat *x, int incx, cfloat *y, int incy, cfloat *A, int lda) {
    cgerc_(&m, &n, &alpha, x, &incx, y, &incy, A, &lda);
}
void gerc(int m, int n, cdouble alpha, cdouble *x, int incx, cdouble *y, int incy, cdouble *A, int lda) {
    zgerc_(&m, &n, &alpha, x, &incx, y, &incy, A, &lda);
}

/// hermitian rank 1 operation 
///    A := A + alpha*x*x.H
void her(char uplo, int n, float alpha, cfloat *x, int incx, cfloat *A, int lda) {
    cher_(&uplo, &n, &alpha, x, &incx, A, &lda, 1);
}
void her(char uplo, int n, double alpha, cdouble *x, int incx, cdouble *A, int lda) {
    zher_(&uplo, &n, &alpha, x, &incx, A, &lda, 1);
}

/// hermitian packed rank 1 operation
///    A := A + alpha*x*x.H
void hpr(char uplo, int n, float alpha, cfloat *x, int incx, cfloat *A) {
    chpr_(&uplo, &n, &alpha, x, &incx, A, 1);
}
void hpr(char uplo, int n, double alpha, cdouble *x, int incx, cdouble *A) {
    zhpr_(&uplo, &n, &alpha, x, &incx, A, 1);
}

/// hermitian rank 2 operation
///    A := A + alpha*x*y.H + alpha.conj * y * x.H
void her2(char uplo, int n, cfloat alpha, cfloat *x, int incx, cfloat *y, int incy, cfloat *A, int lda) {
    cher2_(&uplo, &n, &alpha, x, &incx, y, &incy, A, &lda, 1);
}
void her2(char uplo, int n, cdouble alpha, cdouble *x, int incx, cdouble *y, int incy, cdouble *A, int lda) {
    zher2_(&uplo, &n, &alpha, x, &incx, y, &incy, A, &lda, 1);
}

/// hermitian packed rank 2 operation
///    A := A + alpha*x*y.H + alpha.conj * y * x.H
void hpr2(char uplo, int n, cfloat alpha, cfloat *x, int incx, cfloat *y, int incy, cfloat *A) {
    chpr2_(&uplo, &n, &alpha, x, &incx, y, &incy, A, 1);
}
void hpr2(char uplo, int n, cdouble alpha, cdouble *x, int incx, cdouble *y, int incy, cdouble *A) {
    zhpr2_(&uplo, &n, &alpha, x, &incx, y, &incy, A, 1);
}

/// performs the symmetric rank 1 operation 
///    A := A + alpha*x*x.T
void syr(char uplo, int n, float alpha, float *x, int incx, float *A, int lda) {
    ssyr_(&uplo, &n, &alpha, x, &incx, A, &lda, 1);
}
void syr(char uplo, int n, double alpha, double *x, int incx, double *A, int lda) {
    dsyr_(&uplo, &n, &alpha, x, &incx, A, &lda, 1);
}

/// symmetric packed rank 1 operation  
///    A := A + alpha*x*x.T
void spr(char uplo, int n, float alpha, float *x, int incx, float *ap) {
    sspr_(&uplo, &n, &alpha, x, &incx, ap, 1);
}
void spr(char uplo, int n, double alpha, double *x, int incx, double *ap) {
    dspr_(&uplo, &n, &alpha, x, &incx, ap, 1);
}

/// performs the symmetric rank 2 operation
///    A := A + alpha * x * y.T  +  alpha * y * x.T
void syr2(char uplo, int n, float alpha, float *x, int incx, float *y, int incy, float *A, int lda) {
    ssyr2_(&uplo, &n, &alpha, x, &incx, y, &incy, A, &lda, 1);
}
void syr2(char uplo, int n, double alpha, double *x, int incx, double *y, int incy, double *A, int lda) {
    dsyr2_(&uplo, &n, &alpha, x, &incx, y, &incy, A, &lda, 1);
}

/// performs the symmetric packed rank 2 operation
///    A := A + alpha*x*y.T + alpha*y*x.T
void spr2(char uplo, int n, float alpha, float *x, int incx, float *y, int incy, float *ap) {
    sspr2_(&uplo, &n, &alpha, x, &incx, y, &incy, ap, 1);
}
void spr2(char uplo, int n, double alpha, double *x, int incx, double *y, int incy, double *ap) {
    dspr2_(&uplo, &n, &alpha, x, &incx, y, &incy, ap, 1);
}


/// Level 3 BLAS

/// matrix matrix multiply
///     C := alpha * transa(A) * transb(B) + beta * C
void gemm(char transa, char transb, int m, int n, int k, float alpha, float *A, int lda, float *B, int ldb, float beta, float *C, int ldc) {
    sgemm_(&transa, &transb, &m, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void gemm(char transa, char transb, int m, int n, int k, double alpha, double *A, int lda, double *B, int ldb, double beta, double *C, int ldc) {
    dgemm_(&transa, &transb, &m, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void gemm(char transa, char transb, int m, int n, int k, cfloat alpha, cfloat *A, int lda, cfloat *B, int ldb, cfloat beta, cfloat *C, int ldc) {
    cgemm_(&transa, &transb, &m, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void gemm(char transa, char transb, int m, int n, int k, cdouble alpha, cdouble *A, int lda, cdouble *B, int ldb, cdouble beta, cdouble *C, int ldc) {
    zgemm_(&transa, &transb, &m, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}

/// symmetric matrix matrix multiply
///     C := alpha * A * B + beta * C
/// OR  C := alpha * B * A + beta * C,    where A == A.T
void symm(char side, char uplo, int m, int n, float alpha, float *A, int lda, float *B, int ldb, float beta, float *C, int ldc) {
    ssymm_(&side, &uplo, &m, &n, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void symm(char side, char uplo, int m, int n, double alpha, double *A, int lda, double *B, int ldb, double beta, double *C, int ldc) {
    dsymm_(&side, &uplo, &m, &n, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void symm(char side, char uplo, int m, int n, cfloat alpha, cfloat *A, int lda, cfloat *B, int ldb, cfloat beta, cfloat *C, int ldc) {
    csymm_(&side, &uplo, &m, &n, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void symm(char side, char uplo, int m, int n, cdouble alpha, cdouble *A, int lda, cdouble *B, int ldb, cdouble beta, cdouble *C, int ldc) {
    zsymm_(&side, &uplo, &m, &n, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}

/// hermitian matrix matrix multiply
///     C := alpha * A * B + beta * C
/// OR  C := alpha * B * A + beta * C,    where A == A.H
void hemm(char side, char uplo, int m, int n, cfloat alpha, cfloat *A, int lda, cfloat *B, int ldb, cfloat beta, cfloat *C, int ldc) {
    chemm_(&side, &uplo, &m, &n, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void hemm(char side, char uplo, int m, int n, cdouble alpha, cdouble *A, int lda, cdouble *B, int ldb, cdouble beta, cdouble *C, int ldc) {
    zhemm_(&side, &uplo, &m, &n, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}

/// symmetric rank-k update to a matrix
///     C := alpha * A * A.T + beta * C
/// OR  C := alpha * A.T * A + beta * C
void syrk(char uplo, char trans, int n, int k, float alpha, float *A, int lda, float beta, float *C, int ldc) {
    ssyrk_(&uplo, &trans, &n, &k, &alpha, A, &lda, &beta, C, &ldc, 1, 1);
}
void syrk(char uplo, char trans, int n, int k, double alpha, double *A, int lda, double beta, double *C, int ldc) {
    dsyrk_(&uplo, &trans, &n, &k, &alpha, A, &lda, &beta, C, &ldc, 1, 1);
}
void syrk(char uplo, char trans, int n, int k, cfloat alpha, cfloat *A, int lda, cfloat beta, cfloat *C, int ldc) {
    csyrk_(&uplo, &trans, &n, &k, &alpha, A, &lda, &beta, C, &ldc, 1, 1);
}
void syrk(char uplo, char trans, int n, int k, cdouble alpha, cdouble *A, int lda, cdouble beta, cdouble *C, int ldc) {
    zsyrk_(&uplo, &trans, &n, &k, &alpha, A, &lda, &beta, C, &ldc, 1, 1);
}

/// hermitian rank-k update to a matrix
///     C := alpha * A * A.H + beta * C
/// OR  C := alpha * A.H * A + beta * C
void herk(char uplo, char trans, int n, int k, float alpha, cfloat *A, int lda, float beta, cfloat *C, int ldc) {
    cherk_(&uplo, &trans, &n, &k, &alpha, A, &lda, &beta, C, &ldc, 1, 1);
}
void herk(char uplo, char trans, int n, int k, double alpha, cdouble *A, int lda, double beta, cdouble *C, int ldc) {
    zherk_(&uplo, &trans, &n, &k, &alpha, A, &lda, &beta, C, &ldc, 1, 1);
}

/// symmetric rank-2k update to a matrix
///     C := alpha * A * B.T + alpha.conj * B * A.T + beta * C
/// OR  C := alpha * A.T * B + alpha.conj * B.T * A + beta * C
void syr2k(char uplo, char trans, int n, int k, float alpha, float *A, int lda, float *B, int ldb, float beta, float *C, int ldc) {
    ssyr2k_(&uplo, &trans, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void syr2k(char uplo, char trans, int n, int k, double alpha, double *A, int lda, double *B, int ldb, double beta, double *C, int ldc) {
    dsyr2k_(&uplo, &trans, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void syr2k(char uplo, char trans, int n, int k, cfloat alpha, cfloat *A, int lda, cfloat *B, int ldb, cfloat beta, cfloat *C, int ldc) {
    csyr2k_(&uplo, &trans, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void syr2k(char uplo, char trans, int n, int k, cdouble alpha, cdouble *A, int lda, cdouble *B, int ldb, cdouble beta, cdouble *C, int ldc) {
    zsyr2k_(&uplo, &trans, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}

/// hermitian rank-2k update to a matrix
///     C := alpha * A * B.H + alpha.conj * B * A.H + beta * C
/// OR  C := alpha * A.H * B + alpha.conj * B.H * A + beta * C
void her2k(char uplo, char trans, int n, int k, cfloat alpha, cfloat *A, int lda, cfloat *B, int ldb, float beta, cfloat *C, int ldc) {
    cher2k_(&uplo, &trans, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}
void her2k(char uplo, char trans, int n, int k, cdouble alpha, cdouble *A, int lda, cdouble *B, int ldb, double beta, cdouble *C, int ldc) {
    zher2k_(&uplo, &trans, &n, &k, &alpha, A, &lda, B, &ldb, &beta, C, &ldc, 1, 1);
}

/// triangular matrix matrix multiply
///     B := alpha * transa(A) * B
/// OR  B := alpha * B * transa(A)
void trmm(char side, char uplo, char transa, char diag, int m, int n, float alpha, float *A, int lda, float *B, int ldb) {
    strmm_(&side, &uplo, &transa, &diag, &m, &n, &alpha, A, &lda, B, &ldb, 1, 1, 1, 1);
}
void trmm(char side, char uplo, char transa, char diag, int m, int n, double alpha, double *A, int lda, double *B, int ldb) {
    dtrmm_(&side, &uplo, &transa, &diag, &m, &n, &alpha, A, &lda, B, &ldb, 1, 1, 1, 1);
}
void trmm(char side, char uplo, char transa, char diag, int m, int n, cfloat alpha, cfloat *A, int lda, cfloat *B, int ldb) {
    ctrmm_(&side, &uplo, &transa, &diag, &m, &n, &alpha, A, &lda, B, &ldb, 1, 1, 1, 1);
}
void trmm(char side, char uplo, char transa, char diag, int m, int n, cdouble alpha, cdouble *A, int lda, cdouble *B, int ldb) {
    ztrmm_(&side, &uplo, &transa, &diag, &m, &n, &alpha, A, &lda, B, &ldb, 1, 1, 1, 1);
}

/// solving triangular matrix with multiple right hand sides
///     B := alpha * transa(A.inv) * B
/// OR  B := alpha * B * transa(A.inv)
void trsm(char side, char uplo, char transa, char diag, int m, int n, float alpha, float *A, int lda, float *B, int ldb) {
    strsm_(&side, &uplo, &transa, &diag, &m, &n, &alpha, A, &lda, B, &ldb, 1, 1, 1, 1);
}
void trsm(char side, char uplo, char transa, char diag, int m, int n, double alpha, double *A, int lda, double *B, int ldb) {
    dtrsm_(&side, &uplo, &transa, &diag, &m, &n, &alpha, A, &lda, B, &ldb, 1, 1, 1, 1);
}
void trsm(char side, char uplo, char transa, char diag, int m, int n, cfloat alpha, cfloat *A, int lda, cfloat *B, int ldb) {
    ctrsm_(&side, &uplo, &transa, &diag, &m, &n, &alpha, A, &lda, B, &ldb, 1, 1, 1, 1);
}
void trsm(char side, char uplo, char transa, char diag, int m, int n, cdouble alpha, cdouble *A, int lda, cdouble *B, int ldb) {
    ztrsm_(&side, &uplo, &transa, &diag, &m, &n, &alpha, A, &lda, B, &ldb, 1, 1, 1, 1);
}

/// Test if the characters are equal. (Auxiliary routine in Level 2 and 3 BLAS routines)
// void lsame_() [no D interface]

/// Computes absolute values of a cdouble number. (Auxiliary routine for a few Level 1 BLAS routines)
// void dcabs1_() [no D interface]

/// Error handler for level 2 and 3 BLAS routines
// void xerbla_() [no D interface]

