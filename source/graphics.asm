INCLUDE "system.inc"

SECTION "Info on the current display settings", WRAM0[$C672]
W_Display_LcdcControl:: DB
W_Display_YScroll::     DB
W_Display_XScroll::     DB
W_Display_WindowYPos::  DB
W_Display_WindowXPos::  DB

SECTION "Active palette data", WRAMX[$DD9A], BANK[$01]
W_BgPaletteData::
REPT 32
    DW
ENDR
W_SpritePaletteData::
REPT 32
    DW
ENDR

SECTION "Function to set palettes from WRAM", ROM0[$078F]
SetPalettes::
    ldh a, [A_WramBankControl]
    push af

    ld a, $01
    ldh [A_WramBankControl], a
    ld hl, W_BgPaletteData

    ld a, M_Palette_AutoIncrement | $00
    ldh [A_Palette_Bg_Index], a

    ld b, 64
.copyBgPaletteLoop
    ld a, [hl+]
    ldh [A_Palette_Bg_Data], a
    dec b
    jr nz, .copyBgPaletteLoop

    ld hl, W_SpritePaletteData

    ld a, M_Palette_AutoIncrement | $00
    ldh [A_Palette_Sprite_Index], a

    ld b, 64
.copySpritePaletteLoop
    ld a, [hl+]
    ldh [A_Palette_Sprite_Data], a
    dec b
    jr nz, .copySpritePaletteLoop

    pop af
    ldh [A_WramBankControl], a
    ret
    ret ; Don't ask me!
