IF !DEF(COMMON_INC)
COMMON_INC SET 1

; \1: Bank of code to call
; \2: Address of code to call
M_CrossBankCall: MACRO
    rst $20
    DW \2
    DB \1
ENDM

ENDC
