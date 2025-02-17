$macrofile

;	TITLE	'psg`
;	Scott Baker, www.smbaker.com
;
; 	AY-3-8910 Complex Sound Generator for iPDS-100 PSG Multimodule Adapter

	PUBLIC	PSGNIT
	PUBLIC  PSGMUT
	PUBLIC	PLAY
	PUBLIC  MPLAY

	PUBLIC	NC3
	PUBLIC	NC3S
	PUBLIC	ND3F
	PUBLIC 	ND3
	PUBLIC	ND3S
	PUBLIC	NE3F
	PUBLIC	NE3
	PUBLIC	NF3
	PUBLIC	NF3S
	PUBLIC	NG3F
	PUBLIC	NG3
	PUBLIC	NG3S
	PUBLIC	NA3F
	PUBLIC	NA3
	PUBLIC	NA3S
	PUBLIC	NB3F
	PUBLIC	NB3
	PUBLIC	NC4
	PUBLIC	NC4S
	PUBLIC	ND4F
	PUBLIC	ND4
	PUBLIC	ND4S
	PUBLIC	NE4F
	PUBLIC	NE4
	PUBLIC	NF4
	PUBLIC	NF4S
	PUBLIC	NG4F
	PUBLIC	NG4
	PUBLIC	NG4S
	PUBLIC	NA4F
	PUBLIC	NA4
	PUBLIC	NA4S
	PUBLIC	NB4F
	PUBLIC	NB4
	PUBLIC	NC5
	PUBLIC	NC5S
	PUBLIC	ND5F
	PUBLIC	ND5

	PUBLIC	NOTE16
	PUBLIC	NOTE8
	PUBLIC	NOTE4
	PUBLIC	NOTE2
	PUBLIC 	SIL

	PUBLIC	DELAYS
	PUBLIC	DELAYM

	CSEG

NC3     EQU     3BBH
NC3S    EQU     385H
ND3F    EQU     385H
ND3     EQU     353H
ND3S    EQU     323H
NE3F    EQU     323H
NE3     EQU     2F6H
NF3     EQU     2CBH
NF3S    EQU     2A3H
NG3F    EQU     2A3H
NG3     EQU     27DH
NG3S    EQU     259H
NA3F    EQU     259H
NA3     EQU     238H
NA3S    EQU     218H
NB3F    EQU     218H
NB3     EQU     1FAH
NC4     EQU     1DDH
NC4S    EQU     1C2H
ND4F    EQU     1C2H
ND4     EQU     1A9H
ND4S    EQU     191H
NE4F    EQU     191H
NE4     EQU     17BH
NF4     EQU     165H
NF4S    EQU     151H
NG4F    EQU     151H
NG4     EQU     13EH
NG4S    EQU     12CH
NA4F    EQU     12CH
NA4     EQU     11CH
NA4S    EQU     10CH
NB4F    EQU     10CH
NB4     EQU     0FDH
NC5     EQU     0EEH
NC5S    EQU     0E1H
ND5F    EQU     0E1H
ND5     EQU     0D4H

; NOTE1 is our basic whole note length, which is 4 seconds.
; NOTE4 is a quarter note, which is 1 second
; Usually do our tempo in "note4 per 1 minutes"
;    NOTE1 = 240.0/tempo*1000

NOTE1	EQU	4000
NOTE2	EQU	NOTE1/2*7/8
NOTE4	EQU	NOTE1/4*7/8
NOTE8	EQU	NOTE1/8*7/8
NOTE16	EQU	NOTE1/16*7/8

; SIL is a silent note

SIL	EQU	0FFFFH

$INCLUDE(PORTS.INC)

	; PSGDEL delays because the PSG is slow

PSGDEL	MACRO
	ENDM

	; BCDIV8 divides BC by 8, if BC less than equal to 7FF

BCDIV8	MACRO
	MOV	A,C		; C = C >> 3
	RRC
	RRC
	RRC
	ANI 	01FH
	MOV	C,A
	MOV	A,B		; A = B << 5
	RRC
	RRC
	RRC
	ANI	0E0H
	ORA	C		; A = A | C
	MOV	C,A		; C = A
	MVI	B,0		; B = 0
	ENDM

	; LDEBC loads the word in (DE) into BC, and increments DE

LDEBC	MACRO
	LDAX	D		; Load (DE) into BC
	INX	D	
	MOV	C,A
	LDAX	D
	INX	D
	MOV	B,A
	ENDM

	; Read a value from (DE) and send it to the register

LPRV	MACRO	CHAN
	MVI	A, CHAN
	OUT	PSGREG
	LDAX	D
	INX	D
	OUT	PSGVAL
	ENDM


	; DELAYS - delay in seconds in A

DELAYS:
DELS0:	PUSH	PSW
	LXI	B, 1000		; 1000ms delay
	CALL	DELAYM
	POP	PSW
	DCR	A
	JNZ	DELS0
	RET

	; DELAYM - delay in milliseconds in A (up to 255ms)

DELAYM:	
DELM0:	PUSH	B
	LXI	B, 159		; Loops-per-millisecond constant depends on CPU and speed
DELM1:  DCX	B
	MOV	A,B
	ORA	C
	JNZ	DELM1
	POP	B
	DCX	B
	MOV	A,B
	ORA	C
	JNZ	DELM0
	RET

	; PSGNIT - initialize the PSG and unmute the amp

PSGNIT:	MVI	A,7
	OUT	PSGREG
	MVI	A,38H		; Channels A,B,C On
	OUT	PSGVAL
	MVI	A,8
	OUT	PSGREG
	MVI	A,0
	OUT	PSGVAL
	PSGDEL
	MVI	A,9
	OUT	PSGREG
	MVI	A,0
	OUT	PSGVAL
	PSGDEL
	MVI	A,10
	OUT	PSGREG
	MVI	A,0
	OUT	PSGVAL
	PSGDEL
	MVI	A,001H		; Unmute by default
	OUT	PSMPORT
	RET

	; PSGMUT - mute the amp

PSGMUT:	MVI	A,00H
	OUT	PSMPORT
	RET

	; PLAY - play (note, duration) in DE (N1, D1, N2, D2, N3, D3, ...)

PLAY:
	LDAX	D		; Low byte of note
	CPI	0FFH		; silence?
	JZ	SILNOT
	INX	D
	MOV	C,A		; ... into C
	LDAX	D		; Hi byte of note
	INX	D
	MOV	B,A		; ... into B

	MOV	A,B		; BC = 0 ?
	ORA	C
	JZ	PLAYX		; Quit playing

	MVI	A,0H
	OUT	PSGREG
	MOV	A,C
	OUT	PSGVAL

	MVI	A,1H
	OUT	PSGREG
	MOV	A,B
	OUT	PSGVAL

	MVI	A,8H		; sound on
	OUT	PSGREG
	MVI	A,0FH
	OUT	PSGVAL

WAIT:	LDEBC			; load BC with delay for the note to play
	PUSH	B
	CALL	DELAYM

	MVI	A,8H		; sound off
	OUT	PSGREG
	MVI	A,00H
	OUT	PSGVAL

	POP	B		; delay 1/8 of the note length after
	BCDIV8
	CALL	DELAYM

	JMP	PLAY

SILNOT:
	INX	D		; skip both note bytes
	INX	D
	JMP	WAIT		; wait for the silence to play

PLAYX:
	RET

	; MPLAY - play 3-tone music (duration, N1, V1, N2, V2, N3, V3)

MPLAY:	LDEBC			; first word is the delay

	LPRV	0
	LPRV	1
	LPRV	8		; volume A
	INX	D

	LPRV	2
	LPRV	3
	LPRV	9		; volume B
	INX	D

	LPRV	4
	LPRV	5
	LPRV	10		; volume C
	INX	D

	MOV	A,B
	ORA	C
	JZ	MPLAYX		; If BC=0, we're done

	CALL	DELAYM
	JMP	MPLAY
MPLAYX:	RET

	END
