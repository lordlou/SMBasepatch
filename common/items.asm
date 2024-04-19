!IBranchItem = #$887C
!ISetItem = #$8899
!ILoadSpecialGraphics = #$8764
!ISetGoto = #$8A24
!ISetPreInstructionCode = #$86C1
!IDrawCustom1 = #$E04F
!IDrawCustom2 = #$E067
!IGoto = #$8724
!IKill = #$86BC
!IPlayTrackNow = #$8BDD
!IJSR = #$8A2E
!ISetCounter8 = #$874E
!IGotoDecrement = #$873F
!IGotoIfDoorSet = #$8A72
!ISleep = #$86B4
!IVisibleItem = #i_visible_item
!IChozoItem = #i_chozo_item
!IHiddenItem = #i_hidden_item
!ILoadCustomGraphics = #i_load_custom_graphics
!IPickup = #i_live_pickup
!IStartVisibleOrChozoDrawLoop = #i_start_draw_loop_visible_or_chozo
!IStartHiddenDrawLoop = #i_start_draw_loop_hidden

!ITEM_RAM = $7E09A2

; SM Item Patches (bank $84)

;pushpc
;org $8095f7
;    jsl nmi_read_messages : nop
;pullpc

; Add custom PLM that can asynchronously load in items
; ALL items in archipelago sm will use one of these 3 PLMs:
archipelago_visible_item_plm:
    dw i_visible_item_setup, v_item       ;fc20 if we're org'ed at $84fc20
archipelago_chozo_item_plm:
    dw i_visible_item_setup, c_item       ;fc24 if we're org'ed at $84fc20
archipelago_hidden_item_plm:
    dw i_hidden_item_setup,  h_item       ;fc28 if we're org'ed at $84fc20


; new PLM graphics (only 2)
; each entry is the full set of arguments (10 bytes) for vanilla function $84:8764 Instruction - load item PLM GFX
;     see e.g. vanilla $84:E15B-E167 for an example structure of the data (charge beam plm)
;     this table is at $84f87c IF we're orged at $84f870
plm_graphics_entry_offworld_progression_item:
    dw offworld_graphics_data_progression_item    ; off-world progression item (pointer = $9200)
prog_item_eight_palette_indices: ; symbol provided for AP patcher to overwrite these 8 bytes:
    db $00, $00, $00, $00, $00, $00, $00, $00
; table entry 2 of 2:
plm_graphics_entry_offworld_item:
    dw offworld_graphics_data_item    ; off-world item (pointer = $9300)
nonprog_item_eight_palette_indices: ; symbol provided for AP patcher to overwrite these 8 bytes:
    db $00, $00, $00, $00, $00, $00, $00, $00

pushpc
org $899200
offworld_graphics_data_progression_item:
org $899300
offworld_graphics_data_item:
; the randomizer's patcher will write the actual graphics here at $89:9200 and $89:9300
pullpc ; back to bank $84
v_item:
    dw !IVisibleItem
c_item:
    dw !IChozoItem
h_item:
    dw !IHiddenItem

; indexed by 0 <= item id <= 3
ammo_loop_table:
    ; PLM instruction sequence pointers:
    ;   loop sequence,   hidden loop sequence
    dw #p_etank_loop,   #p_etank_hloop   ; E-Tank
    dw #p_missile_loop, #p_missile_hloop ; Missiles
    dw #p_super_loop,   #p_super_hloop   ; Super Missiles
    dw #p_pb_loop,      #p_pb_hloop      ; Power Bombs

i_visible_item:
    lda #$0006
    jsr i_load_rando_item
    rts

i_chozo_item:
    lda #$0008
    jsr i_load_rando_item
    rts

i_hidden_item:
    lda #$000A
    jsr i_load_rando_item
    rts

p_etank_loop:
    dw $0004, $a2df
    dw $0004, $a2e5
    dw !IBranchItem, p_visible_item_end
    dw !IGoto, p_etank_loop

p_missile_loop:
    dw $0004, $A2EB
    dw $0004, $A2F1
    dw !IBranchItem, p_visible_item_end
    dw !IGoto, p_missile_loop

p_super_loop:
    dw $0004, $A2F7
    dw $0004, $A2FD
    dw !IBranchItem, p_visible_item_end
    dw !IGoto, p_super_loop

p_pb_loop:
    dw $0004, $A303
    dw $0004, $A309
    dw !IBranchItem, p_visible_item_end
    dw !IGoto, p_pb_loop

p_etank_hloop:
    dw $0004, $a2df
    dw $0004, $a2e5
    dw !IGotoDecrement, p_etank_hloop
    dw !IJSR, $e020
    dw !IGoto, p_hidden_item_loop2

p_missile_hloop:
    dw $0004, $A2EB
    dw $0004, $A2F1
    dw !IGotoDecrement, p_missile_hloop
    dw !IJSR, $e020
    dw !IGoto, p_hidden_item_loop2

p_super_hloop:
    dw $0004, $A2F7
    dw $0004, $A2FD
    dw !IGotoDecrement, p_super_hloop
    dw !IJSR, $e020
    dw !IGoto, p_hidden_item_loop2

p_pb_hloop:
    dw $0004, $A303
    dw $0004, $A309
    dw !IGotoDecrement, p_pb_hloop
    dw !IJSR, $e020
    dw !IGoto, p_hidden_item_loop2

p_visible_item:
    dw !ILoadCustomGraphics
    dw !IBranchItem, .end
    dw !ISetGoto, .trigger
    dw !ISetPreInstructionCode, $df89
    dw !IStartVisibleOrChozoDrawLoop
    .loop
    dw !IBranchItem, .end
    dw !IDrawCustom1
    dw !IDrawCustom2
    dw !IGoto, .loop
    .trigger
    dw !ISetItem
    dw SOUNDFX_84 : db !Click
    dw !IPickup
    .end
    dw !IGoto, $dfa9

p_chozo_item:
    dw !ILoadCustomGraphics
    dw !IBranchItem, .end
    dw !IJSR, $dfaf
    dw !IJSR, $dfc7
    dw !ISetGoto, .trigger
    dw !ISetPreInstructionCode, $df89
    dw !ISetCounter8 : db $16
    dw !IStartVisibleOrChozoDrawLoop
    .loop
    dw !IBranchItem, .end
    dw !IDrawCustom1
    dw !IDrawCustom2
    dw !IGoto, .loop
    .trigger
    dw !ISetItem
    dw SOUNDFX_84 : db !Click
    dw !IPickup
    .end
    dw $0001, $a2b5
    dw !IKill   

p_hidden_item:
    dw !ILoadCustomGraphics
    .loop2
    dw !IJSR, $e007
    dw !IBranchItem, .end
    dw !ISetGoto, .trigger
    dw !ISetPreInstructionCode, $df89
    dw !ISetCounter8 : db $16
    dw !IStartHiddenDrawLoop
    .loop
    dw !IBranchItem, .end
    dw !IDrawCustom1
    dw !IDrawCustom2
    dw !IGotoDecrement, .loop
    dw !IJSR, $e020
    dw !IGoto, .loop2
    .trigger
    dw !ISetItem
    dw SOUNDFX_84 : db !Click
    dw !IPickup
    .end
    dw !IJSR, $e032
    dw !IGoto, .loop2

SOUNDFX_84:
    jsr !SOUNDFX
    rts

i_start_draw_loop_visible_or_chozo:
    lda #$0000
    sta.b $00 ; $00 = 'visible or chozo item' column's offset in ammo_loop_table (+0 bytes) (for in case this is an ammo item)
    bra i_start_draw_loop

i_start_draw_loop_hidden:
    lda #$0002
    sta.b $00 ; $00 = 'hidden item' column's offset in ammo_loop_table (+2 bytes) (for in case this is an ammo item)
    ; bra i_start_draw_loop ; not needed
;   fall through to i_start_draw_loop
; |         |         |
; v         v         v

i_start_draw_loop:
    phx
    lda $1dc7, x              ; Load PLM room argument
    asl #3 : tax
    lda.l rando_item_table+$2, x ; Load item id
    cmp #$0016
    bmi .all_items
    ; offworld item:
    ; item ids #$0016 and up are used to display off-world item names, but the graphics are always either
    ; item gfx #$0016 or #$0017 (0n22 or 0n23) based only on whether the item is progression/advancement
    lda #$0016
    clc
    adc.l rando_item_table+$6, x      ; add one if off-world item isnt progression

.all_items
    cmp #$0004
    bpl .non_ammo_item
    ; item id <= 3: a graphics-always-loaded 'ammo'-ish item (etank, missile, super, or pb):
    asl #2    ; \
    clc       ;  } X = item id * 4   + (2 if hidden, 0 otherwise)
    adc.b $00 ;  }     ^ selects row    ^ selects column
    tax       ; /
    lda.l ammo_loop_table, x
    tay
    plx
    rts ; return Y = pointer to next position in PLM instruction sequence (sort of a 'goto' conceptually)

.non_ammo_item
    plx
    rts


i_load_custom_graphics:
    phy : phx : phx
    lda $1dc7, x                   ; Load PLM room argument (tells us which of the 100 items this is)
    asl #3                         ; Multiply by 8 for table width
    tax
    lda.l rando_item_table+$2, x      ; Load item id from item table
    cmp #$0016
    bmi .all_items
    ; offworld item:
    lda #$0016              ; item ids over 20 (#$0016 and up) are used to display off-world item names, but the graphics are always either item gfx #$0016 or #$0017
    clc : adc.l rando_item_table+$6, x      ; add one if off-world item isnt progression
.all_items
    plx

    asl ; multiply by 2 for table width
    tax
    lda.l sm_item_graphics, x
    bpl .alwaysloaded   ; if high bit is not set, this isn't a pointer
    tay ; Y = pointer to 10-byte graphics entry to load (implied bank $84)
    plx ; X = PLM index again
    jsr $8764               ; Jump to original PLM graphics loading routine ($84:8764)
    ply
    rts

.alwaysloaded
    tax
    lda.b $00, x
    plx ; X = PLM index again
    sta.l $7edf0c, x
    ply
    rts

i_visible_item_setup:
    jsl i_item_setup_shared
    jmp $ee64 ; generic visible item setup

i_hidden_item_setup:
    jsl i_item_setup_shared
    jmp $ee8e


i_load_rando_item:
    cmp #$0006 : bne +
    ldy #p_visible_item
    bra .end
+   cmp #$0008 : bne +    
    ldy #p_chozo_item
    bra .end
+   ldy #p_hidden_item

.end
    rts

; Pick up SM item
i_live_pickup:
    jsl i_live_pickup_multiworld
    rts

; X = byte offset into sm_item_plm_pickup_sequence_pointers of item to pick up
; (clobbers Y)
perform_item_pickup:
    phx
    phb
    phk : plb ; DB = $84
    ; sm_item_plm_pickup_sequence_pointers[entry]: ROM data pointer
    ; in turn...                                   ROM data pointer -> function pointer, function args
    ; (ROM data pointer's implied bank is bank $84)
    lda.l sm_item_plm_pickup_sequence_pointers, x
    tax ; X = ROM data pointer
    tay
    iny : iny ; Y = points to function args (pointer X + 2 bytes)
    jsr ($0000,x) ; X is not a function pointer but it points to one
    plb
    plx
    rtl

; function pointer data usable for 'picking up' other players' items (which to SM is just a message box)
plm_sequence_generic_item_0_bitmask:
    ; $84:88F3 = generic item pickup function, parameters:
    ;   #$0000 = do not actually pick up an item (this gets harmlessly OR'ed into samus's equipment)
    ;   #$19 = reserve tank's message box id (will be overriden)
    dw $88F3, $0000 : db $19

; used for Map Rando's Walljump boots item
plm_sequence_walljump_item:
    dw $88F3, $0400
    db $1E
