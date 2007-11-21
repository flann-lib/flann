/* 
Project: nn
*/

module output.console;

import util.logger;
import util.defines;


typedef void delegate() Ticker;

void showOperation(string message, void delegate() action)
{
	Logger.log(Logger.INFO, message~"... ");
	action();
	Logger.log(Logger.INFO, "done\n");
}



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
			Logger.log(Logger.INFO,"\x08\x08\x08\x08\x08\x08=====]\n");
			crtValue++;
		}
		else if (crtValue<maxValue) {
			int newWidth = (crtValue*maxWidth)/maxValue;
			if (newWidth!=crtWidth) {
				
				int percent = (100*crtValue)/maxValue;
			
				Logger.log(Logger.INFO,"\x08\x08\x08\x08\x08\x08=(%2d%%)>",percent);
				crtWidth++;
			}
		}
	}

	Logger.log(Logger.INFO,"[      ");
	
	action(&tick);
}

void showProgressBarStep(int maxValue, int maxWidth, void delegate(int index) action)
{
	int crtValue = 0;
	int crtWidth = 0;

	void tick()
	{
		if (crtValue<=maxValue) {
			crtValue++;
		}
		
		if (crtValue==maxValue) {
			Logger.log(Logger.INFO,"\x08\x08\x08\x08\x08\x08=====]\n");
			crtValue++;
		}
		else if (crtValue<maxValue) {
			int newWidth = (crtValue*maxWidth)/maxValue;
			if (newWidth!=crtWidth) {
				
				int percent = (100*crtValue)/maxValue;
			
				Logger.log(Logger.INFO,"\x08\x08\x08\x08\x08\x08=(%2d%%)>",percent);
				crtWidth++;
			}
		}
	}

	Logger.log(Logger.INFO,"[      ");
	
	for (int index=0;index<maxValue;++index) {
		action(index);
		tick();
	}
}


/*
private class ProgressBar
{
	int crtValue;
	int maxValue;
	
	int maxWidth;
	int crtWidth;


	public this(int value, int width)
	{
		maxValue = value;
		maxWidth = width;
	}
	
	
	public:
	
	void start()
	{
		crtValue = 0;
		crtWidth = 0;
		
		Logger.log(Logger.INFO,"[      ");
	}
	
	void tick()
	{
		if (crtValue<=maxValue) {
			crtValue++;
		}
		
		if (crtValue==maxValue) {
			Logger.log(Logger.INFO,"\x08\x08\x08\x08\x08\x08=====]\n");
			crtValue++;
		}
		else if (crtValue<maxValue) {
			int newWidth = (crtValue*maxWidth)/maxValue;
			if (newWidth!=crtWidth) {
				
				int percent = (100*crtValue)/maxValue;
			
				Logger.log(Logger.INFO,"\x08\x08\x08\x08\x08\x08=(%2d%%)>",percent);
				crtWidth++;
			}
		}
	}

}
*/