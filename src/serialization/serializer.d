/*
 Project: aggnn
*/


/*******************************************************************************


	Based on work from Tom S (h3r3tic) and Clay Smith
	
	License: See <a href="http://www.opensource.org/licenses/zlib-license.php">zlib/libpng license</a>

*******************************************************************************/


module serialization.serializer; 

import serialization.basicarchive;
import serialization.classregister;
import std.stream;

// required for unittests
debug import std.stdio;
debug import std.gc;

//TODO-FEATURE: Allow for non-intrusive out-of-class/struct describe functions. How?

/*******************************************************************************

	Simplifies saving and loading to a file

*******************************************************************************/
class Serializer
{
public:
	/// open file with given name and filemode (FileMode.In or FileMode.Out)
	this(char[] argFileName, FileMode mode)
	{
			// serializer doesn't work with filemodes besides these two
			assert(mode == FileMode.In || mode == FileMode.Out, "Serializer.open only works with FileMode.In and FileMode.Out"); 
			if(mode == FileMode.In)
				write_or_read = WriteRead.Read;
			else if(mode == FileMode.Out)
				write_or_read = WriteRead.Write;
			
			file = new File(argFileName, mode); 
	}
	
	~this()
	{
		delete file;
	}
	
	mixin TBasicArchive!(Serializer);
	
	/// advances the stream b bytes
	void advance(ulong b)
	{
		file.seek(b, SeekPos.Current);
	}

private:
	/// write data as array of bytes
	void describe_primitive(T)(inout T x)
	{
		if (file.readable) 
		{
			ubyte* ptr = cast(ubyte*)&x;
			file.read(ptr[0 .. x.sizeof]);
		} 
		else
		{
			ubyte* ptr = cast(ubyte*)&x;
			file.write(ptr[0 .. x.sizeof]);
		}
	}
	
	/// return position in stream (for use with seek only)
	ulong position()
	{
		return file.position();
	}
	
	/// seeks to a position get by a call to position
	void seek(ulong pos)
	{
		file.seek(pos, SeekPos.Set);
	}

private:
	/// filestream
	File file;	
}


// integral types
unittest
{
	writefln("Unittest - Serializer - plain data");
	
	bool boolv = true, boolvr;
	byte bytev = 101, bytevr;
	ushort ushortv = ushort.max, ushortvr;
	long longv = -32001, longvr;
	float floatv = 1.123, floatvr;
	real realv = 1e120, realvr;
	real real_infv = real.infinity, real_infvr;
	creal crealv = 5. - 2.3123i, crealvr;
	char charv = 'A', charvr;
	dchar dcharv = cast(dchar)0xFFFFFFF0, dcharvr;
	
	int i = 42;
	int* ptr1 = &i, ptr2 = &i, ptr3 = &i;
	int* ptr1r, ptr2r, ptr3r;

	{
		Serializer s = new Serializer("integral_type_unittest", FileMode.Out);
		
		s.describe(boolv);
		s.describe(bytev);
		s.describe(ushortv);
		s.describe(longv);
		s.describe(floatv);
		s.describe(realv);
		s.describe(real_infv);
		s.describe(crealv);
		s.describe(charv);
		s.describe(dcharv);
		
		s.describe(ptr1);
		s.describe(ptr2);
		s.describe(ptr3, Serializer.Tracking.Off);
		
		delete s;
	}

	{
		Serializer s = new Serializer("integral_type_unittest", FileMode.In);
		
		s.describe(boolvr);
		s.describe(bytevr);
		s.describe(ushortvr);
		s.describe(longvr);
		s.describe(floatvr);
		s.describe(realvr);
		s.describe(real_infvr);
		s.describe(crealvr);
		s.describe(charvr);
		s.describe(dcharvr);
	
		s.describe(ptr1r);
		s.describe(ptr2r);
		s.describe(ptr3r, Serializer.Tracking.Off);
		
		delete s;
	}
	
	remove("integral_type_unittest");
	
	assert(boolv == boolvr);
	assert(bytev == bytevr);
	assert(ushortv == ushortvr);
	assert(longv == longvr);
	assert(floatv == floatvr);
	assert(realv == realvr);
	assert(real_infv == real_infvr);
	assert(crealv == crealvr);
	assert(charv == charvr);
	assert(dcharv == dcharvr);
	assert(*ptr1r == i);
	assert(ptr1r == ptr2r);
	assert(*ptr3r == i);
	assert(ptr3r != ptr1r);

	writefln("Unittest - Serializer - plain data - done");
}


// arrays and associative arrays
unittest
{
	writefln("Unittest - Serializer - arrays and assoc arrays");
	
	real[] realv, realvr;
	realv = [1.0, 2.3, 7];
	int[float] aav, aavr;
	aav[0.1] = 1;
	aav[0.5] = 2;

	{
		Serializer s = new Serializer("array_aa_type_unittest", FileMode.Out);
		
		s.describe(realv);
		s.describe(aav);
		
		delete s;
	}

	{
		Serializer s = new Serializer("array_aa_type_unittest", FileMode.In);
		
		s.describe(realvr);
		s.describe(aavr);
		
		delete s;
	}
	
	remove("array_aa_type_unittest");
	
	assert(realv == realvr);
	assert(aav.keys == aavr.keys);
	assert(aav.values == aavr.values);

	writefln("Unittest - Serializer - array and assoc array - done");
}

// these classes are for unittest only, but I can't declare them inside of unitclass scope
private
{
	struct S
	{
		real a, b;
		void describe(T)(T ar)
		{
			ar.describe(a);
			ar.describe(b);
		}
	}
	
	class A
	{
		public:
			int a;
		
			void describe(T)(T ar)
			{
				ar.describe(a);
			}
	}

	class B : A
	{
		public:
			int b;
		
			void describe(T)(T ar)
			{
				super.describe(ar);
				ar.describe(b);
			}
	}
	
	class C
	{
		public:
			this(int a_)
			{
				a = a_;
			}
			int a;
			
			void describe(T)(T ar)
			{
				ar.describe(a);
			}
	}
	
	
	class E {
		F member;
		
		this()
		{
			member = null;
		}
		
		this (F m) {
			member = m;
		}
		
		void describe(T)(T ar)
		{
			ar.describe(member);
		}
	}
	
	
	class F {
		E member;
		
		this() {
			member = new E(this);
		}
		
		void describe(T)(T ar)
		{
			ar.describe(member);
		}
	}
}

// structs and classes
unittest
{	
	writefln("Unittest - Serializer - classes");
	
	Serializer.registerClass!(A)();
	Serializer.registerClass!(B)();
	Serializer.registerClassConstructor!(C)({ return new C(0); });
	
	Serializer.registerClass!(E)();
	Serializer.registerClass!(F)();
	
	S sv, svr;
	sv.a = 3;
	sv.b = 2;
	
	A av = new A, avr;
	av.a = 99;
	
	B bv = new B, bvr;
	bv.a = 12;
	bv.b = 99999;
	
	A b_in_av = bv, b_in_avr;
	A b_in_a_notrackv = bv, b_in_a_notrackvr;
	
	
	C cv = new C(3), cvr;


	F fv = new F, fvr;
	{
		Serializer s = new Serializer("class_struct_unittest", FileMode.Out);
			
		s.describe(sv);
		s.describe(av);
		s.describe(bv);
		s.describe(b_in_av);
		s.describe(b_in_a_notrackv, Serializer.Tracking.Off);
		s.describe(cv);
		
		s.describe(fv);
		
		delete s;
	}

	{
		Serializer s = new Serializer("class_struct_unittest", FileMode.In);
		
		s.describe(svr);
		s.describe(avr);
		s.describe(bvr);
		s.describe(b_in_avr);
		s.describe(b_in_a_notrackvr, Serializer.Tracking.Off);
		s.describe(cvr);
		
		delete s;
	}
	
	remove("class_struct_unittest");
	
	assert(sv == svr);
	assert(av.a == avr.a);
	assert(bv.a == bvr.a);
	assert(bv.b == bvr.b);
	assert(bv is b_in_av);
	assert(!(bv is b_in_a_notrackvr));
	B bvr2 = cast(B) b_in_a_notrackvr;
	assert(bvr2);
	assert(bv.a == bvr2.a);
	assert(bv.b == bvr2.b);
	assert(cv.a == cvr.a);
	
	writefln("Unittest - Serializer - classes - done");
}
