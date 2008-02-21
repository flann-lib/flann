/* 
Project: nn
*/

module output.Console;

import tango.io.Console;
import tango.core.Vararg;
import tango.text.convert.Layout;

import util.Logger;
import util.defines;


public ConsoleWriter console;

static this()
{
	console = new ConsoleWriter();
}

class ConsoleWriter {

	private Layout!(char) layout;
	
	alias write opCall;
	
	public this() 
	{
		layout = new Layout!(char);	
	}

	typeof(this) write(...)
	{
		char[] format = va_arg!(char[])(_argptr);
		layout((char[] s){return Cout.stream.write(s);},_arguments[1..$],_argptr,format);
		Cout.flush();
		
		return this;
	}
}

void showOperation(string message, void delegate() action)
{
	logger.info(message~"... ");
	action();
	logger.info("done");
}


typedef void delegate() Ticker;

void showProgressBar(int maxValue, int maxWidth, void delegate(Ticker ticker) action)
{
	int crtValue = 0;
	int crtWidth = 0;

	void tick()
	{
		if (crtValue<=maxValue) {
			crtValue++;
		}
		
		if (crtValue==maxValue) {
				console("\x08\x08\x08\x08\x08\x08=====]\n");
			crtValue++;
		}
		else if (crtValue<maxValue) {
			int newWidth = (crtValue*maxWidth)/maxValue;
			if (newWidth!=crtWidth) {
				
				int percent = (100*crtValue)/maxValue;
			
				console("\x08\x08\x08\x08\x08\x08=({:D2}%)>",percent);
				crtWidth++;
			}
		}
	}

	console("[      ");	
	
	action(&tick);
}
