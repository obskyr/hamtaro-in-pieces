IF !DEF(SYSTEM_INC)
SYSTEM_INC SET 1

M_MagicIsGbc EQU $11 ; Also GBA.

A_RomBankControl  EQU $2000
A_VramBankControl EQU $FF4F
A_WramBankControl EQU $FF70

M_Buttons_NoneSelected EQU %00110000
A_Buttons EQU $FF00

A_InterruptFlags   EQU $FF0F
A_InterruptControl EQU $FFFF

M_Lcdc_Enabled                  EQU %10000000
M_Lcdc_WindowUsesSecondTilemap  EQU %01000000
M_Lcdc_WindowEnabled            EQU %00100000
M_Lcdc_MapsAndSpritesShareTiles EQU %00010000
M_Lcdc_BgUsesSecondTilemap      EQU %00001000
M_Lcdc_TallSprites              EQU %00000100
M_Lcdc_SpritesEnabled           EQU %00000010
M_Lcdc_BgOn                     EQU %00000001

A_Lcdc_Control      EQU $FF40
A_Lcdc_YScroll      EQU $FF42
A_Lcdc_XScroll      EQU $FF43
A_Lcdc_CurrentY     EQU $FF44
A_Lcdc_GbMapPalette EQU $FF47
A_Lcdc_WindowYPos   EQU $FF4A
A_Lcdc_WindowXPos   EQU $FF4B

A_CpuSpeed EQU $FF4D

A_IrPortControl EQU $FF56

M_Lcdc_SetControl: MACRO
    ld a, \1
    ldh [A_Lcdc_Control], a
ENDM

ENDC
