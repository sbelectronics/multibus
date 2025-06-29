;; sp80.asm
;; Scott Baker, https://www.smbaker.com/
;;
;; Say "This is an Intel Prompt Eighty Computer" on SP0256A-AL2 multimodule
;;

        ORG     0B00H

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

PHONES:	DB	012H,00cH,037H,003H,00cH,02bH,003H,01aH,00bH,003H,00cH,00bH,011H,007H
        DB      02dH,003H,009H,00eH,018H,010H,009H,011H,003H,014H,011H,013H,003H,02aH
        DB      018H,010H,009H,031H,01fH,011H,033H,003H
        DB      0FFH
