
ifndef BUILD_DIR
	BUILD_DIR=../../../build/
endif

LIBS=-lflann -lgphobos -lm -lpthread
LIB_DIRS=-L${BUILD_DIR}/lib

SOURCES=flann_test.c test_clusters.c
PROGS=$(patsubst %.c,%,${SOURCES})

all: ${PROGS}
	@mkdir -p ${BUILD_DIR}/include
	cp flann.h ${BUILD_DIR}/include

clean:
	rm ${PROGS}

% : %.c
	g++ -g $< -o $@ ${LIB_DIRS} ${LIBS}

% : %.cc
	g++ -g $< -o $@ ${LIB_DIRS} ${LIBS}
