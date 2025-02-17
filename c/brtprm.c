/*
 * brutprim.c: The world's worst prime number generator.
 * 
 * Scott Baker, https://www.smbaker.com/
 * 
 * Why to I take credit for this monstrosity?
 * 
 */

#include <stdio.h>
#include <stdlib.h>

/* Note: Without including stdlib.h, the program will not
 *       work. Probably because it guesses the strtoul
 *       prototype wrong.
 */

int main(int argc, char **argv) 
{
    int l,n,d,p;
    char *endptr;

    /* Note: The usual brutprim used scanf() to read the limit,
     *       but for whatever reason this increases disk space
     *       for the CMD by 20KB, so use the cmdline instead
     */

    if (argc != 2) {
        fprintf(stderr, "usage: brutprim <limit>\n");
        return 1;
    }

    /* get port address */
    l = atoi(argv[1]);

    for (n=3; n<=l; n++) {
        p=1;
        for (d=2; d<=(n-1); d++) {
            if ((n % d)==0) {
                putchar('.');
                p=0;
                break;
            }
        }
        if (p) {
            printf("%d ", n);
        }
    }
    printf("\n");
} 
