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

	EXTRN DIGSTP
	EXTRN DIGTST

	STKLN	100H				; Size of stack segment

	CSEG

$INCLUDE(PORTS.INC)

ORIG:	LXI	SP, STACK

	CALL	DIGSTP
	CALL	DIGTST
	CALL	EXIT

	END	ORIG
