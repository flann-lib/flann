#include_directories(${CMAKE_SOURCE_DIR}/include algorithms util nn .)

file(GLOB_RECURSE C_SOURCES *.cpp)
file(GLOB_RECURSE CPP_SOURCES *.cpp)

file(GLOB_RECURSE C_FLANN flann.cpp)
file(GLOB_RECURSE CPP_FLANN flann_cpp.cpp)

list(REMOVE_ITEM CPP_SOURCES ${C_FLANN})
list(REMOVE_ITEM C_SOURCES ${CPP_FLANN})

add_library(flann_cpp_s STATIC ${CPP_SOURCES})
set_target_properties(flann_cpp_s PROPERTIES COMPILE_FLAGS -fPIC)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_COMPILER_IS_GNUCC)
    add_library(flann_cpp SHARED "")
    target_link_libraries(flann_cpp -Wl,-whole-archive flann_cpp_s -Wl,-no-whole-archive)
else()
    add_library(flann_cpp SHARED ${CPP_SOURCES})
endif()

set_target_properties(flann_cpp PROPERTIES
   VERSION ${FLANN_VERSION}
   SOVERSION ${FLANN_SOVERSION}
) 

if (BUILD_C_BINDINGS)
    add_library(flann_s STATIC ${C_SOURCES})
    set_target_properties(flann_s PROPERTIES COMPILE_FLAGS -fPIC)

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_COMPILER_IS_GNUCC)
        add_library(flann SHARED "")
        target_link_libraries(flann -Wl,-whole-archive flann_s -Wl,-no-whole-archive)
    else()
        add_library(flann SHARED ${C_SOURCES})
    endif()

    set_target_properties(flann PROPERTIES
       VERSION ${FLANN_VERSION}
       SOVERSION ${FLANN_SOVERSION}
    ) 
endif()


if(WIN32)
if (BUILD_C_BINDINGS)
    install (
        TARGETS flann
        RUNTIME DESTINATION share/flann/matlab
    )
endif()
endif(WIN32)


install (
    TARGETS flann_cpp flann_cpp_s
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION ${FLANN_LIB_INSTALL_DIR}
    ARCHIVE DESTINATION ${FLANN_LIB_INSTALL_DIR}
)

if (BUILD_C_BINDINGS)
    install (
        TARGETS flann flann_s
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION ${FLANN_LIB_INSTALL_DIR}
        ARCHIVE DESTINATION ${FLANN_LIB_INSTALL_DIR}
    )
endif()

install (
    DIRECTORY flann
    DESTINATION include
    FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
)
