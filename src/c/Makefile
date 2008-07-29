
LIBS=-lflann -lgphobos -lm -lpthread
LIB_DIRS=-L${BUILD_DIR}/lib

SOURCES=flann_test.c test_clusters.c
PROGS=$(patsubst %.c,%,${SOURCES})

all: ${PROGS}
	mkdir -p ${BUILD_DIR}/include
	cp flann.h ${BUILD_DIR}/include

clean:
	-rm ${PROGS}
	-rm -rf ${BUILD_DIR}/include

% : %.c
	g++ -g $< -o ${BUILD_DIR}/bin/$@ ${LIB_DIRS} ${LIBS}

% : %.cc
	g++ -g $< -o ${BUILD_DIR}/bin/$@ ${LIB_DIRS} ${LIBS}
