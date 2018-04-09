IF !DEF(SYSTEM_INC)
SYSTEM_INC SET 1

M_MagicIsGbc EQU $11 ; Also GBA.

A_VramBankControl EQU $FF4F
A_WramBankControl EQU $FF70

M_Buttons_NoneSelected EQU %00110000
A_Buttons EQU $FF00

A_InterruptFlags   EQU $FF0F
A_InterruptControl EQU $FFFF

A_Sound_Ch3_On                  EQU $FF1A
A_Sound_Ch3_Length              EQU $FF1B
A_Sound_Ch3_Volume              EQU $FF1C
A_Sound_Ch3_Freq_Low            EQU $FF1D
A_Sound_Ch3_Freq_HighAndControl EQU $FF1E
A_Sound_Ch3_SampleMemory        EQU $FF30

M_Sound_LeftVolumePos   EQU 0
M_Sound_ExternalToLeft  EQU %00001000
M_Sound_RightVolumePos  EQU 4
M_Sound_ExternalToRight EQU %10000000
M_Sound_BothFullVolume  EQU (%111 << M_Sound_LeftVolumePos) | \
                            (%111 << M_Sound_RightVolumePos)
M_Sound_Ch1ToLeft  EQU %00000001
M_Sound_Ch2ToLeft  EQU %00000010
M_Sound_Ch3ToLeft  EQU %00000100
M_Sound_Ch4ToLeft  EQU %00001000
M_Sound_Ch1ToRight EQU %00010000
M_Sound_Ch2ToRight EQU %00100000
M_Sound_Ch3ToRight EQU %01000000
M_Sound_Ch4ToRight EQU %10000000
M_Sound_Ch1ToBoth  EQU M_Sound_Ch1ToLeft | M_Sound_Ch1ToRight
M_Sound_Ch2ToBoth  EQU M_Sound_Ch2ToLeft | M_Sound_Ch2ToRight
M_Sound_Ch3ToBoth  EQU M_Sound_Ch3ToLeft | M_Sound_Ch3ToRight
M_Sound_Ch4ToBoth  EQU M_Sound_Ch4ToLeft | M_Sound_Ch4ToRight
M_Sound_AllChannelsToBoth EQU M_Sound_Ch1ToBoth | \
                              M_Sound_Ch2ToBoth | \
                              M_Sound_Ch3ToBoth | \
                              M_Sound_Ch4ToBoth
M_Sound_Ch1IsOn EQU %00000001
M_Sound_Ch2IsOn EQU %00000010
M_Sound_Ch3IsOn EQU %00000100
M_Sound_Ch4IsOn EQU %00001000
M_Sound_On      EQU %10000000

A_Sound_OutputControl  EQU $FF24
A_Sound_ChannelOutputs EQU $FF25
A_Sound_On             EQU $FF26

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

M_Palette_AutoIncrement EQU %10000000

A_Palette_Bg_Index     EQU $FF68
A_Palette_Bg_Data      EQU $FF69
A_Palette_Sprite_Index EQU $FF6A
A_Palette_Sprite_Data  EQU $FF6B

A_Mbc5_RomBankControl         EQU $2000
A_Mbc5_RamBankControl_HighBit EQU $3000
A_Mbc5_RamBankControl         EQU $4000

M_Lcdc_SetControl: MACRO
    ld a, \1
    ldh [A_Lcdc_Control], a
ENDM

M_Mbc5_EnableExternalRam: MACRO
    ld a, $0A
    ld [$0000], a
ENDM

M_Mbc5_DisableExternalRam: MACRO
    xor a
    ld [$0000], a
ENDM

ENDC
