/**
 * D header file for C99.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly, Walter Bright
 * Standards: ISO/IEC 9899:1999 (E)
 */
module tango.stdc.tgmath;

private import tango.stdc.config;
private static import tango.stdc.math;
private static import tango.stdc.complex;

extern (C):

alias tango.stdc.math.acos          acos;
alias tango.stdc.math.acosf         acos;
alias tango.stdc.math.acosl         acos;

alias tango.stdc.complex.cacos      acos;
alias tango.stdc.complex.cacosf     acos;
alias tango.stdc.complex.cacosl     acos;

alias tango.stdc.math.asin          asin;
alias tango.stdc.math.asinf         asin;
alias tango.stdc.math.asinl         asin;

alias tango.stdc.complex.casin      asin;
alias tango.stdc.complex.casinf     asin;
alias tango.stdc.complex.casinl     asin;

alias tango.stdc.math.atan          atan;
alias tango.stdc.math.atanf         atan;
alias tango.stdc.math.atanl         atan;

alias tango.stdc.complex.catan      atan;
alias tango.stdc.complex.catanf     atan;
alias tango.stdc.complex.catanl     atan;

alias tango.stdc.math.atan2         atan2;
alias tango.stdc.math.atan2f        atan2;
alias tango.stdc.math.atan2l        atan2;

alias tango.stdc.math.cos           cos;
alias tango.stdc.math.cosf          cos;
alias tango.stdc.math.cosl          cos;

alias tango.stdc.complex.ccos       cos;
alias tango.stdc.complex.ccosf      cos;
alias tango.stdc.complex.ccosl      cos;

alias tango.stdc.math.sin           sin;
alias tango.stdc.math.sinf          sin;
alias tango.stdc.math.sinl          sin;

alias tango.stdc.complex.csin       csin;
alias tango.stdc.complex.csinf      csin;
alias tango.stdc.complex.csinl      csin;

alias tango.stdc.math.tan           tan;
alias tango.stdc.math.tanf          tan;
alias tango.stdc.math.tanl          tan;

alias tango.stdc.complex.ctan       tan;
alias tango.stdc.complex.ctanf      tan;
alias tango.stdc.complex.ctanl      tan;

alias tango.stdc.math.acosh         acosh;
alias tango.stdc.math.acoshf        acosh;
alias tango.stdc.math.acoshl        acosh;

alias tango.stdc.complex.cacosh     acosh;
alias tango.stdc.complex.cacoshf    acosh;
alias tango.stdc.complex.cacoshl    acosh;

alias tango.stdc.math.asinh         asinh;
alias tango.stdc.math.asinhf        asinh;
alias tango.stdc.math.asinhl        asinh;

alias tango.stdc.complex.casinh     asinh;
alias tango.stdc.complex.casinhf    asinh;
alias tango.stdc.complex.casinhl    asinh;

alias tango.stdc.math.atanh         atanh;
alias tango.stdc.math.atanhf        atanh;
alias tango.stdc.math.atanhl        atanh;

alias tango.stdc.complex.catanh     atanh;
alias tango.stdc.complex.catanhf    atanh;
alias tango.stdc.complex.catanhl    atanh;

alias tango.stdc.math.cosh          cosh;
alias tango.stdc.math.coshf         cosh;
alias tango.stdc.math.coshl         cosh;

alias tango.stdc.complex.ccosh      cosh;
alias tango.stdc.complex.ccoshf     cosh;
alias tango.stdc.complex.ccoshl     cosh;

alias tango.stdc.math.sinh          sinh;
alias tango.stdc.math.sinhf         sinh;
alias tango.stdc.math.sinhl         sinh;

alias tango.stdc.complex.csinh      sinh;
alias tango.stdc.complex.csinhf     sinh;
alias tango.stdc.complex.csinhl     sinh;

alias tango.stdc.math.tanh          tanh;
alias tango.stdc.math.tanhf         tanh;
alias tango.stdc.math.tanhl         tanh;

alias tango.stdc.complex.ctanh      tanh;
alias tango.stdc.complex.ctanhf     tanh;
alias tango.stdc.complex.ctanhl     tanh;

alias tango.stdc.math.exp           exp;
alias tango.stdc.math.expf          exp;
alias tango.stdc.math.expl          exp;

alias tango.stdc.complex.cexp       exp;
alias tango.stdc.complex.cexpf      exp;
alias tango.stdc.complex.cexpl      exp;

alias tango.stdc.math.exp2          exp2;
alias tango.stdc.math.exp2f         exp2;
alias tango.stdc.math.exp2l         exp2;

alias tango.stdc.math.expm1         expm1;
alias tango.stdc.math.expm1f        expm1;
alias tango.stdc.math.expm1l        expm1;

alias tango.stdc.math.frexp         frexp;
alias tango.stdc.math.frexpf        frexp;
alias tango.stdc.math.frexpl        frexp;

alias tango.stdc.math.ilogb         ilogb;
alias tango.stdc.math.ilogbf        ilogb;
alias tango.stdc.math.ilogbl        ilogb;

alias tango.stdc.math.ldexp         ldexp;
alias tango.stdc.math.ldexpf        ldexp;
alias tango.stdc.math.ldexpl        ldexp;

alias tango.stdc.math.log           log;
alias tango.stdc.math.logf          log;
alias tango.stdc.math.logl          log;

alias tango.stdc.complex.clog       log;
alias tango.stdc.complex.clogf      log;
alias tango.stdc.complex.clogl      log;

alias tango.stdc.math.log10         log10;
alias tango.stdc.math.log10f        log10;
alias tango.stdc.math.log10l        log10;

alias tango.stdc.math.log1p         log1p;
alias tango.stdc.math.log1pf        log1p;
alias tango.stdc.math.log1pl        log1p;

alias tango.stdc.math.log2          log1p;
alias tango.stdc.math.log2f         log1p;
alias tango.stdc.math.log2l         log1p;

alias tango.stdc.math.logb          log1p;
alias tango.stdc.math.logbf         log1p;
alias tango.stdc.math.logbl         log1p;

alias tango.stdc.math.modf          modf;
alias tango.stdc.math.modff         modf;
alias tango.stdc.math.modfl         modf;

alias tango.stdc.math.scalbn        scalbn;
alias tango.stdc.math.scalbnf       scalbn;
alias tango.stdc.math.scalbnl       scalbn;

alias tango.stdc.math.scalbln       scalbln;
alias tango.stdc.math.scalblnf      scalbln;
alias tango.stdc.math.scalblnl      scalbln;

alias tango.stdc.math.cbrt          cbrt;
alias tango.stdc.math.cbrtf         cbrt;
alias tango.stdc.math.cbrtl         cbrt;

alias tango.stdc.math.fabs          fabs;
alias tango.stdc.math.fabsf         fabs;
alias tango.stdc.math.fabsl         fabs;

alias tango.stdc.complex.cabs       fabs;
alias tango.stdc.complex.cabsf      fabs;
alias tango.stdc.complex.cabsl      fabs;

alias tango.stdc.math.hypot         hypot;
alias tango.stdc.math.hypotf        hypot;
alias tango.stdc.math.hypotl        hypot;

alias tango.stdc.math.pow           pow;
alias tango.stdc.math.powf          pow;
alias tango.stdc.math.powl          pow;

alias tango.stdc.complex.cpow       pow;
alias tango.stdc.complex.cpowf      pow;
alias tango.stdc.complex.cpowl      pow;

alias tango.stdc.math.sqrt          sqrt;
alias tango.stdc.math.sqrtf         sqrt;
alias tango.stdc.math.sqrtl         sqrt;

alias tango.stdc.complex.csqrt      sqrt;
alias tango.stdc.complex.csqrtf     sqrt;
alias tango.stdc.complex.csqrtl     sqrt;

alias tango.stdc.math.erf           erf;
alias tango.stdc.math.erff          erf;
alias tango.stdc.math.erfl          erf;

alias tango.stdc.math.erfc          erfc;
alias tango.stdc.math.erfcf         erfc;
alias tango.stdc.math.erfcl         erfc;

alias tango.stdc.math.lgamma        lgamma;
alias tango.stdc.math.lgammaf       lgamma;
alias tango.stdc.math.lgammal       lgamma;

alias tango.stdc.math.tgamma        tgamma;
alias tango.stdc.math.tgammaf       tgamma;
alias tango.stdc.math.tgammal       tgamma;

alias tango.stdc.math.ceil          ceil;
alias tango.stdc.math.ceilf         ceil;
alias tango.stdc.math.ceill         ceil;

alias tango.stdc.math.floor         floor;
alias tango.stdc.math.floorf        floor;
alias tango.stdc.math.floorl        floor;

alias tango.stdc.math.nearbyint     nearbyint;
alias tango.stdc.math.nearbyintf    nearbyint;
alias tango.stdc.math.nearbyintl    nearbyint;

alias tango.stdc.math.rint          rint;
alias tango.stdc.math.rintf         rint;
alias tango.stdc.math.rintl         rint;

alias tango.stdc.math.lrint         lrint;
alias tango.stdc.math.lrintf        lrint;
alias tango.stdc.math.lrintl        lrint;

alias tango.stdc.math.llrint        llrint;
alias tango.stdc.math.llrintf       llrint;
alias tango.stdc.math.llrintl       llrint;

alias tango.stdc.math.round         round;
alias tango.stdc.math.roundf        round;
alias tango.stdc.math.roundl        round;

alias tango.stdc.math.lround        lround;
alias tango.stdc.math.lroundf       lround;
alias tango.stdc.math.lroundl       lround;

alias tango.stdc.math.llround       llround;
alias tango.stdc.math.llroundf      llround;
alias tango.stdc.math.llroundl      llround;

alias tango.stdc.math.trunc         trunc;
alias tango.stdc.math.truncf        trunc;
alias tango.stdc.math.truncl        trunc;

alias tango.stdc.math.fmod          fmod;
alias tango.stdc.math.fmodf         fmod;
alias tango.stdc.math.fmodl         fmod;

alias tango.stdc.math.remainder     remainder;
alias tango.stdc.math.remainderf    remainder;
alias tango.stdc.math.remainderl    remainder;

alias tango.stdc.math.remquo        remquo;
alias tango.stdc.math.remquof       remquo;
alias tango.stdc.math.remquol       remquo;

alias tango.stdc.math.copysign      copysign;
alias tango.stdc.math.copysignf     copysign;
alias tango.stdc.math.copysignl     copysign;

alias tango.stdc.math.nan           nan;
alias tango.stdc.math.nanf          nan;
alias tango.stdc.math.nanl          nan;

alias tango.stdc.math.nextafter     nextafter;
alias tango.stdc.math.nextafterf    nextafter;
alias tango.stdc.math.nextafterl    nextafter;

alias tango.stdc.math.nexttoward    nexttoward;
alias tango.stdc.math.nexttowardf   nexttoward;
alias tango.stdc.math.nexttowardl   nexttoward;

alias tango.stdc.math.fdim          fdim;
alias tango.stdc.math.fdimf         fdim;
alias tango.stdc.math.fdiml         fdim;

alias tango.stdc.math.fmax          fmax;
alias tango.stdc.math.fmaxf         fmax;
alias tango.stdc.math.fmaxl         fmax;

alias tango.stdc.math.fmin          fmin;
alias tango.stdc.math.fmin          fmin;
alias tango.stdc.math.fminl         fmin;

alias tango.stdc.math.fma           fma;
alias tango.stdc.math.fmaf          fma;
alias tango.stdc.math.fmal          fma;

alias tango.stdc.complex.carg       carg;
alias tango.stdc.complex.cargf      carg;
alias tango.stdc.complex.cargl      carg;

alias tango.stdc.complex.cimag      cimag;
alias tango.stdc.complex.cimagf     cimag;
alias tango.stdc.complex.cimagl     cimag;

alias tango.stdc.complex.conj       conj;
alias tango.stdc.complex.conjf      conj;
alias tango.stdc.complex.conjl      conj;

alias tango.stdc.complex.cproj      cproj;
alias tango.stdc.complex.cprojf     cproj;
alias tango.stdc.complex.cprojl     cproj;

//alias tango.stdc.complex.creal      creal;
//alias tango.stdc.complex.crealf     creal;
//alias tango.stdc.complex.creall     creal;
