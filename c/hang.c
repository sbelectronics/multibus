/* from https://www.tuhs.org/cgi-bin/utree.pl?file=pdp11v/usr/src/games/hangman.c
 *
 * Modified by Scott Baker, www.smbaker.com, for ISIS-II.
 * Updated to all uppercase to match genre and eliminated file accesses because not implemented in my zcc.
 */

static char ID[] = "@(#)hangman.c	1.1";

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hang.h"
#define MAXERR 7
#define MINSCORE 0
#define MINLEN 7
int alive,lost;
long errors=0, words=0;

void setup();
void startnew();
void getguess();
void stateout();
void wordout();
void youwon();
void getword();
void fatal(char *s);
void pscore();

int main(argc,argv) char **argv;
{
	setup();
	for(;;)
	{	startnew();
		while(alive>0)
		{	stateout();
			getguess();
		}
		words=words+1;
		if(lost) wordout();
		else youwon();
	}
	return 0;
}

void setup()
{
	/* 
	 * int tvec[2];
	 * struct stat statb;
	 * time(tvec);
	 * srand(tvec[0]+tvec[1]);
	 */
	srand(1);
}

char word[26],alph[26],realword[26];
void startnew()
{	int i;
	long int pos;
	char buf[128];
	for(i=0;i<26;i++) word[i]=alph[i]=realword[i]=0;
	getword();
	alive=MAXERR;
	lost=0;
}

void stateout()
{	int i;
	printf("GUESSES: ");
	for(i=0;i<26;i++)
		if(alph[i]!=0) putchar(toupper(alph[i]));
	printf(" WORD: %s ", word);
	printf("ERRORS: %d/%d\n", MAXERR - alive, MAXERR);
}

void getguess()
{	char gbuf[128], c;
	int ok = 0, i;
loop:
	printf("GUESS: ");
	if (gets(gbuf) == NULL)
	{	putchar('\n');
		exit(0);
	}
	c = toupper(gbuf[0]);
	if (alph[c - 'A'] != 0)
	{	printf("YOU GUESSED THAT\n");
		goto loop;
	}
	else alph[c - 'A'] = c;
	for (i = 0; realword[i] != 0; i++)
		if (realword[i] == c)
		{	word[i] = c;
			ok = 1;
		}
	if (ok == 0)
	{	alive--;
		errors = errors + 1;
		if (alive <= 0) lost = 1;
		return;
	}
	for (i = 0; word[i] != 0; i++)
		if (word[i] == '.') return;
	alive = 0;
	lost = 0;
	return;
}

void wordout()
{
	errors = errors + 2;
	printf("THE ANSWER WAS %s, YOU BLEW IT\n", realword);
}

void youwon()
{
	printf("YOU WIN, THE WORD IS %s\n", realword);
}

void fatal(s) char *s;
{
	fprintf(stderr, "%s\n", s);
	exit(1);
}

void getword()
{
	char wbuf[128], c;
	int i, j;
loop:
	i = rand() % NUMWORDS;
	strcpy(wbuf, wordlist[i]);
	i = strlen(wbuf);
	if (i < MINLEN) goto loop;
	for (j = 0; j < i; j++)
		if ((c = wbuf[j]) < 'A' || c > 'Z') goto loop;
	pscore();
	strcpy(realword, wbuf);
	for (j = 0; j < i; word[j++] = '.');
}

void pscore()
{
	if (words != 0) printf("(%d.%d/%d) ",
			errors / words, ((errors * 100) / words) % 100, words);
}
