
all:
	-mkdir -p build
	cd build; cmake ../src; make


clean:
	-rm -rf build
