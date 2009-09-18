CMAKE_MINIMUM_REQUIRED(VERSION 2.4)

PROJECT( flann )

set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR}/../build)

ADD_SUBDIRECTORY( cpp )
#temporary removing matlab bindings, until refactoring done
#ADD_SUBDIRECTORY( matlab )
ADD_SUBDIRECTORY( python )
