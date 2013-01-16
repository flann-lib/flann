cmake_minimum_required(VERSION 2.6)

if(COMMAND cmake_policy)
    cmake_policy(SET CMP0003 NEW)
endif(COMMAND cmake_policy)

project(flann)
string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LOWER)

include(${PROJECT_SOURCE_DIR}/cmake/flann_utils.cmake)
set(FLANN_VERSION 1.8.4)
DISSECT_VERSION()
GET_OS_INFO()

# CMAKE_C_COMPILER_ID and CMAKE_CXX_COMPILER_ID are documented as internal variables subject to
# change at: http://www.cmake.org/cmake/help/v2.8.8/cmake.html#variable:CMAKE_LANG_COMPILER_ID
# however currently this seems the most robust way to detect the presence of the Clang compiler
if("${CMAKE_C_COMPILER_ID}" MATCHES "Clang")
  set(CMAKE_COMPILER_IS_CLANG 1)
endif ()

if("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
  set(CMAKE_COMPILER_IS_CLANGXX 1)
endif ()

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

# Add an "uninstall" target
CONFIGURE_FILE ("${PROJECT_SOURCE_DIR}/cmake/uninstall_target.cmake.in"
    "${PROJECT_BINARY_DIR}/uninstall_target.cmake" IMMEDIATE @ONLY)
ADD_CUSTOM_TARGET (uninstall "${CMAKE_COMMAND}" -P
    "${PROJECT_BINARY_DIR}/uninstall_target.cmake")

# Set the build type.  Options are:
#  Debug          : w/ debug symbols, w/o optimization
#  Release        : w/o debug symbols, w/ optimization
#  RelWithDebInfo : w/ debug symbols, w/ optimization
#  MinSizeRel     : w/o debug symbols, w/ optimization, stripped binaries

if (NOT CMAKE_BUILD_TYPE)
    #set(CMAKE_BUILD_TYPE Release)
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
    #set(CMAKE_BUILD_TYPE Debug)
endif()

#set the default path for built executables to the "bin" directory
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
#set the default path for built libraries to the "lib" directory
set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)
# set output path for tests
set(TEST_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/test)

option(BUILD_C_BINDINGS "Build C bindings" ON)
option(BUILD_PYTHON_BINDINGS "Build Python bindings" ON)
option(BUILD_MATLAB_BINDINGS "Build Matlab bindings" ON)
option(BUILD_CUDA_LIB "Build CUDA library" OFF)
option(USE_OPENMP "Use OpenMP multi-threading" ON)
option(USE_MPI "Use MPI" OFF)

set(NVCC_COMPILER_BINDIR "" CACHE PATH  "Directory where nvcc should look for C++ compiler. This is passed to nvcc through the --compiler-bindir option.")

if (NOT BUILD_C_BINDINGS)
    set(BUILD_PYTHON_BINDINGS OFF)
    set(BUILD_MATLAB_BINDINGS OFF)
endif()


# find python
find_package(PythonInterp)
if (NOT PYTHON_EXECUTABLE)
    set(BUILD_PYTHON_BINDINGS OFF)
endif()

find_hdf5()
if (NOT HDF5_FOUND)
	message(WARNING "hdf5 library not found, some tests will not be run")
else()
    include_directories(${HDF5_INCLUDE_DIR})
endif()

if (USE_MPI OR HDF5_IS_PARALLEL)
    find_package(MPI)
endif()
if (HDF5_IS_PARALLEL)
    if (NOT MPI_FOUND)
        message(WARNING "Found the parallel HDF5 library, but could not find the MPI library. Define the MPI_COMPILER variable to the path of your MPI compiler.")
    endif()
    # Parallel HDF5 needs to find the "mpi.h" header file
    include_directories(${MPI_INCLUDE_PATH})
endif()


if (USE_MPI)
    if (NOT MPI_FOUND)
        message(WARNING "Could not find an MPI library. Define the MPI_COMPILER variable to the path of your MPI compiler.")
        set(USE_MPI OFF)
    endif()

    if (NOT HDF5_IS_PARALLEL)
        message(WARNING "For MPI support the Parallel HDF5 library is required.")
        set(USE_MPI OFF)
    endif()
endif(USE_MPI)


if (USE_MPI AND HDF5_IS_PARALLEL)
    find_package(Boost COMPONENTS mpi system serialization thread REQUIRED)
    include_directories(${Boost_INCLUDE_DIRS})
    add_definitions("-DHAVE_MPI")
endif()


find_package(GTest) 
if (NOT GTEST_FOUND)
	message(WARNING "gtest library not found, some tests will not be run")
endif()


if (USE_OPENMP)
    find_package(OpenMP)
    if(OPENMP_FOUND)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
    else()
        message(WARNING "OpenMP NOT found")
    endif()
endif()


# CUDA support
if (BUILD_CUDA_LIB)
    find_package(CUDA)
    if (CUDA_FOUND)
        message(STATUS "CUDA found (include: ${CUDA_INCLUDE_DIRS}, lib: ${CUDA_LIBRARIES})")
        include_directories(${CUDA_INCLUDE_DIRS})
    else(CUDA_FOUND)
        message(STATUS "CUDA not found, CUDA library will not be built")
        set(BUILD_CUDA_LIB OFF)
    endif(CUDA_FOUND)
endif(BUILD_CUDA_LIB)

#set the C/C++ include path to the "include" directory
include_directories(${PROJECT_SOURCE_DIR}/src/cpp)

# require proper c++
#add_definitions( "-Wall -ansi -pedantic" )
# HDF5 uses long long which is not ansi
if (WIN32)
    # lots of warnings with cl.exe right now, use /W1
    add_definitions("/W1 -D_CRT_SECURE_NO_WARNINGS -D_SCL_SECURE_NO_WARNINGS /bigobj")
else(WIN32)
    add_definitions( "-Wall -Wno-unknown-pragmas -Wno-unused-function" )
endif(WIN32)

add_subdirectory( cmake )
add_subdirectory( src )
add_subdirectory( examples )
add_subdirectory( test )
add_subdirectory( doc )


# CPACK options

# RPM
find_program(RPM_PROGRAM rpm)
if(EXISTS ${RPM_PROGRAM})
  list(APPEND CPACK_GENERATOR "RPM")
endif(EXISTS ${RPM_PROGRAM})
# DEB
find_program(DPKG_PROGRAM dpkg)
if(EXISTS ${DPKG_PROGRAM})
  list(APPEND CPACK_GENERATOR "DEB")
endif(EXISTS ${DPKG_PROGRAM})
# NSIS
find_program(NSIS_PROGRAM makensis MakeNSIS)
if(EXISTS ${NSIS_PROGRAM})
  list(APPEND CPACK_GENERATOR "NSIS")
endif(EXISTS ${NSIS_PROGRAM})
# dpkg
find_program(PACKAGE_MAKER_PROGRAM PackageMaker
	    HINTS /Developer/Applications/Utilities)
if(EXISTS ${PACKAGE_MAKER_PROGRAM})
  list(APPEND CPACK_GENERATOR "PackageMaker")
endif(EXISTS ${PACKAGE_MAKER_PROGRAM})
 
set(CPACK_GENERATOR "${CPACK_GENERATOR}")
set(CPACK_MONOLITHIC_INSTALL 1)
set(CPACK_SET_DESTDIR ON)
include(InstallRequiredSystemLibraries)
set(CPACK_PACKAGE_CONTACT "Marius Muja")
set(CPACK_PACKAGING_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
SET(CPACK_PACKAGE_VERSION ${FLANN_VERSION})
SET(CPACK_PACKAGE_VERSION_MAJOR ${FLANN_VERSION_MAJOR})
SET(CPACK_PACKAGE_VERSION_MINOR ${FLANN_VERSION_MINOR})
SET(CPACK_PACKAGE_VERSION_PATCH ${FLANN_VERSION_PATCH})
include(CPack)


message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Building C bindings: ${BUILD_C_BINDINGS}")
message(STATUS "Building python bindings: ${BUILD_PYTHON_BINDINGS}")
message(STATUS "Building matlab bindings: ${BUILD_MATLAB_BINDINGS}")
message(STATUS "Building CUDA library: ${BUILD_CUDA_LIB}")
message(STATUS "Using OpenMP support: ${USE_OPENMP}")
message(STATUS "Using MPI support: ${USE_MPI}")
