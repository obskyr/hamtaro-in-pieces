INCLUDE "system.inc"

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
    ld b, $7E
    ld c, $FD
.clearHramLoop
    ld [$FF00+c], a
    dec c
    dec b
    jr nz, .clearHramLoop

    di
    xor a
    ldh [A_IrPortControl], a
    ldh [A_WramBankControl], a
    ldh [A_VramBankControl], a

.waitForVBlankLoop
    ldh a, [A_Lcdc_CurrentY]
    cp a, 144
    jr nc, .waitForVBlankLoop

    M_Lcdc_SetControl 0

    ; If the CPU is already in double-speed mode, setup has already been done.
    ldh a, [A_CpuSpeed]
    bit 7, a
    jr nz, .setupComplete

    set 0, a
    ldh [A_CpuSpeed], a
    
    xor a
    ldh [A_InterruptControl], a
    ldh [A_InterruptFlags], a

    ld a, M_Buttons_NoneSelected
    ld [A_Buttons], a

    stop ; The requested CPU speed is activated using a stop.

.waitForCpuSpeedSwitch
    ldh a, [A_CpuSpeed]
    bit 7, a
    jr z, .waitForCpuSpeedSwitch

    xor a
    ldh [A_Buttons], a
    ldh [A_InterruptControl], a
    ldh [A_InterruptFlags], a

.setupComplete
    di
    ld sp, $FFFD

    ; Banks 0-7 (inclusive) are cleared.
    ld b, $07
    ld c, $E0
    ld hl, $C000

.switchAndClearWramBankLoop
    ld a, b
    ldh [A_WramBankControl], a

    xor a
.clearWramBankLoop
    ld [hl+], a
    cp l
    jr nz, .clearWramBankLoop
    
    ld a, h
    cp c
    ld a, l
    jr nz, .clearWramBankLoop

    dec b
    ld hl, $D000
    jr nz, .switchAndClearWramBankLoop

    ld a, $01
    ldh [A_WramBankControl], a
    ld hl, A_BgPaletteData + 64 + 64 - 1
    
    ld c, 64 + 64
    ld a, $FF
.clearPaletteLoop
    ld [hl-], a
    dec c
    jr nz, .clearPaletteLoop

    call SetPalettes

    ; ...

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
    ld [A_WramBankControl], a
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
