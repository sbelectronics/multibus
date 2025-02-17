; Ports for SBC-80/24 with scott's ramboard

; 80/24 does not use ATTACH syscall when attaching multimodules

DOATTCH EQU     0

; CSG Multimodule

CSGPORT	EQU	0B3H
CSMPORT	EQU	0B4H    ; Mute for CSG board

; PSG Multimodule

PSGREG	EQU	0B5H
PSGVAL	EQU	0B6H
PSMPORT	EQU	0B7H    ; Mute for PSG board

; TIL311 multimodule

TILL    EQU     0B0H
TILM    EQU     0B1H
TILR    EQU     0B2H
TILB    EQU     0B3H    ; blanking port
TILI    EQU     0B0H    ; input port

; RTC multimodule

RTCDAT  EQU     0A0H
RTCADR  EQU     0A1H
RTCCTL  EQU     0A2H
RTC82C  EQU     0A3H

; Serial multimodule

SERBAS  EQU     0B0H

; Digitalker multimodule

DIGOUT  EQU     0B0H
DIGST   EQU     0B0H

; Votrax multimovule

VTXPHN  EQU     0B0H
VTXRDY  EQU     0B0H
VTXMUT  EQU     0B1H
