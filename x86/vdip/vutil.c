/********************************************************
** vutil.c
**
** Version 4.0 (beta)
**
** This library contains a set of general purpose utility
** routines which support the various needs for accessing
** the FTDI VDIP device. Routines cover four broad types
** of functions: Operating System functions, format conversion,
** string functions and time/date functions.
**
** This code is designed for use with the Software Toolworks C/80
** v. 3.1 compiler with the optional support for
** floats and longs.  The compiler should be configured
** to produce a Microsoft relocatable module (.REL file)
** file which can (optionally) be stored in a library
** (.LIB file) using the Microsoft LIB-80 Library Manager.
** The Microsoft LINK-80 loader program is then used to
** link this code, along with any other required modules,
** with the main (calling) program.
**
**  Glenn Roberts
**  3 January 2022
**
********************************************************/
#include <stdio.h>

#ifndef MULTIBUS
#include <stdlib.h>
#include <string.h>
#endif

#include "vinc.h"
#include "vutil.h"

#ifdef MULTIBUS
char *strstr(haystack, needle)
char *haystack;
char *needle;
{
    int i, j;
    char *start;

    for (i = 0; haystack[i]; i++)
    {
        for (j = 0; needle[j]; j++)
        {
            if (haystack[i + j] != needle[j])
            {
                break;
            }
        }

        if (needle[j] == '\0')
        {
            start = &haystack[i];
            return (start);
        }
    }
    return (NULL);
}
#endif

int myindex(s, pat)
char *s;
char *pat;
{
  char *p = strstr(s,pat);
  if (p==NULL) {
    return -1;
  } else {
    return p-s;
  }
}

/********************************************************
**
** btod
**
** convert a BCD byte to its decimal equivalent
**
********************************************************/
int btod(b)
char b;
{
  return ((b & 0xF0) >> 4) * 10 + (b & 0x0F);
}

/********************************************************
**
** dtob
**
** convert a Decimal byte to its BCD equivalent
**
********************************************************/
int dtob(b)
char b;
{
  return ((b/10) << 4) | (b % 10);
}

/********************************************************
**
** gethexvals
**
** Scan a string for values of the form $xx where xx
** is a hexadecimal upper case string, e.g. $34 $96 $8C ...
** Place these sequentially into the array of bytes provided.
** Search for at most n values and return the number found.
**
** NOTE: very minimal error checking is done!
**
********************************************************/
int gethexvals(s, n, val)
char *s;
int n;
char val[];
{
  int i;
  
  for (i=0; i<n ; i++) {
    while ((*s!='$') && (*s!=0))
      ++s;
    if (*s==0)
      return i;
    else
      val[i] = hexval(++s);
  }
  return i;
}

void endian_flip(c, n)
unsigned char *c;
unsigned int n;
{
  char tmp[8];
  int i;

  for (i=0; i<n; i++) {
    tmp[i] = c[i];
  }

  for (i=0; i<n; i++) {
    c[i] = tmp[n-i-1];
  }
}

/********************************************************
**
** hexval
**
** Turn a two-byte upper case ASCII hex string into its
** binary representation.
**
** NOTE: no error checking is done (e.g. for non-hexadecimal
** characters).
**
********************************************************/
int hexval(s)
char *s;
{
  int n1, n2;
  
  n1 = *s++ - '0';
  if (n1>9)
    n1 -= 7;
  n2 = *s - '0';
  if (n2>9)
    n2 -= 7;
  return (n1<<4) + n2;
}

/********************************************************
**
** hexcat
**
** Converts unsigned int i to a 2 byte hexadecimal
** representation in upper case ASCII and then catenates 
** that to the end of string s
**
********************************************************/
int hexcat(s, i)
char *s;
unsigned i;
{
  static char b[3];
  unsigned n;
  
  n = (i & 0xFF) >> 4;
  b[0] = (n < 10) ? '0'+n : 'A'+n-10;
  n = i & 0xF;
  b[1] = (n < 10) ? '0'+n : 'A'+n-10;
  b[2] = '\0';
  strcat(s, b);
  return 0;
}

/********************************************************
**
** commafmt
**
** Create a string containing the representation of a 
** long with commas every third position.  len is the
** allocated size of the string s. caution: len must 
** be declared big enough to hold any long.
**
********************************************************/
int commafmt(n, s, len)
long n;
char *s;
int len;
{
  char *p;
  int i;

  /* work backward from end of string */
  p = s + len - 1;
  *p = 0;

  i = 0;
  do {
    if(((i % 3) == 0) && (i != 0))
      *--p = ',';
    *--p = '0' + (n % 10);
    n /= 10;
    i++;
  } while(n != 0);

  /* pad the front with blanks */
  while (p != s)
    *--p = ' ';

  return 0;
}

#ifdef MULTIBUS
int param_to_i(s)
char *s;
{
  if ((*s=='0') && (*s+1=='x' || *s+1=='X')) {
    return hexval(s+2);
  } else {
    return atoi(s);
  }
}

#else

int param_to_i(s)
char s[];
{
    unsigned long n;
    char *endptr;
    n = strtoul(s, &endptr, 0);
    if (*endptr) {
        fprintf(stderr, "invalid number!\n");
        exit(-1);
    }

    return (int) n;
}
#endif


/********************************************************
**
** isprint
**
** return TRUE if printable character 
**
********************************************************/
int isprint(c)
char c;
{
  return ((c>0x1F) && (c<0x7F));
}

/********************************************************
**
** prndate
**
** This routine extracts the month, day and year information
** from a 16-bit word stored using the Microsoft FAT format:
**
**  9:15  Year  0..127  (0=1980, 127=2107)
**  5:8   Months  1..12 (1=Jan., 12=Dec.)
**  0:4   Days  1..31 (1=first day of mo.)
**
** Files stored on the USB file device use this date format,
** as documented in the FTDI Vinculum Firmware User Manual.
**
** The results are displayed  on the standard output device.
**
********************************************************/
int prndate(udate)
unsigned udate;
{
  unsigned mo, dy, yr;
  
  dy = udate & 0x1f;
  mo = (udate >> 5) & 0xf;
  yr = 1980 + ((udate >> 9) & 0x7f);
  
  printf("%2d/%02d/%02d", mo, dy, (yr % 100));

  return 0;
}

/********************************************************
**
** prntime
**
** This routine extracts the time information (hour and minute)
** from a 16-bit word stored using the Microsoft FAT format:
**
**  11:15   Hours 0..23   (24 hour clock)
**  5:10  Minutes 0..59
**  0:4   Sec./2  0..29   (0=0, 29=58 sec.)
**
** Files stored on the USB file device use this time format,
** as documented in the FTDI Vinculum Firmware User Manual.
**
** The results are displayed on the standard output device.
** A 12-hour clock format is used including "AM" or "PM".
**
********************************************************/
int prntime(utime)
unsigned utime;
{
  unsigned hr, min, sec;
  char *am_pm;
  
  sec = 2*(utime & 0x1f);
  min = (utime >> 5) & 0x3f;
  hr  = (utime >> 11) & 0x1f;
  if (hr > 12) {
    am_pm = "PM";
    hr = hr - 12;
  }
  else
    am_pm = "AM";
  
  printf("%2d:%02d %s", hr, min, am_pm);

  return 0;
}
