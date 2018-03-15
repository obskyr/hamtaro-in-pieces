IF !DEF(SYSTEM_INC)
SYSTEM_INC SET 1

M_MagicIsGbc EQU $11 ; Also GBA.

A_RomBankControl  EQU $2000
A_WramBankControl EQU $FF70

A_Lcdc_Control     EQU $FF40
A_Lcdc_YScroll     EQU $FF42
A_Lcdc_XScroll     EQU $FF43
A_Lcdc_YCoordinate EQU $FF44
A_Lcdc_WindowYPos  EQU $FF4A
A_Lcdc_WindowXPos  EQU $FF4B

ENDC
