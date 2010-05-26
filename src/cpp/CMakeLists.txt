if (DEFINED OPENCV_VERSION)

# ----------------------------------------------------------------------------
#  CMake file for libflann. See root CMakeLists.txt
#
# ----------------------------------------------------------------------------
project(flann)

# List of C++ files:

include_directories(
   ${CMAKE_CURRENT_SOURCE_DIR}
   ${CMAKE_CURRENT_SOURCE_DIR}/algorithms
   ${CMAKE_CURRENT_SOURCE_DIR}/util
   ${CMAKE_CURRENT_SOURCE_DIR}/nn
   "${CMAKE_CURRENT_SOURCE_DIR}/../include/flann"
   )

# The .cpp files:
file(GLOB_RECURSE flann_sources *.cpp)



# ----------------------------------------------------------------------------------
#           Define the library target:
# ----------------------------------------------------------------------------------

set(the_target "flann")

add_library(${the_target} STATIC ${flann_sources})

if(MSVC)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W3")
    add_definitions(-DJAS_WIN_MSVC_BUILD)
endif()

if(UNIX AND CMAKE_COMPILER_IS_GNUCXX)
     set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
endif()

set_target_properties(${the_target}
   PROPERTIES
   OUTPUT_NAME "${the_target}"
   DEBUG_POSTFIX "${OPENCV_DEBUG_POSTFIX}"
   ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/3rdparty/lib"
   )

else(DEFINED OPENCV_VERSION)
#-----------------------------------------

#include_directories(${CMAKE_SOURCE_DIR}/include algorithms util nn .)
SET(FLANN_SOVERSION "${FLANN_VERSION_MAJOR}.${FLANN_VERSION_MINOR}")

file(GLOB_RECURSE C_SOURCES *.cpp)
file(GLOB_RECURSE CPP_SOURCES *.cpp)

file(GLOB_RECURSE C_FLANN flann.cpp)
file(GLOB_RECURSE CPP_FLANN flann_cpp.cpp)


list(REMOVE_ITEM CPP_SOURCES ${C_FLANN})
list(REMOVE_ITEM C_SOURCES ${CPP_FLANN})


add_library(flann SHARED ${C_SOURCES})
set_target_properties(flann PROPERTIES                                                                       
   VERSION ${FLANN_VERSION}                                                                                          
   SOVERSION ${FLANN_SOVERSION}                                                                                      
) 
add_library(flann_cpp SHARED ${CPP_SOURCES})
set_target_properties(flann_cpp PROPERTIES                                                                       
   VERSION ${FLANN_VERSION}                                                                                          
   SOVERSION ${FLANN_SOVERSION}                                                                                      
) 

add_library(flann_s STATIC ${C_SOURCES})
add_library(flann_cpp_s STATIC ${CPP_SOURCES})

if(WIN32)
    install (
        TARGETS flann
        RUNTIME DESTINATION matlab 
    )
    install (
        TARGETS flann
        RUNTIME DESTINATION python/pyflann/bindings
    )
else(WIN32)
    install (
        TARGETS flann
        LIBRARY DESTINATION python/pyflann/bindings
    )
endif(WIN32)

install (
    TARGETS flann flann_s
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# install (
#     TARGETS flann flann_s
#     ARCHIVE DESTINATION ${PROJECT_SOURCE_DIR}/python
#     LIBRARY DESTINATION ${PROJECT_SOURCE_DIR}/python
# )

install (
    FILES flann.h flann.hpp general.h util/matrix.h util/common.h util/random.h
    DESTINATION include
)

endif(DEFINED OPENCV_VERSION)
