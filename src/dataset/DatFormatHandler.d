module dataset.DatFormatHandler;

import tango.core.Array : find, count, countIf;
import tango.text.Util : trim,split;

import dataset.FormatHandler;
import util.Utils;
import util.Allocator;
import util.defines;
import output.Console;

class DatFormatHandler(T) : FormatHandler!(T)
{

	protected final char[] name() {
		return "dat";
	}

	private char guessDelimiter(string line)
	{
		const string numberChars = "01234567890.e+-";
		const int length = numberChars.length;
		int pos = 0;
			
		while (numberChars.find(line[pos])==length) {
			pos++;
		}
		while (numberChars.find(line[pos])!=length) {
			pos++;
		}
		
		return line[pos];
	}
	
	
	private bool isCorrectFormat(char[] file, out int lines, out int columns, out char[] delimiter)
	{
		bool correctFormat = true;
		withOpenFile(file, (LineInput stream) {
			// get first non-empty line
			char[] line = stream.next;			
			while (line !is null && line.length==0)	line = stream.next;
			delimiter ~= guessDelimiter(line);

			string[] tokens = trim(line).split(delimiter);
			columns = countIf(tokens,(char[] e) {return e.length!=0;});
			
			// check to see if the next few lines have the same number of elements
			for (int i=0;i<10;++i) {
				line = stream.next;
				while (line !is null && line.length==0)	line = stream.next;
				tokens = trim(line).split(delimiter);
				int cnt = countIf(tokens,(char[] e) {return e.length!=0;});
				if (cnt != columns) {
					correctFormat = false;
					return;
				}
			}
		});
		
		if (correctFormat) {
			char buffer[16*1024];		
			lines = 0;
			withOpenFile(file, (FileInput stream) {
				uint ret;
				while ((ret=stream.read(buffer))!=stream.Eof) {
					lines += count(buffer[0..ret],'\n');
				}
			});
		}
		
		return correctFormat;
	}
	
	
	protected final T[][] readValues(char[] file)
	{
		int lines,columns;
		char[] delimiter;
		if (!isCorrectFormat(file, lines,columns,delimiter)) {
			return null;
		}
		
		// allocate memory for the data
		T[][] vecs = allocate!(T[][])(lines,columns);
				
		// read in
		withOpenFile(file, (ScanReader read) {
			foreach (index,vec; vecs) {
				read(vec);
			}
		});
		return vecs;
		
	}
	
		
	protected final void writeValues(char[] file, T[][] vecs)
	{
		withOpenFile(file, (FormatOutput write) {
			foreach (vec;vecs) {
				foreach (i,elem;vec) {
					if (i!=0) write(" ");
					if (is (T==float)) {
						write.format("{:e10}",elem);
					} else {
						write.format("{}",elem);
					}
				}
				write.newline;
			}
		});
	}
}