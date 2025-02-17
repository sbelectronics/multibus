;	TITLE	'argument test`
;	Scott Baker, www.smbaker.com
;
;	A simple test for args.asm
;
;	Call with "argtest A C13 D47 Z" or similar
;	   should print A=0, C=0D, D=2F, Z=0. Others = FF
;
;	Can use hex numbers by using "0X"
;	   for example "argtes J 0X3F"
;
; ISIS system calls
;
	EXTRN COUT
	EXTRN CIN
	EXTRN ZSOUT
	EXTRN COPEN
	EXTRN EXIT

	EXTRN PSPACE
	EXTRN PHEXA
	EXTRN PCRLF

	EXTRN DOFLAG
	EXTRN FLAGA

	STKLN	100H				; Size of stack segment

	CSEG	

ORIG:	LXI	SP, STACK
	CALL	COPEN
	CALL	DOFLAG

	; --------- get ready to print ---------

	MVI	C,0
	LXI	D, FLAGA		; DE = buffer

	; --------- loop through the arguments ---------

LOOP:	PUSH	B
	MOV	A,C
	ADI	41H
	MOV	C,A
	CALL	COUT
	POP	B

	CALL	PSPACE
	LDAX	D
	CALL	PHEXA
	CALL	PCRLF

	INX	D

	INR	C
	MOV	A,C
	CPI	26
	JNZ	LOOP

	CALL 	EXIT

	END	ORIG
