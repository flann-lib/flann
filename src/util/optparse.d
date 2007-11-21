/*
Project: nn
*/

/**
 * Parses UNIX/GNU-ish command lines in a extensible object-oriented
 * manner.
 *
 * The parser in this module supports command lines made up of long
 * options, short options, arguments and positional arguments, and
 * is $(I loosely) based on the <tt>optparse</tt> module from Python.
 *
 * Long options are of the form <tt>--NAME</tt>, <tt>--NAME=ARG</tt> or
 * <tt>--NAME ARG</tt> where <tt>ARG</tt> is only neccecary if the option
 * takes an argument.  Arguments that $(I optionally) take an argument are
 * not supported.
 *
 * Short options are of the form <tt>-C</tt> or
 * <tt>-C ARG</tt> where <tt>C</tt> is the option's "short name", which
 * should be a string containing one character (although this is never
 * enforced).  The semantics of <tt>ARG</tt> are the same as with long
 * options.  Concatenating short options together (ie: <tt>-xvzf</tt>
 * as opposed to <tt>-x -v -z -f</tt>) is not supported at this time.
 *
 * Positional arguments are simply arguments that are not consumed by
 * long or short options which take an argument.
 *
 * There is also one special long option: <tt>--</tt>.  This will force
 * all further arguments to be interpreted literally as positional
 * arguments.
 *
 * It is also worth noting that this module $(I does not) do any form
 * of escaping, quoting, etc.
 *
 * Authors: Daniel Keep, daniel.keep+public@gmail.com
 * Date: 2006-04-15
 * Copyright: Copyright \&copy; 2006 Daniel Keep
 * Version: 0.1
 * License: BSD v2
 * 
 * Examples:
 * ------------------------------------------------------------
 *  import optparse;
 *  import std.stdio;
 *  import std.string;
 *
 *  void main(char[] argv)
 *  {
 *      // Create our option parser
 *      auto optParser = new OptionParser();
 *      
 *      // Now define some options
 *      auto optDebug = new NumericOption!(uint)(
 *              "d", "debugLevel", "DebugLevel", 0u, "LEVEL");
 *      auto optMessage = new StringOption(
 *              "m", "message", "Message", "Hello, World!", "MSG");
 *      auto optVerbose = new BoolOption(
 *              "v", "verbose", "Verbose", false);
 *      auto optHelp = new FlagTrueOption(
 *              "?", "help", "ShowHelp");
 *
 *      // Next, set some help messages
 *      optDebug.helpMessage = "Set the program's debug level";
 *      optMessage.helpMessage = "Message to display";
 *      optVerbose.helpMessage = "Enable/disable verbose output mode";
 *      optHelp.helpMessage = "This message";
 *
 *      // Next, add these options to the parser
 *      optParser.addOption(optDebug);
 *      optParser.addOption(optMessage);
 *      optParser.addOption(optVerbose);
 *      optParser.addOption(optHelp);
 *
 *      // Now we can finally parse our own command line.  Notice that
 *      // we do NOT pass argv[0], since this is the executable's path.
 *      optParser.parse(argv[1..$]);
 *
 *      // Check to see if --help was supplied
 *      if( unbox!(bool)(optParser["ShowHelp"]) )
 *      {
 *          writefln("Usage: optparse [OPTIONS] FILES");
 *          writefln("");
 *          optParse.showHelp();
 *          writefln("");
 *      }
 *
 *      // Display verbosity setting
 *      writefln("Verbose: %s", toString(unbox!(bool)(optParser["Verbose"])));
 *
 *      // Display debug level
 *      writefln("Debug level: %d", unbox!(uint)(optParser["DebugLevel"]));
 *
 *      // Display message
 *      writefln("Message: %s", unbox!(char[])(optParser["Message"]));
 *
 *      // Display other 'positional' arguments
 *      if( optParser.positionalArgs.length > 0 )
 *      {
 *          writefln("\nPositional arguments:");
 *          foreach( int n, char[] arg; optParser.positionalArgs )
 *              writefln("  %4s: %s", "[%d]".format(n), arg);
 *      }
 *
 *      return 0;
 *  }
 * ------------------------------------------------------------
 *
 * History:
 * $(DL
 *  $(DT 0.1)
 *  $(DD First release)
 * )
 *
 */

module util.optparse;

private
{
/+    import std.conv;
    import std.stdio;
    import std.string;+/
	import tango.io.Stdout;
	import tango.core.Array;
	import tango.util.Convert;
	import tango.text.Ascii;
	
	import util.variant;
}

/**
 * The main class used to process command-line arguments.
 */
class OptionParser
{
    private
    {
        Option[] _options;
        Variant[char[]] _values;
        char[][] _positionalArgs;
    }
    
    /**
     * Adds an option object to the parser.
     */
    void addOption(Option option)
    in
    {
        assert(option !is null);
    }
    body
    {
        // Check that the option's short and long names
        // are unique.
        if( findByShortName(option.shortName) !is null )
            throw new DuplicateOptionShortName(option.shortName);
        if( findByLongName(option.longName) !is null )
            throw new DuplicateOptionLongName(option.longName);
        
        // Pull out default value.
        _values[option.valueName] = option.defaultValue;
        
        // Add to array of options.
        _options ~= option;
    }

    /**
     * Locates an Option object by its short name.
     */
    Option findByShortName(char[] shortName)
    in
    {
        assert(shortName !is null);
    }
    body
    {
        foreach( Option option; options )
            if( option.shortName == shortName )
                return option;
        return null;
    }

    /**
     * Locates an Option object by its long name (which may
     * include inline arguments).
     */
    Option findByLongName(char[] longName)
    in
    {
        assert(longName !is null);
    }
    body
    {
        foreach( Option option; options )
        {
            if( option.takesArgument )
            {
                // Need to look for options that have an inline
                // argument.
                int eqPos = longName.find('=');
                if( eqPos > -1 )
                    if( option.longName == longName[0..eqPos] )
                        return option;
            }

            if( option.longName == longName )
                return option;
        }
        
        return null;
    }

    /**
     * Parses the supplied command line arguments.
     */
    void parse(char[][] argv)
    in
    {
        assert(argv !is null);
    }
    body
    {
        char[] arg;
        Option opt;
        bool suppressOptions = false;
        
        // Note that we DO NOT skip the first argument--they'll just have
        // to pass us argv[1..$] :)
        for( int i=0; i<argv.length; i++ )
        {
            arg = argv[i];

            if( arg == "--" && !suppressOptions )
                // First, check to see if the arg is just "--": if so,
                // disable further option checking.
                suppressOptions = true;

            else if( arg.length > 2 && arg[0..2] == "--" && !suppressOptions )
            {
                // Ok, failing that, check to see if this is a valid long
                // option (--OPTION)
                opt = findByLongName(arg[2..$]);
                if( opt is null )
                    // Uh oh... can't find that option--barf
                    throw new InvalidOption(arg);
                
                else
                {
                    // Found it: now either parse its argument, or flag
                    // its value.
                    if( opt.takesArgument )
                    {
                        // The option's name and argument.
                        char[] optName = arg;
                        char[] argument = null;

                        // See if there's an '=' in the option.
                        int eqPos = arg.find('=');

                        if( eqPos > -1 )
                        {
                            optName = arg[0..eqPos];
                            argument = arg[eqPos+1..$];
                        }
                        else if( i+1 < argv.length )
                        {
                            argument = argv[i+1];
                            i++;
                        }
                        else
                            // Argument isn't in the option itself, and we haven't
                            // got any more arguments on the command line... user
                            // screwed up!
                            throw new MissingOptionArgument(optName, opt.argumentName);

                        // Ok, by this point we should have the option's
                        // argument--try to parse it.
                        try
                        {
                            _values[opt.valueName] = opt.parse(argument);
                        }
                        catch( CannotParseArgument e )
                        {
                            throw new InvalidOptionArgument(optName, argument);
                        }
                    }
                    else
                        // Otherwise, this is a flag-style option.
                        _values[opt.valueName] = opt.flag();
                }
            }

            else if( arg.length > 1 && arg[0..1] == "-" && !suppressOptions )
            {
                // Fine, try for a short option instead
                opt = findByShortName(arg[1..$]);
                if( opt is null )
                    // Can't find this one: barf
                    throw new InvalidOption(arg);

                else
                {
                    // Found it: now either parse its argument, or flag
                    // its value.
                    if( opt.takesArgument )
                    {
                        // Option name and argument.  These aren't relly needed
                        // YET, but they will become useful if we ever try to
                        // parse shorthand strings of short options (ie:
                        // "-xvzf" instead of "-x -v -z -f").
                        char[] optName = arg;
                        char[] argument = null;
                        
                        if( i+1 < argv.length )
                        {
                            argument = argv[i+1];
                            i++;
                        }
                        else
                            throw new MissingOptionArgument(arg, opt.argumentName);

                        // Ok, try to parse
                        try
                        {
                            _values[opt.valueName] = opt.parse(argument);
                        }
                        catch( CannotParseArgument e )
                        {
                            throw new InvalidOptionArgument(optName, argument);
                        }
                    }
                    else
                        // Doesn't have an argument--just flag it.
                        _values[opt.valueName] = opt.flag();
                }
            }

            else
            {
                // Ok, it's just a positional argument
                _positionalArgs ~= arg;
            }
        }
    }

    /**
     * Displays all known options, if they take an argument, and
     * their help message (if one has been provided).
     */
    void showHelp(int indentWidth=30, char[] leadingIndent="  ")
    {
        foreach( Option option; options )
        {
            char[] optSyntax = leadingIndent;

            if( option.longName )
                optSyntax ~= "--" ~ option.longName;
            if( option.longName && option.shortName )
                optSyntax ~= ", ";
            if( option.shortName )
                optSyntax ~= "-" ~ option.shortName;

            if( option.takesArgument )
                optSyntax ~= " " ~ option.argumentName;

            optSyntax ~= " ";

            if( optSyntax.length > indentWidth && option.helpMessage.length > 0 )
                Stdout.format("{}\n{,"~to!(char[])(indentWidth)~"}", optSyntax, " ");
            
            else
                Stdout.format("{,-"~to!(char[])(indentWidth)~"}", optSyntax);
            
            Stdout(option.helpMessage).newline;
        }
    }

    /**
     * Returns the boxed value stored under the given key.
     */
    Variant opIndex(char[] key)
    in
    {
        assert(key !is null);
    }
    body
    {
        return _values[key];
    }

    /**
     * Changes the boxed value stored under the given key.
     */
    void opIndexAssign(T)(T value, char[] key)
    in
    {
        assert(key !is null);
    }
    body
    {
        _values[key] = value;
    }

    /**
     * Returns an array of all known Option objects.
     *
     * Changes to this array will $(I not) affect the internal
     * list of known options.
     */
    Option[] options() { return _options.dup; }

    /**
     * Returns an array of positional arguments.
     *
     * Changes to this array will $(I not) affect the internal
     * list of positional arguments.
     */
    char[][] positionalArgs() { return _positionalArgs.dup; }
}

unittest
{
    //** Test duplicate option names **//
    {
        auto op = new OptionParser();
        op.addOption(new FlagTrueOption("short", "long", "value"));

        try
        {
            op.addOption(new FlagTrueOption("short", "foo", "value"));
            assert(0);
        }
        catch( DuplicateOptionShortName e ) {}
        catch( Exception e ) { assert(0); }

        try
        {
            op.addOption(new FlagTrueOption("foo", "long", "value"));
            assert(0);
        }
        catch( DuplicateOptionLongName e ) {}
        catch( Exception e ) { assert(0); }
    }

    //** Ensure that we can find options we've added, and **//
    //** that we can't find ones we haven't added.        **//
    {
        auto op = new OptionParser();
        op.addOption(new FlagTrueOption("a", "option1", "value"));
        op.addOption(new FlagTrueOption("b", "option2", "value"));
        op.addOption(new FlagTrueOption("c", "option3", "value"));
        op.addOption(new BoolOption("d", "option4", "value"));

        assert(op.findByShortName("a") !is null);
        assert(op.findByShortName("b") !is null);
        assert(op.findByShortName("c") !is null);
        assert(op.findByShortName("d") !is null);
        assert(op.findByLongName("option1") !is null);
        assert(op.findByLongName("option2") !is null);
        assert(op.findByLongName("option3") !is null);
        assert(op.findByLongName("option4") !is null);
        assert(op.findByLongName("option3=foo") is null);
        assert(op.findByLongName("option4=foo") !is null);

        // Check to make sure ones that aren't there can't be found
        assert(op.findByShortName("x") is null);
        assert(op.findByLongName("foo") is null);
    }

    //** Check we can parse a complex command line **//
    {
        auto op = new OptionParser();
        op.addOption(new FlagTrueOption("f", "flagtrue", "flagtrue"));
        op.addOption(new BoolOption("b", "bool", "bool"));
        op.addOption(new NumericOption!(int)("i", "int", "int"));
        op.addOption(new StringOption("s", "string", "string"));

        const char[][] args = [
            "-f",
            "-b","true",
            "--int","42",
            "--string=foo",
            "file1",
            "--",
            "--bool=false"
        ];

        op.parse(args);
        
        assert(unbox!(bool)(op["flagtrue"]) == true);
        assert(unbox!(bool)(op["bool"]) == true);
        assert(unbox!(int)(op["int"]) == 42);
        assert(unbox!(char[])(op["string"]) == "foo");

        const char[][] posargs1 = ["file1", "--bool=false"];
        char[][] posargs2 = op.positionalArgs();
        assert(posargs1.length == posargs2.length);
        foreach( int n, char[] arg; posargs1 )
            assert(arg == posargs2[n]);
    }
}

/**
 * This represents the definition of a single option that users
 * can provide on your program's command line.
 *
 * Options are, in an abstract sense, pieces of code that are
 * triggered when the option is encountered on the command line.
 * These pieces of code tell the option parser what value to store
 * against that option.
 *
 * Each option has a long and/or short name, which are used for
 * the <tt>--NAME</tt> and <tt>-C</tt> forms respectively.  It also
 * needs a name for the key under which its value will be stored
 * (<tt>valueName</tt>), whether it takes arguments, and a boxed
 * default value.  These values are (generally) set via the
 * constructor, and not changed afterwards.
 *
 * <tt>valueName</tt> is important because it is the key under which
 * boxed values are stored in the option parser.  These boxed values
 * are accessed using <tt>($(I OptionParser instance))[KEY]</tt>.
 *
 * Each option may also have a help message, which may be set at any
 * time.
 *
 * How an option is processed depends on the value of
 * <tt>takesArguments</tt>.  If this is false, then when the option
 * is encountered on the command line, its <tt>flag</tt> method
 * is called, which should return a boxed value.  If it is true,
 * then the <tt>parse</tt> method is called, with the option's
 * argument, and should return a boxed value.
 *
 * For examples on how this works, see the various classes derived
 * from Option in this module.
 */
abstract class Option
{
    private
    {
        char[] _shortName;
        char[] _longName;
        char[] _valueName;
        bool _takesArgument;
        char[] _argumentName;
        Variant _defaultValue;
    }

    /**
     * Message describing what the option is for.
     */
    char[] helpMessage = "";

    this(char[] shortName, char[] longName, char[] valueName,
            Variant defaultValue, char[] argumentName=null)
    {
        _shortName = shortName;
        _longName = longName;
        _valueName = valueName;
        _defaultValue = defaultValue;
        _takesArgument = (argumentName !is null);
        _argumentName = argumentName;

        assert( _shortName !is null || _longName !is null );
    }
    
    /**
     * Returns new value for this option.
     *
     * Only used by, and must be overridden for options which do not
     * take arguments.
     */
    Variant flag()
    {
        assert(0);
    }

    /**
     * Returns new value for this option, based on the supplied argument.
     *
     * Only used by, and must be overridden for options which
     * take arguments.
     */
    Variant parse(char[] argument)
    {
        assert(0);
    }

    /**
     * Compares two Option objects, based on first their long names, then
     * their short names.
     */
    int opCmp(Option o)
    {
        char[] lhsShort, lhsLong, rhsShort, rhsLong;

        lhsShort = this.shortName ? this.shortName : this.longName;
        lhsLong = this.longName ? this.longName : this.shortName;
        rhsShort = o.shortName ? o.shortName : o.longName;
        rhsLong = o.longName ? o.longName : o.shortName;
        
        int longCmp = compare(lhsLong, rhsLong);
        return ((longCmp == 0) ? compare(lhsShort, rhsShort) : longCmp);
    }

    char[] shortName() { return _shortName; }       /// This option's short name
    char[] longName() { return _longName; }         /// This option's long name
    char[] valueName() { return _valueName; }       /// Key under which this option's value will be stored.
    bool takesArgument() { return _takesArgument; } /// Does this option require an argument?
    char[] argumentName() { return _argumentName; } /// Name of the argument taken
    Variant defaultValue() { return _defaultValue; }    /// Default value if this option is not encountered
}

/**
 * This Option class defaults to <tt>false</tt>, and sets its value
 * to <tt>true</tt> when encountered.
 */
class FlagTrueOption : Option
{
    this(char[] shortName, char[] longName, char[] valueName)
    {
        super(shortName, longName, valueName, Variant(false));
    }

    Variant flag()
    {
        return Variant(true);
    }
}

unittest
{
    auto opt = new FlagTrueOption("s", "long", "value");
    assert(opt !is null);
    assert(!opt.takesArgument);
    assert(false == opt.defaultValue.get!(bool));
    assert(true == opt.flag().get!(bool));
}

/**
 * This option allows the user to set a value to either true or
 * false.  It supports a wide range of synonyms for "true" and
 * "false" (even more if you set the OptParseSilly version...).
 */
class BoolOption : Option
{
    this(char[] shortName, char[] longName, char[] valueName,
            bool defaultValue=false, char[] argumentName="VALUE")
    {
        super(shortName, longName, valueName,
                Variant(defaultValue), argumentName);
    }

    Variant parse(char[] argument)
    {
        switch(toLower(argument))
        {
            case "1":
            case "on":
            case "yes":
            case "true":
                return Variant(true);

            case "0":
            case "off":
            case "no":
            case "false":
                return Variant(false);

            version(OptParseSilly)
            {
                case "ahhuh":
                case "bringit":
                case "doit":
                case "hai":
                case "hellyeah":
                case "makeitso":
                case "ohyeah":
                    return true;

                case "nuhuh":
                case "getlost":
                case "nuu":
                case "iie":
                case "noway":
                case "belaythatorder":
                case "dontdoit":
                    return false;
            }

            default:
                throw new CannotParseArgument();
        }
    }
}

unittest
{
    auto opt = new BoolOption("s", "long", "value", true);

    alias unbox!(bool) ub;
    
    assert(opt !is null);
    assert(opt.takesArgument);
    assert(ub(opt.defaultValue) == true);
    
    const char[][] trueArgs = ["1", "on", "yes", "true"];
    const char[][] falseArgs = ["0", "off", "no", "false"];

    foreach( char[] arg; trueArgs )
        assert(ub(opt.parse(arg)) == true);
    foreach( char[] arg; falseArgs )
        assert(ub(opt.parse(arg)) == false);

    try
    {
        opt.parse("foo");
        assert(0);
    }
    catch( CannotParseArgument e )
    {
    }
    catch( Exception e )
    {
        assert(0);
    }
}

/+private
{+/
//     template toNumericType(T)
//     {
//         static assert(0);
//     }
// 
//     template toNumericType(T : byte) { alias toByte conv; }
//     template toNumericType(T : ubyte) { alias toUbyte conv; }
//     template toNumericType(T : short) { alias toShort conv; }
//     template toNumericType(T : ushort) { alias toUshort conv; }
//     template toNumericType(T : int) { alias toInt conv; }
//     template toNumericType(T : uint) { alias toUint conv; }
//     template toNumericType(T : long) { alias toLong conv; }
//     template toNumericType(T : ulong) { alias toUlong conv; }
//     
//     template toNumericType(T : float) { alias toFloat conv; }
//     template toNumericType(T : double) { alias toDouble conv; }
//     template toNumericType(T : real) { alias toReal conv; }
// }

/**
 * This templated class allows users to set options to any of
 * the built-in numeric types, except for imaginary/complex
 * floating-point types.
 */
class NumericOption(T) : Option
{
    this(char[] shortName, char[] longName, char[] valueName,
            T defaultValue=T.init, char[] argumentName="VALUE")
    {
        super(shortName, longName, valueName,
                Variant(defaultValue), argumentName);
    }

    Variant parse(char[] argument)
    {
        try
        {
            return Variant(to!(T)(argument));
        }
        catch( ConversionException e )
        {
            throw new CannotParseArgument();
        }
    }
}

private template TestNumericOption(T)
{
    template TestParse(T)
    {
        void TestParse(Option opt, T value)
        {
            assert(opt.parse(toString(value)).get!(T) == value);
        }
    }
    
    void TestNumericOption()
    {
        auto opt = new NumericOption!(T)("s", "long", "value");
        alias unbox!(T) ub;
        
        assert(opt !is null);
        assert(opt.takesArgument);
        assert(opt.defaultValue.get!(T) == T.init);
        
        TestParse!(T)(opt,T.init);
        TestParse!(T)(opt,T.min);
        TestParse!(T)(opt,T.max);

        // floating-point tests
        static if( is(T : real) )
        {
            TestParse!(T)(opt,T.infinity);
            TestParse!(T)(opt,T.nan);
        }
        
        try
        {
            opt.parse("foo");
            assert(0);
        }
        catch( CannotParseArgument e )
        {
        }
        catch( Exception e )
        {
            assert(0);
        }
    }
}

/**
 * This option allows users to set a value to any string their shell
 * is capable of passing to the program.
 */
class StringOption : Option
{
    this(char[] shortName, char[] longName, char[] valueName,
            char[] defaultValue="", char[] argumentName="VALUE")
    {
        super(shortName, longName, valueName,
                Variant(defaultValue), argumentName);
    }

    Variant parse(char[] argument)
    {
        return Variant(argument);
    }
}

unittest
{
    auto opt = new StringOption("s", "long", "value", "foo");

    assert(opt !is null);
    assert(opt.takesArgument);
    assert(opt.defaultValue.get!(char[]) == "foo");
    assert(opt.parse("bar").get!(char[]) == "bar");
}

// Because the default ctor sucks ass
private template MDummyException()
{
    this(char[] msg)
    {
        super(msg);
    }
}

/**
 * This exception indicates an unspecified error has occured
 * whilst processing the command line.
 */
abstract class OptionParserException : Exception
{
    mixin MDummyException!();
}

/**
 * Indicates that you have tried to add two Option objects
 * which share the same name.
 */
abstract class DuplicateOptionName : OptionParserException
{
    mixin MDummyException!();
}

/**
 * Indicates that you have tried to add two Option objects
 * which share the same short name.
 */
class DuplicateOptionShortName : DuplicateOptionName
{
    this(char[] shortName)
    {
        super("Short name \"" ~ shortName ~ "\" already used.");
    }
}

/**
 * Indicates that you have tried to add two Option objects
 * which share the same long name.
 */
class DuplicateOptionLongName : DuplicateOptionName
{
    this(char[] shortName)
    {
        super("Long name \"" ~ shortName ~ "\" already used.");
    }
}

/**
 * Indicates that the user has supplied an option that the
 * option parser does not recognise.
 */
class InvalidOption : OptionParserException
{
    this(char[] optName)
    {
        super("Unknown option \"" ~ optName ~ "\".");
    }
}

/**
 * Indicates that the user has supplied an invalid argument
 * to an option.
 */
class InvalidOptionArgument : OptionParserException
{
    this(char[] optName, char[] arg)
    {
        super("Invalid argument \"" ~ arg ~ "\" to option \""
                ~ optName ~ "\".");
    }
}

/**
 * Means that the Option object could not parse the supplied
 * argument.
 *
 * This exception is only used internally, and is $(I always)
 * caught and re-thrown as an <tt>InvalidOptionArgument</tt>
 * exception instead (in order to provide more useful information).
 */
class CannotParseArgument : OptionParserException
{
    this()
    {
        super("Could not parse argument to option.");
    }
}

/**
 * Indicates that the user has not provided an argument to an
 * option which requires one.
 */
class MissingOptionArgument : OptionParserException
{
    this(char[] optName, char[] argName)
    {
        super("Missing required argument \""
                ~ argName ~ "\" on option \"" ~ optName ~ "\".");
    }
}

