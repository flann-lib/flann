
/**
 * Macros:
 *	WIKI = Phobos/StdCompiler
 */

/**
 * Identify the compiler used and its various features.
 * Authors: Walter Bright, www.digitalmars.com
 * License: Public Domain
 */


module std.compiler;

const
{
    /// Vendor specific string naming the compiler, for example: "Digital Mars D".
    string name = __VENDOR__;

    /// Master list of D compiler vendors.
    enum Vendor
    {
	DigitalMars = 1,	/// Digital Mars
    }

    /// Which vendor produced this compiler.
    Vendor vendor = Vendor.DigitalMars;


    /**
     * The vendor specific version number, as in
     * version_major.version_minor
     */
    uint version_major = __VERSION__ / 1000;
    uint version_minor = __VERSION__ % 1000;	/// ditto


    /**
     * The version of the D Programming Language Specification
     * supported by the compiler.
     */
    uint D_major = 1;
    uint D_minor = 0;
}
