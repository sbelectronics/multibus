; Ports for SBC-80/24 with scott's ramboard

; 80/24 does not use ATTACH syscall when attaching multimodules

DOATTCH EQU     0

; Ports
;  00-0F - multimodule on debug board
;  10-1F - multimodule on debug board
;  20-2F - multimodule on debug board / left multimodule on nixie board
;  30-3F - multimodule on debug board
;  40-4F - multimodule on debug board
;  50-5F - multimodule on debug board / middle multimodule on nixie board
;  68-6F - multibus/ISIS hard drive board
;  78-7F - multibus/ISIS first floppy board
;  88-8F - multibus/ISIS second floppy board
;  90-9F - nixie tube board
;  A0-AF - left multimodule on diskboard/ramboard
;  B0-BF - middle multimodule on diskboard/ramboard
;  C0-CF - multimodule on 80/24A (conflicts with C0/C1 IOC on ISIS)
;  D0-DF - peripherals on 80/24A
;  E0-EF - peripherals on 80/24A
;  F0-FF - mutlimodule on 80/24A (conflicts with config port, serial ports, and interrupt on ISIS)

; interrupts

INTMSK  EQU     0DBH
INTACK  EQU     0DAH

; CSG Multimodule

CSGPORT	EQU	0B3H
CSMPORT	EQU	0B4H    ; Mute for CSG board

; PSG Multimodule

PSGREG	EQU	0B5H
PSGVAL	EQU	0B6H
PSMPORT	EQU	0B7H    ; Mute for PSG board

; TIL311 multimodule

TILL    EQU     0B0H
TILM    EQU     0B1H
TILR    EQU     0B2H
TILB    EQU     0B3H    ; blanking port
TILI    EQU     0B0H    ; input port

; RTC multimodule

RTCDAT  EQU     0A0H
RTCADR  EQU     0A1H
RTCCTL  EQU     0A2H
RTC82C  EQU     0A3H

; Serial multimodule

SERBAS  EQU     0B0H

; Digitalker multimodule

DIGBASE EQU     050H
DIGOUT  EQU     DIGBASE
DIGST   EQU     DIGBASE
DIGMUT  EQU     DIGBASE+1

; Votrax multimovule

VTXPHN  EQU     0B0H
VTXRDY  EQU     0B0H
VTXMUT  EQU     0B1H

TMSBASE EQU     0B0H
TMSOUT  EQU     TMSBASE
TMSIN   EQU     TMSBASE
TMSMUT  EQU     TMSBASE+1

; Nixie tube clock board

NIXBAS	EQU	090H

