
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


all: mexfile

.phony: all clean


mexfile : ${SRC_DIR}/nearest_neighbors.cc Makefile ${LIB_TARGET}
	@mkdir -p ${BUILD_DIR}/matlab
	${MEX} ${INCLUDES} ${CFLAGS} $< -o ${BUILD_DIR}/matlab/nearest_neighbors -L${BUILD_DIR}/lib -lflann -lgphobos -lm -lpthread
	cp ${SRC_DIR}/*.m ${BUILD_DIR}/matlab


clean:
	rm -rf ${BUILD_DIR}/matlab