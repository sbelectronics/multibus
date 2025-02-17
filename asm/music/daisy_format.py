lines = open("daisy.phons","r").readlines()

n=0
for line in lines:
    lines = line.strip()
    parts = line.split(",")
    for part in parts:
        part = part.strip()
        if not part:
            continue
        part_int = int(part, 16)
        upper = part_int & 0xC0
        upper = (~upper) & 0xC0
        part_int = (part_int & 0x3F) | upper

        if (n==0):
            print("DAISY:\tDB\t", end="")
        elif (n % 8) == 0:
            print("\tDB\t", end="")
        print("0%02XH" % part_int, end="")
        if (n % 8) == 7:
            print()
        else:
            print(",", end="")
        n += 1
print("")
print("DAISY_LEN\tEQU\t$-DAISY")


