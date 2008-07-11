
// idouble

module std.typeinfo.ti_idouble;

private import std.typeinfo.ti_double;

class TypeInfo_p : TypeInfo_d
{
    char[] toString() { return "idouble"; }
}

