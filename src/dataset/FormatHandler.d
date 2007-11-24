module dataset.FormatHandler;

abstract class FormatHandler(T)
{
	public FormatHandler next;
	
	protected char[] name();
	
	protected T[][] readValues(char[] file);
	
	protected void writeValues(char[] file, T[][] vecs);
	
	public final T[][] read(char[] file) 
	{
		T[][] ret = readValues(file);
		if (ret) {
			return ret;
		} else {
			if (next) {
				return next.read(file);
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