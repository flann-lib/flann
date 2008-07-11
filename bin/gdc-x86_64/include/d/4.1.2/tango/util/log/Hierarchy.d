/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Oct 2004: Initial release
        version:        Feb 2007: Switched to lazy expr
        
        author:         Kris

*******************************************************************************/

module tango.util.log.Hierarchy;

private import  tango.time.Clock;

private import  tango.core.Exception;

private import  tango.util.log.Logger,
                tango.util.log.Appender;

private import  tango.text.convert.Layout;

private import  tango.util.log.model.IHierarchy;

/*******************************************************************************

        Pull in additional functions from the C library

*******************************************************************************/

extern (C)
{
        int memcmp (void *, void *, int);
}

/*******************************************************************************

        Hack to sidestep linux linker errors (big thanks to Keinfarbton)

*******************************************************************************/

private Layout!(char) format;

static this()
{
        .format = new Layout!(char);
}

/*******************************************************************************

        Loggers are named entities, sometimes shared, sometimes specific to 
        a particular portion of code. The names are generally hierarchical in 
        nature, using dot notation (with '.') to separate each named section. 
        For example, a typical name might be something like "mail.send.writer"
        ---
        import tango.util.log.Log;
        
        auto log = Log.getLogger ("mail.send.writer");

        log.info  ("an informational message");
        log.error ("an exception message: " ~ exception.toString);

        etc ...
        ---
        
        It is considered good form to pass a logger instance as a function or 
        class-ctor argument, or to assign a new logger instance during static 
        class construction. For example: if it were considered appropriate to 
        have one logger instance per class, each might be constructed like so:
        ---
        private Logger log;
        
        static this()
        {
            log = Log.getLogger (nameOfThisClassOrStructOrModule);
        }
        ---

        Messages passed to a Logger are assumed to be pre-formatted. You 
        may find that the format() methos is handy for collating various 
        components of the message: 
        ---
        char tmp[128] = void;
        ...
        log.warn (log.format (tmp, "temperature is {} degrees!", 101));
        ---

        Note that a provided workspace is used to format the message, which 
        should generally be located on the stack so as to support multiple
        threads of execution. In the example above we indicate assignment as 
        "tmp = void", although this is an optional attribute (see the language 
        manual for more information).

        To avoid overhead when constructing formatted messages, the logging
        system employs lazy expressions such that the message is not constructed
        unless the logger is actually active. You can also explicitly check to
        see whether a logger is active or not:
        ---
        if (log.isEnabled (log.Level.Warn))
            log.warn (log.format (tmp, "temperature is {} degrees!", 101));
        ---

        You might optionally configure various layout & appender implementations
        to support specific rendering needs.
        
        tango.log closely follows both the API and the behaviour as documented 
        at the official Log4J site, where you'll find a good tutorial. Those 
        pages are hosted over 
        <A HREF="http://logging.apache.org/log4j/docs/documentation.html">here</A>.

*******************************************************************************/

private class LoggerInstance : Logger
{
        private LoggerInstance  next,
                                parent;

        private char[]          name_;
        private Level           level_;
        private Appender        appender;
        private Hierarchy       hierarchy;
        private bool            additive,
                                breakpoint;


        /***********************************************************************
        
                Construct a LoggerInstance with the specified name for the 
                given hierarchy. By default, logger instances are additive
                and are set to emit all events.

        ***********************************************************************/

        protected this (Hierarchy hierarchy, char[] name)
        {
                this.hierarchy = hierarchy;
                this.level_ = Level.Trace;
                this.additive = true;
                this.name_ = name;
        }

        /***********************************************************************
        
                No, you should not delete or 'scope' these entites

        ***********************************************************************/

        private ~this()
        {
        }

        /***********************************************************************
        
                Is this logger enabed for the specified Level?

        ***********************************************************************/

        final bool isEnabled (Level level = Level.Fatal)
        {
                return hierarchy.context.isEnabled (level_, level);
        }

        /***********************************************************************
        
                Is this a breakpoint Logger?
                
        ***********************************************************************/

        final bool isBreakpoint ()
        {
                return breakpoint;
        }

        /***********************************************************************
        
                Is this logger additive? That is, should we walk ancestors
                looking for more appenders?

        ***********************************************************************/

        final bool isAdditive ()
        {
                return additive;
        }

        /***********************************************************************

                Append a trace message

        ***********************************************************************/

        final Logger trace (lazy char[] msg)
        {
                return append (Level.Trace, msg);
        }

        /***********************************************************************

                Append an info message

        ***********************************************************************/

        final Logger info (lazy char[] msg)
        {
                return append (Level.Info, msg);
        }

        /***********************************************************************

                Append a warning message

        ***********************************************************************/

        final Logger warn (lazy char[] msg)
        {
                return append (Level.Warn, msg);
        }

        /***********************************************************************

                Append an error message

        ***********************************************************************/

        final Logger error (lazy char[] msg)
        {
                return append (Level.Error, msg);
        }

        /***********************************************************************

                Append a fatal message

        ***********************************************************************/

        final Logger fatal (lazy char[] msg)
        {
                return append (Level.Fatal, msg);
        }

        /***********************************************************************

                Return the name of this Logger (sans the appended dot).
       
        ***********************************************************************/

        final char[] name ()
        {
                int i = name_.length;
                if (i > 0)
                    --i;
                return name_[0 .. i];     
        }

        /***********************************************************************
        
                Return the Level this logger is set to

        ***********************************************************************/

        final Level level ()
        {
                return level_;     
        }

        /***********************************************************************
        
                Set the current level for this logger (and only this logger).

        ***********************************************************************/

        final Logger setLevel (Level level = Level.Trace)
        {
                return setLevel (level, false);
        }

        /***********************************************************************
        
                Set the current level for this logger, and (optionally) all
                of its descendents.

        ***********************************************************************/

        final Logger setLevel (Level level, bool propagate)
        {
                this.level_ = level;     
                hierarchy.updateLoggers (this, propagate);
                return this;
        }

        /***********************************************************************
        
                Set the breakpoint status of this logger.

        ***********************************************************************/

        final Logger setBreakpoint (bool enabled)
        {
                breakpoint = enabled;     
                hierarchy.updateLoggers (this, false);
                return this;
        }

        /***********************************************************************
        
                Set the additive status of this logger. See isAdditive().

        ***********************************************************************/

        final Logger setAdditive (bool enabled)
        {
                additive = enabled;     
                return this;
        }

        /***********************************************************************
        
                Add (another) appender to this logger. Appenders are each
                invoked for log events as they are produced. At most, one
                instance of each appender will be invoked.

        ***********************************************************************/

        final Logger addAppender (Appender next)
        {
                if (appender)
                    next.setNext (appender);
                appender = next;
                return this;
        }

        /***********************************************************************
        
                Remove all appenders from this Logger

        ***********************************************************************/

        final Logger clearAppenders ()
        {
                appender = null;     
                return this;
        }


        /***********************************************************************
        
                Get time since this application started

        ***********************************************************************/

        final TimeSpan runtime ()
        {
                return Clock.now - Event.startedAt;
        }

        /***********************************************************************
        
                Append a message to this logger via its appender list.

        ***********************************************************************/

        final Logger append (Level level, lazy char[] exp)
        {
                if (hierarchy.context.isEnabled (level_, level))
                   {
                   auto event = Event.allocate;
                   scope (exit)
                          Event.deallocate (event);

                   // set the event attributes
                   event.set (hierarchy, level, exp, name.length ? name_[0..$-1] : "root");

                   // combine appenders from all ancestors
                   auto links = this;
                   Appender.Mask masks = 0;                 
                   do {
                      auto appender = links.appender;

                      // this level have an appender?
                      while (appender)
                            { 
                            auto mask = appender.getMask;

                            // have we used this appender already?
                            if ((masks & mask) is 0)
                               {
                               // no - append message and update mask
                               event.scratch.length = 0;
                               appender.append (event);
                               masks |= mask;
                               }
                            // process all appenders for this node
                            appender = appender.getNext;
                            }
                        // process all ancestors
                      } while (links.additive && ((links = links.parent) !is null));
                   }
                return this;
        }

        /***********************************************************************

                Format text using the formatter configured in the associated
                hierarchy (see Hierarchy.setFormat)

        ***********************************************************************/

        final char[] format (char[] buffer, char[] formatStr, ...)
        {
                return .format.vprint (buffer, formatStr, _arguments, _argptr);     
        }

        /***********************************************************************
        
                See if the provided Logger is a good match as a parent of
                this one. Note that each Logger name has a '.' appended to
                the end, such that name segments will not partially match.

        ***********************************************************************/

        private final bool isCloserAncestor (LoggerInstance other)
        {
                auto length = other.name_.length;

                // possible parent if length is shorter
                if (length < name_.length)
                    // does the prefix match? Note we append a "." to each 
                    if (length is 0 || 
                        memcmp (&other.name_[0], &name_[0], length) is 0)
                        // is this a better (longer) match than prior parent?
                        if ((parent is null) || (length >= parent.name_.length))
                             return true;
                return false;
        }
}


/*******************************************************************************
 
        The Logger hierarchy implementation. We keep a reference to each
        logger in a hash-table for convenient lookup purposes, plus keep
        each logger linked to the others in an ordered chain. Ordering
        places shortest names at the head and longest ones at the tail, 
        making the job of identifying ancestors easier in an orderly
        fashion. For example, when propagating levels across descendents
        it would be a mistake to propagate to a child before all of its
        ancestors were taken care of.

*******************************************************************************/

class Hierarchy : IHierarchy, IHierarchy.Context
{
        private char[]                  name,
                                        address;      
        private LoggerInstance          root;
        private LoggerInstance[char[]]  loggers;
        private Context                 context_;

        /***********************************************************************
        
                Construct a hierarchy with the given name.

        ***********************************************************************/

        this (char[] name)
        {
                this.name = name;
                this.address = "network";

                // insert a root node; the root has an empty name
                root = new LoggerInstance (this, "");
                context = this;
        }

        /**********************************************************************

        **********************************************************************/

        final char[] label ()
        {
                return "";
        }
                
        /**********************************************************************


        **********************************************************************/

        final bool isEnabled (ILevel.Level level, ILevel.Level test)
        {
                return test >= level;
        }

        /**********************************************************************

                Return the name of this Hierarchy

        **********************************************************************/

        final char[] getName ()
        {
                return name;
        }

        /**********************************************************************

                Return the address of this Hierarchy. This is typically
                attached when sending events to remote monitors.

        **********************************************************************/

        final char[] getAddress ()
        {
                return address;
        }

        /**********************************************************************

                Set the name of this Hierarchy

        **********************************************************************/

        final void setName (char[] name)
        {
                this.name = name;
        }

        /**********************************************************************

                Set the address of this Hierarchy. The address is attached
                used when sending events to remote monitors.

        **********************************************************************/

        final void setAddress (char[] address)
        {
                this.address = address;
        }

        /**********************************************************************

                Set the diagnostic context.  Not usually necessary, as a 
                default was created.  Useful when you need to provide a 
                different implementation, such as a ThreadLocal variant.

        **********************************************************************/
        
        final void context (Context context)
        {
        	this.context_ = context;
        }
        
        /**********************************************************************

                Return the diagnostic context.  Useful for setting an 
                override logging level.

        **********************************************************************/
        
        final Context context ()
        {
        	return context_;
        }
        
        /***********************************************************************
        
                Return the root node.

        ***********************************************************************/

        final LoggerInstance getRootLogger ()
        {
                return root;
        }

        /***********************************************************************
        
                Return the instance of a Logger with the provided label. If
                the instance does not exist, it is created at this time.

        ***********************************************************************/

        final synchronized LoggerInstance getLogger (char[] label)
        {
                auto name = label ~ ".";
                auto l = name in loggers;

                if (l is null)
                   {
                   // create a new logger
                   auto li = new LoggerInstance (this, name);
                   l = &li;

                   // insert into linked list
                   insertLogger (li);

                   // look for and adjust children
                   updateLoggers (li, true);

                   // insert into map
                   loggers [name] = li;
                   }
               
                return *l;
        }

        /**********************************************************************

                Iterate over all Loggers in list

        **********************************************************************/

        final int opApply (int delegate(inout Logger) dg)
        {
                int result = 0;
                LoggerInstance curr = root;

                while (curr)
                      {
                      // BUG: this uncovers a cast() issue in the 'inout' delegation
                      Logger logger = curr;
                      if ((result = dg (logger)) != 0)
                           break;
                      curr = curr.next;
                      }
                return result;
        }

        /***********************************************************************
        
                Loggers are maintained in a sorted linked-list. The order 
                is maintained such that the shortest name is at the root, 
                and the longest at the tail.

                This is done so that updateLoggers() will always have a
                known environment to manipulate, making it much faster.

        ***********************************************************************/

        private void insertLogger (LoggerInstance l)
        {
                LoggerInstance prev,
                               curr = root;

                while (curr)
                      {
                      // insert here if the new name is shorter
                      if (l.name.length < curr.name.length)
                          if (prev is null)
                              throw new IllegalElementException ("invalid hierarchy");
                          else                                 
                             {
                             l.next = prev.next;
                             prev.next = l;
                             return;
                             }
                      else
                         // find best match for parent of new entry
                         propagate (l, curr, true);

                      // remember where insertion point should be
                      prev = curr;  
                      curr = curr.next;  
                      }

                // add to tail
                prev.next = l;
        }

        /***********************************************************************
        
                Propagate hierarchical changes across known loggers. 
                This includes changes in the hierarchy itself, and to
                the various settings of child loggers with respect to 
                their parent(s).              

        ***********************************************************************/

        private void updateLoggers (LoggerInstance changed, bool force)
        {
                LoggerInstance logger = root;

                // scan all loggers 
                while (logger)
                      {
                      propagate (logger, changed, force);

                      // try next entry
                      logger = logger.next;
                      }                
        }

        /***********************************************************************
        
                Propagate changes in the hierarchy downward to child Loggers.
                Note that while 'parent' and 'breakpoint' are always forced
                to update, the update of 'level' is selectable.

        ***********************************************************************/

        private void propagate (LoggerInstance logger, LoggerInstance changed, bool force)
        {
                // is the changed instance a better match for our parent?
                if (logger.isCloserAncestor (changed))
                   {
                   // update parent (might actually be current parent)
                   logger.parent = changed;

                   // if we don't have an explicit level set, inherit it
                   if ((logger.level is Logger.Level.None) || force)
                        logger.setLevel (changed.level);

                   // always force breakpoints to follow parent settings
                   logger.breakpoint = changed.breakpoint;
                   }
        }
}


