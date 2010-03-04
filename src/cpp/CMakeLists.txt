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

file(GLOB_RECURSE SOURCES *.cpp)

add_library(flann SHARED ${SOURCES})
add_library(flann_s STATIC ${SOURCES})

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
    FILES flann.h flann.hpp constants.h util/matrix.h util/common.h util/random.h
    DESTINATION include
)

endif(DEFINED OPENCV_VERSION)
