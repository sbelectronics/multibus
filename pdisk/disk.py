from __future__ import print_function
import pigpio
import signal
import string
import sys
import time
from optparse import OptionParser
from terminal import Terminal

from diskface import DiskInterface, LOG_WARN

diskface = None

def hex_escape(s):
    printable = string.ascii_letters + string.digits + string.punctuation + ' '
    return ''.join(c if c in printable else r'\x{0:02x}'.format(ord(c)) for c in s)  

def sigint_handler(signum, frame):
    print("<interrupted>")
    # We have to make sure we call diskface.cleanup() so that it releases pigpio
    # and prevents that mbox zap error.
    # I don't know why we don't have to restore the terminal from cbreak mode...
    diskface.cleanup()
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    signal.raise_signal(signal.SIGINT)

def dumpmem(diskface, start, end):
    for i in range(start, end+1):
        if i % 16 == 0:
            if i != start:
                print(" ", end="")
                for j in range(i-16, i):
                    c = chr(diskface.readMem(j))
                    if c in string.printable and c not in string.whitespace:
                        print(c, end="")
                    else:
                        print(".", end="")
            print("")
            print("%04X: " % i, end="")
        print("%02X " % diskface.readMem(i), end="")
    remaining = (end + 1) % 16
    if remaining != 0:
        print("   " * (16 - remaining), end="")
    print(" ", end="")
    for j in range(end - remaining + 1, end + 1):
        c = chr(diskface.readMem(j))
        if c in string.printable and c not in string.whitespace:
            print(c, end="")
        else:
            print(".", end="")
    print("")

def main():
    global diskface

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

    diskface = DiskInterface(verbosity)
    try:
        if (cmd=="run"):
            signal.signal(signal.SIGINT, sigint_handler)   # pigpio will mess up our sigint handler
            t=Terminal()
            try:
                t.setRaw()
                if options.disk:
                    diskface.setDisk(0, options.disk)
                diskface.run(t, noKeyboard=options.nokeyboard, purge=options.purge)
            finally:
                t.restoreRaw()

        if (cmd=="reset"):
            diskface.reset()

        elif (cmd=="hreset"):
            diskface.hreset()

        elif (cmd=="status"):
            diskface.printStatus()

        elif (cmd=="watch"):
            diskface.watch()

        elif (cmd=="pitest"):
            diskface.pitest()

        elif (cmd=="peek"):
            if len(args)!=1:
                print("missing addr")
                sys.exit(-1)
            v = diskface.readMem(int(args[0], 16))
            print("%02X" % v)
            
        elif (cmd=="poke"):
            if len(args)!=2:
                print("missing addr and/or value")
                sys.exit(-1)
            diskface.writeMem(int(args[0], 16), int(args[1], 16))

        elif (cmd=="out"):
            if len(args)!=2:
                print("missing reg and/or value")
                sys.exit(-1)
            diskface.writeMBOX(int(args[0], 16), int(args[1], 16))       

        elif (cmd=="iset"):
            diskface.intSet()

        elif (cmd=="ireset"):
            diskface.intReset()

        elif (cmd=="dumpmem"):
            if len(args)!=2:
                print("missing start and/or end")
                sys.exit(-1)
            dumpmem(diskface, int(args[0], 16), int(args[1], 16))

        else:
            print("unknown command: %s" % cmd)
            sys.exit(-1)
    finally:
        diskface.cleanup()

if __name__=="__main__":
    main()
