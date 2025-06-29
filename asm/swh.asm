;; swh.asm
;; Scott Baker, https://www.smbaker.com/
;;
;; Say "Scott Was Here" on SP0256A-AL2 multimodule
;;

        ORG     0B80H

SPORT   EQU     0F2H
MPORT   EQU     0F4H

        MVI     A,01H           ; un-mute
        OUT     MPORT

        LXI     D, PHONES       ; get address of phonemes
PLOOP:  
WLOOP:  IN      SPORT           ; wait until ready for phoneme
        ANI     01H
        JZ      WLOOP

        LDAX    D
        CPI     0FFH            ; FF is end of speech marker
        JZ      0CCH            ; return to monitor

        OUT     SPORT           ; send phoneme to port

        INX     D
        JMP     PLOOP

PHONES:	DB	037H,02aH,018H,011H,011H,003H,02eH,018H,02bH,003H,01bH,013H,00eH,003H
        DB      0FFH
