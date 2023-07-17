// Author      : GTT/XKK
// Description : BLOCK TOP
// Change date : 2022/06/20
// Change log  : None
// Change date : 2022/07/21
// Change log  : modify for elec_mux bit width from 8 to 16bit, add SAMP_analog

module BLOCK_DIGITAL (
	clk_3p2M,   // ADC and FSM_BLOCK clock
	rst_n,      // Asynchronous reset active low

	/* REG_MAP */
	// spi cmd, input from FSM
	data_in,
	addr,
	code,
	// reg_map address
	reg_map_addr,
	// spi read data, output to FSM
	data_out,
	
	// output to analog, control state
	Rec_0,
	Rec_1,
	Rec_2,
	Rec_3,

	// output to DAC
	STIM_AMP_0,  STIM_AMP_1,  STIM_AMP_2,  STIM_AMP_3,  // DAC amplitude
	OFF_STIM_0,  OFF_STIM_1,  OFF_STIM_2,  OFF_STIM_3,  // Enable Stim.
	CB_CHNL_0 ,  CB_CHNL_1 ,  CB_CHNL_2 ,  CB_CHNL_3 ,  // balance electric charge 4bit
	SW_ANO_N_0,  SW_ANO_N_1,  SW_ANO_N_2,  SW_ANO_N_3,  // channel 4bit
	SW_CAN_0  ,  SW_CAN_1  ,  SW_CAN_2  ,  SW_CAN_3  ,  // channel 4bit
	AZ_CLK_0  ,  AZ_CLK_1  ,  AZ_CLK_2  ,  AZ_CLK_3  ,
	AZ_CLK_N_0,  AZ_CLK_N_1,  AZ_CLK_N_2,  AZ_CLK_N_3,
	AMP_ON_0  ,  AMP_ON_1  ,  AMP_ON_2  ,  AMP_ON_3  ,
	// input from DAC
	AMP_OUT_0 ,  AMP_OUT_1 ,  AMP_OUT_2 ,  AMP_OUT_3 ,
	AMP_X50_0 ,  AMP_X50_1 ,  AMP_X50_2 ,  AMP_X50_3 ,
	//SAMP_RATE_MUX ,
	elec_mux,
	D_HP,
	/* FSM_BLOCK */
    // adc_ready,
    // data_from_adc0,
    // data_from_adc1,
    // data_from_adc2,
    // data_from_adc3,
    data_from_pre,
    data_to_post,

	COMP,
	SAMP,
	SAMP_analog,
	WP0,
	WP1,
	WP2,
	WP3
);

// `include "../parameter.v"
parameter LEN_SPI = 32 ; //packet data only after decoding and header removeal
parameter BITS_CNT_SPI = 6 ;
parameter SPI_ADDR_LEN = 10;
parameter SPI_DATA_LEN = 16;
parameter SPI_CODE_LEN = 6;

parameter BITS_ADC = 12; // ADC data width

parameter REC_LEN = 12; // Record control REG
parameter DAC_AMP_LEN = 9; // DAC control REG

input clk_3p2M, rst_n;
input [SPI_DATA_LEN-1:0] data_in;
input [SPI_ADDR_LEN-1:0] addr;
input [SPI_CODE_LEN-1:0] code;
input [SPI_ADDR_LEN-3:0] reg_map_addr;
inout [SPI_DATA_LEN-1:0] data_out;

output [REC_LEN-1:0]	Rec_0;				
output [REC_LEN-1:0]	Rec_1;			 						
output [REC_LEN-1:0]	Rec_2;			 						
output [REC_LEN-1:0]	Rec_3;


output [DAC_AMP_LEN-1:0] STIM_AMP_0,STIM_AMP_1,STIM_AMP_2,STIM_AMP_3;
output 					 OFF_STIM_0,OFF_STIM_1,OFF_STIM_2,OFF_STIM_3;
input					 AMP_OUT_0,AMP_OUT_1,AMP_OUT_2,AMP_OUT_3;
output					 AZ_CLK_0,AZ_CLK_1,AZ_CLK_2,AZ_CLK_3;
output					 AZ_CLK_N_0,AZ_CLK_N_1,AZ_CLK_N_2,AZ_CLK_N_3;
output					 AMP_ON_0,AMP_ON_1,AMP_ON_2,AMP_ON_3;
output [3:0]             CB_CHNL_0,CB_CHNL_1,CB_CHNL_2,CB_CHNL_3;
output [3:0]             SW_ANO_N_0,SW_ANO_N_1,SW_ANO_N_2,SW_ANO_N_3;
output [3:0]             SW_CAN_0,SW_CAN_1,SW_CAN_2,SW_CAN_3;
output                   AMP_X50_0, AMP_X50_1, AMP_X50_2, AMP_X50_3;
output [15:0]	    	 elec_mux;
output [3:0]			 D_HP;

// FSM_BLOCK
wire [1:0] SAMP_RATE_MUX;
wire [1:0] POL_0;
wire [1:0] POL_1;
wire [1:0] POL_2;
wire [1:0] POL_3;
wire       clk_CB_LOGIC;

// DAISY_CHAIN
//wire                        adc_ready;
wire    [BITS_ADC-1:0] data_from_adc0;
wire    [BITS_ADC-1:0] data_from_adc1;
wire    [BITS_ADC-1:0] data_from_adc2;
wire    [BITS_ADC-1:0] data_from_adc3;  
input   [BITS_ADC:0]   data_from_pre;
output  [BITS_ADC:0]   data_to_post;

RST_N_SYN rst_n_syn(
    .clk_sys(clk_3p2M),   // Chip clock 
    .rst_n(rst_n),        // Asynchronous rst_n
	.rst_syn_n(rst_syn_n)
);

wire [1:0] elec_sel_0,elec_sel_1,elec_sel_2,elec_sel_3;
FSM_BLOCK fsm_block(
	.clk(clk_3p2M),
	.rst_n(rst_syn_n),

	.data_in(data_in),
	.addr(addr),
	.code(code),
	
	.reg_map_addr(reg_map_addr),//由该端口确定reg_map的地址
	
    .adc_ready(SAMP),       // ADC data ready, posedge valid
    .data_from_adc0(data_from_adc0),  // data from CH0
    .data_from_adc1(data_from_adc1),  // data from CH1
    .data_from_adc2(data_from_adc2),  // data from CH2
    .data_from_adc3(data_from_adc3),  // data from CH3
    .data_from_pre(data_from_pre),   // data from pre BLOCK
    .data_to_post(data_to_post),     // data to post BLOCK

	.data_out(data_out),	//由SPI读出
	
	//给模拟端
	.Rec_0(Rec_0),
	.Rec_1(Rec_1),
	.Rec_2(Rec_2),
	.Rec_3(Rec_3),

	//DAC控制
	.elec_sel_0(elec_sel_0),
	.elec_sel_1(elec_sel_1),
	.elec_sel_2(elec_sel_2),
	.elec_sel_3(elec_sel_3),

	.POL_0(POL_0),// REG_MAP to CB_Logic, polarity control
	.POL_1(POL_1),
	.POL_2(POL_2),
	.POL_3(POL_3),

	.CB_ON_0(CB_ON_0),// REG_MAP to CB_Logic
	.CB_ON_1(CB_ON_1),
	.CB_ON_2(CB_ON_2),
	.CB_ON_3(CB_ON_3),

	.CB_OK_0(CB_OK_0),// from CB_Logic, compensate finish
	.CB_OK_1(CB_OK_1),
	.CB_OK_2(CB_OK_2),
	.CB_OK_3(CB_OK_3),

	.STIM_AMP_0(STIM_AMP_0),// REG_MAP to DAC, amplitude control
	.STIM_AMP_1(STIM_AMP_1),
	.STIM_AMP_2(STIM_AMP_2),
	.STIM_AMP_3(STIM_AMP_3),

	.OFF_STIM_0(OFF_STIM_0),// REG_MAP to DAC, stim on/off, Low valid
	.OFF_STIM_1(OFF_STIM_1),
	.OFF_STIM_2(OFF_STIM_2),
	.OFF_STIM_3(OFF_STIM_3),	
	
	.AMP_X50_0(AMP_X50_0),// REG_MAP to DAC, amplitude times control 
	.AMP_X50_1(AMP_X50_1),
	.AMP_X50_2(AMP_X50_2),
	.AMP_X50_3(AMP_X50_3),

	.SAMP_RATE_MUX(SAMP_RATE_MUX),
	.elec_mux(elec_mux),
	.D_HP(D_HP),
	.clk_CB_LOGIC(clk_CB_LOGIC)
);

CB_Logic CB_Logic_i0(
	.CH(elec_sel_0),
	.CLK(clk_CB_LOGIC), 
	.AMP_OUT(AMP_OUT_0),
	.CB_ON(CB_ON_0),
	.RST_N(rst_syn_n),
	.CAN_STI(POL_0[0]),
	.ANO_STI(POL_0[1]),
	.AZ_CLK(AZ_CLK_0),
	.AZ_CLK_N(AZ_CLK_N_0),
	.AMP_ON(AMP_ON_0),
	.CB_OK(CB_OK_0),
	.CB_CHNL(CB_CHNL_0),
	.SW_ANO_N(SW_ANO_N_0),
	.SW_CAN(SW_CAN_0)	
);

CB_Logic CB_Logic_i1(
	.CH(elec_sel_1),
	.CLK(clk_CB_LOGIC), 
	.AMP_OUT(AMP_OUT_1),
	.CB_ON(CB_ON_1),
	.RST_N(rst_syn_n),
	.CAN_STI(POL_1[0]),
	.ANO_STI(POL_1[1]),
	.AZ_CLK	(AZ_CLK_1),
	.AZ_CLK_N(AZ_CLK_N_1),
	.AMP_ON(AMP_ON_1),
	.CB_OK(CB_OK_1),
	.CB_CHNL(CB_CHNL_1),
	.SW_ANO_N(SW_ANO_N_1),
	.SW_CAN(SW_CAN_1)	
);

CB_Logic CB_Logic_i2(
	.CH(elec_sel_2),
	.CLK(clk_CB_LOGIC), 
	.AMP_OUT(AMP_OUT_2),
	.CB_ON(CB_ON_2),
	.RST_N(rst_syn_n),
	.CAN_STI(POL_2[0]),
	.ANO_STI(POL_2[1]),
	.AZ_CLK(AZ_CLK_2),
	.AZ_CLK_N(AZ_CLK_N_2),
	.AMP_ON(AMP_ON_2),
	.CB_OK(CB_OK_2),
	.CB_CHNL(CB_CHNL_2),
	.SW_ANO_N(SW_ANO_N_2),
	.SW_CAN(SW_CAN_2)
);

CB_Logic CB_Logic_i3(
	.CH(elec_sel_3),
	.CLK(clk_CB_LOGIC), 
	.AMP_OUT(AMP_OUT_3),
	.CB_ON(CB_ON_3),
	.RST_N(rst_syn_n),
	.CAN_STI(POL_3[0]),
	.ANO_STI(POL_3[1]),
	.AZ_CLK(AZ_CLK_3),
	.AZ_CLK_N(AZ_CLK_N_3),
	.AMP_ON(AMP_ON_3),
	.CB_OK(CB_OK_3),
	.CB_CHNL(CB_CHNL_3),
	.SW_ANO_N(SW_ANO_N_3),
	.SW_CAN(SW_CAN_3)	
);

input wire [3:0]  COMP;
output     		  SAMP;
output     [11:0] WP0;
output     [11:0] WP1;
output     [11:0] WP2;
output     [11:0] WP3;
output            SAMP_analog;

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

