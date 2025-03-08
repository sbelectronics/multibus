$macrofile

	EXTRN	THE
	EXTRN	TIME
	EXTRN	IS
	EXTRN	AM
	EXTRN	PM
	EXTRN	OH
	EXTRN	OCLOCK
	EXTRN	ONE
	EXTRN	TWO
	EXTRN	THREE
	EXTRN	FOUR
	EXTRN	FIVE
	EXTRN	SIX
	EXTRN	SEVEN
	EXTRN	EIGHT
	EXTRN	NINE
	EXTRN	TEN
	EXTRN	ELEVEN
	EXTRN	TWELVE
	EXTRN	THIRTEEN
	EXTRN	FOURTEEN
	EXTRN	FIFTEEN
	EXTRN	SIXTEEN
	EXTRN	SEVENTEEN
	EXTRN	EIGHTEEN
	EXTRN	NINETEEN
	EXTRN	TWENTY
	EXTRN	THIRTY
	EXTRN	FOURTY
	EXTRN	FIFTY
	EXTRN	GOOD
	EXTRN	MORNING
	EXTRN	AFTERNOON
	EXTRN	EVENING
	EXTRN	PAUSE

	EXTRN	TMSEXT

	PUBLIC	V7NUM
	PUBLIC	V7NLZ
	PUBLIC	V7TTIS

	CSEG

V7NUM:	PUSH	PSW
	ORA	A
	JZ	SAYZ
	CPI 	50
	JNC 	S50
	CPI 	40
	JNC	S40
	CPI	30
	JNC	S30
	CPI	20
	JNC	S20
	JMP	SAYLT
S50:	PUSH	PSW
	SUI	50
	LXI	D, FIFTY
	JMP	SAYGT
S40:	PUSH	PSW
	SUI	40
	LXI	D, FOURTY
	JMP	SAYGT
S30:	PUSH	PSW
	SUI	30		; save A-30
	LXI	D, THIRTY
	JMP	SAYGT
S20:	PUSH	PSW
	SUI	20		; save A-20
	LXI	D, TWENTY
	JMP	SAYGT
SAYGT:	CALL	TMSEXT
	POP	PSW
SAYLT:	ORA	A		; say for < 20
	JZ	SAYOUT		; We already handled explicit zero, so say nothing

	RLC			; A = A * 2
	MOV	B, A		; Save A in B
	LXI	D, NUMTAB
	MOV	A,E		; Add to low byte
	ADD	B
	MOV	E,A
	MOV	A,D		; Carry into high byte
	ACI	0
	MOV	D,A

SAYN:	CALL	TMSEXT
	JMP	SAYOUT
SAYZ:				; nothing to say for zero
SAYOUT:
	POP	PSW		; restore callee's A
	RET

; V7NLZ - like V7NUM but leading "o" if less than 10

V7NLZ:	CPI	10
	JNC	V7LZ1
	LXI	D, OH
	CALL	TMSEXT
V7LZ1:	JMP	V7NUM

; V7TTIS - say "this time is"

V7TTIS:	LXI	D, THE
	CALL	TMSEXT
	LXI	D, TIME
	CALL	TMSEXT
	LXI	D, IS
	CALL	TMSEXT
	RET

NUMTAB:	DW	OH
	DW	ONE
	DW	TWO
	DW	THREE
	DW	FOUR
	DW	FIVE
	DW	SIX
	DW	SEVEN
	DW	EIGHT
	DW	NINE
	DW	TEN
	DW	ELEVEN
	DW	TWELVE
	DW	THIRTEEN
	DW	FOURTEEN
	DW	FIFTEEN
	DW	SIXTEEN
	DW	SEVENTEEN
	DW	EIGHTEEN
	DW	NINETEEN

	END
