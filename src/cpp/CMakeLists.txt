
INCLUDE_DIRECTORIES(algorithms util nn .)

ADD_SUBDIRECTORY( tests )

ADD_LIBRARY(flann flann.cpp)