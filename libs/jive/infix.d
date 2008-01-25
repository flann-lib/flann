/* Based on original implementation by downs */

module jive.infix;

/* generic custom operator */

template InfixOperator(char[] name)
{
	private struct opStruct
	{
		template RT(T)
		{
			static if (is(T == class) || is(T == struct) || is(T == interface) || is(T == union))
					mixin("alias T." ~ name ~ "Operator RT;");
			else
					mixin("alias " ~ name ~"OperatorGlobal!(T) RT;");
		}

		static RT!(T).RT opOr_r(T)(T left)
		{
			return RT!(T).RT(left);
		}
	}

	mixin ("alias opStruct " ~ name ~ ";");
}
