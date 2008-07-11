module tango.sys.linux.linux;


version (linux) {
    public import tango.stdc.time;
    public import tango.stdc.posix.dlfcn;
    public import tango.stdc.posix.fcntl;
    public import tango.stdc.posix.poll;
    public import tango.stdc.posix.pwd;
    public import tango.stdc.posix.time;
    public import tango.stdc.posix.unistd;
    public import tango.stdc.posix.sys.select;
    public import tango.stdc.posix.sys.stat;
    public import tango.stdc.posix.sys.types;
    public import tango.sys.linux.epoll;
}
