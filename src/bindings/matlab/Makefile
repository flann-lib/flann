
# ------------------ Compilation options ------------------------

LIB_DIRS = 

LIBS = ${LIB_DIRS}

INCLUDES = -I../c


ifeq ($(PROFILE),debug)
	CFLAGS = -g
else
	CFLAGS = -O
endif
CXXFLAGS = ${CFLAGS}
LINKLAGS = 

# Use the gcc compiler.
CC = gcc
#CXX = gfilt
CXX = g++
DC = gdc
LINK = g++
MEX = mex



SRC_DIR = .


all: ${BUILD_DIR}/matlab/nearest_neighbors.mexglx

.phony: all clean


${BUILD_DIR}/matlab/%.mexglx : ${SRC_DIR}/%.cc Makefile ${BUILD_DIR}/libfann.a
	@if [ ! -d ${BUILD_DIR}/matlab ] ; then mkdir ${BUILD_DIR}/matlab; fi
	${MEX} ${INCLUDES} ${CFLAGS} $< -o $@ -L${BUILD_DIR} -L${LDPATH} -lfann -lgphobos -lm -lpthread
	cp ${SRC_DIR}/*.m ${BUILD_DIR}/matlab


clean:
