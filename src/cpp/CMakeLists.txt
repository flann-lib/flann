# TODO: can we remove this include?
#include_directories(${CMAKE_SOURCE_DIR}/include algorithms ext util nn .)

add_definitions(-D_FLANN_VERSION=${FLANN_VERSION})

# find source files
file(GLOB_RECURSE C_SOURCES flann.cpp lz4.c lz4hc.c)
file(GLOB_RECURSE CPP_SOURCES flann_cpp.cpp lz4.c lz4hc.c)
file(GLOB_RECURSE CU_SOURCES *.cu)

# includes for flann/config.h, flann/flann_export.h an flann/ext/lz4_export.h
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

# uncomment to export only defined symbols
# - relevant when using gcc
# - for MSVC 'hidden' is already the default)
# - would break binary compatibility for anyone using non-exported symbols (on gcc)
#cmake_policy(SET CMP0063 NEW) # Honor visibility properties for all target types.
#set(CMAKE_C_VISIBILITY_PRESET   hidden)
#set(CMAKE_CXX_VISIBILITY_PRESET hidden)
#set(CMAKE_VISIBILITY_INLINES_HIDDEN YES)

# static cpp libraries
add_library(flann_cpp_s STATIC ${CPP_SOURCES})
if((CMAKE_COMPILER_IS_GNUCC AND NOT MINGW) OR CMAKE_COMPILER_IS_CLANG)
    set_target_properties(flann_cpp_s PROPERTIES COMPILE_FLAGS -fPIC)
endif()
# TODO: why is FLANN_USE_CUDA always set?
set_property(TARGET flann_cpp_s PROPERTY COMPILE_DEFINITIONS FLANN_STATIC FLANN_USE_CUDA)
# define static flags for clients to automatically use them
target_compile_definitions(flann_cpp_s PUBLIC FLANN_STATIC_DEFINE LZ4_STATIC_DEFINE)

if (BUILD_CUDA_LIB)
    SET(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};-DFLANN_USE_CUDA")
    if(CMAKE_COMPILER_IS_GNUCC)
        set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};-Xcompiler;-fPIC;" )
        if (NVCC_COMPILER_BINDIR)
            set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};--compiler-bindir=${NVCC_COMPILER_BINDIR}")
        endif()
    else()
        set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};" )
    endif()
    # TODO: why does flann_cuda_s use CU_SOURCES and flann_cuda uses just CPP_SOURCES?
    cuda_add_library(flann_cuda_s STATIC ${CU_SOURCES})
    # define static flags for clients to automatically use them
    target_compile_definitions(flann_cuda_s PUBLIC FLANN_STATIC_DEFINE LZ4_STATIC_DEFINE)
    # when client links to target flann_cuda the flag FLANN_USE_CUDA gets automatically set
    target_compile_definitions(flann_cuda_s PUBLIC FLANN_USE_CUDA)
endif()

# dynamic cpp libraries
add_library(flann_cpp SHARED ${CPP_SOURCES})
if (BUILD_CUDA_LIB)
    # TODO: why does flann_cuda_s use CU_SOURCES and flann_cuda uses just CPP_SOURCES?
    cuda_add_library(flann_cuda SHARED ${CPP_SOURCES})
    #set_property(TARGET flann_cpp PROPERTY COMPILE_DEFINITIONS FLANN_USE_CUDA)
    # TODO: does flann_cpp library also need to compile with cuda?
    target_compile_definitions(flann_cpp PUBLIC FLANN_USE_CUDA)
    # when client links to target flann_cuda the flag FLANN_USE_CUDA gets automatically set
    target_compile_definitions(flann_cuda PUBLIC FLANN_USE_CUDA)
endif()

set_target_properties(flann_cpp PROPERTIES
   VERSION ${FLANN_VERSION}
   SOVERSION ${FLANN_SOVERSION}
   DEFINE_SYMBOL FLANN_EXPORTS # export symbols during build of dynamic library
)

if (BUILD_CUDA_LIB)
    set_target_properties(flann_cuda PROPERTIES
       VERSION ${FLANN_VERSION}
       SOVERSION ${FLANN_SOVERSION}
       DEFINE_SYMBOL FLANN_EXPORTS # export symbols during build of dynamic library
    )
endif()


if (USE_MPI AND HDF5_IS_PARALLEL)
    add_executable(flann_mpi_server flann/mpi/flann_mpi_server.cpp)
    target_link_libraries(flann_mpi_server flann_cpp ${HDF5_LIBRARIES} ${MPI_LIBRARIES} ${Boost_LIBRARIES})

    add_executable(flann_mpi_client flann/mpi/flann_mpi_client.cpp)
    target_link_libraries(flann_mpi_client flann_cpp ${HDF5_LIBRARIES} ${MPI_LIBRARIES} ${Boost_LIBRARIES})

    install (TARGETS flann_mpi_client flann_mpi_server
        DESTINATION bin)
endif()


if (BUILD_C_BINDINGS)
    # static C bindings
    add_library(flann_s STATIC ${C_SOURCES})
    if((CMAKE_COMPILER_IS_GNUCC AND NOT MINGW) OR CMAKE_COMPILER_IS_CLANG)
        set_target_properties(flann_s PROPERTIES COMPILE_FLAGS -fPIC)
    endif()
    # define static flags for clients to automatically use them
    target_compile_definitions(flann_s PUBLIC FLANN_STATIC_DEFINE LZ4_STATIC_DEFINE)

    # dynamic C bindings
    add_library(flann SHARED ${C_SOURCES})
    if(MINGW)
        # optimize debug build on MINGW
        # otherwise there is a bug:
        #   Assembler messages:
        #   Fatal error: can't write 610 bytes to section .text of CMakeFiles/flann_s.dir/flann/flann.cpp.obj because: 'File too big'
        target_compile_options(flann_s PRIVATE $<$<CONFIG:Debug>:-O1>)
        target_compile_options(flann   PRIVATE $<$<CONFIG:Debug>:-O1>)

        if(OPENMP_FOUND)
            target_link_libraries(flann gomp)
        endif()
    endif()

    set_target_properties(flann PROPERTIES
       VERSION ${FLANN_VERSION}
       SOVERSION ${FLANN_SOVERSION}
       DEFINE_SYMBOL FLANN_EXPORTS # export symbols during build of dynamic library
    )
endif()

if(WIN32)
if (BUILD_C_BINDINGS AND BUILD_MATLAB_BINDINGS)
    install (
        TARGETS flann
        RUNTIME DESTINATION share/flann/matlab
    )
endif()
endif(WIN32)

# generate export header to export flann and lz4 symbols
include(GenerateExportHeader)
generate_export_header(flann_cpp
    BASE_NAME FLANN
    EXPORT_FILE_NAME flann/flann_export.h)
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/flann/flann_export.h DESTINATION include/flann
)
generate_export_header(flann_cpp
    BASE_NAME lz4
    DEPRECATED_MACRO_NAME LZ4_DEPRECATED_2 # LZ4_DEPRECATED with message is defined by lz4 header files
    EXPORT_FILE_NAME flann/ext/lz4_export.h)
install(FILES
 ${CMAKE_CURRENT_BINARY_DIR}/flann/ext/lz4_export.h DESTINATION include/flann/ext
)
# create config.h file and install it to include/flann
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/flann/config.h.in ${CMAKE_CURRENT_BINARY_DIR}/flann/config.h)
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/flann/config.h DESTINATION include/flann
)


# install targets
install (
    TARGETS flann_cpp flann_cpp_s
    EXPORT ${targets_export_name}
    INCLUDES DESTINATION include
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION ${FLANN_LIB_INSTALL_DIR}
    ARCHIVE DESTINATION ${FLANN_LIB_INSTALL_DIR}
)

if (BUILD_CUDA_LIB)
    install (
        TARGETS flann_cuda flann_cuda_s
        EXPORT ${targets_export_name}
        INCLUDES DESTINATION include
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION ${FLANN_LIB_INSTALL_DIR}
        ARCHIVE DESTINATION ${FLANN_LIB_INSTALL_DIR}
    )
endif()

if (BUILD_C_BINDINGS)
    install (
        TARGETS flann flann_s
        EXPORT ${targets_export_name}
        INCLUDES DESTINATION include
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION ${FLANN_LIB_INSTALL_DIR}
        ARCHIVE DESTINATION ${FLANN_LIB_INSTALL_DIR}
    )
endif()

# install header files
install (
    DIRECTORY flann
    DESTINATION include
    FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
)
