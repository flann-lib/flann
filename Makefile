.PHONY: flann tests test doc all clean

default:
	@-mkdir -p build
	@cd build && cmake .. && make flann flann_cpp

test:
	@-mkdir -p build
	@cd build && cmake .. && make $@

tests:
	@-mkdir -p build
	@cd build && cmake .. && make $@

doc:
	@-mkdir -p build
	@cd build && cmake .. && make $@

all:
	@-mkdir -p build
	@cd build && cmake .. && make all doc

clean:
	-cd build && make clean
	-rm -rf build

%:
	@-mkdir -p build
	@cd build && cmake .. && make $@
