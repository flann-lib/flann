


flann:
	-mkdir -p build
	cd build; cmake ../src; make

flann_clean:
	-rm -rf build


doc:
	cd doc; make

doc_clean:
	cd doc; make clean


all: flann doc

clean: flann_clean doc_clean
