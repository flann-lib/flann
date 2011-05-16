
add_custom_target(tests)
add_custom_target(test)
add_dependencies(test tests)

set(EXECUTABLE_OUTPUT_PATH ${TEST_OUTPUT_PATH})

#add_executable(flann_mt_test flann_mt_test.cpp)
#find_package(Boost COMPONENTS system thread REQUIRED)
#target_link_libraries(flann_mt_test ${Boost_SYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY} flann)

if (PYTHON_EXECUTABLE) 
    flann_download_test_data(sift10K.h5 0964a910946d2dd5fe28337507a8abc3)
    flann_download_test_data(sift10K_byte.h5 f835e0148df4618a81f67febfda2b4d0)
    flann_download_test_data(sift100K.h5 ae2b08f93f3d9f89f5d68566b0406102)
    flann_download_test_data(sift100K_byte.h5 b772255fd2044e9d2a5a0183953e4705)
    flann_download_test_data(cloud.h5 b9f7030c844774baa264c3644129d9c3)
    flann_download_test_data(brief100K.h5 e1e781c0955917bc2f0a27b6344c2342)
endif()

if (GTEST_FOUND AND HDF5_FOUND)
    include_directories(${HDF5_INCLUDE_DIR})
	flann_add_gtest(flann_simple_test flann_simple_test.cpp)
	    target_link_libraries(flann_simple_test flann_cpp ${HDF5_LIBRARIES})
    if (HDF5_IS_PARALLEL)
	    target_link_libraries(flann_simple_test ${MPI_LIBRARIES})
    endif()
endif()

#---------- pyunit tests --------------
if (PYTHON_EXECUTABLE) 
    flann_add_pyunit(test_nn.py)
    flann_add_pyunit(test_nn_index.py)
    flann_add_pyunit(test_index_save.py)
    flann_add_pyunit(test_nn_autotune.py)
    flann_add_pyunit(test_clustering.py)
endif()


