$macrofile

;	TITLE	'rtclib`
;	Scott Baker, www.smbaker.com
;
; 	Library for using MSM5832 RTC IC connected via 8255
;
;	Expects externally defined HOUR, MIN, SEC. Each one byte to
;	hold time from RTCTIM.


	PUBLIC	RTCSTP
	PUBLIC	RTCTIM
	PUBLIC	SETHO
	PUBLIC	SETMI
	PUBLIC	SETSE

	EXTRN	HOUR
	EXTRN	MIN
	EXTRN	SEC

	EXTRN	MUL10
	EXTRN	DIV10

	CSEG

$INCLUDE(PORTS.INC)

RTCS1	EQU	0
RTCS10	EQU	1
RTCM1	EQU	2
RTCM10	EQU	3
RTCH1	EQU	4
RTCH10	EQU	5
RTCW	EQU	6
DTCD1	EQU	7
RTCD10	EQU	8
RTCO1	EQU	9
RTCO10	EQU	10
RTCY1	EQU	11
RTCY10	EQU	12

HOLD	EQU	00010000B
RD	EQU	00110000B
WR	EQU	01010000B
NOHOLD	EQU	00000000B

MODEIN	EQU	10010001B ; MODEA=0, PORTA=IN, PORTCU=OUT, MODEB=0, PORTB=OUT, PORTCU=OUT
MODEOUT EQU	10000001B ; MODEA=0, PORTA=OUT, PORTCU=OUT, MODEB=0, PORTB=OUT, PORTCU=OUT

RTCSTP:	MVI	A, MODEIN
	OUT	RTC82C

	MVI	A, NOHOLD
	OUT	RTCCTL
	RET

RTCTIM: CALL	RTCHLD

	MVI	B, RTCH10
	CALL	RTCGET
	ANI	03H		; Mask off the 24H and AM/PM bits
	CALL	MUL10
	MOV     C, A
	MVI	B, RTCH1
	CALL	RTCGET
	ADD	C
	STA	HOUR

	MVI	B, RTCM10
	CALL	RTCGET
	CALL	MUL10
	MOV     C, A
	MVI	B, RTCM1
	CALL	RTCGET
	ADD	C
	STA	MIN

	MVI	B, RTCS10
	CALL	RTCGET
	CALL	MUL10
	MOV     C, A
	MVI	B, RTCS1
	CALL	RTCGET
	ADD	C
	STA	SEC

	CALL	RTCREL
	RET

	; SETHO - set hours to A

SETHO:	CALL	RTCHLD
	CALL	DIV10
	MOV	D,B
	MVI	B, RTCH10
	CALL	RTCPUT
	MOV	A,D
	MVI	B, RTCH1
	CALL	RTCPUT
	CALL	RTCREL
	RET

	; SETMI - set minutes to A

SETMI:	CALL	RTCHLD
	CALL	DIV10
	MOV	D,B
	MVI	B, RTCM10
	CALL	RTCPUT
	MOV	A,D
	MVI	B, RTCM1
	CALL	RTCPUT
	CALL	RTCREL
	RET

	; SETSE - set seconds to A
	;
	; Note: per datasheet, seconds are always reset to 0 regardless of data

SETSE:	CALL	RTCHLD
	CALL	DIV10
	MOV	D,B
	MVI	B, RTCS10
	CALL	RTCPUT
	MOV	A,D
	MVI	B, RTCS1
	CALL	RTCPUT
	CALL	RTCREL
	RET

RTCHLD: PUSH	PSW
	MVI	A, HOLD
	OUT	RTCCTL
	POP	PSW
	RET

RTCREL: PUSH	PSW
	MVI	A, NOHOLD
	OUT	RTCCTL
	POP	PSW
	RET

	; RTCGET - read from RTC
	;   B - register number
	; returns
	;   A - value
	; assume RTC is held

RTCGET:	MOV	A, B
	OUT	RTCADR
	MVI	A, RD
	OUT	RTCCTL
	IN	RTCDAT
	ANI	0FH
	PUSH 	PSW
	MVI	A, HOLD		; Keep holding
	OUT	RTCCTL
	POP	PSW
	RET

	; RTCPUT - write to RTC
	;   B - register number
	;   A - value
	; destroys
	;   A
	; assume RTC is held

RTCPUT:	PUSH	PSW
	MVI	A, MODEOUT
	OUT	RTC82C
	MOV	A, B
	OUT	RTCADR
	POP	PSW
	OUT	RTCDAT
	MVI	A, WR
	OUT	RTCCTL
	MVI	A, HOLD
	OUT	RTCCTL
	MVI	A, MODEIN
	OUT	RTC82C
	RET

	END
