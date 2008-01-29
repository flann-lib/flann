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

module blas;

// For a good description of issues calling Fortran from C see
//    http://www.math.utah.edu/software/c-with-fortran.html
// Namely the wierdness with char* arguments and complex return types.

version(Windows) {
    pragma(lib, "blaslapackdll.lib");
}

// Prototypes for the raw Fortran interface to BLAS
extern(C):

version (FORTRAN_FLOAT_FUNCTIONS_RETURN_DOUBLE) {
    alias double float_ret_t;
} else {
    alias float float_ret_t;
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
void srotg_(float *a, float *b, float *c, float *s);
void drotg_(double *a, double *b, double *c, double *s);
void crotg_(cfloat *a, cfloat *b, float *c, cfloat *s);
void zrotg_(cdouble *a, cdouble *b, double *c, cdouble *s);

/// Generate modified plane (Givens) rotation
void drotmg_(double *d1, double *d2, double *b1, double *b2, double *param);
void srotmg_(float *d1, float *d2, float *b1, float *b2, float *param);

/// Apply plane (Givens) rotation
///             _      _
///     x_i  := | c  s | * x_i
///     y_i     |-s  c |   y_i
///             -      -
void srot_(int *n, float *x, int *incx, float *y, int *incy, float *c, float *s);
void drot_(int *n, double *x, int *incx, double *y, int *incy, double *c, double *s);
void csrot_(int *n, cfloat *x, int *incx, cfloat *y, int *incy, float *c, float *s);
void zdrot_(int *n, cdouble *x, int *incx, cdouble *y, int *incy, double *c, double *s);

/// Apply modified plane (Givens) rotation
void srotm_(int *n, float *x, int *incx, float *y, int *incy, float *param);
void drotm_(int *n, double *x, int *incx, double *y, int *incy, double *param);

/// Swap the values contained in x and y 
///     x <-> y
void sswap_(int *n, float *x, int *incx, float *y, int *incy);
void dswap_(int *n, double *x, int *incx, double *y, int *incy);
void cswap_(int *n, cfloat *x, int *incx, cfloat *y, int *incy);
void zswap_(int *n, cdouble *x, int *incx, cdouble *y, int *incy);

/// x := alpha * x
void sscal_(int *n, float *alpha, float *x, int *incx);
void dscal_(int *n, double *alpha, double *x, int *incx);
void cscal_(int *n, cfloat *alpha, cfloat *x, int *incx);
void csscal_(int *n, float *alpha, cfloat *x, int *incx);
void zscal_(int *n, cdouble *alpha, cdouble *x, int *incx);
void zdscal_(int *n, double *alpha, cdouble *x, int *incx);

/// y := x
void scopy_(int *n, float *x, int *incx, float *y, int *incy);
void dcopy_(int *n, double *x, int *incx, double *y, int *incy);
void ccopy_(int *n, cfloat *x, int *incx, cfloat *y, int *incy);
void zcopy_(int *n, cdouble *x, int *incx, cdouble *y, int *incy);

/// y := alpha * x + y
void saxpy_(int *n, float *alpha, float *x, int *incx, float *y, int *incy);
void daxpy_(int *n, double *alpha, double *x, int *incx, double *y, int *incy);
void caxpy_(int *n, cfloat *alpha, cfloat *x, int *incx, cfloat *y, int *incy);
void zaxpy_(int *n, cdouble *alpha, cdouble *x, int *incx, cdouble *y, int *incy);


/// ret := x.T * y
float_ret_t sdot_(int *n, float *x, int *incx, float *y, int *incy);
double ddot_(int *n, double *x, int *incx, double *y, int *incy);
double dsdot_(int *n, float *sx, int *incx, float *sy, int *incy);
void cdotu_(cfloat *ret_val, int *n, cfloat *x, int *incx, cfloat *y, int *incy);
void zdotu_(cdouble *ret_val, int *n, cdouble *x, int *incx, cdouble *y, int *incy);
//cfloat cdotu_(cfloat *ret_val, int *n, cfloat *x, int *incx, cfloat *y, int *incy);
//cdouble zdotu_(cdouble *ret_val, int *n, cdouble *x, int *incx, cdouble *y, int *incy);

/// ret := x.H * y
void cdotc_(cfloat *ret_val, int *n, cfloat *x, int *incx, cfloat *y, int *incy);
void zdotc_(cdouble *ret_val, int *n, cdouble *x, int *incx, cdouble *y, int *incy);
//cfloat cdotc_(cfloat *ret_val, int *n, cfloat *x, int *incx, cfloat *y, int *incy);
//cdouble zdotc_(cdouble *ret_val, int *n, cdouble *x, int *incx, cdouble *y, int *incy);

/// ret := b + x.T * y
float_ret_t sdsdot_(int *n, float *b, float *x, int *incx, float *y, int *incy);

/// ret := sqrt( x.T * x )
float_ret_t scnrm2_(int *n, cfloat *x, int *incx);
float_ret_t snrm2_(int *n, float *x, int *incx);
double dnrm2_(int *n, double *x, int *incx);
double dznrm2_(int *n, cdouble *x, int *incx);

/// ret := |x|_1
float_ret_t sasum_(int *n, float *x, int *incx);
double dasum_(int *n, double *x, int *incx);


/// ret := |re(x)|_1 + |im(x)|_1
float_ret_t scasum_(int *n, cfloat *x, int *incx);
double dzasum_(int *n, cdouble *x, int *incx);

/// ret := argmax(abs(x_i))
int isamax_(int *n, float *x, int *incx);
int idamax_(int *n, double *x, int *incx);

/// ret := argmax( abs(re(x_i))+abs(im(x_i)) )
int icamax_(int *n, cfloat *x, int *incx);
int izamax_(int *n, cdouble *x, int *incx);


/// Level 2 BLAS

/** matrix vector multiply
        y = alpha*A*x + beta*y
   OR   y = alpha*A.T*x + beta*y
   OR   y = alpha*A.H*x + beta*y,  with A an mxn matrix
*/
void sgemv_(char *trans, int *m, int *n, float *alpha, float *A, int *lda, float *x, int *incx, float *beta, float *y, int *incy, int trans_len);
void dgemv_(char *trans, int *m, int *n, double *alpha, double *A, int *lda, double *x, int *incx, double *beta, double *y, int *incy, int trans_len);
void cgemv_(char *trans, int *m, int *n, cfloat *alpha, cfloat *A, int *lda, cfloat *x, int *incx, cfloat *beta, cfloat *y, int *incy, int trans_len);
void zgemv_(char *trans, int *m, int *n, cdouble *alpha, cdouble *A, int *lda, cdouble *x, int *incx, cdouble *beta, cdouble *y, int *incy, int trans_len);

/** banded matrix vector multiply
        y = alpha*A*x   + beta*y 
    OR  y = alpha*A.T*x + beta*y
    OR  y = alpha*A.H*x + beta*y,  with A a banded mxn matrix
*/
void sgbmv_(char *trans, int *m, int *n, int *kl, int *ku, float *alpha, float *A, int *lda, float *x, int *incx, float *beta, float *y, int *incy, int trans_len);
void dgbmv_(char *trans, int *m, int *n, int *kl, int *ku, double *alpha, double *A, int *lda, double *x, int *incx, double *beta, double *y, int *incy, int trans_len);
void cgbmv_(char *trans, int *m, int *n, int *kl, int *ku, cfloat *alpha, cfloat *A, int *lda, cfloat *x, int *incx, cfloat *beta, cfloat *y, int *incy, int trans_len);
void zgbmv_(char *trans, int *m, int *n, int *kl, int *ku, cdouble *alpha, cdouble *A, int *lda, cdouble *x, int *incx, cdouble *beta, cdouble *y, int *incy, int trans_len);

/** hermitian matrix vector multiply
 */
void chemv_(char *uplo, int *n, cfloat *alpha, cfloat *A, int *lda, cfloat *x, int *incx, cfloat *beta, cfloat *y, int *incy, int uplo_len);
void zhemv_(char *uplo, int *n, cdouble *alpha, cdouble *A, int *lda, cdouble *x, int *incx, cdouble *beta, cdouble *y, int *incy, int uplo_len);

/// hermitian banded matrix vector multiply
void chbmv_(char *uplo, int *n, int *k, cfloat *alpha, cfloat *A, int *lda, cfloat *x, int *incx, cfloat *beta, cfloat *y, int *incy, int uplo_len);
void zhbmv_(char *uplo, int *n, int *k, cdouble *alpha, cdouble *A, int *lda, cdouble *x, int *incx, cdouble *beta, cdouble *y, int *incy, int uplo_len);

/// hermitian packed matrix vector multiply
void chpmv_(char *uplo, int *n, cfloat *alpha, cfloat *A, cfloat *x, int *incx, cfloat *beta, cfloat *y, int *incy, int uplo_len);
void zhpmv_(char *uplo, int *n, cdouble *alpha, cdouble *A, cdouble *x, int *incx, cdouble *beta, cdouble *y, int *incy, int uplo_len);

/** symmetric matrix vector multiply
    y := alpha * A * x + beta * y
 */
void ssymv_(char *uplo, int *n, float *alpha, float *A, int *lda, float *x, int *incx, float *beta, float *y, int *incy, int uplo_len);
void dsymv_(char *uplo, int *n, double *alpha, double *A, int *lda, double *x, int *incx, double *beta, double *y, int *incy, int uplo_len);

/** symmetric banded matrix vector multiply
    y := alpha * A * x + beta * y
 */
void ssbmv_(char *uplo, int *n, int *k, float *alpha, float *A, int *lda, float *x, int *incx, float *beta, float *y, int *incy, int uplo_len);
void dsbmv_(char *uplo, int *n, int *k, double *alpha, double *A, int *lda, double *x, int *incx, double *beta, double *y, int *incy, int uplo_len);

/** symmetric packed matrix vector multiply
    y := alpha * A * x + beta * y
 */
void sspmv_(char *uplo, int *n, float *alpha, float *ap, float *x, int *incx, float *beta, float *y, int *incy, int uplo_len);
void dspmv_(char *uplo, int *n, double *alpha, double *ap, double *x, int *incx, double *beta, double *y, int *incy, int uplo_len);

/** triangular matrix vector multiply
        x := A * x
    OR  x := A.T * x
    OR  x := A.H * x
 */
void strmv_(char *uplo, char *trans, char *diag, int *n, float *A, int *lda, float *x, int *incx, int uplo_len, int trans_len, int diag_len);
void dtrmv_(char *uplo, char *trans, char *diag, int *n, double *A, int *lda, double *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ctrmv_(char *uplo, char *trans, char *diag, int *n, cfloat *A, int *lda, cfloat *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ztrmv_(char *uplo, char *trans, char *diag, int *n, cdouble *A, int *lda, cdouble *x, int *incx, int uplo_len, int trans_len, int diag_len);

/** triangular banded matrix vector multiply
        x := A * x
    OR  x := A.T * x
    OR  x := A.H * x
 */
void stbmv_(char *uplo, char *trans, char *diag, int *n, int *k, float *A, int *lda, float *x, int *incx, int uplo_len, int trans_len, int diag_len);
void dtbmv_(char *uplo, char *trans, char *diag, int *n, int *k, double *A, int *lda, double *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ctbmv_(char *uplo, char *trans, char *diag, int *n, int *k, cfloat *A, int *lda, cfloat *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ztbmv_(char *uplo, char *trans, char *diag, int *n, int *k, cdouble *A, int *lda, cdouble *x, int *incx, int uplo_len, int trans_len, int diag_len);

/** triangular packed matrix vector multiply
        x := A * x
    OR  x := A.T * x
    OR  x := A.H * x
 */
void stpmv_(char *uplo, char *trans, char *diag, int *n, float *ap, float *x, int *incx, int uplo_len, int trans_len, int diag_len);
void dtpmv_(char *uplo, char *trans, char *diag, int *n, double *ap, double *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ctpmv_(char *uplo, char *trans, char *diag, int *n, cfloat *ap, cfloat *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ztpmv_(char *uplo, char *trans, char *diag, int *n, cdouble *ap, cdouble *x, int *incx, int uplo_len, int trans_len, int diag_len);

/** solving triangular matrix problems
        x := A.inv * x
    OR  x := A.inv.T * x
    OR  x := A.inv.H * x
 */
void strsv_(char *uplo, char *trans, char *diag, int *n, float *A, int *lda, float *x, int *incx, int uplo_len, int trans_len, int diag_len);
void dtrsv_(char *uplo, char *trans, char *diag, int *n, double *A, int *lda, double *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ctrsv_(char *uplo, char *trans, char *diag, int *n, cfloat *A, int *lda, cfloat *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ztrsv_(char *uplo, char *trans, char *diag, int *n, cdouble *A, int *lda, cdouble *x, int *incx, int uplo_len, int trans_len, int diag_len);

/** solving triangular banded matrix problems
        x := A.inv * x
    OR  x := A.inv.T * x
    OR  x := A.inv.H * x
 */
void stbsv_(char *uplo, char *trans, char *diag, int *n, int *k, float *A, int *lda, float *x, int *incx, int uplo_len, int trans_len, int diag_len);
void dtbsv_(char *uplo, char *trans, char *diag, int *n, int *k, double *A, int *lda, double *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ctbsv_(char *uplo, char *trans, char *diag, int *n, int *k, cfloat *A, int *lda, cfloat *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ztbsv_(char *uplo, char *trans, char *diag, int *n, int *k, cdouble *A, int *lda, cdouble *x, int *incx, int uplo_len, int trans_len, int diag_len);

/** solving triangular packed matrix problems
        x := A.inv * x
    OR  x := A.inv.T * x
    OR  x := A.inv.H * x
 */
void stpsv_(char *uplo, char *trans, char *diag, int *n, float *ap, float *x, int *incx, int uplo_len, int trans_len, int diag_len);
void dtpsv_(char *uplo, char *trans, char *diag, int *n, double *ap, double *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ctpsv_(char *uplo, char *trans, char *diag, int *n, cfloat *ap, cfloat *x, int *incx, int uplo_len, int trans_len, int diag_len);
void ztpsv_(char *uplo, char *trans, char *diag, int *n, cdouble *ap, cdouble *x, int *incx, int uplo_len, int trans_len, int diag_len);

/// performs the rank 1 operation 
///    A := A + alpha*x*y.T
void sger_(int *m, int *n, float *alpha, float *x, int *incx, float *y, int *incy, float *A, int *lda);
void dger_(int *m, int *n, double *alpha, double *x, int *incx, double *y, int *incy, double *A, int *lda);

/// performs the rank 1 operation 
///    A := A + alpha*x*y.T
void cgeru_(int *m, int *n, cfloat *alpha, cfloat *x, int *incx, cfloat *y, int *incy, cfloat *A, int *lda);
void zgeru_(int *m, int *n, cdouble *alpha, cdouble *x, int *incx, cdouble *y, int *incy, cdouble *A, int *lda);

/// performs the rank 1 operation 
///    A := A + alpha*x*y.H
void cgerc_(int *m, int *n, cfloat *alpha, cfloat *x, int *incx, cfloat *y, int *incy, cfloat *A, int *lda);
void zgerc_(int *m, int *n, cdouble *alpha, cdouble *x, int *incx, cdouble *y, int *incy, cdouble *A, int *lda);

/// hermitian rank 1 operation 
///    A := A + alpha*x*x.H
void cher_(char *uplo, int *n, float *alpha, cfloat *x, int *incx, cfloat *A, int *lda, int uplo_len);
void zher_(char *uplo, int *n, double *alpha, cdouble *x, int *incx, cdouble *A, int *lda, int uplo_len);

/// hermitian packed rank 1 operation
///    A := A + alpha*x*x.H
void chpr_(char *uplo, int *n, float *alpha, cfloat *x, int *incx, cfloat *A, int uplo_len);
void zhpr_(char *uplo, int *n, double *alpha, cdouble *x, int *incx, cdouble *A, int uplo_len);

/// hermitian rank 2 operation
///    A := A + alpha*x*y.H + alpha.conj * y * x.H
void cher2_(char *uplo, int *n, cfloat *alpha, cfloat *x, int *incx, cfloat *y, int *incy, cfloat *A, int *lda, int uplo_len);
void zher2_(char *uplo, int *n, cdouble *alpha, cdouble *x, int *incx, cdouble *y, int *incy, cdouble *A, int *lda, int uplo_len);

/// hermitian packed rank 2 operation
///    A := A + alpha*x*y.H + alpha.conj * y * x.H
void chpr2_(char *uplo, int *n, cfloat *alpha, cfloat *x, int *incx, cfloat *y, int *incy, cfloat *A, int uplo_len);
void zhpr2_(char *uplo, int *n, cdouble *alpha, cdouble *x, int *incx, cdouble *y, int *incy, cdouble *A, int uplo_len);

/// performs the symmetric rank 1 operation 
///    A := A + alpha*x*x.T
void ssyr_(char *uplo, int *n, float *alpha, float *x, int *incx, float *A, int *lda, int uplo_len);
void dsyr_(char *uplo, int *n, double *alpha, double *x, int *incx, double *A, int *lda, int uplo_len);

/// symmetric packed rank 1 operation  
///    A := A + alpha*x*x.T
void sspr_(char *uplo, int *n, float *alpha, float *x, int *incx, float *ap, int uplo_len);
void dspr_(char *uplo, int *n, double *alpha, double *x, int *incx, double *ap, int uplo_len);

/// performs the symmetric rank 2 operation
///    A := A + alpha * x * y.T  +  alpha * y * x.T
void ssyr2_(char *uplo, int *n, float *alpha, float *x, int *incx, float *y, int *incy, float *A, int *lda, int uplo_len);
void dsyr2_(char *uplo, int *n, double *alpha, double *x, int *incx, double *y, int *incy, double *A, int *lda, int uplo_len);

/// performs the symmetric packed rank 2 operation
///    A := A + alpha*x*y.T + alpha*y*x.T
void sspr2_(char *uplo, int *n, float *alpha, float *x, int *incx, float *y, int *incy, float *ap, int uplo_len);
void dspr2_(char *uplo, int *n, double *alpha, double *x, int *incx, double *y, int *incy, double *ap, int uplo_len);


/// Level 3 BLAS

/// matrix matrix multiply
///     C := alpha * transa(A) * transb(B) + beta * C
void sgemm_(char *transa, char *transb, int *m, int *n, int *k, float *alpha, float *A, int *lda, float *B, int *ldb, float *beta, float *C, int *ldc, int transa_len, int transb_len);
void dgemm_(char *transa, char *transb, int *m, int *n, int *k, double *alpha, double *A, int *lda, double *B, int *ldb, double *beta, double *C, int *ldc, int transa_len, int transb_len);
void cgemm_(char *transa, char *transb, int *m, int *n, int *k, cfloat *alpha, cfloat *A, int *lda, cfloat *B, int *ldb, cfloat *beta, cfloat *C, int *ldc, int transa_len, int transb_len);
void zgemm_(char *transa, char *transb, int *m, int *n, int *k, cdouble *alpha, cdouble *A, int *lda, cdouble *B, int *ldb, cdouble *beta, cdouble *C, int *ldc, int transa_len, int transb_len);

/// symmetric matrix matrix multiply
///     C := alpha * A * B + beta * C
/// OR  C := alpha * B * A + beta * C,    where A == A.T
void ssymm_(char *side, char *uplo, int *m, int *n, float *alpha, float *A, int *lda, float *B, int *ldb, float *beta, float *C, int *ldc, int side_len, int uplo_len);
void dsymm_(char *side, char *uplo, int *m, int *n, double *alpha, double *A, int *lda, double *B, int *ldb, double *beta, double *C, int *ldc, int side_len, int uplo_len);
void csymm_(char *side, char *uplo, int *m, int *n, cfloat *alpha, cfloat *A, int *lda, cfloat *B, int *ldb, cfloat *beta, cfloat *C, int *ldc, int side_len, int uplo_len);
void zsymm_(char *side, char *uplo, int *m, int *n, cdouble *alpha, cdouble *A, int *lda, cdouble *B, int *ldb, cdouble *beta, cdouble *C, int *ldc, int side_len, int uplo_len);

/// hermitian matrix matrix multiply
///     C := alpha * A * B + beta * C
/// OR  C := alpha * B * A + beta * C,    where A == A.H
void chemm_(char *side, char *uplo, int *m, int *n, cfloat *alpha, cfloat *A, int *lda, cfloat *B, int *ldb, cfloat *beta, cfloat *C, int *ldc, int side_len, int uplo_len);
void zhemm_(char *side, char *uplo, int *m, int *n, cdouble *alpha, cdouble *A, int *lda, cdouble *B, int *ldb, cdouble *beta, cdouble *C, int *ldc, int side_len, int uplo_len);

/// symmetric rank-k update to a matrix
///     C := alpha * A * A.T + beta * C
/// OR  C := alpha * A.T * A + beta * C
void ssyrk_(char *uplo, char *trans, int *n, int *k, float *alpha, float *A, int *lda, float *beta, float *C, int *ldc, int uplo_len, int trans_len);
void dsyrk_(char *uplo, char *trans, int *n, int *k, double *alpha, double *A, int *lda, double *beta, double *C, int *ldc, int uplo_len, int trans_len);
void csyrk_(char *uplo, char *trans, int *n, int *k, cfloat *alpha, cfloat *A, int *lda, cfloat *beta, cfloat *C, int *ldc, int uplo_len, int trans_len);
void zsyrk_(char *uplo, char *trans, int *n, int *k, cdouble *alpha, cdouble *A, int *lda, cdouble *beta, cdouble *C, int *ldc, int uplo_len, int trans_len);

/// hermitian rank-k update to a matrix
///     C := alpha * A * A.H + beta * C
/// OR  C := alpha * A.H * A + beta * C
void cherk_(char *uplo, char *trans, int *n, int *k, float *alpha, cfloat *A, int *lda, float *beta, cfloat *C, int *ldc, int uplo_len, int trans_len);
void zherk_(char *uplo, char *trans, int *n, int *k, double *alpha, cdouble *A, int *lda, double *beta, cdouble *C, int *ldc, int uplo_len, int trans_len);

/// symmetric rank-2k update to a matrix
///     C := alpha * A * B.T + alpha.conj * B * A.T + beta * C
/// OR  C := alpha * A.T * B + alpha.conj * B.T * A + beta * C
void ssyr2k_(char *uplo, char *trans, int *n, int *k, float *alpha, float *A, int *lda, float *B, int *ldb, float *beta, float *C, int *ldc, int uplo_len, int trans_len);
void dsyr2k_(char *uplo, char *trans, int *n, int *k, double *alpha, double *A, int *lda, double *B, int *ldb, double *beta, double *C, int *ldc, int uplo_len, int trans_len);
void csyr2k_(char *uplo, char *trans, int *n, int *k, cfloat *alpha, cfloat *A, int *lda, cfloat *B, int *ldb, cfloat *beta, cfloat *C, int *ldc, int uplo_len, int trans_len);
void zsyr2k_(char *uplo, char *trans, int *n, int *k, cdouble *alpha, cdouble *A, int *lda, cdouble *B, int *ldb, cdouble *beta, cdouble *C, int *ldc, int uplo_len, int trans_len);

/// hermitian rank-2k update to a matrix
///     C := alpha * A * B.H + alpha.conj * B * A.H + beta * C
/// OR  C := alpha * A.H * B + alpha.conj * B.H * A + beta * C
void cher2k_(char *uplo, char *trans, int *n, int *k, cfloat *alpha, cfloat *A, int *lda, cfloat *B, int *ldb, float *beta, cfloat *C, int *ldc, int uplo_len, int trans_len);
void zher2k_(char *uplo, char *trans, int *n, int *k, cdouble *alpha, cdouble *A, int *lda, cdouble *B, int *ldb, double *beta, cdouble *C, int *ldc, int uplo_len, int trans_len);

/// triangular matrix matrix multiply
///     B := alpha * transa(A) * B
/// OR  B := alpha * B * transa(A)
void strmm_(char *side, char *uplo, char *transa, char *diag, int *m, int *n, float *alpha, float *A, int *lda, float *B, int *ldb, int side_len, int uplo_len, int transa_len, int diag_len);
void dtrmm_(char *side, char *uplo, char *transa, char *diag, int *m, int *n, double *alpha, double *A, int *lda, double *B, int *ldb, int side_len, int uplo_len, int transa_len, int diag_len);
void ctrmm_(char *side, char *uplo, char *transa, char *diag, int *m, int *n, cfloat *alpha, cfloat *A, int *lda, cfloat *B, int *ldb, int side_len, int uplo_len, int transa_len, int diag_len);
void ztrmm_(char *side, char *uplo, char *transa, char *diag, int *m, int *n, cdouble *alpha, cdouble *A, int *lda, cdouble *B, int *ldb, int side_len, int uplo_len, int transa_len, int diag_len);

/// solving triangular matrix with multiple right hand sides
///     B := alpha * transa(A.inv) * B
/// OR  B := alpha * B * transa(A.inv)
void strsm_(char *side, char *uplo, char *transa, char *diag, int *m, int *n, float *alpha, float *A, int *lda, float *B, int *ldb, int side_len, int uplo_len, int transa_len, int diag_len);
void dtrsm_(char *side, char *uplo, char *transa, char *diag, int *m, int *n, double *alpha, double *A, int *lda, double *B, int *ldb, int side_len, int uplo_len, int transa_len, int diag_len);
void ctrsm_(char *side, char *uplo, char *transa, char *diag, int *m, int *n, cfloat *alpha, cfloat *A, int *lda, cfloat *B, int *ldb, int side_len, int uplo_len, int transa_len, int diag_len);
void ztrsm_(char *side, char *uplo, char *transa, char *diag, int *m, int *n, cdouble *alpha, cdouble *A, int *lda, cdouble *B, int *ldb, int side_len, int uplo_len, int transa_len, int diag_len);

/// Test if the characters are equal. (Auxiliary routine in Level 2 and 3 BLAS routines)
int lsame_(char *ca, char *cb, int ca_len, int cb_len);

/// Computes absolute values of a cdouble number. (Auxiliary routine for a few Level 1 BLAS routines)
double dcabs1_(cdouble *z);

/// Error handler for level 2 and 3 BLAS routines
void xerbla_(char *srname, int *info, int srname_len);

