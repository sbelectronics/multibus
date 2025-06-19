asm86 ports.a86

cc86 vinc.c include(:sd:inc/) define(multibus)
cc86 vutil.c include(:sd:inc/) define(multibus)
cc86 vget.c include(:sd:inc/) define(multibus)
link86 vget.obj,vinc.obj,vutil.obj,ports.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to vget BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP

cc86 vdir.c include(:sd:inc/) define(multibus)
link86 vdir.obj,vinc.obj,vutil.obj,ports.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to vdir BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP

cc86 vcd.c include(:sd:inc/) define(multibus)
link86 vcd.obj,vinc.obj,vutil.obj,ports.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to vcd BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP

cc86 vput.c include(:sd:inc/) define(multibus)
link86 vput.obj,vinc.obj,vutil.obj,ports.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to vput BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP