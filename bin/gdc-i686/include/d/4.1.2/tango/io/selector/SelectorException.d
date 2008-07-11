/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.io.selector.SelectorException;

//private import tango.core.Exception;


/**
 * SelectorException is thrown when the Selector cannot be created because
 * of insufficient resources (file descriptors, memory, etc.)
 */
public class SelectorException: Exception
{
    /**
     * Construct a selector exception with the provided text string
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] msg, char[] file, uint line)
    {
        super(msg, file, line);
    }
}


/**
 * UnregisteredConduitException is thrown when the selector looks for a
 * registered conduit and it cannot find it.
 */
public class UnregisteredConduitException: SelectorException
{
    /**
     * Construct a selector exception with the provided text string
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The conduit is not registered to the selector", file, line);
    }
}

/**
 * RegisteredConduitException is thrown when a selector detects that a conduit
 * registration was attempted more than once.
 */
public class RegisteredConduitException: SelectorException
{
    /**
     * Construct a selector exception with the provided text string
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The conduit is already registered to the selector", file, line);
    }
}

/**
 * InterruptedSystemCallException is thrown when a system call is interrupted
 * by a signal and the selector was not set to restart it automatically.
 */
public class InterruptedSystemCallException: SelectorException
{
    /**
     * Construct a selector exception with the provided text string
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("A system call was interrupted by a signal", file, line);
    }
}

/**
 * OutOfMemoryException is thrown when there is not enough memory.
 */
public class OutOfMemoryException: SelectorException
{
    /**
     * Construct a selector exception with the provided text string
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("Out of memory", file, line);
    }
}

