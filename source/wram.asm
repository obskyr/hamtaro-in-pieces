SECTION "Decompression routine in/out WRAM", WRAM0[$C356]

A_Decompression_SrcAddress::
A_DecompressedData_Address:: DW
A_Decompression_SrcBank::
A_DecompressedData_Bank::    DW
A_Decompression_DestAddress::
A_DecompressedData_Length::  DW
A_Decompression_DestBank::   DW

SECTION "Decompression routine internal WRAM", WRAM0[$C360]
A_RleChunk_DataLength::      DW
A_RleChunk_RepeatsLeft::
A_ReferenceChunk_BytesLeft:: DW
A_RleChunk_DataAddress::     DW

SECTION "Tilemap decompression routine WRAM", WRAM0[$C36A]
A_TilemapDecompression_Width::                   DW
A_TilemapDecompression_TilesLeftInRow::          DB
A_TilemapDecompression_TilesLeftInReferenceRow:: DB
A_TilemapDecompression_TilesToSkip::             DW