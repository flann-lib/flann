# --------------------- Dirs  ----------------------------
export ROOT_DIR = $(shell pwd)
export SRC_DIR = ${ROOT_DIR}/src
export LIBS_DIR = ${ROOT_DIR}/libs
export BUILD_DIR = ${ROOT_DIR}/build
export OBJ_DIR = ${ROOT_DIR}/tmp/build/${PROFILE}/obj
export LIB_OBJ_DIR = ${ROOT_DIR}/tmp/build/${PROFILE}/lib_obj
export BIN_DIR = ${ROOT_DIR}/bin

# ------------------------ Rules --------------------------------
.PHONY: clean all rebuild compile

all: program library c_bindings matlab_bindings python_bindings

clean:
	-(cd src/d; make clean)
	-(cd src/c; make clean)
	-(cd src/matlab; make clean)
	-(cd src/python; make clean)

rebuild: clean all

program:
	(cd src/d; make program)

library:
	(cd src/d; make library)

c_bindings: library
	(cd src/c; make)

matlab_bindings: library
	(cd src/matlab; make)

python_bindings: library
	(cd src/python; make)


