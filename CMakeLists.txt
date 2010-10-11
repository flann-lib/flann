cmake_minimum_required(VERSION 2.4)

if(COMMAND cmake_policy)
    cmake_policy(SET CMP0003 NEW)
endif(COMMAND cmake_policy)


project(flann)

set(FLANN_VERSION 1.5.0)
STRING(REGEX MATCHALL "[0-9]" FLANN_VERSION_PARTS "${FLANN_VERSION}")                                                
LIST(GET FLANN_VERSION_PARTS 0 FLANN_VERSION_MAJOR)                                                                  
LIST(GET FLANN_VERSION_PARTS 1 FLANN_VERSION_MINOR)                                                                  
LIST(GET FLANN_VERSION_PARTS 2 FLANN_VERSION_PATCH)                                                                  

if (NOT CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX /usr/local)
endif()

# Set the build type.  Options are:
#  Debug          : w/ debug symbols, w/o optimization
#  Release        : w/o debug symbols, w/ optimization
#  RelWithDebInfo : w/ debug symbols, w/ optimization
#  MinSizeRel     : w/o debug symbols, w/ optimization, stripped binaries

if (NOT CMAKE_BUILD_TYPE)
    #set(CMAKE_BUILD_TYPE Release)
    set(CMAKE_BUILD_TYPE RelWithDebInfo)
    #set(CMAKE_BUILD_TYPE Debug)
endif()

message("Install prefix: ${CMAKE_INSTALL_PREFIX}")
message("Build type: ${CMAKE_BUILD_TYPE}")


#set the default path for built executables to the "bin" directory
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
#set the default path for built libraries to the "lib" directory
set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)
# set output path for tests
set(TEST_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/test)


message("USE_MPI: ${USE_MPI}")


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

find_hdf5()
if (USE_MPI OR HDF5_IS_PARALLEL)
    find_package(MPI)
endif()

if (HDF5_IS_PARALLEL)
    if (NOT MPI_FOUND)
        message(ERROR "Found the parallel HDF5 library, but could not find the MPI library. Define the MPI_COMPILER variable to the path of your MPI compiler.")
    endif()
    # Parallel HDF5 needs to find the "mpi.h" header file
    include_directories(${MPI_INCLUDE_PATH})
endif()


if (USE_MPI)
    if (NOT MPI_FOUND)
        message(ERROR "Could not find an MPI library. Define the MPI_COMPILER variable to the path of your MPI compiler.")
    endif()

    if (NOT HDF5_IS_PARALLEL)
        message(ERROR "For MPI support the Parallel HDF5 library is required.")
    endif()

endif(USE_MPI)



#set the C/C++ include path to the "include" directory
include_directories(${PROJECT_SOURCE_DIR}/src/cpp)


add_custom_target(tests)
add_custom_target(test)
add_dependencies(test tests)






macro(flann_add_gtest exe)
    # add build target
    add_executable(${exe} EXCLUDE_FROM_ALL ${ARGN})
    target_link_libraries(${exe} gtest)
    # add dependency to 'tests' target
    add_dependencies(tests ${exe})

    # add target for running test
    string(REPLACE "/" "_" _testname ${exe})
    add_custom_target(test_${_testname}
                    COMMAND ${exe}
                    ARGS --gtest_print_time
                    DEPENDS ${exe}
                    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/test
                    VERBATIM
                    COMMENT "Runnint gtest test(s) ${exe}")
    # add dependency to 'test' target
    add_dependencies(test test_${_testname})
endmacro(flann_add_gtest)



macro(flann_add_pyunit file)
    # find test file
    set(_file_name _file_name-NOTFOUND)
    find_file(_file_name ${file} ${CMAKE_CURRENT_SOURCE_DIR})
    if(NOT _file_name)
        message(FATAL_ERROR "Can't find pyunit file \"${file}\"")
    endif(NOT _file_name)

    # find python
    find_package(PythonInterp REQUIRED)
    
    # add target for running test
    string(REPLACE "/" "_" _testname ${file})
    add_custom_target(pyunit_${_testname}
                    COMMAND ${PYTHON_EXECUTABLE} ${PROJECT_SOURCE_DIR}/bin/run_test.py ${_file_name}
                    DEPENDS ${_file_name}
                    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/test
                    VERBATIM
                    COMMENT "Running pyunit test(s) ${file}" )
    # add dependency to 'test' target
    add_dependencies(pyunit_${_testname} flann)
    add_dependencies(test pyunit_${_testname})
endmacro(flann_add_pyunit)


macro(flann_download_test_data _name _md5)
    string(REPLACE "/" "_" _dataset_name dataset_${_name})
    
    # find python
    find_package(PythonInterp REQUIRED)
    
    add_custom_target(${_dataset_name}
        COMMAND ${PROJECT_SOURCE_DIR}/bin/download_checkmd5.py http://people.cs.ubc.ca/~mariusm/uploads/FLANN/datasets/${_name} ${TEST_OUTPUT_PATH}/${_name} ${_md5}
        VERBATIM)

    # Also make sure that downloads are done before we run any tests
    add_dependencies(tests ${_dataset_name})

endmacro(flann_download_test_data)

# require proper c++
add_definitions( "-Wall -ansi -pedantic" )


add_subdirectory( src )
add_subdirectory( examples )
add_subdirectory( test )
add_subdirectory( doc )
