module dataset.BinaryFormatHandler;

import tango.io.protocol.Reader;
import tango.io.protocol.NativeProtocol;

import dataset.FormatHandler;
import util.Utils;
import util.Allocator;
import util.defines;
import util.Logger;


class BinaryFormatHandler(T) : FormatHandler!(T)
{
	protected final char[] name() {
		return "bin";
	}
	
	private T[][] readBinaryFile(U)(char[] file, int veclen)
	{
		T[][] vecs = null;
		
		if (U.sizeof!=T.sizeof) {
			logger.warn("Data elements size not equal to used type size. Performing conversion.");
		}
		
		ulong fileSize = FilePath(file).fileSize;
		logger.info(sprint("File size is {}: ",fileSize));
		int count = fileSize / (veclen*U.sizeof);
		
		logger.info(sprint("Reading {} features from file {}: ",count,file));
				
		withOpenFile(file, (FileInput stream) {
			Reader read = new Reader(new NativeProtocol(stream,false));
			
			vecs = allocate!(T[][])(count,veclen);
			U[] buffer = new U[veclen];
			scope(exit) delete buffer;
			
			for (int i=0;i<count;++i) {
				read(buffer);
				array_copy(vecs[i],buffer);
			}
		});
		
		return vecs;
	}
	
	protected final T[][] readValues(char[] file) 
	{
		string realFile = null;
		int veclen;
		char[] elemType;
		
		T[][] vecs = null;
		
		withOpenFile(file, (ScanReader read) {
			string header;
			read (header);
			if (header != "BINARY") {
				return;
			}
			
			read(realFile);
			read(veclen);
			read(elemType);	
		});
		
		if (realFile is null) { // wrong format
			return null;
		}
		
		switch (elemType) {
			case "float":
				vecs = readBinaryFile!(float)(realFile,veclen);
				break;
			case "ubyte":
				vecs = readBinaryFile!(ubyte)(realFile,veclen);
				break;
			default:
				logger.error("Element type not supported for binary format.");
		}
		
		return vecs;
	}
	
	protected final void writeValues(char[] file, T[][] vecs)
	{
		char[] bin_file = file ~ ".bin";
	
		withOpenFile(file, (FormatOutput print) {
			print("BINARY").newline;
			print(bin_file).newline;
			print(vecs[0].length).newline;
			print(T.stringof).newline;
		});
		
		withOpenFile(bin_file, (FileOutput stream) {
			for (int i=0;i<vecs.length;++i) {
				stream.write(vecs[i]);
			}
		});
	}



}
