INCLUDE "system.inc"

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
