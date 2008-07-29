
.PHONY: pyflann

pyflann:
	-mkdir ${BUILD_DIR}/python
	cp -r pyflann_dist/* ${BUILD_DIR}/python
	(cd ${BUILD_DIR}/python; python create_python_base.py)

clean:
	-rm -rf ${BUILD_DIR}/python
	