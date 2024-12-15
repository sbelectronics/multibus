from __future__ import print_function
import string
import sys
import time
import RPi.GPIO as IO

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

KBD_READY =   0x01
KBD_PRESENT = 0x02
KBD_ILLEGAL = 0x40
KBD_TIMEOUT = 0x80

DISK_READY =    0x02
DISK_COMPLETE = 0x04
DISK_PRESET =   0x08
DISK_ILLEGAL_DATA = 0x20
DISK_ILLEGAL_STATUS = 0x40

def isOBF(flags):
    return (flags&FLAG_OBF)!=0

def isIBF(flags):
    return (flags&FLAG_IBF)!=0

def isCMD(flags):
    return (flags&FLAG_CD)!=0

class IOCInterface:
    def __init__(self, verbose):
        self.verbose = verbose

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

        IO.output(PIN_INIT, 1)
        IO.output(PIN_SELDBOUT, 1)
        IO.output(PIN_SELDBIN, 1)
        IO.output(PIN_SELSTAT, 1)
        IO.output(PIN_INT, 1)
        IO.output(PIN_A0, 1)
        IO.output(PIN_CLKF0, 1)
        IO.output(PIN_SETF1, 1)
        IO.output(PIN_RESETF1, 1)

    def cleanup(self):
        pass # IO.cleanup()

    def setDataInput(self):
        for datapin in DATAPINS:
            IO.setup(datapin, IO.IN)

    def setDataOutput(self):
        for datapin in DATAPINS:
            IO.setup(datapin, IO.OUT)

    def reset(self):
        IO.output(PIN_INIT,0)
        IO.output(PIN_INIT,1)

    def printFlags(self):
        flags = self.readFlags()
        print("  OBF=%d IBF=%d F0=%d CD=%d" % ((flags&FLAG_OBF)!=0, (flags&FLAG_IBF)!=0, (flags&FLAG_F0)!=0, (flags&FLAG_CD)!=0))

    def printDBIN(self):
        dbin = self.readDBIN()
        print("  DBIN=%2X" % dbin)
    
    def printStatus(self):
        self.printFlags()
        self.printDBIN()
        
    def log(self, msg):
        if self.verbose:
            print(msg, file=sys.stderr)

    def error(self, msg):
        print(msg, file=sys.stderr)

    def delay(self):
        time.sleep(0.001)

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
        self.select(REG_STAT)
        result = self.readInput()
        self.select(REG_NONE)
        return result
    
    def readDBIN(self):
        self.select(REG_DBIN)
        result = self.readInput()
        self.select(REG_NONE)
        return result
    
    def writeDBOUT(self, d):
        self.select(REG_NONE)
        self.setA0(0)
        self.setDataOutput()
        self.writeOutput(d)
        self.select(REG_DBOUT)
        self.select(REG_NONE)
        self.setDataInput()
    
    def setA0(self, value):
        IO.output(PIN_A0, value)
    
    def setF0(self, value):
        self.setA0(value)
        IO.output(PIN_CLKF0, 0)
        self.delay()
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
                    self.log("  got data byte: %2X" % data)
            time.sleep(0.001)

    def putOutputByte(self, value):
        while True:
            flags = self.readFlags()
            if not isOBF(flags):
                self.writeDBOUT(value)
                return
            time.sleep(0.001)

    def setCommandResultAndResetF0(self, value):
        self.log("command complete with result to %2X" % value)
        self.setF0(0)   # XXX should we do this before or after we put the output byte?
        self.putOuputByte(value)

    def nilCommandResultAndResetF0(self):
        self.log("command complete with no result")
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
                time.sleep(0.1)

    def handleCRTS(self):
        self.setCommandResultAndResetF0(0x01)

    def handleCRTC(self):
        value = self.getInputByte()
        self.stdout.write(value)
        self.nilCommandResultAndResetF0()

    def handleKEYC(self):
        # TODO: get the keypress and return it
        self.setCommandResultAndResetF0(0x00)

    def handleKSTC(self):
        v = KBD_PRESENT
        # TODO: if key is ready, set KBD_READY
        self.setCommandResultAndResetF0(v)

    def handleRDSTS(self):
        v = 0
        # TODO: set DISK_READY once implemented
        # TODO: deal with the ready and complete bits too...
        self.setCommandResultAndResetF0(v)

    def handleCommand(self, cmdreg):
        cmd = cmdreg&0x1F
        int = (cmdreg&0x80)!=0

        cmdName = CMDTABLE.get(cmd, "UUNKNOWN")
        self.log("command: %s%s" % (cmdName, " INT" if int else ""))

        self.wantInt = int

        if cmd==CMD_CRTC:
            self.handleCRTC()
        elif cmd==CMD_CRTS:
            self.handleCRTS()
        elif cmd==CMD_KEYC:
            self.handleKEYC()
        elif cmd==CMD_KSTC:
            self.handleKSTC()
        elif cmd==CMD_RDSTS:
            self.handleRDSTS()
    
    def run(self):
        self.readDBIN()  # reset will leave IBF set, so clear it
        self.setF0(0)    # reset will leave F0 set, so clear it
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
            time.sleep(0.01)
            pass
