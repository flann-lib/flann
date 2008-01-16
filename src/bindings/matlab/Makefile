
# ------------------ Compilation options ------------------------

LIB_DIRS = 

LIBS = ${LIB_DIRS} -lm -lpthread -lphobos 

INCLUDES = -I../c


WARNS = -W -Wall

ifeq ($(PROFILE),debug)
	CFLAGS = ${WARNS} -g
else
	CFLAGS = ${WARNS} -O3 
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


${DST_DIR}/%.mexglx : ${SRC_DIR}/%.cc Makefile
	${MEX} ${INCLUDES} $< -o $@ -L. -lnn -lgphobos -lm -lpthread


clean:
	rm ${MEXS}