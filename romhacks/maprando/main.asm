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
!table_box_yellow = "table box_smmr.tbl"
!table_box_green = "table box_smmr.tbl"

!SRAM_MW_ITEMS_RECV = $702602 ; current item RECV
!SRAM_MW_ITEMS_RECV_WCOUNT = $702606
!SRAM_SAVING = $702608

!SRAM_MW_ITEMS_SENT_RCOUNT = $70260A
!SRAM_MW_ITEMS_SENT_WCOUNT = $70260C
!SRAM_MW_ITEMS_SENT = $70260E    ; current item SENT. [worldId, itemId, itemIndex] (need unique item index to prevent duping)

!SRAM_MW_SM = $702620
!SRAM_MW_ROMTITLE = $702635
!SRAM_MW_SEEDINT = $702660
!SRAM_MW_INITIALIZED = $702664

!SRAM_MW_CONFIG_ENABLED = $702670
!SRAM_MW_CONFIG_CUSTOM_SPRITE = $702672
!SRAM_MW_CONFIG_DEATHLINK = $702674
!SRAM_MW_CONFIG_REMOTE_ITEMS = $702676
!SRAM_MW_CONFIG_PLAYER_ID = $702678

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

; Map Rando already does this with itemsounds patch
; org $85FF00
; incsrc ../../common/nofanfare.asm

; Start anywhere patch, not used right now until graph based generation is in.
; incsrc startanywhere.asm

; Add code to the main code bank
; had to move this from original place ($b88000) since it conflicts with VariaRandomizer's web tracker race protection 
; and also MapRando's TitlePatcher (done at generation, search for 0x1C0000)
; $80CF70 + 0x02C0 (for supermetroid_msu1 patch colliding at $80D240)
; from $80D130 to $80D340 (conflict with MapRando oob_death.asm, vanilla_bugfixes.asm and msu1.asm)
; from $80D340 to $80E180 (conflict with MapRando reserve_hud.asm)
; from $80E180 to $80E660 (conflict with MapRando decompression.asm)
org $80E660
incsrc ../../common/multiworld.asm
; $80D470 + 0x02C0 (for supermetroid_msu1 patch colliding at $80D240)
; from $80D730 to $80E570 (conflict with MapRando reserve_hud.asm)
; from $80E570 to end of multiworld.asm (conflict with MapRando decompression.asm)
; org $80E570
incsrc ../../common/itemextras.asm

; had to move this from original place ($84efe0) since it conflicts with VariaRandomizer's beam_doors_plms patch
; then conflicted with ($84f900) with VariaRandomizer's door_indicators_plms
; then conflicted with MapRando:
; $FC40 - $FCC0: escape_autosave.asm
; $FD00 - $FE80: credits.asm
org $84F4E0
incsrc ../../common/items.asm

; no longer needed (see seeddata.asm)
; org $b8cf00
; incsrc ../../common/seeddata.asm

; had to move this from original place ($b8c800) since it conflicts with
; MapRando's TitlePatcher (done at generation, search for 0x1C0000)
; $80D500 + 0x02D0 (for supermetroid_msu1 patch colliding at $80D240)
; moved from $80D7D0 to $83BA00 (for msu1, reserve_hud patch and Palette pointer table for Mosaic colliding)
; now done by map rando
; org $83BA00 ; size of 0xF0
; incsrc ../../common/startitem.asm

; org $80D8C0
org $83BAF0 ; size of 0xF00
incsrc ../../common/playertable.asm

; org $80E7C0
org $83D8F0
incsrc ../../common/itemtable.asm
