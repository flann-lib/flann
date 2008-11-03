#ifndef LOGGER_H
#define LOGGER_H


#include <cstdio>
#include <cstdarg>
#include "flann.h"
#include <sstream>

using namespace std;


#define LOG_METHOD(NAME,LEVEL) \
    int NAME(const char* fmt, ...) \
    { \
        int ret; \
        va_list ap; \
        va_start(ap, fmt); \
        ret = log(LEVEL, fmt, ap); \
        va_end(ap); \
        return ret; \
    }


class Logger
{
    int logLevel;

    FILE* stream;
    

public:

    Logger() : stream(stdout), logLevel(LOG_WARN) {};
    
    ~Logger()
    {
        if (stream!=NULL && stream!=stdout) {
            fclose(stream);
        }
    }

    void setDestination(const char* name)
    {
        if (name==NULL) {
            stream = stdout;
        }
        else {
            stream = fopen(name,"w");
            if (stream == NULL) {
                stream = stdout;
            }
        }
    }

    void setLevel(int level) { logLevel = level; }

    int log(int level, const char* fmt, ...)
    {
        if (level > logLevel ) return -1;

        int ret;
        va_list arglist;
        va_start(arglist, fmt);
        ret = vfprintf(stream, fmt, arglist);
        va_end(arglist);

        return ret;
    }

    int log(int level, const char* fmt, va_list arglist)
    {
        if (level > logLevel ) return -1;

        int ret;
        ret = vfprintf(stream, fmt, arglist);

        return ret;
    }

    LOG_METHOD(fatal, LOG_FATAL)
    LOG_METHOD(error, LOG_ERROR)
    LOG_METHOD(warn, LOG_WARN)
    LOG_METHOD(info, LOG_INFO)
    
};

Logger logger;

#endif //LOGGER_H
