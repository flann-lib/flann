.PHONY: tests test libs doc all clean examples

BUILD_TYPE?='Release'
INSTALL_PREFIX?=/usr/local
BUILD_C_BINDINGS?=true
BUILD_MATLAB_BINDINGS?=true
BUILD_PYTHON_BINDINGS?=true
USE_MPI?=false

PARAMS=-DCMAKE_BUILD_TYPE=${BUILD_TYPE}\
		-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}\
		-DBUILD_C_BINDINGS=${BUILD_C_BINDINGS}\
		-DBUILD_MATLAB_BINDINGS=${BUILD_MATLAB_BINDINGS}\
		-DBUILD_PYTHON_BINDINGS=${BUILD_PYTHON_BINDINGS}\
		-DUSE_MPI=${USE_MPI}\

all:
	@-mkdir -p build
	cd build && cmake ${PARAMS} .. && make $@

test:
	@-mkdir -p build
	cd build && cmake ${PARAMS} .. && make $@

tests:
	@-mkdir -p build
	cd build && cmake ${PARAMS} .. && make $@

doc:
	@-mkdir -p build
	cd build && cmake ${PARAMS} .. && make $@

examples:
	@-mkdir -p build
	cd build && cmake ${PARAMS} .. && make $@

install:
	@-mkdir -p build
	cd build && cmake ${PARAMS} .. && make $@

clean:
	-cd build && make clean
	-rm -rf build

%:
	@-mkdir -p build
	cd build && cmake ${PARAMS} .. && make $@

