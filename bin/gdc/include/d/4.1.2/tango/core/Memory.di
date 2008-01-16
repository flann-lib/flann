// D import file generated from 'core/Memory.d'
module tango.core.Memory;
private
{
    extern (C) 
{
    void gc_init();
}
    extern (C) 
{
    void gc_term();
}
    extern (C) 
{
    void gc_enable();
}
    extern (C) 
{
    void gc_disable();
}
    extern (C) 
{
    void gc_collect();
}
    extern (C) 
{
    uint gc_getAttr(void* p);
}
    extern (C) 
{
    uint gc_setAttr(void* p, uint a);
}
    extern (C) 
{
    uint gc_clrAttr(void* p, uint a);
}
    extern (C) 
{
    void* gc_malloc(size_t sz, uint ba = 0);
}
    extern (C) 
{
    void* gc_calloc(size_t sz, uint ba = 0);
}
    extern (C) 
{
    void* gc_realloc(void* p, size_t sz, uint ba = 0);
}
    extern (C) 
{
    size_t gc_extend(void* p, size_t mx, size_t sz);
}
    extern (C) 
{
    void gc_free(void* p);
}
    extern (C) 
{
    void* gc_addrOf(void* p);
}
    extern (C) 
{
    size_t gc_sizeOf(void* p);
}
    struct BlkInfo_
{
    void* base;
    size_t size;
    uint attr;
}
    extern (C) 
{
    BlkInfo_ gc_query(void* p);
}
    extern (C) 
{
    void gc_addRoot(void* p);
}
    extern (C) 
{
    void gc_addRange(void* p, size_t sz);
}
    extern (C) 
{
    void gc_removeRoot(void* p);
}
    extern (C) 
{
    void gc_removeRange(void* p);
}
    alias bool(* collectHandlerType)(Object obj);
}
struct GC
{
    static
{
    void enable()
{
gc_enable();
}
}
    static
{
    void disable()
{
gc_disable();
}
}
    static
{
    void collect()
{
gc_collect();
}
}
    enum BlkAttr : uint
{
FINALIZE = 1,
NO_SCAN = 2,
NO_MOVE = 4,
}
    alias BlkInfo_ BlkInfo;
    static
{
    uint getAttr(void* p)
{
return gc_getAttr(p);
}
}
    static
{
    uint setAttr(void* p, uint a)
{
return gc_setAttr(p,a);
}
}
    static
{
    uint clrAttr(void* p, uint a)
{
return gc_clrAttr(p,a);
}
}
    static
{
    void* malloc(size_t sz, uint ba = 0)
{
return gc_malloc(sz,ba);
}
}
    static
{
    void* calloc(size_t sz, uint ba = 0)
{
return gc_calloc(sz,ba);
}
}
    static
{
    void* realloc(void* p, size_t sz, uint ba = 0)
{
return gc_realloc(p,sz,ba);
}
}
    static
{
    size_t extend(void* p, size_t mx, size_t sz)
{
return gc_extend(p,mx,sz);
}
}
    static
{
    void free(void* p)
{
gc_free(p);
}
}
    static
{
    void* addrOf(void* p)
{
return gc_addrOf(p);
}
}
    static
{
    size_t sizeOf(void* p)
{
return gc_sizeOf(p);
}
}
    static
{
    BlkInfo query(void* p)
{
return gc_query(p);
}
}
    static
{
    void addRoot(void* p)
{
gc_addRoot(p);
}
}
    static
{
    void addRange(void* p, size_t sz)
{
gc_addRange(p,sz);
}
}
    static
{
    void removeRoot(void* p)
{
gc_removeRoot(p);
}
}
    static
{
    void removeRange(void* p)
{
gc_removeRange(p);
}
}
    static
{
    void collectHandler(collectHandlerType h)
{
sm_collectHandler = h;
}
}
    private
{
    static
{
    collectHandlerType sm_collectHandler = null;
}
}
}
extern (C) 
{
    bool onCollectResource(Object obj);
}
