/*******************************************************************************

        copyright:      Copyright (c) 2007 Tango. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        April 2007: Initial release      
        
        author:         h3r3tic, Kris

*******************************************************************************/

module tango.net.cluster.NetworkCall;

private import tango.core.Traits;
private import tango.core.Thread;

private import tango.net.cluster.NetworkMessage;

protected import tango.io.protocol.model.IReader,
                 tango.io.protocol.model.IWriter;

protected import tango.net.cluster.model.IChannel;


/*******************************************************************************

        task harness, for initiating the send

*******************************************************************************/

class NetworkCall : NetworkMessage
{
        /***********************************************************************

        ***********************************************************************/

        void send (IChannel channel = null)
        {
                if (channel)
                    channel.execute (this);
                else
                   {
                   auto x = cast(IChannel) Thread.getLocal(0);
                   if (x)
                       x.execute (this);
                   else
                      execute;
                   }
        }
}


/*******************************************************************************
        
        Template for RPC glue

*******************************************************************************/

class NetCall(alias realFunc) : NetworkCall 
{
        alias ParameterTupleOf!(realFunc) Params;
        alias ReturnTypeOf!(realFunc)     RetType;

        static if (!is(RetType == void)) {
                RetType result;
        }
        Params  params;


        override char[] toString() {
                return signatureOfFunc!(realFunc);
        }

        RetType opCall(Params params, IChannel channel = null) {
                foreach (i, _dummy; this.params) {
                        this.params[i] = params[i];
                }
                send (channel);
                
                static if (!is(RetType == void)) {
                        return result;
                }
        }

        override void execute() {
                static if (!is(RetType == void)) {
                        result = realFunc(params);
                } else {
                        realFunc(params);
                }
        }

        override void read(IReader input) {
                static if (!is(RetType == void)) {
                        input(result);
                }
                foreach (i, _dummy; params) input(params[i]);
        }

        override void write(IWriter output) {
                static if (!is(RetType == void)) {
                        output(result);
                }
                foreach (i, _dummy; params) output(params[i]);
        }
}


/*******************************************************************************
        
        Magic to get a clean function signature

*******************************************************************************/

private {
        struct Wrapper(alias fn) {}
        const char[] WrapperPrefix = `__T7Wrapper`;


        uint parseUint(char[] str) {
                int res = 0;
                foreach (c; str) {
                        res *= 10;
                        res += c - '0';
                }
                return res;
        }


        char[] sliceOffSegment(inout char[] str) {
                assert (str.length > 0 && str[0] >= '0' && str[0] <= '9');

                int lenEnd = 0;
                for (; str[lenEnd] >= '0' && str[lenEnd] <= '9'; ++lenEnd) {}

                char[] lenStr = str[0..lenEnd];
                uint segLen = parseUint(lenStr);
                str = str[lenEnd .. $];

                char[] res = str[0..segLen];
                str = str[segLen .. $];
                return res;
        }


        char[] digOutWrapper(char[] wrapped) {
                wrapped = wrapped[1..$];        // skip the 'S'
                char[] seg;

                do {
                        seg = sliceOffSegment(wrapped);
                } while (seg.length < WrapperPrefix.length || seg[0..WrapperPrefix.length] != WrapperPrefix);

                return seg[WrapperPrefix.length .. $];
        }


        char[] demangleDFunc(char[] mangled) {
                char[] res = sliceOffSegment(mangled);

                while (mangled.length > 0 && mangled[0] >= '0' && mangled[0] <= '9') {
                        res ~= '.' ~ sliceOffSegment(mangled);
                }
                return res;
        }


        char[] nameOf_impl(char[] wrapped) {
                char[] wrapper = digOutWrapper(wrapped)[1..$];  // skip the 'S'
                char[] mangled = sliceOffSegment(wrapper);

                if (mangled.length > 2 && mangled[0..2] == `_D`) {
                        // D func
                        return demangleDFunc(mangled[2..$]);
                } else {
                        return mangled;         // C func
                }
        }
        
        
        int match_param_(char[] str) {
                if (str.length < `_param_0`.length) return 0;
                
                int numDigits = 0;
                while (str[$-1-numDigits] >= '0' && str[$-1-numDigits] <= '9') {
                        ++numDigits;
                }
                
                if (0 == numDigits) return 0;
                
                if (str.length >= `_param_`.length + numDigits && str[$-`_param_`.length-numDigits .. $-numDigits] == `_param_`) {
                        return `_param_`.length + numDigits;
                } else {
                        return 0;
                }
        }
        

        // sometimes the param lists have ugly _param_[0-9]+ names in them...
        char[] tidyTupleStringof(char[] str) {
                char[] res;
                for (int i = 0; i < str.length; ++i) {
                        char c = str[i];
                        
                        if (c == ')' || c == ',') {
                                if (auto len = match_param_(str[0..i])) {
                                        // len is the length of the _param_[0-9]+ thing
                                        int start = i-1-len;
                                        str = str[0..start] ~ str[i..$];
                                        i -= len;
                                }
                        }
                }
                
                return str;
        }


        template nameOfFunc(alias fn) {
                static assert (is(typeof(fn) == function));
                const char[] nameOfFunc = nameOf_impl((Wrapper!(fn)).mangleof);
        }


        template signatureOfFunc(alias fn) {
                static assert (is(typeof(fn) == function));
                const char[] signatureOfFunc = ReturnTypeOf!(fn).stringof ~ ' ' ~ nameOfFunc!(fn) ~ tidyTupleStringof(ParameterTupleOf!(fn).stringof);
        }
}