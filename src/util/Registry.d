/************************************************************************
 * Generic object registry.
 *
 * This module contains a generic object registry. It is used to 
 * register 'creator functions' for various objects types. Object 
 * of the correct types can be obtained later from the registry using 
 * the string they were registered with.
 * 
 *  Example:
 *  ---
 *  Registry.register("file_reporter",function Object(TypeInfo[] arguments, va_list argptr)
 *  {
 *  	if (arguments.length!=1 && typeid(char[])!=arguments[0]) {
 *  		throw new Exception("Expected 1 argument of type char[]");
 *  	}
 *  	
 *  	return new FileReporter(va_arg!(char[])(argptr));
 *  });
 *  ...
 *  //somewhere else in the program
 *  auto reporter = Registry.get!(FileReporter)("file_reporter", "output.txt");
 * ---
 * 
 * Authors: Marius Muja, mariusm@cs.ubc.ca
 * 
 * Version: 0.9
 * 
 * History:
 * 
 * License:
 * 
 *************************************************************************/
module util.Registry;

public import tango.core.Vararg;


/**
 * This is a template that can be mixed in any module and automatically
 * creates and registers a creator of a particular type.
 * Example:
 * ---
 * mixin Register!("console_reporter",ConsoleReporter);
 * ---
 */
template Register(char[] name, alias Type)
{
	static this() {
		Registry.register(name,function Object(TypeInfo[] arguments, va_list argptr)
		{
			return new Type();
		});
	}
}

/**
 * This is the same as the previous, except that a singleton object
 * instance is created.
 * Example:
 * ---
 * mixin RegisterSingleton!("console_reporter",ConsoleReporter);
 * ---
 */
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

/**
 * The registry class.
 */
final class Registry {
	private static {
		alias Object function (TypeInfo[],va_list) CreatorFunction;
		CreatorFunction[char[]] creators;
	}

	private this(){};

	/**
	 * Register a new creator function with the registry.
	 * Params:
	 *     name = name under which the creator function is registered 
	 *     creator = creator function.
	 */
	public static void register(char[] name, CreatorFunction creator)
	{
		creators[name] = creator;
	}
	
	/**
	 * Allows to get an registered object instance in a type-safe manner.
	 * Params:
	 *     name = name of the instance
	 * Returns: the object instance, null if there is no such instance in
	 * 			the registry.
	 */
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








