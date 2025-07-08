/*
 * dtload
 * Scott Baker, https://www.smbaker.com/
 *
 * Load ROM to national semiconductor digitalker DT-2000 board
 * 
 * cc86 dtload.c include(:sd:inc/) define(multibus)
 * link86 dtload.obj,ports.obj,/lib/cc86/sqmain.obj,/lib/cc86/sclib.lib,/lib/small.lib,/lib/cc86/87null.lib to dtload BIND SEGSIZE(STACK(2000H),MEMORY(5000H)) MAP
 */


#include <stdio.h>

#define PORT_BASE 0x80
#define PORT_SPC PORT_BASE
#define PORT_CONTROL PORT_BASE+2
#define PORT_STATUS PORT_BASE+3
#define PORT_LOADDR PORT_BASE+4
#define PORT_HIADDR PORT_BASE+5
#define PORT_RDW PORT_BASE+6

#define WRT_HLD 0x40

char buf[4096];

void copyFile(srcName, destName)
char *srcName;
char *destName;
{
	FILE *src, *dest;
	int bread;

	src = fopen(srcName, "r");
	if (src == NULL) {
		fprintf(stderr, "dtload: Can't open vocabulary src file %s\n", srcName);
		return;
	}

	dest = fopen(destName, "w");
	if (dest == NULL) {
		fprintf(stderr, "dtload: Can't open vocabulary dest file %s\n", destName);
		fclose(src);
		return;
	}

	while ((bread=fread(buf, 1, sizeof(buf), src)) > 0) {
		fwrite(buf, 1, bread, dest);
	}

	fclose(src);
	fclose(dest);

	fprintf(stdout, "Copied vocabulary from %s to %s\n", srcName, destName);
}

int main(argc,argv)
int argc;
char **argv;
{
	register int offset, bread;
	register FILE *f;
	char filename[100];

	if (argc < 2) {
		fprintf(stderr, "Usage: %s name\n", argv[0]);
		return 1;
	}

	strcpy(filename, argv[1]);
	strcpy(filename + strlen(filename), ".bin");

	f = fopen(filename, "rb");
	if (f == NULL) {
		fprintf(stderr, "dtload: Can't open %s\n", filename);
		return 1;
	}

	if ((inp(PORT_STATUS) & WRT_HLD) == 0) {
		fprintf(stdout, "write hold\n");
		while ((inp(PORT_STATUS) & WRT_HLD)==0) {
			/* wait for write hold to clear */
		}
	}

	offset = 0;
	while ((bread=fread(buf, 1, sizeof(buf), f)) > 0) {
		int i;
		for (i=0; i<bread; i++) {
			outp(PORT_LOADDR, offset & 0xFF);
			outp(PORT_HIADDR, (offset >> 8) & 0xFF);
			outp(PORT_RDW, buf[i]);
			offset++;
		}
	}

	fprintf(stdout, "Loaded %d bytes from %s\n", offset, filename);
    fclose(f);

    /* If there's a vocabulary file, then copy it too */
	strcpy(filename, argv[1]);
	strcpy(filename + strlen(filename), ".voc");
	copyFile(filename, "dt2000.voc");

	return 0;
}
