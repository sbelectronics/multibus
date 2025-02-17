* JP1: XACK

  * 1 = fastest, 8 = slowest. (default: 4)

* JP2: data buffer enable

  * 1-2 enabled by BoardCS. This may fail due to lack of extended XACK
 
  * 2-3 enabled always. This will work, but could be a little hard on the RAM and IO devices,
    who might race against the buffer switching between in and out.

  * 2-vertical. Place jumper vertically from pin 2 to pad right above it. This will enable
    the buffers on the bus-enable setting from the MEM PLD. This causes it to be enabled
    when board is selected or when XACKing a write. (Default)

* JP3: type of EPROM

  * 1-2 512kbit or larger (default)
 
  * 2-3 256kbit

* Jp4: inhibit

  * 1-2 ignore inhibit (default)

  * 2-3 inhibit board if INH1 is set

* JP5: external reset switch

  * Used if you want an external RESET switch (default unpopulated)

* JP6, JP16: board version

  * 1-2 v2 board (default)

  * 2-3 v1 board (will not work with v2 mem pld)

* JP7: A19 matching

  * 1-2 matches A19 low, lower 512KB (default)

  * 2-3 matches A19 high, upper 512KB

* JP8: external int2 signal

  * Used if you want an external INT2 switch (default unpopulated)

* JP9: not a jumper - spare 5V and GND outputs

  * Used if you need a spare 5V or GND (default unpopulated)

* JP10: slave interrupt

  * if present, then slave INT will be output as INT7. (default populated)

* JP11: master interrupt

  * if present, then master INT will be output as INT1.
    Note: this is intended to be used only if the master-8259 is present, which probably
    only makes sense with a 80/10B or similar board that does not have an 8259.
    (default unpopulated)

* JP13: master acknowledge

  * if present, then INTA will acknowledge the master 8259.
    Note: See JP11 note.
    (default: unpopulated)

* JP15: raspberry pi power

  * if present, then pi will be powered from multibus +5V.
    Note: set by user preference. It may be more convenient to power pi from separate
    supply while diagnosing/debugging pi-related stuff.

* A16, A17, A18, A19: upper address bits

  * 1-2 disables inputting address from multibus and assumes low (default)

  * 2-3 use address bit from multibus