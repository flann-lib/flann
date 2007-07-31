/* 
Project: aggnn
*/


import std.stdio;


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
		
		writef("[      ");
	}
	
	void tick()
	{
		if (crtValue<=maxValue) {
			crtValue++;
		}
		
		if (crtValue==maxValue) {
			writef("\x08\x08\x08\x08\x08\x08=====]\n");
			crtValue++;
		}
		else {
			int newWidth = (crtValue*maxWidth)/maxValue;
			if (newWidth!=crtWidth) {
				
				int percent = (100*crtValue)/maxValue;
			
				writef("\x08\x08\x08\x08\x08\x08=(%2d%%)>",percent);
				fflush(stdout);
				crtWidth++;
			}
		}
	}

}