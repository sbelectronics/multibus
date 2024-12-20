from __future__ import print_function
import string
import select
import sys
import time
import RPi.GPIO as IO
import iocdirect.iocdirect_ext

PIN_D0=16
PIN_D1=17
PIN_D2=18
PIN_D3=19
PIN_D4=20
PIN_D5=21
PIN_D6=22
PIN_D7=23
PIN_INIT=27
PIN_SELDBOUT=24
PIN_SELDBIN=25
PIN_SELSTAT=26
PIN_INT=4
PIN_A0 =5
PIN_CLKF0=6
PIN_SETF1=12
PIN_RESETF1=13

PIN_HRESET=7

FLAG_OBF=1
FLAG_IBF=2
FLAG_F0=4
FLAG_CD=8

REG_NONE=0
REG_DBOUT=1
REG_DBIN=2
REG_STAT=3

DATAPINS = [PIN_D0, PIN_D1, PIN_D2, PIN_D3, PIN_D4, PIN_D5, PIN_D6, PIN_D7]

CMD_PACIFY = 0x00
CMD_ERESET = 0x01
CMD_SYSTAT = 0x02
CMD_DSTAT =  0x03
CMD_SRQDAK = 0x04
CMD_SRQACK = 0x05
CMD_SRQ =    0x06
CMD_DECHO =  0x07
CMD_CSMEM =  0x08
CMD_TRAM =   0x09
CMD_SINT =   0x0A
CMD_CRTC =   0x10
CMD_CRTS =   0x11
CMD_KEYC =   0x12
CMD_KSTC =   0x13
CMD_WPBC =   0x15
CMD_WPBCC =  0x16
CMD_WDBC =   0x17
CMD_RDBC =   0x19
CMD_RRSTS =  0x1B
CMD_RDSTS =  0x1C

CMDTABLE = {
    CMD_PACIFY: "PACIFY",
    CMD_ERESET: "ERESET",
    CMD_SYSTAT: "SYSTAT",
    CMD_DSTAT:  "DSTAT",
    CMD_SRQDAK: "SRQDAK",
    CMD_SRQACK: "SRQACK",
    CMD_SRQ:    "SRQ",
    CMD_DECHO:  "DECHO",
    CMD_CSMEM:  "CSMEM",
    CMD_TRAM:   "TRAM",
    CMD_SINT:   "SINT",
    CMD_CRTC:   "CRTC",
    CMD_CRTS:   "CRTS",
    CMD_KEYC:   "KEYC",
    CMD_KSTC:   "KSTC",
    CMD_WPBC:   "WPBC",
    CMD_WPBCC:  "WPBCC",
    CMD_WDBC:   "WDBC",
    CMD_RDBC:   "RDBC",
    CMD_RRSTS:  "RRSTS",
    CMD_RDSTS:  "RDSTS"
}

CRT_PRESENT = 0x01

KBD_READY =   0x01
KBD_PRESENT = 0x02
KBD_ILLEGAL = 0x40
KBD_TIMEOUT = 0x80

DISK_READY =    0x03  # manual says 0x02 but code looks for 0x01
DISK_COMPLETE = 0x04
DISK_PRESENT =  0x08
DISK_ILLEGAL_DATA = 0x20
DISK_ILLEGAL_STATUS = 0x40

DISK_NOP    = 0
DISK_SEEK   = 1
DISK_FORMAT = 2
DISK_RECAL  = 3
DISK_READ   = 4
DISK_VERIFY = 5
DISK_WRITE  = 6
DISK_WRITE_DEL = 7

LOG_ERROR = 0
LOG_WARN = 1
LOG_INFO = 2
LOG_DEBUG = 3
LOG_CRAZYDEBUG = 4

def isOBF(flags):
    return (flags&FLAG_OBF)!=0

def isIBF(flags):
    return (flags&FLAG_IBF)!=0

def isCMD(flags):
    return (flags&FLAG_CD)!=0


class ResetException(Exception):
    def __init__(self, message='Reset'):
        super(ResetException, self).__init__(message)

class IOCInterface:
    def __init__(self, verbosity):
        self.verbosity = verbosity
        self.keyTimeout = False
        self.enableDisk = False
        self.diskComplete = False
        self.noKeyboard = False
        self.noCRT = False
        self.verbosityOverride = None
        self.iopbByte = 0
        self.iters = 0
        self.keyWait = []

        self.ext = iocdirect.iocdirect_ext
        if not self.ext.init():
            sys.exit(-1)

        IO.setmode(IO.BCM)
        IO.setwarnings(False) # turn off warnings about reusing the pins
        self.setDataInput()

        IO.setup(PIN_INIT, IO.OUT)
        IO.setup(PIN_SELDBOUT, IO.OUT)
        IO.setup(PIN_SELDBIN, IO.OUT)
        IO.setup(PIN_SELSTAT, IO.OUT)
        IO.setup(PIN_INT, IO.OUT)
        IO.setup(PIN_A0, IO.OUT)
        IO.setup(PIN_CLKF0, IO.OUT)
        IO.setup(PIN_SETF1, IO.OUT)
        IO.setup(PIN_RESETF1, IO.OUT)
        IO.setup(PIN_HRESET, IO.OUT)

        IO.output(PIN_INIT, 1)
        IO.output(PIN_SELDBOUT, 1)
        IO.output(PIN_SELDBIN, 1)
        IO.output(PIN_SELSTAT, 1)
        IO.output(PIN_INT, 1)
        IO.output(PIN_A0, 1)
        IO.output(PIN_CLKF0, 1)
        IO.output(PIN_SETF1, 1)
        IO.output(PIN_RESETF1, 1)

        IO.output(PIN_HRESET, 1)

    def cleanup(self):
        # make sure pigpio is cleaned up
        self.ext.cleanup()

    def setDataInput(self):
        for datapin in DATAPINS:
            IO.setup(datapin, IO.IN)

    def setDataOutput(self):
        for datapin in DATAPINS:
            IO.setup(datapin, IO.OUT)

    def reset(self):
        IO.output(PIN_INIT,0)
        IO.output(PIN_INIT,1)

    def hreset(self):
        IO.output(PIN_HRESET,0)
        IO.output(PIN_HRESET,1)

    def printFlags(self):
        flags = self.readFlags()
        print("  OBF=%d IBF=%d F0=%d CD=%d" % ((flags&FLAG_OBF)!=0, (flags&FLAG_IBF)!=0, (flags&FLAG_F0)!=0, (flags&FLAG_CD)!=0))

    def printDBIN(self):
        dbin = self.readDBIN()
        print("  DBIN=%2X" % dbin)
    
    def printStatus(self):
        self.printFlags()
        self.printDBIN()
        
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

    def select(self, reg):
        if reg==REG_DBOUT:
            IO.output(PIN_SELDBIN, 1)
            IO.output(PIN_SELSTAT, 1)
            IO.output(PIN_SELDBOUT, 0)
        elif reg==REG_DBIN:
            IO.output(PIN_SELDBOUT, 1)
            IO.output(PIN_SELSTAT, 1)
            IO.output(PIN_SELDBIN, 0)
        elif reg==REG_STAT:
            IO.output(PIN_SELDBOUT, 1)
            IO.output(PIN_SELDBIN, 1)
            IO.output(PIN_SELSTAT, 0)
        elif reg==REG_NONE:
            IO.output(PIN_SELDBOUT, 1)
            IO.output(PIN_SELDBIN, 1)
            IO.output(PIN_SELSTAT, 1)
        else:
            raise Exception("invalid register")
        self.clkDelay()

    def readInput(self):
        d = 0
        for pin in reversed(DATAPINS):
            d = d << 1
            if IO.input(pin)==1:
                d = d | 1
        return ~d & 0xFF
    
    def writeOutput(self, d):
        d = (~d & 0xFF)
        for pin in DATAPINS:
            IO.output(pin, (d & 1))
            d = d >> 1
    
    def readFlags(self):
        return self.ext.read_flags()
        #self.select(REG_STAT)
        #lastResult = None
        #while True:
        #    # be wary of catching the flags in a transient state
        #    # maybe we get the IBF while the C/D is still settling...
        #    result = self.readInput()
        #    if result==lastResult:
        #        break
        #    lastResult = result
        #self.select(REG_NONE)
        #return result
    
    def readDBIN(self):
        return self.ext.read_dbin()
        #self.select(REG_DBIN)
        #result = self.readInput()
        #self.select(REG_NONE)
        #return result
    
    def writeDBOUT(self, d):
        self.ext.write_dbout(d)
        #self.select(REG_NONE)
        #self.setA0(0)
        #self.setDataOutput()
        #self.writeOutput(d)
        #self.select(REG_DBOUT)
        #self.select(REG_NONE)
        #self.setDataInput()
    
    def setA0(self, value):
        IO.output(PIN_A0, value)

    def resetOBF(self):
        self.setA0(1)           # writing to DBOUT with A0=1 clears the OBF
        self.select(REG_DBOUT)
        self.clkDelay()
        self.select(REG_NONE)
    
    def setF0(self, value):
        self.setA0(value)
        IO.output(PIN_CLKF0, 0)
        self.clkDelay()
        IO.output(PIN_CLKF0, 1)

    def getInputByte(self):
        while True:
            flags = self.readFlags()
            if isIBF(flags):
                if isCMD(flags):
                    cmd = self.readDBIN()
                    self.error("unexpected command byte: %2X" % cmd)
                else:
                    data = self.readDBIN()
                    self.log(LOG_DEBUG,"  got data byte: %2X" % data)
                    return data
            self.yieldCPU()

    def putOutputByte(self, value):
        while True:
            flags = self.readFlags()
            if not isOBF(flags):
                self.log(LOG_DEBUG,"  put data byte: %2X" % value)
                self.writeDBOUT(value)
                return
            self.yieldCPU()

    def setCommandResultAndResetF0(self, value):
        self.log(LOG_INFO,"  command complete with result %2X" % value)
        self.setF0(0)   # XXX should we do this before or after we put the output byte?
        self.putOutputByte(value)

    def nilCommandResultAndResetF0(self):
        self.log(LOG_INFO,"  command complete with no result")
        self.setF0(0)

    def watch(self):
        lastFlags = None
        while True:
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
            line = line.strip()
            print("%c: %s" % (ch, line))
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
            elif v==(ord('W')-ord('A')+1):
                print("<hreset>")
                self.hreset()
                self.reset()
                self.keyWait = []
                raise ResetException()
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
            self.keyWait.append(v)
            return True
            
        return self.keyWait

    def keyGet(self):
        if self.keyWait:
            v = self.keyWait[0]
            self.keyWait = self.keyWait[1:]
            return v
        else:
            return None

    def handlePACIFY(self):
        # reset the IOC hardware and software
        self.nilCommandResultAndResetF0()

    def handleERESET(self):
        # not implemented in IOC firmware
        self.nilCommandResultAndResetF0()

    def handleDECHO(self):
        self.setF0(0) # reset F0 before getting input byte
        value = self.getInputByte()
        value = ~value & 0xFF
        self.setCommandResultAndResetF0(value)

    def handleCRTS(self):
        if self.noCRT:
            v = 0
        else:
            v = CRT_PRESENT
        self.setCommandResultAndResetF0(v)

    def handleCRTC(self):
        self.setF0(0) # reset F0 before getting input byte
        value = self.getInputByte()
        sys.stdout.write(chr(value))
        sys.stdout.flush()
        self.nilCommandResultAndResetF0()

    def handleKEYC(self):
        # TODO: get the keypress and return it
        value = self.keyGet()
        if value is None:
            self.keyTimeout = True
            self.setCommandResultAndResetF0(0x00)
        else:
            self.setCommandResultAndResetF0(value)

    def handleKSTC(self):
        if self.noKeyboard:
            v = 0
        else:
            v = KBD_PRESENT
            if self.keyReady():
                v = v | KBD_READY
            if self.keyTimeout:
                v = v | KBD_TIMEOUT
                self.keyTimeout = False
        self.setCommandResultAndResetF0(v)

    def handleRDSTS(self):
        v = 0
        if self.disk is not None:
            v = v | DISK_READY | DISK_PRESENT
        if self.diskComplete:
            v = v | DISK_COMPLETE
        self.setCommandResultAndResetF0(v)

    def handleRRSTS(self):
        self.diskComplete = False
        # we never error
        self.setCommandResultAndResetF0(0)

    def handleWPBC(self):
        self.setF0(0) # reset F0 before getting input byte
        self.iopbChannel = self.getInputByte()
        self.iopbByte = 1     
        self.nilCommandResultAndResetF0()

    def handleWPBCC(self):
        self.setF0(0) # reset F0 before getting input byte
        if (self.iopbByte == 1):
            self.iopbInstruction = self.getInputByte() & 0x07;
        elif (self.iopbByte == 2):
            self.iopbSectorCount = self.getInputByte() & 0x1F;
            if self.iopbSectorCount==0:
                self.iopbSectorCount = 1  # sector count of 0 should be interpreted as 1 sector
        elif (self.iopbByte == 3):
            self.iobpTrack = self.getInputByte() & 0x7F;
        elif (self.iopbByte == 4):
            self.iopbSectorAddress = self.getInputByte() & 0x1F;
            if self.iopbSectorAddress==0:
                self.iopbSectorAddress = 1   # valid sectors are 1-26, so just in case someone passes a 0
            else:
                self.iopbSectorAddress -= 1  # convert to 0-based
            self.diskExecute()        

        self.iopbByte += 1
        self.nilCommandResultAndResetF0()

    def diskRead(self):
        f = open(self.disk, "rb")
        try:
            f.seek((self.iobpTrack*26 + self.iopbSectorAddress)*128)
            # read the file into the disk buffer

            self.diskBuffer = f.read(self.iopbSectorCount*128)
        finally:
            f.close()
        self.diskComplete = True

    def diskWrite(self):
        f = open(self.disk, "r+b")
        try:
            f.seek((self.iobpTrack*26 + self.iopbSectorAddress)*128)
            # write the disk buffer to the file
            f.write(bytearray(self.diskBuffer))
        finally:
            f.close()
        self.diskComplete = True

    def diskExecute(self):
        self.diskComplete = False
        if (self.iopbInstruction == DISK_NOP):
            self.diskComplete = True
        elif (self.iopbInstruction == DISK_SEEK):
            self.diskComplete = True
        elif (self.iopbInstruction == DISK_FORMAT):
            self.diskComplete = True
        elif (self.iopbInstruction == DISK_RECAL):
            self.diskComplete = True
        elif (self.iopbInstruction == DISK_READ):
            self.diskRead()
        elif (self.iopbInstruction == DISK_VERIFY):
            self.diskComplete = True
        elif (self.iopbInstruction == DISK_WRITE):
            self.diskWrite()
        elif (self.iopbInstruction == DISK_WRITE_DEL):
            self.diskComplete = True
        else:
            self.error("  unimplemented disk instruction: %d" % self.iopbInstruction)
            self.diskComplete = True

    def handleRDC(self):
        self.setF0(0)
        for i in range(0, len(self.diskBuffer)):
            self.putOutputByte(self.diskBuffer[i])
        self.diskComplete = False

    def handleWBC(self):
        self.setF0(0)
        sectors = self.getInputByte()
        self.diskBuffer = []
        for i in range(0, sectors*128):
            self.diskBuffer.append(self.getInputByte())

    def handleCommand(self, cmdreg):
        cmd = cmdreg&0x1F
        int = (cmdreg&0x80)!=0

        if (self.verbosity<LOG_CRAZYDEBUG) and (cmd in [CMD_KSTC, CMD_KEYC, CMD_CRTC, CMD_CRTS]):
            # this level of debugging is insane
            self.verbosityOverride = LOG_WARN
        else:
            self.verbosityOverride = None

        cmdName = CMDTABLE.get(cmd, "UUNKNOWN")
        self.log(LOG_INFO, "command: %s%s" % (cmdName, " INT" if int else ""))

        self.wantInt = int

        if cmd==CMD_PACIFY:
            self.handlePACIFY()
        elif cmd==CMD_ERESET:
            self.handleERESET()
        elif cmd==CMD_DECHO:
            self.handleDECHO()
        elif cmd==CMD_CRTC:
            self.handleCRTC()
        elif cmd==CMD_CRTS:
            self.handleCRTS()
        elif cmd==CMD_KEYC:
            self.handleKEYC()
        elif cmd==CMD_KSTC:
            self.handleKSTC()
        elif cmd==CMD_RDSTS:
            self.handleRDSTS()
        elif cmd==CMD_RRSTS:
            self.handleRRSTS()            
        elif cmd==CMD_WPBC:
            self.handleWPBC()
        elif cmd==CMD_WPBCC:
            self.handleWPBCC()
        elif cmd==CMD_RDBC:
            self.handleRDC()
        elif cmd==CMD_WDBC:
            self.handleWBC()
        else:
            self.error("  unimplemented command: %s" % cmdName)
            self.nilCommandResultAndResetF0()

        self.verbosityOverride = None

    
    def run(self, terminal, noKeyboard=False, disk=None, purge=False):
        print("<CTRL-D>: DISK  <CTRL-T> Verbose  <CTRL-U> Quiet  <CTRL-W>: RESET")
        print("<CTRL-X>: EOF")
        print("<ioc started>")
        print("")
        self.terminal = terminal
        self.disk = disk
        self.noKeyboard = noKeyboard
        while True:
            try:
                self.resetOBF()  # reset will leave OBF set, so clear it
                self.readDBIN()  # reset will leave IBF set, so clear it
                self.setF0(0)    # reset will leave F0 set, so clear it       
                if (purge):
                    self.writeDBOUT(0)
                while True:
                    flags = self.readFlags()
                    if isIBF(flags):
                        self.setF0(1)  # mark busy while we check for command
                        v = self.readDBIN()
                        if isCMD(flags):
                            self.handleCommand(v)
                        else:
                            self.error("out of band data byte: %2X" % v)
                            self.setF0(0)  # there was no command, so clear busy flag
                    self.yieldCPU()
            except ResetException:
                pass
