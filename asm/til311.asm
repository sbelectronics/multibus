$macrofile

;	TITLE	'til311`
;	Scott Baker, www.smbaker.com
;
;	For scott's TIL311 module
;
;	Use L, M, R for the three digits. If any are unset,
;       they will be set to FF.
;
;	For example,
;	   "til311 L 0x12 M 0x34 R 0x56"

; ISIS system calls
;
	EXTRN COUT
	EXTRN CIN
	EXTRN ZSOUT
	EXTRN COPEN
	EXTRN EXIT

	EXTRN DOFLAG
	EXTRN FLAGL
	EXTRN FLAGM
	EXTRN FLAGR
	EXTRN FLAGB

	EXTRN SETL
	EXTRN SETM
	EXTRN SETR
	EXTRN SETB
	EXTRN SETI

	EXTRN PHEXA
	EXTRN PCRLF

	STKLN	100H				; Size of stack segment

	CSEG

$INCLUDE(PORTS.INC)

ORIG:	LXI	SP, STACK
	CALL	COPEN
	CALL	DOFLAG

	LDA	SETL
	ORA	A
	JNZ	NOTL
	LDA	FLAGL
	OUT	TILL
NOTL:

	LDA	SETM
	ORA	A
	JNZ	NOTM
	LDA	FLAGM
	OUT	TILM
NOTM:

	LDA	SETR
	ORA	A
	JNZ	NOTR
	LDA	FLAGR
	OUT	TILR
NOTR:

	LDA	SETB
	ORA	A
	JNZ	NOTB
	LDA	FLAGB
	XRI	0FFH
	OUT	TILB
NOTB:

	LDA	SETI
	ORA	A
	JNZ	NOTI
	IN	TILI
	CALL	PHEXA
	CALL	PCRLF
NOTI:

	CALL 	EXIT

	END	ORIG
