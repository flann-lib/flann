// D import file generated from 'core/Runtime.d'
module tango.core.Runtime;
private
{
    extern (C) 
{
    bool rt_isHalting();
}
    alias bool(* moduleUnitTesterType)();
}
struct Runtime
{
    static
{
    bool isHalting()
{
return rt_isHalting();
}
}
    static
{
    void moduleUnitTester(moduleUnitTesterType h)
{
sm_moduleUnitTester = h;
}
}
    private
{
    static
{
    moduleUnitTesterType sm_moduleUnitTester = null;
}
}
}
extern (C) 
{
    bool runModuleUnitTests();
}
