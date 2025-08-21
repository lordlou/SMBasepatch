; data and code moved from items.asm to reduce usage of very in-demand bank $84 (PLMs bank)

; Graphics pointers for items (by item index)
; relocatable to any bank
; indexed by 0 <= item id <= 0n23
sm_item_graphics:
    ; pointers to a 10-byte graphics data entry anywhere in bank $84 (this value will be saved by $84:8764 Load item PLM GFX)
    ; for example: $84:E12F in vanilla ROM contains: $8000 (implied bank $89:8000: bomb plm graphic data), followed by 8 palette indices
    ;              $84:E12F: $8000,00,00,00,00,00,00,00,00
    ; the first 4 entries were always loaded in vanilla but are now dynamically loaded by Map Rando (see etank_gfx_header and following in Item Loading.asm)
    dw $86DD ; Energy Tank
    dw $86E7 ; Missile
    dw $86F1 ; Super Missile
    dw $86FB ; Power Bomb

    dw $E12F ; Bombs (graphics at $89:8000)
    dw $E15D ; Charge (graphics at $89:8B00)
    dw $E18B ; Ice Beam (graphics at $89:8C00)
    dw $E1B9 ; Hi-Jump (graphics at $89:8400)
    dw $E1E7 ; Speed booster (graphics at $89:8A00)
    dw $E215 ; Wave beam (graphics at $89:8D00)
    dw $E243 ; Spazer (graphics at $89:8F00)
    dw $E271 ; Spring ball (graphics at $89:8200)
    dw $E2A3 ; Varia suit (graphics at $89:8300)
    dw $E2D8 ; Gravity suit (graphics at $89:8100)
    dw $E30D ; X-ray scope (graphics at $89:8900)
    dw $E33A ; Plasma beam (graphics at $89:8E00)
    dw $E368 ; Grapple beam (graphics at $89:8800)
    dw $E395 ; Space jump (graphics at $89:8600)
    dw $E3C3 ; Screw attack (graphics at $89:8500)
    dw $E3F1 ; Morph ball (graphics at $89:8700)
    dw $E41F ; Reserve tank (graphics at $89:9000)
    dw $F00E ; F000 + E (Map Rando WallJump boots items, see walljump_item.asm) (graphics at $89:9100)
    dw plm_graphics_entry_offworld_progression_item
    dw plm_graphics_entry_offworld_item

; indexed by 0 <= item id <= 23
sm_item_plm_pickup_sequence_pointers:
    ; for each type of item, this list points to a useful sequence of PLM data in bank $84
    ; for example, the original bank $84 contains: dw $8968, $0100
    ; this is very useful data to point to for calling the E-Tank pickup function at $84:8968 (note, cannot jsr to a pointer, only to a pointer to a pointer)
    ; we point to the first byte in this sequence in each case
    ; $pointer: points to (bank $84 data):
    ;                          PLM oriented function pointer, [optional word parameter to function], [optional byte parameter to function]
    dw $E0B6 ; E-Tank:         E-Tank function,               100
    dw $E0DB ; Missiles:       Missiles function,             5
    dw $E100 ; Super Missiles: Super Missiles function,       5
    dw $E125 ; Power Bombs:    Power Bombs function,          5
    dw $E152 ; Bombs:          generic item function,         item bitmask,                           message box id byte
    dw $E180 ; Charge beam:    generic beam function,         beam bitmask,                           message box id byte
    dw $E1AE ; Ice beam:       generic beam function,         beam bitmask,                           message box id byte
    dw $E1DC ; Hi-jump:        generic item function,         item bitmask,                           message box id byte
    dw $E20A ; Speed booster:  generic item function,         item bitmask,                           message box id byte
    dw $E238 ; Wave beam:      generic beam function,         beam bitmask,                           message box id byte
    dw $E266 ; Spazer:         generic beam function,         beam bitmask,                           message box id byte
    dw $E294 ; Spring ball:    generic item function,         item bitmask,                           message box id byte
    dw $E2C8 ; Varia suit:     generic item function,         item bitmask,                           message box id byte
    dw $E2FD ; Gravity suit:   generic item function,         item bitmask,                           message box id byte
    dw $E330 ; X-ray scope
    dw $E35D ; Plasma beam:    generic beam function,         beam bitmask,                           message box id byte
    dw $E38B ; Grapple
    dw $E3B8 ; Space jump:     generic item function,         item bitmask,                           message box id byte
    dw $E3E6 ; Screw attack:   generic item function,         item bitmask,                           message box id byte
    dw $E414 ; Morph ball:     generic item function,         item bitmask,                           message box id byte
    dw $E442 ; Reserve tank:   Reserve tank function,         100
    dw plm_sequence_walljump_item ; WallJump boots from Map Rando (see collect_WallJump in walljump_item.asm)
    dw plm_sequence_generic_item_0_bitmask ; off-world progression item: generic item function
    dw plm_sequence_generic_item_0_bitmask ; off-world item: generic item function

i_item_setup_shared:
    phy : phx
    tyx
    lda.l $7e1dc7, x                    ; Load PLM room argument (tells us which of the 100 items this is)
    asl #3                          ; Multiply by 8 for table width
    tax
    lda.l rando_item_table+$2, x       ; Load item id from item table
    cmp #$0016
    bmi .all_items
    ; offworld item:
    lda #$0016              ; item ids over 20 (#$0016 and up) are used to display off-world item names, but the graphics are always either item gfx #$0016 or #$0017
    clc : adc.l rando_item_table+$6, x      ; add one if off-world item isnt progression
.all_items
    asl ; multiply by 2 for table width
    tax
    lda.l sm_item_graphics, x
    plx : ply
    rtl

