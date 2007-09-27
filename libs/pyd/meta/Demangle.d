/**
 *  Demangle a ".mangleof" name at compile time.
 *
 * Used by meta.Nameof.
 *
 * License:   BSD style: $(LICENSE)
 * Authors:   Don Clugston
 * Copyright: Copyright (C) 2005-2006 Don Clugston
 */
module meta.Demangle;
/*
 Implementation is via pairs of metafunctions:
 a 'demangle' metafunction, which returns a const char [],
 and a 'Consumed' metafunction, which returns an integer, the number of characters which
 are used.
*/

/*****************************************
 * How should the name be displayed?
 */
enum MangledNameType
{
    PrettyName,    // With full type information
    QualifiedName, // No type information, just identifiers seperated by dots
    SymbolName     // Only the ultimate identifier
}

/*****************************************
 * Pretty-prints a mangled type string.
 */
template demangleType(string str, MangledNameType wantQualifiedNames = MangledNameType.PrettyName)
{
    static if (wantQualifiedNames != MangledNameType.PrettyName) {
        // There are only a few types where symbolnameof!(), qualifiednameof!()
        // make sense.
        static if (str[0]=='C' || str[0]=='S' || str[0]=='E' || str[0]=='T')
            const char [] demangleType = prettyLname!(str[1..$], wantQualifiedNames);
        else {
            static assert(0, "Demangle error: type '" ~ str ~ "' does not contain a qualified name");
        }
    } else static if (str[0] == 'A') // dynamic array
        const char [] demangleType = demangleType!(str[1..$], wantQualifiedNames) ~ "[]";
    else static if (str[0] == 'H')   // associative array
        const char [] demangleType
            = demangleType!(str[1+demangleTypeConsumed!(str[1..$])..$], wantQualifiedNames)
            ~ "[" ~ demangleType!(str[1..1+(demangleTypeConsumed!(str[1..$]))], wantQualifiedNames) ~ "]";
    else static if (str[0] == 'G') // static array
        const char [] demangleType
            = demangleType!(str[1+countLeadingDigits!(str[1..$])..$], wantQualifiedNames)
            ~ "[" ~ str[1..1+countLeadingDigits!(str[1..$]) ] ~ "]";
    else static if (str[0]=='C')
        const char [] demangleType = "class " ~ prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='S')
        const char [] demangleType = "struct " ~ prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='E')
        const char [] demangleType = "enum " ~ prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='T')
        const char [] demangleType = "typedef " ~ prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='D' && str.length>2 && isMangledFunction!(( str[1] )) ) // delegate
        const char [] demangleType = demangleFunctionOrDelegate!(str[1..$], "delegate ", wantQualifiedNames);
    else static if (str[0]=='P' && str.length>2 && isMangledFunction!(( str[1] )) ) // function pointer
        const char [] demangleType = demangleFunctionOrDelegate!(str[1..$], "function ", wantQualifiedNames);
    else static if (str[0]=='P') // only after we've dealt with function pointers
        const char [] demangleType = demangleType!(str[1..$], wantQualifiedNames) ~ "*";
    else static if (str[0]=='F')
        const char [] demangleType = demangleFunctionOrDelegate!(str, "", wantQualifiedNames);
    else const char [] demangleType = demangleBasicType!(str);
}

// split these off because they're numerous and simple
// Note: For portability, could replace "v" with void.mangleof, etc.
template demangleBasicType(string str)
{
         static if (str == "v") const char [] demangleBasicType = "void";
    else static if (str == "b") const char [] demangleBasicType = "bool";
    // possibly a bug in the D name mangling algorithm?
    else static if (str == "x") const char [] demangleBasicType = "bool";

    // integral types
    else static if (str == "g") const char [] demangleBasicType = "byte";
    else static if (str == "h") const char [] demangleBasicType = "ubyte";
    else static if (str == "s") const char [] demangleBasicType = "short";
    else static if (str == "t") const char [] demangleBasicType = "ushort";
    else static if (str == "i") const char [] demangleBasicType = "int";
    else static if (str == "k") const char [] demangleBasicType = "uint";
    else static if (str == "l") const char [] demangleBasicType = "long";
    else static if (str == "m") const char [] demangleBasicType = "ulong";
    // floating point
    else static if (str == "e") const char [] demangleBasicType = "real";
    else static if (str == "d") const char [] demangleBasicType = "double";
    else static if (str == "f") const char [] demangleBasicType = "float";

    else static if (str == "j") const char [] demangleBasicType = "ireal";
    else static if (str == "p") const char [] demangleBasicType = "idouble";
    else static if (str == "o") const char [] demangleBasicType = "ifloat";

    else static if (str == "c") const char [] demangleBasicType = "creal";
    else static if (str == "r") const char [] demangleBasicType = "cdouble";
    else static if (str == "q") const char [] demangleBasicType = "cfloat";
    // Char types
    else static if (str == "a") const char [] demangleBasicType = "char";
    else static if (str == "u") const char [] demangleBasicType = "wchar";
    else static if (str == "w") const char [] demangleBasicType = "dchar";

    else static assert(0, "Demangle Error: '" ~ str ~ "' is not a recognised basic type");
}

template demangleTypeConsumed(string str)
{
    static if (str[0]=='A')
        const int demangleTypeConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else static if (str[0]=='H')
        const int demangleTypeConsumed = 1 + demangleTypeConsumed!(str[1..$])
            + demangleTypeConsumed!(str[1+demangleTypeConsumed!(str[1..$])..$]);
    else static if (str[0]=='G')
        const int demangleTypeConsumed = 1 + countLeadingDigits!(str[1..$])
            + demangleTypeConsumed!( str[1+countLeadingDigits!(str[1..$])..$] );
    else static if (str.length>2 && (str[0]=='P' || str[0]=='D') && isMangledFunction!(( str[1] )) )
        const int demangleTypeConsumed = 2 + demangleParamListAndRetValConsumed!(str[2..$]);
    else static if (str[0]=='P') // only after we've dealt with function pointers
        const int demangleTypeConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else static if (str[0]=='C' || str[0]=='S' || str[0]=='E' || str[0]=='T')
        const int demangleTypeConsumed = 1 + getQualifiedNameConsumed!(str[1..$]);
    else static if (str[0]=='F' && str.length>1)
        const int demangleTypeConsumed = 1 + demangleParamListAndRetValConsumed!(str[1..$]);
    else // it's a Basic Type
        const int demangleTypeConsumed = 1;
}

// --------------------------------------------
//              STATIC ARRAYS

// For static arrays, count number of digits used (eg, return 3 for "674")
template countLeadingDigits(string str)
{
    static if (str.length>0 && beginsWithDigit!( str))
        const int countLeadingDigits = 1 + countLeadingDigits!( str[1..$]);
    else const int countLeadingDigits = 0;
}

// --------------------------------------------
//              LNAMES

// str must start with an Lname: first chars give the length
// reads the digits from the front of str, gets the Lname
// Sometimes the characters following the length are also digits!
// (this happens with templates, when the name being 'lengthed' is itself an Lname).
// We guard against this by ensuring that the L is less than the length of the string.
template getLname(string str)
{
    static if (str.length <= 9+1 || !beginsWithDigit!(str[1..$]) )
        const char [] getLname = str[1..(str[0]-'0' + 1)];
    else static if (str.length <= 99+2 || !beginsWithDigit!(str[2..$]) )
        const char [] getLname = str[2..((str[0]-'0')*10 + str[1]-'0'+ 2)];
    else static if (str.length <= 999+3 || !beginsWithDigit!(str[3..$]) )
        const char [] getLname =
            str[3..((str[0]-'0')*100 + (str[1]-'0')*10 + str[2]-'0' + 3)];
    else
        const char [] getLname =
            str[4..((str[0]-'0')*1000 + (str[1]-'0')*100 + (str[2]-'0')*10 + (str[3]-'0') + 4)];
}

// Deal with the case where an Lname contains an embedded "__D".
// This can happen when classes, typedefs, etc are declared inside a function.
template pretty_Dname(string str, int dotnameconsumed, MangledNameType wantQualifiedNames)
{
    static if ( isMangledFunction!( (str[2+dotnameconsumed]))) {
        const char [] pretty_Dname = pretty_Dfunction!(str, dotnameconsumed,
            demangleParamListAndRetValConsumed!(str[3+dotnameconsumed..$]), wantQualifiedNames);
    } else {
        static if (wantQualifiedNames == MangledNameType.PrettyName) {
            const char [] pretty_Dname =
                demangleType!(str[2+dotnameconsumed..$], wantQualifiedNames)
                ~ " " ~ getQualifiedName!(str[2..$], wantQualifiedNames);
        } else {
            const char [] pretty_Dname = getQualifiedName!(str[2..$], wantQualifiedNames);
        }
    }
}

// Deal with the case where an Lname contains an embedded ("__D") function.
// Split into a seperate function because it's so complicated.
template pretty_Dfunction(string str, int dotnameconsumed, int paramlistconsumed,
    MangledNameType wantQualifiedNames)
{
    static if (wantQualifiedNames == MangledNameType.PrettyName) {
        const char [] pretty_Dfunction =
            demangleFunctionOrDelegate!(str[2 + dotnameconsumed .. 3 + dotnameconsumed + paramlistconsumed],
                getQualifiedName!(str[2..2+dotnameconsumed], wantQualifiedNames), wantQualifiedNames)
                // BUG: This shouldn't be necessary, the string length is wrong somewhere
            ~ getQualifiedName!(str[3 + dotnameconsumed + paramlistconsumed .. $], wantQualifiedNames, ".");
    } else static if (wantQualifiedNames == MangledNameType.QualifiedName) {
        // Qualified name
        const char [] pretty_Dfunction = getQualifiedName!(str[2..2+dotnameconsumed], wantQualifiedNames)
            ~ getQualifiedName!(str[3 + dotnameconsumed + paramlistconsumed .. $], wantQualifiedNames, ".");
    } else { // symbol name
        static if (3 + dotnameconsumed + paramlistconsumed == str.length)
            const char [] pretty_Dfunction = getQualifiedName!(str[2..2+dotnameconsumed], wantQualifiedNames);
        else const char [] pretty_Dfunction = getQualifiedName!(
            str[3 + dotnameconsumed + paramlistconsumed .. $], wantQualifiedNames);
    }
 }

// for an Lname that begins with "_D"
template get_DnameConsumed(string str)
{
    const int get_DnameConsumed = 2 + getQualifiedNameConsumed!(str[2..$])
        + demangleTypeConsumed!(str[2+getQualifedNameConsumed!(str[2..$])..$]);
}

// If Lname is a template, shows it as a template
template prettyLname(string str, MangledNameType wantQualifiedNames)
{
    static if (str.length>3 && str[0..3] == "__T") // Template instance name
        static if (wantQualifiedNames == MangledNameType.PrettyName) {
            const char [] prettyLname =
                prettyLname!(str[3..$], wantQualifiedNames) ~ "!("
                ~ prettyTemplateArgList!(str[3+getQualifiedNameConsumed!(str[3..$])..$], wantQualifiedNames)
                ~ ")";
        } else {
            const char [] prettyLname =
                prettyLname!(str[3..$], wantQualifiedNames);
        }
    else static if (str.length>2 && str[0..2] == "_D") {
        const char [] prettyLname = pretty_Dname!(str, getQualifiedNameConsumed!(str[2..$]), wantQualifiedNames);
    } else static if ( beginsWithDigit!( str ) )
        const char [] prettyLname = getQualifiedName!(str[0..getQualifiedNameConsumed!(str)], wantQualifiedNames);
    else const char [] prettyLname = str;
}

// str must start with an lname: first chars give the length
// how many chars are taken up with length digits + the name itself
template getLnameConsumed(string str)
{
    static if (str.length==0)
        const int getLnameConsumed=0;
    else static if (str.length <= (9+1) || !beginsWithDigit!(str[1..$]) )
        const int getLnameConsumed = 1 + str[0]-'0';
    else static if (str.length <= (99+2) || !beginsWithDigit!( str[2..$]) )
        const int getLnameConsumed = (str[0]-'0')*10 + str[1]-'0' + 2;
    else static if (str.length <= (999+3) || !beginsWithDigit!( str[3..$]) )
        const int getLnameConsumed = (str[0]-'0')*100 + (str[1]-'0')*10 + str[2]-'0' + 3;
    else
        const int getLnameConsumed = (str[0]-'0')*1000 + (str[1]-'0')*100 + (str[2]-'0')*10 + (str[3]-'0') + 4;
}

template getQualifiedName(string str, MangledNameType wantQualifiedNames, string dotstr = "")
{
    static if (str.length==0) const char [] getQualifiedName="";
//    else static if (str.length>2 && str[0]=='_' && str[1]=='D')
//        const char [] getDotName = getQualifiedName!(str[2..$], wantQualifiedNames);
    else {
        static assert (beginsWithDigit!(str));
        static if ( getLnameConsumed!(str) < str.length && beginsWithDigit!(str[getLnameConsumed!(str)..$]) ) {
            static if (wantQualifiedNames == MangledNameType.SymbolName) {
                // For symbol names, only display the last symbol
                const char [] getQualifiedName =
                    getQualifiedName!(str[getLnameConsumed!(str) .. $], wantQualifiedNames, "");
            } else {
                // Qualified and pretty names display everything
                const char [] getQualifiedName = dotstr
                    ~ prettyLname!(getLname!(str), wantQualifiedNames)
                    ~ getQualifiedName!(str[getLnameConsumed!(str) .. $], wantQualifiedNames, ".");
            }
        } else {
            const char [] getQualifiedName = dotstr ~ prettyLname!(getLname!(str), wantQualifiedNames);
        }
    }
}

template getQualifiedNameConsumed (string str)
{
    static if ( str.length>1 &&  beginsWithDigit!(str) ) {
        static if (getLnameConsumed!(str) < str.length && beginsWithDigit!( str[getLnameConsumed!(str)..$])) {
            const int getQualifiedNameConsumed = getLnameConsumed!(str)
                + getQualifiedNameConsumed!(str[getLnameConsumed!(str) .. $]);
        } else {
            const int getQualifiedNameConsumed = getLnameConsumed!(str);
        }
    } /*else static if (str.length>1 && str[0]=='_' && str[1]=='D') {
        const int getQualifiedNameConsumed = get_DnameConsumed!(str)
            + getQualifiedNameConsumed!(str[1+get_DnameConsumed!(str)..$]);
    }*/ else static assert(0);
}

// ----------------------------------------
//              FUNCTIONS

/* str[0] must indicate the extern linkage of the function. funcOrDelegStr is the name of the function,
* or "function " or "delegate "
*/
template demangleFunctionOrDelegate(string str, string funcOrDelegStr, MangledNameType wantQualifiedNames)
{
    const char [] demangleFunctionOrDelegate = demangleExtern!(( str[0] ))
        ~ demangleReturnValue!(str[1..$], wantQualifiedNames)
        ~ " " ~ funcOrDelegStr ~ "("
        ~ demangleParamList!(str[1..1+demangleParamListAndRetValConsumed!(str[1..$])], wantQualifiedNames)
        ~ ")";
}

// Special case: types that are in function parameters
// For function parameters, the type can also contain 'lazy', 'out' or 'inout'.
template demangleFunctionParamType(string str, MangledNameType wantQualifiedNames)
{
    static if (str[0]=='L')
        const char [] demangleFunctionParamType = "lazy " ~ demangleType!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='K')
        const char [] demangleFunctionParamType = "inout " ~ demangleType!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='J')
        const char [] demangleFunctionParamType = "out " ~ demangleType!(str[1..$], wantQualifiedNames);
    else const char [] demangleFunctionParamType = demangleType!(str, wantQualifiedNames);
}

// Deal with 'out' and 'inout' parameters
template demangleFunctionParamTypeConsumed(string str)
{
    static if (str[0]=='K' || str[0]=='J' || str[0]=='L')
        const int demangleFunctionParamTypeConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else const int demangleFunctionParamTypeConsumed = demangleTypeConsumed!(str);
}

// Return true if c indicates a function. As well as 'F', it can be extern(Pascal), (C), (C++) or (Windows).
template isMangledFunction(char c)
{
    const bool isMangledFunction = (c=='F' || c=='U' || c=='W' || c=='V' || c=='R');
}

template demangleExtern(char c)
{
    static if (c=='F') const char [] demangleExtern = "";
    else static if (c=='U') const char [] demangleExtern = "extern (C) ";
    else static if (c=='W') const char [] demangleExtern = "extern (Windows) ";
    else static if (c=='V') const char [] demangleExtern = "extern (Pascal) ";
    else static if (c=='R') const char [] demangleExtern = "extern (C++) ";
    else static assert(0, "Unrecognized extern function.");
}

// Skip through the string until we find the return value. It can either be Z for normal
// functions, or Y for vararg functions.
template demangleReturnValue(string str, MangledNameType wantQualifiedNames)
{
    static assert(str.length>=1, "Demangle error(Function): No return value found");
    static if (str[0]=='Z' || str[0]=='Y' || str[0]=='X')
        const char[] demangleReturnValue = demangleType!(str[1..$], wantQualifiedNames);
    else const char [] demangleReturnValue = demangleReturnValue!(str[demangleFunctionParamTypeConsumed!(str)..$], wantQualifiedNames);
}

// Stop when we get to the return value
template demangleParamList(string str, MangledNameType wantQualifiedNames, string commastr = "")
{
    static if (str[0] == 'Z')
        const char [] demangleParamList = "";
    else static if (str[0] == 'Y')
        const char [] demangleParamList = commastr ~ "...";
    else static if (str[0]=='X') // lazy ...
        const char[] demangleParamList = commastr ~ "...";
    else
        const char [] demangleParamList =  commastr ~
            demangleFunctionParamType!(str[0..demangleFunctionParamTypeConsumed!(str)], wantQualifiedNames)
            ~ demangleParamList!(str[demangleFunctionParamTypeConsumed!(str)..$], wantQualifiedNames, ", ");
}

// How many characters are used in the parameter list and return value
template demangleParamListAndRetValConsumed(string str)
{
    static assert (str.length>0, "Demangle error(ParamList): No return value found");
    static if (str[0]=='Z' || str[0]=='Y' || str[0]=='X')
        const int demangleParamListAndRetValConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else {
        const int demangleParamListAndRetValConsumed = demangleFunctionParamTypeConsumed!(str)
            + demangleParamListAndRetValConsumed!(str[demangleFunctionParamTypeConsumed!(str)..$]);
    }
}

// --------------------------------------------
//              TEMPLATES

template templateValueArgConsumed(string str)
{
    static if (str[0]=='n') const int templateValueArgConsumed = 1;
    else static if (beginsWithDigit!(str)) const int templateValueArgConsumed = countLeadingDigits!(str);
    else static if (str[0]=='N') const int templateValueArgConsumed = 1 + countLeadingDigits!(str[1..$]);
    else static if (str[0]=='e') const int templateValueArgConsumed = 1 + 20;
    else static if (str[0]=='c') const int templateValueArgConsumed = 1 + 40;
    else static assert(0, "Unknown character in template value argument");
}

// pretty-print a template value argument.
template prettyValueArg(string str)
{
    static if (str[0]=='n') const char [] prettyValueArg = "null";
    else static if (beginsWithDigit!(str)) const char [] prettyValueArg = str;
    else static if ( str[0]=='N') const char [] prettyValueArg = "-" ~ str[1..$];
    else static if ( str[0]=='e') const char [] prettyValueArg = "0x" ~ str[1..$];
    else static if ( str[0]=='c') const char [] prettyValueArg = "0x" ~ str[1..22] ~ " + 0x" ~ str[21..41] ~ "i";
    else const char [] prettyValueArg = "Value arg {" ~ str[0..$] ~ "}";
}

// Pretty-print a template argument
template prettyTemplateArg(string str, MangledNameType wantQualifiedNames)
{
    static if (str[0]=='S') // symbol name
        const char [] prettyTemplateArg = prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='V') // value
        const char [] prettyTemplateArg =
            demangleType!(str[1..1+demangleTypeConsumed!(str[1..$])], wantQualifiedNames)
            ~ " = " ~ prettyValueArg!(str[1+demangleTypeConsumed!(str[1..$])..$]);
    else static if (str[0]=='T') // type
        const char [] prettyTemplateArg = demangleType!(str[1..$], wantQualifiedNames);
    else static assert(0, "Unrecognised template argument type: {" ~ str ~ "}");
}

template templateArgConsumed(string str)
{
    static if (str[0]=='S') // symbol name
        const int templateArgConsumed = 1 + getLnameConsumed!(str[1..$]);
    else static if (str[0]=='V') // value
        const int templateArgConsumed = 1 + demangleTypeConsumed!(str[1..$]) +
            templateValueArgConsumed!(str[1+demangleTypeConsumed!(str[1..$])..$]);
    else static if (str[0]=='T') // type
        const int templateArgConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else static assert(0, "Unrecognised template argument type: {" ~ str ~ "}");
}

// Like function parameter lists, template parameter lists also end in a Z,
// but they don't have a return value at the end.
template prettyTemplateArgList(string str, MangledNameType wantQualifiedNames, string commastr="")
{
    static if (str[0]=='Z')
        const char[] prettyTemplateArgList = "";
    else
       const char [] prettyTemplateArgList = commastr
            ~ prettyTemplateArg!(str[0..templateArgConsumed!(str)], wantQualifiedNames)
            ~ prettyTemplateArgList!(str[templateArgConsumed!(str)..$], wantQualifiedNames, ", ");
}

template templateArgListConsumed(string str)
{
    static assert(str.length>0, "No Z found at end of template argument list");
    static if (str[0]=='Z')
        const int templateArgListConsumed = 1;
    else
        const int templateArgListConsumed = templateArgConsumed!(str)
            + templateArgListConsumed!(str[templateArgConsumed!(str)..$]);
}

private {
  /*
   * Return true if the string begins with a decimal digit
   *
   * beginsWithDigit!(s) is equivalent to isdigit!((s[0]));
   * it allows us to avoid the ugly double parentheses.
   */
template beginsWithDigit(string s)
{
  static if (s[0]>='0' && s[0]<='9')
    const bool beginsWithDigit = true;
  else const bool beginsWithDigit = false;
}
}



// --------------------------------------------
//              UNIT TESTS

debug(UnitTest){

private {

const char [] THISFILE = "meta.Demangle";

ireal SomeFunc(ushort u) { return -3i; }
idouble SomeFunc2(inout ushort u, ubyte w) { return -3i; }
byte[] SomeFunc3(out dchar d, ...) { return null; }
ifloat SomeFunc4(lazy void[] x...) { return 2i; }
char[dchar] SomeFunc5(lazy int delegate()[] z...);

extern (Windows) {
    typedef void function (double, long) WinFunc;
}
extern (Pascal) {
    typedef short[wchar] delegate (bool, ...) PascFunc;
}
extern (C) {
    typedef dchar delegate () CFunc;
}
extern (C++) {
    typedef cfloat function (wchar) CPPFunc;
}

interface SomeInterface {}

static assert( demangleType!((&SomeFunc).mangleof) == "ireal function (ushort)" );
static assert( demangleType!((&SomeFunc2).mangleof) == "idouble function (inout ushort, ubyte)");
static assert( demangleType!((&SomeFunc3).mangleof) == "byte[] function (out dchar, ...)");
static assert( demangleType!((&SomeFunc4).mangleof) == "ifloat function (lazy void[], ...)");
static assert( demangleType!((&SomeFunc5).mangleof) == "char[dchar] function (lazy int delegate ()[], ...)");
static assert( demangleType!((WinFunc).mangleof)== "extern (Windows) void function (double, long)");
static assert( demangleType!((PascFunc).mangleof) == "extern (Pascal) short[wchar] delegate (bool, ...)");
static assert( demangleType!((CFunc).mangleof) == "extern (C) dchar delegate ()");
static assert( demangleType!((CPPFunc).mangleof) == "extern (C++) cfloat function (wchar)");
// Interfaces are mangled as classes
static assert( demangleType!(SomeInterface.mangleof) == "class " ~ THISFILE ~ ".SomeInterface");

template ComplexTemplate(real a, creal b)
{
    class ComplexTemplate {}
}

static assert( demangleType!((ComplexTemplate!(1.23, 4.56+3.2i)).mangleof) == "class " ~ THISFILE ~ ".ComplexTemplate!(double = 0xa4703d0ad7a3709dff3f, cdouble = 0x85eb51b81e85eb910140c + 0xcdcccccccccccccc0040i).ComplexTemplate");

}
}
