$macrofile

;	TITLE	'rtc`
;	Scott Baker, www.smbaker.com
;
;	For scott's DSM5832 RTC module
;
;	For example,
;	   "RTC" - display current time and exit
;	   "RTC R" - display current time and repeat forever
;	   "RTC H 01 M 02 S 03" - set hours to 1, minutes to 2, and seconds to 3

; ISIS system calls
;
	EXTRN COUT
	EXTRN CIN
	EXTRN ZSOUT
	EXTRN COPEN
	EXTRN EXIT

	EXTRN VTXNIT
	EXTRN VTXSAY

	EXTRN DOFLAG
	EXTRN FLAGC
	EXTRN FLAGD
	EXTRN FLAGE
	EXTRN FLAGV

	STKLN	100H				; Size of stack segment

	CSEG

$INCLUDE(PORTS.INC)

ORIG:	LXI	SP, STACK
	CALL	COPEN
	CALL	DOFLAG

	CALL	VTXNIT

AGAIN:
	LDA	FLAGD
	CPI	0FFH
	JZ	NOTD
	LXI	B, DAISYL
	LXI	D, DAISY
	CALL	VTXSAY
NOTD:
	LDA	FLAGE
	CPI	0FFH
	JZ	NOTE
	LXI	B, DAISYL
	LXI	D, DAISY
	CALL	VTXSAY
NOTE:
	LDA	FLAGV
	CPI	0FFH
	JZ	NOTV
	STA	PLAYD
	LXI	B, VTXL
	LXI	D, VTXMSG
	CALL	VTXSAY
NOTV:
	LDA	PLAYD
	CPI	0FFH
	JNZ	NOHELP
	STA	PLAYD
	LXI	D, HELP
	CALL	ZSOUT
NOHELP:
	LDA	FLAGC				; Conntinous
	CPI	0FFH
	JNZ	AGAIN

	CALL	EXIT				; Exit to ISIS

PLAYD:  DB	0FFH

BANNER:	DB	'VOTRAX TEST TOOL', 0DH, 0AH
	DB	'SCOTT BAKER, WWW.SMBAKER.COM', 0DH, 0AH,0
HELP:	DB      '      D=DAISY, V=VOTRAX', 0DH, 0AH
        DB      '      C=CONTINUOUS', 0DH, 0AH
	DB	00H

VTXMSG: DB	15
	DB	38
	DB	42
	DB	43
	DB	46
	DB	25
	DB	31
	DB	63
VTXL	EQU	$-VTXMSG

DAISY:  DB      01EH,006H,021H,021H,021H,021H,021H,021H
        DB      012H,012H,069H,069H,069H,069H,069H,0C3H
        DB      05EH,046H,061H,061H,061H,061H,061H,061H
        DB      092H,092H,0E9H,0E9H,0E9H,0E9H,0E9H,0AAH
        DB      082H,080H,098H,08CH,07CH,069H,069H,074H
        DB      074H,07AH,0FFH,0AFH,0BBH,0BBH,04DH,05FH
        DB      07AH,06BH,0EAH,0EBH,0F6H,0E8H,0E8H,0E8H
        DB      0FEH,0FEH,0FEH,0C3H,095H,080H,089H,0A2H
        DB      0A2H,0A2H,0A2H,0A2H,08CH,01BH,02FH,03BH
        DB      002H,001H,01DH,019H,02BH,006H,021H,029H
        DB      029H,029H,029H,052H,069H,069H,069H,069H
        DB      069H,083H,083H,0BDH,098H,0BFH,05DH,075H
        DB      06BH,0FFH,078H,072H,072H,0FFH,018H,033H
        DB      032H,032H,00FH,0B2H,0B2H,08FH,0BFH,0E2H
        DB      0F6H,0E8H,0E8H,0F7H,0FEH,0FEH,0FEH,0FEH
        DB      0CBH,0C9H,0EAH,06DH,075H,04DH,06AH,08EH
        DB      0BCH,0A9H,0BFH,0F3H,0FFH,01FH,02AH,015H
        DB      069H,069H,062H,062H,018H,067H,051H,08CH
        DB      081H,081H,0ABH,0E7H,0DEH,0DAH,0FEH,0FEH
        DB      0FEH,0FEH,0C3H,0D5H,0C0H,0C9H,0E9H,0E9H
        DB      099H,06FH,07BH,04DH,02AH,0C3H,073H,09DH
        DB      0A6H,0BAH,0ABH,09EH,0FEH,0F3H,0C3H,059H
        DB      041H,080H,06BH,0E7H,0DEH,0DAH,0FEH,0FEH
        DB      0FEH,0FEH,0CEH,0F2H,0B1H,0AAH,062H,076H
        DB      077H,077H,058H,0FFH,058H,056H,056H,059H
        DB      09FH,0ADH,0BCH,0A9H,0AAH,0FEH,0C3H,0F2H
        DB      0E5H,095H,0B2H,08DH,083H,038H,032H,031H
        DB      05FH,07CH,061H,06AH,0FEH,072H,063H,04FH
        DB      046H,061H,069H,00EH,023H,008H,029H,022H
        DB      01FH,04BH,059H,0A3H,098H,04EH,04BH,04AH
        DB      058H,06AH,0DDH,0F4H,0F4H,0EBH,06AH,076H
        DB      068H,068H,077H,077H,0FEH,0FEH,0FFH

DAISYL  EQU     $-DAISY

	END	ORIG
