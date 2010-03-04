find_package(Boost COMPONENTS system thread REQUIRED)

set(EXECUTABLE_OUTPUT_PATH ${TEST_OUTPUT_PATH})

add_executable(flann_mt_test flann_mt_test.cpp)
target_link_libraries(flann_mt_test ${Boost_SYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY} flann)

add_executable(flann_test flann_test.cpp)
target_link_libraries(flann_test flann)


flann_download_test_data(sift100K.h5 ae2b08f93f3d9f89f5d68566b0406102)

flann_add_gtest(flann_simple_test flann_simple_test.cpp)
target_link_libraries(flann_simple_test hdf5_cpp)

flann_add_pyunit(test_nn.py)

flann_add_pyunit(test_nn_index.py)

#flann_add_pyunit(test_clustering.py)
