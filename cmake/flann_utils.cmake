macro(GET_OS_INFO)
    string(REGEX MATCH "Linux" OS_IS_LINUX ${CMAKE_SYSTEM_NAME})
    set(FLANN_LIB_INSTALL_DIR "lib${LIB_SUFFIX}")
    set(FLANN_INCLUDE_INSTALL_DIR
        "include/${PROJECT_NAME_LOWER}-${FLANN_MAJOR_VERSION}.${FLANN_MINOR_VERSION}")
endmacro(GET_OS_INFO)


macro(DISSECT_VERSION)
    # Find version components
    string(REGEX REPLACE "^([0-9]+).*" "\\1"
        FLANN_VERSION_MAJOR "${FLANN_VERSION}")
    string(REGEX REPLACE "^[0-9]+\\.([0-9]+).*" "\\1"
        FLANN_VERSION_MINOR "${FLANN_VERSION}")
    string(REGEX REPLACE "^[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1"
        FLANN_VERSION_PATCH ${FLANN_VERSION})
    string(REGEX REPLACE "^[0-9]+\\.[0-9]+\\.[0-9]+(.*)" "\\1"
        FLANN_VERSION_CANDIDATE ${FLANN_VERSION})
    set(FLANN_SOVERSION "${FLANN_VERSION_MAJOR}.${FLANN_VERSION_MINOR}")
endmacro(DISSECT_VERSION)


# workaround a FindHDF5 bug
macro(find_hdf5)
    find_package(HDF5)

    set( HDF5_IS_PARALLEL FALSE )
    foreach( _dir ${HDF5_INCLUDE_DIRS} )
        if( EXISTS "${_dir}/H5pubconf.h" )
            file( STRINGS "${_dir}/H5pubconf.h" 
                HDF5_HAVE_PARALLEL_DEFINE
                REGEX "HAVE_PARALLEL 1" )
            if( HDF5_HAVE_PARALLEL_DEFINE )
                set( HDF5_IS_PARALLEL TRUE )
            endif()
        endif()
    endforeach()
    set( HDF5_IS_PARALLEL ${HDF5_IS_PARALLEL} CACHE BOOL
        "HDF5 library compiled with parallel IO support" )
    mark_as_advanced( HDF5_IS_PARALLEL )
endmacro(find_hdf5)


# Enable ExternalProject CMake module
include(ExternalProject)

# Add gtest
ExternalProject_Add(
    googletest
    PREFIX ${CMAKE_BINARY_DIR}/googletest
    URL https://github.com/google/googletest/archive/refs/tags/release-1.12.1.zip
    URL_MD5 2648d4138129812611cf6b6b4b497a3b
    TIMEOUT 10
    # Force separate output paths for debug and release builds to allow easy
    # identification of correct lib in subsequent TARGET_LINK_LIBRARIES commands
    CMAKE_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    # Disable install step
    INSTALL_COMMAND ""
    # Disable update step
    UPDATE_COMMAND ""
    # Wrap download, configure and build steps in a script to log output
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON)
set_target_properties(googletest PROPERTIES EXCLUDE_FROM_ALL TRUE)

ExternalProject_Get_Property(googletest source_dir)
set(googletest_INCLUDE_DIRS ${source_dir}/googletest/include)
ExternalProject_Get_Property(googletest binary_dir)
set(googletest_LIBRARIES ${binary_dir}/lib/libgtest.a)
include_directories(${googletest_INCLUDE_DIRS})


macro(flann_add_gtest exe src)
    # add build target
    add_executable(${exe} EXCLUDE_FROM_ALL ${src})
    target_link_libraries(${exe} ${googletest_LIBRARIES} ${ARGN})
    # add dependency to 'tests' target
    add_dependencies(${exe} googletest)
    add_dependencies(flann_gtests ${exe})

    # add target for running test
    string(REPLACE "/" "_" _testname ${exe})
    add_test(
        NAME test_${_testname}
        COMMAND ${exe} --gtest_print_time
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/test
    )
endmacro(flann_add_gtest)

macro(flann_add_cuda_gtest exe src)
    # add build target
    cuda_add_executable(${exe} EXCLUDE_FROM_ALL ${src})
    target_link_libraries(${exe} ${googletest_LIBRARIES} ${ARGN})
    add_dependencies(${exe} googletest)

    # add target for running test
    string(REPLACE "/" "_" _testname ${exe})
    add_test(
        NAME test_${_testname}
        COMMAND ${exe} --gtest_print_time
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/test
    )
endmacro(flann_add_cuda_gtest)

macro(flann_add_pyunit file)
    # find test file
    set(_file_name _file_name-NOTFOUND)
    find_file(_file_name ${file} ${CMAKE_CURRENT_SOURCE_DIR})
    if(NOT _file_name)
        message(FATAL_ERROR "Can't find pyunit file \"${file}\"")
    endif(NOT _file_name)

    # add target for running test
    string(REPLACE "/" "_" _testname ${file})
    add_test(
        NAME pyunit_${_testname}
        COMMAND ${PYTHON_EXECUTABLE} ${PROJECT_SOURCE_DIR}/bin/run_test.py ${_file_name}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/test
    )
    # add dependency to 'test' target
endmacro(flann_add_pyunit)
