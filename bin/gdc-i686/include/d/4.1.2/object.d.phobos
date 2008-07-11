
// Implementation is in internal\object.d

module object;

//alias bit bool;
alias bool bit;

alias typeof(int.sizeof) size_t;
alias typeof(cast(void*)0 - cast(void*)0) ptrdiff_t;
alias size_t hash_t;

alias char[] string;
alias wchar[] wstring;
alias dchar[] dstring;

extern (C)
{   int printf(char *, ...);
    void trace_term();
}

class Object
{
    void print();
    char[] toString();
    hash_t toHash();
    int opCmp(Object o);
    int opEquals(Object o);

    final void notifyRegister(void delegate(Object) dg);
    final void notifyUnRegister(void delegate(Object) dg);

    static Object factory(char[] classname);
}

struct Interface
{
    ClassInfo classinfo;
    void *[] vtbl;
    ptrdiff_t offset;		// offset to Interface 'this' from Object 'this'
}

class ClassInfo : Object
{
    byte[] init;		// class static initializer
    char[] name;		// class name
    void *[] vtbl;		// virtual function pointer table
    Interface[] interfaces;
    ClassInfo base;
    void *destructor;
    void (*classInvariant)(Object);
    uint flags;
    //	1:			// IUnknown
    //	2:			// has no possible pointers into GC memory
    //	4:			// has offTi[] member
    //	8:			// has constructors
    void *deallocator;
    OffsetTypeInfo[] offTi;
    void* defaultConstructor;	// default Constructor

    static ClassInfo find(char[] classname);
    Object create();
}

struct OffsetTypeInfo
{
    size_t offset;
    TypeInfo ti;
}

class TypeInfo
{
    hash_t getHash(void *p);
    int equals(void *p1, void *p2);
    int compare(void *p1, void *p2);
    size_t tsize();
    void swap(void *p1, void *p2);
    TypeInfo next();
    void[] init();
    uint flags();
    // 1:			// has possible pointers into GC memory
    OffsetTypeInfo[] offTi();
}

class TypeInfo_Typedef : TypeInfo
{
    TypeInfo base;
    char[] name;
    void[] m_init;
}

class TypeInfo_Enum : TypeInfo_Typedef
{
}

class TypeInfo_Pointer : TypeInfo
{
    TypeInfo m_next;
}

class TypeInfo_Array : TypeInfo
{
    TypeInfo value;
}

class TypeInfo_StaticArray : TypeInfo
{
    TypeInfo value;
    size_t len;
}

class TypeInfo_AssociativeArray : TypeInfo
{
    TypeInfo value;
    TypeInfo key;
}

class TypeInfo_Function : TypeInfo
{
    TypeInfo next;
}

class TypeInfo_Delegate : TypeInfo
{
    TypeInfo next;
}

class TypeInfo_Class : TypeInfo
{
    ClassInfo info;
}

class TypeInfo_Interface : TypeInfo
{
    ClassInfo info;
}

class TypeInfo_Struct : TypeInfo
{
    char[] name;
    void[] m_init;

    uint function(void*) xtoHash;
    int function(void*,void*) xopEquals;
    int function(void*,void*) xopCmp;
    char[] function(void*) xtoString;

    uint m_flags;
}

class TypeInfo_Tuple : TypeInfo
{
    TypeInfo[] elements;
}

class TypeInfo_Const : TypeInfo
{
    TypeInfo next;
}

class TypeInfo_Invariant : TypeInfo_Const
{
}

// Recoverable errors

class Exception : Object
{
    char[] msg;

    this(char[] msg);
    void print();
    char[] toString();
}

// Non-recoverable errors

class Error : Exception
{
    Error next;

    this(char[] msg);
    this(char[] msg, Error next);
}

