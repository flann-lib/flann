.PHONY: flann tests test doc all clean


flann:
	@-mkdir -p build
	@cd build && cmake .. && make all

tests:
	@-mkdir -p build
	@cd build && cmake .. && make tests

test:
	@-mkdir -p build
	@cd build && cmake .. && make test

doc:
	@-mkdir -p build
	@cd build && cmake .. && make doc

clean:
	-cd build && make clean
	-rm -rf build


all: flann doc

