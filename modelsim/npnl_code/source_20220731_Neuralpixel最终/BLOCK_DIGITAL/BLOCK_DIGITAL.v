// Author      : GTT/XKK
// Description : BLOCK TOP
// Change date : 2022/06/20
// Change log  : None
// Change date : 2022/07/21
// Change log  : modify for elec_mux bit width from 8 to 16bit, add SAMP_analog
// Change date : 2022/08/18
// Change log  : delete DAC logic

module BLOCK_DIGITAL (
	clk_3p2M,   // ADC and FSM_BLOCK clock
	rst_n,      // Asynchronous reset active low

	data_in, // spi cmd, input from FSM
	addr,    // spi cmd, input from FSM
	code,    // spi cmd, input from FSM

	reg_map_addr, // BLOCK address
	
	data_out, // spi read data, output to FSM
	
	
	Rec_0, // output to analog, control state
	Rec_1, // output to analog, control state
	Rec_2, // output to analog, control state
	Rec_3, // output to analog, control state
	D_HP,  // output to analog, control state

    data_from_pre, // Daisy chain in
    data_to_post,  // Daisy chain out

	COMP, // ADC compare in
	SAMP,
	SAMP_analog,
	WP0,
	WP1,
	WP2,
	WP3
);

// `include "../parameter.v"
parameter LEN_SPI      = 32; //packet data only after decoding and header removeal
parameter BITS_CNT_SPI = 6;
parameter SPI_ADDR_LEN = 10;
parameter SPI_DATA_LEN = 16;
parameter SPI_CODE_LEN = 6;
parameter BITS_ADC     = 12; // ADC data width
parameter REC_LEN      = 12; // Record control REG
parameter DAC_AMP_LEN  = 9;  // DAC control REG

input clk_3p2M;
input rst_n;

input [SPI_DATA_LEN-1:0] data_in;
input [SPI_ADDR_LEN-1:0] addr;
input [SPI_CODE_LEN-1:0] code;
input [SPI_ADDR_LEN-3:0] reg_map_addr;
inout [SPI_DATA_LEN-1:0] data_out;

output [REC_LEN-1:0] Rec_0;				
output [REC_LEN-1:0] Rec_1;			 						
output [REC_LEN-1:0] Rec_2;			 						
output [REC_LEN-1:0] Rec_3;
output [3:0]		 D_HP;

input  [3:0]  COMP;
output 		  SAMP;
output [11:0] WP0;
output [11:0] WP1;
output [11:0] WP2;
output [11:0] WP3;
output        SAMP_analog;

input  [BITS_ADC:0] data_from_pre;
output [BITS_ADC:0] data_to_post;

// DAISY_CHAIN
wire [BITS_ADC-1:0] data_from_adc0;
wire [BITS_ADC-1:0] data_from_adc1;
wire [BITS_ADC-1:0] data_from_adc2;
wire [BITS_ADC-1:0] data_from_adc3;  
wire [1:0]          SAMP_RATE_MUX;

RST_N_SYN rst_n_syn(
    .clk_sys(clk_3p2M),   // Chip clock 
    .rst_n(rst_n),        // Asynchronous rst_n
	.rst_syn_n(rst_syn_n)
);

FSM_BLOCK fsm_block(
	.clk(clk_3p2M),
	.rst_n(rst_syn_n),

	.data_in(data_in),
	.addr(addr),
	.code(code),
	
	.reg_map_addr(reg_map_addr),
	
    .adc_ready(SAMP),                // ADC data ready, posedge valid
    .data_from_adc0(data_from_adc0), // data from CH0
    .data_from_adc1(data_from_adc1), // data from CH1
    .data_from_adc2(data_from_adc2), // data from CH2
    .data_from_adc3(data_from_adc3), // data from CH3
    .data_from_pre(data_from_pre),   // data from pre BLOCK
    .data_to_post(data_to_post),     // data to post BLOCK

	.data_out(data_out),
	
	// to analog
	.Rec_0(Rec_0),
	.Rec_1(Rec_1),
	.Rec_2(Rec_2),
	.Rec_3(Rec_3),

	.SAMP_RATE_MUX(SAMP_RATE_MUX),
	.D_HP(D_HP)
);

sar_adc_logic_12bit_v4_single_input_v2_x4 sar_adc_logic(
	.CLK(clk_3p2M),
	.RSTN(rst_syn_n),
	.COMP(COMP),
	.DR(SAMP),
	.SAMP_analog(SAMP_analog),
	.SAMP_RATE_MUX(SAMP_RATE_MUX),
	.WP0(WP0),
	.WP1(WP1),
	.WP2(WP2),
	.WP3(WP3),
	.D0(data_from_adc0),
	.D1(data_from_adc1),
	.D2(data_from_adc2),
	.D3(data_from_adc3)
);

endmodule

