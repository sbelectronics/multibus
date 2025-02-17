;	TITLE	'attach multimodules`
;	Scott Baker, www.smbaker.com
;
; 	Utils for attaching multimodules
;
; ISIS system calls
;
	PUBLIC	ATTACH

	CSEG

ISIS	EQU	040H

ATTACH:
	MVI	C, 15
	LXI	D, ABLK
	CALL	ISIS
	RET
ABLK:
ATTROW:	DW	1
	DW	ASTAT
ASTAT:	DS	2

	END
