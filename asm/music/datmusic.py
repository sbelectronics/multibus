import sys

psgmode = ("PSG" in sys.argv)
if psgmode:
    print("PSG MODE")
    vol=0x0F
    sil=0
else:
    vol=0;
    sil=0x0F

def nconv(freq):
  if freq==0:
    return 0
  if psgmode:
      return int(2000000.0/16.0/freq)
  else:
      return int(3579545.0/(32.0*freq))

def dodat(fn):
    lines = open(fn, "rt").readlines()
    quad = []
    for line in lines:
        line=line.strip()
        if "DATA" not in line:
            continue
        line = line.split("DATA")[1].strip()
        vals = line.split(",")
        vals = [int(x.strip()) for x in vals]
        for val in vals:
            quad = quad + [val]
            if len(quad)==4:
                if quad[2]==0:
                    print("\tDW\t%d, %d, %d, %d, %d, %d, %d" % (quad[0], nconv(quad[1]), vol, 0, sil, 0, sil))
                elif quad[3]==0:
                    print("\tDW\t%d, %d, %d, %d, %d, %d, %d" % (quad[0], nconv(quad[1]), vol, nconv(quad[2]), vol, 0, sil))
                else:
                    print("\tDW\t%d, %d, %d, %d, %d, %d, %d" % (quad[0], nconv(quad[1]), vol, nconv(quad[2]), vol, nconv(quad[3]), vol))
                quad = []
    print("\tDW\t0,0,0,0")

print("MAXEL:")
dodat("axelf.bas")

print("BIRTHDAY:")
dodat("birthday.bas")
