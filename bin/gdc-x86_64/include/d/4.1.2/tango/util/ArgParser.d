/*******************************************************************************

        copyright:      Copyright (c) 2005-2006 Lars Ivar Igesund, 
                        Eric Anderton. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005      
        
        author:         Lars Ivar Igesund, Eric Anderton

*******************************************************************************/

module tango.util.ArgParser;

private import tango.core.Exception;

/**
    An alias to a delegate taking a char[] as a parameter. The value 
    parameter will hold any chars immediately
    following the argument. 
*/
alias void delegate (char[] value) ArgParserCallback;

/**
    An alias to a delegate taking a char[] as a parameter. The value 
    parameter will hold any chars immediately
    following the argument.

    The ordinal argument represents which default argument this is for
    the given stream of arguments.  The first default argument will
    be ordinal=0 with each successive call to this callback having
    ordinal values of 1, 2, 3 and so forth. This can be reset to zero
    in new calls to parse.
*/
alias void delegate (char[] value,uint ordinal) DefaultArgParserCallback;

/**
    An alias to a delegate taking no parameters
*/
alias void delegate () ArgParserSimpleCallback;


/**
    A struct that represents a "{Prefix}{Identifier}" string.
*/
struct Argument {
    char[] prefix;
    char[] identifier;

    /**
        Creates a new Argument instance with given prefix and identifier.
    */
    static Argument opCall ( char[] prefix, char[] identifier ) {
        Argument result;

        result.prefix = prefix;
        result.identifier = identifier;

        return result;
    }
}

/**
    Alias for for the lazy people.
*/
alias Argument Arg;


/**
    A utility class to parse and handle your command line arguments.
*/
class ArgParser{

    /**
        A helper struct containing a callback and an id, corresponding to
        the argId passed to one of the bind methods.
    */
    protected struct PrefixCallback {
        char[] id;
        ArgParserCallback cb;
    }   

    protected PrefixCallback[][char[]] bindings;
    protected DefaultArgParserCallback[char[]] defaultBindings;
    protected uint[char[]] prefixOrdinals;
    protected char[][] prefixSearchOrder;
    protected DefaultArgParserCallback defaultbinding;
    private uint defaultOrdinal = 0;

    protected void addBinding(PrefixCallback pcb, char[] argPrefix){
        if (!(argPrefix in bindings)) {
            prefixSearchOrder ~= argPrefix;
        }
        bindings[argPrefix] ~= pcb;
    }

    /**
        Binds a delegate callback to argument with a prefix and 
        a argId.
        
        Params:
            argPrefix = the prefix of the argument, e.g. a dash '-'.
            argId = the name of the argument, what follows the prefix
            cb = the delegate that should be called when this argument is found
    */
    public void bind(char[] argPrefix, char[] argId, ArgParserCallback cb){
        PrefixCallback pcb;
        pcb.id = argId;
        pcb.cb = cb;
        addBinding(pcb, argPrefix);
    } 

    /**
        The constructor, creates an empty ArgParser instance.
    */
    public this(){
        defaultbinding = null;
    }
     
    /**
        The constructor, creates an ArgParser instance with a defined default callback.
    */    
    public this(DefaultArgParserCallback callback){
        defaultbinding = callback;
    }    

    protected class SimpleCallbackAdapter{
        ArgParserSimpleCallback callback;
        public this(ArgParserSimpleCallback callback){ 
            this.callback = callback; 
        }
        
        public void adapterCallback(char[] value){
            callback();
        }
    }

    /**
        Binds a delegate callback to argument with a prefix and 
        a argId.
        
        Params:
            argPrefix = the prefix of the argument, e.g. a dash '-'.
            argId = the name of the argument, what follows the prefix
            cb = the delegate that should be called when this argument is found
    */
    public void bind(char[] argPrefix, char[] argId, ArgParserSimpleCallback cb){
        SimpleCallbackAdapter adapter = new SimpleCallbackAdapter(cb);
        PrefixCallback pcb;
        pcb.id = argId;
        pcb.cb = &adapter.adapterCallback;
        addBinding(pcb, argPrefix);
    }
    
    /**
        Binds a delegate callback to all arguments with prefix argPrefix, but that
        do not conform to an argument bound in a call to bind(). 

        Params:
            argPrefix = the prefix for the callback
            callback = the default callback
    */
    public void bindDefault(char[] argPrefix, DefaultArgParserCallback callback){
        defaultBindings[argPrefix] = callback;
        prefixOrdinals[argPrefix] = 0;
        if (!(argPrefix in bindings)) {
            prefixSearchOrder ~= argPrefix;
        }
    }

    /**
        Binds a delegate callback to all arguments not conforming to an
        argument bound in a call to bind(). These arguments will be passed to the
        delegate without having any matching prefixes removed.

        Params:
            callback = the default callback
    */
    public void bindDefault(DefaultArgParserCallback callback){
        defaultbinding = callback;
    }

    /**
        Binds a delegate callback to an argument.

        Params:
            argument = argument to respond to
            callback = the delegate that should be called when the argument is found
    */
    public void bind (Argument argument, ArgParserCallback callback) {
        bind(argument.prefix, argument.identifier, callback);
    }

    /**
        Binds a delegate callback to any number of arguments.

        Params:
            arguments = an array of Argument struct instances
            callback = the delegate that should be called when one of the arguments is found
    */
    public void bind ( Argument[] arguments, void delegate(char[]) callback ) {
        foreach (argument; arguments) { bind(argument, callback); }
    }

    /**
        Binds a delegate callback to an identifier with Posix-like prefixes. This means,
        it binds for both prefixes "-" and "--", as well as identifier with, and
        without a delimiting "=" between identifier and value.

        Params:
            identifier = argument identifier
            callback = the delegate that should be called when one of the arguments is found
    */
    public void bindPosix ( char[] identifier, ArgParserCallback callback ) {
        bind([ Argument("-", identifier ~ "="), Argument("-", identifier),
               Argument("--", identifier ~ "="), Argument("--", identifier) ], callback);
    }

    /**
        Binds a delegate callback to any number of identifiers with Posix-like prefixes.
        See bindPosix(identifier, callback).

        Params:
            arguments = an array of argument identifiers
            callback = the delegate that should be called when one of the arguments is found
    */
    public void bindPosix ( char[][] identifiers, ArgParserCallback callback ) {
        foreach (identifier; identifiers) { bindPosix(identifier, callback); }
    }

    /**
        Parses the arguments provided by the parameter. The bound callbacks are called as
        arguments are recognized. If two arguments have the same prefix, and start with 
        the same characters (e.g.: --open, --opened), the longest matching bound callback
        is called.

        Params:
            arguments = the command line arguments from the application
            resetOrdinals = if true, all ordinal counts will be set to zero
    */
    public void parse(char[][] arguments, bool resetOrdinals = false){
        if (bindings.length == 0) return;

        if (resetOrdinals) {
            defaultOrdinal = 0;
            foreach (key; prefixOrdinals.keys) {
                prefixOrdinals[key] = 0;
            }
        }

        foreach (char[] arg; arguments) {
            char[] argData = arg;
            char[] argOrig = argData;
            bool found = false;

            foreach (char[] prefix; prefixSearchOrder) {
                if(argData.length < prefix.length) continue; 

                if(argData[0..prefix.length] != prefix) continue;
                else argData = argData[prefix.length..$];

                if (prefix in bindings) {
                    PrefixCallback[] candidates;

                    foreach (PrefixCallback cb; bindings[prefix]) {
                        if (argData.length < cb.id.length) continue;
                        
                        uint cbil = cb.id.length;

                        if (cb.id == argData[0..cbil]) {
                            found = true;
                            candidates ~= cb;
                        }
                    }

                    if (found) {
                        // Find the longest matching callback identifier from the candidates.
                        uint indexLongestMatch = 0;

						if (candidates.length > 1) {
							foreach (i, candidate; candidates) {
								if (candidate.id.length > candidates[indexLongestMatch].id.length) {
									indexLongestMatch = i;
								}
							}
						}

                        // Call the best matching callback.
                        with(candidates[indexLongestMatch]) { cb(argData[id.length..$]); }
                    }
                }
                if (found) {
                    break;
                }
                else if (prefix in defaultBindings){
                    defaultBindings[prefix](argData,prefixOrdinals[prefix]);
                    prefixOrdinals[prefix]++;
                    found = true;
                    break;
                }
                argData = argOrig;
            }
            if (!found) {
                if (defaultbinding !is null) {
                    defaultbinding(argData,defaultOrdinal);
                    defaultOrdinal++;
                }
                else {
                    throw new IllegalArgumentException("Illegal argument "~ argData);
                }
            }
        }
    }
}

debug (UnitTest) {
    import Integer = tango.text.convert.Integer;

    //void main() {}

unittest {

    ArgParser parser = new ArgParser();
    bool h = false;
    bool h2 = false;
    bool b = false;
    bool bb = false;
    bool boolean = false;
    int n = -1;
    int dashOrdinalCount = -1;
    int ordinalCount = -1;

    parser.bind("--", "h2", delegate void(){
        h2 = true;
    });

    parser.bind("-", "h", delegate void(){
        h = true;
    });

    parser.bind("-", "bb", delegate void(){
        bb = true;
    });

    parser.bind("-", "bool", delegate void(char[] value){
        assert(value.length == 5);
        assert(value[0] == '=');
        if (value[1..5] == "true") {
            boolean = true;
        }
        else {
            assert(false);
        }
    });

    parser.bind("-", "b", delegate void(){
        b = true;
    });

    parser.bind("-", "n", delegate void(char[] value){
        assert(value[0] == '=');
        n = cast(int) Integer.parse(value[1..5]);
        assert(n == 4349);
    });

    parser.bindDefault(delegate void(char[] value, uint ordinal){
        ordinalCount = ordinal;
        if (ordinal == 0) {
            assert(value == "ordinalTest1");
        }
        else if (ordinal == 1) {
            assert(value == "ordinalTest2");
        }
    });

    parser.bindDefault("-", delegate void(char[] value, uint ordinal){
        dashOrdinalCount = ordinal;
        if (ordinal == 0) {
            assert(value == "dashTest1");
        }
        else if (ordinal == 1) {
            assert(value == "dashTest2");
        }
    });

    parser.bindDefault("@", delegate void(char[] value, uint ordinal){
        assert (value == "atTest");
    });

    static char[][] test1 = ["--h2", "-h", "-bb", "-b", "-n=4349", "-bool=true", "ordinalTest1", "ordinalTest2", "-dashTest1", "-dashTest2", "@atTest"];

    parser.parse(test1);
    assert(h2);
    assert(h);
    assert(b);
    assert(bb);
    assert(n == 4349);
    assert(ordinalCount == 1);
    assert(dashOrdinalCount == 1);
    
    h = h2 = b = bb = false;
    boolean = false;
    n = ordinalCount = dashOrdinalCount = -1;

    static char[][] test2 = ["-n=4349", "ordinalTest1", "@atTest", "--h2", "-b", "-bb", "-h", "-dashTest1", "-dashTest2", "ordinalTest2", "-bool=true"];

    parser.parse(test2, true);
    assert(h2 && h && b && bb && boolean && (n ==4349));
    assert(ordinalCount == 1);
    assert(dashOrdinalCount == 1);
 
    h = h2 = b = bb = false;
    boolean = false;
    n = ordinalCount = dashOrdinalCount = -1;

    static char[][] test3 = ["-n=4349", "ordinalTest1", "@atTest", "--h2", "-b", "-bb", "-h", "-dashTest1", "-dashTest2", "ordinalTest2", "-bool=true"];

    parser.parse(test3, true);
    assert(h2 && h && b && bb && boolean && (n ==4349));
    assert((ordinalCount == 1) && (dashOrdinalCount == 1));
 
    ordinalCount = dashOrdinalCount = -1;

    static char[][] test4 = ["ordinalTest1", "ordinalTest2", "ordinalTest3", "ordinalTest4"];
    static char[][] test5 = ["-dashTest1", "-dashTest2", "-dashTest3"];

    parser.parse(test4, true);
    assert(ordinalCount == 3);

    parser.parse(test5, true);
    assert(dashOrdinalCount == 2);
}
}
