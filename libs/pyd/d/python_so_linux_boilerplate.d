// This file requires the .so be compiled with '-nostartfiles'.
// Also note that this is inferior to the Windows version: it does not call the
// static constructors or unit tests. As far as I can tell, this can't be done
// until Phobos is updated to explicitly allow it.
extern(C) {

void gc_init();
void gc_term();

void _init() {
    gc_init();
}

void _fini() {
    gc_term();
}

} /* extern(C) */
