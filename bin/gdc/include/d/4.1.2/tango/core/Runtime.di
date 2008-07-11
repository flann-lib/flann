// D import file generated from 'core/Runtime.d'
module tango.core.Runtime;
private
{
    extern (C) 
{
    bool rt_isHalting();
}
    alias bool function() ModuleUnitTester;
    alias bool function(Object) CollectHandler;
    alias Exception.TraceInfo function(void* ptr = null) TraceHandler;
    extern (C) 
{
    void rt_setCollectHandler(CollectHandler h);
}
    extern (C) 
{
    void rt_setTraceHandler(TraceHandler h);
}
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
    void traceHandler(TraceHandler h)
{
rt_setTraceHandler(h);
}
}
    static
{
    void collectHandler(CollectHandler h)
{
rt_setCollectHandler(h);
}
}
    static
{
    void moduleUnitTester(ModuleUnitTester h)
{
sm_moduleUnitTester = h;
}
}
    private
{
    static
{
    ModuleUnitTester sm_moduleUnitTester = null;
}
}
}
extern (C) 
{
    bool runModuleUnitTests();
}
