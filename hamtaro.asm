INCLUDE "constants.inc"

SECTION "Interrupt vector $0", ROM0[$0000]
    REPT 8
    DB $FF
    ENDR

SECTION "Interrupt vector $8", ROM0[$0008]
    REPT 8
    DB $FF
    ENDR

SECTION "Interrupt vector $10", ROM0[$0010]
    REPT 8
    DB $FF
    ENDR

SECTION "Interrupt vector $18", ROM0[$0018]
    jp $2A56 ; Which is...?
    REPT 5
    DB $FF
    ENDR

SECTION "Interrupt vector $20", ROM0[$0020]
    jp $2A62 ; Which is...?
    REPT 5
    DB $FF
    ENDR

SECTION "Interrupt vector $28", ROM0[$0028]
    jp $2A77 ; Which is...?
    REPT 5
    DB $FF
    ENDR

SECTION "Interrupt vector $30", ROM0[$0030]
    REPT 8
    DB $FF
    ENDR

SECTION "Interrupt vector $38", ROM0[$0038]
Interrupt_GetStuckForever:
    REPT 8
    DB $FF
    ENDR

SECTION "V-blank interrupt", ROM0[$0040]
Interrupt_VBlank:
    jp $059A ; Call it NewFrame or whatever.
    REPT 5
    DB $FF
    ENDR

SECTION "LCD interrupt", ROM0[$0048]
Interrupt_Lcd:
    jp $085E
    REPT 5
    DB $FF
    ENDR

SECTION "Timer interrupt", ROM0[$0050]
Interrupt_Timer:
    jp $048B
    REPT 5
    DB $FF
    ENDR

SECTION "Serial interrupt", ROM0[$0058]
Interrupt_Serial:
    jp $048C
    REPT 5
    DB $FF
    ENDR

SECTION "Button interrupt", ROM0[$0060]
Interrupt_Button:
    REPT 8
    DB $FF
    ENDR

SECTION "Unused post-interrupt space", ROM0[$0068]
    REPT $100 - $68
    DB $FF
    ENDR

SECTION "Entry point", ROM0[$0100]
EntryPoint::
    nop
    jp Start

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

    ld a, 0
    ld [$C356], a
    ld a, $40
    ld [$C357], a
    ld a, $5E
    ld [$C358], a
    ld a, $00
    ld [$C35A], a
    ld a, $8D
    ld [$C35B], a

    call $251A

    ;...

SECTION "No idea what this is yet", ROM0[$251A]
SomethingIGuess::
    ld a, [$C356]
    ld l, a
    ld a, [$C357]
    ld h, a
    ld a, [$C358]
    ld [$C677], a
    ld [$2000], a

    ld a, [$C35A]
    ld c, a
    ld a, [$C35B]
    ld b, a
    push bc

.someSortaLoop
    ldi a, [hl]
    ld e, a
    and a
    jr z, .outtaTheLoop
    cp a, $80
    jr c, .option1
    and a, $7C
    cp a, $7C
    jr z, .option3
    jr .option2

.option1
    call $2572
    jr .someSortaLoop
.option2
    call $257A
    jr .someSortaLoop
.option3
    call $25C4
    jr .someSortaLoop

.outtaTheLoop
    ld a, [$C35A]
    ld [$C356], a
    ld a, [$C35B]
    ld [$C357], a

    ld a, [$C35C]
    ld [$C358], a

    pop hl
    ld a, c
    sub l
    ld [$C35A], a
    ld a, b
    sbc h
    ld [$C35B], a
    
    ret

