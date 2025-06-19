asm86 ports.a86
cc86 lbforth.c include(:sd:inc/) define(multibus)
link86 lbforth.obj,ports.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to lbforth BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP
