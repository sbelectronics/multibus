#include <stdio.h>
#include "vutil.h"
#include "vinc.h"
#ifdef H8_80186
#include <string.h>
#include <process.h>
#include <conio.h>
#else
#ifdef OLIVETTI
#include <sys/pcos.h>
#include "oliport.h"
#else
#endif
#endif
#ifdef OLIVETTI
unsigned int get_sec()
{
  char buf[12];
  _pcos_gettime(buf,11);
  return buf[7]-'0';
}
#endif
void break_check()
{
#ifdef OLIVETTI
  int r;
  unsigned char b;
  unsigned char bs;
  r = _pcos_lookbyte(DID_CONSOLE, &b, &bs);
  if ((r==0) && (bs==0xFF) && (b==3)) {
    fprintf(stderr,"CTRL-C\n");
    exit(-1);
  }
#endif
}
int str_send(s)
char *s;
{
  char *c;
  int rc;
#ifdef DEBUG
  printf("->str_send %s\n", s);
#endif
  rc = 0;
  for (c=s; ((*c!=0) && (rc!=-1)); c++)
    rc = out_vwait(*c, MAXWAIT);
  return rc;
}
int str_rdw(s, tchar)
char *s;
char tchar;
{
  int c, rc;
  int timedout;
  timedout = FALSE;
  rc = 0;
  do {
    if((c = in_vwait(MAXWAIT)) == -1)
      timedout = TRUE;
    else {
      if (c == tchar)
        c = 0;
      *s++ = c;
    }
  } while ((c != 0) && (!timedout));
  if (timedout) {
    *s = 0;
    rc = -1;
  }
  return rc;
}
int in_v()
{
  int b;
  if ((inp(p_stat) & VRXF) != 0) {
    b = inp(p_data);
    return b;
  }
  else
    return -1;
}
int out_v(c)
char c;
{
  while ((inp(p_stat) & VTXE) == 0) {
    break_check();
  }
  outp(p_data,c);
  return 0;
}
int in_vwait(t)
int t;
{
    int v;
    unsigned long counter;
    counter = ((unsigned long) t) * 25000L;
    while ((inp(p_stat) & VRXF) == 0) {
      counter-=1;
      if (counter==0) {
        return -1;
      }
    }
    v=in_v();
    return v;
}
int out_vwait(c,t)
char c;
int t;
{
  unsigned long counter;
  counter = ((unsigned long) t) * 25000L;
  while ((inp(p_stat) & VTXE) == 0) {
    counter-=1;
    if (counter==0) {
      return -1;
    }
  }
  outp(p_data,c);
  return 0;
}
int vfind_disk()
{
  str_send("\r");
  return vprompt();
}
int vpurge()
{
  int c;
  do {
    c = in_vwait(1);
  } while (c != -1);
  return 0;
}
int vhandshake()
{
  int rc;
  if (str_send("E\r") == -1)
    rc = -1;
  else if (str_rdw(linebuff, '\r') == -1)
    rc = -1;
  else if (strcmp(linebuff,"E") != 0)
    rc = -1;
  else
    rc = 0;
  return rc;
}
int vinit()
{
  int rc;
  rc = 0;
  if (vsync() == -1)
    rc = -1;
  else {
    rc = vipa();
    if (rc == 0)
      rc = vclf();
  }
  return rc;
}
int vsync()
{
  int i, rc;
  rc = -1;
  for (i=0; i<3; i++) {
    vpurge();
    if (vhandshake()==0) {
      rc = 0;
      break;
    }
  }
  return rc;
}
int vdirf(s, len)
char *s;
long *len;
{
  int rc;
  char *c;
  static union u_fil flen;
  rc = 0;
  str_send("dir ");
  str_send(s);
  str_send("\r");
  str_rdw(linebuff, '\r');
  str_rdw(linebuff, '\r');
  if (strcmp(linebuff, CFERROR) == 0) {
    rc = -1;
  }
  else {
    for (c=linebuff; ((*c!=' ') && (*c!=0)); c++)
      ;
    gethexvals(c, 4, &flen.b[0]);
#ifdef ENDIAN_FLIP
    endian_flip(&flen, 4);
#endif
    *len = flen.l;
    str_rdw(linebuff, '\r');
  }
  return rc;
}
int vdird(s, udate, utime)
char *s;
unsigned *udate, *utime;
{
  int i, rc;
  char *c;
  static union u_fil fdate;
  static char dates[10];
  rc = 0;
  str_send("dirt ");
  str_send(s);
  str_send("\r");
  str_rdw(linebuff, '\r');
  str_rdw(linebuff, '\r');
  if (strcmp(linebuff, CFERROR) == 0) {
    rc = -1;
  }
  else {
    for (c=linebuff; ((*c!=' ') && (*c!=0)); c++)
      ;
    gethexvals(c, 10, dates);
    for (i=0; i<4; i++)
      fdate.b[i] = dates[i+6];
    *utime = fdate.i[0];
    *udate = fdate.i[1];
    str_rdw(linebuff, '\r');
  }
  return rc;
}
int vprompt()
{
#ifdef DEBUG
  printf("->vprompt\n");
#endif
  if (str_rdw(linebuff, '\r') == -1)
    return -1;
  else if (strcmp(linebuff, PROMPT) != 0 )
    return -1;
  else
    return 0;
}
int vropen(s)
char *s;
{
  vclf();
  str_send("opr ");
  str_send(s);
  str_send("\r");
  return vprompt();
}
int vwopen(s)
char *s;
{
  vclf();
  str_send("opw ");
  str_send(s);
  str_send(td_string);
  str_send("\r");
  return vprompt();
}
char *itoa(i, buf)
int i;
char *buf;
{
    sprintf(buf,"%d",i);
    return buf;
}
int vseek(p)
int p;
{
  static char fpos[7];
  str_send("sek ");
  str_send(itoa(p, fpos));
  str_send("\r");
  return vprompt();
}
int vclose(s)
char *s;
{
  str_send("clf ");
  str_send(s);
  str_send("\r");
  return vprompt();
}
int vclf()
{
  str_send("clf\r");
  return vprompt();
}
int vipa()
{
  str_send("ipa\r");
  return vprompt();
}
int vread(buff, n)
char *buff;
int n;
{
  int i;
  char *nxt;
  static char fsize[7];
#ifdef DEBUG
  printf("->vread\n");
#endif
  str_send("rdf ");
  str_send(itoa(n, fsize));
  str_send("\r");
  nxt=buff;
  for (i=0; i<n ; i++) {
    while ((inp(p_stat) & VRXF) == 0)
      ;
    *nxt++ = inp(p_data);
  }
#ifdef DEBUG
    printf("%d bytes read\n", n);
#endif
  return vprompt();
}
int vwrite(buff, n)
char *buff;
int n;
{
  int i, rc;
  static char wsize[7];
  rc = 0;
  str_send("wrf ");
  str_send(itoa(n, wsize));
  str_send("\r");
  for (i=0; i<n; i++) {
    out_v(*buff++);
  }
  return vprompt();
}
int vcd(dir)
char *dir;
{
  int rc;
  rc = 0;
  str_send("cd ");
  str_send(dir);
  str_send("\r");
  str_rdw(linebuff, '\r');
  if (strcmp(linebuff, PROMPT) != 0) {
    printf("CD %s: %s\n", dir, linebuff);
    rc = -1;
  }
  return rc;
}
int vcdroot()
{
  while(vcdup() == 0)
    ;
  return 0;
}
int vcdup()
{
  int rc;
  rc = 0;
  str_send("cd ..\r");
  str_rdw(linebuff, '\r');
  if (strcmp(linebuff, CFERROR) == 0) {
    rc = -1;
  }
  return rc;
}
