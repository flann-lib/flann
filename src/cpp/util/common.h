#ifndef COMMOM_H
#define COMMOM_H


#define ARRAY_LEN(a) (sizeof(a)/sizeof(a[0]))


#include "Variant.h"
#include "Logger.h"
#include <map>
#include <stdexcept>

class FLANNException : public std::runtime_error {
 public:
   FLANNException(const char* message) : std::runtime_error(message) { }
 };

typedef std::map<const char*,Variant> Params;



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
        logger.log(level, "%s : ",it->first);
        logger.log(level, "%s",(it->second).toString().c_str());
    }
    logger.log(level, " }");
}

#endif //COMMOM_H
