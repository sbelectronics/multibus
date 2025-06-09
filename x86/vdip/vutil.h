/********************************************************
** vutil.h
**
** template definitions for vutil library, plus useful
** shared values.
**
**      2 February 2022
**      Glenn Roberts
**
********************************************************/
#ifndef EXTERN
#define EXTERN extern
#endif

/* Define either HDOS or CPM here to cause appropriate 
** routines to be compiled.  If none is defined CPM is 
** assumed. Your code must call routine getosver() to 
** set osname and osver, which are used at run time to
** ensure the appropriate code segments are invoked.
**
** Also: HDOS files should be saved with unix style NL 
** line endings; CP/M files require MS-DOS style CR-LF
** line endings.
*/
/* #define      CPM     1 ** done on commandline */

#define NUL     '\0'
#define TRUE    1
#define FALSE   0

int myindex();

/* format conversion */
int btod();
int dtob();
int gethexvals();
int hexval();
int hexcat();
int commafmt();

void endian_flip();

int param_to_i();

int prndate();
int prntime();

/* string functions */
int isprint();

