// Written in the D programming language

/**
 * Information about the target operating system, environment, and CPU
 * Authors: Walter Bright, www.digitalmars.com
 * License: Public Domain
 * Macros:
 *	WIKI = Phobos/StdSystem
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2007
*/

// Information about the target operating system, environment, and CPU

module std.system;

const
{

    // Operating system family
    enum Family
    {
	Win32 = 1,		// Microsoft 32 bit Windows systems
	linux,			// all linux systems
	Unix,                  // Unix-like
	NoSystem               // No operating system
    }

    version (Win32)
    {
	Family family = Family.Win32;
    }
    else version (linux)
    {
	Family family = Family.linux;
    }
    else version (Unix)
    {
	Family family = Family.Unix;
    }	     
    else version (NoSystem)
    {
	Family family = Family.NoSystem;
    }
    else
    {
	static assert(0);
    }

    // More specific operating system name
    enum OS
    {
	Windows95 = 1,
	Windows98,
	WindowsME,
	WindowsNT,
	Windows2000,
	WindowsXP,

	RedHatLinux,
    }

    /// Byte order endianness

    enum Endian
    {
	BigEndian,	/// big endian byte order
	LittleEndian	/// little endian byte order
    }

    version(LittleEndian)
    {
	/// Native system endianness
        Endian endian = Endian.LittleEndian;
    }
    else
    {
        Endian endian = Endian.BigEndian;
    }
}

// The rest should get filled in dynamically at runtime

OS os = OS.WindowsXP;

// Operating system version as in
// os_major.os_minor
uint os_major = 4;
uint os_minor = 0;


