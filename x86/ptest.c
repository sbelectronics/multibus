/*
asm86 ports.a86
cc86 ptest.c include(:sd:inc/)
link86 ptest.obj,ports.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to ptest.86 BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP
 */

#include <stdio.h>

void outp(); /* port, val) */
int inp(); /* port */

main() {
    outp(0x20, 0x34);  // needs to be send up again after modifying source code
    printf("input: %d\n", inp(0x20));
}
