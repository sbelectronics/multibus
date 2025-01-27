from __future__ import print_function
import string
import select
import os
import sys
import time
import RPi.GPIO as IO
import diskdirect.diskdirect_ext

PIN_D0=16
PIN_D1=17
PIN_D2=18
PIN_D3=19
PIN_D4=20
PIN_D5=21
PIN_D6=22
PIN_D7=23

PIN_RESIN = 8
PIN_XACK = 9
PIN_WAIT = 10
PIN_HRESET = 11
PIN_STB = 13
PIN_IOR = 14
PIN_IOW = 15
PIN_XCY = 24
PIN_OVRD = 25
PIN_RSTB = 26
PIN_BCR1 = 27

PIN_A0 = 4
PIN_A1 = 5
PIN_A2 = 6
PIN_A3 = 7

DATAPINS = [PIN_D0, PIN_D1, PIN_D2, PIN_D3, PIN_D4, PIN_D5, PIN_D6, PIN_D7]

LOG_ERROR = 0
LOG_WARN = 1
LOG_INFO = 2
LOG_DEBUG = 3
LOG_CRAZYDEBUG = 4

REG_BUSR = 0
REG_BUSW = 1
REG_LATAL = 2
REG_LATAH = 3
REG_READ_PENDING = 4
REG_RESET_PENDING = 5
REG_READ_RESREQ = 6
REG_RESET_RESREQ = 7
REG_MR0 = 8
REG_MR1 = 9
REG_MR2 = 0xA
REG_MR3 = 0xB
REG_MW0 = 0xC
REG_MW1 = 0xD
REG_MW2 = 0xE
REG_MW3 = 0xF

MBOX_STATUS = 0
MBOX_RESULT_TYPE = 1
MBOX_RESULT_BYTE = 3

MBOX_ADDR_LOWER = 1
MBOX_ADDR_UPPER = 2

STAT_READY0 = 1
STAT_READY1 = 2
STAT_INT = 4
STAT_PRES = 8
STAT_DD = 0x10
STAT_READY2 = 0x20
STAT_READY3 = 0x40

class ResetException(Exception):
    def __init__(self, message='Reset'):
        super(ResetException, self).__init__(message)

class MultibusResetException(Exception):
    def __init__(self, message='Reset'):
        super(MultibusResetException, self).__init__(message)

class IOPB:
    def __init__(self, channel, diskInstr, numRec, trackAddr, secAddr, bufAddr):
        self.channel = channel
        self.diskInstr = diskInstr
        self.numRec = numRec
        self.trackAddr = trackAddr
        self.secAddr = secAddr
        self.bufAddr = bufAddr

    def print(self):
        print("IOPB:")
        print("  Channel   = %2X" % self.channel)
        print("  DiskInstr = %2X" % self.diskInstr)
        print("  NumRec    = %2X" % self.numRec)
        print("  TrackAddr = %2X" % self.trackAddr)
        print("  SecAddr   = %2X" % self.secAddr)
        print("  BufAddr   = %4X" % self.bufAddr)

class DiskInterface:
    def __init__(self, verbosity):
        self.verbosity = verbosity
        self.multibusReset = False
        self.enableDisk = False
        self.diskComplete = False
        self.verbosityOverride = None
        self.iopbByte = 0
        self.iters = 0
        self.iopb = None

        self.ext = diskdirect.diskdirect_ext
        if not self.ext.init():
            sys.exit(-1)

        IO.setmode(IO.BCM)
        IO.setwarnings(False) # turn off warnings about reusing the pins
        self.setDataInput()

        IO.setup(PIN_A0, IO.OUT)
        IO.setup(PIN_A1, IO.OUT)
        IO.setup(PIN_A2, IO.OUT)
        IO.setup(PIN_A3, IO.OUT)

        IO.setup(PIN_HRESET, IO.OUT)
        IO.setup(PIN_WAIT, IO.OUT)
        IO.setup(PIN_STB, IO.OUT)
        IO.setup(PIN_IOR, IO.OUT)
        IO.setup(PIN_IOW, IO.OUT)
        IO.setup(PIN_OVRD, IO.OUT)
        IO.setup(PIN_RSTB, IO.OUT)
        IO.setup(PIN_BCR1, IO.OUT)

        IO.output(PIN_A0, 0)
        IO.output(PIN_A0, 1)
        IO.output(PIN_A0, 2)
        IO.output(PIN_A0, 3)

        IO.output(PIN_HRESET, 0)
        IO.output(PIN_WAIT, 1)
        IO.output(PIN_STB, 1)
        IO.output(PIN_IOR, 1)
        IO.output(PIN_IOW, 1)
        IO.output(PIN_OVRD, 0)
        IO.output(PIN_RSTB, 1)
        IO.output(PIN_BCR1, 0)

        IO.setup(PIN_RESIN, IO.IN)
        IO.add_event_detect(PIN_RESIN, IO.RISING, callback=self.handleMultibusReset, bouncetime=200)

    def cleanup(self):
        # make sure pigpio is cleaned up
        self.ext.cleanup()

    def setDataInput(self):
        for datapin in DATAPINS:
            IO.setup(datapin, IO.IN)

    def setDataOutput(self):
        for datapin in DATAPINS:
            IO.setup(datapin, IO.OUT)

    def handleMultibusReset(self, channel):
        self.multibusReset = True

    def checkMultibusReset(self):
        if self.multibusReset:
            self.multibusReset = False
            raise MultibusResetException()

    def hreset(self):
        IO.output(PIN_HRESET,1)
        IO.output(PIN_HRESET,0)

    def printFlags(self):
        flags = self.readFlags()
        print("  OBF=%d IBF=%d F0=%d CD=%d" % ((flags&FLAG_OBF)!=0, (flags&FLAG_IBF)!=0, (flags&FLAG_F0)!=0, (flags&FLAG_CD)!=0))

    def printMBOX(self):
        for i in range(0, 4):
            dbin = self.readMBOX(i)
            print("  MBOX(%d)=%2X" % (i,dbin))
    
    def printStatus(self):
        self.printMBOX()
        print("  Pending=%d" % self.readPending())
        #print("  ResReq=%d" % self.readResReq())
        
    def log(self, level, msg):
        verbosity = self.verbosity
        if self.verbosityOverride is not None:
            verbosity = self.verbosityOverride
        if level <= verbosity:
            print(msg, file=sys.stderr)

    def error(self, msg):
        self.log(LOG_ERROR, msg)

    def yieldCPU(self):
        self.iters += 1
        if (self.iters % 1000)==0:
            self.keyReady()  # in case system is hung, occasionally check for control keys        

    def clkDelay(self):
        self.ext.clk_delay()

    #def readInput(self):
    #    d = 0
    #    for pin in reversed(DATAPINS):
    #        d = d << 1
    #        if IO.input(pin)==1:
    #            d = d | 1
    #    return ~d & 0xFF
    
    #def writeOutput(self, d):
    #    d = (~d & 0xFF)
    #    for pin in DATAPINS:
    #        IO.output(pin, (d & 1))
    #        d = d >> 1
    
    def readMBOX(self, i):
        return self.ext.read_mbox(i)
        #self.select(REG_DBIN)
        #result = self.readInput()
        #self.select(REG_NONE)
        #return result
    
    def writeMBOX(self, i, d):
        self.ext.write_mbox(i,d)
        #self.select(REG_NONE)
        #self.setA0(0)
        #self.setDataOutput()
        #self.writeOutput(d)
        #self.select(REG_DBOUT)
        #self.select(REG_NONE)
        #self.setDataInput()

    def readPending(self):
        return self.ext.read_pending()
    
    def resetPending(self):
        self.ext.reset_pending()

    def readMem(self, addr):
        return self.ext.read_mem(addr)
    
    def writeMem(self, addr, value):
        self.ext.write_mem(addr, value)
    
    def setAddr(self, value):
        IO.output(PIN_A0, (value & 1) != 0)
        IO.output(PIN_A1, (value & 2) != 0)
        IO.output(PIN_A2, (value & 4) != 0)
        IO.output(PIN_A3, (value & 8) != 0)

    def watch(self):
        lastFlags = None
        while True:
            self.checkMultibusReset()
            flags = self.readFlags() & 0x0F
            if (flags != lastFlags):
                self.printFlags()
                if (flags & FLAG_IBF)!=0:
                    self.printDBIN()
                lastFlags = flags
            else:
                self.yieldCPU()
    
    def diskList(self):
        diskdict = {}
        ch ='A'
        lines = open("disk.lst","r").readlines()
        for line in lines:
            if line.startswith("#"):
                continue
            line = line.strip()
            diskName = os.path.split(line)[1]
            print("%c: %s" % (ch, diskName))
            diskdict[ch] = line
            ch = chr(ord(ch)+1)
        while not self.keyReady():
            self.yieldCPU()
        v = chr(self.keyGet()).upper()
        if v in diskdict:
            self.disk = diskdict[v]
            print("disk selected: %s" % self.disk)
        else:
            print("invalid disk selection")

    def keyReady(self):
        if self.terminal.keyReady():
            v=ord(self.terminal.keyGet())
            if v==(ord('D')-ord('A')+1):
                self.diskList()
                return False
            elif v==(ord('Y')-ord('A')+1):
                print("<hreset>")
                # When <hreset> is triggered, it should automatically detect the multibus reset and trigger a
                # MultibusResetException. This will break us out of any loops, and cause a full reset of the IOC.
                self.hreset()
                return False
            
                #self.reset()
                #raise ResetException()
            elif v==(ord('T')-ord('A')+1): # verbose ("talky")
                self.verbosity += 1
                return False
            elif v==(ord('U')-ord('A')+1): # quiet ("un-talky")
                self.verbosity -= 1
                return False
            if v==0x0A:  # translate newline to CR
                v=0x0D
            elif v==(ord('X')-ord('A')+1):  # translate CTRL-X to CTRL-Z
                v=(ord('Z')-ord('A')+1)
            # self.keyWait.append(v)
            return True
            
        return False
    
    def updateStatus(self):
        v = STAT_PRES | STAT_DD;
        v = v | STAT_READY0

        self.writeMBOX(MBOX_STATUS, v)

    def resetStatus(self):
        self.updateStatus()

    def readIOPB(self, addr):
        iopbChannel = self.readMem(addr)
        iopbDiskInstr = self.readMem(addr+1)
        iopbNumRec = self.readMem(addr+2)
        iopbTrackAddr = self.readMem(addr+3)
        iopbSecAddr = self.readMem(addr+4)
        iopbBufAddr = self.readMem(addr+5) | (self.readMem(addr+6)<<8)

        iopt = IOPB(iopbChannel, iopbDiskInstr, iopbNumRec, iopbTrackAddr, iopbSecAddr, iopbBufAddr)

    def handleCommand(self):
        self.resetPending()
        addr = self.readMBOX(MBOX_ADDR_LOWER) | (self.readMBOX(MBOX_ADDR_UPPER)<<8)

        self.log(LOG_INFO, "Command: iopb at %X" % addr)

        self.iopb = self.readIOPB(addr)
        if self.verbosity >= LOG_INFO:
            self.iopb.print()
    
    def pitest(self):
        print("write to 0x78-0x7B: 33, 44, 55, 66")

        for i in range(0,1000):
            v1=self.readMBOX(0)
            v2=self.readMBOX(1)
            v3=self.readMBOX(2)
            v4=self.readMBOX(3)
            if (v1!=0x33):
                print("error pass %d mbox %d should %2X was %2X" % (i, 0, 0x33, v1))
            if (v2!=0x44):
                print("error pass %d mbox %d should %2X was %2X" % (i, 1, 0x44, v2))
            if (v3!=0x55):
                print("error pass %d mbox %d should %2X was %2X" % (i, 2, 0x55, v3))
            if (v4!=0x66):
                print("error pass %d mbox %d should %2X was %2X" % (i, 3, 0x66, v4))
    
    def run(self, terminal, noKeyboard=False, disk=None, purge=False):
        print("<CTRL-D>: DISK  <CTRL-T> Verbose  <CTRL-U> Quiet  <CTRL-Y>: RESET")
        print("<CTRL-X>: EOF")
        print("<disk started>")
        print("")
        self.terminal = terminal
        self.disk = disk
        while True:
            try:
                self.resetStatus()
                self.writeMBOX(MBOX_RESULT_BYTE, 0)
                self.writeMBOX(MBOX_RESULT_TYPE, 0)
                while True:
                    self.checkMultibusReset()
                    if self.readPending():
                        self.handleCommand()
                    # do stuff here
                    self.yieldCPU()
            except ResetException:
                pass
            except MultibusResetException:
                print("<multibus reset>")
                pass

