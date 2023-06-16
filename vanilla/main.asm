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

org $00ffc0
    ;   0              f01234
    db "      SM RANDOMIZER  "
    db $30, $02, $0C, $04, $00, $01, $00, $20, $07, $DF, $F8

org $808000				; Disable copy protection screen
	db $ff

; Config flags
incsrc ../common/config.asm

; fast save and reload
incsrc ../common/fast_reload.asm

; Super Metroid custom Samus sprite "engine" by Artheau
;incsrc "sprite/sprite.asm"

org $85FF00
incsrc ../common/nofanfare.asm

; Start anywhere patch, not used right now until graph based generation is in.
; incsrc startanywhere.asm

; Add code to the main code bank
; had to move this from original place ($b88000) since it conflicts with VariaRandomizer's web tracker race protection 
; $b88200 to $b88220
org $b88300
incsrc ../common/multiworld.asm
org $b88800
incsrc ../common/itemextras.asm

; had to move this from original place ($84efe0) since it conflicts with VariaRandomizer's beam_doors_plms patch
; then conflicted with ($84f900) with VariaRandomizer's door_indicators_plms
org $84fc20
incsrc ../common/items.asm

org $b8cf00
incsrc ../common/seeddata.asm

org $b8c800
incsrc ../common/startitem.asm

org $b8d000
incsrc ../common/playertable.asm

org $b8e000
incsrc ../common/itemtable.asm
