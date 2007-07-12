/*******
 Project: aggnn
*/

module serialization.basicarchive;

import serialization.classregister;

template TBasicArchive(AR)
{
public:
	
	/// true if serializer is reading a file
	bool reading() { return write_or_read == WriteRead.Read; }

	/// true if serializer is writing a file
	bool writing() { return write_or_read == WriteRead.Write; }
	
	/// used in describe to state whether addresses should be tracked or not
	enum Tracking
	{
		Default,
		Off
	}
	
	/*******************************************************************************
	
			Describe : save/load any data type
			TRACKING.DEFAULT means classes and pointers will get tracked
			TRACKING.OFF disables tracking
	
	*******************************************************************************/
	void describe(T)(inout T dat, Tracking tracking = Tracking.Default) 
	{
		// resolve typedefs
		static if (is(T TYPEDEF == typedef))
			alias TYPEDEF TYPE;
		else
			alias T TYPE;
		
		static if (is(TYPE == class))
		{
			if (tracking == Tracking.Off)
				describe_class!(TYPE)(dat);
			else
			{
				TYPE* ptr_dat = cast(TYPE*) dat;
				describe_pointer!(TYPE)(ptr_dat);
				dat = cast(TYPE) ptr_dat;
			}
		}

		else static if (is(TYPE == struct))
		{
			describe_struct!(TYPE)(dat);
		} 
		
		else static if (is(TYPE ARRAYTYPE : ARRAYTYPE[]))
		{
			// pass tracking parameter to apply to the array members
			describe_array!(ARRAYTYPE)(dat, tracking);
		}
		
		else static if (is(TYPE : real)) 
		{
			describe_primitive(dat);
		}
		
		else static if (is(TYPE : creal))
		{
			typeof(dat.re) re_part = dat.re, im_part = dat.im;
			describe_primitive(re_part);
			describe_primitive(im_part);
			dat = re_part + im_part * 1i;
		}
		
		else static if (is(TYPE POINTERTYPE == POINTERTYPE*))
		{
			if (tracking == Tracking.Off)
			{
				static if (is(POINTERTYPE == class))
				{
					static assert(0, "class pointers are not supported");
				}
				else
				{
					if (write_or_read == WriteRead.Read)
					{
						POINTERTYPE value;
						describe!(POINTERTYPE)(value);
						dat = new POINTERTYPE;
						*dat = value;
					}
					else
						describe!(POINTERTYPE)(*dat);
				}
			}
			else
				describe_pointer!(POINTERTYPE)(dat);
		}
		
		else static if (is(typeof(TYPE.values[$])[typeof(TYPE.keys[$])] == TYPE) && 
					is(typeof(TYPE.values) VALUE == VALUE[]) && 
					is(typeof(TYPE.keys) KEY == KEY[]))
		{
			describe_aa!(KEY, VALUE)(dat, tracking, tracking);
		}
		
		else
		{
			static assert(0, "describe called with unsupported type");
		}		
	}
	
	/// the describe call above will not work with static arrays, since they can't be inout
	void describe_staticarray(T)(T[] array, Tracking tracking = Tracking.Default)
	{
		describe!(T[])(array, tracking);
	}
	
	/// Serialize associative arrays. Might be called explicitly to control tracking.
	void describe_aa(KEY, VALUE)(inout VALUE[KEY] aa, Tracking tracking_keys = Tracking.Default, Tracking tracking_values = Tracking.Default)
	{
		KEY[] keys;
		VALUE[] values;
		
		if (write_or_read == WriteRead.Write)
		{
			keys = aa.keys;
			values = aa.values;
		}
		
		describe(keys, tracking_keys);
		describe(values, tracking_values);
		
		if (write_or_read == WriteRead.Read)
		{
			aa = aa.init;
			
			foreach(uint i, key; keys)
			{
				aa[key] = values[i];
			}
		}		
	}
	
	mixin TClassRegisterPublicInterface!(AR);

protected:
	/// serialize structs
	void describe_struct(T)(inout T x)
	{
		x.describe(this);
	}
	
	/// serialize classes
	void describe_class(T)(inout T x)
	{
		if (write_or_read == WriteRead.Write)
		{
			// check if x's type is registered
			if(!(x.classinfo in class_register.by_classinfo))
			{
				// if T is default constructible and serializable, not registering isn't an error
				static if( is(typeof(new T)) && is(typeof(T.describe!(AR))) )
				{
					// if we're not serializing through a base pointer, register!
					if(T.classinfo is x.classinfo)
						registerClass!(T)();
					else
						throw new Exception("Trying to write unregistered class " ~ x.classinfo.name ~ 
								" through class reference of type " ~ T.classinfo.name ~ ".\nYou need to register the former ahead of time.");
				}
				else // otherwise, it is!
				{
					throw new Exception("Trying to write unregistered class " ~ x.classinfo.name ~ 
							"\nIt is not default-constructible or not serializable, so you need to register it ahead of time.");
				}
			}
			
			char[] name = class_register.by_classinfo[x.classinfo].name;
			describe_array(name);
			class_register.by_classinfo[x.classinfo].call_describe(cast(void *)x, this);
		}
		else if (write_or_read == WriteRead.Read)
		{
			if (x !is null)
				throw new Exception("Class must be null to be read");
			
			// make sure we get back to the initial position on throwing an exception
			auto start_pos = position();
			scope(failure) seek(start_pos);
			
			char[] name;
			describe_array(name);
			
			if (!(name in class_register.by_name))
			{
				// if the name is the mangle of the class reference type we're serializing through
				// it is ok to just default-register the class
				if(name == T.mangleof)
				{
					// can only default-register if default-constructible and serializable					
					static if( is(typeof(new T)) && is(typeof(T.describe!(AR))) )
						registerClass!(T)();
					else
						throw new Exception("Trying to read unregistered class - probably " ~ T.classinfo.name ~ 
															 " - through a class reference of that type.\nBut " ~ T.classinfo.name ~
															 " is not default-constructible or not serializable, " ~
															 "so you need to register it ahead of time.");
				}
				else
				{
					throw new Exception("Trying to read class that has been written with the " ~ name ~ " tag " ~
							"through a class reference of type " ~ T.classinfo.name ~ "." ~
							"\nThe tag is unknown, you need to register this tag ahead of time.");
				}
			}
			
			x = cast(T) class_register.by_name[name].create();
			class_register.by_name[name].call_describe(cast(void*)x, this); 
		}
	}

	/// serialize dynamic arrays
	void describe_array(T)(inout T[] x, Tracking tracking = Tracking.Default)
	{
		uint len;
		if (write_or_read == WriteRead.Read)
		{
				describe_primitive(len);
				x.length = len;
		} 
		else
		{
				len = x.length;
				describe_primitive(len);
		}

		for (uint i = 0; i < x.length; ++i)
				describe(x[i], tracking);
	}
	
	/// serialize pointers
	void describe_pointer(T)(inout T* x)
	{
		byte data_signal = 0x00;
		byte no_data_signal = 0x01;
		
		if (write_or_read == WriteRead.Read)
		{
			// make sure we get back to the initial position on throwing an exception
			auto start_pos = position();
			scope(failure) seek(start_pos);
		
			// if next byte is data_signal data is incoming, else reference to established ptr
			byte next_byte;
			describe_primitive(next_byte);
			if (next_byte == data_signal)
			{
				T new_data;
				describe(new_data, Tracking.Off);
				static if (is(T == class))
				{
					x = cast(T*) new_data;
				}
				else
				{
					x = new T;
					*x = new_data;
				}
				
				read_pointers.length = read_pointers.length + 1;
				read_pointers[$-1] = x;
			}
			else if(next_byte == no_data_signal)
			{
				uint data_nr = uint.max;
				describe_primitive(data_nr);
				
				if (data_nr >= read_pointers.length)
					throw new Error("Inconsistent archive or sequence error:\nTried to access pointer that's not been read yet.");
				
				x = cast(T*) read_pointers[data_nr];
			}
			else 
				throw new Error("Inconsistent archive, expected data_signal or no_data_signal on pointer read.");
		}
		else
		{
			// if we haven't written this already, write data_signal + data; else write no_data_signal + sequence nr
			if (!(x in written_pointers))
			{
				describe_primitive(data_signal);
				static if (is(T == class))
				{
					T obj = cast(T) x;
					describe(obj, Tracking.Off);
				}
				else
					describe(*x, Tracking.Off);
				
				// there's a side effect if you put this in one line
				uint n_pointers = written_pointers.length;
				written_pointers[x] = n_pointers;
			}
			else
			{
				describe_primitive(no_data_signal);
				describe(written_pointers[x]);
			}
		}
	}
	
	/// enum describing whether we're writing or reading
	enum WriteRead
	{
		Write,
		Read
	}
	
	WriteRead write_or_read;

	/// pointers written/read
	void*[] read_pointers;
	uint[void*] written_pointers;

	/// alias to class register for this archive type
	alias ClassRegister!(AR) class_register;
}
