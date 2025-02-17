$macrofile

;	TITLE	'gpslib`
;	Scott Baker, www.smbaker.com
;
; 	Library for using GPS connected via 8255.
;
;	Expects externally defined HOUR, MIN, SEC. One byte each.
;	Extects externally defined GPSST to hold state. One byte.


	PUBLIC	GPSSTP
	PUBLIC  GPSIDL

	EXTRN HOUR
	EXTRN MIN
	EXTRN SEC
	EXTRN GPSST	

	EXTRN	MUL10
	EXTRN	DIV10

	CSEG

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

	; GPSSTP - GPS SETUP

GPSSTP: MVI 	A,C2M3			;INITIALIZE COUNTER #2 FOR BAUD RATE 
	OUT 	TMCP			;OUTPUT COMMAND WORD TO INTERVAL TIMER 
	LXI 	H,B9600			;LOAD BAUD RATE FACTOR 
	MOV 	A,L			;LEAST SIGNIFICANT WORD FOR CTR2 
	OUT 	CTR2			;OUTPUT WORD TO CTR 2 
	MOV 	A,H			;MOST SIGNIFICANT WORD FOR CTR2 
	OUT 	CTR2			;OUTPUT WORD TO CTR2
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
	RET

	; GPSIDL - GPS IDLE LOOP

GPSIDL:	IN 	CONST	        ;GET STATUS OF CONSOLE 
	ANI 	RRDY	        ;SEE IF TRANSMITTER READY 
	RZ			;NO - RETURN
				; otherwise, fall through

GOTCHR: IN	CNIN
	MOV	C,A		; input character to C	
				; fall through

	; GPS state machine -- assumes input character in C

GPSSM:  LDA	GPSST	; load GPS parse state into A

        CPI	1
	JNZ	NOT1

        MOV	A,C
        CPI	'$'
        JNZ	BAD
        MVI	A, 2          ; set state 2
        STA	GPSST
        JMP	GOOD

NOT1:   CPI	2
        JNZ	NOT2

        MOV	A,C
        CPI	'G'
        JNZ	BAD
        MVI	A, 3          ; set state 3
        STA	GPSST
        JMP	GOOD

NOT2:   CPI	3
        JNZ  NOT3

        MOV	A,C
        CPI	'P'
        JNZ 	BAD
        MVI	A, 4          ; set state 4
        STA	GPSST
        JMP	GOOD

NOT3:   CPI	4
        JNZ	NOT4

        MOV	A,C
        CPI	'G'
        JNZ	BAD
        MVI 	A, 5          ; set state 5
        STA	GPSST
        JMP	GOOD

NOT4:   CPI	5
        JNZ	NOT5

        MOV	A,C
        CPI	'G'
        JNZ	BAD
        MVI	A, 6          ; set state 6
        STA	GPSST
        JMP	GOOD

NOT5:   CPI	6
        JNZ	NOT6

        MOV	A,C
        CPI	'A'
        JNZ	BAD
        MVI	A, 7          ; set state 7
        STA	GPSST
        JMP	GOOD

NOT6:   CPI	7
        JNZ	NOT7

        MOV	A,C
        CPI	','
        JNZ	BAD
        MVI	A, 8          ; set state 8
        STA	GPSST
        JMP	GOOD

        ; hours

NOT7:   CPI	8
        JNZ 	NOT8

        MOV	A,C
        SUI	48
        CALL    MUL10
	STA	HOUR

        MVI	A, 9          ; set state 9
        STA	GPSST
        JMP	GOOD

NOT8:   CPI	9
        JNZ 	NOT9

        MOV	A,C
        SUI	48
	MOV	C,A
	LDA	HOUR
        ADD     C
	STA	HOUR

        MVI	A, 10          ; set state 10
        STA	GPSST
        JMP	GOOD

        ; minutes

NOT9:   CPI	10
        JNZ	NOT10

        MOV	A,C
        SUI	48
        CALL	MUL10
	STA	MIN

        MVI	A, 11          ; set state 11
        STA	GPSST
        JMP	GOOD

NOT10:  CPI	11
        JNZ	NOT11

        MOV	A,C
        SUI	48
        MOV	C, A
	LDA	MIN
        ADD     C
	STA	MIN

        MVI	A, 12          ; set state 12
        STA	GPSST
        JMP	GOOD

        ; seconds

NOT11:  CPI	12
        JNZ	NOT12

        MOV	A,C
        SUI	48
        CALL    MUL10
	STA	SEC

        MVI	A, 13          ; set state 13
        STA	GPSST
        JMP	GOOD

NOT12:  CPI	13
        JNZ	NOT13

        MOV	A,C
        SUI	48
	MOV	C,A
	LDA	SEC
        ADD     C
	STA	SEC

        MVI	A, 14          ; set state 14
        STA	GPSST
        JMP	GOOD

NOT13:
BAD:    MVI	A, 1
        STA	GPSST
GOOD:
        RET

	END
