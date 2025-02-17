# Path to the ISIS simulator, which you can find at:
# https://bionic.bloovis.com/cgit/isis/. The simulator is written
# by Mark Alexander and allows native ISIS-II tools to be run
# from Linux (or Windows?) making compiling easy.

ISIS=../simulator/isis/gnu/isis

# Most of the stuff compiles with native ISIS tools, except Nascome
# Basic, which uses the AZZ toolchain. 

ZCC = ../../z88dk/bin/zcc

# So ZCC can find its assembler...

export PATH := $(PATH):../../z88dk/bin
export ZCCCFG := ../../z88dk/lib/config

all: world.hex brtprm.hex maze.hex hang.hex

# .PHONY: env

export ISIS_F1=../simulator/isis/intel/plm80
export ISIS_F2=../simulator/isis/intel/utils
export ISIS_F3=../simulator/isis/intel/asm80

world.obj:
	rm -f world.tmp world.asm
	$(ZCC) +isis world.c -o world.tmp
	python3 ../asm/makeisis.py < world.tmp > world.asm
	unix2dos world.asm
	$(ISIS) :f3:asm80 world.asm

world: world.obj
	rm -f world.map
	$(ISIS) :f2:link world.obj,syspds.lib to world.lnk MAP
	$(ISIS) :f2:locate world.lnk to world PURGE MAP PRINT\(world.map\)

world-run: world
	$(ISIS) world arg1 arg2 arg3

world.hex: world
	$(ISIS) :f2:objhex world to world.hex

brtprm.obj:
	rm -f brtprm.tmp brtprm.asm
	$(ZCC) +isis brtprm.c -o brtprm.tmp
	python3 ../asm/makeisis.py < brtprm.tmp > brtprm.asm
	unix2dos brtprm.asm
	$(ISIS) :f3:asm80 brtprm.asm

brtprm: brtprm.obj
	rm -f brtprm.map
	$(ISIS) :f2:link brtprm.obj,syspds.lib to brtprm.lnk MAP
	$(ISIS) :f2:locate brtprm.lnk to brtprm PURGE MAP PRINT\(brtprm.map\)

brtprm-run: brtprm
	$(ISIS) brtprm

brtprm.hex: brtprm
	$(ISIS) :f2:objhex brtprm to brtprm.hex

maze.obj:
	rm -f maze.tmp maze.asm
	$(ZCC) +isis maze.c -o maze.tmp
	python3 ../asm/makeisis.py < maze.tmp > maze.asm
	unix2dos maze.asm
	$(ISIS) :f3:asm80 maze.asm

maze: maze.obj
	rm -f maze.map
	$(ISIS) :f2:link maze.obj,syspds.lib to maze.lnk MAP
	$(ISIS) :f2:locate maze.lnk to maze PURGE MAP PRINT\(maze.map\)

maze-run: maze
	$(ISIS) maze

maze.hex: maze
	$(ISIS) :f2:objhex maze to maze.hex

hang.obj:
	rm -f hang.tmp hang.asm
	$(ZCC) +isis hang.c -o hang.tmp
	python3 ../asm/makeisis.py < hang.tmp > hang.asm
	unix2dos hang.asm
	$(ISIS) :f3:asm80 hang.asm

hang: hang.obj
	rm -f hang.map
	$(ISIS) :f2:link hang.obj,syspds.lib to hang.lnk MAP
	$(ISIS) :f2:locate hang.lnk to hang PURGE MAP PRINT\(hang.map\)

hang-run: hang
	$(ISIS) hang

hang.hex: hang
	$(ISIS) :f2:objhex hang to hang.hex

clean:
	rm -f *.hex *.obj *.lnk *.map *.lst *.tmp *.lis world brtprm maze hang
