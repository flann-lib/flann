
LIBS=-lfann -lgphobos -lm -lpthread
LIB_DIRS=-L../../.. -L../../../bin/gdc/lib/gcc/i686-pc-linux-gnu/4.1.2/ 

SOURCES=$(wildcard *.c)
PROGS=$(patsubst %.c,%,${SOURCES})

all: ${PROGS}

clean:
	rm ${PROGS}

% : %.c
	g++ $< -o $@ ${LIB_DIRS} ${LIBS}
