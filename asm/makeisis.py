# Ugly hack to turn a ZCC-generated program into a one compatible with
# the ISIS assembler. We just assume the ZCC program started at 0x3680
# and we copy it all in with 'DB' ... Then we can assemble it.

import sys

bytes = sys.stdin.buffer.read()

print("; XXX AUTOGENERATED XXX")

print("\tCSEG")
print("ORIG:\t")

for b in bytes:
  print("\tdb %03XH" % b)

print("\tEND\tORIG")
