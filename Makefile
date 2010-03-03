.PHONY: flann tests test doc all clean

flann:
	@-mkdir -p build
	@cd build && cmake .. && make $@

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
