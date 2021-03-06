INCLUDE "system.inc"
INCLUDE "common.inc"
INCLUDE "compression.inc"

SECTION "Decompression routine in/out WRAM", WRAM0[$C356]
W_Decompression_SrcAddress::
W_DecompressedData_Address:: DW
W_Decompression_SrcBank::
W_DecompressedData_Bank::    DW
W_Decompression_DestAddress::
W_DecompressedData_Length::  DW
W_Decompression_DestBank::   DW

SECTION "Decompression routine internal WRAM", WRAM0[$C360]
W_RleChunk_DataLength::      DW
W_RleChunk_RepeatsLeft::
W_ReferenceChunk_BytesLeft:: DW
W_RleChunk_DataAddress::     DW

SECTION "Tilemap decompression routine WRAM", WRAM0[$C36A]
W_TilemapDecompression_Width::                   DW
W_TilemapDecompression_TilesLeftInRow::          DB
W_TilemapDecompression_TilesLeftInReferenceRow:: DB
W_TilemapDecompression_TilesToSkip::             DW

SECTION "Decompression routines", ROM0[$251A]
; The compression in Hamtaro: HHU! is a mishmash of a few different approaches.
;
; The data is organized in chunks, which can be any one of 3 different types:
; * Up to 127 raw bytes.
; * Run length encoded bytes.
; * A reference to earlier data.
;
; That last one isn't quite LZ77, as it uses absolute addresses from the start
; of the data as opposed to a sliding window (although it *could* also be seen
; as LZ77 with a window size as large as the Game Boy's address space).

M_DecompressionLoadValues: MACRO
    ld a, [W_Decompression_SrcAddress]
    ld l, a
    ld a, [W_Decompression_SrcAddress + 1]
    ld h, a
    ld a, [W_Decompression_SrcBank]
    ld [W_CurrentRomBank], a
    ld [A_Mbc5_RomBankControl], a

    ld a, [W_Decompression_DestAddress]
    ld c, a
    ld a, [W_Decompression_DestAddress + 1]
    ld b, a
    push bc
ENDM

; \1: Address of raw bytes chunk handler
; \2: Address of RLE chunk handler
; \3: Address of reference chunk handler
M_DecompressionMainBody: MACRO
.iterateThroughChunks
    ld a, [hl+]
    ld e, a
    and a
    jr z, .finished

    cp a, 128
    jr c, .isPositive

    and a, $7C
    cp a, $7C
    jr z, .isBetweenFCAndFE

    jr .else

.isPositive
    call \1
    jr .iterateThroughChunks
.else
    call \2
    jr .iterateThroughChunks
.isBetweenFCAndFE
    call \3
    jr .iterateThroughChunks

.finished
    ld a, [W_Decompression_DestAddress]
    ld [W_DecompressedData_Address], a
    ld a, [W_Decompression_DestAddress + 1]
    ld [W_DecompressedData_Address + 1], a
    ld a, [W_Decompression_DestBank]
    ld [W_DecompressedData_Bank], a

    pop hl
    ld a, c
    sub l
    ld [W_DecompressedData_Length], a
    ld a, b
    sbc h
    ld [W_DecompressedData_Length + 1], a
ENDM

Decompress::
    M_DecompressionLoadValues
    M_DecompressionMainBody Decompress_HandleChunk_CopyRawBytes, \
                            Decompress_HandleChunk_Rle, \
                            Decompress_HandleChunk_Reference
    ret

Decompress_HandleChunk_CopyRawBytes::
    ld d, a
.copyLoop
    ld a, [hl+]
    ld [bc], a
    inc bc
    dec d
    jr nz, .copyLoop
    ret

Decompress_HandleChunk_Rle::
    ld d, a
     
    ld a, e
    and a, %00000011
    ld [W_RleChunk_RepeatsLeft + 1], a
    ld a, [hl+]
    ld [W_RleChunk_RepeatsLeft], a

    ld a, d
    srl a
    and a
    jr nz, .storeRleParameters
    
    ld a, 1

.storeRleParameters
    ld [W_RleChunk_DataLength], a
    ld a, l
    ld [W_RleChunk_DataAddress], a
    ld a, h
    ld [W_RleChunk_DataAddress + 1], a

.rleRepeatLoop
    ld a, [W_RleChunk_DataAddress]
    ld l, a
    ld a, [W_RleChunk_DataAddress + 1]
    ld h, a
    ld a, [W_RleChunk_DataLength]
    ld e, a

.copyLoop
    ld a, [hl+]
    ld [bc], a
    inc bc
    dec e
    jr nz, .copyLoop

    ld a, [W_RleChunk_RepeatsLeft]
    sub a, 1
    ld [W_RleChunk_RepeatsLeft], a
    ld a, [W_RleChunk_RepeatsLeft + 1]
    sbc a, 0
    ld [W_RleChunk_RepeatsLeft + 1], a
    
    and a
    jr nz, .rleRepeatLoop
    ld a, [W_RleChunk_RepeatsLeft]
    and a
    jr nz, .rleRepeatLoop

    ret

Decompress_HandleChunk_Reference::
    ld a, e
    and a, %00000011
    ld [W_ReferenceChunk_BytesLeft + 1], a
    ld a, [hl+]
    ld [W_ReferenceChunk_BytesLeft], a

    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    push hl

    ld a, [W_Decompression_DestAddress]
    ld l, a
    ld a, [W_Decompression_DestAddress + 1]
    ld h, a
    add hl, de

    ld a, [W_ReferenceChunk_BytesLeft + 1]
    ld d, a
    ld a, [W_ReferenceChunk_BytesLeft]
    ld e, a
    and a
    jr z, .copyLoop

    ; As long as e isn't 0, d needs to be incremented as it'll otherwise
    ; underflow to 0xFF and copy a superfluous 0x100 bytes.
    inc d

.copyLoop
    ld a, [hl+]
    ld [bc], a
    inc bc
    dec e
    jr nz, .copyLoop
    dec d
    jr nz, .copyLoop

    pop hl
    ret

; The difference between Decompress and DecompressTilemap is that
; DecompressTilemap supports skipping the destination address forward
; when the end of a row of tiles is reached, so that tilemaps may be
; less wide than 32 tiles and not waste CPU time.
DecompressTilemap::
    ld a, [W_TilemapDecompression_Width]
    ld l, a
    ld a, $20
    sub l
    ld [W_TilemapDecompression_TilesToSkip], a

    M_DecompressionLoadValues

    ld a, [W_Decompression_DestBank]
    ldh [A_WramBankControl], a
    ld a, [W_TilemapDecompression_Width]
    ld [W_TilemapDecompression_TilesLeftInRow], a

    M_DecompressionMainBody DecompressTilemap_HandleChunk_CopyRawBytes, \
                            DecompressTilemap_HandleChunk_Rle, \
                            DecompressTilemap_HandleChunk_Reference

    ret

DecompressTilemap_HandleChunk_CopyRawBytes::
    ld d, a

    ld a, [W_TilemapDecompression_TilesLeftInRow]
    ld e, a

.copyLoop
    ld a, [hl+]
    ld [bc], a
    dec e
    jr nz, .skipSkippingForward

    ld a, [W_TilemapDecompression_TilesToSkip]
    add a, c
    ld c, a
    ld a, b
    adc a, 0
    ld b, a
    ld a, [W_TilemapDecompression_Width]
    ld e, a

.skipSkippingForward
    inc bc
    dec d
    jr nz, .copyLoop

    ld a, e
    ld [W_TilemapDecompression_TilesLeftInRow], a

    ret

DecompressTilemap_HandleChunk_Rle::
    ld d, a
    
    ld a, e
    and a, %00000011
    ld [W_RleChunk_RepeatsLeft + 1], a
    ld a, [hl+]
    ld [W_RleChunk_RepeatsLeft], a

    ld a, d
    srl a
    and a
    jr nz, .storeRleParameters
    
    ld a, 1

.storeRleParameters
    ld [W_RleChunk_DataLength], a
    ld a, l
    ld [W_RleChunk_DataAddress], a
    ld a, h
    ld [W_RleChunk_DataAddress + 1], a
    ld a, [W_TilemapDecompression_TilesLeftInRow]
    ld d, a

.rleRepeatLoop
    ld a, [W_RleChunk_DataAddress]
    ld l, a
    ld a, [W_RleChunk_DataAddress + 1]
    ld h, a
    ld a, [W_RleChunk_DataLength]
    ld e, a

.copyLoop
    ld a, [hl+]
    ld [bc], a
    dec d
    jr nz, .skipSkippingForward

    ld a, [W_TilemapDecompression_TilesToSkip]
    add a, c
    ld c, a
    ld a, b
    adc a, 0
    ld b, a
    ld a, [W_TilemapDecompression_Width]
    ld d, a

.skipSkippingForward
    inc bc
    dec e
    jr nz, .copyLoop

    ld a, [W_RleChunk_RepeatsLeft]
    sub a, 1
    ld [W_RleChunk_RepeatsLeft], a
    ld a, [W_RleChunk_RepeatsLeft + 1]
    sbc a, 0
    ld [W_RleChunk_RepeatsLeft + 1], a

    and a
    jr nz, .rleRepeatLoop
    ld a, [W_RleChunk_RepeatsLeft]
    and a
    jr nz, .rleRepeatLoop

    ld a, d
    ld [W_TilemapDecompression_TilesLeftInRow], a
    
    ret

DecompressTilemap_HandleChunk_Reference::
    ld a, e
    and a, %00000011
    ld [W_ReferenceChunk_BytesLeft + 1], a
    ld a, [hl+]
    ld [W_ReferenceChunk_BytesLeft], a

    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    push hl
    push bc

    ld a, [W_Decompression_DestAddress]
    ld l, a
    ld a, [W_Decompression_DestAddress + 1]
    ld h, a
    ld a, [W_TilemapDecompression_Width]
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
    ld a, [W_TilemapDecompression_Width]
    sub e
    ld [W_TilemapDecompression_TilesLeftInReferenceRow], a
    pop bc
    ld a, [W_ReferenceChunk_BytesLeft]
    ld e, a
    ld a, [W_ReferenceChunk_BytesLeft + 1]
    inc a
    ld d, a

.copyLoop
    ld a, [hl]
    ld [bc], a

    ld a, [W_TilemapDecompression_TilesLeftInRow]
    dec a
    jr nz, .skipSkippingDestinationForward

    ld a, [W_TilemapDecompression_TilesToSkip]
    add a, c
    ld c, a
    ld a, b
    adc a, 0
    ld b, a
    ld a, [W_TilemapDecompression_Width]

.skipSkippingDestinationForward
    ld [W_TilemapDecompression_TilesLeftInRow], a
    inc bc

    ld a, [W_TilemapDecompression_TilesLeftInReferenceRow]
    dec a
    jr nz, .skipSkippingReferenceForward

    ld a, [W_TilemapDecompression_TilesToSkip]
    add a, l
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    ld a, [W_TilemapDecompression_Width]

.skipSkippingReferenceForward
    ld [W_TilemapDecompression_TilesLeftInReferenceRow], a
    inc hl
    
    dec e
    jr nz, .copyLoop
    dec d
    jr nz, .copyLoop

    pop hl
    ret
