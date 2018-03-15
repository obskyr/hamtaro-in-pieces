IF !DEF(MACROS_INC)
MACROS_INC SET 1

INCLUDE "constants.inc"

; \1: Source bank
; \2: Source address
; \3: Destination address
M_Decompress: MACRO
    ld a, \2 & $FF
    ld [A_Decompression_SrcAddress], a
    ld a, (\2 >> 8) & $FF
    ld [A_Decompression_SrcAddress + 1], a
    ld a, \1
    ld [A_Decompression_SrcBank], a
    ld a, \3 & $FF
    ld [A_Decompression_DestAddress], a
    ld a, (\3 >> 8) & $FF
    ld [A_Decompression_DestAddress + 1], a
    call Decompress
ENDM

; \1: Tilemap width
; \2: Source bank
; \3: Source address
; \4: Destination address
M_DecompressTilemap: MACRO
    ld a, \3 & $FF
    ld [A_Decompression_SrcAddress], a
    ld a, (\3 >> 8) & $FF
    ld [A_Decompression_SrcAddress + 1], a
    ld a, \2
    ld [A_Decompression_SrcBank], a
    ld a, \1
    ld [A_TilemapDecompression_Width], a
    ld a, \4 & $FF
    ld [A_Decompression_DestAddress], a
    ld a, (\4 >> 8) & $FF
    ld [A_Decompression_DestAddress + 1], a
    call DecompressTilemap
ENDM

M_DecompressionLoadValues: MACRO
    ld a, [A_Decompression_SrcAddress]
    ld l, a
    ld a, [A_Decompression_SrcAddress + 1]
    ld h, a
    ld a, [A_Decompression_SrcBank]
    ld [$C677], a
    ld [A_RomBankControl], a

    ld a, [A_Decompression_DestAddress]
    ld c, a
    ld a, [A_Decompression_DestAddress + 1]
    ld b, a
    push bc
ENDM

; \1: Address of raw bytes chunk handler
; \2: Address of RLE chunk handler
; \3: Address of reference chunk handler
M_DecompressionMainBody: MACRO

.iterateThroughChunks
    ldi a, [hl]
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
    ld a, [A_Decompression_DestAddress]
    ld [A_DecompressedData_Address], a
    ld a, [A_Decompression_DestAddress + 1]
    ld [A_DecompressedData_Address + 1], a
    ld a, [A_Decompression_DestBank]
    ld [A_DecompressedData_Bank], a

    pop hl
    ld a, c
    sub l
    ld [A_DecompressedData_Length], a
    ld a, b
    sbc h
    ld [A_DecompressedData_Length + 1], a
ENDM

ENDC
