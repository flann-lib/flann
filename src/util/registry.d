module util.registry;


import algo.nnindex;
import dataset.features;
import util.utils;

import util.defines;


template IndexConstructor(T) {
	alias NNIndex function(Features!(T), Params) IndexConstructor;
}

template indexRegistry(T) {
	IndexConstructor!(T)[string] indexRegistry;
}

// alias NNIndex delegate(string) load_index_delegate;
// static load_index_delegate[string] loadIndexRegistry;


/*------------------- module constructor template--------------------*/

template AlgorithmRegistry(alias ALG,T)
{
	
// 	import serialization.serializer;
// 	import std.stream;
	
	static this() 
	{
		indexRegistry!(T)[ALG.NAME] = function(Features!(T) inputData, Params params) {return cast(NNIndex) new ALG(inputData, params);};
		
/+		Serializer.registerClassConstructor!(ALG)({return new ALG();});
		
		loadIndexRegistry[ALG.NAME] = delegate(string file) 
			{ Serializer s = new Serializer(file, FileMode.In);
				ALG index;
				s.describe(index);
				return cast(NNIndex)index;
				};+/
	}
}

