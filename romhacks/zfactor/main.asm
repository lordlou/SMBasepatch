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
org $e58000
incsrc ../../common/multiworld.asm
org $e58800
incsrc ../../common/itemextras.asm

org $84fbc0  ; strtolog: had to move from previous place ($84f870) to fit into the bank along with zfactor's PLMs, with only 13 (0xd) bytes to spare
incsrc ../../common/items.asm

;incompatible with zfactor?
;org $b8cf00
;incsrc seeddata.asm

org $e5c800
incsrc ../../common/startitem.asm

org $e5d000
incsrc ../../common/playertable.asm

org $e5e000
incsrc ../../common/itemtable.asm
