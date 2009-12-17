find_package(Boost COMPONENTS system thread REQUIRED)

set(FLANN_HOME "/home/marius/ubc/flann/build")

INCLUDE_DIRECTORIES( ${FLANN_HOME}/include )
LINK_DIRECTORIES( ${FLANN_HOME}/lib )

ADD_EXECUTABLE(flann_mt_test flann_mt_test.cpp)
TARGET_LINK_LIBRARIES(flann_mt_test ${Boost_SYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY} flann)

INSTALL (
    FILES build/flann_mt_test
    DESTINATION ${FLANN_HOME}/bin
)
