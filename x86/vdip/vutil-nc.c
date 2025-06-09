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
int btod(b)
char b;
{
  return ((b & 0xF0) >> 4) * 10 + (b & 0x0F);
}
int dtob(b)
char b;
{
  return ((b/10) << 4) | (b % 10);
}
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
int commafmt(n, s, len)
long n;
char *s;
int len;
{
  char *p;
  int i;
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
int isprint(c)
char c;
{
  return ((c>0x1F) && (c<0x7F));
}
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
int prntime(utime)
unsigned utime;
{
  unsigned hr, min, sec;
  char *am_pm;
  sec = 2*(utime & 0x1f);
  min = (utime >> 5) & 0x3f;
  hr = (utime >> 11) & 0x1f;
  if (hr > 12) {
    am_pm = "PM";
    hr = hr - 12;
  }
  else
    am_pm = "AM";
  printf("%2d:%02d %s", hr, min, am_pm);
  return 0;
}
