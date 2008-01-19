
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



SOURCES = nearest_neighbors.cc
SRC_DIR = .
DST_DIR = .
MEXS = ${patsubst %.cc, ${DST_DIR}/%.mexglx, ${SOURCES}}

all: ${MEXS}
	echo ${MEXS}

.phony: all clean


${DST_DIR}/%.mexglx : ${SRC_DIR}/%.cc Makefile ../../../libnn.a
	${MEX} ${INCLUDES} ${CFLAGS} $< -o $@ -L../../.. -L${LDPATH} -lnn -lgphobos -lm -lpthread


clean:
	rm ${MEXS}
