/**
	Templates not found in Tango, but included in Phobos.
*/
module meta.Default;

template ReturnType(alias dg) {
    alias ReturnType!(typeof(dg)) ReturnType;
}
template ReturnType(dg) {
    static if (is(dg R == return))
        alias R ReturnType;
    else
        static assert(false, "argument has no return type");
}

template ParameterTypeTuple(alias dg) {
    alias ParameterTypeTuple!(typeof(dg)) ParameterTypeTuple;
}
template ParameterTypeTuple(dg) {
    static if (is(dg P == function))
        alias P ParameterTypeTuple;
    else static if (is(dg P == delegate))
        alias ParameterTypeTuple!(P) ParameterTypeTuple;
    else static if (is(dg P == P*))
        alias ParameterTypeTuple!(P) ParameterTypeTuple;
    else
        static assert(false, "argument has no parameters");
}

/**
	Derives the minimum number of arguments the given function may be called with.

	This has some cases in which it can fail, or at least not behave exactly as
	expected. For instance, it cannot distinguish between the following:

	void foo(int i);
	void foo(int i, real j);

	and

	void foo(int i, real j=2.0);

	In the first case, calling minArgs!(foo, void function(int, real)) will
	result in 1, which is arguably incorrect. However, minArgs should be "good
	enough" in most cases.
*/
template minArgs(alias fn, fn_t = typeof(&fn)) {
	const uint minArgs = minArgsT!(fn, fn_t).minArgs;
}

template minArgsT(alias fn, fn_t = typeof(&fn)) {
	alias ParameterTypeTuple!(fn_t) T;

	T[i] I(uint i)() {
		return T[i].init;
	}

	static if (is(typeof(fn())))
		const uint minArgs = 0;
	else static if (is(typeof(fn(I!(0)()))))
		const uint minArgs = 1;
	else static if (is(typeof(fn(I!(0)(), I!(1)()))))
		const uint minArgs = 2;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)()))))
		const uint minArgs = 3;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)()))))
		const uint minArgs = 4;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)()))))
		const uint minArgs = 5;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)()))))
		const uint minArgs = 6;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)()))))
		const uint minArgs = 7;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)()))))
		const uint minArgs = 8;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)()))))
		const uint minArgs = 9;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)()))))
		const uint minArgs = 10;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)()))))
		const uint minArgs = 11;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)(), I!(11)()))))
		const uint minArgs = 12;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)(), I!(11)(), I!(12)()))))
		const uint minArgs = 13;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)(), I!(11)(), I!(12)(), I!(13)()))))
		const uint minArgs = 14;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)(), I!(11)(), I!(12)(), I!(13)(), I!(14)()))))
		const uint minArgs = 15;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)(), I!(11)(), I!(12)(), I!(13)(), I!(14)(), I!(15)()))))
		const uint minArgs = 16;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)(), I!(11)(), I!(12)(), I!(13)(), I!(14)(), I!(15)(), I!(16)()))))
		const uint minArgs = 17;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)(), I!(11)(), I!(12)(), I!(13)(), I!(14)(), I!(15)(), I!(16)(), I!(17)()))))
		const uint minArgs = 18;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)(), I!(11)(), I!(12)(), I!(13)(), I!(14)(), I!(15)(), I!(16)(), I!(17)(), I!(18)()))))
		const uint minArgs = 19;
	else static if (is(typeof(fn(I!(0)(), I!(1)(), I!(2)(), I!(3)(), I!(4)(), I!(5)(), I!(6)(), I!(7)(), I!(8)(), I!(9)(), I!(10)(), I!(11)(), I!(12)(), I!(13)(), I!(14)(), I!(15)(), I!(16)(), I!(17)(), I!(18)(), I!(19)()))))
		const uint minArgs = 20;
}
