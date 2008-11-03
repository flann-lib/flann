#ifndef VARIANT_H
#define VARIANT_H

#include <stdio.h>


class Variant {
    public:
    union {
        int intVal;
        float floatVal;
        double doubleVal;
        const char* strVal;
    };
    

    Variant()
    {
        doubleVal = 0;
    };

    Variant(int val) 
    {
        intVal = val;
    }
    
    Variant(float val) 
    {
        floatVal = val;
    }
    
    Variant(double val) 
    {
        doubleVal = val;
    }
    
    Variant(const char* val) 
    {
        strVal = val;
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
        return intVal==val;
    }

    bool operator==(float val)
    {
        return floatVal==val;
    }

    bool operator==(double val)
    {
        return doubleVal==val;
    }

    bool operator==(const char* val)
    {
        return strVal==val;
    }
};

#endif // VARIANT_H
