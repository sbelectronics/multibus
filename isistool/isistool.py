from optparse import OptionParser
import sys
import struct

ACT_OPEN = 0x00
ACT_NEVER_USED = 0x7F

FLAG_INVISIBLE = 1
FLAG_SYSTEM = 2
FLAG_WRITE_PROTECT = 4
FLAG_FORM = 0x80

def hexdump(s):
    for i in range(0,len(s),16):
        print("{:04x}: ".format(i), end="")
        for j in range(0,16):
            if i+j < len(s):
                print("{:02x} ".format(s[i+j]), end="")
            else:
                print("   ", end="")
        print(" ", end="")
        for j in range(0,16):
            if i+j < len(s):
                c = s[i+j]
                if c < 32 or c > 127:
                    c = ord(".")
                print("{:c}".format(c), end="")
            else:
                print(" ", end="")
        print("")

def strip(s):
    while s and (ord(s[-1]) == 0):
        s = s[:-1]
    return s

def secOffset(sector, track, sectorsPerTrack):
    return (track * sectorsPerTrack + sector - 1) * 128

def secNumberToSecTrack(secnum, sectorsPerTrack):
    track = secnum // sectorsPerTrack
    sector = (secnum % sectorsPerTrack) + 1
    return (sector, track)

class DirEntry:
    def __init__(self, activity=ACT_NEVER_USED, name="", ext="", invisible=False, system=False, writeProtect=False, form=False, length=0, track=0, sector=0):
        self.name = name
        self.invisible = invisible
        self.system = system
        self.writeProtect = writeProtect
        self.form=form
        self.activity=activity
        self.length=length
        self.track = track
        self.sector = sector

    def pack(self, buffer):
        flags = 0
        if self.invisible:
            flags |= FLAG_INVISIBLE
        if self.system:
            flags |= FLAG_SYSTEM
        if self.writeProtect:
            flags |= FLAG_WRITE_PROTECT
        if self.form:
            flags |= FLAG_FORM
        datablocks = self.length // 128
        leftover = self.length % 128
        packed = struct.pack("B6s3sBBHBB",
                    self.activity,
                    self.name,
                    self.ext,
                    flags,
                    leftover,
                    datablocks,
                    self.sector,
                    self.track)
        return packed
    
    def unpack(self, buffer):
        self.activity, self.name, self.ext, flags, leftover, datablocks, self.sector, self.track = struct.unpack("B6s3sBBHBB", buffer[:16])
        self.name = strip(self.name.decode('ascii'))
        self.ext = strip(self.ext.decode('ascii'))
        self.invisible = flags & FLAG_INVISIBLE
        self.system = flags & FLAG_SYSTEM
        self.writeProtect = flags & FLAG_WRITE_PROTECT
        self.form = flags & FLAG_FORM
        self.length = (datablocks-1) * 128 + leftover

    def printEntry(self):
        if self.invisible:
            inv = "I"
        else:
            inv = " "
        if self.system:
            sys = "S"
        else:
            sys = " "
        if self.writeProtect:
            wp = "W"
        else:
            wp = " "
        if self.form:
            form = "F"
        else:
            form = " "
        print("%-6s %-3s %c%c%c%c %6d" % (self.name, self.ext, inv, sys, wp, form, self.length))

class Dir:
    def __init__(self):
        self.entries = []

    def pack(self):
        buffer = b""
        for entry in self.entries:
            buffer += entry.pack()
        return buffer

    def unpack(self, buffer):
        while buffer:
            entry = DirEntry()
            entry.unpack(buffer[:16])
            self.entries.append(entry)
            buffer = buffer[16:]

    def toSectors(self):
        sectors = []
        buffer = self.pack()
        while buffer:
            sectors.append(buffer[:128])
            buffer = buffer[128:]
        return sectors

    def fromSectors(self, sectors):
        buffer = b"".join(sectors)
        self.unpack(buffer)
        
    def printDir(self):
        for entry in self.entries:
            if entry.activity == ACT_OPEN:
                entry.printEntry()

    def find(self, name):
        if "." in name:
            (name, ext) = name.split(".",1)
        else:
            ext=""
        for entry in self.entries:
            if (entry.name.lower() == name.lower()) and (entry.ext.lower() == ext.lower()):
                return entry
        return None

class Link:
    def __init__(self, sector, track):
        self.sector = sector
        self.track = track

class LinkBlock:
    def __init__(self, prevSec=0, prevTrack=0, nextSec=0, nextTrack=0):
        self.prevSec = prevSec
        self.prevTrack = prevTrack
        self.nextSec = nextSec
        self.nextTrack = nextTrack
        self.links = []
        for i in range(0,62):
            self.links.append(Link(0,0))

    def unpack(self, buffer):
        self.prevSec, self.prevTrack, self.nextSec, self.nextTrack = struct.unpack("BBBB", buffer[:4])
        buffer = buffer[4:]
        for i in range(0,62):
            self.links[i] = Link(buffer[i*2], buffer[i*2+1])

class LinkList:
    def __init__(self, sector=0, track=0, sectorsPerTrack=26):
        self.linkBlocks = []
        self.sector = sector
        self.track = track
        self.sectorsPerTrack = sectorsPerTrack

    def load(self, buffer):
        sector = self.sector
        track = self.track
        while (track != 0):
            offset = secOffset(sector, track, self.sectorsPerTrack)
            blk = LinkBlock()
            blk.unpack(buffer[offset:])
            self.linkBlocks.append(blk)
            sector = blk.nextSec
            track = blk.nextTrack

class Bitmap:
    def __init__(self, sectorsPerTrack=26):
        self.inuse = []
        self.sectorsPerTrack = sectorsPerTrack

    def load(self, buffer):
        offset = secOffset(2, 2, self.sectorsPerTrack)  # always starts at sector 2 on track 2 and is contiguous
        sectors = self.sectorsPerTrack * 77
        j = offset
        for i in range(0, sectors-1):
            if (i % 8) == 0:
                b = buffer[j]
                j += 1
            self.inuse.append(b & 0x01)
            b = b >> 1

    def printFree(self):
        for i in range(0, len(self.inuse)):
            if not self.inuse[i]:
                (sec, track) = secNumberToSecTrack(i+1, self.sectorsPerTrack)
                print("Sector %d Track %d" % (sec, track))

class Disk:
    def __init__(self, fileName=None, sectorsPerTrack=26):
        self.fileName = fileName
        self.sectorsPerTrack = sectorsPerTrack
        self.dir = Dir()
        if fileName is not None:
            self.contents = open(fileName, "rb").read()
            if len(self.contents) == 256256:
                pass
            elif len(self.contents) == 512512:
                self.sectorsPerTrack = 52
            else:
                raise("Invalid disk image size")
            self.loadDir()
            self.loadBitmap()
    
    def loadDir(self):
        dirLinks = LinkList(1,1, self.sectorsPerTrack)
        dirLinks.load(self.contents)
        for linkBlock in dirLinks.linkBlocks:
            sectors = []
            for link in linkBlock.links:
                if link.track != 0:
                    offset = secOffset(link.sector, link.track, self.sectorsPerTrack)
                    sectors.append(self.contents[offset:offset+128])
            self.dir.fromSectors(sectors)

    def loadBitmap(self):
        self.bitmap = Bitmap(self.sectorsPerTrack)
        self.bitmap.load(self.contents)

    def getFile(self, name):
        f = self.dir.find(name)
        if not f:
            return None
        links = LinkList(f.sector, f.track, self.sectorsPerTrack)
        links.load(self.contents)
        data = b""
        for linkBlock in links.linkBlocks:
            for link in linkBlock.links:
                if link.track != 0:
                    offset = secOffset(link.sector, link.track, self.sectorsPerTrack)
                    data += self.contents[offset:offset+128]
        data = data[:f.length]
        return data
    
    def listBlocks(self, name):
        f = self.dir.find(name)
        if not f:
            return
        links = LinkList(f.sector, f.track, self.sectorsPerTrack)
        links.load(self.contents)
        for linkBlock in links.linkBlocks:
            for link in linkBlock.links:
                if link.track != 0:
                    print("Sector %d Track %d" % (link.sector, link.track))

def checkLoaded(f):
    if f is None:
        print("file not found")
        sys.exit(-1)

def main():
    parser = OptionParser(usage="supervisor [options] command",
            description="Commands: ...")

    parser.add_option("-v", "--verbose", dest="verbose",
         help="verbose", action="count", default=0)
    
    parser.add_option("-q", "--quiet", dest="quiet",
         help="quiet", action="count", default=0)
    
    parser.add_option("-f", "--filename", dest="filename",
         help="filename", action="store", default="disk.img")

    (options, args) = parser.parse_args(sys.argv[1:])

    if len(args)==0:
        print("missing command")
        sys.exit(-1)

    disk = Disk(fileName = options.filename)

    cmd = args[0]
    args=args[1:]

    if (cmd in ["hexdump", "extract", "blocks"]):
        if len(args)==0:
            print("missing filename")
            sys.exit(-1)

    if (cmd=="dir"):
        disk.dir.printDir()
    elif (cmd=="hexdump"):
        f = disk.getFile(args[0])
        checkLoaded(f)
        hexdump(f)
    elif (cmd=="extract"):
        f = disk.getFile(args[0])
        checkLoaded(f)
        open(args[0], "wb").write(f)
    elif (cmd=="free"):
        disk.bitmap.printFree()
    elif (cmd=="blocks"):
        disk.listBlocks(args[0])

if __name__ == "__main__":
    main()

