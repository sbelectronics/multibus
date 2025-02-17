;	TITLE	'print utils`
;	Scott Baker, www.smbaker.com
;
; 	Utils for printing hex digits and similar
;
; ISIS system calls
;
	EXTRN COUT

	PUBLIC	PSPACE
	PUBLIC	PCRLF
	PUBLIC	PHEXA
	PUBLIC	PBINA
	PUBLIC	PRNDEC
	PUBLIC	DIV10
	PUBLIC	MUL10

	CSEG

	; --------- print a space ---------

PSPACE:	PUSH	PSW
	PUSH	B
	PUSH	D
	MVI	C,' '
	CALL	COUT
	POP	D
	POP	B
	POP	PSW
	RET

	; --------- print CR/LF ---------

PCRLF:	PUSH	PSW
	PUSH	B
	PUSH	D
	MVI	C,0DH
	CALL	COUT
	MVI	C,0AH
	CALL	COUT
	POP	D
	POP	B
	POP	PSW
	RET

	; --------- print 8-bit hex in A register ---------

PHEXA:	push psw
	push b
	push d
	mov b,a
	rrc                     ; rotate most significant nibble into lower 4 bits
	rrc
	rrc
	rrc
	call HEXASC          ; convert the most significand digit to ascii
	mov c,a
	call COUT
	mov a,b                 ; restore
	call HEXASC
	mov c,a
	call COUT
	pop d
	pop b
	pop psw
	ret

	; --------- helper: convert nibble in A to hex character ---------

HEXASC:	push b
	ani 0FH                 ; mask all but the lower nibble
	mov b,a                 ; save the nibble in E
	sui 10
	mov a,b
	jc HEXAS1           ; jump if the nibble is less than 10
	adi 7                   ; add 7 to convert to A-F
HEXAS1:	adi 30H
	pop b
	ret

	; ----------- PRNDEC - prints 2-digit 0 padded decimal number --------
	; Code credt goes to copilot
	
PRNDEC: PUSH    PSW
	PUSH	B
	MOV     B, A          ; Save A in B
	CALL    DIV10         ; Divide A by 10, quotient in A, remainder in B
	ADI     30H           ; Convert quotient to ASCII
	MOV	C, A
	CALL	COUT
	MOV     A, B          ; Move remainder to A
	ADI     30H           ; Convert remainder to ASCII
	MOV	C, A
	CALL	COUT
	POP	B
	POP     PSW
	RET

	; ----------- DIV10 - divide A by 10, return divisor in A and rem in B ------
	; Code credt goes to copilot

DIV10:  MVI     C, 0          ; Clear D
DIVLP:  CPI     0AH           ; Compare A with 10
	JC      DIVEND        ; If A < 10, jump to DIVEND
	SUI	0AH           ; Subtract 10 from A
	INR     C             ; Increment quotient in D
	JMP     DIVLP         ; Repeat until A < 10
DIVEND: MOV     B, A          ; Move remainder to B
	MOV     A, C          ; Move quotient to A
	RET

	; -------- MUL10 - multiply A by 10, return in A, destroys B ------
	; Code credt goes to copilot

MUL10: 	MOV     B, A          ; Save A in B
	ADD     A             ; A = A * 2
	ADD     A             ; A = A * 4
	ADD     A             ; A = A * 8
	ADD     B             ; A = A + B (A = A * 9)
	ADD     B             ; A = A + B (A = A * 10)
	RET

	; --------- print 8-bit binary in A register ---------

PBINA:  PUSH B
	MVI B, 8          ; SET BIT COUNTER TO 8
PBINLP: RLC               ; ROTATE LEFT THROUGH CARRY
	PUSH PSW
	ANI 01H           ; MASK ALL BUT THE LEAST SIGNIFICANT BIT
	ADI 30H           ; CONVERT TO ASCII
	MOV C, A
	CALL COUT         ; PRINT THE BIT
	POP PSW
	DCR B             ; DECREMENT BIT COUNTER
	JNZ PBINLP        ; REPEAT UNTIL ALL BITS ARE PRINTED
	POP B
	RET

	END
