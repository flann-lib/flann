module dataset.BinaryFormatHandler;

import dataset.FormatHandler;
import util.utils;
import util.allocator;
import util.defines;
import util.logger;


class BinaryFormatHandler(T) : FormatHandler!(T)
{
	protected final char[] name() {
		return "binary";
	}
		
	protected final T[][] readValues(char[] file) 
	{
		string realFile = null;
		int veclen,elemSize;
		
		T[][] vecs = null;
		
		withOpenFile(file, (ScanReader read) {
			string header;
			read (header);
			if (header != "BINARY") {
				return;
			}
			
			read(realFile);
			read(veclen);
			read(elemSize);	
		});
		
		if (realFile is null) { // wrong format
			return null;
		}
		
		if (elemSize!=T.sizeof) {
			logger.warn("Data elements size not equal to used type size. Performing conversion.");
		}
		
		ulong fileSize = FilePath(realFile).fileSize;
		int count = fileSize / (veclen*elemSize);
		
		logger.info(sprint("Reading {} features: ",count));
				
		withOpenFile(realFile, (FileInput stream) {
		
			vecs = allocate_mat!(T[][])(count,veclen);
			ubyte[] buffer = new ubyte[veclen*elemSize];
		
			for (int i=0;i<count;++i) {
				stream.read(buffer);
				array_copy(vecs[i],buffer);
			}
		});		
		
		return vecs;
	}
	
	protected final void writeValues(char[] file, T[][] vecs)
	{
		char[] bin_file = file ~ ".bin";
	
		withOpenFile(file, (FormatOutput print) {
			print("BINARY").newline;
			print(bin_file).newline;
			print(vecs[0].length).newline;
			print(T.sizeof).newline;
		});
		
		withOpenFile(bin_file, (FileOutput stream) {
			for (int i=0;i<vecs.length;++i) {
				stream.write(vecs[i]);
			}
		});
	}



}