$macrofile

;	TITLE	'tmslib`
;	Scott Baker, www.smbaker.com
;
; 	Library for using TMS5220 speech synthesizer


	PUBLIC  TMSSTP
	PUBLIC	TMSSTR
	PUBLIC	TMSADR
	PUBLIC	TMSDLY
	PUBLIC	TMSEXT
	PUBLIC	TMSMTE

	EXTRN	PHEXA

	CSEG

$INCLUDE(PORTS.INC)

	; ROMADDR is the CS of the ROM. For the 620024 6100, this is
	; 0b1111 == 0x0F

ROMADDR	EQU	00FH

	; TMSSTP - setup the TMS5220
	;
	; Turns off Mute, then calls reset.

TMSSTP:	MVI	A,00H		; Unmute by default
	OUT	TMSMUT
	JMP	TMSRST
	RET

	; TMSMTE - turns on mute

TMSMTE:	MVI	A,01H
	OUT	TMSMUT
	RET

	; TMSDLY - sometimes a little delay can be helpful

TMSDLY: PUSH	B
	MVI	B,32
TMSDL:	NOP
	NOP
	DCR	B
	JNZ	TMSDL
	POP	B
	RET

	; TMSRST - reset sequence
	;
	; Writes 11111111 nine times, then executes a reset.

TMSRST: MVI	B,9
TMSRL:	MVI	A,0FFH
	OUT	TMSOUT
	CALL	TMSDLY
	DCR	B
	JNZ	TMSRL
	CALL	TMSDLY
	MVI	A,070H
	OUT	TMSOUT
	CALL	TMSDLY
	RET

	; TSMWRD - say word in ROM
	;  BC = addr
	;  Destroys A

TMSWRD:	CALL	TMSWAT
	CALL	TMSADR
	MVI	A,050H
	OUT	TMSOUT	; Speak
	RET

	; TMSSTR - say the string pointed to by DE.
	;
	; The string is a list of words. Each word is 16-bits.
	; Terminate the list with an FFFF.

TMSSTR: PUSH	PSW
	PUSH	B
TMSSLP:	LDAX	D		; load low bytes
	CALL	TMSDLY
	MOV	C,A		; save in C
	INX	D
	LDAX	D		; load high byte
	CPI	0FFH		; is it FF
	JZ	TMSSTO		; ... yes, exit
	MOV	B,A		; save in B
	INX	D
	CALL	TMSWRD		; say it
	JMP	TMSSLP
TMSSTO:	POP	B
	POP	PSW
	RET

	; TMSWAT - wait for TMS to be idle
	;   destroys A

TMSWAT: IN	TMSIN
	ANI	080H
	JNZ	TMSWAT
	RET

	; TSMADR - set address to rom
	;  BC = addr
	;  Destroys A

TMSADR: MOV	A,C
	ANI	00FH
	ORI	040H
	OUT	TMSOUT	; A0...A3
	MOV	A,C
	RRC
	RRC
	RRC
	RRC
	ANI	00FH
	ORI	040H
	OUT	TMSOUT ; A4...A7
	MOV	A,B
	ANI	00FH
	ORI	040H
	OUT	TMSOUT ; A11..A8
	MOV	A,B
	RRC
	RRC
	RRC
	RRC
	ANI	00FH
	ORI	040H
	ORI	((ROMADDR shl 2) and 0CH)
	OUT	TMSOUT	; A12, A13, CS0, CS1
	MVI	A,040H
	ORI	((ROMADDR shr 2) and 03H)
	OUT	TMSOUT  ; CS2, CS3, x, x
	RET

	; TMSEXT - speak external
	;
	; DE contains speech data. First word is the length.
	;
	; Following guidelines on the Internet, we send 16 bytes to start. Then
	; everytime the buffer becomes less than half full, we send the next 8
	; bytes. There might be a remainder if the number of bytes is not divisible
	; by 8, so we send that too.
	;
	; Note: Assumes length is less than 256 bytes. Fix this as soon as we encounter
	; a bigger sample...

TMSEXT:	CALL	TMSWAT		; wait for not speaking

	MVI	A,060H
	OUT	0B0H

	LDAX	D		; get length into C
	SUI	010H		; We always send at least 16 bytes so subtract 16
	MOV	C,A
	INX	D
	INX	D

	MVI	B,16		; send the first 16
TMSXL1:	LDAX	D
	OUT	0B0H
	INX	D
	DCR	B
	JNZ	TMSXL1

TMSXL2:	IN	0B0H		; wait for buffer less than half full
	ANI	040H
	JZ	TMSXL2

	MOV	A,C
	ORA	A		; no bytes remaining?
	RZ
	CPI	08H		; less than 8 bytes remaining?
	JC	TMSXL4		; yup...
	SBI	08H		; nope... so subtract 8 and send the next 8
	MOV	C,A

	MVI	B,8		; send 8 bytes
TMSXL3:	LDAX	D
	OUT	0B0H
	INX	D
	DCR	B
	JNZ	TMSXL3

	JMP	TMSXL2		; go to next 8-group

TMSXL4: MOV	B,C		; less than 8 bytes left in C
TMSXL5:	LDAX	D
	OUT	0B0H
	INX	D
	DCR	B
	JNZ	TMSXL5

	RET			; we are done -- return

	END
