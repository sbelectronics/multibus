;
; ISIS system calls
;
	EXTRN COPEN
	EXTRN ZSOUT
	EXTRN EXIT
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
	LXI	D, HELLO			; Load Hello String
	CALL	ZSOUT				; Print string
	CALL	EXIT				; Exit to ISIS

HELLO:	DB	'Hello, World!', 0DH, 0AH, 0

	END	ORIG
