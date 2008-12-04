#ifndef VARIANT_H
#define VARIANT_H

#include <string>
#include <cstring>
#include <sstream>

using namespace std;


class Variant {
    enum {
        INT,
        FLOAT,
        DOUBLE,
        STR
    } type;

    union {
        int intVal;
        float floatVal;
        double doubleVal;
        const char* strVal;
    };

    public:
    

    Variant()
    {
        doubleVal = 0;
        type = DOUBLE;        
    };

    Variant(int val) 
    {
        intVal = val;
        type = INT;
    }
    
    Variant(float val) 
    {
        floatVal = val;
        type = FLOAT;
    }
    
    Variant(double val) 
    {
        doubleVal = val;
        type = DOUBLE;
    }
    
    Variant(const char* val) 
    {
        strVal = val;
        type = STR;
    }
    
    operator int()
    {
        return intVal;
    }
        
    operator float()
    {
        return floatVal;
    }
    
    operator double()
    {
        return doubleVal;
    }
    
    operator const char*()
    {
        return strVal;
    }

    bool operator==(int val)
    {
        return type==INT && intVal==val;
    }

    bool operator==(float val)
    {
        return type==FLOAT && floatVal==val;
    }

    bool operator==(double val)
    {
        return type==DOUBLE && doubleVal==val;
    }

    bool operator==(const char* val)
    {
        return type==STR && strcmp(strVal,val)==0;
    }

    string toString()
    {
        ostringstream ss;
        if (type==INT) {
            ss << intVal;
        }
        else if (type==FLOAT) {
            ss << floatVal;
        }
        else if (type==DOUBLE) {
            ss << doubleVal;
        }
        else if (type==STR) {
            ss << strVal;
        }

        return ss.str();
    }
};

#endif // VARIANT_H
