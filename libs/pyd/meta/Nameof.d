/**
 *  Convert any D symbol or type to a human-readable string, at compile time.
 *
 *   Given any D symbol (class, template, function, module name, or non-local variable)
 *   or any D type, convert it to a compile-time string literal,
 *   optionally containing the fully qualified and decorated name.
 *
 *   Limitations (as of DMD 0.167):
 *   1. Names of local variables cannot be determined, because they are not permitted
 *      as template alias parameters. Technically, it's possible to determine the name by using
 *      a mixin hack, but it's so ugly that it cannot be recommended.
 *   2. The name mangling for symbols declared inside extern(Windows), extern(C) and extern(Pascal)
 *      functions is inherently ambiguous, so such inner symbols are not always correctly displayed.
 *
 * License:   BSD style: $(LICENSE)
 * Authors:   Don Clugston
 * Copyright: Copyright (C) 2005-2006 Don Clugston
 */
module meta.Nameof;
private import meta.Demangle;

private {
    // --------------------------------------------
    // Here's the magic...
    //
    // Make a unique type for each identifier; but don't actually
    // use the identifier for anything.
    // This works because any class always needs to be fully qualified.
    template inner(alias F)
    {
      class inner { }
    }

    // If you take the .mangleof an alias parameter, you are only
    // told that it is an alias.
    // So, we put the type as a function parameter.
    template outer(alias B)
    {
      void function( inner!(B) ) outer;
    }

    // We will get the .mangleof for a pointer to this function pointer.
    template rawmanglednameof(alias A)
    {
      const char [] rawmanglednameof  =
                 typeof(&outer!(A)).mangleof;
    }

// If the identifier is "MyIdentifier" and this module is "QualModule"
// The return value will be:
//  "PPF"   -- because it's a pointer to a pointer to a function
//   "C"     -- because the first parameter is a class
//    "10QualModule"  -- the name of this module
//      "45" -- the number of characters in the remainder of the mangled name.
//         Note that this could be more than 2 characters, but will be at least "10".
//      "__T"    -- because it's a class inside a template
//       "5inner" -- the name of the template "inner"
//       "T" MyIdentifer -- Here's our prize!
//       "Z"  -- marks the end of the template parameters for "inner"
//    "5inner" -- this is the class "inner"
//  "Z"  -- the return value of the function is coming
//  "v"  -- the function returns void

// The only unknown parts above are:
// (1) the name of this source file
// (it could move or be renamed). So we do a simple case:
//  "C"   -- it's a class
//   "10QualModule" -- the name of this module
//   "15establishMangle" -- the name of the class
// and (2) the number of characters in the remainder of the name

    class establishMangle {}
    // Get length of this (fully qualified) module name
    const int modulemanglelength = establishMangle.mangleof.length - "C15establishMangle".length;

    // Get the number of chars at the start relating to the pointer
    const int pointerstartlength = "PPFC".length + modulemanglelength + "__T5inner".length;
    // And the number of chars at the end
    const int pointerendlength = "Z5innerZv".length;
}

// --------------------------------------------------------------
// Now, some functions which massage the mangled name to give something more useful.


/**
 * Like .mangleof, except that it works for an alias template parameter instead of a type.
 */
template manglednameof(alias A)
{
    static if (rawmanglednameof!(A).length - pointerstartlength <= 100 + 1) {
        // the length of the template argument requires 2 characters
        const char [] manglednameof  =
             rawmanglednameof!(A)[ pointerstartlength + 2 .. $ - pointerendlength];
    } else
        const char [] manglednameof  =
             rawmanglednameof!(A)[ pointerstartlength + 3 .. $ - pointerendlength];
}

/**
 * The symbol as it was declared, but including full type qualification.
 *
 * example: "int mymodule.myclass.myfunc(uint, class otherclass)"
 */
template prettynameof(alias A)
{
  const char [] prettynameof = prettyTemplateArg!(manglednameof!(A), MangledNameType.PrettyName);
}

/** Convert any D type to a human-readable string literal
 *
 * example: "int function(double, char[])"
 */
template prettytypeof(A)
{
  const char [] prettytypeof = demangleType!(A.mangleof, MangledNameType.PrettyName);
}

/**
 * Returns the qualified name of the symbol A.
 *
 * This will be a sequence of identifiers, seperated by dots.
 * eg "mymodule.myclass.myfunc"
 * This is the same as prettynameof(), except that it doesn't include any type information.
 */
template qualifiednameof(alias A)
{
  const char [] qualifiednameof = prettyTemplateArg!(manglednameof!(A), MangledNameType.QualifiedName);
}

/**
 * Returns the unqualified name, as a single text string.
 *
 * eg. "myfunc"
 */
template symbolnameof(alias A)
{
  const char [] symbolnameof = prettyTemplateArg!(manglednameof!(A), MangledNameType.SymbolName);
}

//----------------------------------------------
//                Unit Tests
//----------------------------------------------

debug (UnitTest)
{
private {
// Declare some structs, classes, enums, functions, and templates.

template ClassTemplate(A)
{
   class ClassTemplate {}
}

struct OuterClass  {
class SomeClass {}
}

alias double delegate (int, OuterClass) SomeDelegate;

template IntTemplate(int F)
{
  class IntTemplate { }
}

template MyInt(int F)
{
    const int MyIntX = F;
}


enum SomeEnum { ABC = 2 }
SomeEnum SomeInt;

// remove the ".d" from the end
const char [] THISFILE = "meta.Nameof";

static assert( prettytypeof!(real) == "real");
static assert( prettytypeof!(OuterClass.SomeClass) == "class " ~ THISFILE ~".OuterClass.SomeClass");

// Test that it works with module names (for example, this module)
static assert( qualifiednameof!(meta.Nameof) == "meta.Nameof");
static assert( symbolnameof!(meta.Nameof) == "Nameof");

static assert( prettynameof!(SomeInt)
    == "enum " ~ THISFILE ~ ".SomeEnum " ~ THISFILE ~ ".SomeInt");
static assert( qualifiednameof!(OuterClass) == THISFILE ~".OuterClass");
static assert( symbolnameof!(SomeInt) == "SomeInt");

static assert( prettynameof!(inner!( MyInt!(68u) ))
    ==  "class " ~ THISFILE ~ ".inner!(" ~ THISFILE ~ ".MyInt!(uint = 68)).inner");
static assert( symbolnameof!(inner!( MyInt!(68u) )) ==  "inner");
static assert( prettynameof!(ClassTemplate!(OuterClass.SomeClass))
    == "class "~ THISFILE ~ ".ClassTemplate!(class "~ THISFILE ~ ".OuterClass.SomeClass).ClassTemplate");
static assert( symbolnameof!(ClassTemplate!(OuterClass.SomeClass))  == "ClassTemplate");

// Extern(D) declarations have full type information.
extern int pig();
extern int pog;
static assert( prettynameof!(pig) == "int " ~ THISFILE ~ ".pig()");
static assert( prettynameof!(pog) == "int " ~ THISFILE ~ ".pog");
static assert( symbolnameof!(pig) == "pig");

// Extern(Windows) declarations contain no type information.
extern (Windows) {
    extern int dog();
    extern int dig;
}

static assert( prettynameof!(dog) == "dog");
static assert( prettynameof!(dig) == "dig");

// There are some nasty corner cases involving classes that are inside functions.
// Corner case #1: class inside nested function inside template

extern (Windows) {
template aardvark(X) {
    int aardvark(short goon) {
        class wolf {}
        static assert(prettynameof!(wolf)== "class extern (Windows) int " ~ THISFILE ~ ".aardvark!(struct "
            ~ THISFILE ~ ".OuterClass).aardvark(short).wolf");
        static assert(qualifiednameof!(wolf)== THISFILE ~ ".aardvark.aardvark.wolf");
        static assert( symbolnameof!(wolf) == "wolf");
        return 3;
        }
    }
}

// This is just to ensure that the static assert actually gets executed.
const test_aardvark = is (aardvark!(OuterClass) == function);

// Corner case #2: template inside function. This is currently possible only with mixins.
template fox(B, ushort C) {
    class fox {}
}

void wolf() {
        mixin fox!(cfloat, 21);
        static assert(prettynameof!(fox)== "class void " ~ THISFILE ~ ".wolf().fox!(cfloat, int = 21).fox");
        static assert(qualifiednameof!(fox)== THISFILE ~ ".wolf.fox.fox");
        static assert(symbolnameof!(fox)== "fox");
}
}

}
