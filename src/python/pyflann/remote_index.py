#Copyright 2008-2010  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
#Copyright 2008-2010  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
#
#THE BSD LICENSE
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions
#are met:
#
#1. Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#2. Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
#IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
#INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
#NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import rpyc

from pyflann import FLANN
from threading import Semaphore
import time



class ServerNamespace:

    def __init__(self,server):
        self.connection = rpyc.classic.connect(server)
        self.pyflann = self.connection.modules.pyflann

class RemoteIndex(FLANN):

    def __setup_servers(self,servers):
        self.__servers = {}
        for s in servers:
            self.__servers[s] = ServerNamespace(s)

    def __load_data(self,remote_dataset):
        filename, array_name, range = remote_dataset
        num_servers = len(self.__servers)
        k,m = (range[1]-range[0])/num_servers, (range[1]-range[0])%num_servers
        ranges = [(range[0]+i * k + min(i, m), range[0]+(i + 1) * k + min(i + 1, m)) for i in xrange(num_servers)]

        for i,namespace in enumerate(self.__servers.values()):
            namespace.dataset_ref = (filename,array_name,ranges[i])

        pending = num_servers
        for server,namespace in self.__servers.iteritems():
            def async_callback(async_result):
                namespace.data = async_result.value
                print 'Finished loading on ', server
                pending -= 1
            print 'Loading data on', server
            print namespace.pyflann.load_range
            load_range_async = rpyc.async(namespace.pyflann.load_range)
            async_ref = load_range_async(*namespace.dataset_ref)
            async_ref.add_callback(async_callback)

        while pending>0:
            print 'Waiting...'
            time.sleep(0.5)



            

    def __init__(self, servers, remote_dataset, **kwargs):
        self.__setup_servers(servers)
        self.__load_data(remote_dataset)
        FLANN.__init__(self,**kwargs)



def test():
    index = RemoteIndex(['cook','magellan'],('/ubc/cs/home/m/mariusm/local/tinyimages/tinygist80million.hdf5', 'dataset',(0,2000000)))

