INCLUDE "system.inc"
INCLUDE "common.inc"

M_Signature EQUS "\"HAMTARO2 Paxsoftnica. 2000/11/21\""

; \1: Address to bank control register
; \2: Bank to clear up to
; \3: Address to start clearing at
; \4: Address switchable banks start at
; \5: Address to stop clearing at (rounded down to nearest multiple of 0x100)
M_ClearBanks: MACRO
    ld b, \2
    ld c, \5 >> 8
    ld hl, \3

.switchAndClearBankLoop\@
    ld a, b
    ldh [\1], a

    xor a
.clearBankLoop\@
    ld [hl+], a
    cp l
    jr nz, .clearBankLoop\@
    
    ld a, h
    cp c
    ld a, l
    jr nz, .clearBankLoop\@

    dec b
    ld hl, \4
    jr nz, .switchAndClearBankLoop\@
ENDM

SECTION "Signature", ROMX[$579F], BANK[$04]
Signature::
    DB M_Signature

SECTION "Start", ROM0[$0254]
Start::
    cp a, M_MagicIsGbc
    ld sp, $FFFD
    jp nz, DisplayGbcOnlyScreen

    ; Sets the bottom stack return address to the entry point.
    ld a, EntryPoint >> 8
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

    M_ClearBanks A_WramBankControl, $07, $C000, $D000, $E000

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

    M_ClearBanks A_VramBankControl, $01, $8000, $8000, $A000

    ; Time to check that the save isn't nonexistent or garbage.
    xor a
    ld [A_Mbc5_RamBankControl], a
    M_Mbc5_EnableExternalRam

    ld a, BANK(Signature)
    ld [A_Mbc5_RomBankControl], a

    ld hl, Signature
    ld de, $A000
    ld c, STRLEN(M_Signature)
.compareSaveSignatureLoop
    ld a, [de]
    cp [hl]
    jr nz, .signatureDoesNotMatch
    inc hl
    inc de
    dec c
    jr nz, .compareSaveSignatureLoop

    M_Mbc5_DisableExternalRam

    jr .saveSignatureIsValid

.signatureDoesNotMatch
    ; If there isn't a valid signature in the beginning of the save,
    ; it's either blank or corrupted, so it's cleared out and reinitialized.
    xor a
    ld hl, $A000
    ld bc, $2000

.clearSaveLoop
    ld [hl+], a
    dec c
    jr nz, .clearSaveLoop

    dec b
    jr nz, .clearSaveLoop

    ; Gotta disassemble these.
    M_CrossBankCall $00, $3889
    M_CrossBankCall $03, $5D63
    M_CrossBankCall $03, $5D63

    ld a, BANK(Signature)
    ld [A_Mbc5_RomBankControl], a
    ld hl, Signature
    ld de, $A000
    ld c, STRLEN(M_Signature)
    
    xor a
    ld [A_Mbc5_RamBankControl], a
    M_Mbc5_EnableExternalRam

.copySignatureLoop
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .copySignatureLoop

    M_Mbc5_DisableExternalRam

.saveSignatureIsValid
    ; ...

SECTION "Bank-related interrupt functions", ROM0[$2A47]
SwitchBank::
    push af
    di

    ld [A_CurrentRomBank], a
    ld [A_Mbc5_RomBankControl], a
    xor a
    ld [A_Mbc5_RamBankControl_HighBit], a
    
    ei
    pop af
    ret

CrossBankJump::
    pop hl

    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    ld a, [hl+]
    call SwitchBank
    
    ld l, e
    ld h, d
    jp hl

; This might need to be renamed, based on how it's used later.
; It doesn't actually switch the bank *back* after calling,
; but rather leaves that to the destination function if at all.
;
; Arguments for this comes in the form of data after the rst/call:
; DW address of code to call
; DB bank of code to call
CrossBankCall::
    pop hl

    ld a, [A_CurrentRomBank]
    ld e, a
    ld a, 0
    ld d, a
    push de

    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    ld a, [hl+]
    push hl
    call SwitchBank

    ld l, e
    ld h, d
    jp hl

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
