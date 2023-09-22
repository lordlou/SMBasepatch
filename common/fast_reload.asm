; Fast save and reload (not on death)
; Based on patch by Brent Kerby: https://github.com/blkerby/MapRandomizer which is
; Based on patch by total: https://metroidconstruction.com/resource.php?id=421
; Compile with "asar" (https://github.com/RPGHacker/asar/releases)


!deathhook82 = $82DDC7 ;$82 used for death hook (game state $19)

;free space: make sure it doesnt override anything you have
!freespace82_start = $82F990
!freespace82_end = $82FA71
!freespacea0 = $a0fe00 ;$A0 used for instant save reload

!QUICK_RELOAD = $1f60 ;dont need to touch this
!SRAM_SAVING = $702604
!current_save_slot = $7e0952
!sram_save_slot_addresses = $81812B

lorom

org !freespace82_start
check_reload:
    PHP
    REP #$30
    PHA
    lda $8B      ; Controller 1 input
    and #$3030   ; L + R + Select + Start
    cmp #$3030
    bne .end
    lda.l !SRAM_SAVING  ; Don't reset while saving to SRAM
    bne .end
    lda $0617           ; Don't reset if uploading to the APU
    bne .end
    lda $0998           ; Don't reset during SM boot or title screen
    cmp #$0002
    bcc .end
    lda $7E09C2         ; Don't reset if health is 0
    cmp #$0000
    beq .end
    lda #$000e
    jsl $808233         ; Don't reset if escaping
    bcs .end
    PLA
    PLP
    jsr deathhook
    RTL
.end
    PLA
    PLP
    RTL

deathhook:
    php
    rep #$30
    lda #$0001
    sta !QUICK_RELOAD ; Currently "quick reloading"

    lda.l $a1f200       ; start_location
    cmp #$fffe : bne .zebes
    lda.l #$0000
.zebes
    pha
	lda !current_save_slot
	jsl $818000                     ; Save SRAM

    lda !current_save_slot
    and #$0003
    asl
    sta $12
    tax
    lda !sram_save_slot_addresses, x
    adc #$0156
    tax
    pla
    pha
    and #$ff00 : xba : sta $700002,x ; hi byte is area
    pla
    and #$00ff : sta $700000,x      ; low byte is save index
    jsl sm_fix_checksum             ; Fix SRAM checksum (otherwise SM deletes the file on load)

    jsl $82be17       ; Stop sounds
	lda $0952         ; Load saveslot
    jsl $818085       ; Load savefile
	jsl $80858C		  ; load map
    lda #$0006        
    sta $0998         ; Goto game mode 6 (load game)
    plp
    rts

sm_fix_checksum:
    pha
    phx
    phy
    php

    %ai16()
    
    lda $14
    pha
    stz $14
    lda $12
    tax
    lda !sram_save_slot_addresses, x
    tax
    ldy #$0000
 -
    lda.l $700000,x
    clc
    adc $14
    sta $14
    inx
    inx
    iny
    iny
    cpy #$065c
    bne -

    ldx $12
    lda $14
    sta.l $700000,x
    sta.l $701ff0,x
    eor #$ffff
    sta.l $700008,x
    sta.l $701ff8,x
    pla
    sta $14

    plp
    ply
    plx
    pla
    rtl

warnpc !freespace82_end

; Hook setting up game
org $80a088
    jsl setup_music : nop : nop

org $80A095
    jml setup_game_1

org $80a0ce
    jml setup_game_2

org $80a113
    jml setup_game_3

org $91e164
    jsl setup_samus : nop : nop

; Free space somewhere for hooked code
org !freespacea0
setup_music:
    lda !QUICK_RELOAD
    bne .quick
    stz $07f3
    stz $07f5
.quick
    rtl

setup_game_1:
	jsl $82be17       ; Stop sounds
    lda !QUICK_RELOAD
    bne .quick
    lda #$ffff      ; Do regular things
    sta $05f5
    jml $80a09b
.quick
    jsl $80835d
    jsl $80985f
    jsl $82e76b
    jml $80a0aa

setup_game_2:
    jsl $82be17       ; Stop sounds
    lda !QUICK_RELOAD
    bne .quick
    jsl $82e071
    jml $80a0d2
.quick
    jml $80a0d5

setup_game_3:
    jsl $82be17       ; Stop sounds
    pha
    lda !QUICK_RELOAD
    bne .quick
    pla
    jsl $80982a
    jml $80a117
.quick
    pla
    jsl $80982a
    stz !QUICK_RELOAD
    lda $07c9
    cmp $07f5
    bne .loadmusic
    lda $07cb
    cmp $07f3
    bne .loadmusic
    jml $80a122

.loadmusic
    lda $07c9
    sta $07f5
    lda $07cb
    sta $07f3    

    lda $07cb
    ora #$ff00
    jsl $808fc1
    lda $07c9
    jsl $808fc1

    jml $80a122

setup_samus:
    lda !QUICK_RELOAD
    beq .normal
    lda #$e695
    sta $0a42
    lda #$e725
    sta $0a44
.normal    
    lda $09c2
    sta $0a12
    rtl

warnpc $A18000