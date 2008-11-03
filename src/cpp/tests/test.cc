#include <stdio.h>
#include <map>

using namespace std;



class TestClass
{

public:
    TestClass()
    {
        printf("Constructor\n");
    }
    
    ~TestClass()
    {
        printf("Destructor\n");
    }

};



int main()
{
    TestClass& c = *(new TestClass());

    delete &c;
}
