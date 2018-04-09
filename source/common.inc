IF !DEF(COMMON_INC)
COMMON_INC SET 1

A_Interrupt_CrossBankJump EQU $18
A_Interrupt_CrossBankCall EQU $20

; \1: Bank of code to call
; \2: Address of code to call
M_CrossBankCall: MACRO
    rst A_Interrupt_CrossBankCall
    DW \2
    DB \1
ENDM

; \1: Bank of code to jump to
; \2: Address of code to jump to
M_CrossBankJump: MACRO
    rst A_Interrupt_CrossBankJump
    DW \2
    DB \1
ENDM

M_ResetMapPositions: MACRO
    ; Interesting that they used `ld a, 0` here and not `xor a`.
    ld a, 0
    ld [W_Display_LcdcControl], a

    ; Reset the background scroll to 0, 0.
    ld a, 0
    ld [W_Display_YScroll], a
    ldh [A_Lcdc_YScroll], a
    ld [W_Display_XScroll], a
    ldh [A_Lcdc_XScroll], a

    ; Shift the window horizontally completely off the screen.
    ld [W_Display_WindowYPos], a
    ldh [A_Lcdc_WindowYPos], a
    ld a, 167
    ld [W_Display_WindowXPos], a
    ldh [A_Lcdc_WindowXPos], a
ENDM

ENDC
