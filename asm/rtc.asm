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

	EXTRN DOFLAG

	EXTRN FLAGH
	EXTRN FLAGM
	EXTRN FLAGR
	EXTRN FLAGS

	EXTRN PHEXA
	EXTRN PCRLF
	EXTRN PRNDEC

	PUBLIC HOUR
	PUBLIC MIN
	PUBLIC SEC

	EXTRN RTCSTP
	EXTRN RTCTIM
	EXTRN SETHO
	EXTRN SETMI
	EXTRN SETSE

	STKLN	100H				; Size of stack segment

	CSEG

$INCLUDE(PORTS.INC)

ORIG:	LXI	SP, STACK
	CALL	COPEN
	CALL	DOFLAG

	CALL	RTCSTP

	LDA	FLAGH		; argument to set hours?
	CPI	0FFH
	JZ	NOTH
	CALL	SETHO
NOTH:

	LDA	FLAGM		; argument to set minutes?
	CPI	0FFH
	JZ	NOTM
	CALL	SETMI
NOTM:

	LDA	FLAGS		; argument to set seconds?
	CPI	0FFH
	JZ	NOTS
	CALL	SETSE
NOTS:

	CALL	RTCTIM

CHNGD:	CALL	PRNTIM

	LDA	FLAGR
	ORA	A
	JNZ	LEAVE		; No repeat flag, so leave

AGAIN:  CALL	RTCTIM		; Get the time again
	LDA	LSTSEC		; See if the seconds digit has changed
	MOV	B,A
	LDA	SEC
	CMP	B
	JZ	AGAIN		; Nope, keep checking
	STA	LSTSEC
	MVI	C, 0DH		; Print CR to overwrite line
	CALL	COUT
	JMP	CHNGD

LEAVE:	CALL	PCRLF
	CALL 	EXIT

PRNTIM:	LDA	HOUR
	CALL	PRNDEC
	MVI	C, ':'
	CALL	COUT
	LDA	MIN
	CALL	PRNDEC
	MVI	C, ':'
	CALL	COUT
	LDA	SEC
	CALL	PRNDEC
	RET

HOUR:	DB	0
MIN:	DB	0
SEC:	DB	0
LSTSEC: DB	0FFH

	END	ORIG
