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
	EXTRN FLAGG
	EXTRN FLAGQ

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

	STKLN	100H				; Size of stack segment

	CSEG

$INCLUDE(PORTS.INC)

NIXBAS	EQU	090H
NIXH10	EQU	NIXBAS
NIXH1	EQU	NIXBAS+1
NIXM10	EQU	NIXBAS+3
NIXM1	EQU	NIXBAS+4
NIXS10	EQU	NIXBAS+6
NIXS1	EQU	NIXBAS+7

DTZ	EQU	-8		; Default timezone is UTC-8

ORIG:	LXI	SP, STACK
	CALL	COPEN
	CALL	DOFLAG

	CALL	SETUP		; Setup the GPS or RTC

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

CQUIT:	CALL	CSTS		; key pending?
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
	RET

LEAVE:	CALL	PCRLF
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
	RET
NOTGPS:	CALL	RTCSTP
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

GPSST:  DB	0		; state
HOUR:	DB	0
MIN:	DB	0
SEC:	DB	0
LSTSEC:	DB	0
TZONE:	DB	0

	END	ORIG
