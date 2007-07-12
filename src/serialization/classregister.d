/*******
 Project: aggnn
*/



module serialization.classregister; 

/**

 Any serializer needs to be able to:
 - create class instances by classinfo (possibly supporting not-default-constructible objects later)
 - call the describe function of the most derived class when getting a base class

 This template is supposed to be used as a public mixin
 and provides the registration functionality for the user.

 It could also go into the ClassRegister template below, but would make using it 'look odd'
 
*/
template TClassRegisterPublicInterface(AR)
{
	/// registers a default-constructible class with the archive
	static void registerClass(T)(char[] name = T.mangleof)
	{
		if(name in ClassRegister!(AR).by_name)
			throw new Exception("There's already a class registered with the name " ~ name);
		
		auto entry = new ClassRegister!(AR).ClassDescriptionDefault!(T)(name);
		ClassRegister!(AR).by_name[name] = entry;
		ClassRegister!(AR).by_classinfo[T.classinfo] = entry;
	}
	
	/// registers a class with a construction function with the archive
	static void registerClassConstructor(T)(T delegate() constructor, char[] name = T.mangleof)
	{
		if(name in ClassRegister!(AR).by_name)
			throw new Exception("There's already a class registered with the name " ~ name);
		
		auto entry = new ClassRegister!(AR).ClassDescription!(T)(name, constructor);
		ClassRegister!(AR).by_name[name] = entry;
		ClassRegister!(AR).by_classinfo[T.classinfo] = entry;
	}
}

/// keeps static class registration data per archive type
template ClassRegister(AR)
{
	interface ClassDescriptionBase
	{
		public:
			Object create();
			char[] name();
			void call_describe(void* x, AR ar);
	}

	class ClassDescriptionDefault(T) : ClassDescriptionBase
	{
		public:
			this(char[] name)
			{
				name_ = name;
			}
			
			T create()
			{
				return new T;
			}
			
			char[] name()
			{
				return name_;
			}
			
			void call_describe(void* x, AR ar)
			{
				(cast(T) x).describe(ar);
			}
			
		private:
			char[] name_;
	}
	
	class ClassDescription(T) : ClassDescriptionBase
	{
		public:
			this(char[] name, T delegate() constructor)
			{
				name_ = name;
				constructor_ = constructor;
			}
			
			T create()
			{
				return constructor_();
			}			
			
			char[] name()
			{
				return name_;
			}
			
			void call_describe(void* x, AR ar)
			{
				(cast(T) x).describe(ar);
			}
		private:
			T delegate() constructor_;
			char[] name_;
	}
	
	// class information
	static ClassDescriptionBase[char[]] by_name;
	static ClassDescriptionBase[ClassInfo] by_classinfo;
}
