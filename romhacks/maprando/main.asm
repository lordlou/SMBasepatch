lorom

macro a8()
	sep #$20
endmacro

macro a16()
	rep #$20
endmacro

macro i8()
	rep #$10
endmacro

macro ai8()
	sep #$30
endmacro

macro ai16()
	rep #$30
endmacro

macro i16()
	rep #$10
endmacro

!table_box = "table box_smmr.tbl"
!table_box_yellow = "table box_yellow_smmr.tbl"
!table_box_green = "table box_green_smmr.tbl"

; linked to check_reload in fast_reload.asm of MapRando
;!check_reload = "jsl $82F82A"

org $00ffc0
    ;   0              f01234
    db "      SM RANDOMIZER  "
    db $30, $02, $0C, $04, $00, $01, $00, $20, $07, $DF, $F8

org $808000				; Disable copy protection screen
	db $ff

;org $a1f200 ; used by fast_reload.asm
;start_location:
    ;; start location: $0000=Zebes Landing site
;    dw $0000

; Config flags
incsrc ../../common/config.asm

; fast save and reload
;incsrc ../../common/fast_reload.asm

; Super Metroid custom Samus sprite "engine" by Artheau
;incsrc "sprite/sprite.asm"

org $85FF00
incsrc ../../common/nofanfare.asm

; Start anywhere patch, not used right now until graph based generation is in.
; incsrc startanywhere.asm

; Add code to the main code bank
; had to move this from original place ($b88000) since it conflicts with VariaRandomizer's web tracker race protection 
; and also MapRando's TitlePatcher (done at generation, search for 0x1C0000)
; $80CF70 + 0x01C0 (for supermetroid_msu1 patch colliding at $80D02F)
; from $80D130 to $80D240 (conflict with MapRando oob_death.asm and vanilla_bugfixes.asm)
org $80D240
incsrc ../../common/multiworld.asm
; $80D470 + 0x01C0 (for supermetroid_msu1 patch colliding at $80D02F)
org $80D630
incsrc ../../common/itemextras.asm

; had to move this from original place ($84efe0) since it conflicts with VariaRandomizer's beam_doors_plms patch
; then conflicted with ($84f900) with VariaRandomizer's door_indicators_plms
; then conflicted with MapRando:
; $FC40 - $FCC0: escape_autosave.asm
; $FD00 - $FE80: credits.asm
org $84f430
incsrc ../../common/items.asm

; no longer needed (see seeddata.asm)
; org $b8cf00
; incsrc ../../common/seeddata.asm

; had to move this from original place ($b8c800) since it conflicts with
; MapRando's TitlePatcher (done at generation, search for 0x1C0000)
; $80D500 + 0x01C0 (for supermetroid_msu1 patch colliding at $80D02F)
org $80D6C0
incsrc ../../common/startitem.asm

org $80D7C0
incsrc ../../common/playertable.asm

org $80E7C0
incsrc ../../common/itemtable.asm
