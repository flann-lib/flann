module dataset.FormatHandler;

public import util.Allocator;

abstract class FormatHandler(T)
{
	public FormatHandler next;
	
	protected char[] name();
	
	protected T[][] readValues(char[] file, Allocator allocator);
	
	protected void writeValues(char[] file, T[][] vecs);
	
	
	
	public final T[][] read(char[] file, Allocator allocator) 
	{
		T[][] ret = readValues(file,allocator);
		if (ret) {
			return ret;
		} else {
			if (next) {
				return next.read(file,allocator);
			} else {
				throw new Exception("Format now recognized for file: "~file);
			}
		}
	}
	
	public final void write(char[] file, T[][] vecs, char[] format) 
	{
		if (format == name) {
			writeValues(file,vecs);
		} else {
			if (next) {
				next.write(file,vecs,format);
			} else {
				throw new Exception("No such format: "~format);
			}
		}
	}
}