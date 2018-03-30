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

SECTION "Interrupt vector $18: cross-bank jump", ROM0[$0018]
Interrupt_CrossBankJump::
    jp CrossBankJump
    REPT 5
    DB $FF
    ENDR

SECTION "Interrupt vector $20: cross-bank call", ROM0[$0020]
Interrupt_CrossBankCall::
    jp CrossBankCall
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
    ; Fun fact: all the unused `rst`s lead here, because 0xFF happens
    ; to be `rst $38`. This interrupt is therefore an infinite recursive
    ; loop that overwrites all RAM via the stack.
    REPT 8
    DB $FF
    ENDR

SECTION "V-blank interrupt", ROM0[$0040]
Interrupt_VBlank::
    jp $059A ; Call it NewFrame or whatever.
    REPT 5
    DB $FF
    ENDR

SECTION "LCD interrupt", ROM0[$0048]
Interrupt_Lcd::
    jp $085E
    REPT 5
    DB $FF
    ENDR

SECTION "Timer interrupt", ROM0[$0050]
Interrupt_Timer::
    jp $048B
    REPT 5
    DB $FF
    ENDR

SECTION "Serial interrupt", ROM0[$0058]
Interrupt_Serial::
    jp $048C
    REPT 5
    DB $FF
    ENDR

SECTION "Button interrupt", ROM0[$0060]
Interrupt_Button::
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
