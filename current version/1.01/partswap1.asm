;PARTSWAP.ASM
;1581 PARTITION LIST AND SWAP
;AKX 2021
;---------------------------------------
;SET UP BASIC SYS
         *= $0801

         ;END $080C
         ;LINE $000A
         ;SYS (TOKEN $9E)
         ;" 4096"
         ;END LINE (000)
         .BYTE $0C,$08,$0A,$00,$9E,$20
         .BYTE $34,$30,$39,$36,$00,$00
         .BYTE $00

;---------------------------------------
;VARIABLES
         *= $0820
DRIVE    .BYTE $00
TYPE     .BYTE $00
STAT     .BYTE $00
FOUND    .BYTE $00
PRES     .BYTE $00
INDIR    .BYTE $00
SCRPOS   .BYTE $00
NUMPART  .BYTE $00
DIRPOSL  .BYTE $00
DIRPOSH  .BYTE $00
DIRBUFF  .BYTE $00,$00,$00,$00,$00,$00
         .BYTE $00,$00,$00,$00,$00,$00
         .BYTE $00,$00,$00,$00,$00,$00
         .BYTE $00,$00,$00,$00

NAMEBUFF .BYTE $00,$00,$00,$00,$00,$00
         .BYTE $00,$00,$00,$00,$00,$00
         .BYTE $00,$00,$00,$00

XTEN     .BYTE $00,$0A,$14,$1E,$28,$32
         .BYTE $3C,$46,$50,$5A

;---------------------------------------
;DATA

S1       .TEXT "           "
         .TEXT "FINDING 1581 DRIVE"
LS1      = *-S1

S2       .TEXT "           "
         .TEXT "LISTING PARTITIONS"
LS2      = *-S2

S3       .TEXT "           "
         .TEXT "CHANGING PARTITION"
LS3      = *-S3

MSGNP    .TEXT "1581 DRIVE NOT PRESENT"
         .BYTE $0D
LMSGNP   = *-MSGNP

RPMSG    .TEXT "1581 DRIVE FOUND ON"
         .TEXT " DEVICE"
         .BYTE $20
LRPMSG   = *-RPMSG

UDMSG    .TEXT "USE THIS DRIVE? (Y/N)"
         .BYTE $0D
LUDMSG   = *-UDMSG

MRTYPE   .TEXT "M-R"
         .BYTE $C6,$E5,$01
LMRTYPE  = *-MRTYPE

PCMSG    .TEXT "CONTINUE? (Y/N)"
         .BYTE $0D
LPCMSG   = *-PCMSG

ENTMSG   .TEXT "ENTER A PARTITION? "
         .TEXT "(Y/N)"
         .BYTE $0D
LENTMSG  = *-ENTMSG

PNMSG    .TEXT "TYPE QUIT TO EXIT"
         .TEXT "       "
         .BYTE $0D
         .TEXT "NAME OF PARTITION: "
LPNMSG   = *-PNMSG

ROOT     .TEXT "/"
         .BYTE $0D
LROOT    = *-ROOT

QUIT     .TEXT "QUIT"
LQUIT    = *-QUIT

NOPAMSG  .TEXT "NO PARTITIONS-"
         .TEXT "INITIALIZING..."
         .BYTE $0D
LNOPAMSG = *-NOPAMSG

AGMSG    .TEXT "CHANGE AGAIN? (Y/N)"
         .BYTE $0D
LAGMSG   = *-AGMSG

DNAME    .TEXT "$0"
LDNAME   = *-DNAME

INIT     .TEXT "I0"
LINIT    = *-INIT

CD       .TEXT "/0:"
LCD      = *-CD

;---------------------------------------
;BEGIN CODE
         *= $1000
;JUMP TABLE
         LDA #$00
         STA $D020    ;BORDER = BLACK
         STA $D021    ;BCKGND = BLACK
         LDA #$93
         JSR $FFD2    ;CLS
         LDA #$05
         JSR $FFD2    ;WHITE TEXT
         JSR SPROBE   ;PROBE DRIVS 8->30
         LDA FOUND
         BEQ EXIT     ;IF NO 1581
         JSR CLS
CHGDIR   JSR SLIST    ;LIST PARTITIONS
         LDA STAT
         CMP #$4A
         BEQ DINIT    ;DRIVE NOT RDY
         JSR GPART    ;INPUT PARTITION
         LDA STAT
         CMP #$4A
         BEQ EXIT
         JSR CPART    ;CHANGE PARTITION
         LDA STAT
         CMP #$4A
         BEQ EXIT
         JMP AGAIN
EXIT     RTS          ;RETURN TO BASIC

AGAIN    LDY #$00
AGLOOP1  LDA AGMSG,Y
         JSR $FFD2
         INY
         CPY #LAGMSG
         BNE AGLOOP1
AGLOOP2  JSR $FFE4
         CMP #$4E     ;N
         BEQ EXIT
         CMP #$59     ;Y
         BNE AGLOOP2
         JSR CLS
         JMP CHGDIR

DINIT    JSR OCOMM    ;OPEN COMM CHN
         LDX #$0F
         JSR $FFC9    ;CHKOUT
         LDY #$00
DILOOP   LDA INIT,Y
         JSR $FFD2    ;CHROUT
         INY
         CPY #LINIT
         BNE DILOOP
         JSR $FFCC    ;CLRCHN
         JSR CCOMM    ;CLOSE COMM CHN
         JMP EXIT

;---------------------------------------
;PROBE DRIVES 8->30 FOR 1581

SPROBE   LDA #$08     ;DEVICE 8
         STA DRIVE
         JSR PRINTS1  ;STAT BAR
         LDX #$01
         LDY #$00
         JSR $FFF0    ;PLOT - SET CSR
PROBE    JSR CHKPRES  ;IS DRV PRESENT?
         LDA PRES
         BNE PAHEAD   ;IF NOT, SKIP
         JSR OCOMM    ;OPEN COMM CHNL
         JSR GTYPE    ;GET DRIVE TYPE
         JSR CCOMM    ;CLOSE COMM CHNL
         LDA TYPE     ;1=1581,0=OTHER
         BNE RPROBE   ;RETURN
PAHEAD   INC DRIVE
         LDA DRIVE
         CMP #$1F     ;DRIVE <31
         BNE PROBE
         JSR NPRES
         RTS

GTYPE    LDX #$0F
         JSR $FFC9    ;CHKOUT
         LDY #$00
GTLOOP   LDA MRTYPE,Y
         JSR $FFD2    ;CHROUT
         INY
         CPY #LMRTYPE
         BNE GTLOOP
         JSR $FFCC    ;CLRCHN
         LDX #$0F
         JSR $FFC6    ;CHKIN
         JSR $FFCF    ;CHRIN
         TAY
         JSR $FFCC    ;CLRCHN
         TYA
         ADC #$00     ;PROTECT NULL$
         CMP #$FF     ;255=1581
         BEQ DPRES
         LDA #$00     ;0=OTHER DRIVE
         STA TYPE
         RTS
DPRES    LDA #$01     ;1=1581
         STA TYPE
         RTS

NPRES    LDY #$00
NPLOOP   LDA MSGNP,Y
         JSR $FFD2    ;CHROUT
         INY
         CPY #LMSGNP
         BNE NPLOOP
         RTS

RPROBE   LDA #$01     ;DRIVE FOUND
         STA FOUND
         LDY #$00
RPLOOP   LDA RPMSG,Y  ;PRINT MESSAGE
         JSR $FFD2
         INY
         CPY #LRPMSG
         BNE RPLOOP
         TYA
         PHA
         LDA DRIVE
         JSR NUMCHAR  ;PRINT DRIVE #
         PLA
         TAY
         LDA #$0D
         JSR $FFD2    ;PRINT RETURN
         JSR RERR
         JSR UDRIVE
         RTS

UDRIVE   LDY #$00
UDLOOP   LDA UDMSG,Y
         JSR $FFD2
         INY
         CPY #LUDMSG
         BNE UDLOOP
UDKBD    JSR $FFE4    ;SCAN KBD
         CMP #$4E     ;N
         BEQ UDNO
         CMP #$59     ;Y
         BEQ UDYES
         JMP UDKBD
UDNO     LDA #$00
         STA FOUND
         LDA #$0D
         JSR $FFD2
         JMP PAHEAD
UDYES    LDA #$0D
         JSR $FFD2
         RTS

PRINTS1  JSR POSSTAT  ;SETUP STAT BAR
S1LOOP1  LDA S1,Y
         JSR $FFD2
         LDA #$03
         STA $D800,Y  ;CYAN
         INY
         CPY #LS1
         BNE S1LOOP1
         JSR CLRSTAT  ;END STAT BAR
         RTS

;---------------------------------------
;LIST PARTITIONS
SLIST    JSR PRINTS2  ;STAT BAR
         JSR OCOMM    ;OPEN COMM CHN
         LDA #LDNAME
         LDX #<DNAME
         LDY #>DNAME
         JSR $FFBD    ;SETNAM
         LDA #$60     ;96,DRIVE,96
         LDX DRIVE
         LDY #$60
         JSR $FFBA    ;SETLFS
         JSR $FFC0    ;OPEN DATA CHN
         JSR RSTAT
         LDA STAT
         CMP #$4A     ;74 = NOT RDY
         BEQ LEXIT
         LDA STAT
         CMP #$14     ;NO ERRORS < 20
         BCC PLIST
LEXIT    LDA #$60
         JSR $FFC3    ;CLOSE DATA CHN
         JSR CCOMM    ;CLOSE COMM CHN
         RTS

PLIST    CLC
         LDX #$01
         LDY #$00
         JSR $FFF0    ;PLOT - SET CSR
         LDY #$00
         LDA #$20
PSPLOOP  JSR $FFD2    ;? SPC(4)
         INY
         CPY #$04
         BNE PSPLOOP
         LDA #$12     ;REV ON
         JSR $FFD2
         LDA #$22     ;? QUOTES
         JSR $FFD2
         JSR FNDQUOTE ;FIND NEXT QUOTES
         JSR READHEAD ;? DISK HEADER
         LDA #$92     ;REV OFF
         JSR $FFD2
         LDA #$0D
         JSR $FFD2
PENTRY   LDA #$00
         STA DIRPOSL  ;LOW INDEX
         STA DIRPOSH  ;HIGH INDEX
         STA SCRPOS   ;POS ON SCR <14
         STA NUMPART  ;TOTAL PARTITIONS
DIRLOOP  JSR FNDQUOTE
         LDA INDIR    ;1=IN DIR 0=DONE
         BEQ LEXIT
         JSR READDIR  ;READ 1 ENTRY
         INC DIRPOSL  ;NEXT ENTRY
         LDA DIRPOSL
         CMP #$29     ;$29+$FF=296
         BNE DIRLOOP
         INC DIRPOSH  ;NEXT BANK
         LDA DIRPOSH
         CMP #$02     ;+$FF
         BNE DIRLOOP
         JMP LEXIT

FNDQUOTE LDA #$01
         STA INDIR    ;SET INDIR TRUE
         LDX #$60
         JSR $FFC6    ;CHKIN
FNDLOOP  JSR $FFCF    ;CHRIN
         TAY
         JSR $FFB7    ;CHECK STAT
         BNE EXITDIR
         TYA
         CMP #$22     ;QUOTES
         BNE FNDLOOP
         RTS

READHEAD LDY #$16     ;22 CHARS
HEADLOOP JSR $FFCF    ;CHRIN
         JSR $FFD2    ;CHROUT
         DEY
         BPL HEADLOOP
         JMP $FFCC    ;CLRCHN
                      ;USE RTS IN FFCC

EXITDIR  DEC INDIR    ;INDIR FALSE
         JMP $FFCC    ;CLRCHN
                      ;USE RTS IN FFCC

READDIR  LDY #$15
RLOOP1   JSR $FFCF    ;CHRIN
         STA DIRBUFF,Y
         DEY
         BPL RLOOP1
         JSR $FFCC    ;CLRCHN
         LDA DIRBUFF+1
         CMP #$4D     ;"M" FROM CBM
         BNE DIRRET
         INC SCRPOS
         INC NUMPART
         LDA SCRPOS
         CMP #$0E     ;SCRPOS=14?
         BEQ PRMTCONT ;PROMPT FOR CONT
RDCONT   LDY #$05     ;?SPC(5)
         LDA #$20
RLOOP2   JSR $FFD2
         DEY
         BNE RLOOP2
         LDA #$22     ;? QUOTES
         JSR $FFD2
         LDY #$15
RLOOP3   LDA DIRBUFF,Y
         JSR $FFD2    ;CHROUT
         DEY
         BPL RLOOP3
         LDA #$0D     ;RETURN
         JSR $FFD2
DIRRET   RTS

PRMTCONT LDA #$00
         STA SCRPOS
         LDY #$00
PCLOOP   LDA PCMSG,Y
         JSR $FFD2    ;CHROUT
         INY
         CPY #LPCMSG
         BNE PCLOOP
PCKBD    JSR $FFE4    ;SCAN KBD
         CMP #$4E     ;N
         BNE PCFWDY
         LDA #$28     ;SET END OF DIR
         STA DIRPOSL
         LDA #$01
         STA DIRPOSH
         RTS
PCFWDY   CMP #$59     ;Y
         BNE PCKBD
         JSR CLRDIR
         JMP RDCONT

CLRDIR   LDX #$02
         LDY #$00
         CLC
         JSR $FFF0    ;PLOT - SET CSR
         LDX #$00
CLRLOOP1 LDY #$00
         LDA #$20
CLRLOOP2 JSR $FFD2
         INY
         CPY #$1B     ;27 SPACES
         BNE CLRLOOP2
         LDA #$0D     ;RETURN
         JSR $FFD2
         INX
         CPX #$0E     ;14 LINES
         BNE CLRLOOP1
         LDX #$02
         LDY #$00
         CLC
         JSR $FFF0    ;PLOT - SET CSR
         RTS

PRINTS2  JSR POSSTAT  ;SETUP STAT BAR
PS2L1    LDA S2,Y
         JSR $FFD2
         LDA #$03
         STA $D800,Y  ;CYAN
         INY
         CPY #LS2
         BNE PS2L1
         JSR CLRSTAT  ;END STAT BAR
         RTS

;---------------------------------------
;CHOOSE PARTITION

GPART    SEC
         JSR $FFF0    ;PLOT - GET CSR
         TAY
         PHA          ;PUSH HORIZ
         TXA
         PHA          ;PUSH VERT
         JSR PRINTS3  ;STAT BAR
         JSR SETBUFF  ;DEFAULT ROOT
         PLA
         TAX          ;PULL VERT
         PLA
         TAY          ;PULL HORIZ
         CLC
         JSR $FFF0    ;PLOT - SET CSR
         LDY #$00
GPLOOP1  LDA ENTMSG,Y
         JSR $FFD2
         INY
         CPY #LENTMSG
         BNE GPLOOP1
GPLOOP2  JSR $FFE4    ;SCAN KBD
         CMP #$4E     ;N
         BNE GPFWY
         LDA #$4A     ;SET NOT RDY STAT
         STA STAT
         RTS
GPFWY    CMP #$59     ;Y
         BNE GPLOOP2
         LDA #$91     ;CSR UP
         JSR $FFD2
         LDY #$00
GPLOOP3  LDA PNMSG,Y
         JSR $FFD2
         INY
         CPY #LPNMSG
         BNE GPLOOP3
         LDY #$00
GPLOOP4  LDA ROOT,Y
         JSR $FFD2
         INY
         CPY #$01
         BNE GPLOOP4
         LDA #$9D     ;CSR LEFT TO START
GPLOOP5  JSR $FFD2
         DEY
         BNE GPLOOP5
GPLOOP6  JSR $FFCF    ;CHRIN
         CMP #$0D     ;CHK FOR RETURN
         BEQ GPFWD
         STA NAMEBUFF,Y
         INY
         CPY #$10     ;16 CHR MAX
         BNE GPLOOP6
GPFWD    RTS

SETBUFF  LDY #$00     ;SET NAMEBUFF TO
SBLOOP1  LDA ROOT,Y   ;ROOT AS DEFAULT
         STA NAMEBUFF,Y
         INY
         CPY #LROOT
         BNE SBLOOP1
         LDA #$00
SBLOOP2  STA NAMEBUFF,Y
         INY
         CPY #$10
         BNE SBLOOP2
         RTS

PRINTS3  JSR POSSTAT  ;SETUP STAT BAR
PS3L1    LDA S3,Y
         JSR $FFD2
         LDA #$03
         STA $D800,Y  ;CYAN
         INY
         CPY #LS3
         BNE PS3L1
         JSR CLRSTAT  ;END STAT BAR
         RTS

;---------------------------------------
;CHANGE PARTITION

CPART    LDY #$00     ;CHECK FOR QUIT
         LDA #$0D
         JSR $FFD2
CQLOOP   LDA NAMEBUFF,Y
         CMP QUIT,Y
         BNE CPROOT
         INY
         CPY #LQUIT
         BNE CQLOOP
         LDA #$4A
         STA STAT
         RTS

CPROOT   LDY #$00     ;CHECK FOR ROOT
CRLOOP   LDA NAMEBUFF,Y
         CMP ROOT,Y
         BNE CPNAME
         INY
         CPY #LROOT
         BNE CRLOOP
         JMP GOROOT

CPNAME   LDA NUMPART
         BEQ NOPARTS
         JSR OCOMM    ;OPEN COMM CHN
         LDX #$0F
         JSR $FFC9    ;CHKOUT
         LDY #$00
CPNLOOP1 LDA CD,Y
         JSR $FFD2    ;CHROUT
         INY
         CPY #LCD
         BNE CPNLOOP1
         LDY #$00
CPNLOOP2 LDA NAMEBUFF,Y
         BEQ CPNEXIT  ;IF CHR = $00
         JSR $FFD2
         INY
         CPY #$10
         BNE CPNLOOP2
CPNEXIT  JSR $FFCC    ;CLRCHN
         JSR RSTAT    ;READ STAT
         JMP CCOMM    ;CLOSE COMM CHN
                      ;USE RTS IN CCOMM

NOPARTS  LDY #$00
NPALOOP  LDA NOPAMSG,Y
         JSR $FFD2
         INY
         CPY #LNOPAMSG
         BNE NPALOOP
GOROOT   JSR OCOMM    ;OPEN COMM CHN
         LDX #$0F
         JSR $FFC9    ;CHKOUT
         LDA CD       ;/ (ROOT)
         JSR $FFD2    ;CHROUT
         JSR $FFCC    ;CLRCHN
         JSR RSTAT    ;READ STAT
         JMP CCOMM    ;CLOSE COMM CHN
                      ;USE RTS IN CCOMM

;---------------------------------------
;GENERAL FUNCTIONS

CLS      LDA #$20     ;CLEAR ALL EXCEPT
         LDY #$28     ;STAT AND ERR ROW
CLOOP1   STA $0400,Y
         INY
         BNE CLOOP1
CLOOP2   STA $0500,Y
         INY
         BNE CLOOP2
CLOOP3   STA $0600,Y
         INY
         BNE CLOOP3
CLOOP4   STA $0700,Y
         INY
         CPY #$C0
         BNE CLOOP4
         RTS

OCOMM    LDA #$00     ;NO FILENAME
         LDX #$00
         LDY #$00
         JSR $FFBD    ;SETNAM
         LDA #$0F
         LDX DRIVE
         LDY #$0F
         JSR $FFBA    ;SETLFS
         JMP $FFC0    ;OPEN
                      ;USE JSR IN $FFC0

CCOMM    LDA #$0F
         JMP $FFC3    ;CLOSE
                      ;USE JSR IN $FFC3

RSTAT    LDA #$01     ;1=RSTAT
         JMP RSTAT1

RERR     JSR OCOMM
         LDA #$00     ;0=RERR
         PHA          ;PUSH MARKER
RSTAT1   BEQ RESKIP   ;SKIP IF RSTAT
         PHA          ;PUSH MARKER
RESKIP   SEC
         JSR $FFF0    ;PLOT - GET CSR
         TYA
         PHA          ;PUSH HORIZ
         TXA
         PHA          ;PUSH VERT
         CLC
         LDX #$18
         LDY #$00
         JSR $FFF0    ;SET CURSOR
         LDA #$12
         JSR $FFD2    ;RVS ON
         LDA #$9E
         JSR $FFD2    ;YELLOW
         LDX #$0F
         JSR $FFC6    ;CHKIN
         JSR $FFCF    ;CHRIN
         PHA          ;PUSH TENS DIGIT
         JSR $FFD2    ;CHROUT
         JSR $FFCF    ;CHRIN
         JSR $FFD2    ;CHROUT
         PHA          ;PUSH ONES DIGIT
ELOOP    JSR $FFB7    ;READST
         BNE ECLOSE
         JSR $FFCF    ;CHRIN
         CMP #$0D
         BEQ ECLOSE
         JSR $FFD2    ;CHROUT
         JMP ELOOP
ECLOSE   SEC
         JSR $FFF0    ;PLOT - GET CSR
         INY          ;NEXT HORIZ
PELOOP   LDA #$A0     ;INV SPACE
         STA $07BF,Y
         LDA #$07     ;YELLOW
         STA $DBBF,Y
         INY
         CPY #$29     ;LAST SCR POS
         BNE PELOOP
         PLA          ;PULL ONES DIGIT
         SEC
         SBC #$30     ;CHR->NUM
         STA STAT
         PLA          ;PULL TENS DIGIT
         SBC #$30     ;CHR->NUM
         TAY
         LDA XTEN,Y   ;MULTIPLY BY 10
         CLC
         ADC STAT     ;TENSÛONES
         STA STAT
         LDA #$92     ;RVS OFF
         JSR $FFD2
         LDA #$05     ;WHITE TEXT
         JSR $FFD2
         CLC
         PLA          ;PULL VERT
         TAX
         PLA          ;PULL HORIZ
         TAY
         JSR $FFF0    ;PLOT - SET CSR
         JSR $FFCC    ;CLRCHN
         PLA          ;PULL MARKER
         CMP #$00
         BNE RSEXIT   ;SKIP IF RSTAT
         JSR CCOMM    ;CLOSE COMM CHN
RSEXIT   RTS

CHKPRES  LDA #$00     ;NO FILENAME
         LDX #$00
         LDY #$00
         JSR $FFBD    ;SETNAM
         LDA #$01
         LDX DRIVE
         LDY #$01
         JSR $FFBA    ;SETLFS
         JSR $FFC0    ;OPEN
         LDA #$01
         JSR $FFC3    ;CLOSE
         JSR $FFB7    ;READ STAT
         STA PRES     ;ST=0 IF SUCCESS
         RTS

POSSTAT  LDA #$12     ;RVS ON
         JSR $FFD2
         LDY #$00
         LDX #$00
         CLC
         JMP $FFF0    ;PLOT - SET CSR
                      ;USE RTS IN $FFF0

CLRSTAT  LDA #$A0     ;INV SPACE
         STA $0400,Y
         LDA #$03     ;CYAN
         STA $D800,Y
         INY
         CPY #$28     ;END OF SCR
         BNE CLRSTAT
         LDA #$92     ;INV OFF
         JMP $FFD2    ;USE RTS IN $FFD2

NUMCHAR  CMP #$0A
         BCC NCAHEAD  ;IF < 10 1 DIGIT
         TAX          ;STORE NUMBER
         LDY #$09
NCLOOP   CMP XTEN,Y   ;90->1X
         BCS TENS     ;IF XTEN,Y > A
         DEY
         JMP NCLOOP
TENS     TYA          ;INDEX Y=TENS
         CLC
         ADC #$30     ;CONV TO CHAR
         JSR $FFD2
         TXA          ;RETURN NUMBER
         SEC          ;SET CARRY
         SBC XTEN,Y   ;SUBTRACT TENS
         CLC
NCAHEAD  ADC #$30     ;OFFSET FOR CHAR
         JMP $FFD2    ;USE RTS IN $FFD2

;---------------------------------------
;END OF CODE

