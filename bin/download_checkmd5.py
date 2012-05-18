#!/usr/bin/env python2

import urllib, hashlib, sys, os
from optparse import OptionParser

class AppURLopener(urllib.FancyURLopener):
    version ="Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7"

    def prompt_user_passwd(self, host, realm):
        raise Exception()
urllib._urlopener = AppURLopener()

def file_md5(file):
    m = hashlib.md5()
    m.update(open(dest).read())
    return m.hexdigest()


def main():
    parser = OptionParser(usage="usage: %prog URI dest [md5sum]", prog=sys.argv[0])
    options, args = parser.parse_args()
    md5sum = None
    
    if len(args)==2:
        uri, dest = args
    elif len(args)==3:
        uri, dest, md5 = args
    else:
        parser.error("Wrong arguments")
    
    fresh = False
    if not os.path.exists(dest):
        print "Downloading from %s to %s..."%(uri, dest),
        sys.stdout.flush()
        urllib.urlretrieve(uri, dest)
        print "done"
        fresh = True
        
    if md5sum:
        print "Computing md5sum on downloaded file",
        sys.stdout.flush()
        checksum = md5_file(dest)
        print "done"
        
        if checksum!=md5sum:
            if not fresh:
                print "Checksum mismatch (%s != %s), re-downloading file %s"%(checksum, md5sum, dest),
                sys.stdout.flush()
                os.remove(dest)
                urllib.urlretrieve(uri, dest)
                print "done"
    
                print "Computing md5sum on downloaded file",
                sys.stdout.flush()
                checksum = md5_file(dest)
                print "done"
                
                if checksum!=md5sum:
                    print "ERROR, checksum mismatch (%s != %s) on %d",(checksum, md5sum, dest)
                    return 1
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as e:
        print "ERROR, ",e
        sys.exit(1)
