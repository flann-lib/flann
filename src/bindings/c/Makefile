
LIBS=-lflann -lgphobos -lm -lpthread
LIB_DIRS=-L${BUILD_DIR}/lib -L../../../bin/gdc/lib/gcc/i686-pc-linux-gnu/4.1.2/ 

SOURCES=flann_test.c test_clusters.c
PROGS=$(patsubst %.c,%,${SOURCES})

all: ${PROGS}
	@mkdir -p ${BUILD_DIR}/include
	cp flann.h ${BUILD_DIR}/include

clean:
	rm ${PROGS}

% : %.c
	g++ -g $< -o $@ ${LIB_DIRS} ${LIBS}
