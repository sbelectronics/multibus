;	TITLE	'play songs`
;	Scott Baker, www.smbaker.com
;
; 	Plays various songs on the iPDS-100 with CSG multimodule board.
;

	EXTRN	COPEN
	EXTRN	ZSOUT
	EXTRN	EXIT
	EXTRN	PLAY
	EXTRN	MPLAY
	EXTRN 	CSGNIT
	EXTRN	CSGMUT

	EXTRN	NC3
	EXTRN	NC3S
	EXTRN	ND3F
	EXTRN 	ND3
	EXTRN	ND3S
	EXTRN	NE3F
	EXTRN	NE3
	EXTRN	NF3
	EXTRN	NF3S
	EXTRN	NG3F
	EXTRN	NG3
	EXTRN	NG3S
	EXTRN	NA3F
	EXTRN	NA3
	EXTRN	NA3S
	EXTRN	NB3F
	EXTRN	NB3
	EXTRN	NC4
	EXTRN	NC4S
	EXTRN	ND4F
	EXTRN	ND4
	EXTRN	ND4S
	EXTRN	NE4F
	EXTRN	NE4
	EXTRN	NF4
	EXTRN	NF4S
	EXTRN	NG4F
	EXTRN	NG4
	EXTRN	NG4S
	EXTRN	NA4F
	EXTRN	NA4
	EXTRN	NA4S
	EXTRN	NB4F
	EXTRN	NB4
	EXTRN	NC5
	EXTRN	NC5S
	EXTRN	ND5F
	EXTRN	ND5

	EXTRN   SIL

	EXTRN	FLAGA
	EXTRN	FLAGB
	EXTRN	FLAGC
	EXTRN   FLAGD
	EXTRN	FLAGF
        EXTRN   FLAGL
	EXTRN	FLAGM
	EXTRN	FLAGW
	EXTRN	FLAGX
	EXTRN	DOFLAG

	EXTRN	ATTACH

	STKLN	100H				; Size of stack segment

	CSEG

NOTE1	EQU	2000				; tempo=120
NOTE2	EQU	NOTE1/2*7/8			; see csg.asm for calculation instructions
NOTE4	EQU	NOTE1/4*7/8
NOTE8	EQU	NOTE1/8*7/8
NOTE16	EQU	NOTE1/16*7/8

T60N1	EQU	4000				; tempo=60
T60N2	EQU	T60N1/2*7/8			; see csg.asm for calculation instructions
T60N4	EQU	T60N1/4*7/8
T60N8	EQU	T60N1/8*7/8
T60N16	EQU	T60N1/16*7/8	

T90N1	EQU	3000				; tempo=90
T90N2	EQU	T90N1/2*7/8			; see csg.asm for calculation instructions
T90N4	EQU	T90N1/4*7/8
T90N8	EQU	T90N1/8*7/8
T90N16	EQU	T90N1/16*7/8	

T15N1	EQU	1548				; tempo=155
T15N2	EQU	T15N1/2*7/8			; see csg.asm for calculation instructions
T15N4	EQU	T15N1/4*7/8
T15N8	EQU	T15N1/8*7/8
T15N16	EQU	T15N1/16*7/8

$INCLUDE(PORTS.INC)

ORIG:	NOP					; Some NOPs makes it easier for the disassembler to sync
	NOP
	NOP
	LXI	SP,STACK			; Setup initial stack
	CALL	COPEN				; Open the console

	CALL	DOFLAG

        IF      DOATTCH
	CALL	ATTACH				; Attach multimodule row 1
        ENDIF

	CALL	CSGNIT				; SIL and unmute

AGAIN:
	LDA	FLAGM				; M is for Mute
	CPI	0FFH
	JZ	NOTM
	CALL	CSGMUT				; Do it before any songs
NOTM:
	LDA	FLAGA
	CPI	0FFH
	JZ	NOTA
	STA	PLAYD
	LXI	D, AMSG
	CALL	ZSOUT
	LXI	D, ANOTES
	CALL	PLAY

NOTA:	
	LDA	FLAGB
	CPI	0FFH
	JZ	NOTB
	STA	PLAYD
	LXI	D, BMSG
	CALL	ZSOUT
	LXI	D, BNOTES
	CALL	PLAY

NOTB:
	LDA	FLAGD
	CPI	0FFH
	JZ	NOTD
	STA	PLAYD
	LXI	D, DMSG
	CALL	ZSOUT
	LXI	D, DNOTES
	CALL	MPLAY

NOTD:
	LDA	FLAGF
	CPI	0FFH
	JZ	NOTF
	STA	PLAYD
	LXI	D, FMSG
	CALL	ZSOUT
	LXI	D, FNOTES
	CALL	MPLAY

NOTF:
	LDA	FLAGL
	CPI	0FFH
	JZ	NOTL
	STA	PLAYD
	LXI	D, LMSG
	CALL	ZSOUT
	LXI	D, LNOTES
	CALL	PLAY	

NOTL:
	LDA	FLAGW
	CPI	0FFH
	JZ	NOTW
	STA	PLAYD
	LXI	D, WMSG
	CALL	ZSOUT
	LXI	D, WNOTES
	CALL	PLAY

NOTW:
	LDA	FLAGX
	CPI	0FFH
	JZ	NOTX
	STA	PLAYD
	LXI	D, XMSG
	CALL	ZSOUT
	LXI	D, XNOTES
	CALL	MPLAY

NOTX:
	LDA	PLAYD
	CPI	0FFH
	JNZ	NOHELP
	LXI	D, HELP
	CALL	ZSOUT

NOHELP:
	LDA	FLAGC				; Conntinous
	CPI	0FFH
	JNZ	AGAIN

	CALL	CSGMUT

	CALL	EXIT				; Exit to ISIS

PLAYD:  DB	0FFH

HELP:	DB	'ARGS: C=CONTINUOUS, M=MUTE', 0DH, 0AH
        DB      '      A=AMERICA, B=BONG, L=LAMB, W=WILTEL', 0DH, 0AH
	DB	'      D=BIRTHDAY,F=AXELF, X=XMAS (3-voice)', 0DH, 0AH, 0

BMSG:	DB	'Bong.', 0DH, 0AH, 0
BNOTES:	DW	ND5F, T60N16, SIL, T60N8, ND4F, T60N16
	DW	NG4F, T60N16, ND4F, T60N16, NA4F, T60N16, 0, 0

LMSG:	DB	'Mary Had a Little Lamb.', 0DH, 0AH, 0
LNOTES:
        DW      NG4, NOTE8, NF4, NOTE8, NE4F, NOTE8, NF4, NOTE8
        DW      NG4, NOTE8, NG4, NOTE8, NG4, NOTE8, SIL, NOTE8
        DW      NF4, NOTE8, NF4, NOTE8, NF4, NOTE4, NG4, NOTE8
        DW      NB4F, NOTE8, NB4F, NOTE4, NG4, NOTE8, NF4, NOTE8
        DW      NE4F, NOTE8, NF4, NOTE8, NG4, NOTE8, NG4, NOTE8
        DW      NG4, NOTE8, NG4, NOTE8, NF4, NOTE8, NF4, NOTE8
        DW      NG4, NOTE8, NF4, NOTE8, NE4F, NOTE8, 0, 0

WMSG:	DB	'William Tell Overture.', 0DH, 0AH, 0
WNOTES:
        DW      ND3, T15N16, ND3, T15N16, ND3, T15N16, SIL, T15N16
        DW      ND3, T15N16, ND3, T15N16, ND3, T15N16, SIL, T15N16
        DW      ND3, T15N16, ND3, T15N16, NG3, T15N8, NA3, T15N16
        DW      NB3, T15N8, ND3, T15N16, ND3, T15N16, ND3, T15N16
        DW      SIL, T15N16, ND3, T15N16, ND3, T15N16, ND3, T15N16
        DW      SIL, T15N16, NB3, T15N16, NB3, T15N16, NA3, T15N8
        DW      NG3F, T15N8, ND3, T15N8, ND3, T15N16, ND3, T15N16
        DW      SIL, T15N16, ND3, T15N16, ND3, T15N16, ND3, T15N16
        DW      SIL, T15N16, ND3, T15N16, ND3, T15N16, NG3, T15N8
        DW      NA3, T15N8, NB3, T15N8, SIL, T15N16, NG3, T15N16
        DW      ND4, T15N4, SIL, T15N8, NG3, T15N8, NB3, T15N8
        DW      NG3, T15N8, 0, 0

AMSG:	DB	'America the Beautiful.', 0DH, 0AH, 0
ANOTES:
        DW      NG4, T90N8, NG4, T90N4, NE4, T90N8, NE4, T90N8
        DW      NG4, T90N8, NG4, T90N4, ND4, T90N8, ND4, T90N8
        DW      NE4, T90N8, NF4, T90N8, NG4, T90N8, NA4, T90N8
        DW      NB4, T90N8, NG4, T90N2, NG4, T90N8, NG4, T90N4
        DW      NE4, T90N8, NE4, T90N8, NG4, T90N8, NG4, T90N4
        DW      ND4, T90N8, ND4, T90N8, ND4, T90N8, NC4S, T90N8
        DW      ND4, T90N8, NE4, T90N8, NA3, T90N8, ND4, T90N2
        DW      NG3, T90N8, NE4, T90N4, NE4, T90N8, ND4, T90N8
        DW      NC4, T90N8, NC4, T90N4, NB3, T90N8, NB3, T90N8
        DW      NC4, T90N8, ND4, T90N8, NB3, T90N8, NA3, T90N8
        DW      NG3, T90N8, NC4, T90N2, 0, 0

; This is an example 3-channel music sequence, played with MPLAY

T	EQU	500

XMSG:	DB	'We wish you a Merry Christmas.', 0DH, 0AH, 0
XNOTES:
        DW      T, 338, 2, 0, 15, 0, 15
        DW      T, 254, 1, 403, 7, 1118, 9
        DW      T/2, 254, 1, 403, 7, 677, 9
        DW      T/2, 226, 1, 403, 7, 677, 9
        DW      T/2, 254, 1, 403, 7, 508, 9
        DW      T/2, 269, 1, 403, 7, 508, 9
        DW      T, 302, 1, 380, 7, 760, 9
        DW      T, 302, 1, 380, 7, 604, 9
        DW      T, 302, 1, 380, 7, 508, 9
        DW      T, 226, 1, 380, 7, 909, 9
        DW      T/2, 226, 1, 380, 7, 604, 9
        DW      T/2, 201, 1, 380, 7, 604, 9
        DW      T/2, 226, 1, 380, 7, 452, 9
        DW      T/2, 254, 1, 380, 7, 452, 9
        DW      T, 269, 1, 338, 7, 677, 9
        DW      T, 338, 1, 537, 9, 0, 15
        DW      T, 338, 1, 677, 9, 0, 15
        DW      T, 201, 0, 338, 6, 1016, 9
        DW      T/2, 201, 0, 338, 6, 677, 9
        DW      T/2, 190, 0, 338, 6, 677, 9
        DW      T/2, 201, 0, 338, 6, 508, 9
        DW      T/2, 226, 0, 338, 6, 508, 9
        DW      T, 254, 0, 380, 6, 760, 8
        DW      T, 302, 0, 380, 6, 508, 8
        DW      T/2, 338, 1, 508, 6, 804, 9
        DW      T/2, 338, 1, 508, 6, 0, 15
        DW      T, 302, 0, 380, 6, 760, 8
        DW      T, 226, 0, 380, 6, 604, 8
        DW      T, 269, 1, 338, 7, 452, 9
        DW      T*2, 254, 0, 403, 5, 1016, 8
        DW      T, 338, 2, 0, 15, 0, 15
        DW      T, 254, 2, 403, 8, 1016, 10
        DW      T/2, 254, 2, 403, 8, 677, 10
        DW      T/2, 226, 2, 403, 8, 677, 10
        DW      T/2, 254, 2, 403, 8, 508, 10
        DW      T/2, 269, 2, 403, 8, 508, 10
        DW      T, 302, 2, 380, 8, 760, 10
        DW      T, 302, 2, 380, 8, 604, 10
        DW      T, 302, 2, 380, 8, 508, 10
        DW      T, 226, 1, 380, 7, 909, 9
        DW      T/2, 226, 1, 380, 7, 604, 9
        DW      T/2, 201, 1, 380, 7, 604, 9
        DW      T/2, 226, 1, 380, 7, 452, 9
        DW      T/2, 254, 1, 380, 7, 452, 9
        DW      T, 269, 1, 338, 7, 677, 9
        DW      T, 338, 2, 537, 6, 0, 15
        DW      T, 338, 1, 677, 6, 0, 15
        DW      T, 201, 0, 338, 6, 1016, 9
        DW      T/2, 201, 0, 338, 6, 677, 9
        DW      T/2, 190, 0, 338, 6, 677, 9
        DW      T/2, 201, 0, 338, 6, 508, 9
        DW      T/2, 226, 0, 338, 6, 508, 3
        DW      T, 254, 0, 380, 6, 760, 9
        DW      T, 302, 0, 380, 6, 508, 9
        DW      T/2, 338, 0, 508, 6, 804, 9
        DW      T/2, 338, 0, 508, 6, 0, 15
        DW      T, 302, 0, 508, 6, 0, 15
        DW      T, 302, 0, 380, 6, 760, 9
        DW      T, 226, 0, 302, 6, 909, 9
        DW      T, 269, 0, 380, 6, 677, 9
        DW      T*4, 254, 0, 338, 6, 804, 9
        DW      0,0,15,0,15,0,15

FMSG:   DB	'Axel F.', 0DH, 0AH, 0
FNOTES:
        DW      500, 508, 0, 0, 15, 0, 15
        DW      500, 320, 0, 642, 0, 0, 15
        DW      375, 269, 0, 320, 0, 0, 15
        DW      125, 320, 0, 359, 0, 0, 15
        DW      125, 508, 0, 0, 15, 0, 15
        DW      125, 320, 0, 359, 0, 0, 15
        DW      250, 240, 0, 428, 0, 0, 15
        DW      250, 320, 0, 359, 0, 0, 15
        DW      250, 359, 0, 320, 0, 0, 15
        DW      500, 320, 0, 642, 0, 0, 15
        DW      375, 213, 0, 320, 0, 0, 15
        DW      125, 320, 0, 320, 0, 0, 15
        DW      125, 508, 0, 0, 15, 0, 15
        DW      125, 320, 0, 480, 0, 0, 15
        DW      250, 201, 0, 428, 0, 0, 15
        DW      250, 213, 0, 359, 0, 0, 15
        DW      250, 269, 0, 320, 0, 0, 15
        DW      250, 320, 0, 810, 0, 0, 15
        DW      250, 213, 0, 810, 0, 0, 15
        DW      250, 160, 0, 403, 0, 0, 15
        DW      125, 320, 0, 403, 0, 0, 15
        DW      125, 359, 0, 359, 0, 0, 15
        DW      125, 508, 0, 0, 15, 0, 15
        DW      125, 359, 0, 359, 0, 0, 15
        DW      250, 428, 0, 428, 0, 0, 15
        DW      250, 286, 0, 359, 0, 0, 15
        DW      750, 320, 0, 320, 0, 0, 15
        DW      625, 508, 0, 0, 15, 0, 15
        DW      125, 359, 0, 0, 15, 0, 15
        DW      250, 428, 0, 0, 15, 0, 15
        DW      250, 480, 0, 0, 15, 0, 15
        DW      250, 540, 0, 0, 15, 0, 15
        DW      500, 320, 0, 642, 0, 0, 15
        DW      375, 269, 0, 320, 0, 0, 15
        DW      125, 320, 0, 359, 0, 0, 15
        DW      125, 508, 0, 0, 15, 0, 15
        DW      125, 320, 0, 359, 0, 0, 15
        DW      250, 240, 0, 428, 0, 0, 15
        DW      250, 320, 0, 359, 0, 0, 15
        DW      250, 359, 0, 320, 0, 0, 15
        DW      500, 320, 0, 642, 0, 0, 15
        DW      375, 213, 0, 320, 0, 0, 15
        DW      125, 320, 0, 320, 0, 0, 15
        DW      125, 508, 0, 0, 15, 0, 15
        DW      125, 320, 0, 480, 0, 0, 15
        DW      250, 201, 0, 428, 0, 0, 15
        DW      250, 213, 0, 359, 0, 0, 15
        DW      250, 269, 0, 320, 0, 0, 15
        DW      250, 320, 0, 810, 0, 0, 15
        DW      250, 213, 0, 810, 0, 0, 15
        DW      250, 160, 0, 403, 0, 0, 15
        DW      125, 320, 0, 403, 0, 0, 15
        DW      125, 359, 0, 359, 0, 0, 15
        DW      125, 508, 0, 0, 15, 0, 15
        DW      125, 359, 0, 359, 0, 0, 15
        DW      250, 428, 0, 428, 0, 0, 15
        DW      250, 286, 0, 359, 0, 0, 15
        DW      750, 320, 0, 320, 0, 0, 15
        DW      625, 508, 0, 0, 15, 0, 15
        DW      125, 359, 0, 0, 15, 0, 15
        DW      250, 428, 0, 0, 15, 0, 15
        DW      250, 480, 0, 0, 15, 0, 15
        DW      250, 540, 0, 0, 15, 0, 15
        DW      250, 642, 0, 0, 15, 0, 15
        DW      125, 213, 0, 642, 0, 0, 15
        DW      125, 213, 0, 642, 0, 213, 0
        DW      125, 213, 0, 320, 0, 0, 15
        DW      250, 213, 0, 320, 0, 213, 0
        DW      125, 179, 0, 359, 0, 213, 0
        DW      125, 179, 0, 0, 15, 0, 15
        DW      125, 179, 0, 359, 0, 179, 0
        DW      250, 179, 0, 428, 0, 179, 0
        DW      125, 190, 0, 359, 0, 0, 15
        DW      125, 190, 0, 359, 0, 190, 0
        DW      250, 190, 0, 320, 0, 190, 0
        DW      250, 642, 0, 0, 15, 0, 15
        DW      125, 213, 0, 642, 0, 0, 15
        DW      125, 213, 0, 642, 0, 213, 0
        DW      125, 213, 0, 320, 0, 0, 15
        DW      250, 213, 0, 320, 0, 213, 0
        DW      125, 179, 0, 320, 0, 213, 0
        DW      125, 179, 0, 0, 15, 0, 15
        DW      125, 179, 0, 480, 0, 179, 0
        DW      125, 190, 0, 428, 0, 179, 0
        DW      125, 190, 0, 428, 0, 190, 0
        DW      125, 213, 0, 359, 0, 0, 15
        DW      125, 213, 0, 359, 0, 213, 0
        DW      250, 213, 0, 320, 0, 213, 0
        DW      250, 810, 0, 0, 15, 0, 15
        DW      125, 269, 0, 810, 0, 0, 15
        DW      125, 269, 0, 810, 0, 269, 0
        DW      125, 269, 0, 403, 0, 0, 15
        DW      250, 269, 0, 403, 0, 269, 0
        DW      125, 269, 0, 359, 0, 269, 0
        DW      125, 269, 0, 0, 15, 0, 15
        DW      125, 240, 0, 359, 0, 0, 15
        DW      250, 240, 0, 428, 0, 240, 0
        DW      125, 359, 0, 240, 0, 0, 15
        DW      125, 240, 0, 359, 0, 240, 0
        DW      250, 240, 0, 320, 0, 240, 0
        DW      250, 320, 0, 0, 15, 0, 15
        DW      125, 213, 0, 320, 0, 0, 15
        DW      125, 213, 0, 320, 0, 213, 0
        DW      125, 213, 0, 0, 15, 0, 15
        DW      375, 213, 0, 213, 0, 0, 15
        DW      125, 240, 0, 0, 15, 0, 15
        DW      125, 213, 0, 359, 0, 0, 15
        DW      250, 213, 0, 428, 0, 213, 0
        DW      250, 480, 0, 213, 0, 0, 15
        DW      250, 540, 0, 213, 0, 0, 15
        DW      250, 642, 0, 0, 15, 0, 15
        DW      125, 213, 0, 642, 0, 0, 15
        DW      125, 213, 0, 642, 0, 213, 0
        DW      125, 213, 0, 320, 0, 0, 15
        DW      250, 213, 0, 320, 0, 213, 0
        DW      125, 179, 0, 359, 0, 213, 0
        DW      125, 179, 0, 0, 15, 0, 15
        DW      125, 179, 0, 359, 0, 179, 0
        DW      250, 179, 0, 428, 0, 179, 0
        DW      125, 190, 0, 359, 0, 0, 15
        DW      125, 190, 0, 359, 0, 190, 0
        DW      250, 190, 0, 320, 0, 190, 0
        DW      250, 642, 0, 0, 15, 0, 15
        DW      125, 213, 0, 642, 0, 0, 15
        DW      125, 213, 0, 642, 0, 213, 0
        DW      125, 213, 0, 320, 0, 0, 15
        DW      250, 213, 0, 320, 0, 213, 0
        DW      125, 179, 0, 320, 0, 213, 0
        DW      125, 179, 0, 0, 15, 0, 15
        DW      125, 179, 0, 480, 0, 179, 0
        DW      125, 190, 0, 428, 0, 179, 0
        DW      125, 190, 0, 428, 0, 190, 0
        DW      125, 213, 0, 359, 0, 0, 15
        DW      125, 213, 0, 359, 0, 213, 0
        DW      250, 213, 0, 320, 0, 213, 0
        DW      250, 810, 0, 0, 15, 0, 15
        DW      125, 269, 0, 810, 0, 0, 15
        DW      125, 269, 0, 810, 0, 269, 0
        DW      125, 269, 0, 403, 0, 0, 15
        DW      250, 269, 0, 403, 0, 269, 0
        DW      125, 269, 0, 359, 0, 269, 0
        DW      125, 269, 0, 0, 15, 0, 15
        DW      125, 240, 0, 359, 0, 0, 15
        DW      250, 240, 0, 428, 0, 240, 0
        DW      125, 359, 0, 240, 0, 0, 15
        DW      125, 240, 0, 359, 0, 240, 0
        DW      250, 240, 0, 320, 0, 240, 0
        DW      250, 320, 0, 0, 15, 0, 15
        DW      125, 213, 0, 320, 0, 0, 15
        DW      125, 213, 0, 320, 0, 213, 0
        DW      125, 213, 0, 0, 15, 0, 15
        DW      375, 213, 0, 213, 0, 0, 15
        DW      125, 240, 0, 0, 15, 0, 15
        DW      125, 213, 0, 359, 0, 0, 15
        DW      250, 213, 0, 428, 0, 213, 0
        DW      250, 480, 0, 213, 0, 0, 15
        DW      250, 540, 0, 213, 0, 0, 15
        DW      1500, 213, 0, 0, 15, 0, 15
        DW      0,0,0,0


DMSG:	DB	'Happy Birthday.',0DH,0AH,0
DNOTES:
        DW      500, 213, 0, 381, 0, 860, 0
        DW      500, 190, 0, 340, 0, 766, 0
        DW      500, 213, 0, 381, 0, 860, 0
        DW      500, 160, 0, 286, 0, 642, 0
        DW      1000, 169, 0, 320, 0, 682, 0
        DW      500, 213, 0, 381, 0, 860, 0
        DW      500, 190, 0, 340, 0, 766, 0
        DW      500, 213, 0, 381, 0, 860, 0
        DW      500, 142, 0, 254, 0, 573, 0
        DW      1000, 160, 0, 286, 0, 642, 0
        DW      500, 213, 0, 381, 0, 860, 0
        DW      500, 106, 0, 190, 0, 428, 0
        DW      500, 127, 0, 226, 0, 508, 0
        DW      500, 160, 0, 286, 0, 642, 0
        DW      500, 169, 0, 320, 0, 682, 0
        DW      500, 190, 0, 340, 0, 766, 0
        DW      500, 113, 0, 213, 0, 454, 0
        DW      500, 127, 0, 226, 0, 508, 0
        DW      500, 160, 0, 286, 0, 642, 0
        DW      500, 142, 0, 254, 0, 573, 0
        DW      1500, 160, 0, 286, 0, 642, 0
        DW      500, 213, 0, 381, 0, 860, 0
        DW      500, 190, 0, 286, 0, 766, 0
        DW      500, 213, 0, 286, 0, 860, 0
        DW      500, 160, 0, 286, 0, 642, 0
        DW      1000, 169, 0, 381, 0, 573, 0
        DW      500, 213, 0, 573, 0, 0, 15
        DW      500, 190, 0, 381, 0, 573, 0
        DW      500, 213, 0, 381, 0, 573, 0
        DW      500, 142, 0, 381, 0, 682, 0
        DW      1000, 160, 0, 286, 0, 642, 0
        DW      500, 213, 0, 642, 0, 0, 15
        DW      500, 106, 0, 286, 0, 642, 0
        DW      500, 127, 0, 286, 0, 642, 0
        DW      500, 160, 0, 286, 0, 642, 0
        DW      500, 169, 0, 428, 0, 573, 0
        DW      500, 190, 0, 428, 0, 642, 0
        DW      500, 113, 0, 428, 0, 573, 0
        DW      500, 127, 0, 381, 0, 642, 0
        DW      500, 160, 0, 381, 0, 642, 0
        DW      500, 142, 0, 381, 0, 682, 0
        DW      1500, 160, 0, 286, 0, 860, 0
        DW      0,0,0,0

	END	ORIG
