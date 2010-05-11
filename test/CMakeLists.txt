
set(EXECUTABLE_OUTPUT_PATH ${TEST_OUTPUT_PATH})

#add_executable(flann_mt_test flann_mt_test.cpp)
#find_package(Boost COMPONENTS system thread REQUIRED)
#target_link_libraries(flann_mt_test ${Boost_SYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY} flann)

add_executable(flann_example flann_example.cpp)
target_link_libraries(flann_example flann)

find_library(GTEST gtest)
if (NOT GTEST)
	message("gtest library not found, some tests will not be run")
endif()

find_library(HDF5 hdf5)
find_library(HDF5_CPP hdf5_cpp)
if (NOT HDF5 OR NOT HDF5_CPP)
	message("hdf5 library not found, some tests will not be run")
endif()

flann_download_test_data(sift100K.h5 ae2b08f93f3d9f89f5d68566b0406102)
flann_download_test_data(sift100K_byte.h5 b772255fd2044e9d2a5a0183953e4705)

if (GTEST AND HDF5 AND HDF5_CPP)
	flann_add_gtest(flann_simple_test flann_simple_test.cpp)
	target_link_libraries(flann_simple_test hdf5 hdf5_cpp)
endif()


#---------- pyunit tests --------------
flann_add_pyunit(test_nn.py)
flann_add_pyunit(test_nn_index.py)
#flann_add_pyunit(test_clustering.py)
