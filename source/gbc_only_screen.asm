INCLUDE "system.inc"
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

    ; Very odd to set a bunch of already cleared memory addresses to 0 here...
    ; Might be a macro or two to set the position of the maps.
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

    M_Decompress $5E, $4000, $8D00
    M_Decompress $5E, $41DE, $9000
    M_DecompressTilemap $14, $5E, $4808, $9800

    ; Black, dark gray, light gray, white.
    ld a, $E4
    ldh [A_Lcdc_GbMapPalette], a
    ld a, M_Lcdc_Enabled | \
          M_Lcdc_WindowUsesSecondTilemap | \
          M_Lcdc_TallSprites | \
          M_Lcdc_BgOn
    ld [$C672], a
    ldh [A_Lcdc_Control], a

.doNothingForever
    nop
    nop
    nop
    jr .doNothingForever
