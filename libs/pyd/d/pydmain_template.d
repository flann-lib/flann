import pyd.def;
import pyd.exception;

extern(C) void PydMain();

extern(C)
export void init%(modulename)s() {
    pyd.exception.exception_catcher(delegate void() {
        pyd.def.pyd_module_name = "%(modulename)s";
        PydMain();
    });
}

