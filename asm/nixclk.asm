$macrofile

;	TITLE	'nixclk`
;	Scott Baker, www.smbaker.com
;
;	Nixie Tube Clock
;
;	Flags
;	  G - use GPS instead of RTC
;	  Q - quit

; ISIS system calls
;
	EXTRN COUT
	EXTRN CIN
	EXTRN ZSOUT
	EXTRN COPEN
	EXTRN EXIT
	EXTRN CSTS
	EXTRN CI

	EXTRN DOFLAG
	EXTRN FLAGD
	EXTRN FLAGG
	EXTRN FLAGQ
	EXTRN FLAGT

	EXTRN PHEXA
	EXTRN PCRLF
	EXTRN PRNDEC
	EXTRN DIV10

	PUBLIC	HOUR
	PUBLIC	MIN
	PUBLIC	SEC
	PUBLIC	GPSST

	EXTRN GPSSTP
	EXTRN GPSIDL

	EXTRN RTCSTP
	EXTRN RTCTIM

	EXTRN DIGSTP
	EXTRN DIGNUM
	EXTRN DIGNLZ
	EXTRN DIGSTR
	EXTRN MAM
	EXTRN MPM
	EXTRN MTIME

	EXTRN TMSSTP
	EXTRN V7NUM
	EXTRN V7NLZ
	EXTRN V7TTIS
	EXTRN V7AM
	EXTRN V7PM

	STKLN	100H				; Size of stack segment

	CSEG

$INCLUDE(PORTS.INC)

NIXH10	EQU	NIXBAS
NIXH1	EQU	NIXBAS+1
NIXM10	EQU	NIXBAS+3
NIXM1	EQU	NIXBAS+4
NIXS10	EQU	NIXBAS+6
NIXS1	EQU	NIXBAS+7

IVEC	EQU	008H		; vector address for int1

DTZ	EQU	-8		; Default timezone is UTC-8

ORIG:	LXI	SP, STACK
	CALL	COPEN
	CALL	DOFLAG

	CALL	SETUP		; Setup the GPS or RTC
	CALL	INTSTP		; Install interrupt handler

	MVI	A, DTZ		; Set default time zone for GPS
	STA	TZONE

AGAIN:	CALL	GETTIM		; Get Time
	CALL	NIXTIM		; Output to nixie tubes

	LDA	FLAGQ
	CPI	0FFH
	JNZ	QUIET
	MVI	C, 0DH		; Print CR to overwrite line
	CALL	COUT
	CALL	PRNTIM		; Print time to console
QUIET:
	JMP	AGAIN		; Run forever

	; CQUIT - see if it's quittin' time

CQUIT:	LDA	BTNSIG		; button interrupt signaled
	ORA	A
	JNZ	KEYS		; yes - say time

	CALL	CSTS		; key pending?
	ORA	A
	RZ			; No Key
	CALL	CI
	CPI	3		; CTRL-C ?
	JZ	LEAVE
	CPI	26		; CTRL-Z ?
	JZ	LEAVE
	CPI	'Q'		; 'Q'
	JZ	LEAVE
	CPI	'q'		; 'q'
	JZ	LEAVE
	CPI	'S'
	JZ	KEYS
	CPI	's'
	JZ	KEYS
	RET
KEYS:	CALL	SAYTIM
	MVI	A,0
	STA	BTNSIG
	RET

LEAVE:	CALL	PCRLF
	CALL	INTTD		; teardown interrupt handler
	CALL 	EXIT

	; GETTIME - get the current time

GETTIM: LDA	FLAGG
	CPI 	0FFH
	JZ	RTCAGN
GPSAGN:	CALL	CQUIT
	CALL	GPSIDL
	LDA	GPSST
	CPI	14
	JNZ	GPSAGN
	JMP	ADJTIM		; Now adjust for timezone. ADJTIM will return.
RTCAGN:	CALL	CQUIT
	CALL	RTCTIM
	LDA	LSTSEC		; See if the seconds digit has changed
	MOV	B,A
	LDA	SEC
	CMP	B
	JZ	RTCAGN
	STA	LSTSEC
	RET

	; ADJTIM - adjust timezone
ADJTIM:	LDA	HOUR
	ADI	24
	MOV	B,A
	LDA	TZONE
	ADD	B
	CPI	24H		; Are we past 24 ?
	JM	NOTP24
	SBI	24H
NOTP24: STA	HOUR
	RET

SETUP:	LDA	FLAGG
	CPI 	0FFH
	JZ	NOTGPS
	CALL	GPSSTP
	JMP	SETUP0
NOTGPS:	CALL	RTCSTP
SETUP0: LDA	FLAGD		; digitalker flag specified?
	CPI	0FFH
	JZ	NOTDIG
	CALL	DIGSTP		; setup the digitalker
NOTDIG: LDA	FLAGT		; TMS-5220 flag specified?
	CPI	0FFH
	JZ	NOTTMS
	CALL	TMSSTP		; setup the TMS-5220
NOTTMS:
	RET

	; NIXTIM - output current time to nixies

NIXTIM:	LDA	HOUR
	CALL	DIV10
	OUT	NIXH10
	MOV	A,B
	OUT	NIXH1

	LDA	MIN
	CALL	DIV10
	OUT	NIXM10
	MOV	A,B
	OUT	NIXM1

	LDA	SEC
	CALL	DIV10
	OUT	NIXS10
	MOV	A,B
	OUT	NIXS1
	RET

	; PRNTIM - print current time to console

PRNTIM:	LDA	HOUR
	CALL	PRNDEC
	MVI	C, ':'
	CALL	COUT
	LDA	MIN
	CALL	PRNDEC
	MVI	C, ':'
	CALL	COUT
	LDA	SEC
	CALL	PRNDEC
	RET

	; SAYTIM - say time on digitalker or TMS-5220

SAYTIM: LDA	FLAGD
	CPI	0FFH
	JNZ	SAYDIG
	LDA	FLAGT
	CPI	0FFH
	JNZ	SAYTMS
	RET

	; SAYDIG - say time on digitalker

SAYDIG:	LDA	HOUR
	CPI	13
	JC	SAYAM
	SUI	12
	CALL	SAYDG0
	LXI	D, MPM		; say PM
	CALL	DIGSTR
	RET
SAYAM:	CALL	SAYDG0
	LXI	D, MAM		; say AM
	CALL	DIGSTR
	RET

SAYDG0:	LXI	D, MTIME	; say the time
	CALL	DIGSTR
	CALL	DIGNUM
	LDA	MIN
	ORA	A
	RZ			; If zero hours no need to say
	CALL	DIGNLZ
	RET

	; SAYTMS - say time on tms-5220

SAYTMS:	LDA	HOUR
	CPI	13
	JC	SAYAM
	SUI	12
	CALL	SAYTM0
	CALL	V7PM		; say PM
	RET
SAYTAM:	CALL	SAYTM0
	CALL	V7AM		; say AM
	RET

SAYTM0:	PUSH	PSW
	CALL	V7TTIS		; say "The Time Is"
	POP	PSW
	CALL	V7NUM
	LDA	MIN
	ORA	A
	RZ			; If zero hours no need to say
	CALL	V7NLZ
	RET

; INTBTN - interrupt called on button push

INTBTN: PUSH	PSW		; should start with ints disabled
	MVI	A,1
	STA	BTNSIG
	MVI	A,20H
	OUT	INTACK
	POP	PSW
	EI
	RET

; INTSTP - interrupt setup

INTSTP:	LDA	IVEC		; save the in11 vector to IV0...IV2
	STA	IV0
	LDA	IVEC+1
	STA	IV1
	LDA	IVEC+2
	STA	IV2

	LDA	JMPI		; load the JMP INTBTN instruction
	STA	IVEC		; and write it to the int1 vector
	LDA	JMPI+1
	STA	IVEC+1
	LDA	JMPI+2
	STA	IVEC+2

	DI			; disable while touch the intmask
	IN	INTMSK
	ANI	0FDH		; enable int1
	OUT	INTMSK
	EI
	RET
JMPI:	JMP	INTBTN		; instruction we will stick in int2 vector

; INTTD - interrupt teardown

INTTD:	DI			; disable while we touch the intvec
	IN	INTMSK
	ORI	002H		; disable int1
	OUT	INTMSK

	LDA	IV0		; restore IV0..IVT to int1 vector
	STA	IVEC
	LDA	IV1
	STA	IVEC+1
	LDA	IV2
	STA	IVEC+2
	EI
	RET

GPSST:  DB	0		; state
HOUR:	DB	0
MIN:	DB	0
SEC:	DB	0
LSTSEC:	DB	0
LSTMIN: DB	0FFH
TZONE:	DB	0
BTNSIG: DB	0
IV0: 	DB	0		; saved contents of int1 vector
IV1:	DB	0
IV2:	DB	0

	END	ORIG
