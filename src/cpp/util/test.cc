#include <stdio.h>


class A
{
    public:
    int val;
    
    A() {
        printf("A constructor.\n");
    }
    ~A() {
        printf("A destructor.\n");
    }
};


class B
{

    class C
    {
        public:
        C() {
            printf("C constructor.\n");
        }
        ~C() {
            printf("C destructor.\n");
        }
    };


    C c;

    A& a;
    public:
    B(A& a_) : a(a_)  {
        printf("B constructor.\n");
        printf("A val: %d\n",a.val);
    }
    ~B() {
        printf("B destructor.\n");
    }
};


int main()
{
    A a;
    a.val = 12;
    printf("In main1\n");
    B b(a);
    printf("In main\n");

//     B::C c;
}
