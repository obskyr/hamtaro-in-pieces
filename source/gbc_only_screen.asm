INCLUDE "system.inc"
INCLUDE "common.inc"
INCLUDE "compression.inc"

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
    ldh a, [A_Lcdc_CurrentY]
    cp a, 144
    jr nc, .waitForVBlankLoop

    M_Lcdc_SetControl 0

    ; Clear WRAM from $C000 all the way to $E000, 256 bytes at a time
    ld c, $E0
    ld hl, $C000
    xor a
.clearWramBankLoop
    ldi [hl], a
    cp l
    jr nz, .clearWramBankLoop

    ld a, h
    cp c
    ld a, l
    jr nz, .clearWramBankLoop

    M_ResetMapPositions

    M_Decompress $5E, $4000, $8D00
    M_Decompress $5E, $41DE, $9000
    M_DecompressTilemap $14, $5E, $4808, $9800

    ; Black, dark gray, light gray, white.
    ld a, (3 << 6) | (2 << 4) | (1 << 2) | 0
    ldh [A_Lcdc_GbMapPalette], a
    ld a, M_Lcdc_Enabled | \
          M_Lcdc_WindowUsesSecondTilemap | \
          M_Lcdc_TallSprites | \
          M_Lcdc_BgOn
    ld [W_Display_LcdcControl], a
    ldh [A_Lcdc_Control], a

.doNothingForever
    nop
    nop
    nop
    jr .doNothingForever
