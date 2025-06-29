# Target. Set this to either idps or rambrd. This will determine
# which port range is used for the multimodules.

TARGET ?= unspecified

# Path to the ISIS simulator, which you can find at:
# https://bionic.bloovis.com/cgit/isis/. The simulator is written
# by Mark Alexander and allows native ISIS-II tools to be run
# from Linux (or Windows?) making compiling easy.

ISIS=../simulator/isis/gnu/isis

# Mark Ogden's C-Ports used to build these files. To install these yourself,
# visit https://github.com/ogdenpm/c-ports. Download the tools and go into the
# Linux directory and run the Makefile.

ASMTOOL=../../ipds/ogden/c-ports/Linux/Install/asm80
LIBTOOL=../../ipds/ogden/c-ports/Linux/Install/lib
LINKTOOL=../../ipds/ogden/c-ports/Linux/Install/link
LOCATETOOL=../../ipds/ogden/c-ports/Linux/Install/locate
OBJHEXTOOL=../../ipds/ogden/c-ports/Linux/Install/objhex

# These alternatives could be used instead to use actual ISIS commands under
# the emulator

#ASMTOOL=$(ISIS) :f3:asm80
#LIBTOOL=$(ISIS) :f2:lib
#LINKTOOL=$(ISIS) :f2:link
#LOCATETOOL=$(ISIS) :f2:locate
#OBJHEXTOOL=$(ISIS) :f2:objhex

# Most of the stuff compiles with native ISIS tools, except Nascome
# Basic, which uses the AZZ toolchain. 

ZCC = ../../z88dk/bin/zcc

# So ZCC can find its assembler...

export PATH := $(PATH):../../z88dk/bin

all: forth.hex hello.hex life.hex argtes.hex basic.hex song.hex aysong.hex bong.hex memtes.hex deltes.hex til311.hex rtc.hex drives.hex gps.hex nixclk.hex dig.hex votrax.hex sertes.hex coptes.hex tms.hex

# .PHONY: env

export ISIS_F1=../simulator/isis/intel/plm80
export ISIS_F2=../simulator/isis/intel/utils
export ISIS_F3=../simulator/isis/intel/asm80

.PHONY: ports
.PHONY: ipds
.PHONY: rambrd

unspecified:
	@echo "Please set TARGET to either ipds or rambrd"
	@exit 1

ipds:
	echo "; edit ipds.inc instead of this file" > ports.inc
	cat ipds.inc >> ports.inc
	cp ports.inc PORTS.INC

rambrd:
	echo "; edit rambrd.inc instead of this file" > ports.inc
	cat rambrd.inc >> ports.inc
	cp ports.inc PORTS.INC

ports: $(TARGET)

forth : forth.obj conio.obj
	$(LINKTOOL) forth.obj,conio.obj,syspds.lib to forth.lnk
	$(LOCATETOOL) forth.lnk to forth MAP PRINT\(forth.map\)

forth.hex: forth
	$(OBJHEXTOOL) forth to forth.hex

forth-run:
	$(ISIS) -l  forth

forth.obj: forth.asm
	$(ASMTOOL) forth.asm

tforth: tforth.obj conio.obj
	$(LINKTOOL) tforth.obj,conio.obj,syspds.lib to tforth.lnk
	$(LOCATETOOL) tforth.lnk to tforth MAP PRINT\(tforth.map\)

tforth.hex: tforth
	$(OBJHEXTOOL) tforth to tforth.hex

tforth-run: tforth
	$(ISIS) -l tforth

tforth.obj: tforth.asm
	$(ASMTOOL) tforth.asm

tforth.rom: tforth.asm
	sed 's:PROMP80\tEQU\t0:PROMP80\tEQU\t1:g' tforth.asm > tforth.tmp1
	sed 's:ISIS\tEQU\t1:ISIS\tEQU\t0:g' tforth.tmp1 > tforth.tmp2
	rm -rf zout
	zmac --dri -i -8 -c -s -n tforth.tmp2
	cp zout/tforth.cim tforth.rom
	rm -f tforth.tmp1 tforth.tmp2

swh.rom: swh.asm
	zmac --dri -i -8 -c -s -n swh.asm
	cp zout/swh.cim swh.rom

sp80.rom: sp80.asm
	zmac --dri -i -8 -c -s -n sp80.asm
	cp zout/sp80.cim sp80.rom

conio.obj: conio.asm
	$(ASMTOOL) conio.asm

putil.obj: putil.asm
	$(ASMTOOL) putil.asm

args.obj: args.asm
	$(ASMTOOL) args.asm

argtes.obj: argtes.asm
	$(ASMTOOL) argtes.asm

argtes: argtes.obj conio.obj args.obj putil.obj
	$(LINKTOOL) argtes.obj,conio.obj,args.obj,putil.obj,syspds.lib to argtes.lnk MAP
	$(LOCATETOOL) argtes.lnk to argtes PURGE MAP PRINT\(argtes.map\)

argtes-run:
	echo "--- everything FF"
	$(ISIS) argtes
	echo "--- A:00, B:00, C:00 D:7B E:E7 F:01 G:10 H:33 I:A3 J:01 K:00 L:00 M:00 N:00 O:FF P:FE Q:07 R:09 X:2C"
	$(ISIS) argtes A B C D123 E 231 F 001 G 0x10 H0X33 I0XA3 J 0x01 K 0 L 0x00 M N P 0XFE Q7R9 X 44

argtes.hex: argtes
	$(OBJHEXTOOL) argtes to argtes.hex

hello: hello.obj conio.obj
	$(LINKTOOL) hello.obj,conio.obj,syspds.lib to hello.lnk MAP
	$(LOCATETOOL) hello.lnk to hello PURGE MAP PRINT\(hello.map\)

hello.hex: hello
	$(OBJHEXTOOL) hello to hello.hex

hello-run:
	$(ISIS) hello

hello.obj: hello.asm
	$(ASMTOOL) hello.asm

memtes: memtes.obj conio.obj putil.obj
	$(LINKTOOL) memtes.obj,conio.obj,putil.obj,syspds.lib to memtes.lnk MAP
	$(LOCATETOOL) memtes.lnk to memtes PURGE MAP PRINT\(memtes.map\)

memtes.hex: memtes
	$(OBJHEXTOOL) memtes to memtes.hex

memtes-run:
	$(ISIS) memtes

memtes.obj: memtes.asm
	$(ASMTOOL) memtes.asm

life.obj: life.asm
	$(ASMTOOL) life.asm

life: life.obj args.obj
	$(LINKTOOL) life.obj,args.obj,syspds.lib to life.lnk MAP
	$(LOCATETOOL) life.lnk to life PURGE MAP PRINT\(life.map\)

life.hex: life
	$(OBJHEXTOOL) life to life.hex

life-run:
	$(ISIS) life

bong: bong.obj conio.obj csg.obj attach.obj
	$(LINKTOOL) bong.obj,conio.obj,csg.obj,attach.obj,syspds.lib to bong.lnk MAP
	$(LOCATETOOL) bong.lnk to bong PURGE MAP PRINT\(bong.map\)

bong.hex: bong
	$(OBJHEXTOOL) bong to bong.hex

bong-run:
	$(ISIS) bong

bong.obj: bong.asm
	$(ASMTOOL) bong.asm

song: song.obj conio.obj csg.obj args.obj attach.obj
	$(LINKTOOL) song.obj,conio.obj,csg.obj,args.obj,attach.obj,syspds.lib to song.lnk MAP
	$(LOCATETOOL) song.lnk to song PURGE MAP PRINT\(song.map\)

song.hex: song
	$(OBJHEXTOOL) song to song.hex

song-run:
	$(ISIS) song

song.obj: ports song.asm
	$(ASMTOOL) song.asm

aysong: aysong.obj conio.obj psg.obj args.obj attach.obj
	$(LINKTOOL) aysong.obj,conio.obj,psg.obj,args.obj,attach.obj,syspds.lib to aysong.lnk MAP
	$(LOCATETOOL) aysong.lnk to aysong PURGE MAP PRINT\(aysong.map\)

aysong.hex: aysong
	$(OBJHEXTOOL) aysong to aysong.hex

aysong-run:
	$(ISIS) aysong

aysong.obj: ports aysong.asm
	$(ASMTOOL) aysong.asm

csg.obj: ports csg.asm
	$(ASMTOOL) csg.asm

psg.obj: ports psg.asm
	$(ASMTOOL) psg.asm

attach.obj: attach.asm
	$(ASMTOOL) attach.asm

deltes: deltes.obj conio.obj csg.obj
	$(LINKTOOL) deltes.obj,conio.obj,csg.obj,syspds.lib to deltes.lnk MAP
	$(LOCATETOOL) deltes.lnk to deltes PURGE MAP PRINT\(deltes.map\)

deltes.hex: deltes
	$(OBJHEXTOOL) deltes to deltes.hex

deltes-run:
	$(ISIS) deltes

deltes.obj: deltes.asm
	$(ASMTOOL) deltes.asm

basic.obj:
	echo "nascom32k.asm" > nascom32k.lst
	rm -f basic.tmp basic.asm
	$(ZCC) +micro8085 -m8085 --no-crt -v -m --list -Ca-f0xFF @nascom32k.lst -o basic.tmp
	python3 ./makeisis.py < basic.tmp > basic.asm
	unix2dos basic.asm
	$(ASMTOOL) basic.asm

basic: basic.obj
	rm -f basic.map
	$(LINKTOOL) basic.obj,syspds.lib to basic.lnk MAP
	$(LOCATETOOL) basic.lnk to basic PURGE MAP PRINT\(basic.map\)

basic-run: basic
	$(ISIS) basic

basic.hex: basic
	$(OBJHEXTOOL) basic to basic.hex

til311: til311.obj conio.obj args.obj putil.obj
	$(LINKTOOL) til311.obj,conio.obj,args.obj,putil.obj,syspds.lib to til311.lnk MAP
	$(LOCATETOOL) til311.lnk to til311 PURGE MAP PRINT\(til311.map\)

til311.hex: til311
	$(OBJHEXTOOL) til311 to til311.hex

til311.obj: ports til311.asm
	$(ASMTOOL) til311.asm

rtc: rtc.obj conio.obj args.obj putil.obj rtclib.obj
	$(LINKTOOL) rtc.obj,conio.obj,args.obj,putil.obj,rtclib.obj,syspds.lib to rtc.lnk MAP
	$(LOCATETOOL) rtc.lnk to rtc PURGE MAP PRINT\(rtc.map\)

rtc.hex: rtc
	$(OBJHEXTOOL) rtc to rtc.hex

rtc.obj: ports rtc.asm
	$(ASMTOOL) rtc.asm

rtclib.obj: ports rtclib.asm
	$(ASMTOOL) rtclib.asm

gps: gps.obj conio.obj args.obj putil.obj gpslib.obj
	$(LINKTOOL) gps.obj,conio.obj,args.obj,putil.obj,gpslib.obj,syspds.lib to gps.lnk MAP
	$(LOCATETOOL) gps.lnk to gps PURGE MAP PRINT\(gps.map\)

gps.hex: gps
	$(OBJHEXTOOL) gps to gps.hex

gps.obj: ports gps.asm
	$(ASMTOOL) gps.asm

gpslib.obj: ports gpslib.asm
	$(ASMTOOL) gpslib.asm

nixclk: nixclk.obj conio.obj args.obj putil.obj gpslib.obj rtclib.obj diglib.obj tmslib.obj vm7tim.obj vm7dat.obj
	$(LINKTOOL) nixclk.obj,conio.obj,args.obj,putil.obj,gpslib.obj,rtclib.obj,diglib.obj,tmslib.obj,vm7tim.obj,vm7dat.obj,syspds.lib to nixclk.lnk map
	$(LOCATETOOL) nixclk.lnk to nixclk PURGE MAP PRINT\(nixclk.map\)
	
nixclk.hex: nixclk
	$(OBJHEXTOOL) nixclk to nixclk.hex

nixclk.obj: ports nixclk.asm
	$(ASMTOOL) nixclk.asm

dig: dig.obj conio.obj args.obj putil.obj diglib.obj
	$(LINKTOOL) dig.obj,conio.obj,args.obj,putil.obj,diglib.obj,syspds.lib to dig.lnk MAP
	$(LOCATETOOL) dig.lnk to dig PURGE MAP PRINT\(dig.map\)

dig.hex: dig
	$(OBJHEXTOOL) dig to dig.hex

dig.obj: ports dig.asm
	$(ASMTOOL) dig.asm

diglib.obj: ports diglib.asm
	$(ASMTOOL) diglib.asm

sertes.obj: ports sertes.asm
	$(ASMTOOL) sertes.asm

sertes: sertes.obj conio.obj args.obj putil.obj
	$(LINKTOOL) sertes.obj,conio.obj,args.obj,putil.obj,syspds.lib to sertes.lnk MAP
	$(LOCATETOOL) sertes.lnk to sertes PURGE MAP PRINT\(sertes.map\)

sertes.hex: sertes
	$(OBJHEXTOOL) sertes to sertes.hex

coptes.obj: coptes.asm
	$(ASMTOOL) coptes.asm

coptes: coptes.obj conio.obj putil.obj
	$(LINKTOOL) coptes.obj,conio.obj,putil.obj,syspds.lib to coptes.lnk MAP
	$(LOCATETOOL) coptes.lnk to coptes PURGE MAP PRINT\(coptes.map\)

coptes.hex: coptes
	$(OBJHEXTOOL) coptes to coptes.hex

drives.obj: drives.asm
	$(ASMTOOL) drives.asm

drives: drives.obj conio.obj putil.obj
	$(LINKTOOL) drives.obj,conio.obj,putil.obj,syspds.lib to drives.lnk MAP
	$(LOCATETOOL) drives.lnk to drives PURGE MAP PRINT\(drives.map\)

drives.hex: drives
	$(OBJHEXTOOL) drives to drives.hex

votrax: votrax.obj conio.obj args.obj putil.obj vtxlib.obj
	$(LINKTOOL) votrax.obj,conio.obj,args.obj,putil.obj,vtxlib.obj,syspds.lib to votrax.lnk MAP
	$(LOCATETOOL) votrax.lnk to votrax PURGE MAP PRINT\(votrax.map\)

votrax.hex: votrax
	$(OBJHEXTOOL) votrax to votrax.hex

votrax.obj: ports votrax.asm
	$(ASMTOOL) votrax.asm

vtxlib.obj: ports vtxlib.asm
	$(ASMTOOL) vtxlib.asm

tms: tms.obj conio.obj args.obj putil.obj tmslib.obj vm7dat.obj vm7tim.obj
	$(LINKTOOL) tms.obj,conio.obj,args.obj,putil.obj,tmslib.obj,vm7dat.obj,vm7tim.obj,syspds.lib to tms.lnk MAP
	$(LOCATETOOL) tms.lnk to tms PURGE MAP PRINT\(tms.map\)

tms.hex: tms
	$(OBJHEXTOOL) tms to tms.hex

tms.obj: ports tms.asm
	$(ASMTOOL) tms.asm

tmslib.obj: ports tmslib.asm
	$(ASMTOOL) tmslib.asm

vm7dat.obj: vm7dat.asm
	$(ASMTOOL) vm7dat.asm

vm7tim.obj: vm7tim.asm
	$(ASMTOOL) vm7tim.asm

clean:
	rm -f ports.inc PORTS.INC *.hex *.obj *.lnk *.map *.lst *.tmp *.lis forth hello life basic argtes bong wiltel song memtes deltes til311 aysong sertes rtc gps nixclk dig votrax coptes drives tms tforth
