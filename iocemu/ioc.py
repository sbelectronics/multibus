from __future__ import print_function
import pigpio
import signal
import string
import sys
import time
from optparse import OptionParser
from terminal import Terminal

from iocface import IOCInterface, LOG_WARN

iocface = None

def hex_escape(s):
    printable = string.ascii_letters + string.digits + string.punctuation + ' '
    return ''.join(c if c in printable else r'\x{0:02x}'.format(ord(c)) for c in s)  

def sigint_handler(signum, frame):
    print("<interrupted>")
    # We have to make sure we call iocface.cleanup() so that it releases pigpio
    # and prevents that mbox zap error.
    # I don't know why we don't have to restore the terminal from cbreak mode...
    iocface.cleanup()
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    signal.raise_signal(signal.SIGINT)

def main():
    global iocface

    parser = OptionParser(usage="supervisor [options] command",
            description="Commands: ...")

    parser.add_option("-v", "--verbose", dest="verbose",
         help="verbose", action="count", default=0)
    
    parser.add_option("-q", "--quiet", dest="quiet",
         help="quiet", action="count", default=0)
    
    parser.add_option("-p", "--purge", dest="purge",
         help="attempt to purge a KSTC that could be waiting", action="store_true", default=False)
    
    parser.add_option("-d", "--disk", dest="disk",
         help="set disk filename", action="store", default=None)
    
    parser.add_option("-n", "--nokeyboard", dest="nokeyboard",
         help="disable console", action="store_true", default=None)

    (options, args) = parser.parse_args(sys.argv[1:])

    if len(args)==0:
        print("missing command")
        sys.exit(-1)

    verbosity = LOG_WARN + options.verbose - options.quiet

    cmd = args[0]
    args=args[1:]

    iocface = IOCInterface(verbosity)
    try:
        if (cmd=="run"):
            signal.signal(signal.SIGINT, sigint_handler)   # pigpio will mess up our sigint handler
            t=Terminal()
            try:
                t.setRaw()
                iocface.run(t, noKeyboard=options.nokeyboard, disk=options.disk, purge=options.purge)
            finally:
                t.restoreRaw()

        if (cmd=="reset"):
            iocface.reset()

        elif (cmd=="hreset"):
            iocface.hreset()

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

        elif (cmd=="resetobf"):
            iocface.resetOBF()            

        else:
            print("unknown command: %s" % cmd)
            sys.exit(-1)
    finally:
        iocface.cleanup()

if __name__=="__main__":
    main()
