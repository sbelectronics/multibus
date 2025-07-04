/*
 * https://www.tuhs.org/cgi-bin/utree.pl?file=pdp11v/usr/src/cmd/sum.c
 *
 * Sum bytes in file mod 2^16
 * 
 * cc86 sum.c include(:sd:inc/) define(multibus)
 * link86 sum.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to sum BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP
 */

char xxxnotused[] = "@(#)sum.c	1.4";

#define WDMSK 0177777L
#include <stdio.h>
struct part {
	short unsigned hi,lo;
};
union hilo { /* this only works right in case short is 1/2 of long */
	struct part hl;
	long	lg;
} tempa, suma;

int main(argc,argv)
int argc;
char **argv;
{
	register unsigned sum;
	register int i, c;
	register FILE *f;
	register long nbytes;
	int	alg, ca, errflg = 0;
	unsigned lsavhi,lsavlo;

	alg = 0;
	i = 1;
	if(argv[1][0]=='-' && argv[1][1]=='r') {
		alg = 1;
		i = 2;
	}

	do {
		if(i < argc) {
			if((f = fopen(argv[i], "rb")) == NULL) {
				(void) fprintf(stderr, "sum: Can't open %s\n", argv[i]);
				errflg += 10;
				continue;
			}
		} else
			f = stdin;
		sum = 0;
		suma.lg = 0;
		nbytes = 0;
		if(alg == 1) {
			while((c = getc(f)) != EOF) {
				nbytes++;
				if(sum & 01)
					sum = (sum >> 1) + 0x8000;
				else
					sum >>= 1;
				sum += c;
				sum &= 0xFFFF;
			}
		} else {
			while((ca = getc(f)) != EOF) {
				nbytes++;
				suma.lg += ca & WDMSK;
			}
		}
		if(ferror(f)) {
			errflg++;
			(void) fprintf(stderr, "sum: read error on %s\n", argc>1?argv[i]:"-");
		}
		if (alg == 1)
			(void) printf("%.5u%6ld", sum, (nbytes+BUFSIZ-1)/BUFSIZ);
		else {
			tempa.lg = (suma.hl.lo & WDMSK) + (suma.hl.hi & WDMSK);
			lsavhi = (unsigned) tempa.hl.hi;
			lsavlo = (unsigned) tempa.hl.lo;
			(void) printf("%u %ld", (unsigned)(lsavhi + lsavlo), (nbytes+BUFSIZ-1)/BUFSIZ);
		}
		if(argc > 1)
			(void) printf(" %s", argv[i]==(char *)0?"":argv[i]);
		(void) printf("\n");
		(void) fclose(f);
	} while(++i < argc);
	exit(errflg);
}
