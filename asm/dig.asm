$macrofile

;	TITLE	'dig`
;	Scott Baker, www.smbaker.com
;
;	For scott's digitalker module

; ISIS system calls
;
	EXTRN COUT
	EXTRN CIN
	EXTRN ZSOUT
	EXTRN COPEN
	EXTRN EXIT

	EXTRN DOFLAG
	EXTRN FLAGN

	EXTRN DIGSTP
	EXTRN DIGTST
	EXTRN DIGNUM

	STKLN	100H				; Size of stack segment

	CSEG

$INCLUDE(PORTS.INC)

ORIG:	LXI	SP, STACK

	CALL	COPEN
	CALL	DOFLAG

	CALL	DIGSTP

	LDA	FLAGN		; argument to set hours?
	CPI	0FFH
	JZ	NOTN
	CALL	DIGNUM
	JMP	DONE

NOTN:
	CALL	DIGTST
DONE:
	CALL	EXIT

	END	ORIG
