module tango.sys.linux.epoll;

version (linux)
{
	// From <sys/epoll.h>: support for the Linux epoll_*() system calls
	extern (C)
	{
		enum: uint
		{
			EPOLLIN         = 0x001,
			EPOLLPRI        = 0x002,
			EPOLLOUT        = 0x004,
			EPOLLRDNORM     = 0x040,
			EPOLLRDBAND     = 0x080,
			EPOLLWRNORM     = 0x100,
			EPOLLWRBAND     = 0x200,
			EPOLLMSG        = 0x400,
			EPOLLERR        = 0x008,
			EPOLLHUP        = 0x010,
			EPOLLONESHOT    = (1 << 30),
			EPOLLET         = (1 << 31)
		}

		// Valid opcodes ( "op" parameter ) to issue to epoll_ctl().
		public const int EPOLL_CTL_ADD = 1;	// Add a file descriptor to the interface.
		public const int EPOLL_CTL_DEL = 2;	// Remove a file descriptor from the interface.
		public const int EPOLL_CTL_MOD = 3;	// Change file descriptor epoll_event structure.

		align(1) union epoll_data
		{
			void* ptr;
			int fd;
			uint u32;
			ulong u64;
		}

		alias epoll_data epoll_data_t;

		align(1) struct epoll_event
		{
			uint events;		// Epoll events
			epoll_data_t data;	// User data variable
		}

		// Creates an epoll instance. Returns an fd for the new instance.
		// The "size" parameter is a hint specifying the number of file
		// descriptors to be associated with the new instance. The fd
		// returned by epoll_create() should be closed with close().
		int epoll_create(int size);

		// Manipulate an epoll instance "epfd". Returns 0 in case of success,
		// -1 in case of error (the "errno" variable will contain the
		// specific error code) The "op" parameter is one of the EPOLL_CTL_*
		// constants defined above. The "fd" parameter is the target of the
		// operation. The "event" parameter describes which events the caller
		// is interested in and any associated user data.
		int epoll_ctl(int epfd, int op, int fd, epoll_event* event);

		// Wait for events on an epoll instance "epfd". Returns the number of
		// triggered events returned in "events" buffer. Or -1 in case of
		// error with the "errno" variable set to the specific error code. The
		// "events" parameter is a buffer that will contain triggered
		// events. The "maxevents" is the maximum number of events to be
		// returned (usually size of "events"). The "timeout" parameter
		// specifies the maximum wait time in milliseconds (-1 == infinite).
		int epoll_wait(int epfd, epoll_event* events, int maxevents, int timeout);
	}
}
