/*
 * dtsay
 * Scott Baker, https://www.smbaker.com/
 *
 * Speak works on national semiconductor digitalker DT-2000 board
 * 
 * cc86 dtsay.c include(:sd:inc/) define(multibus)
 * link86 dtsay.obj,ports.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to dtsay BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP
 */

#ifdef LINUX
#include <string.h>
#include <stdlib.h>
#endif


#include <stdio.h>

#define PORT_BASE 0x80
#define PORT_SPC PORT_BASE
#define PORT_CONTROL PORT_BASE+2
#define PORT_STATUS PORT_BASE+3
#define PORT_LOADDR PORT_BASE+4
#define PORT_HIADDR PORT_BASE+5
#define PORT_RDW PORT_BASE+6

#define INT_ENB 0x01
#define CMS 0x02
#define WRT_HLD 0x40
#define INTR 0x80

int numVocab;
char *vocab[255];

void trimStr(s)
char *s;
{
	char *p;

    /* Trim trailing whitespace */
	p = s + strlen(s) - 1;
	while (p > s && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) {
		*p-- = '\0';
	}
}

void loadVocab(fn)
char *fn;
{
	FILE *f;
	char s[80];

	f = fopen(fn, "r");
	if (f == NULL) {
		fprintf(stderr, "dtsay: Can't open vocab file %s\n", fn);
		return; /* non-fatal exit */
	}

	while (fgets(s, 80, f) != NULL) {
		trimStr(s);
		vocab[numVocab] = malloc(strlen(s) + 1);
		if (vocab[numVocab] == NULL) {
			fprintf(stderr, "dtsay: Memory allocation error\n");
			exit(1);
		}
		strcpy(vocab[numVocab], s);
		numVocab++;
		if (numVocab >= 255) {
			fprintf(stderr, "dtsay: Vocabulary limit reached\n");
			break;
		}
	}
}

int findVocab(s)
char *s;
{
	int i;

	for (i = 0; i < numVocab; i++) {
		if (strcmp(vocab[i], s) == 0) {
			return i;
		}
	}

    if (s[0] >= '0' && s[0] <= '9') {
		/* If the string is a number, return it as an integer */
		return atoi(s);
	}

	fprintf(stderr, "dtsay: Word '%s' not found in vocabulary and is not a number\n", s);
    exit(1);
}


int main(argc,argv)
int argc;
char **argv;
{
	register int c, i;
	int debug;
	int vocabLoaded = 0;
	char *vocabFileName = "dt2000.voc";

	debug = 0;
	numVocab = 0;

	for (i = 1; i<argc; i++) {
        if (strcmp(argv[i], "-d") == 0) {
			debug = 1;
			continue;
		}

		if (strcmp(argv[i], "-v") == 0) {
			if (i + 1 < argc) {
				vocabFileName = argv[++i];
			} else {
				fprintf(stderr, "dtsay: -v used but no vocabulary file specified\n");
				return 1;
			}
			continue;
		}

		if (strcmp(argv[i], "-l") == 0) {
			if (numVocab == 0) {
				fprintf(stderr, "dtsay: No vocabulary loaded\n");
				return 1;
			}
			for (c = 0; c < numVocab; c++) {
				fprintf(stdout, "%d: %s\n", c, vocab[c]);
			}
			return 0;
		}

		/* wait for speech to be idle */
		if ((inp(PORT_STATUS) & INTR) == INTR) {
			if (debug) {
			    fprintf(stdout, "wait\n");
			}
			while ((inp(PORT_STATUS) & INTR) == INTR) {
				/* wait for write hold to clear */
			}
		}

		if (debug) {
			fprintf(stdout, "speak: %s\n", argv[i]);
		}

		if (!vocabLoaded) {
			loadVocab(vocabFileName);
			vocabLoaded = 1;
		}

		c = findVocab(argv[i]);
		if (c < 0) {
			c = atoi(argv[i]);
		}

		if (debug) {
			fprintf(stdout, "speak word: %d\n", c);
		}
		outp(PORT_SPC, c & 0xFF);
	}

	return 0;
}
