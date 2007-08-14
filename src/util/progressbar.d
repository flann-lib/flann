/* 
Project: aggnn
*/

module util.progressbar;

import util.logger;


class ProgressBar
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