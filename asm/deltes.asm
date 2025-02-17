;
; ISIS system calls
;
	EXTRN COPEN
	EXTRN ZSOUT
	EXTRN EXIT
	EXTRN DELAYS
;
;
;-------------------------------------------------------

	STKLN	100H				; Size of stack segment

	CSEG

ORIG:	NOP					; Some NOPs makes it easier for the disassembler to sync
	NOP
	NOP
	LXI	SP,STACK			; Setup initial stack
	CALL	COPEN				; Open the console
	LXI	D, STARTM			; Load Hello String
	CALL	ZSOUT				; Print string

	MVI	A,60				; 60 second delay
	CALL	DELAYS

	LXI	D,ENDM
	CALL	ZSOUT
	CALL	EXIT				; Exit to ISIS

STARTM:	DB	'Start!', 0DH, 0AH, 0
ENDM:	DB	'End!', 0DH, 0AH, 0

	END	ORIG
