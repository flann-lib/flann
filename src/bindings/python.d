// A minimal "hello world" Pyd module.
module bindings.python;
import pyd.pyd;
import pyd.def;
import pyd.exception;
import d.python_so_linux_boilerplate;

extern(C)
export void inithello() {
	pyd.exception.exception_catcher(delegate void() {
			pyd.def.pyd_module_name = "nn";
			PydMain();
			});
}




extern(C) void PydMain() {
	def!(print_message);
	module_init();
}


