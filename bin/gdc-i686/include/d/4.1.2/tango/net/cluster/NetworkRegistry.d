/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Apr 2004: Initial release
                        Dec 2006: Outback version
                        Apr 2007: Delegate revision

        author:         Kris

*******************************************************************************/

module tango.net.cluster.NetworkRegistry;

private import  tango.core.Exception;

private import  tango.net.cluster.model.IMessage;


/*******************************************************************************

        Bare framework for registering and creating serializable objects.
        Such objects are intended to be transported across a local network
        and re-instantiated at some destination node.

        Each IMessage exposes the means to write, or freeze, its content. An
        IPickleFactory provides the means to create a new instance of itself
        populated with thawed data. Frozen objects are uniquely identified
        by a guid exposed via the interface. Responsibility of maintaining
        uniqueness across said identifiers lies in the hands of the developer.

*******************************************************************************/

class NetworkRegistry
{
        private IMessage[char[]] registry;

        public static NetworkRegistry shared;

        /***********************************************************************

                
        ***********************************************************************/

        static this () 
        {
                shared = new NetworkRegistry;
        }

        /***********************************************************************

                
        ***********************************************************************/

        this (typeof(registry) registry = null) 
        {
                this.registry = registry;
        }

        /***********************************************************************

                Synchronized Factory lookup of the guid

        ***********************************************************************/

        final synchronized IMessage lookup (char[] guid)
        {
                auto p = guid in registry;
                if (p is null)
                     error ("Registry.thaw :: attempt to reify via unregistered guid: ", guid);

                return *p;
        }

        /***********************************************************************

                Add the provided Factory to the registry. Note that one
                cannot change a registration once it is placed. Neither
                can one remove registered item. This is done to avoid
                issues when trying to synchronize servers across
                a farm, which may still have live instances of "old"
                objects waiting to be passed around the cluster. New
                versions of an object should be given a distinct guid
                from the prior version; appending an incremental number
                may well be sufficient for your needs.

        ***********************************************************************/

        final synchronized void enroll (IMessage target)
        {
                auto guid = target.toString;

                if (guid in registry)
                    error ("Registry.enroll :: attempt to re-register guid: ", guid);

                registry[guid] = target;
        }

        /***********************************************************************

                Serialize an Object. Objects are written in Network-order,
                and are prefixed by the guid exposed via the IMessage
                interface. This guid is used to identify the appropriate
                factory when reconstructing the instance.

        ***********************************************************************/

        final void freeze (IWriter output, IMessage target)
        {
                output (target.toString);
                target.write (output);
        }

        /***********************************************************************

                Create a new instance of a registered class from the content
                made available via the given reader. The factory is located
                using the provided guid, which must match an enrolled factory.

                Note that only the factory lookup is synchronized, and not
                the instance construction itself. This is intentional, and
                limits how long the calling thread is stalled

        ***********************************************************************/

        final IMessage thaw (IReader input, IMessage host = null)
        {
                char[] guid;

                input (guid);

                if (host is null)
                    host = lookup (guid);
                else
                   if (guid != host.toString)
                       error ("Registry.thaw :: attempt to reify into a mismatched host: ", guid);

                host.read (input);
                return host;
        }

        /***********************************************************************

                Duplicate the registry

        ***********************************************************************/

        final NetworkRegistry dup () 
        { 
                typeof(registry) u; 
                
                foreach (k, v; registry) 
                         u[k] = v.clone; 
                return new NetworkRegistry (u);
        }

        /***********************************************************************

        ***********************************************************************/

        private static void error (char[] msg, char[] guid)
        {
                throw new RegistryException (msg ~ guid);
        }
}



