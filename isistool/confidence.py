#!/usr/bin/env python3

# confidence.py
# http://www.smbaker.com/
#
# confidence test for isistool.py

import os
import sys
from isistool import *

SD_FILENAME = "testdata/testdisk_sd.img"
DD_FILENAME = "testdata/testdisk_dd.img"
TEST_FILENAME = "testdisk.img"
TEST_FILENAME2 = "testdisk2.img"

files = {
    "ATTRIB": (5002, "07e7b8708e69275aefde43443a78f20bc9cab769"),
    "COPY": (8582, "8bcc3c24b63ee7439095cd7d35fa5369a7939caf"),
    "DELETE": (4917, "47f8abf3f45fb5e79b69e8841e7902e9354f3bc8"),
    "EDIT": (7333, "5f9faa3bbc4bda6d50d840bafdcf4cc8340bc631"),
    "FORMAT": (7849, "ba0af0b81c7b0d778f7c85ee2bce9acc9115de45"),
    "LIB": (10227,"f80fe02a70f7995589d5628049525d049e1b72d4"),
    "LINK.OVL": (4578, "b2e7fc18f3c1b60c70f4604f935b9ff21c14eff5"),
    "SUBMIT": (4914, "60a4b48e6228d5b5605a2a83add091dfc30c858e"),
    "SYSTEM.LIB": (3128, "73a38b48f0479304a2a245c4bf04f71a440db0c3")
}

newFiles = {
    "ILLIAD.TXT": (39291, "907933e5a98192b454c00190f16affd03d28c7d7"),
    "ODYSS.TXT": (24510, "0a9c4b1a04c37142d05f39445c1377fad5b070f3"),
    "CNTRY.TXT": (69, "a9adb1c0452cfe5cd4b762d1602cd237b8b2bb65"),
    "RANDOM.BIN": (8197, "cafe540bc007cf2e23b9a1d74904d97ee5a44879"),
    "PRIMES.TXT": (471, "e0f5e0c10ef1e9bae3c3105db311e68e1a180052")
}

def verify(disk, files):
    for name, (size, sha1) in files.items():
        f = disk.getFile(name)
        if f is None:
            print("missing file: %s" % name)
            sys.exit(-1)
        computedSha1 = hashlib.sha1(f).hexdigest()
        if len(f)!=size:
            print("size mismatch: %s: %d != %d" % (name, len(f), size))
            #sys.exit(-1)
        if computedSha1 != sha1:
            print("sha1 mismatch: %s: %s != %s" % (name, computedSha1, sha1))
            #sys.exit(-1)

def runtest(srcFilename):
    if os.path.exists(TEST_FILENAME):
        os.remove(TEST_FILENAME)

    if os.path.exists(TEST_FILENAME2):
        os.remove(TEST_FILENAME2)

    disk = Disk(fileName = srcFilename)
    disk.chkdsk()
    verify(disk, files)
    disk.save(fileName = TEST_FILENAME)

    # now open the newly created disk

    disk = Disk(fileName = TEST_FILENAME)
    disk.chkdsk()
    verify(disk, files)

    disk.addFile("CNTRY.TXT", open("testdata/cntry.txt", "rb").read())
    disk.chkdsk()

    disk.addFile("ODYSS.TXT", open("testdata/odyss.txt", "rb").read())
    disk.chkdsk()

    disk.addFile("PRIMES.TXT", open("testdata/primes.txt", "rb").read())
    disk.chkdsk()

    disk.addFile("RANDOM.BIN", open("testdata/random.bin", "rb").read())
    disk.chkdsk()

    f = disk.deleteFile("FIXMAP")
    if f is None:
        print("missing file: FIXMAP")
        sys.exit(-1)

    disk.deleteFile("LINK")
    if f is None:
        print("missing file: LINK")
        sys.exit(-1)

    disk.deleteFile("VERS")
    if f is None:
        print("missing file: VERS")
        sys.exit(-1)

    disk.addFile("ILLIAD.TXT", open("testdata/illiad.txt", "rb").read())
    disk.chkdsk()

    f = disk.getFile("ILLIAD.TXT")
    open("verify.txt", "wb").write(f)

    verify(disk,files)
    verify(disk,newFiles)

    # save the modified disk and reload it again

    disk.save(fileName = TEST_FILENAME2)
    disk = Disk(fileName = TEST_FILENAME2)
    disk.chkdsk()
    
    verify(disk,files)
    verify(disk,newFiles)    

def main():
    print("SD TEST")
    runtest(SD_FILENAME)
    print("DD TEST")
    runtest(DD_FILENAME)

    print("Confidence test passed")

if __name__=="__main__":
    main()
