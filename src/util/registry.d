module util.registry;


import algo.nnindex;
import util.features;
import util.utils;



alias NNIndex delegate(Features!(float), Params) index_delegate;
static index_delegate[string] indexRegistry;

alias NNIndex delegate(string) load_index_delegate;
static load_index_delegate[string] loadIndexRegistry;


/*------------------- module constructor template--------------------*/

template AlgorithmRegistry(alias ALG,T)
{
	
	import serialization.serializer;
	import std.stream;
	
	static this() 
	{
		indexRegistry[ALG.NAME] = delegate(Features!(T) inputData, Params params) {return cast(NNIndex) new ALG(inputData, params);};
		
		Serializer.registerClassConstructor!(ALG)({return new ALG();});
		
		loadIndexRegistry[ALG.NAME] = delegate(string file) 
			{ Serializer s = new Serializer(file, FileMode.In);
				ALG index;
				s.describe(index);
				return cast(NNIndex)index;
				};
	}
}

