$macrofile

; Conway's Game of Life, ISIS-II Port
; Scott Baker, https://www.smbaker.com/
;
; Based on my 8008 Game of Life for the 8008 CPU.
; No attempts made to optimize for 8080 instruction set.
;
; Supports Four command-line arguments:
;
; H - prints help message and exits
; I<n> - set number of iterations (0..254). If unset, runs forever
; R<n> - set number of rows (12, 16, 20, or 24)
; W - start without waiting
;
; Example: "LIFE R16 I5" ... 16 rows, 5 iterations

;
;
;-------------------------------------------------------

COLDEC	MACRO                                ; decrement column by 1
	mov a,l
	ani 0C0H
	mov c,a                              ; C has bits 7,6 of L
	mov a,l
	sui 1
	ani 03FH
	ora c
	mov l,a
	ENDM

COLINC	macro                                ; increment column by 1
	mov a,l
	ani 0C0H
	mov c,a                              ; C has bits 7,6 of L
	mov a,l
	adi 1
	ani 03FH
	ora c
	mov l,a
	endm

ROWDEC	macro                                ; decrement row by 1
	local	nowrap
	mov a,l
	sui 040H
	mov l,a
	mov a,h
	sbi 0H
	cpi CONPAGE-1
	jnz nowrap
	lda LPAGE				; wrap to last page
nowrap:	mov h,a
	endm

ROWINC	macro                                ; increment row by 1
	local	nowrap
	mov a,l
	adi 040H
	mov l,a
	mov a,h
	aci 0H
	mov c,a					; save A into C
	lda OPAGE				; A = overflow page number
	cmp c					; at overflow?
	mov a,c					; restore A from C
	jnz nowrap
	mvi a,CONPAGE
nowrap:	mov h,a
	endm

PRSPACE	macro
	push b
	mvi c,' '
	call CO
	pop b
	endm

PRSTAR	macro
	push b
	mvi c,'*'
	call CO
	pop b
	endm

;
; ISIS system calls
;
	EXTRN EXIT
	EXTRN CO
	EXTRN CI
	EXTRN CSTS
	EXTRN DOFLAG
	EXTRN FLAGH
	EXTRN FLAGR
	EXTRN FLAGI
	EXTRN FLAGW

	STKLN	100H				; Size of stack segment

CONPAGE EQU	080H				; start the playfield at 0x8000
CONNEXT EQU	088H

NROW	EQU	20				; number of rows
DNPAGE	EQU	NROW/4				; number of pages

LF	EQU	0AH

	CSEG

ORIG:	LXI	SP,STACK			; Setup initial stack

	CALL	DOFLAG

	; --------- check the R flag ---------

	LDA	FLAGR				; Check for R<n> flag
	CPI	0FFH
	JZ	NOTR
	RRC					; Divide number of rows by 4
	RRC
	ANI	0FH
	STA	NPAGE				; Store it in NPAGE
NOTR:

	; --------- check the H flag ---------

	LXI	D, BANNER			; Load Hello String
	CALL	ZSOUT				; Print string

	LDA	FLAGH				; If -H is specified then just exit
	CPI	0FFH
	JZ	NOTH
	CALL	EXIT
NOTH:

	; --------- check the W flag ---------

	LDA	FLAGW				; If W flag isn't specified, then wait
	CPI	0FFH
	JNZ	YESW
	LXI	D, WAIT
	CALL	ZSOUT
	CALL	CI
YESW:

	; --------- initialize ---------

	;; the banner will immediately be overwritten
	CALL	CLRSCR

	CALL	RESET

	CALL	TOP
	CALL	COPY

	; --------- run loop ---------

	; --------- check I flag ---------

FOREVR:
	LDA	FLAGI				; Is I<n> flag set?
	CPI	0FFH
	JZ	NOTI				; Nope
	MOV	B,A				; Yep. Compare iteration count and bail
	LDA	ITER				; if done.
	CMP	B
	JZ	BAIL
NOTI:

	; --------- perform iteration ---------

	CALL	FULL
	CALL	TOP
	CALL	COPY

	; --------- update iteration count ---------

	LDA	ITER
	ADI	1
	STA	ITER
	LDA	ITER+1
	ACI	0
	STA	ITER+1

	; --------- check for ESC ---------

	CALL	CSTS				; Key pressed?
	CPI	0FFH
	JNZ	NOKEY
	CALL	CI				; Was it ESC?
	CPI	01BH
	JNZ	NOKEY
	JMP	BAIL
NOKEY:

	JMP	FOREVR

BAIL:
	CALL	EXIT				; Exit to ISIS

BANNER:	DB	'Conway', 027H, 's Game of Life!', 0DH, 0AH
	DB	'Scott Baker, http://www.smbaker.com/', 0DH, 0AH
	DB	'Flags:',0DH,0AH
	DB	'  H     ... Help', 0DH, 0AH
	DB	'  W     ... Do not wait', 0DH, 0AH	
	DB	'  R<n>  ... Set number of rows (12, 16, 20, or 24)', 0DH, 0AH
	DB	'  I<n>  ... Set number of iterations (0..254)', 0DH, 0AH
	DB	'            (if unspecified, runs forever)', 0DH, 0AH
	DB	0

WAIT:	DB	0DH, 0AH, 'Press any key to start', 0

;-------------- screen manipulation -----------------

HOME:	MVI	C,01BH
	CALL	CO
	MVI	C,'H'
	CALL	CO
	RET

TOP:	MVI	C,01BH				; Move cursor to 0,0
	CALL	CO
	MVI	C,'Y'
	CALL	CO
	MVI	C,20H
	CALL	CO
	MVI	C,20H
	CALL	CO
	RET

FOOT:	MVI	C,01BH				; Move cursor to 2 lines from bottom
	CALL	CO
	MVI	C,'Y'
	CALL	CO
	MVI	C,20H
	CALL	CO
	MVI	C,34H
	CALL	CO
	RET

CLRSCR:	MVI	C,01BH				; clear screen
	CALL	CO
	MVI	C,'E'
	CALL	CO
	RET

GRAPH:	MVI	C,01BH				; enter graphics mode
	CALL	CO
	MVI	C,'G'
	CALL	CO
	RET

NORM:	MVI	C,01BH				; leave graphics mode
	CALL	CO
	MVI	C,'N'
	CALL	CO
	RET

;-------------- RESET ----------------

RESET:	lda NPAGE
	adi CONPAGE
	sta OPAGE
	sui 1
	sta LPAGE

	mvi h,CONPAGE
	mvi l,0
	mvi c,00EH                           ; Clear 8 blocks on the first page and 6 on the second
RESETL:
	mvi m,0
	inr l
	jnz RESETL
	inr h

	dcr c
	jnz RESETL

	;; load a glider

	mvi h,CONNEXT	                     ; put the glider in the new screen
	mvi l,001H
	mvi m,1
	mvi l,042H
	mvi m,1
	mvi l,080H
	mvi m,1
	mvi l,081H
	mvi m,1
	mvi l,082H
	mvi m,1
	ret

;------------ COPY ------------
COPY:
	mvi h, CONNEXT
	mvi l,0
	call COPBLK
	call COPBLK
	call COPBLK
	LDA	NPAGE				; Bail if only 4 pages (16 rows)
	CPI	3
	RZ	

	call COPBLK
	LDA	NPAGE				; Bail if only 4 pages (16 rows)
	CPI	4
	RZ

	call COPBLK
	LDA	NPAGE				; Bail if only 5 pages (20 rows)
	CPI	5
	RZ

	call COPBLK

	ret

COPBLK:
	mvi d,04H                               ; 4 rows
COPLPR:
	mvi c,040H                              ; 64 columns
COPLPC:
	mov a,m
	ora a
	jnz COPALV
	PRSPACE
	mvi b,0
	jmp COPSET
COPALV:
	PRSTAR
	mvi b,1
COPSET:
	mov a,h
	ani 0F7H                                 ; copy to old
	mov h,a
	mov m,b
	ori 08H                                 ; set H back to new
	mov h,a
	inr l
	jnz COPNW
	inr h
COPNW:
	dcr c
	jnz COPLPC
	mvi c,0DH
	call CO
	mvi c,0AH
	call CO
	dcr d
	jnz COPLPR
	ret

;----------- FULL ------------

FULL:
	mvi d, CONPAGE
	mvi e, 0
	call BLOCK
	call BLOCK
	CALL BLOCK
	LDA	NPAGE				; Bail if only 4 pages (16 rows)
	CPI	3
	RZ	

	call BLOCK
	LDA	NPAGE				; Bail if only 4 pages (16 rows)
	CPI	4
	RZ

	call BLOCK
	LDA	NPAGE				; Bail if only 5 pages (20 rows)
	CPI	5
	RZ

	call BLOCK

	ret

;----------- BLOCK ------------

BLOCK:
BLOCKL:
;;           mov a,e
;;           out LEDPORT                          ; for debugging

	mov h,d
	mov l,e
	mov a,m

	ora a
	jz dead
ALIVE:
	call CELL
	mov a,b
	cpi 2                                ; exactly 2 neighbors?
	jz SALIVE
	cpi 3                                ; exactly 2 neighbors?
	jz SALIVE
	mvi b,0
	jmp UPDATE
SALIVE: mvi b,1
	jmp UPDATE
DEAD:
	call CELL
	mov a,b
	cpi 3                                ; are there exactly 3 neighbors
	jnz SDEAD
	mvi b,1
	jmp UPDATE
SDEAD:  mvi b,0
UPDATE:                                         ; b==0 if dead, b==1 if alive
	mov a,d
	ori 08H                              ; go forward 2K
	mov h,a
	mov l,e
	mov m,b                              ; store the new cell

	inr e
	jnz BLOCKL                      ; do all 256 entries in the block

	inr d                                ; at the end of the loop, we wrapped so increment d

	ret

;----------- CELL ------------	

CELL:
	coldec                               ; (R-1, C-1)
	rowdec
	mov a,m
	mov b,a

	colinc                               ; (R-1, C)
	mov a,m
	add b
	mov b,a

	colinc                               ; (R-1, C+1)
	mov a,m
	add b
	mov b,a

	rowinc                               ; (R, C+1)
	mov a,m
	add b
	mov b,a

	coldec                               ; (R, C-1)
	coldec
	mov a,m
	add b
	mov b,a

	rowinc                               ; (R+1,C-1)
	mov a,m
	add b
	mov b,a

	colinc                               ; (R+1, C)
	mov a,m
	add b
	mov b,a

	colinc                               ; (R+1, C+1)
	mov a,m
	add b
	mov b,a
	ret

;----------- ZSOUT: print zero terminated string -----------

ZSOUT:	PUSH	PSW
	PUSH	B
ZSOUT0:	LDAX	D		; String in DE. Not Preserved.
	ORA	A
	JZ	ZSOUT1
	MOV	C,A
	CALL	CO
	INX	D
	JMP	ZSOUT0
ZSOUT1: POP	B
	POP	PSW
	RET

;----------- DATA --------------

	DSEG
ITER:	DW	0
NPAGE:	DB	DNPAGE				; number of pages (each page is 4 rows)
LPAGE:	DS	1				; last page number (computed in RESET)
OPAGE:	DS	1				; overflow - one page after last page number (computed in RESET)

;----------- END ---------------


	END	ORIG
