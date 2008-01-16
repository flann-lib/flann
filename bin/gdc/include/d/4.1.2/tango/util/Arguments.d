/*******************************************************************************
    copyright:  Copyright (c) 2007 Darryl Bleau. All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Oct2007
    author:     Darryl B, Jeff D
    
    History:
    ---
    Date     Who           What
    Sep2006  Darryl Bleau  Original C module
    Sep2007  Jeff Davey    Ported to D, added comments.
    Oct2007  Darryl Bleau  Added validation delegates/functions, more comments.
    ---
*******************************************************************************/

/*******************************************************************************

    This module is used to parse arguments, and give easy access to them.

*******************************************************************************/

module tango.util.Arguments;

private import tango.core.Exception : TracedException;

/***********************************************************************

    This exception is thrown during argument validation.

***********************************************************************/

public class ArgumentException : TracedException
{
    /*********************************************************************** 

        The reason the exception was thrown

    ***********************************************************************/

    enum ExceptionReason
    {
        /*********************************************************************** 
          An invalid parameter was passed 
         ***********************************************************************/

        INVALID_PARAMETER,
        /*********************************************************************** 
          A parameter wasn't passed to an argument when it was expected 
         ***********************************************************************/

        MISSING_PARAMETER,
        /*********************************************************************** 
          An argument was missing 
         ***********************************************************************/

        MISSING_ARGUMENT
    }

    private char[] _name;
    private char[] _parameter;
    private ExceptionReason _reason;

    /*********************************************************************** 

      The name of the specific argument 

     ***********************************************************************/

    char[] name() { return _name; }

    /***********************************************************************

      The parameter to the argument 

     ***********************************************************************/

    char[] parameter() { return _parameter; }

    /***********************************************************************

      The enum to the reason it failed 

     ***********************************************************************/

    ExceptionReason reason() {  return _reason; }

    this(char[] msg, char[] name, char[] parameter, ExceptionReason reason)
    {
        _name = name;
        _parameter = parameter;
        _reason = reason;
        super(msg);
    }
}

/***********************************************************************

    The Arguments class is used to parse arguments and encapsulate the
    parameters passed by an application user.

    The command line arguments into an array of found arguments and their 
    respective parameters (if any).
    
    Arguments can be short (-), long (--), or implicit. Arguments can 
    optionally be passed parameters. For example, this module
    parses command lines such as: "-a -b -c --long --argument=parameter"
    
    Example:
    ---
    char[][] arguments = [ "programname", "-a:on", "-abc:on", "--this=good", "-x:on" ];
    Arguments args = new Arguments(arguments);
    if (args)
    {
        args.addValidation("b", true, false);
        args.addValidation("c", true, true);
        args.addValidation("x", false, true);
        args.addValidation("this", false, true);
        args.addValidation("this", (char[] a) { (return a.length < 5); });
        try
        {
            args.validate();
            return Test.Status.Success;
        }
        catch (ArgumentException ex)
        {
            messages ~= Stdout.layout.convert("{}: {} - {}", ex.name, ex.msg, ex.reason == ArgumentException.ExceptionReason.INVALID_PARAMETER ? "invalid parameter" : ex.reason == ArgumentException.ExceptionReason.MISSING_PARAMETER ? "missing parameter" : "missing argument");
        }
    }
    ---
    
    Syntax:
    ---
    Short Argument - -[x][:=]?[ parameter]...
    Long Argument - --[long][:=]?[ parameter]...
    Implicit Arguments - [implicitName]... Multiple implicit arguments are allowed.
    ---

    Usage:

    Short options can be grouped in a single dash. The following are equivalent.
    ---
    - "myprogram -a -b -c"
    - "myprogram -abc"
    ---

    Arguments can be passed with space, '=', or ':'. The following are equivalent.
    ---
    - "myprogram -c arg"
    - "myprogram -c=arg"
    - "myprogram -c:arg"
    ---

    As are these.
    ---
    - "myprogram --long arg"
    - "myprogram --long=arg"
    - "myprogram --long:arg"
    ---

    Arguments can contain either '=' or ':', but not both. For example. 
    the following results in the argument 'long' being set to 'arg=other' 
    and 'arg:other', respectively.
    ---
    - "myprogram --long:arg=other"
    - "myprogram --long=arg:other"
    ---

    Blank dashes are ignored. The following are all equivalent.
    ---
    - "myprogram -c -- -a"
    - "myprogram -c - -a"
    - "myprogram - - - -a -- -c"
    ---

    In the absence of implicit arguments, short options can be infered when 
    they come first. Given no implicit arguments, the following are equivalent.
    ---
    - "myprogram abc"
    - "myprogram -abc"
    - "myprogram -a -b -c"
    ---

    Short options are case sensitive, while long options are not. The following 
    are equivalent.
    ---
    - "myprogram -a -A -LONG"
    - "myprogram -a -A -Long"
    - "myprogram -a -A -long"
    ---

    In the event of multiple definitions of an argument, any parameters given 
    will be concatenated. The following are equivalent.
    ---
    - "myprogram -a one two three"
    - "myprogram -a one -a two -a three"
    - "myprogram -a:one two -a=three"
    ---
        
    Multiple parameters can be iterated through using via the opIndex operator. 
    For example, given:
    ---
    - "myprogram -collect one two three '4 5 6'"
    ---
    args["collect"] will return a char[][] array ["one", "two", "three", "4 5 6"].

    Implicit arguments can be defined by passing in an implicit arguments array, 
    which may look something like: ["first", "second"].
    Given implicit arguments, any non-argument command line parameters will be 
    automatically assigned to the implicit arguments,
    in the order they were given.
    For example, given the implicit arguments ["first", "second"] and command line:
    ---
    - "myprogram hello there bob"
    ---
    The argument 'first' will be assigned 'hello', and the argument 'second' will 
    be assigned both 'there' and 'bob'.

    Any intervening arguments will end the assignment. For example, given:
    ---
    - "myprogram hello there bob -a how are you"
    ---
    'first' is assigned 'hello', 'second' is assigned 'there' and 'bob', and 'a' 
    is assigned 'how', 'are', and 'you'.
    
    Implicit arguments also allows programs to support non-option arguments, 
    given implicit arguments ["actions"], and a command line such as:
    ---
    - "myprogram mop sweep get_coffee -time:now"
    ---
    args["actions"] will contain ["mop", "sweep", "get_coffee"], and 
    args["time"] will contain "now".

***********************************************************************/

public class Arguments
{
    /// Function used to validate multiple parameters at once.
    alias bool function(char[][] params, inout char[] invalidParam) validationFunctionMulti;
    /// Delegate used to validate multiple parameters at once.
    alias bool delegate(char[][] params, inout char[] invalidParam) validationDelegateMulti;
    /// Function used to validate single parameters at a time.
    alias bool function(char[] param) validationFunction;
    /// Delegate used to validate single parameters at a time.
    alias bool delegate(char[] param) validationDelegate;
    
    private char[][][char[]] _args;
    private char[] _program;
    private struct validation
    {
        validationFunction[] validF;
        validationDelegate[] validD;
        validationFunctionMulti[] validFM;
        validationDelegateMulti[] validDM;
        bool required;
        bool paramRequired;
    }
    private validation[char[]] _validations;

    private char[] parseLongArgument(char[] arg)
    {
        char[] rtn;

        int locate(char[] arg, char c) {
            foreach (i, a; arg)
                if (a is c)
                    return i;
            return arg.length;
        }
            

        if (arg)
        {
            int equalDelim = locate(arg, '=');
            int colonDelim = locate(arg, ':');
            int paramPos = ((equalDelim != arg.length) && (colonDelim != arg.length)) ? (equalDelim < colonDelim ? equalDelim : colonDelim) : (equalDelim != arg.length) ? equalDelim : colonDelim;
            if (paramPos != arg.length)
            {
                char[] argName = arg[0 .. paramPos];
                char[] value = arg[(paramPos + 1) .. arg.length];
                setArg(argName, value);
                rtn = argName;
            }
            else
            {
                setArg(arg, null);
                rtn = arg;
            }
        }
        return rtn;
    }

    private void setArg(char[] arg, char[] value)
    {
        if (arg)
        {
            if ((arg in _args) || (value !is null))
                _args[arg] ~= value;
            else
                _args[arg] = null;
        }
    }

    private char[] parseShortArgument(char[] arg)
    {
        char[] rtn;

        if (arg)
        {
            char[] argName;
            uint i;
            for (i = 0; i < arg.length; i++)
            {
                if (arg[i] != '=' && arg[i] != ':')
                {
                    argName = arg[i .. i + 1];
                    setArg(argName, null);
                }
                else if (((arg.length) - i) > 1)
                {
                    setArg(argName, arg[i+1 .. arg.length]);
                    break;
                }
            }
            rtn = argName;
        }
        return rtn;     
    }

    /***********************************************************************

        Allows external argument assignment, works the same as command line
        in that it appends to any values already assigned to the given key.

        Params:
            value = assigned value
            key = key to assign to

    ***********************************************************************/

    void opIndexAssign(char[] value, char[] key)
    {
        setArg(key, value);
    }

    /***********************************************************************

        Allows removal of keys from the arguments. Useful if you want to replace
        values for a given key rather than to append to them.

        Params:
            key = key to remove values from.

    ***********************************************************************/

    void remove(char[] key)
    {
        _args[key] = null;
    }
    
    /***********************************************************************

        Directly access an argument's parameters via opIndex operator as an
        array.
        This is to cover something like: param1 "parm with space" param2

    ***********************************************************************/

    char[][] opIndex(char[] key)
    {
        char[][] rtn = null;    
        if (key && (key in _args))
            rtn = _args[key];
        return rtn;
    }

    /*********************************************************************** 
      
        Operator is used to check if the argument exists

    ***********************************************************************/

    bool opIn_r(char[] key)
    {
        bool rtn = false;
        if (key)
            rtn = (key in _args) != null;
        return rtn;
    }

    /***********************************************************************

        Adds a validation to the arguments

        Params:
            argument = the argument name
            required = specifies if this argument is required
            paramRequired = specifies if this argument requires a parameter

    ***********************************************************************/

    void addValidation(char[] argument, bool required, bool paramRequired)
    {
        if (argument)
        {
            validation* val = getValidation(argument);
            if (val !is null)
            {
                val.required = required;
                val.paramRequired = paramRequired;
            }
        }
    }
    
    /***********************************************************************

        Adds a validation to the arguments

        Params:
            argument = the argument name
            validF = a validation function for single parameters

    ***********************************************************************/    

    void addValidation(char[] argument, validationFunction validF)
    {
        if (argument && validF)
        {
            validation* val = getValidation(argument);
            if (val !is null)
                val.validF ~= validF;
        }
    }

    /***********************************************************************

        Adds a validation to the arguments

        Params:
            argument = the argument name
            validD = a validation delegate for single parameters

    ***********************************************************************/    

    void addValidation(char[] argument, validationDelegate validD)
    {
        if (argument && validD)
        {
            validation* val = getValidation(argument);
            if (val !is null)
                val.validD ~= validD;
        }
    }

    /***********************************************************************

        Adds a validation to the arguments

        Params:
            argument = the argument name
            validF = a validation function for multiple parameters

    ***********************************************************************/    

    void addValidation(char[] argument, validationFunctionMulti validFM)
    {
        if (argument && validFM)
        {
            validation* val = getValidation(argument);
            if (val !is null)
                val.validFM ~= validFM;
        }
    }

    /***********************************************************************

        Adds a validation to the arguments

        Params:
            argument = the argument name
            validD = a validation delegate for multiple parameters

    ***********************************************************************/    

    void addValidation(char[] argument, validationDelegateMulti validDM)
    {
        if (argument && validDM)
        {
            validation* val = getValidation(argument);
            if (val !is null)
                val.validDM ~= validDM;
        }
    }   

    private validation* getValidation(char[] argument)
    {
        validation* rtn = null;
        if (!(argument in _validations))
        {
            validation newValidation;
            _validations[argument] = newValidation;
        }
        if (argument in _validations)
            rtn = &(_validations[argument]);
        return rtn;
    }
    
    /***********************************************************************

        Validates the parsed arguments.

        Throws ArgumentException if it finds something wrong.

    ***********************************************************************/

    void validate()
    {
        foreach(char[] argument, validation val; _validations)
        {
            if (val.required && !(argument in _args))
                throw new ArgumentException("Argument required.", argument, null, ArgumentException.ExceptionReason.MISSING_ARGUMENT);
            if (val.paramRequired && (argument in _args) && (_args[argument].length == 0))
                throw new ArgumentException("Parameter required.", argument, null, ArgumentException.ExceptionReason.MISSING_PARAMETER);
            if ((argument in _args) && (_args[argument].length > 0))
            {
                char[] invalidParameter = null;
                foreach(validationFunctionMulti validFM; val.validFM)
                    if (!validFM(_args[argument], invalidParameter))
                        break;
                if (invalidParameter is null)
                {
                    foreach(validationDelegateMulti validDM; val.validDM)
                        if (!validDM(_args[argument], invalidParameter))
                            break;
                    if (invalidParameter is null)
                    {
                        foreach(char[] arg; _args[argument])
                        {
                            foreach(validationFunction validF; val.validF)
                            {
                                if (!validF(arg))
                                {
                                    invalidParameter = arg;
                                    break;
                                }
                            }
                            if (invalidParameter is null)
                            {
                                foreach(validationDelegate validD; val.validD)
                                {
                                    if (!validD(arg))
                                    {
                                        invalidParameter = arg;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                if (invalidParameter !is null)
                    throw new ArgumentException("Invalid parameter.", argument, invalidParameter, ArgumentException.ExceptionReason.INVALID_PARAMETER);
            }
        }
    }

    /***********************************************************************
    
            Parse the arguments according to the passed implicitArg list
            and aliases.

    ***********************************************************************/


    void parse(char[][] arguments, char[][] implicitArgs, char[][][] aliases)
    {
        char[] lastArgumentSet;
        uint currentImplicitArg = 0;
        for (uint i = 1; i < arguments.length; i++)
        {
            char[] currentArgument = arguments[i];
            if (currentArgument)
            {
                if (currentArgument[0] == '-')
                {
                    if (currentArgument.length > 1)
                    {
                        if (currentArgument[1] == '-')
                        {
                            if (currentArgument.length > 2)
                                lastArgumentSet = parseLongArgument(currentArgument[2 .. currentArgument.length]); // long argument
                        }
                        else
                            lastArgumentSet = parseShortArgument(currentArgument[1 .. currentArgument.length]); // short argument
                    }
                }
                else
                {
                    char[] argName;
                    // implicit argument / previously set argument
                    if (implicitArgs && (currentImplicitArg < implicitArgs.length))
                        lastArgumentSet = argName = implicitArgs[currentImplicitArg++];
                    else
                        argName = lastArgumentSet;

                    if (argName)
                        setArg(argName, currentArgument);
                    else
                        lastArgumentSet = parseShortArgument(currentArgument);
                }
            }
        }

        if (aliases)
        {
            for (uint i = 0; i < aliases.length; i++)
            {
                bool foundOne = false;
                char[][] currentValues;
                for (uint j = 0; j < aliases[i].length; j++)
                {
                    if (aliases[i][j] in _args)
                    {
                        foundOne = true;
                        currentValues ~= _args[aliases[i][j]];
                    }
                }

                if (foundOne)
                {
                    for (uint j = 0; j < aliases[i].length; j++)
                        _args[aliases[i][j]] = currentValues;
                }
            }
        }
    }

    /***********************************************************************

        Constructor that supports all features 

        Params:
            arguments = the list of arguments (usually from main)
            implicitArgs = assigns values using these keys in order from the arguments array. 
            aliases = aliases specific arguments to each other to concat parameters. looks like aliases[0] = [ "alias1", "alias2", "alias3" ]; (which groups all these arguments together)

    ***********************************************************************/

    this(char[][] arguments, char[][] implicitArgs, char[][][] aliases)
    {
        _program = arguments[0];
        this.parse(arguments, implicitArgs, aliases);
    }

    /***********************************************************************

        Basic constructor which only deals with arguments

        Params:
            arguments = array usually from main()

    ***********************************************************************/

    this(char[][] arguments)
    {
        this(arguments, null, null);
    }


    /*********************************************************************** 

        This constructor allows implicitArgs to be set as well

        Params:
            arguments = array usually from main()
            implicitArgs = the implicit arguments

    ***********************************************************************/

    this(char[][] arguments, char[][] implicitArgs)
    {
        this(arguments, implicitArgs, null);
    }

    /***********************************************************************

        This constructor allows aliases

        Params:
            arguments = array usually from main
            aliases = the array of arguments to alias

    ***********************************************************************/

    this(char[][] arguments, char[][][] aliases)
    {
        this(arguments, null, aliases);
    }
}

/+

TODO: Either rewrite this test to not use the Test class, or resolve ticket
749 to include Test in Tango.

version(UnitTest)
{
    import tango.util.Test;
    import tango.text.Util;
    import tango.io.Stdout;
    
    unittest
    {   
        Test.Status parseTest(inout char[][] messages)
        {   
            char[][] arguments = [ "ignoreprogramname", "--accumulate", "one", "-x", "on", "--accumulate:two", "-y", "off", "--accumulate=three", "-abc" ];
            Arguments args = new Arguments(arguments);
            if (args)
            {
                if (!("ignoreprogramname" in args))
                {
                    if (join(args["accumulate"], " ") == "one two three")
                    {
                        if (args["x"][0] == "on")
                        {
                            if (("a" in args) && ("b" in args) && ("c" in args))
                                return Test.Status.Success;     
                        }
                    }
                }
            }
            return Test.Status.Failure;
        }

        Test.Status implicitParseTest(inout char[][] messages)
        {
            char[][] arguments = ["ignoreprogramname", "-r", "zero", "one two three", "four five", "-s", "six"];
            char[][] implicitArgs = [ "first", "second" ];
            Arguments args = new Arguments(arguments, implicitArgs);
            if (args)
            {
                if (!("ignoreprogramname" in args))
                {
                    if (("r" in args) && !args["r"])
                    {
                        if (args["first"][0] == "zero")
                        {
                            if (join(args["second"], " ") == "one two three four five")
                            {
                                if (args["second"] == ["one two three", "four five"])
                                {
                                    if (args["s"][0] == "six")
                                        return Test.Status.Success;
                                }
                            }
                        }
                    }
                }
            }
            return Test.Status.Failure;
        }

        Test.Status aliasParseTest(inout char[][] messages)
        {
            char[][] arguments = [ "ignoreprogramname", "abc", "-d", "-e=eee", "--eff=f" ];
            char[][][4] aliases;
            aliases[0] = [ "lettera", "a" ];
            aliases[1] = [ "letterbc", "c", "b" ];
            aliases[2] = [ "letterd", "d" ];
            aliases[3] = [ "lettere", "eff", "e" ];
            Arguments args = new Arguments(arguments, aliases);
            if (args)
            {       
                if (!("ignoreprogramname" in args) && ("letterbc" in args) && ("a" in args) && ("b" in args) &&
                        ("c" in args) && ("d" in args) && ("eff" in args))
                {
                    if (("lettera" in args) && ("letterbc" in args) && ("letterd" in args))
                    {
                        if (join(args["eff"], " ") == "f eee")
                        {
                            if (args["eff"] == ["f", "eee"])
                                return Test.Status.Success;
                        }
                    }
                }
            }
            return Test.Status.Failure;
        }

        bool testRan = false;
        bool testValidation(char[] arg)
        {
            bool rtn = true;
            if (arg.length > 5)
                rtn = false;
            testRan = true;
            return rtn;
        }
        
        Test.Status validationTest(inout char[][] messages)
        {
            char[][] arguments = [ "programname", "-a:on", "-abc:on", "--this=good", "-x:on" ];
            Arguments args = new Arguments(arguments);
            if (args)
            {
                args.addValidation("b", true, false);
                args.addValidation("c", true, true);
                args.addValidation("x", false, true);
                args.addValidation("this", false, true);
                args.addValidation("this", &testValidation);
                try
                {
                    args.validate();
                    if (testRan)
                        return Test.Status.Success;
                }
                catch (ArgumentException ex)
                {
                    messages ~= Stdout.layout.convert("{}: {} - {} ({})", ex.name, ex.msg, ex.reason == ArgumentException.ExceptionReason.INVALID_PARAMETER ? "invalid parameter" : ex.reason == ArgumentException.ExceptionReason.MISSING_PARAMETER ? "missing parameter" : "missing argument", ex.parameter);
                }
            }
            return Test.Status.Failure;
        }

        Test argTest = new Test("tetra.util.Arguments");
        argTest["Normal"] = &parseTest;
        argTest["Implicit"] = &implicitParseTest;
        argTest["Alias"] = &aliasParseTest;
        argTest["Validation"] = &validationTest;
        argTest.run;
    }
}
+/
