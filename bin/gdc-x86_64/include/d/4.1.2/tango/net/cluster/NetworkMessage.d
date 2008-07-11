/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.NetworkMessage;

private import tango.core.Exception;

public  import tango.net.cluster.model.ICluster;        

/*******************************************************************************

        A cluster-based messaging class. You should override both read() and 
        write() methods to transport non-transient content along with the msg.

        Note that when using read() and write(), invoke the superclass first 
        so that your Message can potentially be deserialized as a superclass 
        instance. That is, read() and write() might look something like this:
        ---
        void read (IReader input)
        {       
                super.read (input);
                input (myAttribute) (myOtherAttribute);
        }

        void write (IWriter output)
        {
                super.write (output);
                output (myAttribute) (myOtherAttribute2);
        }
        ---

*******************************************************************************/

class NetworkMessage : IMessage
{
        private uint      id_;
        private long      time_; // converted to Time as necessary
        private char[]    reply_;

        /***********************************************************************

                Have to proxy this to satisfy interface requirements. It's 
                both annoying and fragile to be forced into this kind of 
                call-brokering, but then interfaces also don't expose the
                methods from Object either. Interfaces in D are still a
                bit too immature

        ***********************************************************************/
        
        char[] toString ()
        {
                return super.toString;
        }

        /***********************************************************************

                Set the optional reply-channel

        ***********************************************************************/
        
        void reply (char[] channel)
        {
                reply_ = channel;
        }

        /***********************************************************************

                Return the optional reply-channel

        ***********************************************************************/
        
        char[] reply ()
        {
                return reply_;
        }

        /***********************************************************************

                Set the waterline of the cache-entries that should not be 
                touched by an invalidation. This is typically the time of
                an entry in a local cache on the machine originating the 
                invalidation. Without the ability to guard against local 
                invalidation, the cache entry just added locally would be 
                removed along with others across the cluster. 
                
                An alternative would be to invalidate before adding, though 
                that can become complicated by network race conditions.

        ***********************************************************************/

        void time (Time time)
        {
                time_ = time.ticks;
        }

        /***********************************************************************

                Return our time value

        ***********************************************************************/

        Time time ()
        {
                return Time(time_);
        }

        /***********************************************************************

        ***********************************************************************/
        
        void id (uint value)
        {
                id_ = value;
        }

        /***********************************************************************

        ***********************************************************************/
        
        uint id ()
        {
                return id_;
        }

        /**********************************************************************
        
                Recover the reply-channel from the provided reader

        **********************************************************************/

        void read (IReader input)
        {       
                input (id_) (time_) (reply_);
        }

        /**********************************************************************

                Emit our reply-channel to the provided writer

        **********************************************************************/

        void write (IWriter output)
        {
                output (id_) (time_) (reply_);
        }

        /***********************************************************************

                Creates a shallow object copy. This is used internally 
                for setting up templates/hosts of registered objects and 
                should be overridden where deep(er) copying is desired. 
                Specifically: it makes a bit-copy only. Dynamic arrays or
                pointer/reference oriented attributes are not duplicated.

                In general, there should be zero heap activity ocurring
                during cluster requests. Thus, specific cluster services 
                utilize this method to construct message hosts, up-front, 
                helping to ensure the heap remains untouched during normal 
                operation.

        ***********************************************************************/

        IMessage clone () 
        {
                auto ci = this.classinfo;
                auto end = ci.init.length;
                auto start = Object.classinfo.init.length;

                auto clone = ci.create;
                if (! clone)
                      throw new ClusterException ("cannot clone msg with no default ctor: "~ci.name);

                (cast(void*)clone)[start .. end] = (cast(void*)this)[start .. end];
                return cast(IMessage) clone;
        }

        /**********************************************************************

                Interface issues mean that we'd have to reimplement all 
                the above methods again to support the ITask derivative. 
                Just hack this in here instead :[

        **********************************************************************/

        void execute ()
        {
        }
}
