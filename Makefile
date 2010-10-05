.PHONY: flann tests test libs doc all clean examples


all:
	@-mkdir -p build
	cd build && cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} .. && make all doc

libs:
	@-mkdir -p build
	cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} && make flann flann_cpp

test:
	@-mkdir -p build
	cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} && make $@

tests:
	@-mkdir -p build
	cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} && make $@

doc:
	@-mkdir -p build
	cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} && make $@

examples:
	@-mkdir -p build
	cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} && make $@

install:
	@-mkdir -p build
	cd build && cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} .. && make all doc install


clean:
	-cd build && make clean
	-rm -rf build

%:
	@-mkdir -p build
	cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} && make $@

