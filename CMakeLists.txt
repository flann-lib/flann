cmake_minimum_required(VERSION 2.4.6)

if(COMMAND cmake_policy)
    cmake_policy(SET CMP0003 NEW)
endif(COMMAND cmake_policy)


project(flann)

set(CMAKE_INSTALL_PREFIX /ubc/cs/home/m/mariusm/scratch/flann_install)
#set the default path for built executables to the "bin" directory
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
#set the default path for built libraries to the "lib" directory
set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)
# set output path for tests
set(TEST_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/test)


#set the C/C++ include path to the "include" directory
include_directories(${PROJECT_SOURCE_DIR}/src/cpp)

# Set the build type.  Options are:
#  Debug          : w/ debug symbols, w/o optimization
#  Release        : w/o debug symbols, w/ optimization
#  RelWithDebInfo : w/ debug symbols, w/ optimization
#  MinSizeRel     : w/o debug symbols, w/ optimization, stripped binaries
#set(CMAKE_BUILD_TYPE Release)
set(CMAKE_BUILD_TYPE RelWithDebInfo)
#set(CMAKE_BUILD_TYPE Debug)


add_custom_target(tests)
add_custom_target(test)
add_dependencies(test tests)

macro(flann_add_gtest exe)
    # add build target
    add_executable(${exe} EXCLUDE_FROM_ALL ${ARGN})
    target_link_libraries(${exe} flann gtest)
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
add_subdirectory( test )
add_subdirectory( doc )
