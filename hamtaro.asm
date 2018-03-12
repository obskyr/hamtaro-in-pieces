INCLUDE "constants.inc"

SECTION "Interrupt vector $0", ROM0[$0000]
    REPT 8
    DB $FF
    ENDR

SECTION "Interrupt vector $8", ROM0[$0008]
    REPT 8
    DB $FF
    ENDR

SECTION "Interrupt vector $10", ROM0[$0010]
    REPT 8
    DB $FF
    ENDR

SECTION "Interrupt vector $18", ROM0[$0018]
    jp $2A56 ; Which is...?
    REPT 5
    DB $FF
    ENDR

SECTION "Interrupt vector $20", ROM0[$0020]
    jp $2A62 ; Which is...?
    REPT 5
    DB $FF
    ENDR

SECTION "Interrupt vector $28", ROM0[$0028]
    jp $2A77 ; Which is...?
    REPT 5
    DB $FF
    ENDR

SECTION "Interrupt vector $30", ROM0[$0030]
    REPT 8
    DB $FF
    ENDR

SECTION "Interrupt vector $38", ROM0[$0038]
Interrupt_GetStuckForever:
    REPT 8
    DB $FF
    ENDR

SECTION "V-blank interrupt", ROM0[$0040]
Interrupt_VBlank:
    jp $059A ; Call it NewFrame or whatever.
    REPT 5
    DB $FF
    ENDR

SECTION "LCD interrupt", ROM0[$0048]
Interrupt_Lcd:
    jp $085E
    REPT 5
    DB $FF
    ENDR

SECTION "Timer interrupt", ROM0[$0050]
Interrupt_Timer:
    jp $048B
    REPT 5
    DB $FF
    ENDR

SECTION "Serial interrupt", ROM0[$0058]
Interrupt_Serial:
    jp $048C
    REPT 5
    DB $FF
    ENDR

SECTION "Button interrupt", ROM0[$0060]
Interrupt_Button:
    REPT 8
    DB $FF
    ENDR

SECTION "Unused post-interrupt space", ROM0[$0068]
    REPT $100 - $68
    DB $FF
    ENDR

SECTION "Entry point", ROM0[$0100]
EntryPoint::
    nop
    jp Start

SECTION "Start", ROM0[$0254]
Start::
    cp a, M_MagicIsGbc
    ld sp, $FFFD
    jp nz, DisplayGbcOnlyScreen

    ; Sets the bottom stack return address to the entry point.
    ld a, (EntryPoint >> 8) & $FF
    ldh [$FFFE], a

    ld a, 1
    and b
    jr z, .skipChangingReturnAddress

    ld a, $02
    ldh [$FFFE], a
    
.skipChangingReturnAddress
    xor a
    ; ...

SECTION "GBC-only screen", ROM0[$04DD]
DisplayGbcOnlyScreen::
    ; Set the bottom stack return address to $0000.
    xor a
    ldh [$FFFE], a
    
    xor a
    ld b, $7E
    ld c, $FD
.clearHramLoop
    ld [$FF00+c], a
    dec c
    dec b
    jr nz, .clearHramLoop

.waitForVBlankLoop
    ldh a, [A_Lcdc_YCoordinate]
    cp a, 144
    jr nc, .waitForVBlankLoop

    ; Turn off the LCD
    ld a, 0
    ldh [A_Lcdc_Control], a
    
    ; Clear WRAM from $C000 all the way to $E000, 256 bytes at a time
    ld c, $E0
    ld hl, $C000
    xor a
.clearWramLoop
    ldi [hl], a
    cp l
    jr nz, .clearWramLoop

    ld a, h
    cp c
    ld a, l
    jr nz, .clearWramLoop

    ; Very odd to set a bunch of already cleared memory addresses to 0 here...
    ld a, 0
    ld [$C672], a
    ld a, 0
    ld [$C673], a
    ldh [A_Lcdc_YScroll], a
    ld [$C674], a
    ldh [A_Lcdc_XScroll], a
    ld [$C675], a
    ldh [A_Lcdc_WindowYPos], a
    
    ; Shift the window completely off the screen, I suppose.
    ld a, 167
    ld [$C676], a
    ldh [A_Lcdc_WindowXPos], a

    ld a, 0
    ld [A_GfxLoadInfo_SrcAddress], a
    ld a, $40
    ld [A_GfxLoadInfo_SrcAddress + 1], a
    ld a, $5E
    ld [A_GfxLoadInfo_SrcBank], a
    ld a, $00
    ld [A_GfxLoadInfo_DestAddress], a
    ld a, $8D
    ld [A_GfxLoadInfo_DestAddress + 1], a

    call LoadJazzedUpRleData

    ;...

SECTION "Decompression routine", ROM0[$251A]
LoadJazzedUpRleData::
    ld a, [A_GfxLoadInfo_SrcAddress]
    ld l, a
    ld a, [A_GfxLoadInfo_SrcAddress + 1]
    ld h, a
    ld a, [A_GfxLoadInfo_SrcBank]
    ld [$C677], a
    ld [A_BankNumberControl], a

    ld a, [A_GfxLoadInfo_DestAddress]
    ld c, a
    ld a, [A_GfxLoadInfo_DestAddress + 1]
    ld b, a
    push bc

.iterateThroughChunks
    ldi a, [hl]
    ld e, a
    and a
    jr z, .finished

    cp a, -128
    jr c, .isPositive

    and a, $7C
    cp a, $7C
    jr z, .isBetweenNegative124AndNegative127

    jr .else

.isPositive
    call ChunkHandler_CopyRawBytes
    jr .iterateThroughChunks
.else
    call ChunkHandler_Rle
    jr .iterateThroughChunks
.isBetweenNegative124AndNegative127
    call ChunkHandler_3
    jr .iterateThroughChunks

.finished
    ld a, [A_GfxLoadInfo_DestAddress]
    ld [A_LoadedGfx_Address], a
    ld a, [A_GfxLoadInfo_DestAddress + 1]
    ld [A_LoadedGfx_Address + 1], a
    ld a, [A_GfxLoadInfo_DestBank]
    ld [A_LoadedGfx_Bank], a

    pop hl
    ld a, c
    sub l
    ld [A_LoadedGfx_Length], a
    ld a, b
    sbc h
    ld [A_LoadedGfx_Length + 1], a
    
    ret

ChunkHandler_CopyRawBytes:
    ld d, a
.copyLoop
    ldi a, [hl]
    ld [bc], a
    inc bc
    dec d
    jr nz, .copyLoop
    ret

ChunkHandler_Rle:
    ld d, a
    
    ld a, e
    and a, %00000011
    ld [A_RleChunk_RepeatsLeft + 1], a
    ldi a, [hl]
    ld [A_RleChunk_RepeatsLeft], a

    ld a, d
    srl a
    and a
    jr nz, .storeRleParameters
    
    ld a, 1

.storeRleParameters
    ld [A_RleChunk_DataLength], a
    ld a, l
    ld [A_RleChunk_DataAddress], a
    ld a, h
    ld [A_RleChunk_DataAddress + 1], a

.rleRepeatLoop
    ld a, [A_RleChunk_DataAddress]
    ld l, a
    ld a, [A_RleChunk_DataAddress + 1]
    ld h, a
    ld a, [A_RleChunk_DataLength]
    ld e, a

.copyLoop
    ldi a, [hl]
    ld [bc], a
    inc bc
    dec e
    jr nz, .copyLoop

    ld a, [A_RleChunk_RepeatsLeft]
    sub a, 1
    ld [A_RleChunk_RepeatsLeft], a
    ld a, [A_RleChunk_RepeatsLeft + 1]
    sbc a, 0
    ld [A_RleChunk_RepeatsLeft + 1], a
    
    and a
    jr nz, .rleRepeatLoop
    ld a, [A_RleChunk_RepeatsLeft]
    and a
    jr nz, .rleRepeatLoop

    ret

ChunkHandler_3:
    ld a, e
    and a, $03
    ld [$C363], a

.loopTime
    ldi a, [hl]
    ld [$C362], a
    ldi a, [hl]
    ld e, a
    ldi a, [hl]
    ld d, a
    push hl
    ld a, [A_GfxLoadInfo_DestAddress]
    ld l, a
    ld a, [A_GfxLoadInfo_DestAddress + 1]
    ld h, a
    add hl, de
    ld a, [$C363]
    ld d, a
    ld a, [$C362]
    ld e, a
    and a
    jr z, .itIsLooop
    inc d
.itIsLooop
    ldi a, [hl]
    ld [bc], a
    inc bc
    dec e
    jr nz, .itIsLooop
    dec d
    jr nz, .itIsLooop

    pop hl
    ret
