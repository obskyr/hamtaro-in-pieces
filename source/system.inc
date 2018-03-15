IF !DEF(SYSTEM_INC)
SYSTEM_INC SET 1

M_MagicIsGbc EQU $11 ; Also GBA.

A_RomBankControl  EQU $2000
A_WramBankControl EQU $FF70

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
A_Lcdc_YCoordinate  EQU $FF44
A_Lcdc_GbMapPalette EQU $FF47
A_Lcdc_WindowYPos   EQU $FF4A
A_Lcdc_WindowXPos   EQU $FF4B

ENDC
