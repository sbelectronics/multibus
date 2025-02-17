;
; ISIS system calls
;
	EXTRN COPEN
	EXTRN ZSOUT
	EXTRN EXIT
	EXTRN PHEXA
	EXTRN PCRLF
;
;
;-------------------------------------------------------

	STKLN	100H				; Size of stack segment

	CSEG

ORIG:	NOP					; Some NOPs makes it easier for the disassembler to sync
	NOP
	NOP
	LXI	SP,0F200H			; Setup initial stack
	CALL	COPEN				; Open the console
	LXI	D, BANNER			; Load Hello String
	CALL	ZSOUT				; Print string

	LXI	H,START
TESTLP:
	MVI	A, 0
	MOV	M, A
	MOV	B, M
	CMP	B
	JNZ	ERR

	MVI	A, 1
	MOV	M, A
	MOV	B, M
	CMP	B
	JNZ	ERR

	MVI	A, 2
	MOV	M, A
	MOV	B, M
	CMP	B
	JNZ	ERR

	MVI	A, 4
	MOV	M, A
	MOV	B, M
	CMP	B
	JNZ	ERR

	MVI	A, 8
	MOV	M, A
	MOV	B, M
	CMP	B
	JNZ	ERR

	MVI	A, 10H
	MOV	M, A
	MOV	B, M
	CMP	B
	JNZ	ERR

	MVI	A, 20H
	MOV	M, A
	MOV	B, M
	CMP	B
	JNZ	ERR

	MVI	A, 40H
	MOV	M, A
	MOV	B, M
	CMP	B
	JNZ	ERR

	MVI	A, 80H
	MOV	M, A
	MOV	B, M
	CMP	B
	JNZ	ERR

	INX	H
	MOV	A,H
	CPI	0F0H
	JZ	DONE

	JMP	TESTLP

ERR:	PUSH	B
	PUSH	PSW
	PUSH	H
	PUSH	H
	LXI	D, ERRM
	CALL	ZSOUT
	POP	H
	MOV	A,H
	CALL	PHEXA
	POP	H
	MOV	A,L
	CALL	PHEXA
	LXI	D, VALM
	CALL	ZSOUT
	POP	PSW
	CALL	PHEXA
	LXI	D, ACTM
	CALL	ZSOUT	
	POP	B
	MOV	A,B
	CALL	PHEXA
	CALL	PCRLF
	JMP	EXIT
	
DONE:	LXI	D,DONEM
	CALL	ZSOUT
	JMP	EXIT				; Exit to ISIS

BANNER:	DB	'Memory Test', 0DH, 0AH, 0

ERRM:	DB	'Memory Error:', 0

VALM:	DB	' Expected:',0

ACTM:	DB	' Actual:',0

DONEM:	DB	'Success', 0DH, 0AH, 0

	DSEG
START:	DB	0

	END	ORIG
