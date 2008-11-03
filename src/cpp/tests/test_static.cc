#include <stdio.h>



template <typename T>
class StaticInit {
    public:
    StaticInit() {
        T::static_init();
    }
};


class Test
{
    static StaticInit<Test> s;

    static int val;
public:


    static void static_init() {
        printf("In static constructor\n");
        val = 20;
    }

    Test()
    {
        printf("In normal constructor\n");
    }
    
    void test() {
        printf("val=%d\n",val);
    }
    
};
StaticInit<Test> Test::s;
int Test::val = 10;



int main()
{
    printf("In main\n");
    Test t;

    t.test();
    
    Test t2;
    t.test();
}
