$macrofile

;	TITLE	'rtclib`
;	Scott Baker, www.smbaker.com
;
; 	Library for using MSM5832 RTC IC connected via 8255
;
;	Expects externally defined HOUR, MIN, SEC. Each one byte to
;	hold time from RTCTIM.

	PUBLIC	DIGSTP
	PUBLIC	DIGWRD
	PUBLIC	DIGSTR
	PUBLIC	DIGTST

	CSEG

$INCLUDE(PORTS.INC)

DIGSTP:	MVI	A, 67	; 20 MS PAUSE
	OUT	DIGOUT
	RET

DIGWRD:	PUSH	PSW
DWLP:	IN	DIGST
	ANI	01H
	JZ	DWLP
	POP	PSW
	OUT	DIGOUT
	RET

DIGSTR:	LDAX	D
	ORA	A
	RZ
	CALL	DIGWRD
	INX	D
	JMP	DIGSTR

DIGTST:	LXI	D, MTEST
	JMP	DIGSTR

MTEST:	DB	138	; THE
	DB	139	; TIME
	DB	96	; IS
	DB	1	; ONE
	DB	32	; A
	DB	44	; M
	DB	0

	END
