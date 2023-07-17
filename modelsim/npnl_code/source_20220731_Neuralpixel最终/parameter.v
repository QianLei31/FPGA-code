parameter LEN_SPI = 32 ; //packet data only after decoding and header removeal
parameter BITS_CNT_SPI = 6 ;
parameter SPI_ADDR_LEN = 10;
parameter SPI_DATA_LEN = 16;
parameter SPI_CODE_LEN = 6;

parameter BITS_ADC = 12; // ADC data width

parameter REC_LEN = 12; // Record control REG
parameter DAC_AMP_LEN = 9; // DAC control REG

parameter ELE_NUM       = 1024; // NeuralPixel : Eletrode number 0-1023
parameter ELE_CHEM_NUM  = 1024; // NeuralPixel : Chem Eletrode number 0-1023
parameter ELE_GROUP_WID = 16;   // NeuralPixel : ALL Eletrode group width: 16. 1024/16=64 group in total
