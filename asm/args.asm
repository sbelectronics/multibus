;	TITLE	'ISIS ARG PROCESSOR'
;	Scott Baker, www.smbaker.com
;
; ISIS system calls
;
	EXTRN ISIS

	PUBLIC DOFLAG
	PUBLIC FLAGA
	PUBLIC FLAGB
	PUBLIC FLAGC
	PUBLIC FLAGD
	PUBLIC FLAGE
	PUBLIC FLAGF
	PUBLIC FLAGG
	PUBLIC FLAGH
	PUBLIC FLAGI
	PUBLIC FLAGJ
	PUBLIC FLAGK
	PUBLIC FLAGL
	PUBLIC FLAGM
	PUBLIC FLAGN
	PUBLIC FLAGO
	PUBLIC FLAGP
	PUBLIC FLAGQ
	PUBLIC FLAGR
	PUBLIC FLAGS
	PUBLIC FLAGT
	PUBLIC FLAGU
	PUBLIC FLAGV
	PUBLIC FLAGW
	PUBLIC FLAGX
	PUBLIC FLAGY
	PUBLIC FLAGZ

	PUBLIC SETA
	PUBLIC SETB
	PUBLIC SETC
	PUBLIC SETD
	PUBLIC SETE
	PUBLIC SETF
	PUBLIC SETG
	PUBLIC SETH
	PUBLIC SETI
	PUBLIC SETJ
	PUBLIC SETK
	PUBLIC SETL
	PUBLIC SETM
	PUBLIC SETN
	PUBLIC SETO
	PUBLIC SETP
	PUBLIC SETQ
	PUBLIC SETR
	PUBLIC SETS
	PUBLIC SETT
	PUBLIC SETU
	PUBLIC SETV
	PUBLIC SETW
	PUBLIC SETX
	PUBLIC SETY
	PUBLIC SETZ

NOTSET	EQU	255

	CSEG

;; A simple argument processor
;;
;; Reads from stdin. Accepts flags of the form <C><n> where
;; <C> is an uppercase letter and <n> is an optional decimal number.
;; Stores the flag in the FLAG<C> variable. If unset, FLAG<C> will
;; have 0xFF in it.
;;
;; Each flag has both a FLAG<C> variable and a SET<C> variable.
;; The "SET" variable can be used to determine whether a FLAG variable
;; was set (otherwise, it's impossible to determine whether a FLAG
;; is unset or a FLAG is set to 0xFF)

DOFLAG:	MVI	C, 3
	LXI	D, RBLK
	CALL	ISIS			; TODO: status check

	LHLD	FLAG0

	LXI	D, BUFFER
LOOP:	LDAX	D		; A = character from arg string
	INX	D		; point to next character

	CPI	0DH		; Should be terminated with CR
	RZ			; We are done

	ORA	A		; We hit a null ... how?
	RZ			; We are done

LOOP1:	CALL	TOUPPR

	CPI	41H		; less than 'A' ?
	JM	NOTFLG
	CPI	5BH		; Greater than 'Z' ?
	JP	NOTFLG

	SUI	41H		; offset so 'A' = 0

	LXI	H, SETA	; 	HL = (SETA + A)
	ADD	L		; Is there a better way to do HL = HL + A ?
	MOV	L,A
	MOV	A,H
	ACI	0
	MOV	H,A
	MVI	M,0		; set the set bit by storing 0

	MOV	A,L		; Move HL from SETA+A to FLAGA+A
	ADI	(FLAGA-SETA)
	MOV	L,A
	MOV	A,H
	ACI	0
	MOV	H,A
	MVI	M,0		; set initial value of flag to 0

	JMP	LOOP

NOTFLG: CPI	30H		; it's not a flag, is it a digit?
	JM	LOOP		; nope.
	CPI	3AH
	JP	LOOP		; nope.
	JMP	DIGLP1		; yep, switch to digit loop

	JMP	LOOP

; loop for processing decimal numbers

DIGLP:  LDAX	D		; A = character from arg string
	INX	D		; point to next character
	CPI	0DH		; Should be terminated with CR
	RZ			; We are done
	ORA	A		; We hit a null ... how?
	RZ			; We are done
DIGLP1: CALL	TOUPPR
	CPI	058H		; Is "X" ?
	JZ	HEXLP		; Yes. must be hex number
	CPI	30H		; Is it a digit?
	JM	LOOP1		; Nope.
	CPI	3AH		
	JP	LOOP1		; Hope.

	SUI	30H		; offset so '1' = 0
	MOV	B,A		; save A into B

	MOV	A,M		; get current flag value
	CALL	MULA10

	ADD	B		; Add the new lower digit

	MOV	M,A		; store flag back out
	JMP	DIGLP		; Look for next digit

; loop for processing hex numbers

HEXLP:	LDAX	D		; A = character from arg string
	INX	D		; point to next character
	CPI	0DH		; Should be terminated with CR
	RZ			; We are done
	ORA	A		; We hit a null ... how?
	RZ			; We are done
HEXLP1:	CALL	TOUPPR
	CPI	41H		; less than 'A' ?
	JM	NOTAF
	CPI	47H		; Greater than 'F' ?
	JP	NOTAF
	SUI	37H		; A = A - ord('A') + 10D
	JMP	GOTHD
NOTAF:	CPI	30H		; Is it a 0-9 digit?
	JM	LOOP1		; Nope.
	CPI	3AH		
	JP	LOOP1		; Hope.
	SUI	30H		; A = A - ord('0')
GOTHD:	MOV	B,A	        ; Save digit into B
	MOV	A,M		; Get current value
	RLC			; A = A << 4
	RLC
	RLC
	RLC
	ADD	B		; A = A + B
	MOV	M,A		; store flag back out
	JMP	HEXLP		; look for next hex digit

; subroutine - multiply by 10

MULA10: PUSH	B
	MOV	C,A		; C = A
	RLC			; A = A*2
	RLC			; A = A*2
	RLC			; A = A*2
	ANI	0FCH		; mask off any bits carried in
	ADD	C		; A = A + C
	ADD	C		; A = A + C
	POP	B
	RET

; subroutine - convert to uppercase

TOUPPR:	CPI	60H		; is less than 'a' ?
	JM	NOTLC
	CPI	7BH		; Is greater than 'z' ?
	JP	NOTLC
	SUI	20H		; Convert lowercase to upper
NOTLC:	RET

	DSEG
RBLK:
AFT:	DW	1
	DW	BUFFER
	DW	128
	DW	ACTUAL
	DW	STATUS
ACTUAL: DW	0
STATUS:	DW	0
BUFFER: DS	128
	DB	0

;; SET is set to 0xFF if the flags was unset or 0x00 if the flag was set

SETA:	DB	NOTSET
SETB:	DB	NOTSET
SETC:	DB	NOTSET
SETD:	DB	NOTSET
SETE:	DB	NOTSET
SETF:	DB	NOTSET
SETG:	DB	NOTSET
SETH:	DB	NOTSET
SETI:	DB	NOTSET
SETJ:	DB	NOTSET
SETK:	DB	NOTSET
SETL:	DB	NOTSET
SETM:	DB	NOTSET
SETN:	DB	NOTSET
SETO:	DB	NOTSET
SETP:	DB	NOTSET
SETQ:	DB	NOTSET
SETR:	DB	NOTSET
SETS:	DB	NOTSET
SETT:	DB	NOTSET
SETU:	DB	NOTSET
SETV:	DB	NOTSET
SETW:	DB	NOTSET
SETX:	DB	NOTSET
SETY:	DB	NOTSET
SETZ:	DB	NOTSET

;; FLAG contains the initial value of the flag. Default is 0xFF.

FLAG0:	DB	NOTSET
FLAGA:	DB	NOTSET
FLAGB:	DB	NOTSET
FLAGC:	DB	NOTSET
FLAGD:	DB	NOTSET
FLAGE:	DB	NOTSET
FLAGF:	DB	NOTSET
FLAGG:	DB	NOTSET
FLAGH:	DB	NOTSET
FLAGI:	DB	NOTSET
FLAGJ:	DB	NOTSET
FLAGK:	DB	NOTSET
FLAGL:	DB	NOTSET
FLAGM:	DB	NOTSET
FLAGN:	DB	NOTSET
FLAGO:	DB	NOTSET
FLAGP:	DB	NOTSET
FLAGQ:	DB	NOTSET
FLAGR:	DB	NOTSET
FLAGS:	DB	NOTSET
FLAGT:	DB	NOTSET
FLAGU:	DB	NOTSET
FLAGV:	DB	NOTSET
FLAGW:	DB	NOTSET
FLAGX:	DB	NOTSET
FLAGY:	DB	NOTSET
FLAGZ:	DB	NOTSET

	END
