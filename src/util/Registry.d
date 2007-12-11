module util.registry;

public import tango.core.Vararg;
import util.defines;

/*****************************************************
    
    Generic object registry

*****************************************************/


template Register(char[] name, alias Type)
{
	static this() {
		Registry.register(name,function Object(TypeInfo[] arguments, va_list argptr)
		{
			return new Type();
		});
	}
}

template RegisterSingleton(char[] name, alias Type)
{
	static this() {
		Registry.register(name,function Object(TypeInfo[] arguments, va_list argptr)
		{
			static Type obj; 
			if (obj is null ) { 
				obj =  new Type();
			}
			return obj;
		});
	}
}


final class Registry {
	private static {
		alias Object function (TypeInfo[],va_list) Creator;
		Creator[char[]] creators;
	}

	private this(){};

	public static void register(char[] name, Creator creator)
	{
		creators[name] = creator;
	}
	
	public static T get(T) (char[] name, ...)
	{
		if (name in creators) {
			return cast(T)creators[name](_arguments,_argptr);
		}
		else {
			throw new Exception("Cannot find creator for object: "~name);
		}
	}
}








