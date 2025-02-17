$macrofile

;	TITLE	'csg`
;	Scott Baker, www.smbaker.com
;
; 	76489 Complex Sound Generator for iPDS-100 CSG Multimodule Adapter
;
; simple test
;   O73,BF - silence channel 2
;   O73,DF - silence channel 3
;   O73,FF - silence channel 4
;   O74,1  - turn off amplifier mute
;   O73,90 - volume up
;   O73,82 - E2 note low part
;   O73,0E - E2 note high part

	PUBLIC	CSGNIT
	PUBLIC  CSGMUT
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

NC3	EQU	0357H
NC3S	EQU	0327H
ND3F	EQU	NC3S
ND3	EQU	02F9H
ND3S	EQU	02CFH
NE3F	EQU	ND3S
NE3	EQU	02A6H
NF3	EQU	0280H
NF3S	EQU	025CH
NG3F	EQU	NF3S
NG3	EQU	023AH
NG3S	EQU	021AH
NA3F	EQU	NG3S
NA3	EQU	01FCH
NA3S	EQU	01DFH
NB3F	EQU	NA3S
NB3	EQU	01C4H
NC4	EQU	01A8H
NC4S	EQU	01ABH
ND4F	EQU	0193H
ND4	EQU	017CH
ND4S	EQU	0167H
NE4F	EQU	ND4S
NE4	EQU	0153H
NF4	EQU	0140H
NF4S	EQU	012EH
NG4F	EQU	NF4S
NG4	EQU	011DH
NG4S	EQU	010DH
NA4F	EQU	NG4S
NA4	EQU	00FEH
NA4S	EQU	00EFH
NB4F	EQU	NA4S
NB4	EQU	00E2H
NC5	EQU	00D5H
NC5S	EQU	00C9H
ND5F	EQU	NC5S
ND5	EQU	00BEH

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

	; CSGDEL delays because the CSG is slow

CSGDEL	MACRO
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
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

	; PNOT plays the note in BC

PNOT	MACRO	CHAN
	MOV	A,C
	ANI	0FH
	ORI	CHAN
	OUT	CSGPORT

	MOV	A,B		; Shift hi byte left 4 bits
	RLC
	RLC
	RLC
	RLC
	ANI	030H
	MOV	B,A

	MOV	A,C		; Shift lo byte right 4 bits
	RRC
	RRC
	RRC
	RRC
	ANI	0FH
	ORA	B
	OUT	CSGPORT
	ENDM

LPVOL	MACRO	CHAN
	LDAX	D
	INX	D
	INX	D
	ORI	CHAN
	OUT	CSGPORT
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

	; CSGNIT - initialize the CSG and unmute the amp

CSGNIT:	MVI	A,09FH
	OUT	CSGPORT
	CSGDEL
	MVI	A,0BFH
	OUT	CSGPORT
	CSGDEL
	MVI	A,0DFH
	OUT	CSGPORT
	CSGDEL
	MVI	A,0FFH
	OUT	CSGPORT
	CSGDEL
	MVI	A,001H		; Unmute by default
	OUT	CSMPORT
	RET

	; CSGMUT - mute the amp

CSGMUT:	MVI	A,00
	OUT	CSMPORT
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

	PNOT	80H		; Play Note
	CSGDEL

	MVI	A,090H		; sound on
	OUT	CSGPORT		; atn0 = 0

WAIT:	LDEBC			; load BC with delay for the note to play
	PUSH	B
	CALL	DELAYM

	MVI	A,09FH		; sound off
	OUT	CSGPORT		; atn0 = F

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

	PUSH	B

	LDEBC
	PNOT	80H
	LPVOL	90H

	LDEBC
	PNOT	0A0H
	LPVOL	0B0H

	LDEBC
	PNOT	0C0H
	LPVOL	0D0H

	POP	B

	MOV	A,B
	ORA	C
	JZ	MPLAYX		; If BC=0, we're done

	CALL	DELAYM
	JMP	MPLAY
MPLAYX:	RET

	END
