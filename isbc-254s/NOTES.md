# iSBC-254s bubble memory multibus board notes

Scott Baker, https://www.smbaker.com/

## general notes

* iRMX-86 / iRMX-286 release 6 includes a built in iSBC-254S driver, configured for 4 bubbles. If you have
  a 254 with fewer bubbles, then you may have to rebuild iRMX.
  
* The port and int configured in iRMX is 0x880 and int3. You will need to either ensure your 254S is
  configured the same, or rebuild iRMX with your settings.

* According to the ICU utilitity, multiple iSBC-254S can be used together on the same system.

* Make sure to place the iSBC-254S at a greater priority than other bus master controllers. For example,
  I had to move my iSBC-215 winchester controller to a lower slot in my System 310. If you do not do this,
  then operations that involve multiple devices (for example a COPY from HDD to Bubble) may fail.
  My suspicion is the higher priority device will starve the bubble for bus access during a write
  operation. Bubbles are sensitive to timing and power.

* The iSBC-264 is a different board, featuring 7114 bubbles (4 megabit) and 7225 controller. It is probably
  not compatible with the iSBC-254S driver, though I have not tried. If you have a system that supports the
  264, please let me know.

## jumper settings

```
Jumpers E67 through E82 - 8-bit address select
  connects to 3205 3-8 decoder
  3205 is connected to A5, A6, A7 via 8287 inverting bus transceiver U46
  (rightmost)
  E82 - 0xE0
  E80 - 0xC0
  E78 - 0xA0
  E76 - x080
  E74 - 0x60
  E72 - 0x40
  E70 - 0x20
  E68 - 0x00
  (leftmost)

Jumpers E83 through E100 - 16-bit address select
  connects to 3205 3-8 decoder
  3205 is connected to A8, A9, A10 via U42, 7404 inverter
  (rightmost)
  E100 - 0x700
  E98 - 0x600
  E96 - 0x500
  E94 - 0x400
  E92 - 0x300
  E90 - 0x200
  E88 - 0x100
  E86 - 0x000
  E84 - ignore 16-bit select, use 8-bit select only
  (leftmost)

Other address jumpers
  E103 - !A12
  E104 - U37-6 active high enable to U36

  jumper E103-E104 for !0x1000 address select

  E105 - !A13
  E106 - U36-6, active high select on U36
  
  jumper E105-E106 for !0x2000 address select

  E101 - U37-4, active low enable on U37
  E109 - !A11
  E102 - A11
     
  jumper E101-E109 for 0x800 address select, or E101-E102 for !0x800 address select

  E114, E115 - U37-5, active low select to U37
  E116 is inverted !A14 = A14
 
  jumper 115-116 for !0x4000 address select

  E117 - U41-9
  E118 - G

  E119 - U36-4, active low select to U36
  E120 G

  E112 - !A15

  U41 is an OR gate
    U41-8 output to U36-5, active low enable to U36
    U41-9 input, jumpered to GND
    U41-10 is U46-11, which is direction on address buffers

XACK jumpers
  Similar to design in Jun82 multibus specification
  (longer wait)
  E41 - U27-13 (H)
  E43 - U27-12 (G)
  E45 - U27-11 (F)
  E47 - U27-10 (E)
  E49 - U27-6 (D)
  (shorter wait)

interrupt jumpers
  E52 - int7
  E54 - int6
  E56 - int5
  E58 - int4
  E60 - int3 (assumed; not tested)
  E62 - int2
  E64 - int1 (assumed; not tested)
  E66 - int0

misc jumpers
  E130-E131  8218 pin 23 to bus BPRO

7242 enable jumpers
  E1-E2   U3 ENABLE-A to 7250-CS  (alternate E2-E3 for ENABLE-B)
  E20-E19 U4 ENABLE-A to 7250-CS  (alternate E19-E21 for ENABLE-B)
  E17-E16 U5 ENABLE-A to 7250-CS  (alternate E16-E18 for ENABLE-B)
  E33-E32 U6 ENABLE-A to 7250-CS  (alternate E33-E31 for ENABLE-B)

orig board

  address

  together these jumpers put the board on address 0x820

  E69-E70 -   address 0x02x
  E85-E87 -   address 0x0xx
  E101-E109 - address 0x8xx
  E103-E104 - not address 0x1000
  E105-E106 - not address 0x2000
  E115-E116 - not address 0x4000
  E117-E118 -
  E119-E120 - ignore address bit 0x8000

  interrupt

  together these use int3 (for bubble) and int2 (unknown)

  E59-E60 - int3 for bubble
  E57-E62 - int2 unknown purpose (seems unnecessary when using with iRMX)

  other
  E1-E2 - ENABLE-A
  E20-E19 - ENABLE-A
  E17-E16 - ENABLE-A
  E33-E32 - ENABLE-A
  E49-E48 - xack shortest possible
  E130-E131 - BPRO

scott's changes for irmx-86 / irmx-286
  move E69-E70 to E75-E76 for board at 0x880
  removed jumper E57-E62
```

## short demo

```
- attachdevice b0 as :bub:
:bub:, volume is not a NAMED volume

- diskverify :bub:
iRMX 86 Disk Verify Utility, V3.0
Copyright 1981, 1982, 1984 Intel Corporation
*disk
Device name = b0            
   Physical disk
      Device gran = 0100
       Block size = 0100
     No of blocks = 00000800
      Volume size = 00080000

- format :bub:scottb
volume (scottb) will be formatted as a NAMED volume
    granularity   =   256        map start =        992
    interleave    =     5
    files         =   200
    extensionsize =     3
    volume size   =   512 K


volume formatted

- dir :bub: e
25 JUL 84  23:33:23
DIRECTORY OF  :bub:  ON VOLUME scottb
                                                 GRAN
  NAME         AT   ACC      BLKS     LENGTH   VOL FIL OWNER           LAST MOD

         0  FILES           0  BLKS             0  BYTES

       200  FILES       1,958  BLKS       501,248  BYTES FREE

- copy hello.c to :bub:
hello.c copied TO :bub:hello.c

- copy :bub:hello.c to :co:
#include <stdio.h>
main() {
    printf("Hello, World!\n");
    return 0;
}
:bub:hello.c copied TO :co:
```
