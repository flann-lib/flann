#include "Logger.h"

#include <cstdio>
#include <cstdarg>
#include "flann.h"
#include <sstream>

using namespace std;


Logger logger;

void log_params(int level, Params p)
{
    Params::iterator it;
    logger.log(level, "{ ");
    bool first = true;
    for (it=p.begin(); it!=p.end(); ++it) {
        if (!first) {
            logger.info(", ");
        }
        first = false;
        logger.log(level, "%s : ",it->first.c_str());
        logger.log(level, "%s",(it->second).toString().c_str());
    }
    logger.log(level, " }");
}


int Logger::log(int level, const char* fmt, ...)
{
    if (level > logLevel ) return -1;

    int ret;
    va_list arglist;
    va_start(arglist, fmt);
    ret = vfprintf(stream, fmt, arglist);
    va_end(arglist);

    return ret;
}

int Logger::log(int level, const char* fmt, va_list arglist)
{
    if (level > logLevel ) return -1;

    int ret;
    ret = vfprintf(stream, fmt, arglist);

    return ret;
}


#define LOG_METHOD(NAME,LEVEL) \
    int Logger::NAME(const char* fmt, ...) \
    { \
        int ret; \
        va_list ap; \
        va_start(ap, fmt); \
        ret = log(LEVEL, fmt, ap); \
        va_end(ap); \
        return ret; \
    }


LOG_METHOD(fatal, LOG_FATAL)
LOG_METHOD(error, LOG_ERROR)
LOG_METHOD(warn, LOG_WARN)
LOG_METHOD(info, LOG_INFO)

