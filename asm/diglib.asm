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
	PUBLIC	DIGNUM

	PUBLIC	MAM
	PUBLIC	MPM
	PUBLIC	MTIME

PZERO	EQU	01FH
PONE	EQU	001H
PTEN	EQU	00AH
PTWENTY	EQU	014H
PTHIRTY	EQU	015H
PFORTY	EQU	016H
PFIFTY	EQU	017H
PSIXTY	EQU	018H
PA	EQU	020H
PM	EQU	020H+12
PP	EQU	020H+15

	CSEG

$INCLUDE(PORTS.INC)

DIGSTP:	MVI	A, 67	; 20 MS PAUSE
	OUT	DIGOUT
	MVI	A,0
	OUT	DIGMUT	; unmute
	RET

DIGWRD:	PUSH	PSW
DWLP:	IN	DIGST
	ANI	01H
	JZ	DWLP
	POP	PSW
	OUT	DIGOUT
	RET

DIGSTR:	PUSH	PSW
DIGSTL:	LDAX	D
	ORA	A
	JZ	DIGSTO
	CALL	DIGWRD
	INX	D
	JMP	DIGSTL
DIGSTO: POP	PSW
	RET

DIGTST:	LXI	D, MTIME
	CALL	DIGSTR
	MVI	A,1
	CALL	DIGNUM
	MVI	A,23
	CALL	DIGNUM
	LXI	D, MAM
	CALL	DIGSTR
	RET

DIGNUM: PUSH	PSW
	ORA	A
	JZ	SAYZ
	CPI	60
	JNC	S60
	CPI 	50
	JNC 	S50
	CPI 	40
	JNC	S40
	CPI	30
	JNC	S30
	CPI	20
	JNC	S20
	JMP	SAYLT
S60:	SUI	60
	PUSH	PSW
	MVI	A, PSIXTY
	JMP	SAYGT
S50:	SUI	50
	PUSH	PSW		; save A-50
	MVI	A, PFIFTY
	JMP	SAYGT
S40:	SUI	40
	PUSH	PSW		; save A-40
	MVI	A, PFORTY
	JMP	SAYGT
S30:	SUI	30		; save A-30
	PUSH	PSW
	MVI	A, PTHIRTY
	JMP	SAYGT
S20:	SUI	20		; save A-20
	PUSH	PSW
	MVI	A, PTWENTY
	JMP	SAYGT
	JMP	SAYLT
SAYGT:	CALL	DIGWRD		; say for >= 20
	POP	PSW
SAYLT:	ORA	A		; say for < 20
	JZ	SAYNOT		; We already handled explicit zero, so say nothing
	CALL	DIGWRD
SAYNOT:	POP	PSW		; restore callee's A
	RET
SAYZ:	MVI	A, PZERO
	CALL	DIGWRD
	POP	PSW		; restore callee's A
	RET

MAM:	DB	PA
	DB	PM
	DB	0

MPM:	DB	PP
	DB	PM
	DB	0

MTIME:	DB	138	; THE
	DB	139	; TIME
	DB	96	; IS
	DB	0

	END
