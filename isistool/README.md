isis disk manipulation tool
http://www.smbaker.com/

This tool works on raw disk images, i.e. "IMG" files. It does not work on imagedisk (IMD) or other
non-raw file types.

This program requires python version 3.

Syntax:

* isistool.py -f <filename> COMMAND <ARG>

Commands:

* DIR ... display directory

* SUMS ... directory with shasum display

* HEXDUMP <FN> ... dump hex contents of fdile

* GET <FN> ... get file from ISIS disk and store in local file

* PUT <FN> ... get local file and write to isis disk

* ATTRIB <FN> <ATTR> ... set or reset attributes (ISWF). Example I+ to set or I- to reset. Separate multiple attributes with spaces.

* VERIFY <FN> <SUM> ... verify that filename has the right sum

* FREE ... display list of free blocks

* BLOCKS <fn> ... display the list of blocks occupied by file

* CHKDSK ... check disk integrity by verifying free bitmap matches allocated block lists.

Examples:

```bash
$ echo "scott was here" > tstfil.txt

$ cp testdata/testdisk_sd.img disk.img

$ isistool.py -f disk.img add tstfil.txt

$ isistool.py -f disk.img hexdump tstfil.txt
0000: 73 63 6f 74 74 20 77 61 73 20 68 65 72 65 0a     scott was here. 

$ isistool.py -f disk.img dir
ISIS   DIR I  F   3072 
ISIS   MAP I  F    128
...
MAZE        SW    6855 
TSTFIL TXT          15
```

Note: It's intended that you start by manipulating a known-good disk image.
This tool does not yet create blank images.
