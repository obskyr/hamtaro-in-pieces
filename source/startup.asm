INCLUDE "system.inc"
INCLUDE "common.inc"

M_Signature EQUS "\"HAMTARO2 Paxsoftnica. 2000/11/21\""

SECTION "Signature", ROMX[$579F], BANK[$04]
Signature::
    DB M_Signature

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
    ldh [A_Buttons], a

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
    ld a, $00
    ldh [A_WramBankControl], a
    ld a, BANK(JumpToInitSoundStructures)
    ld [A_CurrentRomBank], a
    ld [A_Mbc5_RomBankControl], a

    call JumpToInitSoundStructures

    ; ...

SECTION "Stepping stone to initializing sound-related WRAM", ROMX[$4000], BANK[$07]
JumpToInitSoundStructures::
    jp InitSoundStructures

SECTION "Function for initializing sound-related WRAM", ROMX[$5F82], BANK[$07]
; This seems to fill out a lot of sound-related WRAM values.
; Miiiight be other WRAM too, but there's no telling yet.
; All of this needs to be filled in later as we see how it's used.
InitSoundStructures:: ; Tentative name.
    xor a
    ld [A_Sound_On], a
    ld a, M_Sound_On
    ld [A_Sound_On], a
    
    ld a, M_Sound_BothFullVolume
    ld [A_Sound_OutputControl], a
    ; I suppose these are WRAM structures with
    ; info about current sound settings. 
    ld [$CF14], a
    ld [$CF1B], a

    ld a, M_Sound_AllChannelsToBoth
    ld [A_Sound_ChannelOutputs], a

    ; Ah, yes. The classic "turn on sound and then immediately
    ; turn off all sound" move. These have got to be macros.
    xor a
    ld [A_Sound_ChannelOutputs], a
    ld [$CF15], a
    ld [$CF1C], a
    ld [A_Sound_Ch3_On], a
    ld [A_Sound_Ch3_Volume], a

    xor a
    ld [$CEE9], a
    ld [$CF04], a

    ld a, $20
    ld [$CFFD], a
    ld a, $80
    ld [$CFFC], a

    xor a
    ld [$CF05], a
    ld [$CF06], a

    ld hl, $43DD
    ld a, l
    ld [$CF12], a
    ld a, h
    ld [$CF13], a
    ld a, $80
    ld [$CE4B], a
    ld a, $FF
    ld [$CF1C], a

    xor a

Addr = $CEDC
REPT 12
    ld [Addr], a
Addr = Addr + 1
ENDR

Addr = $CF0A
REPT 8
    ld [Addr], a
Addr = Addr + 1
ENDR

    ld [$CFFA], a
    ld [$CF20], a

    xor a
    ld [$CF00], a
    
    ld a, $66
    ld [$CFFF], a
    
    ret
