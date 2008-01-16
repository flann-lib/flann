# ------------------ Compilation options ------------------------

HAS_SQLITE = 1


include Makefile.platform

ifdef UNIT_TEST
	DFLAGS := ${DFLAGS} -unittest -debug 
endif

DFLAGS := ${DFLAGS}

ifeq ($(PROFILER),gprof)
	DFLAGS := ${DFLAGS} -q,-pg -K-q,-pg
endif

ifndef PROFILE
	PROFILE := release
endif
	
ifeq ($(PROFILE),debug)
#	DFLAGS := ${DFLAGS} -g -release -C-q,-msse2
	#DFLAGS := ${DFLAGS} -g -debug -C-q,-msse2
	DFLAGS := ${DFLAGS} -g -debug
else ifeq (${PROFILE},release)
#	DFLAGS := ${DFLAGS} -O -inline -release -C-q,-fno-bounds-check -C-q,-funroll-loops
	DFLAGS := ${DFLAGS} -O -inline -release -C-q,-pipe
endif


WARNS = -W -Wall
INCLUDES = -Iinclude
LIBS = 
LLIBS = -llc -llgphobos -llm -llpthread -llgcc_s

LIB_DFLAGS := -C-q,-fPIC -shlib ${DFLAGS} 

ifeq ($(HAS_SQLITE),1)
	DFLAGS := ${DFLAGS} -version=hasSqlite
	LIBS := -llsqlite3 -lldl
endif

TARGET = nn
LIB_TARGET = libnn.a
# --------------------- Dirs  ----------------------------
SRC_DIR = src
LIBS_DIR = libs
BUILD_DIR = $(HOME)/tmp/${TARGET}_build/${PROFILE}
OBJ_DIR = ${BUILD_DIR}/obj
LIB_OBJ_DIR = ${BUILD_DIR}/lib_obj
BIN_DIR = bin
DIST_DIR = .

MAIN_FILE=${SRC_DIR}/main.d
LIB_FILE=${SRC_DIR}/bindings/exports.d

# ------------------------ Rules --------------------------------

.PHONY: clean all rebuild compile

all: program library dist

clean:
	rm -rf ${BUILD_DIR}/*
	
dist:
	cp ${BUILD_DIR}/${TARGET} ${DIST_DIR}
	cp ${BUILD_DIR}/${LIB_TARGET} ${DIST_DIR}

rebuild: clean all

program:
	${BIN_DIR}/build -oq${OBJ_DIR} ${MAIN_FILE} -I${SRC_DIR} -I${LIBS_DIR} -of${BUILD_DIR}/${TARGET} ${DFLAGS} ${LIBS}

library:
	 ${BIN_DIR}/build -oq${LIB_OBJ_DIR} ${LIB_FILE} -I${SRC_DIR} -I${LIBS_DIR} -of${BUILD_DIR}/${LIB_TARGET} ${LIB_DFLAGS} ${LLIBS}

