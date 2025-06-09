TODO: Consolidate with the Olivetti copy, which is 99% the same as this.
TODO: Contribute back to Glenn.

Heathkit H8 vdip-utilities

https://github.com/sebhc/vdip-utilities

Original by Glenn Roberts, Douglas Miller, and others.

Ported to Olivetti by smbaker.

Ported to Multibus by smbaker.

Temporarily here, eventual plan is to consolidate back with master and generalize
for multiple architectures.

Olivetti Changes:

* different port numbers, different bitmasks on the status bits

* replaced some functions in vutil.c with their equivalents from stdlib

* replaced the index() function

* threw out all of the timeout stuff, then added it back in using manually-tuned loops. This is probably the messiest change.

* dropped some of the time/date stuff that wasn't working

* endian-flipped the size returned in VDIR

* arguments on the M20 can't start with '-'. I've been using '/' instead.

* use fwrite() nad fread() instead of write() and read()

Multibus changes:

* Made sure to use strict K&R function prototypes.

* Dealt with lack of strstr()

* Name clash on "entry". Must have been a reserved word.

* No stdlib.h or strings.h
