#ifndef COMMOM_H
#define COMMOM_H


#define ARRAY_LEN(a) (sizeof(a)/sizeof(a[0]))


#include "Variant.h"
#include <map>
#include <string>
#include <stdexcept>

class FLANNException : public std::runtime_error {
 public:
   FLANNException(const char* message) : std::runtime_error(message) { }
 };

typedef std::map<std::string,Variant> Params;

#endif //COMMOM_H
