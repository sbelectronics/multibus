;	TITLE	'serial test`
;	Scott Baker, www.smbaker.com
;
;	Test for sbx-351 serial board
;
;
; ISIS system calls
;
	EXTRN CSTAT
	EXTRN COUT
	EXTRN CIN
	EXTRN ZSOUT
	EXTRN COPEN
	EXTRN EXIT

	EXTRN CSTS
	EXTRN CI
	EXTRN CO

	EXTRN DOFLAG
	EXTRN FLAGL
	EXTRN FLAGR

	EXTRN PSPACE
	EXTRN PHEXA
	EXTRN PCRLF

$INCLUDE(PORTS.INC)

CTR0    EQU	SERBAS+08H	;COUNTER #0
CTR1	EQU	SERBAS+09H	;COUNTER #1 
CTR2	EQU	SERBAS+0AH	;COUNTER #2
TMCP 	EQU 	SERBAS+0BH	;COMMAND FOR INTERVAL TIMER 

B9600	EQU	08 		;COUNT FOR 9600 BAUD TIMER (9600 x 16 = 153,600)
C2M3	EQU	0B6H 		;counter 2 mode three (square wave)

;       8251 UART PORTS
CNCTL	EQU	SERBAS+01H	;CONSOLE USART CONTROL PORT 
CONST	EQU	SERBAS+01H	;CONSOLE STATUS INPUT PORT
CNIN	EQU	SERBAS 		;CONSOLE INPUT PORT 
CNOUT	EQU	SERBAS 		;CONSOLE OUTPUT PORT 

TRDY    EQU     001H        	;Transmit ready
RRDY	EQU 	002H		;RECEIVER BUFFER STATUS READY
MODE	EQU 	04EH		;MODE SET FOR USART 1 stop no parity 8 bit 16x clock

CMD	EQU	036H 		;INITIALIZATION
RESURT 	EQU 	037H		;RESET ERROR AND SET DTR. 
RSTUST 	EQU 	040H		;USART MODE RESET COMMAND

CR      EQU      0DH            ;CARRIAGE RETURN
LF      EQU      0AH            ;LINE FEED

	STKLN	100H				; Size of stack segment

	CSEG	

ORIG:	LXI	SP, STACK
	CALL	COPEN
	CALL	DOFLAG

;set up timer for baud rate clock generator
	MVI 	A,C2M3			;INITIALIZE COUNTER #2 FOR BAUD RATE 
	OUT 	TMCP			;OUTPUT COMMAND WORD TO INTERVAL TIMER 
	LXI 	H,B9600			;LOAD BAUD RATE FACTOR 
	MOV 	A,L			;LEAST SIGNIFICANT WORD FOR CTR2 
	OUT 	CTR2			;OUTPUT WORD TO CTR 2 
	MOV 	A,H			;MOST SIGNIFICANT WORD FOR CTR2 
	OUT 	CTR2			;OUTPUT WORD TO CTR2
	;JMP	SKPSET
;set up UART
	MVI	A,00			;USART SET UP MODE 
	OUT	CNCTL			;OUTPUT MODE 
	OUT	CNCTL			;OUTPUT MODE 
	OUT	CNCTL			;OUTPUT MODE 
	MVI	A,040H  		;USART RESET
	OUT	CNCTL			;OUTPUT MODE 
			
	MVI	A,04EH			;USART SET UP MODE. 
	OUT	CNCTL			;OUTPUT MODE 
	MVI 	A,037H			;
	OUT 	CNCTL			;OUTPUT COMMAND WORD TO USART
SKPSET:

	LDA	FLAGR
	CPI	0FFH
	JNZ     RTST

	LDA	FLAGL
	CPI	0FFH
	JNZ	LPTST

	JMP	TERM

	; bidirectional terminal

TERM:   LXI	D,TBANR
	CALL	ZSOUT
TLP:	IN 	CONST
	ANI	RRDY
	JZ	NOSER
	CALL	SERCIN
	CPI	3		; CTRL-C
	JZ	DONE
	CPI	26		; CTRL-Z
	JZ	DONE
	MOV	C,A		; Move to C so we can call CO
	CPI	0DH		; CR ?
	JNZ	NOSCR
	MOV	C,A
	CALL	CO		; output the CR
	MVI	C,0AH		; load A with LF
NOSCR:	CALL	CO
NOSER:	CALL	CSTS
	ORA	A
	JZ	NOKEY
	CALL	CI
	CPI	3		; CTRL-C ?
	JZ	DONE
	CPI	26		; CTRL-Z ?
	JZ	DONE
	CPI	0DH		; CR ?
	JNZ	NOKCR
	CALL	SERCHR		; output the CR
	MVI	A,0AH		; load A with LF
NOKCR:	CALL	SERCHR
NOKEY:	JMP	TLP

	; read port and print to console

RTST:	LXI	D,RBANR
	CALL	ZSOUT
RLP:
	CALL	SERCIN
	MOV	C,A
	CALL	COUT
	JMP	RLP

	; read port and print back to port

LPTST:	LXI	D, LPBANR
	CALL	ZSOUT
	LXI	H, LPBANR
	CALL	SERSTR
LPLP:
	CALL	SERCIN
	CPI	3		; CTRL-C
	JZ	DONE
	CPI	26		; CTRL-Z
	JZ	DONE
	CALL	SERCHR
	JMP	LPLP

	; quit
DONE:
	CALL 	EXIT

LPBANR: DB	CR, LF
	DB	'Serial Loopback Test', CR, LF
	DB	'Press CTRL-C or CTRL-Z on Serial Port to quit', CR, LF, 0

RBANR:	DB	CR, LF
	DB	'Serial Read Test (forever)', CR, LF, 0

TBANR:	DB	CR, LF
	DB	'Serial Terminal', CR, LF
	DB	'Press CTRL-C or CTRL-Z to quit', CR, LF, 0

; SERCHR: print character in A to serial port

SERCHR:	PUSH    B		;save BC
        PUSH    PSW
	MOV     C,A
SEROUT:	IN 	CONST	        ;GET STATUS OF CONSOLE 
        ANI 	TRDY	        ;SEE IF TRANSMITTER READY 
	JZ  	SEROUT	        ;NO - WAIT till ready
	MOV 	A,C		;move CHARACTER TO A REG 
	OUT 	CNOUT	        ;SEND Character TO CONSOLE 
	POP     PSW
	POP     B               ;restore BC
	RET

SERCIN: PUSH   H				;SAVE REGISTERS
        PUSH   D
        PUSH   B 
CINLP:	IN 	CONST		;GET STATUS OF CONSOLE 
	ANI 	RRDY		;CHECK FOR RECEIVER BUFFER READY 
	JZ 	CINLP		;WAIT till recieved 
	IN      CNIN		;GET CHARACTER 
        POP    B                ;RESTORE REGISTERS
        POP    D
        POP    H
        RET                      ;RETURN

; SERSTR: print string in HL to serial port

SERSTR: PUSH    PSW             ;SAVE PSW
        PUSH    H               ;SAVE HL
MNXT:   MOV     A,M             ;GET A CHARACTER
        CPI     0FFH            ;CHECK FOR 377Q/0FFH/-1 EOM
        JZ      MDONE           ;DONE IF OFFH EOM FOUND
        ORA     A               ;TO CHECK FOR ZERO TERMINATOR
        JZ      MDONE           ;DONE IF ZERO EOM FOUND
        RAL                     ;ROTATE BIT 8 INTO CARRY
        JC      MLAST           ;DONE IF BIT 8 = 1 EOM FOUND
        RAR                     ;RESTORE CHAR
        CALL    SERCHR          ;TYPE THE CHARACTER
        INX     H               ;BUMP MEM VECTOR
        JMP     MNXT            ;AND CONTINUE
;
MLAST:  RAR                     ;RESTORE CHARACTER
        ANI     7FH             ;STRIP OFF BIT 8
        CALL    SERCHR          ;TYPE THE CHARACTER & EXIT
;
MDONE:  POP     H               ;RESTORE HL
        POP     PSW             ;AND PSW
        RET                     ;EXIT TO CALLER

	END	ORIG
