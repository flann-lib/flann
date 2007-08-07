
# ------------------ Compilation options ------------------------

ifndef TARGET	
	#TARGET := $(shell basename `pwd`)
	TARGET = aggnn
endif
# ------------------ Compilation options ------------------------

LIB_DIRS =

LIBS = ${LIB_DIRS} 

INCLUDES = -Iinclude

# Flags for the C compiler:
#   -Wall for strict gcc warnings (requires prototypes for all functions).
#   -g to produce debug data for gdb
#   -O for optimization

WARNS = -W -Wall


ifdef UNIT_TEST
	DFLAGS := ${DFLAGS} -funittest -fdebug
endif


ifeq ($(PROFILER),gprof)
	DFLAGS := $(DFLAGS) -pg
	LINKFLAGS := $(LINKFLAGS) -pg
endif
	
ifeq ($(CONFIGURATION),debug)
	DFLAGS := ${DFLAGS} -g -fdebug
	CFLAGS = ${WARNS} -g
else
	DFLAGS := ${DFLAGS} -O3 -finline -frelease
	CFLAGS = ${WARNS} -O3 
endif
CXXFLAGS = ${CFLAGS}
LINKLAGS = 

# Use the gcc compiler.
CC = gcc
#CXX = gfilt
CXX = g++
DC = gdc
LINK = gdc


# --------------------- Dirs  ----------------------------

SRC_DIR = src
BUILD_DIR = $(HOME)/tmp/${TARGET}_build
DEPS_DIR = ${BUILD_DIR}/deps
OBJ_DIR = ${BUILD_DIR}/obj
DOC_DIR = doc
RES_DIR = res
BIN_DIR = bin

# --------------------- Code modules ----------------------------

OBJ := $(shell find $(SRC_DIR) -type f ! -regex '.*[.]svn.*' ! -name '*~' | xargs -izxc grep -l 'Project:[[:space:]]*'${TARGET} zxc | sed -e 's/\(.*\)[.].*/\1.o'/)

OBJS = ${patsubst ${SRC_DIR}/%, ${OBJ_DIR}/%, ${OBJ}}

DEPS = ${patsubst ${SRC_DIR}/%.o, ${DEPS_DIR}/%.dep, ${OBJ}}


# ------------------------ Rules --------------------------------

all: prepare ${BUILD_DIR}/${TARGET}
#all:
#	@echo $(OBJ)


prepare:
	@if [ -f build_file_list ] ; then rm build_file_list; fi

clean:
	rm -rf ${BUILD_DIR}/*

rebuild: clean all

.PHONY: clean all rebuild prepare



#---------------- Handle c/cpp dependencies ----------------------

${DEPS_DIR}/%.dep : ${SRC_DIR}/%.cpp
	@if [ ! -d ${DEPS_DIR} ] ; then mkdir -p ${DEPS_DIR}; fi
	@echo Computing $< dependencies...
	@${CXX} -MM -MF $@ -MT${OBJ_DIR}/${<:${SRC_DIR}/%.cpp=%.o} $<

${DEPS_DIR}/%.dep : ${SRC_DIR}/%.cc
	@if [ ! -d ${DEPS_DIR} ] ; then mkdir -p ${DEPS_DIR}; fi
	@echo Computing $< dependencies...
	@${CXX} -MM -MF $@ -MT${OBJ_DIR}/${<:${SRC_DIR}/%.cc=%.o} $<

${DEPS_DIR}/%.dep : ${SRC_DIR}/%.c
	@if [ ! -d ${DEPS_DIR} ] ; then mkdir -p ${DEPS_DIR}; fi
	@echo Computing $< dependencies...
	@${CC} -MM -MF $@ -MT${OBJ_DIR}/${<:${SRC_DIR}/%.c=%.o} $<

-include ${DEPS}

#------------------ Compile source files --------------------------

#---------- compile cpp files
${OBJ_DIR}/%.o : ${SRC_DIR}/%.cpp ${DEPS_DIR}/%.dep Makefile
	@if [ ! -d ${OBJ_DIR} ] ; then mkdir -p ${OBJ_DIR}; fi
	${CXX} -c ${CXXFLAGS} ${INCLUDES} $< -o $@

${OBJ_DIR}/%.o : ${SRC_DIR}/%.cc ${DEPS_DIR}/%.dep Makefile
	@if [ ! -d ${OBJ_DIR} ] ; then mkdir -p ${OBJ_DIR}; fi
	${CXX} -c ${CXXFLAGS} ${INCLUDES} $< -o $@

#---------- compile c files
${OBJ_DIR}/%.o : ${SRC_DIR}/%.c ${DEPS_DIR}/%.dep Makefile
	@if [ ! -d ${OBJ_DIR} ] ; then mkdir -p ${OBJ_DIR}; fi
	${CC} -c ${CFLAGS} ${INCLUDES} $< -o $@


#---------- compile d files
${OBJ_DIR}/%.o : ${SRC_DIR}/%.d Makefile
	@if [ ! -d `dirname $@` ] ; then mkdir -p `dirname $@`; fi
	@echo $< >> build_file_list
	${DC} -c ${DFLAGS} -I${SRC_DIR} $< -o $@
#---------------------- Link objects -------------------------------


# link single file
% : ${OBJ_DIR}/%.o
	@if [ ! -d ${BUILD_DIR} ] ; then mkdir -p ${BUILD_DIR}; fi
	${LINK} ${LINKFLAGS} $< ${LIBS} -o ${BUILD_DIR}/$@ 
	cp ${BUILD_DIR}/$@ .

#link project
${BUILD_DIR}/${TARGET}: ${OBJS}
	@if [ ! -d ${BUILD_DIR} ] ; then mkdir -p ${BUILD_DIR}; fi
	${LINK} ${LINKFLAGS} ${OBJS} ${LIBS} -o $@ 
	#@if [ -f build_file_list ] ; then rm build_file_list; fi
	cp ${BUILD_DIR}/${TARGET} ${TARGET}
