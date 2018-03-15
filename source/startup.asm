INCLUDE "system.inc"
INCLUDE "compression.inc"

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
