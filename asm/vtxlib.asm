$macrofile

;	TITLE	'rtclib`
;	Scott Baker, www.smbaker.com
;
; 	Library for using MSM5832 RTC IC connected via 8255
;
;	Expects externally defined HOUR, MIN, SEC. Each one byte to
;	hold time from RTCTIM.


	PUBLIC	VTXNIT
	PUBLIC	VTXSAY

	CSEG

$INCLUDE(PORTS.INC)

	; VTXNIT - initialize the Votrax

VTXNIT:	MVI	A,00H		; Unmute by default
	OUT	VTXMUT
	RET

	; VTXSAY - Say phonemes
	;  BC = length
	;  DE = address

VTXSAY:	MOV	A,B		; if BC=0 then we're done
	ORA	C
	RZ

VTXLP:	IN	VTXRDY		; Spin until SC-01A is ready
	ANI	01H
	JZ	VTXLP

	LDAX	D		; Get the phoneme...
	OUT	VTXPHN		; ... and output it
	INX	D		; Point to next phoneme
	DCX	B		; Decrement the count
	JMP	VTXSAY

	END
