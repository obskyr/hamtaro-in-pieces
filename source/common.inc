IF !DEF(COMMON_INC)
COMMON_INC SET 1

A_Interrupt_CrossBankJump   EQU $18
A_Interrupt_CrossBankCall   EQU $20

; \1: Bank of code to call
; \2: Address of code to call
M_CrossBankCall: MACRO
    rst A_Interrupt_CrossBankCall
    DW \2
    DB \1
ENDM

; \1: Bank of code to jump to
; \2: Address of code to jump to
M_CrossBankJump: mACRO
    rst A_Interrupt_CrossBankJump
    DW \2
    DB \1
ENDM

ENDC
