import sys

# Double Density Disk addresses for 8259A operations. These
# are FC on an MDS-80 but D8 on an 80/24.

addr_out_fc = [ 0x669,
                0x6ca,
                0x372B,
                0x3EA8,
                0x3FCB,
                0x400C,
                0x4016,
                0x470B,
                0x4776 ]
#                0x667A ]   # patching the one at 667A will cause it to not boot

addr_in_fc =  [  0x662,
                 0x3EA1,
                 0x4704 ]

# The first two (2F8 and 331) may not even be instructions.
# The rest of them probably don't matter. It turns out the IN C1 that
# were messing up my load time were in the ROM, not the disk.

addr_in_c1 =  [ 0x02FB,
                0x0331,
                0x077F,
                0x79D,
                0x5FA3,
                0x600A ]

instr_mvi = 0x3E
instr_out = 0xD3
instr_in = 0xDB

def main(argv=None):
    print("PatchDisk v1.0")
    print("This program will patch a disk image to change the 8259 port addresses")
    print("from FC to D8")
    print("")

    diskfile = argv[1]
    try:
        with open(diskfile, "rb") as f:
            disk = f.read()
    except FileNotFoundError:
        print("File not found.")
        return
    
    disk = bytearray(disk)

    # Patch the disk image
    for addr in addr_in_fc:
        if (disk[addr] == instr_in) and (disk[addr+1] == 0xFC):
            print("Patching %04X" % addr)
            disk[addr+1] = 0xD8
        else:
            print("Instruction not found at %04X" % addr)

    for addr in addr_out_fc:
        if (disk[addr] == instr_out) and (disk[addr+1] == 0xFC):
            print("Patching %04X" % addr)
            disk[addr+1] = 0xD8
        else:
            print("Instruction not found at %04X" % addr)

    # Write the patched disk image
    patchedfile = argv[2]
    with open(patchedfile, "wb") as f:
        f.write(disk)

    print("Patched disk image written to %s" % patchedfile)

if __name__ == "__main__":
    main(sys.argv)