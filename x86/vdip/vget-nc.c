#include <stdio.h>
#ifndef MULTIBUS
#include <stdlib.h>
#include <string.h>
#endif
#define EXTERN 
#include "vutil.h"
#include "vinc.h"
#define BUFFSIZE 256
#define FSLEN 20
char rwbuffer[BUFFSIZE];
char srcfile[FSLEN], destfile[FSLEN];
vcget(source, dest)
char *source, *dest;
{
  FILE *channel;
  int nblocks, nbytes, i, rc, done;
  long filesize;
  char fsize[15];
  rc = 0;
  if (vdirf(source, &filesize) == -1) {
    printf("Unable to open file %s\n", source);
    rc = -1;
  } else {
    commafmt(filesize, fsize, 15);
    printf("USB:%-12s  %s bytes --> ", source, fsize);
    nblocks = filesize/BUFFSIZE;
    nbytes = filesize % BUFFSIZE;
    if (vropen(source) == -1) {
      printf("\nUnable to open source file %s\n", source);
      rc = -1;
    }
    else if ((channel = fopen(dest, "wb")) == 0) {
      printf("\nError opening destination file %s\n", dest);
      rc = -1;
    }
    else {
      for (done=FALSE, i=1; ((i<=nblocks) && (!done)); i++) {
        if (vread(rwbuffer, BUFFSIZE) == -1) {
          printf("\nError reading block %d\n", i);
          done = TRUE;
          rc = -1;
        }
        else if ((fwrite(rwbuffer, 1, BUFFSIZE, channel) != BUFFSIZE)) {
          printf("\nError writing to %s\n", dest);
          rc = -1;
          done = TRUE;
        }
      }
      for (i=0; i<BUFFSIZE; i++)
        rwbuffer[i]=0;
      if ((nbytes > 0) && !done) {
        if (vread(rwbuffer, nbytes) == -1) {
          printf("Error reading final block\n");
          rc = -1;
        }
        else if ((fwrite(rwbuffer, 1, nbytes, channel) != nbytes)) {
          printf("\nError writing to %s\n", dest);
          rc = -1;
        }
      }
      printf("%-12s\n", dest);
      vclose(source);
      fclose(channel);
    }
  }
  return rc;
}
dofiles(argc, argv)
int argc;
char *argv[];
{
  int i, havedest, cindex;
  char *s;
  havedest = FALSE;
  strcpy(srcfile, argv[1]);
  for (i=2; (i<argc) && (!havedest); i++) {
    s = argv[i];
    if (*s != '-') {
      havedest = TRUE;
      if ((cindex = myindex(s, ":")) == -1)
        strncpy(destfile, s, FSLEN-1);
      else if (s[cindex+1] == '\0') {
        strcpy(destfile, s);
        strcat(destfile, srcfile);
      }
      else
        strncpy(destfile, s, FSLEN-1);
    }
  }
  if (!havedest)
    strcpy(destfile, srcfile);
}
dosw(argc, argv)
int argc;
char *argv[];
{
  int i;
  char *s;
  p_data = VDATA;
  p_stat = VSTAT;
  for (i=argc-1; i>1; i--) {
    s = argv[i];
    if (*s++ == '/') {
      switch (*s) {
      case 'P':
        ++s;
        p_data = param_to_i(s);
        break;
      case 'S':
        ++s;
        p_stat = param_to_i(s);
        break;
      default:
          printf("Invalid switch %c\n", *s);
        break;
      }
    }
  }
}
int main(argc,argv)
int argc;
char *argv[];
{
  if (argc < 2) {
    printf("Usage: VGET usbfile {local} <-pxxx>\n");
    printf("\tlocal is local drive and/or filespec\n");
    printf("\txxx is USB optional port in octal (default is %o)\n", VDATA);
    return -1;
  }
  dosw(argc, argv);
  dofiles(argc, argv);
  printf("VGET v4 [%o]\n", p_data);
  if (vinit() == -1) {
    printf("Error initializing VDIP-1 device!\n");
    return -1;
  }
  if (vfind_disk() == -1) {
    printf("No flash drive found!\n");
    return -1;
  }
  vcget(srcfile, destfile);
  return 0;
}
