INCLUDE "constants.inc"
INCLUDE "macros.inc"

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

    ld a, $00
    ld [A_Decompression_SrcAddress], a
    ld a, $40
    ld [A_Decompression_SrcAddress + 1], a
    ld a, $5E
    ld [A_Decompression_SrcBank], a
    ld a, $00
    ld [A_Decompression_DestAddress], a
    ld a, $8D
    ld [A_Decompression_DestAddress + 1], a
    call Decompress

    ld a, $DE
    ld [A_Decompression_SrcAddress], a
    ld a, $41
    ld [A_Decompression_SrcAddress + 1], a
    ld a, $5E
    ld [A_Decompression_SrcBank], a
    ld a, $00
    ld [A_Decompression_DestAddress], a
    ld a, $90
    ld [A_Decompression_DestAddress + 1], a
    call Decompress

    ld a, $08
    ld [A_Decompression_SrcAddress], a
    ld a, $48
    ld [A_Decompression_SrcAddress + 1], a
    ld a, $5E
    ld [A_Decompression_SrcBank], a
    ld a, $14
    ld [A_TilemapDecompression_Width], a
    ld a, $00
    ld [A_Decompression_DestAddress], a
    ld a, $98
    ld [A_Decompression_DestAddress + 1], a
    call DecompressTilemap

SECTION "Decompression routine", ROM0[$251A]
; Decompression in Hamtaro: HHU! is  a mish-mash of a few different approaches.
;
; The data is organized in chunks, which can be any one of 3 different types:
; * Up to 127 raw bytes.
; * Run length encoded bytes.
; * A reference to earlier data.
;
; That last one isn't quite LZ77, as it uses absolute addresses from the start
; of the data as opposed to a sliding window (although it *could* also be seen
; as LZ77 with a window size as large as the Game Boy's address space).
Decompress::
    M_DecompressionLoadValues
    M_DecompressionMainBody Decompress_ChunkHandler_CopyRawBytes, Decompress_ChunkHandler_Rle, Decompress_ChunkHandler_Reference
    ret

Decompress_ChunkHandler_CopyRawBytes:
    ld d, a
.copyLoop
    ldi a, [hl]
    ld [bc], a
    inc bc
    dec d
    jr nz, .copyLoop
    ret

Decompress_ChunkHandler_Rle:
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

Decompress_ChunkHandler_Reference:
    ld a, e
    and a, %00000011
    ld [A_ReferenceChunk_BytesLeft + 1], a
    ldi a, [hl]
    ld [A_ReferenceChunk_BytesLeft], a

    ldi a, [hl]
    ld e, a
    ldi a, [hl]
    ld d, a
    push hl

    ld a, [A_Decompression_DestAddress]
    ld l, a
    ld a, [A_Decompression_DestAddress + 1]
    ld h, a
    add hl, de

    ld a, [A_ReferenceChunk_BytesLeft + 1]
    ld d, a
    ld a, [A_ReferenceChunk_BytesLeft]
    ld e, a
    and a
    jr z, .copyLoop

    ; As long as e isn't 0, d needs to be incremented as it'll otherwise
    ; underflow to 0xFF and copy a superfluous 0x100 bytes.
    inc d

.copyLoop
    ldi a, [hl]
    ld [bc], a
    inc bc
    dec e
    jr nz, .copyLoop
    dec d
    jr nz, .copyLoop

    pop hl
    ret

DecompressTilemap::
    ; The difference between Decompress and DecompressTilemap is that
    ; DecompressTilemap supports skipping the destination address forward
    ; when the end of a row of tiles is reached, so that tilemaps may be
    ; less wide than 32 tiles and not waste CPU time.
    ld a, [A_TilemapDecompression_Width]
    ld l, a
    ld a, $20
    sub l
    ld [A_TilemapDecompression_TilesToSkip], a

    M_DecompressionLoadValues

    ld a, [A_Decompression_DestBank]
    ldh [A_WramBankControl], a
    ld a, [A_TilemapDecompression_Width]
    ld [A_TilemapDecompression_TilesLeftInRow], a

    M_DecompressionMainBody DecompressTilemap_ChunkHandler_CopyRawBytes, $2680, $26E2

    ret

DecompressTilemap_ChunkHandler_CopyRawBytes:
    ld d, a

    ld a, [A_TilemapDecompression_TilesLeftInRow]
    ld e, a

.copyLoop
    ldi a, [hl]
    ld [bc], a
    dec e
    jr nz, .skipSkippingForward

    ld a, [A_TilemapDecompression_TilesToSkip]
    add a, c
    ld c, a
    ld a, b
    adc a, 0
    ld b, a
    ld a, [A_TilemapDecompression_Width]
    ld e, a

.skipSkippingForward
    inc bc
    dec d
    jr nz, .copyLoop

    ld a, e
    ld [A_TilemapDecompression_TilesLeftInRow], a

    ret

DecompressTilemap_ChunkHandler_Rle:
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
    ld a, [$C36C]
    ld d, a

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
    dec d
    jr nz, .skipSkippingForward

    ld a, [A_TilemapDecompression_TilesToSkip]
    add a, c
    ld c, a
    ld a, b
    adc a, 0
    ld b, a
    ld a, [A_TilemapDecompression_Width]
    ld d, a

.skipSkippingForward
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

    ld a, d
    ld [A_TilemapDecompression_TilesLeftInRow], a
    
    ret

DecompressTilemap_ChunkHandler_Reference:
    ld a, e
    and a, %00000011
    ld [A_ReferenceChunk_BytesLeft + 1], a
    ldi a, [hl]
    ld [A_ReferenceChunk_BytesLeft], a

    ldi a, [hl]
    ld e, a
    ldi a, [hl]
    ld d, a
    push hl
    push bc

    ld a, [A_Decompression_DestAddress]
    ld l, a
    ld a, [A_Decompression_DestAddress + 1]
    ld h, a
    ld a, [A_TilemapDecompression_Width]
    ld c, a

.skipRowsLoop
    ; Since the tilemap was compressed without the blank tiles at the end
    ; of the rows, for every [width] tiles in the offset, HL needs to skip
    ; forward $20 tiles to actually get to the next row.
    push de
    ld a, e
    sub c
    ld e, a
    ld a, d
    sbc a, 0
    ld d, a
    jr c, .doneResolvingAddress

    ld a, l
    add a, $20
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    pop af
    jr .skipRowsLoop

.doneResolvingAddress
    pop de
    add hl, de
    ld a, [A_TilemapDecompression_Width]
    sub e
    ld [A_TilemapDecompression_TilesLeftInReferenceRow], a
    pop bc
    ld a, [A_ReferenceChunk_BytesLeft]
    ld e, a
    ld a, [A_ReferenceChunk_BytesLeft + 1]
    inc a
    ld d, a

.copyLoop
    ld a, [hl]
    ld [bc], a

    ld a, [A_TilemapDecompression_TilesLeftInRow]
    dec a
    jr nz, .skipSkippingDestinationForward

    ld a, [A_TilemapDecompression_TilesToSkip]
    add a, c
    ld c, a
    ld a, b
    adc a, 0
    ld b, a
    ld a, [A_TilemapDecompression_Width]

.skipSkippingDestinationForward
    ld [A_TilemapDecompression_TilesLeftInRow], a
    inc bc

    ld a, [A_TilemapDecompression_TilesLeftInReferenceRow]
    dec a
    jr nz, .skipSkippingReferenceForward

    ld a, [A_TilemapDecompression_TilesToSkip]
    add a, l
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    ld a, [A_TilemapDecompression_Width]

.skipSkippingReferenceForward
    ld [A_TilemapDecompression_TilesLeftInReferenceRow], a
    inc hl
    
    dec e
    jr nz, .copyLoop
    dec d
    jr nz, .copyLoop

    pop hl
    ret
