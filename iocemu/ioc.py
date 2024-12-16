from __future__ import print_function
import string
import sys
import time
from optparse import OptionParser
from terminal import Terminal

from iocface import IOCInterface

def hex_escape(s):
    printable = string.ascii_letters + string.digits + string.punctuation + ' '
    return ''.join(c if c in printable else r'\x{0:02x}'.format(ord(c)) for c in s)  

def main():
    parser = OptionParser(usage="supervisor [options] command",
            description="Commands: ...")

    parser.add_option("-v", "--verbose", dest="verbose",
         help="verbose", action="store_true", default=False)
    
    parser.add_option("-p", "--purge", dest="purge",
         help="attempt to purge a KSTC that could be waiting", action="store_true", default=False)    

    (options, args) = parser.parse_args(sys.argv[1:])

    if len(args)==0:
        print("missing command")
        sys.exit(-1)

    cmd = args[0]
    args=args[1:]

    iocface = IOCInterface(options.verbose)
    try:
        if (cmd=="run"):
            t=Terminal()
            try:
                t.setRaw()
                iocface.run(t, purge=options.purge)
            finally:
                t.restoreRaw()

        if (cmd=="reset"):
            iocface.reset()

        elif (cmd=="status"):
            iocface.printStatus()

        elif (cmd=="watch"):
            iocface.watch()

        elif (cmd=="out"):
            if len(args)!=1:
                print("missing value")
                sys.exit(-1)
            iocface.writeDBOUT(int(args[0], 16))

        elif (cmd=="in"):
            iocface.printDBIN()

        elif (cmd=="setf0"):
            iocface.setF0(1)
        
        elif (cmd=="resetf0"):
            iocface.setF0(0)

        else:
            print("unknown command: %s" % cmd)
            sys.exit(-1)
    finally:
        iocface.cleanup()

if __name__=="__main__":
    main()
