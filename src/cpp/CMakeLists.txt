
INCLUDE_DIRECTORIES(algorithms util nn .)

ADD_SUBDIRECTORY( tests )

SET(SOURCES flann.cpp util/Random.cpp nn/Testing.cpp algorithms/NNIndex.cpp util/Logger.cpp)

ADD_LIBRARY(flann SHARED ${SOURCES})
ADD_LIBRARY(flann_s STATIC ${SOURCES})

IF(WIN32)
INSTALL (
    TARGETS flann
    RUNTIME DESTINATION matlab
)
INSTALL (
    TARGETS flann
    RUNTIME DESTINATION python/pyflann/bindings
)
ELSE(WIN32)
INSTALL (
    TARGETS flann
    LIBRARY DESTINATION python/pyflann/bindings
)
ENDIF(WIN32)

INSTALL (
    TARGETS flann flann_s
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# INSTALL (
#     TARGETS flann flann_s
#     ARCHIVE DESTINATION ${PROJECT_SOURCE_DIR}/python
#     LIBRARY DESTINATION ${PROJECT_SOURCE_DIR}/python
# )

INSTALL (
    FILES flann.h constants.h
    DESTINATION include
)