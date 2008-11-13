#ifndef LOGGER_H
#define LOGGER_H


#include <cstdio>
#include "common.h"
#include "flann.h"

using namespace std;


void log_params(int level, Params p);

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

    int log(int level, const char* fmt, ...);

    int log(int level, const char* fmt, va_list arglist);

    int fatal(const char* fmt, ...);

    int error(const char* fmt, ...);

    int warn(const char* fmt, ...);

    int info(const char* fmt, ...);    
};

extern Logger logger;

#endif //LOGGER_H
