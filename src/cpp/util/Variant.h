/*
Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.

THE BSD LICENSE

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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
