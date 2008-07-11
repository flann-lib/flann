/*******************************************************************************
    copyright:  Copyright (c) 2008 Darryl Bleau. All rights reserved.
    license:    BSD style: $(LICENSE)
    version:    Feb2008
    author:     Darryl B, Jeff D
    
    History:
    ---
    Date     Who           What
    Sep2006  Darryl Bleau  Original C module
    Sep2007  Jeff Davey    Ported to D, added comments.
    Oct2007  Darryl Bleau  Added validation delegates/functions, additional 
                             comments.
    Feb2008  Darryl Bleau  Entirely rewritten, addressing issues brought up 
                             with initial design.
    ---
*******************************************************************************/

/*******************************************************************************
Arguments is a module for parsing argument strings, such as command line 
arguments passed to main(). It is an extrememly flexible module, able to 
accomodate a wide variety of desired parsing behavior. Arguments follows a 
declarative paradigm, requiring the programmer to tell it some basic information
about the arguments and any possible parameters. However, it also will parse a 
given string using a default set of actions that covers most basic use cases.
*******************************************************************************/

module tango.util.Arguments;

import tango.text.Util;

/*******************************************************************************
    The Arguments class is used to parse a given argument string, and 
    encapsulate all found arguments and parameters. For example, this module 
    parses command line strings such as: "-a -b -c --long --argument=parameter".

    Arguments can be short or long, and can optionally be passed parameters. 
    Parameters can also be passed implicitly (that is, not belonging to a 
    particular argument).

    Example:
    ---
    char[][] cmdl = ["programname", "-z", "--lights:off", "-zz"];
    Arguments args = new Arguments(cmdl[1..$]);
    if ((args.contains("lights")) && (args["lights"].length))
    {
        if (args["lights"] == "off")
            lights.enabled = false; // turn the lights off
        sleep(args.count("z")); // sleep for the indicated period
    }
    ---
    
    Terminology:
    ---
    - Short Argument: Single character arguments, potentially grouped under a 
          single prefix. (-a, -abc)
    - Long Argument: Multiple character arguments, always contained under 
          their own prefix. (--file, --help)
    - Parameter: A parameter to a particular argument, identified by a 
          parameter delimiter or whitespace with no prefix (--arg=parameter, -arg parameter)
    - Implicit Parameter: A given parameter that doesn't match to a particular 
          argument, accessible using the null index (args[null]). (file1.txt file2.txt)
    ---

    Behavior:

    Default:

    Arguments defaults to a basic parse behavior which provides for handling 
    of most common argument strings. You can invoke this default parse behavior
    by simply passing the argument string to the class constructor.

    Short Arguments can be grouped under a single prefix. The following are 
    equivalent.
    ---
    - "-a -b -c"
    - "-abc"
    ---

    Argument Parameters can be identified via being space-separated from their 
    argument, or via either a '=' or a ':'. The following are equivalent.
    ---
    - "-c arg"
    - "-c=arg"
    - "-c:arg"
    ---

    Only the first found parameter will be skipped over as a delimiter. The 
    following are equivalent.
    ---
    - "-c =blah"
    - "-c==blah"
    - "-c:=blah"
    ---

    Empty prefixes are ignored. The following are equivalent.
    ---
    - "-c -- -a"
    - "-c - -a"
    - "- - - - -a -- -c"
    ---

    Multiple parameters to a particular argument are appended to the array for 
    that argument. The following are equivalent.
    ---
    - "-a one two three"
    - "-a one -a two -a three"
    - "-a:one two -a=three"
    ---

    Implicit parameters are assigned to the [null] index of the class.
    ---
    - "file1 file2 file3"
    ---

    Defined:

    Accepted arguments and the particular behavior to apply to them can be 
    defined via the .define method. .define returns a Arguments.Definition, 
    which can then be chained with additional methods for further definition.
    The prefixes for both short and long arguments can be overwritten or 
    appended to, as can the parameter delimiters, by setting the .prefixLong, 
    .prefixShort, and/or delimiters arrays as appropriate.
    
    Null prefixes can be used to specify 'word sentence' behavior.
    ---
    args.prefixLong = [null];
    ---

    Will parse each of the items as if they were Arguments prefixed with "--" 
    in the default behavior.
    ---
    myProgram one two three
    ---

    Null delimiters can be used to specify 'arguments smushed up with 
    parameters' behavior.
    ---
    args.define("f").parameters.delimiters([null]);
    ---

    Will parse the following as args["f"] = ["file"].
    ---
    myProgram -ffile
    ---

    You can also define argument aliases.
    ---
    args.define("a").aliases(["b"]);
    ---

    Given that, the following would be equivalent.
    ---
    - "-a"
    - "-b"
    ---

    You can also specify that an argument has default parameters.
    ---
    args.define("x").defaults(["hello"]);
    ---

    In which case, the following would be equivalent.
    ---
    - "-a -x hello"
    - "-a"
    ---

    Finally, you may also specify limiting behavior, that a particular argument
    is required, conflicts with another argument, requires another argument, 
    that a callback should be called when encountering the argument, or that a 
    particular validation routine should be called on all defined parameters 
    for an argument.
    ---
    args.define("x").required;
    args.define("x").conflicts("b");
    args.define("x").requires("a");
    args.define("x").callback( ... );
    args.define("x").validation( ... );
    ---

    Note that requires and conflicts are order-sensitive, if you want, for 
    example, "a" and "b" to be mutually exclusive, you would need to define 
    that explicitly.
    ---
    args.define("a").conflicts("b");
    args.define("b").conflicts("a");
    ---

    Samples:

    Sample definitions (tar-like).
    ---
    args.prefixShort = [null];
    args.define("f").parameters;
    args.define("v");
    args.define("x");
    args.define("z");
    args.parse(["zxfv", "file1.tar", "file2.tar"]);
    ---

    Sample definitions (dsss-like).
    ---
    args.prefixLong = [null];
    args.define("net").parameters(0,2);
    args.parse(["net", "install", "tango"]);
    ---

    Sample definitions (ls-like).
    ---
    args.define("a");
    args.define("l");
    args.parse(["-al", "blah.txt"]);
    args.parse(["blah.txt", "-al"]);
    ---

    Sample definitions (complex).
    ---
    args.define("x").defaults(["on"]).aliases(["X"]).conflicts("a").requires("b").required;
    args.define("C").callback(delegate void(char[] n, char[] p){ ... });
    args.define("V").validation(delegate bool(char[][] p, out char[] ip){ ... });
    ---
    
    Ideas:
    Some thoughts about future progression of the module.
    ---
    -Forcing arguments to lowercase. (define("x").lowercase, -X gives "x" in args)
    -User defined callback when encountering an undefined argument.
    -Standard help text generation
    ---
*******************************************************************************/

public class Arguments
{
	/// All Arguments exceptions are derived from this
	class ParseException : Exception
	{
		private char[] _argument;
		/// The name of the particular argument
		char[] argument() { return _argument; }
		this(char[] msg, char[] argument)
		{
			_argument = argument;
			super(msg);
		}
	}

	/// Thrown when a parameter for a given argument is determined to be invalid
	class InvalidParameterException : ParseException
	{
		private char[] _parameter;
		/// The invalid parameter
		char[] parameter() { return _parameter; }
		this(char[] msg, char[] argument, char[] parameter)
		{
			_parameter = parameter;
			super(msg, argument);
		}
	}

	/// Thrown when the minimum defined number of parameters for a given 
    /// argument are not discovered
	class InsufficientParameterException : ParseException
	{
		private int _count;
		private int _expected;
		/// The discovered parameter count
		int count() { return _count; }
		/// The expected parameter count
		int expected() { return _expected; }
		this(char[] msg, char[] argument, int count, int expected)
		{
			_count = count;
			_expected = expected;
			super(msg, argument);
		}
	}

	/// Thrown when a previously discovered argument was defined to conflict 
    /// with this one
	class ConflictingArgumentException : ParseException
	{
		private char[] _conflict;
		/// The name of the conflicting argument
		char[] conflict() { return _conflict; }
		this(char[] msg, char[] argument, char[] conflict)
		{
			_conflict = conflict;
			super(msg, argument);
		}
	}

	/// Thrown when an argument requires a previously defined argument which 
    /// was not discovered
	class MissingPrerequisiteException : ParseException
	{
		private char[] _requirement;
		/// The name of the missing prerequisite argument
		char[] requirement() { return _requirement; }
		this(char[] msg, char[] argument, char[] requirement)
		{
			_requirement = requirement;
			super(msg, argument);
		}
	}

	/// Thrown when an argument is defined as being required but is not 
    /// discovered
	class MissingArgumentException : ParseException
	{
		this(char[] msg, char[] argument)
		{
			super(msg, argument);
		}
	}

    private char[][][char[]] _args;
    private char[][char[]] _aliases;
    private int[char[]] _count;

	private class Parameters
	{
		char[][] opIndex(char[] key)
		{
			char[][] rtn = null;
			if (key in _args)
				rtn = _args[key];
			return rtn;
		}
	}
	/// Provides char[][] access of all discovered parameters for a particular
    /// argument (via .parameters["argName"])
	Parameters parameters;

    /// Delegate intended to be called back when the defined argument is 
    /// discovered.
    alias void delegate(char[] name, char[] parameter) argumentCallback;
    /// Delegate to be used to perform validation on all parameters given for 
    /// the defined argument.
    alias bool delegate(char[][] parameters, out char[] invalidParameter) argumentValidation;

    /// This class represents the definition of one particular argument.
    class Definition
    {
        private char[] _name;
        /// The name of the particular argument.
        char[] name() { return _name; }
        private int _parameterMin;
        /// The defined minumum number of parameters this argument requires.
        int parameterMin() { return _parameterMin; }
        private int _parameterMax;
        /// The defined maximum number of parameters this argument will consume.
        int parameterMax() { return _parameterMax; }
        private bool _isRequired;
        /// Whether this argument is required.
        bool isRequired() { return _isRequired; }
        private char[][] _definedDelimiters;
        /// A set of defined parameter delimiters for this argument.
        char[][] definedDelimiters() { return _definedDelimiters; }
        private char[][] _definedAliases;
        /// A set of defined aliases for this argument.
        char[][] definedAliases() { return _definedAliases; }
        private char[][] _definedConflicts;
        /// A set of defined conflicting arguments to this argument. Note that 
        /// this is order-sensitive.
        char[][] definedConflicts() { return _definedConflicts; }
        private char[][] _definedPrerequisites;
        /// A set of defined required arguments to this argument. Note that 
        /// they are also order-sensitive.
        char[][] definedPrerequisites() { return _definedPrerequisites; }
        private argumentCallback[] _callbacks;
        /// A set of defined callback functions to be called when this argument
        /// is discovered.
        argumentCallback[] callbacks() { return _callbacks; }
        private argumentValidation[] _validations;
        /// A set of defined validation functions to be called on the 
        /// parameters for this argument.
        argumentValidation[] validations() { return _validations; }
        private char[][] _defaultParameters;
        /// A set of default parameters that will represent this argument if 
        /// it is not discovered during parsing.
        char[][] defaultParameters() { return _defaultParameters; }

        /// Defines both a minumum and maximum number of parameters that this
        /// argument will take. Set max to -1 for unlimited.
        Definition parameters(int min, int max)
        {
            this._parameterMin = min;
            this._parameterMax = max;
            return this;
        }

        /// Defines a definite number of parameters that this argument must 
        /// take, implies both min and max of the given requirement.
        Definition parameters(int req)
        {
            this._parameterMin = req;
            this._parameterMax = req;
            return this;
        }

        // Defines that this argument will consume any and all parameters 
        /// following it that don't belong to another argument.
        Definition parameters()
        {
            this._parameterMin = 0;
            this._parameterMax = -1;
            return this;
        }

        /// Sets the default parameters that will be assigned to this argument 
        /// if it is not discovered during parsing.
        Definition defaults(char[][] defaultParameters)
        {
            this._defaultParameters = defaultParameters;
            return this;
        }

        /// Sets the set of valid delimiters for this argument. Set to [null] 
        /// for '-ffile' behavior. Supercedes any defined Arguments.delimiters, 
        /// for this argument only.
        Definition delimiters(char[][] delimiters)
        {
            this._definedDelimiters ~= delimiters;
            return this;
        }

        /// Defines that this argument must be discovered during parsing.
        Definition required()
        {
            this._isRequired = true;
            return this;
        }

        /// Defines a set of aliases which will also correspond to this argument. 
        /// Note that only the root defined argument is accessible via the 
        /// Arguments index[] following parse.
        Definition aliases(char[][] aliases)
        {
            this._definedAliases ~= aliases;
            foreach(char[] thisAlias; aliases)
                _aliases[thisAlias] = this.name;
            return this;
        }

        /// Defines a set of arguments which, if found before this one is 
        /// discovered, will conflict with this one. Note that for mutually 
        /// exclusive conflicts, you need to declare both directions.
        Definition conflicts(char[][] conflictingArguments)
        {
            this._definedConflicts ~= conflictingArguments;
            return this;
        }

        /// Defines a set of arguments which must be discovered before this 
        /// one is.
        Definition prerequisites(char[][] requiredArguments)
        {
            this._definedPrerequisites ~= requiredArguments;
            return this;
        }

        /// Defines a callback function that will be called when this argument 
        /// is discovered.
        Definition callback(argumentCallback cb)
        {
            this._callbacks ~= cb;
            return this;
        }

        /// Defines a validation function which will be called on any and all 
        /// found parameters for this argument.
        Definition validation(argumentValidation av)
        {
            this._validations ~= av;
            return this;
        }

        /***********************************************************************
        Constructor
        Params:
            name = name of this argument.
        ***********************************************************************/
        this(char[] name)
        {
            this._name = name;
        }
    }
    /// A set of defined argument Definitions, indexed by their respective name.
    Definition[char[]] definitions;

    /// The set of prefixes which define a short argument.
    char[][] prefixShort = ["-"];
    /// The set of prefixes which define a long argument.
    char[][] prefixLong = ["--"];
    /// The set of delimiters which identify a parameter to an argument.
    char[][] delimiters = [":", "="];

    private char[][]* _prefixCompare(char[] candidate, char[][][] prefixes, out char[]* prefix)
    { // returns the prefix array that contains the longest prefix match for our 
      // candidate, and sets out var to the matching prefix.
        char[][]* rtn = null;
        char[]* matchingPrefix = null;
        for (uint p = 0; p < prefixes.length; p++)
        {
            for (uint i = 0; i < prefixes[p].length; i++)
            {
                if (candidate.length >= prefixes[p][i].length)
                {
                    if (prefixes[p][i] == candidate[0..(prefixes[p][i].length)])
                    {
                        if ((matchingPrefix is null) || (prefixes[p][i].length > (*matchingPrefix).length))
                        {
                            matchingPrefix = &prefixes[p][i];
                            rtn = &prefixes[p];
                            break;
                        }
                    }
                }
            }
        }
        prefix = matchingPrefix;
        return rtn;
    }

    private void _addArgument(char[] argumentName, char[][]* seenArguments, int* unsatisfiedParameters)
    { // adds the argument, increments the unsatisfied count if required, and 
      // calls any configured callbacks for this argument.
        char[] thisArgument;
        if (argumentName in _aliases)
            thisArgument = _aliases[argumentName];
        else
            thisArgument = argumentName.dup;
        this[thisArgument] = null;
        _count[thisArgument] = (thisArgument in _count) ? _count[thisArgument] + 1 : 1;
        *seenArguments ~= thisArgument;

        auto argDefinition = (thisArgument in definitions);
        if (argDefinition !is null)
        {
            if (*unsatisfiedParameters != -1)
            {
                int parameterCount;
                char[][] theseParameters = *(thisArgument in _args);
                if (theseParameters !is null)
                    parameterCount = theseParameters.length;

                if (argDefinition.parameterMax == -1)
                    *unsatisfiedParameters = -1;
                else if (parameterCount < argDefinition.parameterMax)
                    *unsatisfiedParameters += (argDefinition.parameterMax - parameterCount);
            }
            foreach (cb; argDefinition.callbacks)
                cb(thisArgument, null);
            if (argDefinition.definedConflicts.length)
            {
                foreach(char[] conflict; argDefinition.definedConflicts)
                {
                    if (conflict in _args)
                    	throw new ConflictingArgumentException("Argument conflicts with previously a discovered argument.", thisArgument, conflict);
                }
            }
            if (argDefinition.definedPrerequisites.length)
            {
                foreach(char[] requirement; argDefinition.definedPrerequisites)
                {
                    if (!(requirement in _args))
                    	throw new MissingPrerequisiteException("Argument requires a prerequisite argument which was not discovered.", thisArgument, requirement);
                }
            }
        }
    }

    private void _addParameter(char[] parameter, char[][]* seenArguments, int* unsatisfiedParameters)
    { // adds this parameter to the appropriate argument, and also calls any configured callbacks.
        char[] argumentName;
        if (definitions.length == 0)
        {
            if ((*seenArguments).length)
                argumentName = (*seenArguments)[$-1];
        }
        else
        {
            for (uint p = seenArguments.length; p > 0; p--)
            {
                auto argDefinition = ((*seenArguments)[p-1] in definitions);
                if (argDefinition !is null)
                {
                    int parameterCount;
                    char[][] theseParameters = *((*seenArguments)[p-1] in _args);
                    if (theseParameters !is null)
                        parameterCount = theseParameters.length;
                        
                    if ((argDefinition.parameterMax == -1) || (parameterCount < argDefinition.parameterMax))
                    {
                        argumentName = (*seenArguments)[p-1];
                        if (*unsatisfiedParameters != -1)
                            (*unsatisfiedParameters)--;
                    }
                    foreach(cb; argDefinition.callbacks)
                        cb((*seenArguments)[p-1], parameter);
                }
                else
                    argumentName = (*seenArguments)[p-1];
                if (argumentName !is null)
                    break;
            }
        }
        this[argumentName] = parameter.dup;
    }

    private int _locateDelimiter(char[] argString, out char[]* delimiter)
    { // finds the delimiter closest to the start of the string, returns parameter start index
        char[][] thisDelimiters;
        char[] overrideArgument;
        for (uint i = 1; i <= argString.length; i++)
        {
            auto thisDefinition = (argString[0..i] in definitions);
            if (thisDefinition && thisDefinition.definedDelimiters.length)
            {
                overrideArgument = argString[0..i];
                thisDelimiters = thisDefinition.definedDelimiters;
                break;
            }
        }
        if (thisDelimiters is null)
            thisDelimiters = delimiters;
            
        int rtn = argString.length;
        for (uint i = 0; i < thisDelimiters.length; i++)
        {
            if (thisDelimiters[i] !is null)
            {
                int loc = locatePattern(argString, thisDelimiters[i]);
                if (loc < rtn)
                {
                    rtn = loc;
                    delimiter = &thisDelimiters[i];
                }
            }
            else
            {
                if (overrideArgument !is null)
                {
                    rtn = overrideArgument.length;
                    delimiter = &thisDelimiters[i];
                }
                else
                {
                    for (uint j = 1; j <= argString.length; j++)
                    {
                        if (argString[0..j] in definitions)
                        {
                            rtn = j;
                            delimiter = &thisDelimiters[i];
                        }
                    }
                }
            }
        }
        return rtn;
    }

    /*******************************************************************************
    Parse the passed command line string according to the defined behavior.
    Params:
        cmdl: command line string.
    *******************************************************************************/
    void parse(char[][] cmdl)
    { // performs the magic, and also processes any argument validation for defined arguments.
        char[][] seenArguments;
        int unsatisfiedParameters;
        for (uint i = 0; i < cmdl.length; i++)
        {
            char[]* prefix;
            char[][]* prefixMatch = _prefixCompare(cmdl[i], [prefixShort, prefixLong], prefix);
            if (((prefixMatch !is null) && (*prefixMatch !is null)) && ((*prefix !is null) || !unsatisfiedParameters))
            {
                if (cmdl[i].length > (*prefix).length)
                {
                    char[]* delimiter;
                    int parameterStart = (_locateDelimiter(cmdl[i][(*prefix).length..$], delimiter) + (*prefix).length);
                    if (parameterStart != (*prefix).length)
                    {
                        if (*prefixMatch is prefixShort)
                        {
                            for (uint p = (*prefix).length; p < parameterStart; p++)
                                _addArgument(cmdl[i][p..p+1], &seenArguments, &unsatisfiedParameters);
                        }
                        else if (*prefixMatch is prefixLong)
                            _addArgument(cmdl[i][(*prefix).length..parameterStart], &seenArguments, &unsatisfiedParameters);
                    }
                    if ((delimiter !is null) && (parameterStart < (cmdl[i].length - (*delimiter).length)))
                        _addParameter(cmdl[i][parameterStart+(*delimiter).length..$], &seenArguments, &unsatisfiedParameters);
                }
            }
            else
                _addParameter(cmdl[i], &seenArguments, &unsatisfiedParameters);
        }
        foreach(char[] argName, Definition argDefinition; definitions)
        {
            if ((!(argName in _args)) && argDefinition.defaultParameters.length)
                _args[argName] = argDefinition.defaultParameters;
            if (argName in _args)
            {
                char[][] argParameters = *(argName in _args);
                if (argParameters !is null)
                {
                    if ((argDefinition.parameterMin > 0) && (argParameters.length < argDefinition.parameterMin))
                    	throw new InsufficientParameterException("Minimum number of parameters for argument not discovered.", argName, argParameters.length, argDefinition.parameterMin);
                    foreach(argValidation; argDefinition.validations)
                    {
                        char[] invalidParameter;
                        if (!argValidation(argParameters, invalidParameter))
                        	throw new InvalidParameterException("Argument parameter is invalid.", argName, invalidParameter);
                    }                
                }
                else if (argDefinition.parameterMin > 0)
                	throw new InsufficientParameterException("Argument requires parameter(s) but none were discovered.", argName, 0, argDefinition.parameterMin);
            }
            else if (argDefinition.isRequired)
            	throw new MissingArgumentException("Argument is required but was not discovered.", argName);
        }
    }

    /*******************************************************************************
    Provides for querying if a particular argument is contained
    Params:
        key: the key to query for.
    *******************************************************************************/
	bool contains(char[] key)
	{
		return ((key in _args) !is null);
	}

    /*******************************************************************************
    Provides access to the first found parameter for the given argument.
    Params:
        key: the argument to return the first found parameter for.
    *******************************************************************************/
    char[] opIndex(char[] key)
    {
        char[] rtn = null;
        if ((key in _args) && (_args[key].length > 0))
            rtn = _args[key][0];
        return rtn;
    }

    /*******************************************************************************
    Allows assignment to the parameter array for a particular argument.
    Params:
        value: the value to assign
        key: the key to assign to
    *******************************************************************************/
    void opIndexAssign(char[] value, char[] key)
    {
        if (value !is null)
            _args[key] ~= value;
        else if (!(key in _args))
            _args[key] = null;
    }

    /***************************************************************************
    Resets the found argument and parameters. Does not reset defined prefixes 
    or delimiters.
    ***************************************************************************/
    void reset()
    {
        _args = null;
    }

    /***************************************************************************
    Removes a given argument and all of it's found parameters.
    Params:
        key: the argument to remove
    ***************************************************************************/
    void remove(char[] key)
    {
        _args.remove(key);
    }

    /***************************************************************************
    Returns a count which represents the number of times the argument was 
    discovered during parsing.
    Params:
        name: The argument name.
    ***************************************************************************/
    int count(char[] name)
    {
        int rtn;
        if (name in _count)
            rtn = _count[name];
        return rtn;
    }

    /***************************************************************************
    Provides for definition of a particular argument. Returns the Definition 
    for the argument which can be used for call chaining.
    Can be called multiple times for the same argument without overwriting any 
    previous definition.
    Params:
        name: The name of the argument.
    ***************************************************************************/
    Definition define(char[] name)
    { // base method for defining arguments, used to chain other argument aspects.
        Definition rtn;
        if (name !is null)
        {
            if (!(name in definitions))
            {
                auto thisDefinition = new Definition(name);
                definitions[name] = thisDefinition;
            }
            rtn = definitions[name];
        }
        return rtn;
    }

    /***************************************************************************
    Constructor which parses a given command line string.
    Params:
        cmdl: The command line string.
    ***************************************************************************/
    this(char[][] cmdl)
    {
        parse(cmdl);
        this();
    }

    /***************************************************************************
    Constructor.
    ***************************************************************************/
    this()
    {
    	parameters = new Parameters;
    }
}

debug(UnitTest)
{
	unittest
	{
		auto args = new Arguments(["implicit", "-a", "1", "--b", "2", "3"]);
		assert(args[null] == "implicit");
		assert(args.contains("a"));
		assert(args.contains("b"));
		assert(!args.contains("x"));
		assert(args["a"]);
		assert(!args["x"]);
		assert(args.contains("a"));
		assert(args["a"] == "1");
		assert(args["b"] == "2");
		assert(args.parameters["b"][1] == "3");
	}
}

/*version(Test)
{
    import tetra.util.Test;

    unittest
    {
        Test.Status complexTest(inout char[][] messages)
        {
            bool calledMe;
            auto args = new Arguments;
            args.define("a").parameters(1).required;
            args.define("b").parameters(1).required;
            args.define("c");
            args.define("d");
            args.define("o").defaults(["p"]);
            args.define("cde").parameters.aliases(["xyz"]).callback(delegate void (char[] name, char[] param){ calledMe = true; });
            args.delimiters ~= "^^";
            args.parse(["implicit", "-a", "-b", "-cd", "1", "--", "2", "--xyz", "fg", "--yyy:xxx=zzz", "--aeiou=", "--:blah", "--cat^^hat"]);
            if ((args.parameters[null][0] == "implicit") && (args["a"] == "2") && (args["b"] == "1") && ("c" in args) && ("d" in args) &&
            	(args.parameters["aeiou"][0] == "blah") && (args["cat"] == "hat") && (args["cde"] == "fg") && (args["yyy"] == "xxx=zzz") && calledMe)
            {
                return Test.Status.Success;
            }
            return Test.Status.Failure;
        }

        Test.Status simpleTest(inout char[][] messages)
        {
            auto args = new Arguments;
            args.parse(["implicit", "-x", "1"]);
            if ((args.parameters[null][0] == "implicit") && (args.parameters["x"][0] == "1"))
                return Test.Status.Success;
            return Test.Status.Failure;
        }

        Test.Status stackingTest(inout char[][] messages)
        {
            auto args = new Arguments;
            args.define("a");
            args.define("b").parameters(1).validation(delegate bool(char[][] p, out char[] iP) { if (p[0] != "B") { iP = p[0]; return false; } else return true; });
            args.define("c").parameters(1);
            args.define("d").parameters(1);
            args.parse(["-b", "-a", "-c", "C", "-d", "D", "B"]);
            if (("a" in args) && (args["b"] == "B") && (args["c"] == "C") && (args["d"] == "D"))
                return Test.Status.Success;
            return Test.Status.Failure;
        }

        Test.Status tarTest(inout char[][] messages)
        {
            auto args = new Arguments;
            args.prefixShort = [null];
            args.define("f").parameters;
            args.define("v");
            args.parse(["fv", "file1", "file2"]);
            if (("f" in args) && (args.parameters["f"][0] == "file1") && (args.parameters["f"][1] == "file2"))
                return Test.Status.Success;
            return Test.Status.Failure;
        }

        Test.Status dsssTest(inout char[][] messages)
        {
            auto args = new Arguments;
            args.prefixLong = [null];
            args.define("net").parameters(0, 2);
            args.parse(["net", "install", "tango", "clean"]);
          	if ((args.parameters["net"][0] == "install") && (args.parameters["net"][1] == "tango") && ("clean" in args))
                return Test.Status.Success;
            return Test.Status.Failure;
        }

        Test.Status coTest(inout char[][] messages)
        {
            auto args = new Arguments;
            args.prefixLong = [null];
            args.define("co").parameters(1);
            args.parse(["co", "http://blah"]);
            if (args["co"] == "http://blah")
                return Test.Status.Success;
            return Test.Status.Failure;
        }

        Test.Status svnTest(inout char[][] messages)
        {
            auto args = new Arguments;
            args.prefixLong = ["--", null];
            args.define("switch").parameters(1, 2);
            args.define("relocate");
            args.parse(["switch", "--relocate", "blah1", "blah2"]);
            if (("relocate" in args) && (args["switch"] == "blah1") && (args.parameters["switch"][1] == "blah2"))
            {
                args.reset;
                args.parse(["switch", "https://blah1"]);
                if (args["switch"] == "https://blah1")
                    return Test.Status.Success;
            }
            return Test.Status.Failure;
        }

        Test.Status lsTest(inout char[][] messages)
        {
            auto args = new Arguments;
            args.define("a");
            args.define("l");
            args.parse(["-al", "blah.txt"]);
            if (("a" in args) && ("l" in args) && (args[null] == "blah.txt"))
            {
                args.reset;
                args.parse(["blah.txt", "-al"]);
                if (("a" in args) && ("l" in args) && (args[null] == "blah.txt"))
                    return Test.Status.Success;
            }
            return Test.Status.Failure;
        }
        
        Test.Status countTest(inout char[][] messages)
        {
            auto args = new Arguments;
            args.define("f").parameters(1).delimiters([null]);
            args.define("v").parameters(0);
            args.parse(["-v", "-vv", "-ffile1"]);
            if ((args["f"] == "file1") && ("v" in args) && (args.count("v") == 3))
                return Test.Status.Success;
            return Test.Status.Failure;
        }

        Test argTest = new Test("tetra.app.Arguments");
        argTest["Complex Parsing"] = &complexTest;
        argTest["Simple Parsing"] = &simpleTest;
        argTest["Stacking Parsing"] = &stackingTest;
        argTest["'tar' - like"] = &tarTest;
        argTest["'dsss' - like"] = &dsssTest;
        argTest["'svn co' - like"] = &coTest;
        argTest["'svn' - like"] = &svnTest;
        argTest["'ls' - like"] = &lsTest;
        argTest["Count"] = &countTest;
        argTest.run;
    }
}*/
