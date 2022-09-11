#include_directories(${CMAKE_SOURCE_DIR}/include algorithms ext util nn .)

add_definitions(-D_FLANN_VERSION=${FLANN_VERSION})

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/flann/config.h.in ${CMAKE_CURRENT_SOURCE_DIR}/flann/config.h)

file(GLOB_RECURSE C_SOURCES flann.cpp)
file(GLOB_RECURSE CPP_SOURCES flann_cpp.cpp)
file(GLOB_RECURSE CU_SOURCES *.cu)

add_library(flann_cpp_s STATIC ${CPP_SOURCES})
target_link_libraries(flann_cpp_s PUBLIC ${LZ4_LINK_LIBRARIES})
if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_CLANG)
    set_target_properties(flann_cpp_s PROPERTIES COMPILE_FLAGS -fPIC)
endif()
if (CMAKE_BUILD_STATIC_LIBS)
    list(APPEND flann_install_targets flann_cpp_s)
else()
    set_target_properties(flann_cpp_s PROPERTIES EXCLUDE_FROM_ALL true)
endif()

add_library(flann_cpp SHARED ${CPP_SOURCES})
target_link_libraries(flann_cpp ${LZ4_LINK_LIBRARIES})
# export lz4 headers, so that MSVC to creates flann_cpp.lib
set_target_properties(flann_cpp PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS YES)

set(flann_install_targets flann_cpp)

if (BUILD_CUDA_LIB)
    SET(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};-DFLANN_USE_CUDA;-Xcudafe \"--diag_suppress=partial_override\" ;-gencode=arch=compute_52,code=\"sm_52,compute_52\";-gencode=arch=compute_61,code=\"sm_61,compute_61\"")
    if(CMAKE_COMPILER_IS_GNUCC)
		set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};-Xcompiler;-fPIC;" )
        if (NVCC_COMPILER_BINDIR)
            set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};--compiler-bindir=${NVCC_COMPILER_BINDIR}")
        endif()
    else()
	    set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS};" )
    endif()
    cuda_add_library(flann_cuda_s STATIC ${CU_SOURCES})
    set_property(TARGET flann_cuda_s PROPERTY COMPILE_DEFINITIONS FLANN_STATIC)
    if (CMAKE_BUILD_STATIC_LIBS)
        list(APPEND flann_install_targets flann_cuda_s)
    else()
        set_target_properties(flann_cuda_s PROPERTIES EXCLUDE_FROM_ALL true)
    endif()

    cuda_add_library(flann_cuda SHARED ${CU_SOURCES})
    list(APPEND flann_install_targets flann_cuda)
    set_property(TARGET flann_cpp PROPERTY COMPILE_DEFINITIONS FLANN_USE_CUDA)
    set_property(TARGET flann_cpp_s PROPERTY COMPILE_DEFINITIONS FLANN_STATIC FLANN_USE_CUDA)
else()
    set_property(TARGET flann_cpp_s PROPERTY COMPILE_DEFINITIONS FLANN_STATIC)
endif()

set_target_properties(flann_cpp PROPERTIES
   VERSION ${FLANN_VERSION}
   SOVERSION ${FLANN_SOVERSION}
   DEFINE_SYMBOL FLANN_EXPORTS
)

if (BUILD_CUDA_LIB)
    set_target_properties(flann_cuda PROPERTIES
       VERSION ${FLANN_VERSION}
       SOVERSION ${FLANN_SOVERSION}
       DEFINE_SYMBOL FLANN_EXPORTS
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
    add_library(flann_s STATIC ${C_SOURCES})
    target_link_libraries(flann_s ${LZ4_LINK_LIBRARIES})
    if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_CLANG)
        set_target_properties(flann_s PROPERTIES COMPILE_FLAGS -fPIC)
    endif()
    set_property(TARGET flann_s PROPERTY COMPILE_DEFINITIONS FLANN_STATIC)
    if (CMAKE_BUILD_STATIC_LIBS)
        list(APPEND flann_install_targets flann_s)
    else()
        set_target_properties(flann_s PROPERTIES EXCLUDE_FROM_ALL true)
    endif()

    add_library(flann SHARED ${C_SOURCES})
    target_link_libraries(flann ${LZ4_LINK_LIBRARIES})
    list(APPEND flann_install_targets flann)

    if(MINGW AND OPENMP_FOUND)
        target_link_libraries(flann gomp)
    endif()

    set_target_properties(flann PROPERTIES
       VERSION ${FLANN_VERSION}
       SOVERSION ${FLANN_SOVERSION}
       DEFINE_SYMBOL FLANN_EXPORTS
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


install (
    TARGETS ${flann_install_targets}
    EXPORT ${targets_export_name}
    INCLUDES DESTINATION include
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION ${FLANN_LIB_INSTALL_DIR}
    ARCHIVE DESTINATION ${FLANN_LIB_INSTALL_DIR}
)


install (
    DIRECTORY flann
    DESTINATION include
    FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
)
