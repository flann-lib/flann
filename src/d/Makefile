# ------------------ Compilation options ------------------------

ifdef UNIT_TEST
	DFLAGS := ${DFLAGS} -unittest -debug 
endif

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
	DFLAGS := ${DFLAGS} -O -inline -release -C-q,-pipe 
endif


ARCH=$(shell uname -m)
ifeq (${ARCH},i686)
	DFLAGS := ${DFLAGS} -C-q,-march=i686
endif
ifeq (${ARCH},x86_64)
endif



WARNS = -W -Wall
INCLUDES = -Iinclude
LIBS =
LLIBS = ${LIBS} -llc -llgphobos -llm -llpthread -llgcc_s

LIB_DFLAGS := -lib ${DFLAGS} 


MAIN_FILE=${SRC_DIR}/d/main.d
LIB_FILE=${SRC_DIR}/d/exports.d

TARGET = ${BUILD_DIR}/bin/flann
export LIB_TARGET = ${BUILD_DIR}/lib/libflann.a


# ------------------------ Rules --------------------------------

program:
	@mkdir -p ${BUILD_DIR}/bin
	${BIN_DIR}/build -oq${OBJ_DIR} ${MAIN_FILE} -I${SRC_DIR}/d -I${LIBS_DIR} -of${TARGET} ${DFLAGS} ${LIBS}

library:
	@mkdir -p ${BUILD_DIR}/lib
	${BIN_DIR}/build -oq${LIB_OBJ_DIR} ${LIB_FILE} -I${SRC_DIR}/d -I${LIBS_DIR} -C-q,-fPIC -of${LIB_TARGET} ${LIB_DFLAGS} ${LLIBS}
	cp `${BIN_DIR}/gdc -print-file-name=libgphobos.a` ${BUILD_DIR}/lib

clean:
	rm -rf {${BUILD_DIR}/bin,${BUILD_DIR}/lib}
	rm -rf {${BUILD_DIR}/tmp/debug,${BUILD_DIR}/tmp/release}


