/**
 * Bind function arguments to functions.
 *
 * References:
 *	$(LINK2 http://www.boost.org/libs/bind/bind.html, boost::bind)	
 * Authors: Tomasz Stachowiak
 * Date: November 28, 2006
 * Macros:
 *	WIKI = Phobos/StdBind
 * Copyright:
 *	Public Domain
 */
module std.bind;


import std.string : stdFormat = format;
import std.traits;
import std.typetuple;





struct DynArg(int i) {
	static assert (i >= 0);
	
	alias i argNr;
}


/**
	When passed to the 'bind' function, they will mark dynamic params - ones that aren't statically bound
	In boost, they're called __1, __2, __3, etc.. here __0, __1, __2, ...
*/
const DynArg!(0) _0;
const DynArg!(1) _1;		/// ditto
const DynArg!(2) _2;		/// ditto
const DynArg!(3) _3;		/// ditto
const DynArg!(4) _4;		/// ditto
const DynArg!(5) _5;		/// ditto
const DynArg!(6) _6;		/// ditto
const DynArg!(7) _7;		/// ditto
const DynArg!(8) _8;		/// ditto
const DynArg!(9) _9;		/// ditto



/*
	Detect if a given type is a DynArg of any index
*/
template isDynArg(T) {
	static if (is(typeof(T.argNr))) {				// must have the argNr field
		static if(is(T : DynArg!(T.argNr))) {		// now check the exact type
			static const bool isDynArg = true;
		} else static const bool isDynArg = false;
	} else static const bool isDynArg = false;
}


/*
	Detect if a given type is a DynArg of the specified index
*/
template isDynArg(T, int i) {
	static const bool isDynArg = is(T : DynArg!(i));
}


/*
	Converts a static array type to a dynamic array type
*/
template DynamicArrayType(T) {
	alias typeof(T[0])[] DynamicArrayType;
}


/*
	Assigns one entity to another. As static arrays don't like normal assignment, slice assignment is used for them.
	
	Params:
		a = destination
		b = source
*/
template _assign(T) {
	static if (isStaticArray!(T)) {
		void _assign(DynamicArrayType!(T) a, DynamicArrayType!(T) b) {
			a[] = b[];
		}
	} else {
		void _assign(inout T a, inout T b) {
			a = b;
		}
	}
}


/*
	Assigns and potentially converts one entity to another
	
	Normally, only implicit conversion is used, but when both operands are numeric types, an explicit cast is performed on them.
	
	Params:
		T = destination type
		a = destination
		Y = source type
		b = source
		copyStaticArrays = when a static array is assigned to a dynamic one, it sometimes has to be .dup'ed as the storage may exist in volatile locations
*/
template _assign(T, Y, bool copyStaticArrays = true) {
	static if (isStaticArray!(T)) {
		
		// if the destination is a static array, copy each element from the source to the destination by a foreach
		void _assign(DynamicArrayType!(T) a, DynamicArrayType!(Y) b) {
			foreach (i, x; b) {
				_assign!(typeof(a[i]), typeof(x))(a[i], x);
			}
		}
	} else static if (!isStaticArray!(T) && isStaticArray!(Y)) {
		
		// the destination is a dynamic array and the source is a static array. this sometimes needs a .dup
		void _assign(inout T a, DynamicArrayType!(Y) b) {
			static if (copyStaticArrays) {
				a = b.dup;
			} else {
				a = b;
			}
		}
	} else {
		
		// none of the items is a static array
		void _assign(inout T a, inout Y b) {
			static if (IndexOf!(T, NumericTypes.type) != -1 && IndexOf!(Y, NumericTypes.type) != -1) {
				a = cast(T)b;
			} else {
				a = b;
			}
		}
	}
}



/**
	A simple tuple struct with some basic operations
*/
struct Tuple(T ...) {
	alias Tuple	meta;
	const bool	expressionTuple = isExpressionTuple!(T);
	
	static if (!expressionTuple) {
		alias T	type;		// a built-in tuple
		T			value;		// a built-in tuple instance
	} else {
		alias T	value;
	}
	
	
	const int length = value.length;
	

	/**
		Statically yields a tuple type with an extra element added at its end
	*/
	template appendT(X) {
		alias .Tuple!(T, X) appendT;
	}


	/**
		Yields a tuple with an extra element added at its end
	*/
	appendT!(X) append(X)(X x) {
		appendT!(X) res;
		foreach (i, y; value) {
			_assign!(typeof(y))(res.value[i], y);
		}
		_assign!(typeof(x))(res.value[$-1], x);
		return res;
	}
	
	
	/**
		Statically yields a tuple type with an extra element added at its beginning
	*/
	template prependT(X) {
		alias .Tuple!(X, T) prependT;
	}


	/**
		Yields a tuple with an extra element added at its beginning
	*/
	prependT!(X) prepend(X)(X x) {
		prependT!(X) res;
		foreach (i, y; value) {
			_assign!(typeof(y))(res.value[i+1], y);
		}
		_assign!(typeof(x))(res.value[0], x);
		return res;
	}
	
	
	/**
		Statically concatenates this tuple type with another tuple type
	*/
	template concatT(T ...) {
		static if (expressionTuple) {
			alias .Tuple!(value, T) concatT;
		} else {
			alias .Tuple!(type, T) concatT;
		}
	}
	
	
	char[] toString() {
		char[] res = "(" ~ stdFormat(value[0]);
		foreach (x; value[1..$]) {
			res ~= stdFormat(", ", x);
		}
		return res ~ ")";
	}
}


/**
	An empty tuple struct
*/
struct Tuple() {
	alias Tuple					meta;

	template EmptyTuple_(T ...) {
		alias T EmptyTuple_;
	}
	

	alias EmptyTuple_!()	type;		/// an empty built-in tuple
	alias EmptyTuple_!()	value;		/// an empty built-in tuple
	
	const bool	expressionTuple = false;	
	const int	length = 0;


	template appendT(X) {
		alias .Tuple!(X) appendT;
	}
	alias appendT prependT;


	appendT!(X) append(X)(X x) {
		appendT!(X) res;
		foreach (i, y; value) {
			_assign!(typeof(y))(res.value[i], y);
		}
		return res;
	}
	alias append prepend;
	
	
	// T - other tuple
	template concatT(T ...) {
		alias .Tuple!(T) concatT;
	}
	
	
	char[] toString() {
		return "()";
	}
}


/**
	Dynamically create a tuple from the given items
*/
Tuple!(T) tuple(T ...)(T t) {
	Tuple!(T) res;
	foreach (i, x; t) {
		_assign!(typeof(x))(res.value[i], x);
	}
	return res;
}


/**
	Checks whether a given type is the Tuple struct of any length
*/
template isTypeTuple(T) {
	static if (is(T.type)) {
		static if (is(T == Tuple!(T.type))) {
			const bool isTypeTuple = true;
		} else const bool isTypeTuple = false;
	} else const bool isTypeTuple = false;
}

static assert(isTypeTuple!(Tuple!(int)));
static assert(isTypeTuple!(Tuple!(float, char)));
static assert(isTypeTuple!(Tuple!(double, float, int, char[])));
static assert(isTypeTuple!(Tuple!(Object, creal, long)));
static assert(!isTypeTuple!(Object));
static assert(!isTypeTuple!(int));




template minNumArgs_impl(alias fn, fnT) {
	alias ParameterTypeTuple!(fnT) Params;
	Params params = void;
	
	template loop(int i = 0) {
		static assert (i <= Params.length);
		
		static if (is(typeof(fn(params[0..i])))) {
			const int res = i;
		} else {
			alias loop!(i+1).res res;
		}
	}
	
	alias loop!().res res;
}
/**
	Finds the minimal number of arguments a given function needs to be provided
*/
template minNumArgs(alias fn, fnT = typeof(&fn)) {
	const int minNumArgs = minNumArgs_impl!(fn, fnT).res;
}


// mixed into BoundFunc struct/class
template MBoundFunc() {
	// meta
	alias FAlias_													FAlias;
	alias FT															FuncType;
	alias AllBoundArgs_										AllBoundArgs;		// all arguments given to bind() or bindAlias()
	
	static if (!is(typeof(FAlias) == EmptySlot)) {
		alias Tuple!(ParameterTypeTuple!(FT))				RealFuncParams;	// the parameters of the bound function
		alias FuncReferenceParamsAsPointers!(FAlias)	FuncParams;			// references converted to pointers
	} else {
		alias Tuple!(ParameterTypeTuple!(FT))			FuncParams;			// the parameters of the bound function
	}
	
	alias ReturnType!(FT)										RetType;				// the return type of the bound function
	alias ExtractedBoundArgs!(AllBoundArgs.type)	BoundArgs;			// 'saved' arguments. this includes nested/composed functions
	
	
	// if bindAlias was used, we can detect default arguments and only demand the non-default arguments to be specified
	static if (!is(typeof(FAlias) == EmptySlot)) {
		const int minFuncArgs = minNumArgs!(FAlias);
		
		alias ParamsPassMethodTuple!(FAlias)			ParamPassingMethods;	// find out whether the function expects parameters by value or reference
	} else {
		const int minFuncArgs = FuncParams.length;
	}
	
	// the parameters that our wrapper function must get
	alias getDynArgTypes!(FuncParams, AllBoundArgs, minFuncArgs).res.type	DynParams;
	
	// data
	FuncType			fp;
	BoundArgs		boundArgs;

	// yields the number of bound-function parameters that are covered by the binding. takes tuple expansion into account
	template numFuncArgsReallyBound(int argI = 0, int fargI = 0, int bargI = 0) {
		
		// walk though all of AllBoundArgs
		static if (argI < AllBoundArgs.length) {
			
			// the argI-th arg is a composed/nested function
			static if (isBoundFunc!(AllBoundArgs.type[argI])) {
				alias DerefFunc!(AllBoundArgs.type[argI]).RetType		FuncRetType;
				const int argLen = getArgLen!(FuncParams.type[fargI], FuncRetType);
				const int bargInc = 1;
			}
			
			// the argI-th arg is a dynamic argument whose value we will get in the call to func()
			else static if (isDynArg!(AllBoundArgs.type[argI])) {
				const int argLen = getArgLen!(FuncParams.type[fargI], DynParams[AllBoundArgs.type[argI].argNr]);
				const int bargInc = 0;
			}
			
			// the argI-th arg is a statically bound argument
			else {
				const int argLen = getArgLen!(FuncParams.type[fargI], BoundArgs.type[bargI]);
				const int bargInc = 1;
			}
			
			// iterate
			const int res = numFuncArgsReallyBound!(argI+1, fargI+argLen, bargI+bargInc).res;
		} else {
			// last iteration
			
			// the number of bound args is the number of arguments we've detected in this template loop
			const int res = fargI;

			// make sure we'll copy all args the function is going to need
			static assert (res >= minFuncArgs);
		}
	}
	
	const int numSpecifiedParams = numFuncArgsReallyBound!().res;
	
	// it's a tuple type whose instance will be applied to the bound function
	alias Tuple!(FuncParams.type[0 .. numSpecifiedParams])	SpecifiedParams;
	

	// argI = indexes AllBoundArgs
	// fargI = indexes funcArgs
	// bargI = indexes boundArgs
	void copyArgs(int argI = 0, int fargI = 0, int bargI = 0)(inout SpecifiedParams funcArgs, DynParams dynArgs) {
		static if (argI < AllBoundArgs.length) {

			// the argI-th arg is a composed/nested function
			static if (isBoundFunc!(AllBoundArgs.type[argI])) {
				alias DerefFunc!(AllBoundArgs.type[argI]).RetType		FuncRetType;
				alias DerefFunc!(AllBoundArgs.type[argI]).DynParams	FuncDynParams;
				
				// if FuncDynParams contains an empty slot, e.g. as in the case  bind(&f, bind(&g, _1), _0)
				// then we cannot just apply the dynArgs tuple to the nested/composed function because it will have EmptySlot params
				// while our dynArgs tuple will contain ordinary types
				static if (ContainsEmptySlotType!(FuncDynParams)) {
					
					FuncDynParams funcParams;	// we'll fill it with values in a bit
					
					foreach (i, dummy_; dynArgs) {
						static if (!is(typeof(FuncDynParams[i] == EmptySlot))) {
							
							// 3rd param is false because there is no need to .dup static arrays just for the function below this foreach
							// the storage exists in the whole copyArgs function
							// dynArgs[i] is used instead of dummy_ so that loop-local data isn't referenced in any dynamic arrays after the loop
							_assign!(typeof(funcParams[i]), typeof(dummy_), false)(funcParams[i], dynArgs[i]);
						}
					}
					
					FuncRetType funcRet = boundArgs.value[bargI].func(funcParams);
				} else {
					FuncRetType funcRet = boundArgs.value[bargI].func(dynArgs[0..FuncDynParams.length]);	// only give it as many dynParams as it needs
				}
				
				// we'll take data from the returned value
				auto srcItem = &funcRet;
				
				const int bargInc = 1;							// nested/composed functions belong to the boundArgs tuple
				const bool dupStaticArrays = true;		// because the function's return value is stored locally
			}

			// the argI-th arg is a dynamic argument whose value we will get in the call to func()
			else static if (isDynArg!(AllBoundArgs.type[argI])) {
				
				// we'll take data from dynArgs
				auto srcItem = &dynArgs[AllBoundArgs.type[argI].argNr];
				
				const int bargInc = 0;							// dynamic args don't belond to the boundArgs tuple
				const bool dupStaticArrays = true;		// because we get dynArgs on stack
			}
			
			// the argI-th arg is a statically bound argument
			else {
				
				// we'll take data directly from boundArgs
				auto srcItem = &boundArgs.value[bargI];
				
				const int bargInc = 1;							// statically bound args belong to the boundArgs tuple
				const bool dupStaticArrays = false;		// because the storage exists in boundArgs
			}

			// the number of bound-function parameters this argument will cover after tuple expansion
			const int argLen = getArgLen!(funcArgs.type[fargI], typeof(*srcItem));

			static if (isTypeTuple!(typeof(*srcItem)) && !isTypeTuple!(funcArgs.type[fargI])) {
				foreach (i, x; srcItem.value) {
					_assign!(funcArgs.type[fargI + i], typeof(x), dupStaticArrays)(funcArgs.value[fargI + i], x);
				}
			} else {
				static assert (1 == argLen);
				_assign!(funcArgs.type[fargI], typeof(*srcItem), dupStaticArrays)(funcArgs.value[fargI], *srcItem);
			}

			// because we might've just expended a tuple, this may be larger than one
			static assert (argLen >= 1);
			
			// we could've just used a dynamic arg (0) or a statically bound arg(1)
			static assert (bargInc == 0 || bargInc == 1);
			
			
			return copyArgs!(argI+1, fargI+argLen, bargI+bargInc)(funcArgs, dynArgs);
		} else {
			// last iteration
			
			// make sure we've copied all args the function will need
			static assert (fargI >= minFuncArgs);
		}
	}


	static if (SpecifiedParams.length > 0) {
		/// The final wrapped function
		RetType func(DynParams dynArgs) {
			SpecifiedParams funcArgs;
			copyArgs!()(funcArgs, dynArgs);
			
			// if the function expects any parameters passed by reference, we'll have to use the ptrApply template
			// and convert pointers back to references by hand
			static if (!is(typeof(FAlias) == EmptySlot) && IndexOf!(PassByRef, ParamPassingMethods.type) != -1) {
				
				// function parameter type pointers (int, float*, inout char) -> (int*, float*, char*)
				PointerTuple!(Tuple!(RealFuncParams.type[0 .. SpecifiedParams.length]))	ptrs;
				
				// initialize the 'ptrs' tuple instance
				foreach (i, dummy_; funcArgs.value) {
					static if (is(ParamPassingMethods.type[i] == PassByRef)) {
						
						version (BindNoNullCheck) {}
						else {
							assert (funcArgs.value[i], "references cannot be null");
						}
						
						ptrs.value[i] = funcArgs.value[i];
					} else {
						ptrs.value[i] = &funcArgs.value[i];
					}
				}
				
				// and call the function :)
				ptrApply!(RetType, FuncType, ptrs.type)(fp, ptrs.value);
			} else {
				
				// ordinary call-by-tuple
				return fp(funcArgs.value);
			}
		}
	} else {
		/// The final wrapped function
		RetType func() {
			return fp();
		}
	}
	
	/// The final wrapped function
	alias func call;
	
	
	/// The final wrapped function
	alias func opCall;
	
	
	/**
		The type of the delegate that may be returned from this object
	*/
	template PtrType() {
		alias typeof(&(new BoundFunc).call) PtrType;
	}
	
	/**
		Get a delegate. Equivalent to getting it thru &foo.call
	*/
	PtrType!() ptr() {
		return &this.func;
	}
}


version (BindUseStruct) {
	template DerefFunc(T) {
		alias typeof(*T) DerefFunc;
	}

	/**
		A context for bound/curried functions
	*/
	struct BoundFunc(FT, alias FAlias_, AllBoundArgs_) {
		mixin MBoundFunc;
	}
} else {
	template DerefFunc(T) {
		alias T DerefFunc;
	}

	/**
		A context for bound/curried functions
	*/
	class BoundFunc(FT, alias FAlias_, AllBoundArgs_) {
		mixin MBoundFunc;
	}
}


/**
	bind() can curry or "bind" arguments of a function, producing a different function which requires less parameters,
	or a different order of parameters. It also allows function composition.
	
	The syntax of a bind() call is:
	
	bind(function or delegate pointer { , <b>argument</b> });
	
	<b>argument</b> can be one of:
	<ul>
	<li> static/bound argument (an immediate value) </li>
	<li> another bound function object </li>
	<li> dynamic argument, of the form __[0-9], e.g. __0, __3 or __9 </li>
	</ul>
	
	The result is a function object, which can be called using call(), func() or opCall().
	There also exists a convenience function, ptr() which returns a delegate to call/func/opCall
	
	The resulting delegate accepts exactly as many parameters as many distinct dynamic arguments were used.
---
- bind(&foo, _0, _1) // will yield a delegate accepting two parameters
- bind(&foo, _1, _0) // will yield a delegate accepting two parameters
- bind(&bar, _0, _1, _2, _0) // will yield a delegate accepting three parameters
---
	
	<br />
	<br />
	The types of dynamic parameters are extracted from the bound function itself and when necessary, type negotiation
	is performed. For example, binding a function
---
void foo(int a, long b)

// with:
bind(&foo, _0, _0)
---
	will result in a delegate accepting a single, optimal parameter type. The best type is computed
	using std.typetuple.DerivedToFront, so in case of an int and a long, long will be selected. Generally, bind will try to find
	a type that can be implicitly converted to all the other types a given dynamic parameter uses.
		Note: in case of numeric types, an explicit, but transparent (to the user) cast will be performed
	
	<br />
	Function composition works intuitively:
---
bind(&f1, bind(&f2, _0))
---
	
	which will yield a delegate, that takes the argument, calls f2, then uses the return value of f2 to call f1. Mathematically
	speaking, it will yield a function composition:
---
f1(f2(_0))
---
	
	When one function is composed multiple times, it will be called multiple times - Bind does no lazy evaluation, so
---
bind(&f3, bind(&f4, _0), bind(&f4, _0))
---
	will produce a delegate, which, upon calling, will invoke f4 two times to evaluate the arguments for f3 and then call f3
	
	
	One another feature that bind() supports is automatic tuple expansion. It means that having functions:
---
void foo(int a, int b)
Tuple!(int, int) bar()
---
	
	Allows them to be bound by writing:
---
bind(&foo, bind(&bar))
// or
bind(&foo, tuple(23, 45))
---
*/
typeof(new BoundFunc!(FT, NullAlias, Tuple!(ArgList))) bind(FT, ArgList...)(FT fp, ArgList args) {
	auto res = new DerefFunc!(ReturnType!(bind));
	res.fp = fp;
	extractBoundArgs!(0, 0, ArgList)(res.boundArgs, args);
	return res;
}


/**
	bindAlias() is similar to bind(), but it's more powerful. Use bindAlias() rather than bind() where possible. <br/>


	The syntax is:
	
	bindAlias!(Function)(argument, argument, argument, argument, ...);
	
	bindAlias takes advantage of using aliases directly, thus being able to extract default values from functions and not forcing the user
	to bind them. It doesn't, however mean that the resulting delegate can be called, omitting some of its parameters. It only means that these
	arguments that have default values in the function provided to bindAlias don't have to be bound explicitly.
	
	Additionally, bindAlias takes care of functions with out/inout parameters, by converting them to pointers internally. A function like:
---
void foo(inout a)
---	
	can be bound using:
---
int x;
bindAlias!(foo)(&x);
---
	
	Note: there is no bind-time check for reference nullness, there is however a call-time check on all references which can be disabled
	by using version=BindNoNullCheck or compiling in release mode.
*/
template bindAlias(alias FT) {
	typeof(new BoundFunc!(typeof(&FT), FT, Tuple!(ArgList))) bindAlias(ArgList...)(ArgList args) {
		auto res = new DerefFunc!(ReturnType!(bindAlias));
		res.fp = &FT;
		extractBoundArgs!(0, 0, ArgList)(res.boundArgs, args);
		return res;
	}
}





/*
	Tells whether the specified type is a bound function
*/
template isBoundFunc(T) {
	static if (is(DerefFunc!(T).FuncType)) {
		static if (is(DerefFunc!(T).BoundArgs)) {
			static if (is(typeof(DerefFunc!(T).FAlias))) {
				static if (is(DerefFunc!(T) : BoundFunc!(DerefFunc!(T).FuncType, DerefFunc!(T).FAlias, DerefFunc!(T).AllBoundArgs))) {
					static const bool isBoundFunc = true;
				} else static const bool isBoundFunc = false;
			} else static const bool isBoundFunc = false;
		} else static const bool isBoundFunc = false;
	} else static const bool isBoundFunc = false;
}


// all numeric types as of dmd.175
alias Tuple!(byte, ubyte, short, ushort, int, uint, long, ulong, /+cent, ucent, +/float, double, real, ifloat, idouble, ireal, cfloat, cdouble, creal) NumericTypes;



/*
	Gather all types that a given (i-th) dynamic arg uses.
	The types will be inserted into a tuple
*/
template dynArgTypes(int i, FuncParams, BoundArgs, int minParamsLeft) {
	
	// performs slicing on the tuple ... tuple[i .. length]
	template sliceOffTuple(T, int i) {
		alias Tuple!(T.type[i..length]) res;
	}
	
	// prepends a T to the resulting tuple
	// SkipType - the type in BoundArgs that we're just processing
	template prependType(T, SkipType) {
		static if (isTypeTuple!(SkipType) && !isTypeTuple!(FuncParams.type[0])) {
			// perform tuple decomposition
			// e.g. if a function being bound is accepting (int, int) and the current type is a Tuple!(int, int),
			// then skip just one tuple in the bound args and the length of the tuple in func args
			// - skips two ints and one tuple in the example
			alias dynArgTypes!(
					i,
					sliceOffTuple!(FuncParams, SkipType.length).res,
					Tuple!(BoundArgs.type[1..$]),
					minParamsLeft - SkipType.length
				).res tmp;
				
		} else {
			// just advance by one type
			alias dynArgTypes!(
					i,
					sliceOffTuple!(FuncParams, 1).res,
					Tuple!(BoundArgs.type[1..$]),
					minParamsLeft-1
				).res tmp;
		}
		
		static if (is(T == void)) {	// void means that we aren't adding anything
			alias tmp res;
		} else {
			alias tmp.meta.prependT!(T) res;
		}
	}
	
	// iteration end detector
	static if (is(BoundArgs == Tuple!())) {
		static assert (minParamsLeft <= 0, "there are still unbound function parameters");
		alias Tuple!() res;
	}
	else {
		
		// w00t, detected a regular dynamic arg
		static if (isDynArg!(BoundArgs.type[0], i)) {
			alias prependType!(FuncParams.type[0], BoundArgs.type[0]).res res;
		} 
		
		// the arg is a bound function, extract info from it. we will be evaluating it later
		else static if (isBoundFunc!(BoundArgs.type[0])) {
			alias DerefFunc!(BoundArgs.type[0]) BoundFunc;		// the bound function is a struct pointer, we have to derefernce its type
			
			// does that function even have any dynamic params ?
			static if (BoundFunc.DynParams.length > i) {
				alias prependType!(BoundFunc.DynParams[i], BoundFunc.RetType).res res;
			}
			// it doesn't
			else {
				alias prependType!(void, BoundFunc.RetType).res res;
			}
		}
		
		// a static arg, just skip it since we want to find all types a given DynArg uses. static args <> dyn args
		else alias prependType!(void, BoundArgs.type[0]).res res;
	}
}


// just a simple util
private template maxInt(int a, int b) {
	static if (a > b) static const int maxInt = a;
	else static const int maxInt = b;
}


/*
	Given a list of BoundArgs, it returns the nuber of args that should be specified dynamically
*/
template numDynArgs(BoundArgs) {
	static if (BoundArgs.length == 0) {
		// received an EmptyTuple
		static const int res = 0;
	} else {
		// ordinary dynamic arg
		static if (isDynArg!(BoundArgs.type[0])) {
			static const int res = maxInt!(BoundArgs.type[0].argNr+1, numDynArgs!(Tuple!(BoundArgs.type[1..$])).res);
		}
		
		// count the args in nested / composed functions
		else static if (isBoundFunc!(BoundArgs.type[0])) {
			static const int res = maxInt!(DerefFunc!(BoundArgs.type[0]).DynParams.length, numDynArgs!(Tuple!(BoundArgs.type[1..$])).res);
		}
		
		// statically bound arg, skip it
		else {
 			static const int res = numDynArgs!(Tuple!(BoundArgs.type[1..$])).res;
		}
	}
}


/*
	Used internally to mark a parameter which is a dummy placeholder
	E.g. when using bind(&f, bind(&g, _1), _0), then the inner bound function will use an EmptySlot for its 0-th parameter
*/
struct EmptySlot {
	char[] toString( ) {
		return "_";
	}
}


/*
	Get a tuple of all dynamic args a function binding will need
	take nested/composed functions as well as tuple decomposition into account
*/
template getDynArgTypes(FuncParams, BoundArgs, int minFuncArgs) {
	template loop(int i) {
		static if (i < numDynArgs!(BoundArgs).res) {
			alias dynArgTypes!(i, FuncParams, BoundArgs, minFuncArgs).res.type dirtyArgTypeList;
			
			// 'clean' the type list, erasing all NoTypes from it that could've been added there from composed functions
			// if the arg is not used, we'll mark it as NoType anyway, but for now, we only want 'real' types so the most derived one can be found
			alias Tuple!(EraseAll!(EmptySlot, dirtyArgTypeList)) argTypeList;
			
			
			// make sure the arg is used
			static if(!is(argTypeList == Tuple!())) {
				alias DerivedToFront!(argTypeList.type)[0] argType;
			} else {
				//static assert(false, i);
				alias EmptySlot argType;
			}

			alias loop!(i+1).res.meta.prependT!(argType) res;
		} else {
			alias Tuple!() res;
		}
	}
	
	alias loop!(0).res res;
}


/*
	Given a tuple that bind() was called with, it will detect which types need to be stored in a BoundFunc object
*/
template ExtractedBoundArgs(BoundArgs ...) {
	static if (BoundArgs.length == 0) {
		alias Tuple!() ExtractedBoundArgs;
	}
	
	// we'll store all non-dynamic arguments...
	else static if (!isDynArg!(BoundArgs[0])) {
		alias ExtractedBoundArgs!(BoundArgs[1..$]).meta.prependT!(BoundArgs[0]) ExtractedBoundArgs;
	}
	
	// ... and we're going to leave the dynamic ones for later
	else {
		alias ExtractedBoundArgs!(BoundArgs[1..$]) ExtractedBoundArgs;
	}
}


/*
	Given a tuple that bind() was called with, it will copy all data that a BoundFunc object will store into an ExtractedBoundArgs tuple
*/
void extractBoundArgs(int dst, int src, BoundArgs ...)(inout ExtractedBoundArgs!(BoundArgs) result, BoundArgs boundArgs) {
	static if (dst < result.length) {
		// again, we only want non-dynamic arguments here
		static if (!isDynArg!(BoundArgs[src])) {
			_assign!(typeof(result.value[dst]), typeof(boundArgs[src]))(result.value[dst], boundArgs[src]);
			return extractBoundArgs!(dst+1, src+1, BoundArgs)(result, boundArgs);
		}
		
		// the dynamic ones will be specified at the time BoundFunc.call() is invoked
		else {
			return extractBoundArgs!(dst, src+1, BoundArgs)(result, boundArgs);
		}
	}
}


/*
	Number of args in the bound function that this Src arg will cover
*/
template getArgLen(Dst, Src) {
	// if the arg is a tuple and the target isn't one, it will be expanded/decomposed to the tuple's length
	static if (isTypeTuple!(Src) && !isTypeTuple!(Dst)) {
		static const int getArgLen = Src.length;
	}
	
	// plain arg - it will use 1:1 mapping of functioni params to bound params
	else {
		static const int getArgLen = 1;
	}
}


/*
	Tell whether a parameter type tuple contains an EmptySlot struct
*/
template ContainsEmptySlotType(ParamList ...) {
	const bool ContainsEmptySlotType = -1 != IndexOf!(EmptySlot, ParamList);
}


// just something to be default in bind(). bindAlias() will use real aliases.
const EmptySlot NullAlias;




struct PassByCopy	{}
struct PassByRef	{}

template ParamsPassMethodTuple_impl(alias Func, int i = 0) {
	alias Tuple!(ParameterTypeTuple!(typeof(&Func)))	Params;
	
	static if (Params.length == i) {
		alias Tuple!() res;
	} else {
		Params params = void;
		const params.type[i] constParam;
		
		// if the function expects references, it won't like our const.
		static if (is(typeof(Func(params.value[0..i], constParam, params.value[i+1..$])))) {
			alias ParamsPassMethodTuple_impl!(Func, i+1).res.meta.prependT!(PassByCopy) res;
		} else {
			alias ParamsPassMethodTuple_impl!(Func, i+1).res.meta.prependT!(PassByRef) res;
		}
	}
}

/*
	Detect parameter passing methods: PassByCopy or PassByRef[erence]
*/
template ParamsPassMethodTuple(alias Func) {
	alias ParamsPassMethodTuple_impl!(Func).res ParamsPassMethodTuple;
}


template FuncReferenceParamsAsPointers_impl(alias Func) {
	alias Tuple!(ParameterTypeTuple!(typeof(&Func)))	Params;
	alias ParamsPassMethodTuple!(Func)						PassMethods;
	
	template loop(int i) {
		static if (i == Params.length) {
			alias Tuple!() res;
		} else {
			static if (is(PassMethods.type[i] == PassByRef)) {
				alias Params.type[i]*	type;
			} else {
				alias Params.type[i]	type;
			}
			
			alias loop!(i+1).res.meta.prependT!(type) res;
		}		
	}
	
	alias loop!(0).res res;
}

/*
	Takes a function/delegate alias and converts its refence parameters to pointers. E.g.
	
	void function(int, inout char, float*)    ->   (int, char*, float*)
*/
template FuncReferenceParamsAsPointers(alias Func) {
	alias FuncReferenceParamsAsPointers_impl!(Func).res FuncReferenceParamsAsPointers;
}



/*
	Converts a tuple of types to a tuple containing pointer types of the original types
*/
template PointerTuple(T) {
	static if (T.length > 0) {
		alias PointerTuple!(Tuple!(T.type[1..$])).meta.prependT!(T.type[0]*) PointerTuple;
	} else {
		alias Tuple!() PointerTuple;
	}
}



/*
	Calls a function, dereferencing a pointer tuple for each argument
*/
RetType ptrApply(RetType, FN, T ...)(FN fn, T t) {
	static if (1 == T.length) {
		return fn(*t[0]);
	}
	else static if (2 == T.length) {
		return fn(*t[0], *t[1]);
	}
	else static if (3 == T.length) {
		return fn(*t[0], *t[1], *t[2]);
	}
	else static if (4 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3]);
	}
	else static if (5 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4]);
	}
	else static if (6 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5]);
	}
	else static if (7 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5], *t[6]);
	}
	else static if (8 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5], *t[6], *t[7]);
	}
	else static if (9 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5], *t[6], *t[7], *t[8]);
	}
	else static if (10 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5], *t[6], *t[7], *t[8], *t[9]);
	}
}
