# ------------------ Compilation options ------------------------

HAS_SQLITE = 1


include Makefile.platform

ifdef UNIT_TEST
	DFLAGS := ${DFLAGS} -unittest -debug 
endif

DFLAGS := ${DFLAGS}

ifeq ($(PROFILER),gprof)
	DFLAGS := ${DFLAGS} -C-q,-pg -K-q,-pg
endif

ifndef PROFILE
	PROFILE := release
endif
	
ifeq ($(PROFILE),debug)
#	DFLAGS := ${DFLAGS} -g -release -C-q,-msse2
	#DFLAGS := ${DFLAGS} -g -debug -C-q,-msse2
	DFLAGS := ${DFLAGS} -g -debug
endif
ifeq (${PROFILE},release)
#	DFLAGS := ${DFLAGS} -O -inline -release -C-q,-fno-bounds-check -C-q,-funroll-loops
	DFLAGS := ${DFLAGS} -O -inline -release -C-q,-pipe
endif


WARNS = -W -Wall
INCLUDES = -Iinclude
LIBS =
LLIBS = ${LIBS} -llc -llgphobos -llm -llpthread -llgcc_s

LIB_DFLAGS := -C-q,-fPIC -lib ${DFLAGS} 

ifeq ($(HAS_SQLITE),1)
	DFLAGS := ${DFLAGS} -version=hasSqlite
	LIBS := ${LIBS} -llsqlite3 -lldl
endif

TARGET = nn
LIB_TARGET = libnn.a
# --------------------- Dirs  ----------------------------
CRT_DIR = $(shell pwd)
SRC_DIR = ${CRT_DIR}/src
LIBS_DIR = ${CRT_DIR}/libs
BUILD_DIR = $(HOME)/tmp/${TARGET}_build/${PROFILE}
OBJ_DIR = ${BUILD_DIR}/obj
LIB_OBJ_DIR = ${BUILD_DIR}/lib_obj
BIN_DIR = ${CRT_DIR}/bin
export DIST_DIR = ${CRT_DIR}

MAIN_FILE=${SRC_DIR}/main.d
LIB_FILE=${SRC_DIR}/bindings/exports.d

export LDPATH=${BIN_DIR}/gdc/lib/gcc/i686-pc-linux-gnu/4.1.2
export PROFILE
# ------------------------ Rules --------------------------------

.PHONY: clean all rebuild compile

all: program library matlab_bindings

clean:
	rm -rf ${BUILD_DIR}/*

rebuild: clean all

matlab_bindings: library
	(cd src/bindings/matlab; make)

program:
	${BIN_DIR}/build -oq${OBJ_DIR} ${MAIN_FILE} -I${SRC_DIR} -I${LIBS_DIR} -of${TARGET} ${DFLAGS} ${LIBS}

library:
	 ${BIN_DIR}/build -oq${LIB_OBJ_DIR} ${LIB_FILE} -I${SRC_DIR} -I${LIBS_DIR} -of${LIB_TARGET} ${LIB_DFLAGS} ${LLIBS}

