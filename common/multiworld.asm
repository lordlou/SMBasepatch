; SM Multiworld support
;

; SRAM map for SRAM space newly created by doubling SRAM size:

; $70:2000 }
; ...      } Item receive queue. 4 bytes per entry
; $70:25FF }

; $70:2600: unused; formerly RPTR aka RCOUNT for item receive queue, & was moved to RAM that gets saved at save stations
; $70:2602: WCOUNT (elements written count) for item receive queue
; $70:2604: SRAM saving marker

; $70:2606 }
; ...      } unused
; $70:267F }

; $70:2680: RCOUNT (elements read count) for item send queue
; $70:2682: WCOUNT (elements written count) for item send queue

; $70:2684 }
; ...      } unused
; $70:26FF }

; $70:2700 }
; ...      } Item send queue (not actually a very fixed size if player keeps reloading and picking up the same item)
; $70:2AFF } 8 bytes per entry

; $70:2B00 }
; ...      } unused
; $70:2FFF }

; $70:3000 (0n21 bytes): "Super Metroid        " (ASCII, no null terminator)
; $70:3015 (0n21 bytes): copy of ROM title

; $70:302a }
; ...      } reserved for future data about game variations and software versions
; $70:305f }

; $70:3060 (4 bytes): multiworld's copy of VARIA seed number ($df:ff00), used for detecting the need to clear all data
;                                                                  above $70:2000 when a new multiworld seed is loaded
; $70:3064 (2 bytes): SRAM_MW_INITIALIZED (#$cafe when initialized)

; $70:3064 }
; ...      } unused
; $70:306F }

; $70:3070 }
; ...      } copy of multiworld ROM config data $CE:FF00 onward (only first several bytes used, rest is reserved)
; $70:316F }


!SRAM_MW_ITEMS_RECV ?= $702000 ; RECV queue buffer
!SRAM_MW_ITEMS_RECV_WCOUNT ?= $702602
!SRAM_SAVING ?= $702604

; This location is always saved to the current slot's data in SRAM on save, and loaded from SRAM slot on load.
; This takes the place of a global SRAM_MW_ITEM_RECV_RCOUNT, since different saves may have processed different amounts
; of the receive queue.
; For example, when Samus takes a death and reloads, this value is rolled back to the queue read position from the time
; of the last save. Samus's items are rolled back to that point in time as well; thus acquisitions queued after the
; save happened are re-processed correctly out of the queue and shown as message boxes on reload.
; Uses unused bits at the end of the end of the array of bits representing item locations acquired.
!ReceiveQueueCompletedCount_InRamThatGetsSavedToSaveSlot = $7ed8ae

!SRAM_MW_ITEMS_SENT_RCOUNT ?= $702680
!SRAM_MW_ITEMS_SENT_WCOUNT ?= $702682
!SRAM_MW_ITEMS_SENT ?= $702700    ; SENT queue buffer. [worldId, itemId, itemIndex] (need unique item index to prevent duping)

!SRAM_MW_SM ?= $703000
!SRAM_MW_ROMTITLE ?= $703015
!SRAM_MW_SEEDINT ?= $703060
!SRAM_MW_INITIALIZED ?= $703064

!SRAM_MW_CONFIG_ENABLED ?= $703070
!SRAM_MW_CONFIG_CUSTOM_SPRITE ?= $703072
!SRAM_MW_CONFIG_DEATHLINK ?= $703074
!SRAM_MW_CONFIG_REMOTE_ITEMS ?= $703076
!SRAM_MW_CONFIG_PLAYER_ID ?= $703078

!varia_seedint_location = $dfff00

!current_save_slot = $7e0952

!check_reload ?= "" ; see freespace82_start in fast_reload.asm

!Big = #$825A
!Small = #$8289
!EmptySmall = #$8436
!Shot = #$83C5
!Dash = #$83CC
!EmptyBig = #message_EmptyBig
!PlaceholderBig = #message_PlaceholderBig

mw_init_memory:
    rep #$30
    lda.l config_multiworld
    beq +
    jsl mw_init         ; Init multiworld
+
    ;jsl $8b9146
    ; restore overwritten instructions before returning:
    sep #$30
    lda #$8F
    rtl

mw_init:
    pha : phx : phy : php
    %ai16()

    ; If already initialized, don't do it again
    lda.l !SRAM_MW_INITIALIZED
    cmp #$cafe
    bne .reset_sram
    lda.l !varia_seedint_location
    cmp.l !SRAM_MW_SEEDINT
    bne .reset_sram
    lda.l !varia_seedint_location+2
    cmp.l !SRAM_MW_SEEDINT+2
    bne .reset_sram
    ; always copy config from ROM to SRAM, in case a player wants to hex edit a change to their config within 1 seed
    jsl copy_config_to_sram
    jmp .end

.reset_sram
    phb
    lda #$0000
    ldx #$2000
    ldy #$2000
    pea $7070
    plb
    plb ; $DB (data bank register) = $70 (first bank of SRAM)
    jsl write_repeated_memory ; zero out $70:2000 - $70:3fff
    plb

    bra .continuereset
.smstringdata
    db "Super Metroid        "
.continuereset
    sep #$20
    phk
    pla
    sta.b $02
    lda #$70
    sta.b $05
    rep #$20
    lda #(.smstringdata) ; copy from $(current program bank):.data in this function
    sta.b $00
    ldy #$0015 ; 0n15 bytes
    lda #(!SRAM_MW_SM) ; copy to SRAM_MW_SM
    sta.b $03
    jsl copy_memory

    sep #$20
    lda #$80
    sta.b $02
    lda #$70
    sta.b $05
    rep #$20
    lda #$ffc0 ; copy from $80:ffc0 (ROM title)
    sta.b $00
    ldy #$0015 ; 0n15 bytes
    lda #(!SRAM_MW_ROMTITLE) ; copy to SRAM_MW_ROMTITLE
    sta.b $03
    jsl copy_memory

    lda #$cafe
    sta.l !SRAM_MW_INITIALIZED
    lda.l !varia_seedint_location
    sta.l !SRAM_MW_SEEDINT
    lda.l !varia_seedint_location+2
    sta.l !SRAM_MW_SEEDINT+2

    jsl copy_config_to_sram

    ; lastly, delete the saves by writing a number and something other than its own inverse to the checksum locations
    ; note: since out of all the vanilla SRAM range $70:0000 - $70:1fff, below is the only location we write, multiworld
    ;       should remain compatible both with VARIA changes and with various romhacks, such as romhacks using
    ;       https://metroidconstruction.com/resource.php?id=285 save/load patch with simpler ingame map tooling - this
    ;       patch increases the size of each save file within the first 0x2000 bytes, but we never write directly to
    ;       those slots, so we're safe.
    lda #$bad0
    ldx #$0010
-
    dex
    dex
    sta $700000,x
    sta $701ff0,x
    bne -

    ; last location to write, and it is also within $70:0000 - $70:1fff: if we're on an old (pre-Sep 2021) version of
    ; VARIA, it doesn't check against the seed but against a fixed value that it always writes (#$cacacaca). if it's not
    ; there at boot, VARIA resets its custom SRAM areas.
    ; unfortunately, VARIA's global SRAM data does fall into the range used by some romhacks' save/load patch mentioned
    ; above. so we want to be careful/sure.
    ; unfortunately part 2, our boot hook comes after VARIA's, so VARIA has already decided whether or not to reset its
    ; SRAM. so we add an extra delete-all-saves step here, acting like pre-Sep 2021 VARIA rando's SRAM reset, if we're
    ; sure that we're on a pre-Sep 2021 VARIA rando.
    ; later versions of VARIA will detect the seed mismatch on their own: if we update to such later versions, then our
    ; modifications within the $70:0000 - $70:1fff range (our clearing of the checksums) will be needed only for
    ; romhacks' sake at that point, and the following check-and-write can be removed.
    lda $701dfc
    cmp #$caca
    bne .end
    lda $701dfe
    cmp #$caca
    bne .end
    ; here we are definitely under a pre-Sep 2021 VARIA that just ran boot code, and the VARIA code may or may not have
    ; just cleared its global SRAM values. but we know it's safe to clear since we know the seed changed.
    ; clear 2 key global VARIA values.
    ; VARIA will then ignore any other initial SRAM data since it is contained in invalid save slots.
    lda #$0000
    sta $701df8 ; used_slots_mask = 0
    sta $701dfa ; last_saveslot = 0

.end
    plp : ply : plx : pla
    rtl


; Write [Y] bytes of [A] to $DB:0000 + [X] - 16 bit
; Must be rep #$30
; Clobbers X and Y
write_repeated_memory:
    pha
    tya
    lsr a
    tay
    pla
.loop
    sta.w $0000,x
    inx
    inx
    dey
    bne .loop

    rtl


; Copy [Y] bytes from [$00] to [$03] (indirect)
; Must be rep #$10 (#$20 bit ignored)
; Clobbers A and Y
copy_memory:
    php
    tya
    lsr a
    bcc .even
    ; y is odd; copy last byte to make it even
    sep #$20
    dey
    lda [$00],y
    sta [$03],y
.even
    rep #$20
    dey
    dey
    bmi .done
.loop
    lda [$00],y
    sta [$03],y
    dey
    dey
    bpl .loop
.done
    plp
    rtl


copy_config_to_sram:
    lda.l config_multiworld
    sta.l !SRAM_MW_CONFIG_ENABLED
    lda.l config_sprite
    sta.l !SRAM_MW_CONFIG_CUSTOM_SPRITE
    lda.l config_deathlink
    sta.l !SRAM_MW_CONFIG_DEATHLINK
    lda.l config_remote_items
    sta.l !SRAM_MW_CONFIG_REMOTE_ITEMS
    lda.l config_player_id
    sta.l !SRAM_MW_CONFIG_PLAYER_ID
    rtl


; Write multiworld item message
; Params (all 16-bit):
;   A = Item Id
;   X = byte offset of item location's row in rando_item_table (ie, location id * 8)
;   Y = world id aka archipelago player id to send to
mw_write_message:
    pha : phx ; for preserving
    phx : pha ; for pulling into A to write out
    lda.l !SRAM_MW_ITEMS_SENT_WCOUNT
    asl #3 : tax
    tya                              ; }
    sta.l !SRAM_MW_ITEMS_SENT, x     ; } these (from params Y and A) are actually ignored by the client.
    pla                              ; } same for the unwritten bytes 6-7
    sta.l !SRAM_MW_ITEMS_SENT+$2, x  ; }
    pla
    sta.l !SRAM_MW_ITEMS_SENT+$4, x ; write location id * 8. client will divide to get location id

    lda.l !SRAM_MW_ITEMS_SENT_WCOUNT
    inc a
    sta.l !SRAM_MW_ITEMS_SENT_WCOUNT
    plx : pla
    rtl


mw_save_sram:
    ; runs just before RAM -> SRAM save
    pha : php
    %ai16()
    lda #$0001
    sta.l !SRAM_SAVING
    plp : pla
    ; restore overwritten instructions
    tax
    ldy #$0000
    rtl

sm_save_done_hook:
    lda #$0000
    sta.l !SRAM_SAVING
    ply : plx : clc : plb : plp
    rtl

mw_load_sram:
    ; runs just after SRAM -> RAM load complete
    pha : php
    %ai16()
    lda.l !SRAM_MW_ITEMS_RECV_WCOUNT
    cmp.l !ReceiveQueueCompletedCount_InRamThatGetsSavedToSaveSlot
    bmi .setnewgame
.done
    plp : pla
    rtl
.setnewgame
    ; this means ReceiveQueueCompletedCount_InRamThatGetsSavedToSaveSlot > SRAM_MW_ITEMS_RECV_WCOUNT.
    ; this is an invalid state where we've supposedly read deeper into the queue than the max amount of data it's had.
    ; the cause is that we auto-cleared the SRAM over $70:2000, including the whole queue, when a new seed was loaded,
    ; but perhaps VARIA rando is not around to similarly auto-clear the save slot data, where the read pointer lives.
    ; let's assume *if* any items are really in the queue, they have already been processed, and make ready to process
    ; the next thing to come in. more than likely, it's 0.
    sta.l !ReceiveQueueCompletedCount_InRamThatGetsSavedToSaveSlot
    bra .done


; Display message that we picked up someone elses item
; X = item id, Y = Other Player Index
mw_display_item_sent:
    stx.b $c1
    sty.b $c3
    ;lda #$0168       ; With fanfare skip, no need to queue room track
    ;jsl $82e118      ; Queue room track after item fanfare
    lda #$7b49 ; magic number
    sta.b $cc
    lda #$0300 ; item sent message box override
    sta.b $ce
    lda #$0019 ; param to function: message box id of something fake but known. 19h = reserve tank vanilla message box id. will be overridden by $ce
    jsl $858080
    stz.b $c1
    stz.b $c3
    stz.b $cc
    stz.b $ce
    rtl

; Prepare overrides for displaying that we picked up an item link item
; X = item id, Y = Other Player Index
mw_prep_item_link_messagebox:
    stx.b $c1
    sty.b $c3
    lda #$7b49 ; magic number
    sta.b $cc
    lda #$0302 ; item link message box override
    sta.b $ce
    lda #$0019 ; param to function: message box id of something fake but known. 19h = reserve tank vanilla message box id. will be overridden by $ce
    rtl

mw_cleanup_item_link_messagebox:
    stz.b $c1
    stz.b $c3
    stz.b $cc
    stz.b $ce
    rtl

; A = item id
mw_receive_item:
    pha : phx
    cmp #$0016
    beq .end                 ; skip receiving if its a Nothing item (#$0016 might also mean offworld progression item? which should be skipped too)
    cmp #$0017
    beq .end                 ; skip receiving if its a No Energy item (#$0017 might also mean offworld non-prog item? which should be skipped too)
    asl ; X =
    tax ;     byte offset within sm_item_plm_pickup_sequence_pointers for this item
    ; sound:
    lda #$0001 ; sound number
    sta.b $cc
    ldy #$00cc ; pointer to sound number
    phb ; data bank cannot be C0+ since SETFX reads from 0000,y and must access WRAM that way
    pea $7e7e
    plb : plb ; DB = $7E
    jsl SETFX
    plb ; restore DB
    lda #$0037
    jsl $809049 ; play sound #$37, or was it 1, idk TODO document
    stz.b $cc
    ; message box:
    lda #$7b49 ; magic number
    sta.b $cc
    lda #$0301 ; item received message box override
    sta.b $ce
    ; X is still the param: byte offset into sm_item_plm_pickup_sequence_pointers per above
    jsl perform_item_pickup   ; Call original item receive code in bank $84 (will eventually read the message box index from $ce)
.end
    stz.b $ce
    stz.b $cc
    plx : pla
    rts

; from varia endingtotals.asm - code copied to here so we don't depend on any jsl address without a symbol
;                               (and in order to save precious room in bank $84 for optional varia decoupling)
; Params:
;     A:     item location id (aka A parameter to $80:818E)
; Returns:
;     A/X:   Byte index ([A] >> 3)
;     $05E7: Bitmask (1 << ([A] &  7))
!CollectedItems  = $7ED86E
COLLECTTANK:
    PHA
    LDA.l !CollectedItems
    INC A
    STA.l !CollectedItems
    PLA
    ; bit math in preparation for storing to world item states bit array 
    JSL $80818E ; $80:818E: Change bit index to byte index and bitmask
    RTL


; point-in-time documentation of all item interactions (anything involving a message box) october 2022:
; mw_handle_queue (multiworld.asm) <-- receive item from network
;    sta $c3
;    if own item received from network (under remote items config) && location is not already marked collected:
;       COLLECTTANK (copied into multiworld.asm - keeps track of item count &
;                    calls vanilla helper that helps set up for setting the item location bit as collected in SRAM)
;    sta $c1
;    mw_receive_item (multiworld.asm)
;       SETFX (nofanfare.asm)
;       $80:9049 play sound
;       sta $cc, ce
;       perform_item_pickup (items.asm)
;          $84:($0000,x) x <-- x = sm_item_table[A].0
;             ends up in $85:8080 like below (see below for details)
; 
;       stz $cc, ce
;     stz $c1, c3
; 
; 
; all plms' instruction lists (i_live_pickup in items.asm)
;    i_live_pickup_multiworld (multiworld.asm)
;       mw_write_message (multiworld.asm) <- to SRAM/network, X=itemloc*8, always performed
;       if we touched ANOTHER player's item:
;          mw_display_item_sent (multiworld.asm) <- show message box for other player's items
;             sta $c1, c3, cc, ce
;             $85:8080 A=message box index
;                $85:8241 Initialise message box (normally calls into function table)
;                   multiworld_messagebox_function_pointerish_calls (multiworld.asm)
;                      lda $ce
;                      PlaceholderBig (multiworld.asm)
;                          write_placeholders (multiworld.asm)
;                             lda $c1 $c3
;                      { $85:8289 small                         }
;                      {  or                                    }
;                      { $85:825A large (all multiworld boxes)  }
;                      both call:
;                         $85:82B8 Write message tilemap
;                             hook_tilemap_calc (multiworld.asm)
;                                lda $ce
;              stz $c1, c3, cc, ce
;       if we touched an item link item that includes ourselves:
;          hybrid approach: override message box like mw_display_item_sent does, but show it via perform_item_pickup,
;          which picks up the item
;       else - ie - we are picking up our OWN item within our world:
;          perform_item_pickup (items.asm) A=0..20
;             $84:($0000,x) <-- x = sm_item_table[A].0
;                 this ends up in $85:8080 as well (see above), but uses the vanilla message table instead of multiworld boxes


mw_handle_queue: ; receive only
    pha : phx

.loop
    lda.l !ReceiveQueueCompletedCount_InRamThatGetsSavedToSaveSlot 
    cmp.l !SRAM_MW_ITEMS_RECV_WCOUNT
    bne .lookup_player
    brl .end

.lookup_player
    asl #2 : tax
    ; X = offset in buffer of next new message to process, bytes of which are:
    ; [source player id.lo, source player id.hi, SM item type, location id where item was found]
    lda.l !SRAM_MW_ITEMS_RECV+$2, x
    sta.b $c1
    lda.l !SRAM_MW_ITEMS_RECV, x
    cmp.l config_player_id
    bne .perform_receive
    ; receiving item from self. should be due to remote items AND/OR item link
    ; (sender id is never the item link id, it's the player who actually had the item placed in their world--in this
    ;  path, also us.)
    lda.b $c1
    xba
    and #$00FF ; A = source location id
    cmp #$00FF
    beq .perform_receive ; location FF -> branch. FF is a special location code meaning "N/A", don't treat as a location
    ; if (remote items disabled && (the message received is (self -> self, any item id, item loc 0) OR
    ;                                                    is (self -> self, any item id, item loc containing an item
    ;                                                                                   link to send to self),
    ; this is the client sending an item link message back to the game that sent it (us), or from another game connected
    ; to the same slot. since the user wants to find all the items placed in their own world and lose them on death,
    ; we DROP this message.
    ; (in the future this could be made to work the way it does for remote items, but currently (0.3.5) the client
    ;  zeroes out the item loc in the message when remote items are disabled, so we can't know what item loc to collect!)
    lda.l config_remote_items
    bit #$0002
    bne .collect_item_if_present
    ; if (remote items disabled && self item location does NOT send to an item link that includes self)), .perform_receive
    lda.b $c1
    xba
    and #$00FF ; A = source location id
    beq .next ; drop
    phx
    asl #3
    tax
    lda.l rando_item_table, x ; load Item Destination Type for the source location of the item we're receiving
    plx
    cmp #$0002
    beq .next ; drop
    ; some other self -> self message with remote items disabled. this shouldn't happen as the server should filter it
    ; out. traditional handling is to accept the item but we could probably do anything
    bra .perform_receive

.collect_item_if_present
    lda.b $c1
    xba
    and #$00FF ; A = source location id
    phx
    pha
    jsl $80818E ; $80:818E: Change bit index to byte index and bitmask
    ; X:        item byte
    ; $7e:05e7: item bit (mask)
    lda $7ed870, X
    and.l $7e05e7 ; check if item bit was already collected
    beq .new_remote_item
    ; item location collection bit is already set (this happens when our own game touched the item)
    pla
    plx
    bra .next

.new_remote_item
    ; our item, but not locally collected:
    ; save remote item as collected
    pla ; A = item location id
    jsl COLLECTTANK
    ; X:        item byte
    ; $7e:05e7: item bit (mask)
    lda $7ed870, X ; re-load item collection array byte
    ora.l $7e05e7  ; } set this location's bit to '1' (collected)
    sta $7ed870, X ; }
    plx
    ; now show message box

.perform_receive
    lda.l !SRAM_MW_ITEMS_RECV, x
    jsl ap_playerid_to_rom_other_player_index
    bcs .found
    lda #$0000 ; should not happen. but receive from "Archipelago" player if not found
.found
    sta.b $c3 ; write Other Player Index for message box
    lda.b $c1
    and #$00FF
    sta.b $c1 ; write item id for message box
    jsr mw_receive_item

.next
    lda.l !ReceiveQueueCompletedCount_InRamThatGetsSavedToSaveSlot 
    inc a
    sta.l !ReceiveQueueCompletedCount_InRamThatGetsSavedToSaveSlot 

    brl .loop

.end
    stz.b $c1
    stz.b $c3
    plx : pla
    rts


; param: A: archipelago playerid to search for
; return value: A: Other Player Index (carry is set)
;               else carry is cleared if not found
ap_playerid_to_rom_other_player_index:
    ; entry [0] should always be id 0 and name "Archipelago", special-case it
    cmp #$0000
    bne .do_search_stage_1
    rtl ; return id 0 -> idx 0
.do_search_stage_1
    ; search our whole list of sorted AP player IDs for the value in A.
    ; list ends with zeroes which we don't care about for this purpose and have already ruled out.
    ; going down an entire list of 202 unique players would take something like ~6% of an frame,
    ; so we try to optimize this slightly with an O(sqrt(n)) algorithm (rather than O(n)):
    ; - pretend rando_player_id_table is 14 columns wide (thus about 14.4 rows) and find the correct row first
    sta.b $00
    phx
    ; skip first table entry (id 0, name "Archipelago", already checked).
    ; start rows at [1, 17, 33, ...] instead of [0, 16, 32, ...]
    ; that way if we hit another id 0, we know it's the end
    ldx #$0002
    ; move forward 0n14 entries (0x1c bytes) until we've gone past the id we're searching for
-
    lda.l rando_player_id_table, x
    beq .checklastrow ; hit the final block of zeroes in table = gone past the id we're searching for
    cmp.b $00
    beq .correctindex
    bpl .checklastrow ; hit a value greater than what what we're searching for = gone past the id we're searching for
    ; advance to next row
    txa
    clc
    adc #$001c
    tax
    cpx #(rando_player_id_table_end-rando_player_id_table)
    bmi -
.checklastrow
    ; we already checked the beginning of the relevant rows, so check the 0n13 non-beginning elements of the last row
    stx.b $02 ; end when x gets back to this index
    txa        ; }
    sec        ; }
    sbc #$001a ; } X -= 0n13 word-sized array elements
    tax        ; }
-
    lda.l rando_player_id_table, x
    beq .notfound
    cmp.b $00
    beq .correctindex
    inx
    inx
    cpx.b $02
    bmi -

.notfound
    clc
    plx
    rtl
.correctindex
    txa
    lsr ; byte index -> array index (divide by 2)
    sec
    plx
    rtl


i_live_pickup_multiworld: ; touch PLM code
    phx : phy : php
    lda.l $1dc7, x              ; Load PLM room argument (item location id). '.l' makes this work with DB>=$c0
    asl #3 : tax                ; index by item location id into rando_item_table (entry size 8 bytes)

    lda.l config_player_id
    tay
    lda.l rando_item_table, x  ; Load item destination type
    beq .send_network ; skip looking up the destination player id/world id if it's our own item

    lda.l rando_item_table+$4, x    ; Load Other Player Index, convert to other player id, and transfer to Y
    asl
    phx
    tax
    lda.l rando_player_id_table, x
    plx
    tay
.send_network
    ; params: A = Item Id, X = byte offset of item location's row in rando_item_table (ie, location id * 8), Y = world id to send to (all 16-bit)
    lda.l rando_item_table+$2, x ; load Item Id
    jsl mw_write_message       ; Send message over network/SRAM

    lda.l rando_item_table, x  ; Load item destination type
    beq .own_item
    cmp #$0001
    beq .otherplayers_item
    ; type of item == #$0002: SM item link item that sends to the current player and others
    bra .item_link_item

.own_item
    lda.l rando_item_table+$2, x ; Load item id
    cmp #$0015
    bmi .own_item1
    lda #$0014              ; self item id >= #$0015 should never happen... but just call it a reserve tank (#$0014) to avoid a crash
.own_item1
    ; param X = byte offset of item data within sm_item_plm_pickup_sequence_pointers for this item
    asl
    tax
    jsl perform_item_pickup
    bra .end

.otherplayers_item
    ; type of item == #$0001: other player's item:
    lda.l rando_item_table+$4, x    ; Y = Other Player Index
    tay
    lda.l rando_item_table+$2, x    ; X = original item id aka message table index again
    tax
    ; params: X = item id, Y = Other Player Index
    jsl mw_display_item_sent     ; Display custom message box
    bra .end

.item_link_item
    ; pick up the item for ourselves now since we know it's ours, rather than incur a network delay.
    ; show a special message box since it's a send to others at the same time.
    lda.l rando_item_table+$4, x    ; Y = Other Player Index
    tay
    lda.l rando_item_table+$2, x    ; X = original item id aka message table index again
    tax
    cmp #$0015 ; } skip immediate pickup and message box if this isn't an SM item
    bpl .end   ; } (this is never expected). should still receive back from network if valid
    ; params: X = item id, Y = Other Player Index
    jsl mw_prep_item_link_messagebox
    ; param X = byte offset of item data within sm_item_plm_pickup_sequence_pointers for this item
    txa
    asl
    tax
    jsl perform_item_pickup ; also displays the overridden message box
    jsl mw_cleanup_item_link_messagebox
    bra .end

.end
    plp : ply : plx
    rtl


mw_hook_main_game:
    jsl $A09169     ; Last routine of game mode 8 (main gameplay)
    !check_reload
    lda.l config_multiworld
    beq +
    lda.l $7e0998
    cmp #$0008
    bne +
    lda.l $7e079B
    cmp #$DF45      ; exclude first room of Ceres as its in Mode7 so doesnt handle message box properly
    beq +
    jsr mw_handle_queue     ; Handle MW RECVQ only in gamemode 8
+
    rtl

patch_load_multiworld:
    jsl mw_load_sram
    ; restore overwritten & skipped instructions
    ply
    plx
    clc
    plb
    rtl

pushpc
org $8B914A ; hook boot @ $8B:9146 Initialise IO registers and display Nintendo logo
    ; Multiworld init
    jsl mw_init_memory

org $8180f7
    jml patch_load_multiworld

org $818027 ; hook saving @ $81:8000 Save to SRAM (after VARIA randomizer's hook - point being to not collide)
    jsl mw_save_sram

org $81807F
    jml sm_save_done_hook

org $828BB3
    jsl mw_hook_main_game

namespace message
org $859963

!table_box_yellow,rtl
item_names:
    dw "___      AN ENERGY TANK      ___"
    dw "___         MISSILES         ___"
    dw "___       SUPER MISSILES     ___"
    dw "___        POWER BOMBS       ___"
    dw "___          BOMBS           ___"
    dw "___       CHARGE BEAM        ___"
    dw "___         ICE BEAM         ___"
    dw "___       HI-JUMP BOOTS      ___"
    dw "___       SPEED BOOSTER      ___"
    dw "___        WAVE BEAM         ___"
    dw "___       S P A Z E R        ___"
    dw "___       SPRING BALL        ___"
    dw "___        VARIA SUIT        ___"
    dw "___       GRAVITY SUIT       ___"
    dw "___       X-RAY SCOPE        ___"
    dw "___       PLASMA BEAM        ___"
    dw "___      GRAPPLING BEAM      ___"
    dw "___        SPACE JUMP        ___"
    dw "___       SCREW ATTACK       ___"
    dw "___       MORPHING BALL      ___"
    dw "___      A RESERVE TANK      ___"

    ; add 100 more entries for worst case of a different item at each location
    ; to be filled by patcher
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
cleartable


!table_box,rtl
    ;   0                              31
item_sent:
    dw "___         YOU FOUND        ___"
    dw "___      ITEM NAME HERE      ___"
    dw "___           FOR            ___"
    dw "___          PLAYER          ___"
item_sent_end:

item_received:
    dw "___       YOU RECEIVED       ___"
    dw "___      ITEM NAME HERE      ___"
    dw "___           FROM           ___"
    dw "___          PLAYER          ___"
item_received_end:

item_link_distributed:
    dw "___         YOU FOUND        ___"
    dw "___      ITEM NAME HERE      ___"
    dw "___     FOR YOURSELF AND     ___"
    dw "___      ITEM LINK NAME      ___"
; item link name is just stored as a player name, no special handling needed
item_link_distributed_end:

cleartable

write_placeholders:
    phx : phy

.adjust
    lda.b $c1                 ; Load item id
    asl #6 : tay
    ldx #$0000
    phb
    phk : plb ; DB = program bank register.
              ; note, item_names must be in an exlpicitly known bank (here, same bank as this asm)
              ; .. in order to index into it with lda ,y (there is no lda.l ,y)
-
    lda item_names, y       ; Write item name to box
    sta.l $7e3280, x
    inx #2 : iny #2
    cpx #$0040
    bne -

    plb ; restore previous DB
    lda.b $c3 ; load Other Player Index
    asl #4 : tax
    ldy #$0000
-
    lda.l rando_player_name_table, x
    and #$00ff
    phx
    asl : tax               ; Put char table offset in X
    lda.l char_table-$40, x 
    tyx
    sta.l $7e3310, x
    iny #2
    plx
    inx
    cpy #$0020              ; 16 char player name
    bne -
    rep #$30

.end
    ply : plx
    lda #$0020
    rts

!table_box_green,rtl
char_table:
    dw " \!""#$%%'()*+,-./"
    dw "0123456789:;<=>?"
    dw "@ABCDEFGHIJKLMNO"
    dw "PQRSTUVWXYZ[\\]^_"
cleartable

PlaceholderBig:
    ; warning: if calling directly, caller must restore their own register widths, since $85:841D calls $85:831E, which blithely SEPs #$20
    REP #$30
    JSR write_placeholders
    LDY #$0000
    JMP $841D

; if we need a multiworld message box, call its setup functions
; else go back to the vanilla way of init'ing a message box
; return value:
;   sec if multiworld functions called
;   clc if vanilla behavior should continue
multiworld_init_new_messagebox_if_needed:
    pha
    lda.b $cc     ; if $cc and $ce are set, they override the message box
    cmp #$7b49 ; magic number
    bne .vanilla
    lda.b $ce
    cmp #$0300
    beq .msgbox_mwsend
    cmp #$0301
    beq .msgbox_mwrecv
    cmp #$0302
    beq .msgbox_mw_item_link
.vanilla
    ; restore original code
    pla
    dec
    asl
    sta.b $34
    asl
    clc
    rts
.msgbox_mwsend
.msgbox_mwrecv
.msgbox_mw_item_link
    ; simulate table entry: dw !PlaceholderBig, !Big, item_sent
    ;       or table entry: dw !PlaceholderBig, !Big, item_received
    ;       or table entry: dw !PlaceholderBig, !Big, item_link_distributed
    jsr $825A ; vanilla large message box init routine $85:825A (no parameters)
    php
    jsr PlaceholderBig
    plp
    pla
    sec ; set carry, indicating skip normal table-based function calls
    rts

; if we need a multiworld message box, calculate its data source
; else restore vanilla code
; return value:
;   if multiworld, these values are modified from original code:
;      in mem location $00: message tilemap source (like memcpy src) (bank $85 implied)
;      in mem location $09: message tilemap size   (like memcpy n bytes)
;      in A:                ^same value as held in $09 (next vanilla instruction to execute in all cases will be sta.b $09 btw)
hook_tilemap_calc:
    ; orig code figures out source and size based on table value math; for the 2 multiworld messages, no message table, we set fixed sources and sizes in the code here
    pha
    lda.b $ce     ; if $ce is set, it overrides the message box
    cmp #$0300
    beq .msgbox_mwsend
    cmp #$0301
    beq .msgbox_mwrecv
    cmp #$0302
    beq .msgbox_mw_item_link
.vanilla
    ; restore original code
    pla
    sec
    sbc.b $00
    rts
.msgbox_mwsend
    pla
    stz.b $ce
    lda #item_sent ; 16-bit pointer to sent box template
    sta.b $00 ; $00 = message tilemap source
    lda #(item_sent_end-item_sent)
    sta.b $09 ; $09 = message tilemap size
    rts
.msgbox_mwrecv
    pla
    stz.b $ce
    lda #item_received ; 16-bit pointer to receive box template
    sta.b $00 ; $00 = message tilemap source
    lda #(item_received_end-item_received)
    sta.b $09 ; $09 = message tilemap size
    rts
.msgbox_mw_item_link
    pla
    stz.b $ce
    lda #item_link_distributed ; 16-bit pointer to receive box template
    sta.b $00 ; $00 = message tilemap source
    lda #(item_link_distributed_end-item_link_distributed)
    sta.b $09 ; $09 = message tilemap size
    rts


; hook the relevant locations where an item's message box index will be read from $1c1f in RAM and used
org $858246 ; inside $85:8241 Initialise message box
    jsr multiworld_init_new_messagebox_if_needed
    bcc .normal
    rts ; functions were already called, don't call again
.normal

org $8582F9 ; inside $85:82B8 Write message tilemap
    jsr hook_tilemap_calc

pullpc
namespace off
