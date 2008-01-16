/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.sys.Process;

private import tango.io.FileConst;
private import tango.io.Console;
private import tango.io.Buffer;
private import tango.sys.Common;
private import tango.sys.Pipe;
private import tango.core.Exception;
private import tango.text.Util;
private import Integer = tango.text.convert.Integer;

private import tango.stdc.stdlib;
private import tango.stdc.string;
private import tango.stdc.stringz;

version (Posix)
{
    private import tango.stdc.errno;
    private import tango.stdc.posix.fcntl;
    private import tango.stdc.posix.unistd;
    private import tango.stdc.posix.sys.wait;
}

debug (Process)
{
    private import tango.io.Stdout;
}


/**
 * The Process class is used to start external programs and communicate with
 * them via their standard input, output and error streams.
 *
 * You can pass either the command line or an array of arguments to execute,
 * either in the constructor or to the args property. The environment
 * variables can be set in a similar way using the env property and you can
 * set the program's working directory via the workDir property.
 *
 * To actually start a process you need to use the execute() method. Once the
 * program is running you will be able to write to its standard input via the
 * stdin OutputStream and you will be able to read from its standard output and
 * error through the stdout and stderr InputStream respectively.
 *
 * You can check whether the process is running or not with the isRunning()
 * method and you can get its process ID via the pid property.
 *
 * After you are done with the process of if you just want to wait for it to
 * end you need to call the wait() method, which will return once the process
 * is no longer running.
 *
 * To stop a running process you must use kill() method. If you do this you
 * cannot call the wait() method. Once the kill() method returns the process
 * will be already dead.
 *
 * Examples:
 * ---
 * try
 * {
 *     auto p = new Process ("ls -al", null);
 *     p.execute;
 *
 *     Stdout.formatln ("Output from {}:", p.programName);
 *     Stdout.copy (p.stdout).flush;
 *     auto result = p.wait;
 *
 *     Stdout.formatln ("Process '{}' ({}) exited with reason {}, status {}",
 *                      p.programName, p.pid, cast(int) result.reason, result.status);
 * }
 * catch (ProcessException e)
 *        Stdout.formatln ("Process execution failed: {}", e);
 * ---
 */
class Process
{
    /**
     * Result returned by wait().
     */
    public struct Result
    {
        /**
         * Reasons returned by wait() indicating why the process is no
         * longer running.
         */
        public enum
        {
            Exit,
            Signal,
            Stop,
            Continue,
            Error
        }

        public int reason;
        public int status;

        /**
         * Returns a string with a description of the process execution result.
         */
        public char[] toString()
        {
            char[] str;

            switch (reason)
            {
                case Exit:
                    str = format("Process exited normally with return code ", status);
                    break;

                case Signal:
                    str = format("Process was killed with signal ", status);
                    break;

                case Stop:
                    str = format("Process was stopped with signal ", status);
                    break;

                case Continue:
                    str = format("Process was resumed with signal ", status);
                    break;

                case Error:
                    str = format("Process failed with error code ", reason) ~
                                 " : " ~ SysError.lookup(status);
                    break;

                default:
                    str = format("Unknown process result ", reason);
                    break;
            }
            return str;
        }
    }

    static const uint DefaultStdinBufferSize    = 512;
    static const uint DefaultStdoutBufferSize   = 8192;
    static const uint DefaultStderrBufferSize   = 512;

    private char[][]        _args;
    private char[][char[]]  _env;
    private char[]          _workDir;
    private PipeConduit     _stdin;
    private PipeConduit     _stdout;
    private PipeConduit     _stderr;
    private bool            _running = false;

    version (Windows)
    {
        private PROCESS_INFORMATION *_info = null;
    }
    else
    {
        private pid_t _pid = cast(pid_t) -1;
    }

    /**
     * Constructor (variadic version).
     *
     * Params:
     * args     = array of strings with the process' arguments; the first
     *            argument must be the process' name; the arguments can be
     *            empty.
     *
     * Examples:
     * ---
     * auto p = new Process("myprogram", "first argument", "second", "third")
     * ---
     */
    public this(char[][] args ...)
    {
        _args = args;
    }

    /**
     * Constructor.
     *
     * Params:
     * command  = string with the process' command line; arguments that have
     *            embedded whitespace must be enclosed in inside double-quotes (").
     * env      = associative array of strings with the process' environment
     *            variables; the variable name must be the key of each entry.
     *
     * Examples:
     * ---
     * char[] command = "myprogram \"first argument\" second third";
     * char[][char[]] env;
     *
     * // Environment variables
     * env["MYVAR1"] = "first";
     * env["MYVAR2"] = "second";
     *
     * auto p = new Process(command, env)
     * ---
     */
    public this(char[] command, char[][char[]] env)
    in
    {
        assert(command.length > 0);
    }
    body
    {
        _args = splitArgs(command);
        _env = env;
    }

    /**
     * Constructor.
     *
     * Params:
     * args     = array of strings with the process' arguments; the first
     *            argument must be the process' name; the arguments can be
     *            empty.
     * env      = associative array of strings with the process' environment
     *            variables; the variable name must be the key of each entry.
     *
     * Examples:
     * ---
     * char[][] args;
     * char[][char[]] env;
     *
     * // Process name
     * args ~= "myprogram";
     * // Process arguments
     * args ~= "first argument";
     * args ~= "second";
     * args ~= "third";
     *
     * // Environment variables
     * env["MYVAR1"] = "first";
     * env["MYVAR2"] = "second";
     *
     * auto p = new Process(args, env)
     * ---
     */
    public this(char[][] args, char[][char[]] env)
    in
    {
        assert(args.length > 0);
        assert(args[0].length > 0);
    }
    body
    {
        _args = args;
        _env = env;
    }

    /**
     * Indicate whether the process is running or not.
     */
    public bool isRunning()
    {
        return _running;
    }

    /**
     * Return the running process' ID.
     *
     * Returns: an int with the process ID if the process is running;
     *          -1 if not.
     */
    public int pid()
    {
        version (Windows)
        {
            return (_info !is null ? cast(int) _info.dwProcessId : -1);
        }
        else // version (Posix)
        {
            return cast(int) _pid;
        }
    }

    /**
     * Return the process' executable filename.
     */
    public char[] programName()
    {
        return (_args !is null ? _args[0] : null);
    }

    /**
     * Set the process' executable filename.
     */
    public void programName(char[] name)
    {
        if (_args.length == 0)
        {
            _args.length = 1;
        }
        _args[0] = name;
    }

    /**
     * Return an array with the process' arguments.
     */
    public char[][] args()
    {
        return _args;
    }

    /**
     * Set the process' arguments from the arguments received by the method.
     *
     * Remarks:
     * The first element of the array must be the name of the process'
     * executable.
     *
     * Examples:
     * ---
     * p.args("myprogram", "first", "second argument", "third");
     * ---
     */
    public void args(char[][] args ...)
    {
        _args = args;
    }

    /**
     * Return an associative array with the process' environment variables.
     */
    public char[][char[]] env()
    {
        return _env;
    }

    /**
     * Set the process' environment variables from the associative array
     * received by the method.
     *
     * Params:
     * env  = associative array of strings containing the environment
     *        variables for the process. The variable name should be the key
     *        used for each entry.
     *
     * Examples:
     * ---
     * char[][char[]] env;
     *
     * env["MYVAR1"] = "first";
     * env["MYVAR2"] = "second";
     *
     * p.env = env;
     * ---
     */
    public void env(char[][char[]] env)
    {
        _env = env;
    }

    /**
     * Return an UTF-8 string with the process' command line.
     */
    public char[] toString()
    {
        char[] command;

        for (uint i = 0; i < _args.length; ++i)
        {
            if (i > 0)
            {
                command ~= ' ';
            }
            if (contains(_args[i], ' ') || _args[i].length == 0)
            {
                command ~= '"';
                command ~= _args[i];
                command ~= '"';
            }
            else
            {
                command ~= _args[i];
            }
        }
        return command;
    }

    /**
     * Return the working directory for the process.
     *
     * Returns: a string with the working directory; null if the working
     *          directory is the current directory.
     */
    public char[] workDir()
    {
        return _workDir;
    }

    /**
     * Set the working directory for the process.
     *
     * Params:
     * dir  = a string with the working directory; null if the working
     *         directory is the current directory.
     */
    public void workDir(char[] dir)
    {
        _workDir = dir;
    }

    /**
     * Return the running process' standard input pipe.
     *
     * Returns: a write-only PipeConduit connected to the child
     *          process' stdin.
     *
     * Remarks:
     * The stream will be null if no child process has been executed.
     */
    public PipeConduit stdin()
    {
        return _stdin;
    }

    /**
     * Return the running process' standard output pipe.
     *
     * Returns: a read-only PipeConduit connected to the child
     *          process' stdout.
     *
     * Remarks:
     * The stream will be null if no child process has been executed.
     */
    public PipeConduit stdout()
    {
        return _stdout;
    }

    /**
     * Return the running process' standard error pipe.
     *
     * Returns: a read-only PipeConduit connected to the child
     *          process' stderr.
     *
     * Remarks:
     * The stream will be null if no child process has been executed.
     */
    public PipeConduit stderr()
    {
        return _stderr;
    }

    /**
     * Execute a process using the arguments as parameters to this method.
     *
     * Once the process is executed successfully, its input and output can be
     * manipulated through the stdin, stdout and
     * stderr member PipeConduit's.
     *
     * Throws:
     * ProcessCreateException if the process could not be created
     * successfully; ProcessForkException if the call to the fork()
     * system call failed (on POSIX-compatible platforms).
     *
     * Remarks:
     * The process must not be running and the provided list of arguments must
     * not be empty. If there was any argument already present in the args
     * member, they will be replaced by the arguments supplied to the method.
     */
    public void execute(char[][] args ...)
    in
    {
        assert(!_running);
    }
    body
    {
        if (args.length > 0 && args[0] !is null)
        {
            _args = args;
        }
        executeInternal();
    }

    /**
     * Execute a process using the command line arguments as parameters to
     * this method.
     *
     * Once the process is executed successfully, its input and output can be
     * manipulated through the stdin, stdout and
     * stderr member PipeConduit's.
     *
     * Params:
     * command  = string with the process' command line; arguments that have
     *            embedded whitespace must be enclosed in inside double-quotes (").
     * env      = associative array of strings with the process' environment
     *            variables; the variable name must be the key of each entry.
     *
     * Throws:
     * ProcessCreateException if the process could not be created
     * successfully; ProcessForkException if the call to the fork()
     * system call failed (on POSIX-compatible platforms).
     *
     * Remarks:
     * The process must not be running and the provided list of arguments must
     * not be empty. If there was any argument already present in the args
     * member, they will be replaced by the arguments supplied to the method.
     */
    public void execute(char[] command, char[][char[]] env)
    in
    {
        assert(!_running);
        assert(command.length > 0);
    }
    body
    {
        _args = splitArgs(command);
        _env = env;

        executeInternal();
    }

    /**
     * Execute a process using the command line arguments as parameters to
     * this method.
     *
     * Once the process is executed successfully, its input and output can be
     * manipulated through the stdin, stdout and
     * stderr member PipeConduit's.
     *
     * Params:
     * args     = array of strings with the process' arguments; the first
     *            argument must be the process' name; the arguments can be
     *            empty.
     * env      = associative array of strings with the process' environment
     *            variables; the variable name must be the key of each entry.
     *
     * Throws:
     * ProcessCreateException if the process could not be created
     * successfully; ProcessForkException if the call to the fork()
     * system call failed (on POSIX-compatible platforms).
     *
     * Remarks:
     * The process must not be running and the provided list of arguments must
     * not be empty. If there was any argument already present in the args
     * member, they will be replaced by the arguments supplied to the method.
     *
     * Examples:
     * ---
     * auto p = new Process();
     * char[][] args;
     *
     * args ~= "ls";
     * args ~= "-l";
     *
     * p.execute(args, null);
     * ---
     */
    public void execute(char[][] args, char[][char[]] env)
    in
    {
        assert(!_running);
        assert(args.length > 0);
    }
    body
    {
        _args = args;
        _env = env;

        executeInternal();
    }

    /**
     * Execute a process using the arguments that were supplied to the
     * constructor or to the args property.
     *
     * Once the process is executed successfully, its input and output can be
     * manipulated through the stdin, stdout and
     * stderr member PipeConduit's.
     *
     * Throws:
     * ProcessCreateException if the process could not be created
     * successfully; ProcessForkException if the call to the fork()
     * system call failed (on POSIX-compatible platforms).
     *
     * Remarks:
     * The process must not be running and the list of arguments must
     * not be empty before calling this method.
     */
    protected void executeInternal()
    in
    {
        assert(!_running);
        assert(_args.length > 0 && _args[0] !is null);
    }
    body
    {
        version (Windows)
        {
            SECURITY_ATTRIBUTES sa;
            STARTUPINFO         startup;

            // We close and delete the pipes that could have been left open
            // from a previous execution.
            cleanPipes();

            // Set up the security attributes struct.
            sa.nLength = SECURITY_ATTRIBUTES.sizeof;
            sa.lpSecurityDescriptor = null;
            sa.bInheritHandle = true;

            // Set up members of the STARTUPINFO structure.
            memset(&startup, '\0', STARTUPINFO.sizeof);
            startup.cb = STARTUPINFO.sizeof;
            startup.dwFlags |= STARTF_USESTDHANDLES;

            // Create the pipes used to communicate with the child process.
            Pipe pin = new Pipe(DefaultStdinBufferSize, &sa);
            // Replace stdin with the "read" pipe
            _stdin = pin.sink;
            startup.hStdInput = cast(HANDLE) pin.source.fileHandle();
            // Ensure the write handle to the pipe for STDIN is not inherited.
            SetHandleInformation(cast(HANDLE) pin.sink.fileHandle(), HANDLE_FLAG_INHERIT, 0);
            scope(exit)
                pin.source.close();

            Pipe pout = new Pipe(DefaultStdoutBufferSize, &sa);
            // Replace stdout with the "write" pipe
            _stdout = pout.source;
            startup.hStdOutput = cast(HANDLE) pout.sink.fileHandle();
            // Ensure the read handle to the pipe for STDOUT is not inherited.
            SetHandleInformation(cast(HANDLE) pout.source.fileHandle(), HANDLE_FLAG_INHERIT, 0);
            scope(exit)
                pout.sink.close();

            Pipe perr = new Pipe(DefaultStderrBufferSize, &sa);
            // Replace stderr with the "write" pipe
            _stderr = perr.source;
            startup.hStdError = cast(HANDLE) perr.sink.fileHandle();
            // Ensure the read handle to the pipe for STDOUT is not inherited.
            SetHandleInformation(cast(HANDLE) perr.source.fileHandle(), HANDLE_FLAG_INHERIT, 0);
            scope(exit)
                perr.sink.close();

            _info = new PROCESS_INFORMATION;
            // Set up members of the PROCESS_INFORMATION structure.
            memset(_info, '\0', PROCESS_INFORMATION.sizeof);

            char[] command = toString();
            command ~= '\0';

            // Convert the working directory to a null-ended string if
            // necessary.
            if (CreateProcessA(null, command.ptr, null, null, true,
                               DETACHED_PROCESS,
                               (_env.length > 0 ? toNullEndedBuffer(_env).ptr : null),
                               toStringz(_workDir), &startup, _info))
            {
                CloseHandle(_info.hThread);
                _running = true;
            }
            else
            {
                throw new ProcessCreateException(_args[0], __FILE__, __LINE__);
            }
        }
        else version (Posix)
        {
            // We close and delete the pipes that could have been left open
            // from a previous execution.
            cleanPipes();

            Pipe pin = new Pipe(DefaultStdinBufferSize);
            Pipe pout = new Pipe(DefaultStdoutBufferSize);
            Pipe perr = new Pipe(DefaultStderrBufferSize);
            // This pipe is used to propagate the result of the call to
            // execv*() from the child process to the parent process.
            Pipe pexec = new Pipe(8);
            int status = 0;

            _pid = fork();
            if (_pid >= 0)
            {
                if (_pid != 0)
                {
                    // Parent process
                    _stdin = pin.sink;
                    pin.source.close();

                    _stdout = pout.source;
                    pout.sink.close();

                    _stderr = perr.source;
                    perr.sink.close();

                    pexec.sink.close();
                    scope(exit)
                        pexec.source.close();

                    try
                    {
                        pexec.source.input.read((cast(byte*) &status)[0 .. status.sizeof]);
                    }
                    catch (Exception e)
                    {
                        // Everything's OK, the pipe was closed after the call to execv*()
                    }

                    if (status == 0)
                    {
                        _running = true;
                    }
                    else
                    {
                        // We set errno to the value that was sent through
                        // the pipe from the child process
                        errno = status;
                        _running = false;

                        throw new ProcessCreateException(_args[0], __FILE__, __LINE__);
                    }
                }
                else
                {
                    // Child process
                    int rc;
                    char*[] argptr;
                    char*[] envptr;

                    // Replace stdin with the "read" pipe
                    dup2(pin.source.fileHandle(), STDIN_FILENO);
                    pin.sink().close();
                    scope(exit)
                        pin.source.close();

                    // Replace stdout with the "write" pipe
                    dup2(pout.sink.fileHandle(), STDOUT_FILENO);
                    pout.source.close();
                    scope(exit)
                        pout.sink.close();

                    // Replace stderr with the "write" pipe
                    dup2(perr.sink.fileHandle(), STDERR_FILENO);
                    perr.source.close();
                    scope(exit)
                        perr.sink.close();

                    // We close the unneeded part of the execv*() notification pipe
                    pexec.source.close();
                    scope(exit)
                        pexec.sink.close();
                    // Set the "write" pipe so that it closes upon a successful
                    // call to execv*()
                    if (fcntl(cast(int) pexec.sink.fileHandle(), F_SETFD, FD_CLOEXEC) == 0)
                    {
                        // Convert the arguments and the environment variables to
                        // the format expected by the execv() family of functions.
                        argptr = toNullEndedArray(_args);
                        envptr = (_env.length > 0 ? toNullEndedArray(_env) : null);

                        // Switch to the working directory if it has been set.
                        if (_workDir.length > 0)
                        {
                            chdir(toStringz(_workDir));
                        }

                        // Replace the child fork with a new process. We always use the
                        // system PATH to look for executables that don't specify
                        // directories in their names.
                        rc = execvpe(_args[0], argptr, envptr);
                        if (rc == -1)
                        {
                            Cerr("Failed to exec ")(_args[0])(": ")(SysError.lastMsg).newline;

                            try
                            {
                                status = errno;

                                // Propagate the child process' errno value to
                                // the parent process.
                                pexec.sink.output.write((cast(byte*) &status)[0 .. status.sizeof]);
                            }
                            catch (Exception e)
                            {
                            }
                            exit(errno);
                        }
                    }
                    else
                    {
                        Cerr("Failed to set notification pipe to close-on-exec for ")
                            (_args[0])(": ")(SysError.lastMsg).newline;
                        exit(errno);
                    }
                }
            }
            else
            {
                throw new ProcessForkException(_pid, __FILE__, __LINE__);
            }
        }
        else
        {
            assert(false, "tango.sys.Process: Unsupported platform");
        }
    }


    /**
     * Unconditionally wait for a process to end and return the reason and
     * status code why the process ended.
     *
     * Returns:
     * The return value is a Result struct, which has two members:
     * reason and status. The reason can take the
     * following values:
     *
     * Process.Result.Exit: the child process exited normally;
     *                      status has the process' return
     *                      code.
     *
     * Process.Result.Signal: the child process was killed by a signal;
     *                        status has the signal number
     *                        that killed the process.
     *
     * Process.Result.Stop: the process was stopped; status
     *                      has the signal number that was used to stop
     *                      the process.
     *
     * Process.Result.Continue: the process had been previously stopped
     *                          and has now been restarted;
     *                          status has the signal number
     *                          that was used to continue the process.
     *
     * Process.Result.Error: We could not properly wait on the child
     *                       process; status has the
     *                       errno value if the process was
     *                       running and -1 if not.
     *
     * Remarks:
     * You can only call wait() on a running process once. The Signal, Stop
     * and Continue reasons will only be returned on POSIX-compatible
     * platforms.
     */
    public Result wait()
    {
        version (Windows)
        {
            Result result;

            if (_running)
            {
                DWORD rc;
                DWORD exitCode;

                assert(_info !is null);

                // We clean up the process related data and set the _running
                // flag to false once we're done waiting for the process to
                // finish.
                //
                // IMPORTANT: we don't delete the open pipes so that the parent
                //            process can get whatever the child process left on
                //            these pipes before dying.
                scope(exit)
                {
                    CloseHandle(_info.hProcess);
                    _running = false;
                }

                rc = WaitForSingleObject(_info.hProcess, INFINITE);
                if (rc == WAIT_OBJECT_0)
                {
                    GetExitCodeProcess(_info.hProcess, &exitCode);

                    result.reason = Result.Exit;
                    result.status = cast(typeof(result.status)) exitCode;

                    debug (Process)
                        Stdout.formatln("Child process '{0}' ({1}) returned with code {2}\n",
                                        _args[0], _pid, result.status);
                }
                else if (rc == WAIT_FAILED)
                {
                    result.reason = Result.Error;
                    result.status = cast(short) GetLastError();

                    debug (Process)
                        Stdout.formatln("Child process '{0}' ({1}) failed "
                                        "with unknown exit status {2}\n",
                                        _args[0], _pid, result.status);
                }
            }
            else
            {
                result.reason = Result.Error;
                result.status = -1;

                debug (Process)
                    Stdout.formatln("Child process '{0}' is not running", _args[0]);
            }
            return result;
        }
        else version (Posix)
        {
            Result result;

            if (_running)
            {
                int rc;

                // We clean up the process related data and set the _running
                // flag to false once we're done waiting for the process to
                // finish.
                //
                // IMPORTANT: we don't delete the open pipes so that the parent
                //            process can get whatever the child process left on
                //            these pipes before dying.
                scope(exit)
                {
                    _running = false;
                }

                // Wait for child process to end.
                if (waitpid(_pid, &rc, 0) != -1)
                {
                    if (WIFEXITED(rc))
                    {
                        result.reason = Result.Exit;
                        result.status = WEXITSTATUS(rc);
                        if (result.status != 0)
                        {
                            debug (Process)
                                Stdout.formatln("Child process '{0}' ({1}) returned with code {2}\n",
                                                _args[0], _pid, result.status);
                        }
                    }
                    else
                    {
                        if (WIFSIGNALED(rc))
                        {
                            result.reason = Result.Signal;
                            result.status = WTERMSIG(rc);

                            debug (Process)
                                Stdout.formatln("Child process '{0}' ({1}) was killed prematurely "
                                                "with signal {2}",
                                                _args[0], _pid, result.status);
                        }
                        else if (WIFSTOPPED(rc))
                        {
                            result.reason = Result.Stop;
                            result.status = WSTOPSIG(rc);

                            debug (Process)
                                Stdout.formatln("Child process '{0}' ({1}) was stopped "
                                                "with signal {2}",
                                                _args[0], _pid, result.status);
                        }
                        else if (WIFCONTINUED(rc))
                        {
                            result.reason = Result.Stop;
                            result.status = WSTOPSIG(rc);

                            debug (Process)
                                Stdout.formatln("Child process '{0}' ({1}) was continued "
                                                "with signal {2}",
                                                _args[0], _pid, result.status);
                        }
                        else
                        {
                            result.reason = Result.Error;
                            result.status = rc;

                            debug (Process)
                                Stdout.formatln("Child process '{0}' ({1}) failed "
                                                "with unknown exit status {2}\n",
                                                _args[0], _pid, result.status);
                        }
                    }
                }
                else
                {
                    result.reason = Result.Error;
                    result.status = errno;

                    debug (Process)
                        Stdout.formatln("Could not wait on child process '{0}' ({1}): ({2}) {3}",
                                        _args[0], _pid, result.status, SysError.lastMsg);
                }
            }
            else
            {
                result.reason = Result.Error;
                result.status = -1;

                debug (Process)
                    Stdout.formatln("Child process '{0}' is not running", _args[0]);
            }
            return result;
        }
        else
        {
            assert(false, "tango.sys.Process: Unsupported platform");
        }
    }

    /**
     * Kill a running process. This method will not return until the process
     * has been killed.
     *
     * Throws:
     * ProcessKillException if the process could not be killed;
     * ProcessWaitException if we could not wait on the process after
     * killing it.
     *
     * Remarks:
     * After calling this method you will not be able to call wait() on the
     * process.
     */
    public void kill()
    {
        version (Windows)
        {
            if (_running)
            {
                assert(_info !is null);

                if (TerminateProcess(_info.hProcess, cast(UINT) -1))
                {
                    assert(_info !is null);

                    // We clean up the process related data and set the _running
                    // flag to false once we're done waiting for the process to
                    // finish.
                    //
                    // IMPORTANT: we don't delete the open pipes so that the parent
                    //            process can get whatever the child process left on
                    //            these pipes before dying.
                    scope(exit)
                    {
                        CloseHandle(_info.hProcess);
                        _running = false;
                    }

                    // FIXME: We should probably use a timeout here
                    if (WaitForSingleObject(_info.hProcess, INFINITE) == WAIT_FAILED)
                    {
                        throw new ProcessWaitException(cast(int) _info.dwProcessId,
                                                       __FILE__, __LINE__);
                    }
                }
                else
                {
                    throw new ProcessKillException(cast(int) _info.dwProcessId,
                                                   __FILE__, __LINE__);
                }
            }
            else
            {
                debug (Process)
                    Stdout.print("Tried to kill an invalid process");
            }
        }
        else version (Posix)
        {
            if (_running)
            {
                int rc;

                assert(_pid > 0);

                if (.kill(_pid, SIGTERM) != -1)
                {
                    // We clean up the process related data and set the _running
                    // flag to false once we're done waiting for the process to
                    // finish.
                    //
                    // IMPORTANT: we don't delete the open pipes so that the parent
                    //            process can get whatever the child process left on
                    //            these pipes before dying.
                    scope(exit)
                    {
                        _running = false;
                    }

                    // FIXME: is this loop really needed?
                    for (uint i = 0; i < 100; i++)
                    {
                        rc = waitpid(pid, null, WNOHANG | WUNTRACED);
                        if (rc == _pid)
                        {
                            break;
                        }
                        else if (rc == -1)
                        {
                            throw new ProcessWaitException(cast(int) _pid, __FILE__, __LINE__);
                        }
                        usleep(50000);
                    }
                }
                else
                {
                    throw new ProcessKillException(_pid, __FILE__, __LINE__);
                }
            }
            else
            {
                debug (Process)
                    Stdout.print("Tried to kill an invalid process");
            }
        }
        else
        {
            assert(false, "tango.sys.Process: Unsupported platform");
        }
    }

    /**
     * Split a string containing the command line used to invoke a program
     * and return and array with the parsed arguments. The double-quotes (")
     * character can be used to specify arguments with embedded spaces.
     * e.g. first "second param" third
     */
    protected static char[][] splitArgs(inout char[] command, char[] delims = " \t\r\n")
    in
    {
        assert(!contains(delims, '"'),
               "The argument delimiter string cannot contain a double quotes ('\"') character");
    }
    body
    {
        enum State
        {
            Start,
            FindDelimiter,
            InsideQuotes
        }

        char[][]    args = null;
        char[][]    chunks = null;
        int         start = -1;
        char        c;
        int         i;
        State       state = State.Start;

        // Append an argument to the 'args' array using the 'chunks' array
        // and the current position in the 'command' string as the source.
        void appendChunksAsArg()
        {
            uint argPos;

            if (chunks.length > 0)
            {
                // Create the array element corresponding to the argument by
                // appending the first chunk.
                args   ~= chunks[0];
                argPos  = args.length - 1;

                for (uint chunkPos = 1; chunkPos < chunks.length; ++chunkPos)
                {
                    args[argPos] ~= chunks[chunkPos];
                }

                if (start != -1)
                {
                    args[argPos] ~= command[start .. i];
                }
                chunks.length = 0;
            }
            else
            {
                if (start != -1)
                {
                    args ~= command[start .. i];
                }
            }
            start = -1;
        }

        for (i = 0; i < command.length; i++)
        {
            c = command[i];

            switch (state)
            {
                // Start looking for an argument.
                case State.Start:
                    if (c == '"')
                    {
                        state = State.InsideQuotes;
                    }
                    else if (!contains(delims, c))
                    {
                        start = i;
                        state = State.FindDelimiter;
                    }
                    else
                    {
                        appendChunksAsArg();
                    }
                    break;

                // Find the ending delimiter for an argument.
                case State.FindDelimiter:
                    if (c == '"')
                    {
                        // If we find a quotes character this means that we've
                        // found a quoted section of an argument. (e.g.
                        // abc"def"ghi). The quoted section will be appended
                        // to the preceding part of the argument. This is also
                        // what Unix shells do (i.e. a"b"c becomes abc).
                        if (start != -1)
                        {
                            chunks ~= command[start .. i];
                            start = -1;
                        }
                        state = State.InsideQuotes;
                    }
                    else if (contains(delims, c))
                    {
                        appendChunksAsArg();
                        state = State.Start;
                    }
                    break;

                // Inside a quoted argument or section of an argument.
                case State.InsideQuotes:
                    if (start == -1)
                    {
                        start = i;
                    }

                    if (c == '"')
                    {
                        chunks ~= command[start .. i];
                        start = -1;
                        state = State.Start;
                    }
                    break;

                default:
                    assert(false, "Invalid state in Process.splitArgs");
            }
        }

        // Add the last argument (if there is one)
        appendChunksAsArg();

        return args;
    }

    /**
     * Close and delete any pipe that may have been left open in a previous
     * execution of a child process.
     */
    protected void cleanPipes()
    {
        delete _stdin;
        delete _stdout;
        delete _stderr;
    }

    version (Windows)
    {
        /**
         * Convert an associative array of strings to a buffer containing a
         * concatenation of "<name>=<value>" strings separated by a null
         * character and with an additional null character at the end of it.
         * This is the format expected by the CreateProcess() Windows API for
         * the environment variables.
         */
        protected static char[] toNullEndedBuffer(char[][char[]] src)
        {
            char[] dest;

            foreach (key, value; src)
            {
                dest ~= key ~ '=' ~ value ~ '\0';
            }

            if (dest.length > 0)
            {
                dest ~= '\0';
            }

            return dest;
        }
    }
    else version (Posix)
    {
        /**
         * Convert an array of strings to an array of pointers to char with
         * a terminating null character (C strings). The resulting array
         * has a null pointer at the end. This is the format expected by
         * the execv*() family of POSIX functions.
         */
        protected static char*[] toNullEndedArray(char[][] src)
        {
            if (src !is null)
            {
                char*[] dest = new char*[src.length + 1];
                int     i = src.length;

                // Add terminating null pointer to the array
                dest[i] = null;

                while (--i >= 0)
                {
                    // Add a terminating null character to each string
                    dest[i] = toStringz(src[i]);
                }
                return dest;
            }
            else
            {
                return null;
            }
        }

        /**
         * Convert an associative array of strings to an array of pointers to
         * char with a terminating null character (C strings). The resulting
         * array has a null pointer at the end. This is the format expected by
         * the execv*() family of POSIX functions for environment variables.
         */
        protected static char*[] toNullEndedArray(char[][char[]] src)
        {
            char*[] dest;

            foreach (key, value; src)
            {
                dest ~= (key ~ '=' ~ value ~ '\0').ptr;
            }

            if (dest.length > 0)
            {
                dest ~= null;
            }
            return dest;
        }

        /**
         * Execute a process by looking up a file in the system path, passing
         * the array of arguments and the the environment variables. This
         * method is a combination of the execve() and execvp() POSIX system
         * calls.
         */
        protected static int execvpe(char[] filename, char*[] argv, char*[] envp)
        in
        {
            assert(filename.length > 0);
        }
        body
        {
            int rc = -1;
            char* str;

            if (!contains(filename, FileConst.PathSeparatorChar) &&
                (str = getenv("PATH")) !is null)
            {
                char[][] pathList = delimit(str[0 .. strlen(str)], ":");

                foreach (path; pathList)
                {
                    if (path[path.length - 1] != FileConst.PathSeparatorChar)
                    {
                        path ~= FileConst.PathSeparatorChar;
                    }

                    debug (Process)
                        Stdout.formatln("Trying execution of '{0}' in directory '{1}'",
                                        filename, path);

                    path ~= filename;
                    path ~= '\0';

                    rc = execve(path.ptr, argv.ptr, (envp.length > 0 ? envp.ptr : null));
                    // If the process execution failed because of an error
                    // other than ENOENT (No such file or directory) we
                    // abort the loop.
                    if (rc == -1 && errno != ENOENT)
                    {
                        break;
                    }
                }
            }
            else
            {
                debug (Process)
                    Stdout.formatln("Calling execve('{0}', argv[{1}], {2})",
                                    (argv[0])[0 .. strlen(argv[0])],
                                    argv.length, (envp.length > 0 ? "envp" : "null"));

                rc = execve(argv[0], argv.ptr, (envp.length > 0 ? envp.ptr : null));
            }
            return rc;
        }
    }
}


/**
 * Exception thrown when the process cannot be created.
 */
class ProcessCreateException: ProcessException
{
    public this(char[] command, char[] file, uint line)
    {
        super("Could not create process for " ~ command ~ " : " ~ SysError.lastMsg);
    }
}

/**
 * Exception thrown when the parent process cannot be forked.
 *
 * This exception will only be thrown on POSIX-compatible platforms.
 */
class ProcessForkException: ProcessException
{
    public this(int pid, char[] file, uint line)
    {
        super(format("Could not fork process ", pid) ~ " : " ~ SysError.lastMsg);
    }
}

/**
 * Exception thrown when the process cannot be killed.
 */
class ProcessKillException: ProcessException
{
    public this(int pid, char[] file, uint line)
    {
        super(format("Could not kill process ", pid) ~ " : " ~ SysError.lastMsg);
    }
}

/**
 * Exception thrown when the parent process tries to wait on the child
 * process and fails.
 */
class ProcessWaitException: ProcessException
{
    public this(int pid, char[] file, uint line)
    {
        super(format("Could not wait on process ", pid) ~ " : " ~ SysError.lastMsg);
    }
}




/**
 *  append an int argument to a message
*/
private char[] format (char[] msg, int value)
{
    char[10] tmp;

    return msg ~ Integer.format (tmp, value);
}


debug (UnitTest)
{
    private import tango.text.stream.LineIterator;

    unittest
    {
        char[][] params;
        char[] command = "echo ";

        params ~= "one";
        params ~= "two";
        params ~= "three";

        command ~= '"';
        foreach (i, param; params)
        {
            command ~= param;
            if (i != params.length - 1)
            {
                command ~= '\n';
            }
        }
        command ~= '"';

        try
        {
            auto p = new Process(command, null);

            p.execute();

            foreach (i, line; new LineIterator!(char)(p.stdout))
            {
                if (i == params.length) // echo can add ending new line confusing this test
                    break;
                assert(line == params[i]);
            }

            auto result = p.wait();

            assert(result.reason == Process.Result.Exit && result.status == 0);
        }
        catch (ProcessException e)
        {
            Cerr("Program execution failed: ")(e.toString()).newline();
        }
    }
}

