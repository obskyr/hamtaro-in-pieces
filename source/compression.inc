IF !DEF(COMPRESSION_INC)
COMPRESSION_INC SET 1

; \1: Source bank
; \2: Source address
; \3: Destination address
M_Decompress: MACRO
    ld a, \2 & $FF
    ld [W_Decompression_SrcAddress], a
    ld a, \2 >> 8
    ld [W_Decompression_SrcAddress + 1], a
    ld a, \1
    ld [W_Decompression_SrcBank], a
    ld a, \3 & $FF
    ld [W_Decompression_DestAddress], a
    ld a, \3 >> 8
    ld [W_Decompression_DestAddress + 1], a
    call Decompress
ENDM

; \1: Tilemap width
; \2: Source bank
; \3: Source address
; \4: Destination address
M_DecompressTilemap: MACRO
    ld a, \3 & $FF
    ld [W_Decompression_SrcAddress], a
    ld a, \3 >> 8
    ld [W_Decompression_SrcAddress + 1], a
    ld a, \2
    ld [W_Decompression_SrcBank], a
    ld a, \1
    ld [W_TilemapDecompression_Width], a
    ld a, \4 & $FF
    ld [W_Decompression_DestAddress], a
    ld a, \4 >> 8
    ld [W_Decompression_DestAddress + 1], a
    call DecompressTilemap
ENDM

ENDC
