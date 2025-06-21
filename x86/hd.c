/*
 * 
 * cc86 hd.c include(:sd:inc/) define(multibus)
 * link86 hd.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to hd BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP
 */


#define WDMSK 0177777L
#include <stdio.h>

int main(argc,argv)
int argc;
char **argv;
{
	register int i;
	register FILE *f;
	register long nbytes;
	int ncol;
	int	ca, errflg = 0;

	i = 1;

	do {
		if(i < argc) {
			if((f = fopen(argv[i], "rb")) == NULL) {
				(void) fprintf(stderr, "hd: Can't open %s\n", argv[i]);
				errflg += 10;
				continue;
			}
		} else
			f = stdin;

		nbytes = 0;
		ncol = 0;

		while((ca = getc(f)) != EOF) {
			if (ncol==0) {
				printf("%08X: ", (int) nbytes);
			}

			printf("%02X ", ca & 0xFF);
			nbytes++;

			if (++ncol >= 16) {
				ncol = 0;
				(void) printf("\n");
			}
		}

	    if (ncol>0) {
			(void) printf("\n");
		}
		(void) fclose(f);
	} while(++i < argc);
	exit(errflg);
}
