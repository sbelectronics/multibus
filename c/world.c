/*
 *	Hello World
 */


#include <stdio.h>
#include <features.h>

pdec(int d)
{
	if (d>0) {
		pdec(d/10);
		fputc_cons('0' + (d%10));
	}
}

main(int argc, char **argv)
{
    char s[81];
	int i;

	// test several output functions
	printk("hello");
	fputc_cons(',');
	fputc(' ', stdout);
	printf("world\n");

	printf("%d plus %d is %d\n", 1, 2, 3);

	printf("argc: %d\n", argc);
	for (i=0; i<argc; i++) {
		printf("arg%d: %s (%d)\n", i, argv[i], strlen(argv[i]));
	}

/*
	printf("%d\n", fgetc_cons());
	printf("%d\n", fgetc_cons());
	printf("%d\n", fgetc_cons());
*/

	printf("type something: ");

	if (fgets(s, 80, stdin) == NULL) {
		printf("error when reading\n");
	} else {
		printf("Read string: %s\n", s);
	}
}
