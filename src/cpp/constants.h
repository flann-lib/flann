#ifndef CONSTANTS_H
#define CONSTANTS_H



/* Nearest neighbor index algorithms */
const int LINEAR    = 0;
const int KDTREE    = 1;
const int KMEANS    = 2;
const int COMPOSITE = 3;

const int CENTERS_RANDOM = 0;
const int CENTERS_GONZALES = 1;
const int CENTERS_KMEANSPP = 2;


const int LOG_NONE  = 0;
const int LOG_FATAL = 1;
const int LOG_ERROR = 2;
const int LOG_WARN  = 3;
const int LOG_INFO  = 4;

#endif  // CONSTANTS_H
