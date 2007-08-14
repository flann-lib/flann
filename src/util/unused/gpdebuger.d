/*
Project: _aggnn
*/

private import std.stdio;
private import std.string;
private import std.c.string;
private import std.c.unix.unix;
private import std.process;



class GPDebuger
{
static:

private const char[] program = "octave";
private const char[][] data_files;

int fifo[2];

private static void startProcess() 
{	
	pipe(fifo);
	
	pid_t pid = fork();
	if (pid==-1) {
		throw new Exception("Cannot fork.");
	}
	if (pid==0) {
		close(fifo[1]);
		close(0);
		int fd = dup(fifo[0]);
		
		execvp(program,[null]);
		printf("Shouldn't get here!\n");
	}
	else {
		close(fifo[0]);
	}
}


public static void sendCommand(char[] command)
{
	static bool processStarted = false;
	
	if (!processStarted) {
		startProcess();
		processStarted = true;
	}

	write(fifo[1],toStringz(command~"\n"),command.length+1);	
}

public static void plotPoint(float[] point, char[] type = "b*", bool pause = false)
{
	char buffer[100];
	
	sprintf(&buffer[0],"plot(%f,%f,'%s')",point[0],point[1],toStringz(type));
	
	int size = strlen(&buffer[0]);
	sendCommand(buffer[0..size]);
	
	if (pause) {
		getchar();
	}
}

public static void plotLine(float[] from, float[] to, char[] type = "r" )
{
	char buffer[100];
	
	sprintf(&buffer[0],"plot([%f, %f], [%f %f],'%s')",from[0],to[0],from[1],to[1],toStringz(type));
//	printf("plot([%f, %f], [%f %f],'%s')\n",from[0],to[0],from[1],to[1],toStringz(type));
	
	int size = strlen(&buffer[0]);
	sendCommand(buffer[0..size]);
}

public static void wait()
{
	int status;
	.wait(&status);
}

unittest {
	startProcess();
			
	sendCommand("hold on");
	
	plotPoint([1.0,1.0],"r*");
 	plotPoint([2.0,2.0],"b+");
 	plotPoint([1.5,1.8],"g+");
	
 	plotLine([1.5,1.8],[2.0,2.0],"g");
		
	

	int status;
	.wait(&status);

}	
	


}