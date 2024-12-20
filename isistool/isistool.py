#!/usr/bin/env python3

# isistool.py
# http://www.smbaker.com/
#
# a tool for manipulating ISIS-II disk images

import os
from optparse import OptionParser
import sys
import struct
import hashlib

ACT_OPEN = 0x00
ACT_NEVER_USED = 0x7F
ACT_DELETED = 0xFF

FLAG_INVISIBLE = 1
FLAG_SYSTEM = 2
FLAG_WRITE_PROTECT = 4
FLAG_FORM = 0x80

flagMap = {"I": FLAG_INVISIBLE,
        "S": FLAG_SYSTEM,
        "W": FLAG_WRITE_PROTECT,
        "F": FLAG_FORM}

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

def secTrackToSecNumber(sector, track, sectorsPerTrack):
    return (track * sectorsPerTrack) + sector - 1

def secOffset(sector, track, sectorsPerTrack):
    return secTrackToSecNumber(sector, track, sectorsPerTrack) * 128

def secNumberToSecTrack(secnum, sectorsPerTrack):
    track = secnum // sectorsPerTrack
    sector = (secnum % sectorsPerTrack) + 1
    return (sector, track)

class DirEntry:
    def __init__(self, activity=ACT_NEVER_USED, name="", ext="", invisible=False, system=False, writeProtect=False, form=False, length=0, sector=0, track=0):
        self.name = name
        self.ext = ext
        self.invisible = invisible
        self.system = system
        self.writeProtect = writeProtect
        self.form=form
        self.activity=activity
        self.length=length
        self.track = track
        self.sector = sector

    def pack(self):
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
        if (leftover!=0):
            datablocks += 1
        packed = struct.pack("B6s3sBBHBB",
                    self.activity,
                    self.name.encode(encoding="utf-8"),
                    self.ext.encode(encoding="utf-8"),
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
        if (datablocks == 0):
            self.length = 0
        else:
            self.length = (datablocks-1) * 128 + leftover

    def printEntry(self, extra=""):
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
        if extra:
            extra = " " + extra
        print("%-6s %-3s %c%c%c%c %6d %s" % (self.name, self.ext, inv, sys, wp, form, self.length, extra))

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
    
    def remove(self, name):
        if "." in name:
            (name, ext) = name.split(".",1)
        else:
            ext=""
        for entry in self.entries:
            if (entry.name.lower() == name.lower()) and (entry.ext.lower() == ext.lower()):
                entry.activity = ACT_DELETED
                return entry
        return None
    
    def add(self, entry):
        for i in range(0, len(self.entries)):
            if self.entries[i].activity in [ACT_NEVER_USED, ACT_DELETED]:
                self.entries[i] = entry
                return
        raise Exception("No free space in dir")

class Link:
    def __init__(self, sector, track):
        self.sector = sector
        self.track = track

class LinkBlock:
    def __init__(self, sector=0, track=0, prevSec=0, prevTrack=0, nextSec=0, nextTrack=0):
        self.sector = sector
        self.track = track
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

    def pack(self):
        packed = struct.pack("BBBB", self.prevSec, self.prevTrack, self.nextSec, self.nextTrack)
        for link in self.links:
            packed += struct.pack("BB", link.sector, link.track)
        return packed

    def isFull(self):
        for link in self.links:
            if link.track == 0:
                return False
        return True
    
    def addLink(self, sector, track):
        for link in self.links:
            if link.track == 0:
                link.sector = sector
                link.track = track
                return
        raise("Link block full")

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
            blk = LinkBlock(sector, track)
            blk.unpack(buffer[offset:])
            self.linkBlocks.append(blk)
            sector = blk.nextSec
            track = blk.nextTrack

    def save(self, buffer):
        for blk in self.linkBlocks:
            offset = secOffset(blk.sector, blk.track, self.sectorsPerTrack)
            buffer[offset:offset+128] = blk.pack()

    def addLinkBlock(self, bitmap):
        (sector, track) = bitmap.getFirstFree()
        blk = LinkBlock(sector, track)
        if self.linkBlocks:
            lastBlock = self.linkBlocks[-1]
            lastBlock.nextSec = sector
            lastBlock.nextTrack = track
            blk.prevSec = lastBlock.sector
            blk.prevTrack = lastBlock.track
        else:
            self.sector = sector
            self.track = track
        self.linkBlocks.append(blk)

    def makeSpace(self, bitmap):
        if (len(self.linkBlocks) == 0) or (self.linkBlocks[-1].isFull()):
            self.addLinkBlock(bitmap)

    def addSector(self, sector, track):
        self.linkBlocks[-1].addLink(sector, track)

class Bitmap:
    def __init__(self, sectorsPerTrack=26):
        self.inuse = []
        self.sectorsPerTrack = sectorsPerTrack
        for i in range(0, self.sectorsPerTrack * 77):
            self.inuse.append(False)

    def load(self, buffer):
        offset = secOffset(2, 2, self.sectorsPerTrack)  # always starts at sector 2 on track 2 and is contiguous
        sectors = self.sectorsPerTrack * 77
        j = offset
        self.inuse = []
        for i in range(0, sectors):
            if (i % 8) == 0:
                b = buffer[j]
                j += 1
            self.inuse.append((b & 0x80)!=0)
            b = b << 1

    def save(self, buffer):
        offset = secOffset(2, 2, self.sectorsPerTrack)  # always starts at sector 2 on track 2 and is contiguous
        sectors = self.sectorsPerTrack * 77
        j = offset
        for i in range(0, sectors):
            if (i % 8) == 0:
                buffer[j] = 0

            if self.inuse[i]:
                buffer[j] = buffer[j] | (1 << (7 - (i % 8)))
            
            if (i % 8) == 7:
                j += 1

    def printFree(self):
        for i in range(0, len(self.inuse)):
            if not self.inuse[i]:
                (sec, track) = secNumberToSecTrack(i, self.sectorsPerTrack)
                print("Sector %d Track %d" % (sec, track))

    def freeSector(self, sector, track):
        secNum = secTrackToSecNumber(sector, track, self.sectorsPerTrack)
        self.inuse[secNum] = False

    def useSector(self, sector, track):
        secNum = secTrackToSecNumber(sector, track, self.sectorsPerTrack)
        self.inuse[secNum] = True

    def getFirstFree(self):
        for i in range(0, len(self.inuse)):
            if not self.inuse[i]:
                self.inuse[i] = True
                return secNumberToSecTrack(i, self.sectorsPerTrack)
        raise Exception("no free space in bitmap")

class Disk:
    def __init__(self, fileName=None, sectorsPerTrack=26):
        self.fileName = fileName
        self.sectorsPerTrack = sectorsPerTrack
        self.dir = Dir()
        if fileName is not None:
            self.contents = open(fileName, "rb").read()
            self.contents = bytearray(self.contents)
            if len(self.contents) == 256256:
                pass
            elif len(self.contents) == 512512:
                self.sectorsPerTrack = 52
            else:
                raise("Invalid disk image size")
            self.loadDir()
            self.loadBitmap()

    def save(self, fileName=None):
        if fileName is None:
            fileName = self.fileName
        open(fileName, "wb").write(self.contents)

    def loadDir(self):
        self.dir = Dir()
        dirLinks = LinkList(1,1, self.sectorsPerTrack)
        dirLinks.load(self.contents)
        for linkBlock in dirLinks.linkBlocks:
            sectors = []
            for link in linkBlock.links:
                if link.track != 0:
                    offset = secOffset(link.sector, link.track, self.sectorsPerTrack)
                    sectors.append(self.contents[offset:offset+128])
            self.dir.fromSectors(sectors)

    def saveDir(self):
        dirLinks = LinkList(1,1, self.sectorsPerTrack)
        dirLinks.load(self.contents)
        sectors = self.dir.toSectors()
        for linkBlock in dirLinks.linkBlocks:
            for link in linkBlock.links:
                if link.track != 0:
                    offset = secOffset(link.sector, link.track, self.sectorsPerTrack)
                    self.contents[offset:offset+128] = sectors[0]
                    sectors = sectors[1:]

    def loadBitmap(self):
        self.bitmap = Bitmap(self.sectorsPerTrack)
        self.bitmap.load(self.contents)

    def saveBitmap(self):
        self.bitmap.save(self.contents)

    def getFileDataFromEntry(self, f):
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

    def getFile(self, name):
        f = self.dir.find(name)
        if not f:
            return None
        return self.getFileDataFromEntry(f)
    
    def listBlocks(self, name):
        f = self.dir.find(name)
        if not f:
            return
        links = LinkList(f.sector, f.track, self.sectorsPerTrack)
        links.load(self.contents)
        for linkBlock in links.linkBlocks:
            print("LINK Block %d %d" % (linkBlock.sector, linkBlock.track))
            for link in linkBlock.links:
                if link.track != 0:
                    print("DATA Sector %d Track %d" % (link.sector, link.track))

    def deleteFile(self, name):
        f = self.dir.find(name)
        if not f:
            return None
        links = LinkList(f.sector, f.track, self.sectorsPerTrack)
        links.load(self.contents)
        for linkBlock in links.linkBlocks:
            for link in linkBlock.links:
                if link.track != 0:
                    self.bitmap.freeSector(link.sector, link.track)
            self.bitmap.freeSector(linkBlock.sector, linkBlock.track)
        result = self.dir.remove(name)
        self.saveDir()
        self.saveBitmap()
        return result
    
    def setAttr(self, name, flag, value):
        f = self.dir.find(name)
        if not f:
            return None
        if flag&FLAG_INVISIBLE:
            f.invisible = value
        if flag&FLAG_SYSTEM:
            f.system = value
        if flag&FLAG_WRITE_PROTECT:
            f.writeProtect = value
        if flag&FLAG_FORM:
            f.form = value
        self.saveDir()
        return f
    
    def addFile(self, name, data):
        name = os.path.split(name)[1]

        if "." in name:
            (name, ext) = name.split(".",1)
        else:
            ext = ""

        name = name.upper()
        ext = ext.upper()

        dataLen = len(data)

        blkList = LinkList(sectorsPerTrack=self.sectorsPerTrack)
        while data:
            blkList.makeSpace(self.bitmap)
            (sector, track) = self.bitmap.getFirstFree()
            blkList.addSector(sector, track)
            while (len(data)<128):  # pad data out to a full sector
                data += b"\0"
            self.contents[secOffset(sector, track, self.sectorsPerTrack):secOffset(sector, track, self.sectorsPerTrack)+128] = data[:128]
            data = data[128:]

        entry = DirEntry(ACT_OPEN, name, ext, sector=blkList.sector, track=blkList.track, length=dataLen)
        self.dir.add(entry)

        blkList.save(self.contents)

        self.saveDir()
        self.saveBitmap()

    def chkdsk(self):
        cmap = Bitmap(self.sectorsPerTrack)
        for entry in self.dir.entries:
            if entry.activity == ACT_OPEN:
                links = LinkList(entry.sector, entry.track, self.sectorsPerTrack)
                links.load(self.contents)
                for linkBlock in links.linkBlocks:
                    for link in linkBlock.links:
                        if link.track != 0:
                            cmap.useSector(link.sector, link.track)
                    cmap.useSector(linkBlock.sector, linkBlock.track)

        # T0 is always used
        for i in range(0, self.sectorsPerTrack):
            cmap.useSector(i+1, 0)

        # second half of T1 on DD disk should be marked used too
        for i in range(26, self.sectorsPerTrack):
            cmap.useSector(i+1, 1)

        failed=False
        for i in range(0, 77*self.sectorsPerTrack):
            if cmap.inuse[i] and not self.bitmap.inuse[i]:
                print("Sector %d Track %d is in use but not marked in bitmap" % secNumberToSecTrack(i, self.sectorsPerTrack))
                failed=True
            if not cmap.inuse[i] and self.bitmap.inuse[i]:
                print("Sector %d Track %d is marked in bitmap but not in use" % secNumberToSecTrack(i, self.sectorsPerTrack))
                failed=True

        if failed:
            raise Exception("CHKDSK failed")
        
    def sums(self):
        for entry in self.dir.entries:
            if entry.activity == ACT_OPEN:
                data = self.getFileDataFromEntry(entry)
                sha1 = hashlib.sha1(data).hexdigest()
                entry.printEntry(extra=sha1)

def checkFound(f):
    if f is None:
        print("file not found")
        sys.exit(-1)

def help():
    print("""Syntax: isistool.py -f <filename> COMMAND <ARG>

Commands:
* DIR ... display directory
* SUMS ... directory with shasum display
* HEXDUMP <FN> ... dump hex contents of fdile
* GET <FN> ... get file from ISIS disk and store in local file
* PUT <FN> ... get local file and write to isis disk
* DELETE <FN> ... delete file from ISIS disk
* ATTRIB <FN> <ATTR>  ... set file attributes
* VERIFY <FN> <SUM> ... verify that filename has the right sum
* FREE ... display list of free blocks
* BLOCKS <fn> ... display the list of blocks occupied by file
* CHKDSK ... check disk integrity by verifying free bitmap matches allocated block lists.
""")

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
        help()
        sys.exit(-1)

    disk = Disk(fileName = options.filename)

    cmd = args[0].lower()
    args=args[1:]

    # extract, addr, and remove are synonyms for get, put, and delete

    if (cmd in ["hexdump", "extract", "put", "add", "get", "blocks", "remove", "delete", "attrib", "verify"]):
        if len(args)==0:
            print("missing filename")
            sys.exit(-1)

    if (cmd=="dir"):
        disk.dir.printDir()
    elif (cmd=="sums"):
        disk.sums()
    elif (cmd=="hexdump"):
        f = disk.getFile(args[0])
        checkFound(f)
        hexdump(f)
    elif (cmd in ["extract", "get"]):
        f = disk.getFile(args[0])
        checkFound(f)
        open(args[0], "wb").write(f)
    elif (cmd=="verify"):
        f = disk.getFile(args[0])
        checkFound(f)        
        sum = hashlib.sha1(f).hexdigest()
        if sum != args[1]:
            print("sha mismatch")
            sys.exit(-1)
    elif (cmd in ["remove", "delete"]):
        f = disk.deleteFile(args[0])
        checkFound(f)
        disk.chkdsk()
        disk.save()
    elif (cmd in ["add", "put"]):
        data = open(args[0], "rb").read()
        disk.addFile(args[0], data)
        disk.chkdsk()
        disk.save()
    elif (cmd=="attrib"):
        fn = args[0]
        attrs = args[1:]
        for attr in attrs:
            attr = attr.upper()
            if attr[:1] not in flagMap:
                print("unknown attribute. should be one of I, S, W, F")
                sys.exit(-1)
            if attr[1:] == "+":
                f = disk.setAttr(fn, flagMap[attr[:1]], True)
                checkFound(f)
            elif attr[1:] == "-":
                f = disk.setAttr(fn, flagMap[attr[:1]], False)
            else:
                print("attribute should end with + or -. For example W+ or I-")
                sys.exit(-1)
        disk.saveDir()
        disk.chkdsk()
        disk.save()
    elif (cmd=="free"):
        disk.bitmap.printFree()
    elif (cmd=="blocks"):
        disk.listBlocks(args[0])
    elif (cmd=="chkdsk"):
        disk.chkdsk()
    elif (cmd=="help"):
        help()
    else:
        print("unknown command: %s" % cmd)
        help()
        sys.exit(-1)

if __name__ == "__main__":
    main()

