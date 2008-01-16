module gcc.config.mathfuncs;

private import gcc.config.libc;
private import gcc.builtins;


// If long double functions are present, just alias
// to the __builtin_ version.  This may not do the right thing (TODO)
extern (C) { // prob doesn't matter..
alias __builtin_acosl acosl;
alias __builtin_asinl asinl;
alias __builtin_atanl atanl;
alias __builtin_atan2l atan2l;
alias __builtin_cosl cosl;
alias __builtin_sinl sinl;
alias __builtin_tanl tanl;
alias __builtin_acoshl acoshl;
alias __builtin_asinhl asinhl;
alias __builtin_atanhl atanhl;
alias __builtin_coshl coshl;
alias __builtin_sinhl sinhl;
alias __builtin_tanhl tanhl;
alias __builtin_expl expl;
alias __builtin_exp2l exp2l;
alias __builtin_expm1l expm1l;
alias __builtin_frexpl frexpl;
alias __builtin_ilogbl ilogbl;
alias __builtin_ldexpl ldexpl;
alias __builtin_logl logl;
alias __builtin_log10l log10l;
alias __builtin_log1pl log1pl;
alias __builtin_log2l log2l;
alias __builtin_logbl logbl;
alias __builtin_modfl modfl;
alias __builtin_scalbnl scalbnl;
alias __builtin_scalblnl scalblnl;
alias __builtin_cbrtl cbrtl;
alias __builtin_fabsl fabsl;
alias __builtin_hypotl hypotl;
alias __builtin_powl powl;
alias __builtin_sqrtl sqrtl;
alias __builtin_erfl erfl;
alias __builtin_erfcl erfcl;
alias __builtin_lgammal lgammal;
alias __builtin_tgammal tgammal;
alias __builtin_ceill ceill;
alias __builtin_floorl floorl;
alias __builtin_nearbyintl nearbyintl;
alias __builtin_rintl rintl;
alias __builtin_lrintl lrintl;
alias __builtin_llrintl llrintl;
alias __builtin_roundl roundl;
alias __builtin_lroundl lroundl;
alias __builtin_llroundl llroundl;
alias __builtin_truncl truncl;
alias __builtin_fmodl fmodl;
alias __builtin_remainderl remainderl;
alias __builtin_remquol remquol;
alias __builtin_copysignl copysignl;
//alias __builtin_nanl nanl;
real nanl(char *);
alias __builtin_nextafterl nextafterl;
alias __builtin_nexttowardl nexttowardl;
alias __builtin_fdiml fdiml;
alias __builtin_fmaxl fmaxl;
alias __builtin_fminl fminl;
alias __builtin_fmal fmal;

alias __builtin_sqrt sqrt;
//alias __builtin_sqrtf sqrtf;// needs an extra step
}

alias __builtin_sqrtf sqrtf;
