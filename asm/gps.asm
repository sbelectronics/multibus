$macrofile

;	TITLE	'gps`
;	Scott Baker, www.smbaker.com
;
;	For scott's GPS MODULE

; ISIS system calls
;
	EXTRN COUT
	EXTRN CIN
	EXTRN ZSOUT
	EXTRN COPEN
	EXTRN EXIT

	EXTRN DOFLAG
	EXTRN FLAGR

	EXTRN PHEXA
	EXTRN PCRLF
	EXTRN PRNDEC

	PUBLIC	HOUR
	PUBLIC	MIN
	PUBLIC	SEC
	PUBLIC	GPSST

	EXTRN GPSSTP
	EXTRN GPSIDL

	STKLN	100H				; Size of stack segment

	CSEG

$INCLUDE(PORTS.INC)

ORIG:	LXI	SP, STACK
	CALL	COPEN
	CALL	DOFLAG

	CALL	GPSSTP

AGAIN:	CALL	GPSIDL		; Call the GPS idle function
	LDA	GPSST
	CPI	14		; State 14 means we read the last seconds digit
	JNZ	AGAIN

	MVI	C, 0DH		; Print CR to overwrite line
	CALL	COUT

	CALL	PRNTIM

	LDA	FLAGR
	ORA	A
	JNZ	LEAVE		; No repeat flag, so leave

	JMP	AGAIN

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

GPSST:  DB	0		; state
HOUR:	DB	0
MIN:	DB	0
SEC:	DB	0

	END	ORIG
