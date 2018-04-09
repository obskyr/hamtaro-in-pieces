INCLUDE "system.inc"

SECTION "Info on the current display settings", WRAM0[$C672]
A_CurDisplay_LcdcControl:: DB
A_CurDisplay_YScroll::     DB
A_CurDisplay_XScroll::     DB
A_CurDisplay_WindowYPos::  DB
A_CurDisplay_WindowXPos::  DB

SECTION "Active palette data", WRAMX[$DD9A], BANK[$01]
A_BgPaletteData::
REPT 32
    DW
ENDR
A_SpritePaletteData::
REPT 32
    DW
ENDR

SECTION "Function to set palettes from WRAM", ROM0[$078F]
SetPalettes::
    ldh a, [A_WramBankControl]
    push af

    ld a, $01
    ldh [A_WramBankControl], a
    ld hl, A_BgPaletteData

    ld a, M_Palette_AutoIncrement | $00
    ldh [A_Palette_Bg_Index], a

    ld b, 64
.copyBgPaletteLoop
    ld a, [hl+]
    ldh [A_Palette_Bg_Data], a
    dec b
    jr nz, .copyBgPaletteLoop

    ld hl, A_SpritePaletteData

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
