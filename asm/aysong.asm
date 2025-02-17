;	TITLE	'play songs`
;	Scott Baker, www.smbaker.com
;
; 	Plays various songs on the iPDS-100 with PSG multimodule board.
;

	EXTRN	COPEN
	EXTRN	ZSOUT
	EXTRN	EXIT
	EXTRN	PLAY
	EXTRN	MPLAY
	EXTRN 	PSGNIT
	EXTRN	PSGMUT

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
NOTE2	EQU	NOTE1/2*7/8			; see psg.asm for calculation instructions
NOTE4	EQU	NOTE1/4*7/8
NOTE8	EQU	NOTE1/8*7/8
NOTE16	EQU	NOTE1/16*7/8

T60N1	EQU	4000				; tempo=60
T60N2	EQU	T60N1/2*7/8			; see psg.asm for calculation instructions
T60N4	EQU	T60N1/4*7/8
T60N8	EQU	T60N1/8*7/8
T60N16	EQU	T60N1/16*7/8	

T90N1	EQU	3000				; tempo=90
T90N2	EQU	T90N1/2*7/8			; see psg.asm for calculation instructions
T90N4	EQU	T90N1/4*7/8
T90N8	EQU	T90N1/8*7/8
T90N16	EQU	T90N1/16*7/8	

T15N1	EQU	1548				; tempo=155
T15N2	EQU	T15N1/2*7/8			; see psg.asm for calculation instructions
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

	CALL	PSGNIT				; SIL and unmute

AGAIN:
	LDA	FLAGM				; M is for Mute
	CPI	0FFH
	JZ	NOTM
	CALL	PSGMUT				; Do it before any songs
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

	CALL	PSGMUT

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
        DW      T, 338, 13, 0, 0, 0, 0
        DW      T, 254, 14, 403, 8, 1118, 6
        DW      T/2, 254, 14, 403, 8, 677, 6
        DW      T/2, 226, 14, 403, 8, 677, 6
        DW      T/2, 254, 14, 403, 8, 508, 6
        DW      T/2, 269, 14, 403, 8, 508, 6
        DW      T, 302, 14, 380, 8, 760, 6
        DW      T, 302, 14, 380, 8, 604, 6
        DW      T, 302, 14, 380, 8, 508, 6
        DW      T, 226, 14, 380, 8, 909, 6
        DW      T/2, 226, 14, 380, 8, 604, 6
        DW      T/2, 201, 14, 380, 8, 604, 6
        DW      T/2, 226, 14, 380, 8, 452, 6
        DW      T/2, 254, 14, 380, 8, 452, 6
        DW      T, 269, 14, 338, 8, 677, 6
        DW      T, 338, 14, 537, 6, 0, 0
        DW      T, 338, 14, 677, 6, 0, 0
        DW      T, 201, 15, 338, 9, 1016, 6
        DW      T/2, 201, 15, 338, 9, 677, 6
        DW      T/2, 190, 15, 338, 9, 677, 6
        DW      T/2, 201, 15, 338, 9, 508, 6
        DW      T/2, 226, 15, 338, 9, 508, 6
        DW      T, 254, 15, 380, 9, 760, 7
        DW      T, 302, 15, 380, 9, 508, 7
        DW      T/2, 338, 14, 508, 9, 804, 6
        DW      T/2, 338, 14, 508, 9, 0, 0
        DW      T, 302, 15, 380, 9, 760, 7
        DW      T, 226, 15, 380, 9, 604, 7
        DW      T, 269, 14, 338, 8, 452, 6
        DW      T*2, 254, 15, 403, 10, 1016, 7
        DW      T, 338, 13, 0, 0, 0, 0
        DW      T, 254, 13, 403, 7, 1016, 5
        DW      T/2, 254, 13, 403, 7, 677, 5
        DW      T/2, 226, 13, 403, 7, 677, 5
        DW      T/2, 254, 13, 403, 7, 508, 5
        DW      T/2, 269, 13, 403, 7, 508, 5
        DW      T, 302, 13, 380, 7, 760, 5
        DW      T, 302, 13, 380, 7, 604, 5
        DW      T, 302, 13, 380, 7, 508, 5
        DW      T, 226, 14, 380, 8, 909, 6
        DW      T/2, 226, 14, 380, 8, 604, 6
        DW      T/2, 201, 14, 380, 8, 604, 6
        DW      T/2, 226, 14, 380, 8, 452, 6
        DW      T/2, 254, 14, 380, 8, 452, 6
        DW      T, 269, 14, 338, 8, 677, 6
        DW      T, 338, 13, 537, 9, 0, 0
        DW      T, 338, 14, 677, 9, 0, 0
        DW      T, 201, 15, 338, 9, 1016, 6
        DW      T/2, 201, 15, 338, 9, 677, 6
        DW      T/2, 190, 15, 338, 9, 677, 6
        DW      T/2, 201, 15, 338, 9, 508, 6
        DW      T/2, 226, 15, 338, 9, 508, 12
        DW      T, 254, 15, 380, 9, 760, 6
        DW      T, 302, 15, 380, 9, 508, 6
        DW      T/2, 338, 15, 508, 9, 804, 6
        DW      T/2, 338, 15, 508, 9, 0, 0
        DW      T, 302, 15, 508, 9, 0, 0
        DW      T, 302, 15, 380, 9, 760, 6
        DW      T, 226, 15, 302, 9, 909, 6
        DW      T, 269, 15, 380, 9, 677, 6
        DW      T*4, 254, 15, 338, 9, 804, 6
        DW      0,0,15,0,15,0,15

FMSG:   DB	'Axel F.', 0DH, 0AH, 0
FNOTES:
        DW      500, 568, 15, 0, 0, 0, 0
        DW      500, 358, 15, 718, 15, 0, 0
        DW      375, 301, 15, 358, 15, 0, 0
        DW      125, 358, 15, 401, 15, 0, 0
        DW      125, 568, 15, 0, 0, 0, 0
        DW      125, 358, 15, 401, 15, 0, 0
        DW      250, 268, 15, 478, 15, 0, 0
        DW      250, 358, 15, 401, 15, 0, 0
        DW      250, 401, 15, 358, 15, 0, 0
        DW      500, 358, 15, 718, 15, 0, 0
        DW      375, 239, 15, 358, 15, 0, 0
        DW      125, 358, 15, 358, 15, 0, 0
        DW      125, 568, 15, 0, 0, 0, 0
        DW      125, 358, 15, 536, 15, 0, 0
        DW      250, 225, 15, 478, 15, 0, 0
        DW      250, 239, 15, 401, 15, 0, 0
        DW      250, 301, 15, 358, 15, 0, 0
        DW      250, 358, 15, 905, 15, 0, 0
        DW      250, 239, 15, 905, 15, 0, 0
        DW      250, 179, 15, 451, 15, 0, 0
        DW      125, 358, 15, 451, 15, 0, 0
        DW      125, 401, 15, 401, 15, 0, 0
        DW      125, 568, 15, 0, 0, 0, 0
        DW      125, 401, 15, 401, 15, 0, 0
        DW      250, 478, 15, 478, 15, 0, 0
        DW      250, 319, 15, 401, 15, 0, 0
        DW      750, 358, 15, 358, 15, 0, 0
        DW      625, 568, 15, 0, 0, 0, 0
        DW      125, 401, 15, 0, 0, 0, 0
        DW      250, 478, 15, 0, 0, 0, 0
        DW      250, 536, 15, 0, 0, 0, 0
        DW      250, 603, 15, 0, 0, 0, 0
        DW      500, 358, 15, 718, 15, 0, 0
        DW      375, 301, 15, 358, 15, 0, 0
        DW      125, 358, 15, 401, 15, 0, 0
        DW      125, 568, 15, 0, 0, 0, 0
        DW      125, 358, 15, 401, 15, 0, 0
        DW      250, 268, 15, 478, 15, 0, 0
        DW      250, 358, 15, 401, 15, 0, 0
        DW      250, 401, 15, 358, 15, 0, 0
        DW      500, 358, 15, 718, 15, 0, 0
        DW      375, 239, 15, 358, 15, 0, 0
        DW      125, 358, 15, 358, 15, 0, 0
        DW      125, 568, 15, 0, 0, 0, 0
        DW      125, 358, 15, 536, 15, 0, 0
        DW      250, 225, 15, 478, 15, 0, 0
        DW      250, 239, 15, 401, 15, 0, 0
        DW      250, 301, 15, 358, 15, 0, 0
        DW      250, 358, 15, 905, 15, 0, 0
        DW      250, 239, 15, 905, 15, 0, 0
        DW      250, 179, 15, 451, 15, 0, 0
        DW      125, 358, 15, 451, 15, 0, 0
        DW      125, 401, 15, 401, 15, 0, 0
        DW      125, 568, 15, 0, 0, 0, 0
        DW      125, 401, 15, 401, 15, 0, 0
        DW      250, 478, 15, 478, 15, 0, 0
        DW      250, 319, 15, 401, 15, 0, 0
        DW      750, 358, 15, 358, 15, 0, 0
        DW      625, 568, 15, 0, 0, 0, 0
        DW      125, 401, 15, 0, 0, 0, 0
        DW      250, 478, 15, 0, 0, 0, 0
        DW      250, 536, 15, 0, 0, 0, 0
        DW      250, 603, 15, 0, 0, 0, 0
        DW      250, 718, 15, 0, 0, 0, 0
        DW      125, 239, 15, 718, 15, 0, 0
        DW      125, 239, 15, 718, 15, 239, 15
        DW      125, 239, 15, 358, 15, 0, 0
        DW      250, 239, 15, 358, 15, 239, 15
        DW      125, 200, 15, 401, 15, 239, 15
        DW      125, 200, 15, 0, 0, 0, 0
        DW      125, 200, 15, 401, 15, 200, 15
        DW      250, 200, 15, 478, 15, 200, 15
        DW      125, 212, 15, 401, 15, 0, 0
        DW      125, 212, 15, 401, 15, 212, 15
        DW      250, 212, 15, 358, 15, 212, 15
        DW      250, 718, 15, 0, 0, 0, 0
        DW      125, 239, 15, 718, 15, 0, 0
        DW      125, 239, 15, 718, 15, 239, 15
        DW      125, 239, 15, 358, 15, 0, 0
        DW      250, 239, 15, 358, 15, 239, 15
        DW      125, 200, 15, 358, 15, 239, 15
        DW      125, 200, 15, 0, 0, 0, 0
        DW      125, 200, 15, 536, 15, 200, 15
        DW      125, 212, 15, 478, 15, 200, 15
        DW      125, 212, 15, 478, 15, 212, 15
        DW      125, 239, 15, 401, 15, 0, 0
        DW      125, 239, 15, 401, 15, 239, 15
        DW      250, 239, 15, 358, 15, 239, 15
        DW      250, 905, 15, 0, 0, 0, 0
        DW      125, 301, 15, 905, 15, 0, 0
        DW      125, 301, 15, 905, 15, 301, 15
        DW      125, 301, 15, 451, 15, 0, 0
        DW      250, 301, 15, 451, 15, 301, 15
        DW      125, 301, 15, 401, 15, 301, 15
        DW      125, 301, 15, 0, 0, 0, 0
        DW      125, 268, 15, 401, 15, 0, 0
        DW      250, 268, 15, 478, 15, 268, 15
        DW      125, 401, 15, 268, 15, 0, 0
        DW      125, 268, 15, 401, 15, 268, 15
        DW      250, 268, 15, 358, 15, 268, 15
        DW      250, 358, 15, 0, 0, 0, 0
        DW      125, 239, 15, 358, 15, 0, 0
        DW      125, 239, 15, 358, 15, 239, 15
        DW      125, 239, 15, 0, 0, 0, 0
        DW      375, 239, 15, 239, 15, 0, 0
        DW      125, 268, 15, 0, 0, 0, 0
        DW      125, 239, 15, 401, 15, 0, 0
        DW      250, 239, 15, 478, 15, 239, 15
        DW      250, 536, 15, 239, 15, 0, 0
        DW      250, 603, 15, 239, 15, 0, 0
        DW      250, 718, 15, 0, 0, 0, 0
        DW      125, 239, 15, 718, 15, 0, 0
        DW      125, 239, 15, 718, 15, 239, 15
        DW      125, 239, 15, 358, 15, 0, 0
        DW      250, 239, 15, 358, 15, 239, 15
        DW      125, 200, 15, 401, 15, 239, 15
        DW      125, 200, 15, 0, 0, 0, 0
        DW      125, 200, 15, 401, 15, 200, 15
        DW      250, 200, 15, 478, 15, 200, 15
        DW      125, 212, 15, 401, 15, 0, 0
        DW      125, 212, 15, 401, 15, 212, 15
        DW      250, 212, 15, 358, 15, 212, 15
        DW      250, 718, 15, 0, 0, 0, 0
        DW      125, 239, 15, 718, 15, 0, 0
        DW      125, 239, 15, 718, 15, 239, 15
        DW      125, 239, 15, 358, 15, 0, 0
        DW      250, 239, 15, 358, 15, 239, 15
        DW      125, 200, 15, 358, 15, 239, 15
        DW      125, 200, 15, 0, 0, 0, 0
        DW      125, 200, 15, 536, 15, 200, 15
        DW      125, 212, 15, 478, 15, 200, 15
        DW      125, 212, 15, 478, 15, 212, 15
        DW      125, 239, 15, 401, 15, 0, 0
        DW      125, 239, 15, 401, 15, 239, 15
        DW      250, 239, 15, 358, 15, 239, 15
        DW      250, 905, 15, 0, 0, 0, 0
        DW      125, 301, 15, 905, 15, 0, 0
        DW      125, 301, 15, 905, 15, 301, 15
        DW      125, 301, 15, 451, 15, 0, 0
        DW      250, 301, 15, 451, 15, 301, 15
        DW      125, 301, 15, 401, 15, 301, 15
        DW      125, 301, 15, 0, 0, 0, 0
        DW      125, 268, 15, 401, 15, 0, 0
        DW      250, 268, 15, 478, 15, 268, 15
        DW      125, 401, 15, 268, 15, 0, 0
        DW      125, 268, 15, 401, 15, 268, 15
        DW      250, 268, 15, 358, 15, 268, 15
        DW      250, 358, 15, 0, 0, 0, 0
        DW      125, 239, 15, 358, 15, 0, 0
        DW      125, 239, 15, 358, 15, 239, 15
        DW      125, 239, 15, 0, 0, 0, 0
        DW      375, 239, 15, 239, 15, 0, 0
        DW      125, 268, 15, 0, 0, 0, 0
        DW      125, 239, 15, 401, 15, 0, 0
        DW      250, 239, 15, 478, 15, 239, 15
        DW      250, 536, 15, 239, 15, 0, 0
        DW      250, 603, 15, 239, 15, 0, 0
        DW      1500, 239, 15, 0, 0, 0, 0
        DW      0,0,0,0

DMSG:	DB	'Happy Birthday.',0DH,0AH,0
DNOTES:
        DW      500, 239, 15, 426, 15, 961, 15
        DW      500, 212, 15, 379, 15, 856, 15
        DW      500, 239, 15, 426, 15, 961, 15
        DW      500, 179, 15, 319, 15, 718, 15
        DW      1000, 189, 15, 358, 15, 762, 15
        DW      500, 239, 15, 426, 15, 961, 15
        DW      500, 212, 15, 379, 15, 856, 15
        DW      500, 239, 15, 426, 15, 961, 15
        DW      500, 159, 15, 284, 15, 641, 15
        DW      1000, 179, 15, 319, 15, 718, 15
        DW      500, 239, 15, 426, 15, 961, 15
        DW      500, 119, 15, 212, 15, 478, 15
        DW      500, 142, 15, 253, 15, 568, 15
        DW      500, 179, 15, 319, 15, 718, 15
        DW      500, 189, 15, 358, 15, 762, 15
        DW      500, 212, 15, 379, 15, 856, 15
        DW      500, 126, 15, 239, 15, 508, 15
        DW      500, 142, 15, 253, 15, 568, 15
        DW      500, 179, 15, 319, 15, 718, 15
        DW      500, 159, 15, 284, 15, 641, 15
        DW      1500, 179, 15, 319, 15, 718, 15
        DW      500, 239, 15, 426, 15, 961, 15
        DW      500, 212, 15, 319, 15, 856, 15
        DW      500, 239, 15, 319, 15, 961, 15
        DW      500, 179, 15, 319, 15, 718, 15
        DW      1000, 189, 15, 426, 15, 641, 15
        DW      500, 239, 15, 641, 15, 0, 0
        DW      500, 212, 15, 426, 15, 641, 15
        DW      500, 239, 15, 426, 15, 641, 15
        DW      500, 159, 15, 426, 15, 762, 15
        DW      1000, 179, 15, 319, 15, 718, 15
        DW      500, 239, 15, 718, 15, 0, 0
        DW      500, 119, 15, 319, 15, 718, 15
        DW      500, 142, 15, 319, 15, 718, 15
        DW      500, 179, 15, 319, 15, 718, 15
        DW      500, 189, 15, 478, 15, 641, 15
        DW      500, 212, 15, 478, 15, 718, 15
        DW      500, 126, 15, 478, 15, 641, 15
        DW      500, 142, 15, 426, 15, 718, 15
        DW      500, 179, 15, 426, 15, 718, 15
        DW      500, 159, 15, 426, 15, 762, 15
        DW      1500, 179, 15, 319, 15, 961, 15
        DW      0,0,0,0

	END	ORIG
