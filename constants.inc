; M stands for "macro".
M_MagicIsGbc EQU $11

; A stands for "address".
A_BankNumberControl EQU $2000

A_Lcdc_Control     EQU $FF40
A_Lcdc_YScroll     EQU $FF42
A_Lcdc_XScroll     EQU $FF43
A_Lcdc_YCoordinate EQU $FF44
A_Lcdc_WindowYPos  EQU $FF4A
A_Lcdc_WindowXPos  EQU $FF4B

RSSET $C356
A_Decompression_SrcAddress    RW 1
A_Decompression_SrcBank       RW 1
A_Decompression_DestAddress   RW 1
A_Decompression_DestBank      RW 1

; The structure for passing arguments to the graphics loader
; is reused to pass information out again.
RSSET $C356
A_DecompressedData_Address  RW 1
A_DecompressedData_Bank     RW 1
A_DecompressedData_Length   RW 1

RSSET $C360
A_RleChunk_DataLength      RW 1
A_RleChunk_RepeatsLeft     RW 1
A_ReferenceChunk_BytesLeft EQU A_RleChunk_RepeatsLeft
A_RleChunk_DataAddress     RW 1
