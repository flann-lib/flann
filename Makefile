# ------------------ Compilation options ------------------------


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
	DFLAGS := ${DFLAGS} -g -debug
endif
ifeq (${PROFILE},release)
#	DFLAGS := ${DFLAGS} -O -inline -release -C-q,-fno-bounds-check -C-q,-funroll-loops
#	DFLAGS := ${DFLAGS} -O -inline -release -C-q,-pipe -C-q,-march=pentium4
	DFLAGS := ${DFLAGS} -O -inline -release -C-q,-pipe -C-q,-march=i686
endif

WARNS = -W -Wall
INCLUDES = -Iinclude
LIBS =
LLIBS = ${LIBS} -llc -llgphobos -llm -llpthread -llgcc_s

LIB_DFLAGS := -lib ${DFLAGS} 

# --------------------- Dirs  ----------------------------
CRT_DIR = $(shell pwd)
SRC_DIR = ${CRT_DIR}/src
LIBS_DIR = ${CRT_DIR}/libs
BUILD_DIR = ${CRT_DIR}/build
TMP_DIR= ${CRT_DIR}/tmp
OBJ_DIR = ${TMP_DIR}/build/${PROFILE}/obj
LIB_OBJ_DIR = ${TMP_DIR}/build/${PROFILE}/lib_obj
BIN_DIR = ${CRT_DIR}/bin

MAIN_FILE=${SRC_DIR}/main.d
LIB_FILE=${SRC_DIR}/bindings/exports.d

TARGET = ${BUILD_DIR}/bin/flann
export LIB_TARGET = ${BUILD_DIR}/lib/libflann.a


LDPATH=${BIN_DIR}/gdc/lib/gcc/i686-pc-linux-gnu/4.1.2
export PROFILE BUILD_DIR LDPATH
# ------------------------ Rules --------------------------------

.PHONY: clean all rebuild compile

all: program library c_bindings matlab_bindings python_bindings

clean:
	rm -rf ${BUILD_DIR}/*
	-(cd src/bindings/matlab; make clean)
	-(cd src/bindings/c; make clean)

deapclean: clean
	rm -rf ${OBJ_DIR}
	rm -rf ${LIB_OBJ_DIR}

rebuild: clean all

matlab_bindings: library
	(cd src/bindings/matlab; make)

python_bindings: library
	cp -r src/bindings/python_dist ${BUILD_DIR}
	-rm -rf ${BUILD_DIR}/python
	mv ${BUILD_DIR}/python_dist ${BUILD_DIR}/python
	(cd ${BUILD_DIR}/python; sage -python create_python_base.py)

c_bindings: library
	(cd src/bindings/c; make)

program:
	@mkdir -p ${BUILD_DIR}/bin
	${BIN_DIR}/build -oq${OBJ_DIR} ${MAIN_FILE} -I${SRC_DIR} -I${LIBS_DIR} -of${TARGET} ${DFLAGS} ${LIBS}

library:
	@mkdir -p ${BUILD_DIR}/lib
	${BIN_DIR}/build -oq${LIB_OBJ_DIR} ${LIB_FILE} -I${SRC_DIR} -I${LIBS_DIR} -of${LIB_TARGET} ${LIB_DFLAGS} ${LLIBS}
	cp `${BIN_DIR}/gdc/bin/gdc -print-file-name=libgphobos.a` ${BUILD_DIR}/lib

