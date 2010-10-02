
set(EXECUTABLE_OUTPUT_PATH ${TEST_OUTPUT_PATH})

#add_executable(flann_mt_test flann_mt_test.cpp)
#find_package(Boost COMPONENTS system thread REQUIRED)
#target_link_libraries(flann_mt_test ${Boost_SYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY} flann)

find_library(GTEST gtest)
if (NOT GTEST)
	message("gtest library not found, some tests will not be run")
endif()

if (NOT HDF5)
	message("hdf5 library not found, some tests will not be run")
endif()

flann_download_test_data(sift10K.h5 0964a910946d2dd5fe28337507a8abc3)
flann_download_test_data(sift10K_byte.h5 f835e0148df4618a81f67febfda2b4d0)
flann_download_test_data(sift100K.h5 ae2b08f93f3d9f89f5d68566b0406102)
flann_download_test_data(sift100K_byte.h5 b772255fd2044e9d2a5a0183953e4705)

if (GTEST AND HDF5)
	flann_add_gtest(flann_simple_test flann_simple_test.cpp)
	target_link_libraries(flann_simple_test flann_cpp hdf5)
endif()


#---------- pyunit tests --------------
flann_add_pyunit(test_nn.py)
flann_add_pyunit(test_nn_index.py)
#flann_add_pyunit(test_clustering.py)
