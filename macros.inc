M_Decompress: MACRO
; \1: Source address
; \2: Source bank
; \3: Destination address
    ld a, \1 & 0xFF
    ld [A_Decompression_SrcAddress], a
    ld a, (\1 >> 8) & 0xFF
    ld [A_Decompression_SrcAddress + 1], a
    ld a, \2
    ld [A_Decompression_SrcBank], a
    ld a, \3 & 0xFF
    ld [A_Decompression_DestAddress], a
    ld a, (\3 >> 8) & 0xFF
    ld [A_Decompression_DestAddress + 1], a
    call Decompress
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

M_DecompressionMainBody: MACRO
    ; \1, \2, and \3 are the handlers for the chunk types.

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

M_ChunkHandler_Rle: MACRO
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
ENDM