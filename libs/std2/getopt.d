
// Written in the D programming language.

/**
 * Processing of command line options.
 *
 * The getopt module implements a $(D_PARAM getopt) function, which
 * adheres to the POSIX syntax for command line options. GNU
 * extensions are supported in the form of long options introduced by
 * a double dash ("--"). Support for bundling of command line options,
 * as was the case with the more traditional single-letter approach,
 * is provided but not enabled by default.
 *
 * Credits:
 * 
 * This module and its documentation are inspired by Perl's
 * $(LINK2 http://perldoc.perl.org/Getopt/Long.html,Getopt::Long) module. The
 * syntax of D's $(D_PARAM getopt) is simplified because $(D_PARAM
 * getopt) infers the expected parameter types from the static types
 * of the passed-in pointers.
 */

/* Author:
 *	Andrei Alexandrescu, www.erdani.org
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

module std2.getopt;
import std.string, std2.conv, std2.traits;

import std.stdio; // for testing only

/**
 Synopsis:

---------
import std.getopt;

string data   = "file.dat";
int length = 24;
bool verbose;

void main(string[] args)
{
  bool result = getopt(
    args,
    "length",  &length,    // numeric
    "file",    &data,      // string
    "verbose", &verbose);  // flag
  ...
}
---------

 The $(D_PARAM getopt) function takes a reference to the command line
 (as received by $(D_PARAM main)) as its first argument, and an
 unbounded number of pairs of strings and pointers. Each string is an
 option meant to "fill" the value pointed-to by the pointer to its
 right (the "bound" pointer). The option string in the call to
 $(D_PARAM getopt) should not start with a dash.

 In all cases, the command-line options that were parsed and
 used by $(D_PARAM getopt) are removed from $(D_PARAM args). Whatever
 in the arguments did not look like an option is left in $(D_PARAM
 args) for further processing by the program. Values that were
 unaffected by the options are not touched, so a common idiom is to
 initialize options to their defaults and then invoke $(D_PARAM
 getopt). If a command-line argument is recognized as an option with a
 parameter and the parameter cannot be parsed properly (e.g. a number
 is expected but not present), a $(D_PARAM ConvError) exception is
 thrown.

 Depending on the type of the pointer being bound, $(D_PARAM getopt)
 recognizes the following kinds of options:

 $(OL $(LI $(I Boolean options). These are the simplest options; all
 they do is set a Boolean to $(D_PARAM true):

---------
  bool verbose, debugging;
  bool result = getopt(args, "verbose", &verbose, "debug", &debugging);
---------

 $(LI $(I Numeric options.) If an option is bound to a numeric type, a
 number is expected as the next option, or right within the option
 separated with an "=" sign:
 
---------
  uint timeout;
  bool result = getopt(args, "timeout", &timeout);
---------

 Invoking the program with "--timeout=5" or "--timeout 5" will set
 $(D_PARAM timeout) to 5.)
 
 $(UL $(LI $(I Incremental options.) If an option name has a "+" suffix and
 is bound to a numeric type, then the option's value tracks the number
 of times the option occurred on the command line:

---------
  uint paranoid;
  bool result = getopt(args, "paranoid+", &paranoid);
---------

 Invoking the program with "--paranoid --paranoid --paranoid" will set
 $(D_PARAM paranoid) to 3. Note that an incremental option never
 expects a parameter, e.g. in the command line "--paranoid 42
 --paranoid", the "42" does not set $(D_PARAM paranoid) to 42;
 instead, $(D_PARAM paranoid) is set to 2 and "42" is not considered
 as part of the program options.))
 
 $(LI $(I String options.) If an option is bound to a string, a string
 is expected as the next option, or right within the option separated
 with an "=" sign:
 
---------
  string outputFile;
  bool result = getopt(args, "output", &outputFile);
---------

 Invoking the program with "--output=myfile.txt" or "--output
 myfile.txt" will set $(D_PARAM outputFile) to "myfile.txt".) If you
 want to pass a string containing spaces, you need to use the quoting
 that is appropriate to your shell, e.g. --output='my file.txt'. 
 
 $(LI $(I Array options.) If an option is bound to an array, a new
 element is appended to the array each time the option occurs:
 
---------
  string[] outputFiles;
  bool result = getopt(args, "output", &outputFiles);
---------

 Invoking the program with "--output=myfile.txt --output=yourfile.txt"
 or "--output myfile.txt --output yourfile.txt" will set $(D_PARAM
 outputFiles) to [ "myfile.txt", "yourfile.txt" ] .)
 
 $(LI $(I Hash options.) If an option is bound to an associative
 array, a string of the form "name=value" is expected as the next
 option, or right within the option separated with an "=" sign:
 
---------
  double[string] tuningParms;
  bool result = getopt(args, "tune", &tuningParms);
---------

 Invoking the program with e.g. "--tune=alpha=0.5 --tune beta=0.6"
 will set $(D_PARAM tuningParms) to [ "alpha" : 0.5, "beta" : 0.6 ].)
 In general, keys and values can be of any parsable types.
 
 $(LI $(I Delegate options.) An option can be bound to a delegate with
 the signature $(D_PARAM void delegate(string option)) or $(D_PARAM
 void delegate(string option, string value)).

 $(UL $(LI In the $(D_PARAM void delegate(string option)) case, the
 option string (without the leading dash(es)) is passed to the
 delegate. After that, the option string is considered handled and
 removed from the options array.)
 
---------
void main(string[] args)
{
  uint verbosityLevel = 1;
  void myHandler(string option)
  {
    if (option == "quiet")
    {
      verbosityLevel = 0;
    }
    else
    {
      assert(option == "verbose");
      verbosityLevel = 2;
    }
  }
  bool result = getopt(args, "verbose", &myHandler, "quiet", &myHandler);
}
---------

 $(LI In the $(D_PARAM void delegate(string option, string value))
 case, the option string is handled as an option with one argument,
 and parsed accordingly. The option and its value are passed to the
 delegate. After that, whatever was passed to the delegate is
 considered handled and removed from the list.)
 
---------
void main(string[] args)
{
  uint verbosityLevel = 1;
  void myHandler(string option, string value)
  {
    switch (value)
    {
      case "quiet": verbosityLevel = 0; break;
      case "verbose": verbosityLevel = 2; break;
      case "shouting": verbosityLevel = verbosityLevel.max; break;
      default :
        writeln(stderr, "Dunno how verbose you want me to be by saying ",
          value);
        exit(1);
    }
  }
  bool result = getopt(args, "verbosity", &myHandler);
}
---------
))))

$(B Options with multiple names)

Sometimes option synonyms are desirable, e.g. "--verbose",
"--loquacious", and "--garrulous" should have the same effect. Such
alternate option names can be included in the option specification,
using "|" as a separator:

---------
bool verbose;
getopt(args, "verbose|loquacious|garrulous", &verbose);
---------

$(B Case)

By default options are case-insensitive. You can change that behavior by passing $(D_PARAM getopt) the $(D_PARAM caseSensitive) directive like this:

---------
bool foo, bar;
getopt(args,
    std.getopt.config.caseSensitive,
    "foo", &foo,
    "bar", &bar);
---------

In the example above, "--foo", "--bar", "--FOo", "--bAr" etc. are recognized. The directive is active til the end of $(D_PARAM getopt), or until the converse directive $(D_PARAM caseSensitive) is encountered:

---------
bool foo, bar;
getopt(args,
    std.getopt.config.caseSensitive,
    "foo", &foo,
    std.getopt.config.caseInsensitive,
    "bar", &bar);
---------

The option "--Foo", is rejected due to $(D_PARAM
std.getopt.config.caseSensitive), but not "--Bar", "--bAr"
etc. because the directive $(D_PARAM
std.getopt.config.caseInsensitive) turned sensitivity off before
option "bar" was parsed.

$(B Bundling)

Single-letter options can be bundled together, i.e. "-abc" is the same as "-a -b -c". By default, this confusing option is turned off. You can turn it on with the $(D_PARAM std.getopt.config.bundling) directive:

---------
bool foo, bar;
getopt(args,
    std.getopt.config.bundling,
    "foo|f", &foo,
    "bar|b", &bar);
---------

In case you want to only enable bundling for some of the parameters, bundling can be turned off with $(D_PARAM std.getopt.config.noBundling).

$(B Passing unrecognized options through)

If an application needs to do its own processing of whichever arguments $(D_PARAM getopt) did not understand, it can pass the $(D_PARAM std.getopt.config.passThrough) directive to $(D_PARAM getopt):

---------
bool foo, bar;
getopt(args,
    std.getopt.config.passThrough,
    "foo", &foo,
    "bar", &bar);
---------

An unrecognized option such as "--baz" will be found untouched in $(D_PARAM args) after $(D_PARAM getopt) returns.

$(B Options Terminator)

A lonesome double-dash terminates $(D_PARAM getopt) gathering. It is used to separate program options from other parameters (e.g. options to be passed to another program). Invoking the example above with "--foo -- --bar" parses foo but leaves "--bar" in $(D_PARAM args). The double-dash itself is removed from the argument array.
*/

bool getopt(T...)(ref string[] args, T opts) {
    configuration cfg;
    return getoptImpl(args, cfg, opts);
}

/**
 * Configuration options for $(D_PARAM getopt). You can pass them to
 * $(D_PARAM getopt) in any position, except in between an option
 * string and its bound pointer.
 */

enum config {
    /// Turns case sensitivity on
    caseSensitive,
    /// Turns case sensitivity off
    caseInsensitive,
    /// Turns bundling on
    bundling,
    /// Turns bundling off
    noBundling,
    /// Pass unrecognized arguments through
    passThrough,
    /// Signal unrecognized arguments as errors
    noPassThrough,
};

private bool getoptImpl(T...)(ref string[] args,
    ref configuration cfg, T opts)
{
    static if (opts.length) {
        static if (is(typeof(opts[0]) : config))
        {
            switch (opts[0])
            {
            case config.caseSensitive: cfg.caseSensitive = true; break;
            case config.caseInsensitive: cfg.caseSensitive = false; break;
            case config.bundling: cfg.bundling = true; break;
            case config.noBundling: cfg.bundling = false; break;
            case config.passThrough: cfg.passThrough = true; break;
            case config.noPassThrough: cfg.passThrough = false; break;
            }
            return getoptImpl(args, cfg, opts[1 .. $]);
        }
        else
        {
            string option = to!(string)(opts[0]);
            auto receiver = opts[1];
            bool incremental;
            if (option.length && option[$ - 1] == '+')
            {
                option = option[0 .. $ - 1];
                incremental = true;
            }
            for (size_t i = 1; i != args.length; ) {
                auto a = args[i];
                if (a == endOfOptions) break; // end of options
                string val;
                if (!optMatch(a, option, val, cfg))
                {
                    ++i;
                    continue;
                }
                // found it
                
                static if (is(typeof(receiver) : bool*)) {
                    *receiver = true;
                    args = args[0 .. i] ~ args[i + 1 .. $];
                    break;
                } else {
                    static const isDelegateWithOneParameter =
                        is(typeof(receiver("")) : void);
                    // non-boolean option, which might include an argument
                    if (val || incremental || isDelegateWithOneParameter) {
                        args = args[0 .. i] ~ args[i + 1 .. $];
                    } else {
                        val = args[i + 1];
                        args = args[0 .. i] ~ args[i + 2 .. $];
                    }
                    static if (is(typeof(*receiver) : real)) {
                        if (incremental) ++*receiver;
                        else *receiver = to!(typeof(*receiver))(val);
                    } else static if (is(typeof(receiver) : string*)) {
                        *receiver = to!(string)(val);
                    } else static if (is(typeof(receiver) == delegate)) {
                        static if (is(typeof(receiver("", "")) : void)) 
                        {
                            // option with argument
                            receiver(option, val);
                        }
                        else
                        {
                            static assert(is(typeof(receiver("")) : void));
                            // boolean-style receiver
                            receiver(option);
                        }
	            } else static if (isArray!(typeof(*receiver))) {
                        *receiver ~= [ to!(typeof(*receiver[0]))(val) ];
                    } else static if (isAssociativeArray!(typeof(*receiver))) {
                        alias typeof(receiver.keys[0]) K;
                        alias typeof(receiver.values[0]) V;
                        auto j = find(val, '=');
                        auto key = val[0 .. j], value = val[j + 1 .. $];
                        (*receiver)[to!(K)(key)] = to!(V)(value);
                    } else {
                        static assert(false, "Dunno how to deal with type " ~
                            typeof(receiver).stringof);
                    }
                }
            }
            return getoptImpl(args, cfg, opts[2 .. $]);
        }
    } else {
        foreach (a ; args[1 .. $]) {
            if (!a.length || a[0] != '-') continue; // not an option
            if (a == "--") break; // end of options
            if (!cfg.passThrough)
            {
                fwritefln(stderr, "Unrecognized option ", a);
                return false;
            }
        }
    }
    return true;
}

const
  optChar = '-',
  assignChar = '=',
  endOfOptions = "--";

private struct configuration
{
    bool caseSensitive = false;
    bool bundling = false;
    bool passThrough = false;
}

private bool optMatch(string arg, string optPattern, ref string value,
    configuration cfg)
{
    if (!arg.length || arg[0] != optChar) return false;
    arg = arg[1 .. $];
    final isLong = arg.length > 1 && arg[0] == optChar;
    if (isLong) arg = arg[1 .. $];
    final eqPos = find(arg, assignChar);
    if (eqPos >= 0) {
        value = arg[eqPos + 1 .. $];
        arg = arg[0 .. eqPos];
    } else {
        value = null;
    }
    //writeln("Arg: ", arg, " pattern: ", optPattern, " value: ", value);
    // Split the option
    final variants = split(optPattern, "|");
    foreach (v ; variants) {
        if (arg == v || !cfg.caseSensitive && toupper(arg) == toupper(v))
            return true;
        if (cfg.bundling && !isLong && v.length == 1 && find(arg, v) >= 0)
            return true;
    }
    return false;
}

unittest
{
    uint paranoid = 2;
    string[] args = (["program.name",
                      "--paranoid", "--paranoid", "--paranoid"]).dup;
    assert(getopt(args, "paranoid+", &paranoid));
    assert(paranoid == 5, to!(string)(paranoid));
    
    string data   = "file.dat";
    int length = 24;
    bool verbose = true;
    args = (["program.name", "--length=5",
                      "--file", "dat.file", "--verbose"]).dup;
    assert(getopt(
        args,
        "length",  &length,
        "file",    &data,     
        "verbose", &verbose));
    assert(args.length == 1);
    assert(data == "dat.file");
    assert(length == 5);
    assert(verbose);

    //
    string[] outputFiles;
    args = (["program.name", "--output=myfile.txt",
             "--output", "yourfile.txt"]).dup;
    assert(getopt(args, "output", &outputFiles));
    assert(outputFiles.length == 2
           && outputFiles[0] == "myfile.txt" && outputFiles[0] == "myfile.txt");

    args = (["program.name", "--tune=alpha=0.5",
             "--tune", "beta=0.6"]).dup;
    double[string] tuningParms;
    assert(getopt(args, "tune", &tuningParms));
    assert(args.length == 1);
    assert(tuningParms.length == 2);
    assert(tuningParms["alpha"] == 0.5);
    assert(tuningParms["beta"] == 0.6);

    uint verbosityLevel = 1;
    void myHandler(string option)
    {
        if (option == "quiet")
        {
            verbosityLevel = 0;
        }
        else
        {
            assert(option == "verbose");
            verbosityLevel = 2;
        }
    }
    args = (["program.name", "--quiet"]).dup;
    assert(getopt(args, "verbose", &myHandler, "quiet", &myHandler));
    assert(verbosityLevel == 0);
    args = (["program.name", "--verbose"]).dup;
    assert(getopt(args, "verbose", &myHandler, "quiet", &myHandler));
    assert(verbosityLevel == 2);

    verbosityLevel = 1;
    void myHandler2(string option, string value)
    {
        assert(option == "verbose");
        verbosityLevel = 2;
    }
    args = (["program.name", "--verbose", "2"]).dup;
    assert(getopt(args, "verbose", &myHandler2));
    assert(verbosityLevel == 2);

    bool foo, bar;
    args = (["program.name", "--foo", "--bAr"]).dup;
    assert(getopt(args,
        std.getopt.config.caseSensitive,
        std.getopt.config.passThrough,
        "foo", &foo,
        "bar", &bar));
    assert(args[1] == "--bAr");
}
