
add_custom_target(tests)
add_custom_target(flann_gtests)

add_dependencies(tests flann_gtests)

set(EXECUTABLE_OUTPUT_PATH ${TEST_OUTPUT_PATH})

if (HDF5_FOUND)
    include_directories(${HDF5_INCLUDE_DIR})

    set(TEST_LIBRARIES "${HDF5_LIBRARIES}")
    if (HDF5_IS_PARALLEL)
        set(TEST_LIBRARIES "${TEST_LIBRARIES};${MPI_LIBRARIES}")
    endif()

    flann_add_gtest(flann_linear_test flann_linear_test.cpp flann_cpp ${TEST_LIBRARIES})
    flann_add_gtest(flann_kdtree_test flann_kdtree_test.cpp flann_cpp ${TEST_LIBRARIES})
    flann_add_gtest(flann_kmeans_test flann_kmeans_test.cpp flann_cpp ${TEST_LIBRARIES})
    flann_add_gtest(flann_kdtree_single_test flann_kdtree_single_test.cpp flann_cpp ${TEST_LIBRARIES})
    flann_add_gtest(flann_hierarchical_test flann_hierarchical_test.cpp flann_cpp ${TEST_LIBRARIES})
    flann_add_gtest(flann_lsh_test flann_lsh_test.cpp flann_cpp ${TEST_LIBRARIES})
    flann_add_gtest(flann_autotuned_test flann_autotuned_test.cpp flann_cpp ${TEST_LIBRARIES})
    if (OPENMP_FOUND)
        flann_add_gtest(flann_multithreaded_test flann_multithreaded_test.cpp flann_cpp ${TEST_LIBRARIES})
    endif()

endif()

if (HDF5_FOUND AND BUILD_CUDA_LIB)
    set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};-Xcompiler;-fPIC;-Xcudafe \"--diag_suppress=partial_override\" ;-gencode=arch=compute_52,code=\"sm_52,compute_52\";-gencode=arch=compute_61,code=\"sm_61,compute_61\"" )
    if (NVCC_COMPILER_BINDIR)
        set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};--compiler-bindir=${NVCC_COMPILER_BINDIR}")
    endif()
    flann_add_cuda_gtest(flann_cuda_test flann_cuda_test.cu flann_cpp ${HDF5_LIBRARIES} flann_cuda)
endif()


#---------- pyunit tests --------------
if (BUILD_PYTHON_BINDINGS) 
    flann_add_pyunit(test_nn.py)
    flann_add_pyunit(test_nn_index.py)
    flann_add_pyunit(test_index_save.py)
    flann_add_pyunit(test_nn_autotune.py)
    flann_add_pyunit(test_clustering.py)
endif()

#---------- ruby spec ----------------
#if (BUILD_C_BINDINGS)
#    add_custom_target(flann_ruby_spec
#                    COMMAND bundle exec rake spec
#                    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/src/ruby)
#    add_dependencies(test flann_ruby_spec)
#endif()
