; note: also works for otherRotation in addition to Super Metroid: Rotation
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

!table_box = "table box.tbl"
!table_box_yellow = "table box_yellow.tbl"
!table_box_green = "table box_green.tbl"

org $00ffc0
    ;   0              f01234
    db "      SM RANDOMIZER  "
    db $30, $02, $0C, $04, $00, $01, $00, $20, $07, $DF, $F8

org $808000				; Disable copy protection screen
	db $ff

; Config flags
incsrc ../../common/config.asm

; Super Metroid custom Samus sprite "engine" by Artheau
;incsrc "sprite/sprite.asm"

org $85FF00
incsrc ../../common/nofanfare.asm

; Start anywhere patch, not used right now until graph based generation is in.
; incsrc startanywhere.asm

; Add code to the main code bank
org $e28000
incsrc ../../common/multiworld.asm
org $e28800
incsrc ../../common/itemextras.asm

org $84f870                               ; lordlou: had to move this from original place ($84efe0) since it conflicts with VariaRandomizer's beam_doors_plms patch
incsrc ../../common/items.asm

;incompatible with sm: rotation:
;org $b8cf00
;incsrc seeddata.asm

org $e2c800
incsrc ../../common/startitem.asm

org $e2d000
incsrc ../../common/playertable.asm

org $e2e000
incsrc ../../common/itemtable.asm
