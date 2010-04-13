find_package(Boost COMPONENTS system thread REQUIRED)

set(EXECUTABLE_OUTPUT_PATH ${TEST_OUTPUT_PATH})

add_executable(flann_mt_test flann_mt_test.cpp)
target_link_libraries(flann_mt_test ${Boost_SYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY} flann)

add_executable(flann_test flann_test.cpp)
target_link_libraries(flann_test flann)

find_library(HDF5 hdf5_cpp)
if (${HDF5} STREQUAL "HDF5-NOTFOUND")
	message("hdf5 library not found, some tests will not be run")
endif()


flann_download_test_data(sift100K.h5 ae2b08f93f3d9f89f5d68566b0406102)
flann_download_test_data(sift100K_byte.h5 b772255fd2044e9d2a5a0183953e4705)

if (NOT ${HDF5} STREQUAL "HDF5-NOTFOUND")
	flann_add_gtest(flann_simple_test flann_simple_test.cpp)
	target_link_libraries(flann_simple_test hdf5_cpp)
endif()


#---------- pyunit tests --------------
flann_add_pyunit(test_nn.py)
flann_add_pyunit(test_nn_index.py)
#flann_add_pyunit(test_clustering.py)
