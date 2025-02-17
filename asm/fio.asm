;	TITLE	'ISIS FILE IO'
;	Scott Baker, www.smbaker.com
;
; ISIS system calls
;
	EXTRN CSTS
	EXTRN LO
	EXTRN EXIT
	EXTRN ISIS

; XXX leftover code from conio


	CSEG
FOPEN:	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	MVI	C,0
	LXI	D,OBLKCI
	CALL	ISIS
	MVI	C,0
	LXI	D,OBLKCO
	CALL	ISIS
	POP	H
	POP	D
	POP	B
	POP	PSW
	RET
OBLKCI:
	DW	RAFT
	DW	CIFILE
	DW	1	; 1 = input
	DW	0	; 0 = no echo
	DW	RSTAT
CIFILE: DB	':CI:',0
OBLKCO:
	DW	WAFT
	DW	COFILE
	DW	2	; 2 = output
	DW	0	; 0 = no echo
	DW	WSTAT
COFILE: DB	':CO:',0


FCLOSE: MVI	C,1
	LXI	D,WBLK
	CALL	ISIS
	MVI	C,1
	LXI	D,RBLK
	CALL	ISIS
	RET

	END
