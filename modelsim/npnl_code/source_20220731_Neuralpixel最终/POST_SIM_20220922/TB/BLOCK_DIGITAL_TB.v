// Author      : GTT
// Description : BLOCK DIGITAL TB
// Change date : 2022/06/21
// Change log  : None
`timescale 1ns/10ps
module BLOCK_DIGITAL_TB ();

// `include "../parameter.v"
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

parameter ROW_BLOCK_NUM = 8;
parameter ROW_NUM = 8;

wire rst_n;
wire clk_3p2M;
wire clk_50M;

wire [REC_LEN-1:0] Rec_0;
wire [REC_LEN-1:0] Rec_1;
wire [REC_LEN-1:0] Rec_2;
wire [REC_LEN-1:0] Rec_3;
wire [SPI_DATA_LEN-1:0] data_in;
wire [SPI_ADDR_LEN-1:0] addr;
wire [SPI_CODE_LEN-1:0] code;
wire [SPI_DATA_LEN-1:0] data_out;

wire [DAC_AMP_LEN-1:0] STIM_AMP_0;
wire 				  OFF_STIM_0;
reg 				  AMP_OUT_0 ;
wire				  AZ_CLK_0  ;
wire				  AZ_CLK_N_0;
wire				  AMP_ON_0  ;
wire [3:0]            CB_CHNL_0 ;						
wire [3:0]            SW_ANO_N_0;
wire [3:0]            SW_CAN_0  ;
wire AMP_X50_0;

wire [DAC_AMP_LEN-1:0] STIM_AMP_1;
wire 				  OFF_STIM_1;
reg 				  AMP_OUT_1 ;
wire				  AZ_CLK_1  ;
wire				  AZ_CLK_N_1;
wire				  AMP_ON_1  ;
wire [3:0]            CB_CHNL_1 ;						
wire [3:0]            SW_ANO_N_1;
wire [3:0]            SW_CAN_1  ;
wire AMP_X50_1;

wire [DAC_AMP_LEN-1:0] STIM_AMP_2;
wire 				  OFF_STIM_2;
reg 				  AMP_OUT_2 ;
wire				  AZ_CLK_2  ;
wire				  AZ_CLK_N_2;
wire				  AMP_ON_2  ;
wire [3:0]            CB_CHNL_2 ;						
wire [3:0]            SW_ANO_N_2;
wire [3:0]            SW_CAN_2  ;
wire AMP_X50_2;

wire [DAC_AMP_LEN-1:0] STIM_AMP_3;
wire 				  OFF_STIM_3;
reg 				  AMP_OUT_3 ;
wire				  AZ_CLK_3  ;
wire				  AZ_CLK_N_3;
wire				  AMP_ON_3  ;
wire [3:0]            CB_CHNL_3 ;						
wire [3:0]            SW_ANO_N_3;
wire [3:0]            SW_CAN_3  ;
wire AMP_X50_3;

wire [7:0]	          elec_mux;
wire [3:0]	          D_HP;
wire 			      clk_CB_LOGIC;
//wire [1:0] 		      SAMP_RATE_MUX;
reg [7:0] chem_out; // counter CHEM pulse

wire [BITS_ADC:0] daisy_chain[ROW_BLOCK_NUM:0];

wire        SAMP;
wire        WP0 ;
wire        WP1 ;
wire        WP2 ;
wire        WP3 ;
wire        SAMP_analog;
wire [11:0] WN0 ;
wire [11:0] WN1 ;
wire [11:0] WN2 ;
wire [11:0] WN3 ;

wire [ROW_NUM-1:0] s_data;
wire [ROW_NUM-1:0] data_valid;
wire [64*8-1:0] reg_map_addr;

wire [BITS_ADC:0] data_from_pre;
wire [BITS_ADC:0] data_to_post;

// ADC comparator model
reg  [3:0]  COMP;
always @(posedge clk_3p2M or negedge rst_n) begin
	if(~rst_n) begin
		COMP <= 'b0;
	end else begin
		COMP <= {$random} % 16;
		// $display("COMP: %d",COMP);
	end
end

// CB_OK model
initial begin //1243 us 读
	AMP_OUT_0 = 1'b0;
	AMP_OUT_1 = 1'b0;
	AMP_OUT_2 = 1'b0;
	AMP_OUT_3 = 1'b0;
	
	#500000
	AMP_OUT_2 = 1'b1;
	#100000
	AMP_OUT_2 = 1'b0;

	#300000
	AMP_OUT_2 = 1'b1;
	#1100000
	AMP_OUT_2 = 1'b0;

end

initial begin 
	chem_out = 8'b0;
	#3000
	@ (posedge clk_50M);
	chem_out = 8'b0000_0001;
	#3000
	@ (posedge clk_50M);
	chem_out = 8'b0000_0011;
	#3000
	@ (posedge clk_50M);
	chem_out = 8'b0000_0111;
	#3000
	@ (posedge clk_50M);
	chem_out = 8'b0000_1111;
	#3000
	@ (posedge clk_50M);
	chem_out = 8'b0001_1111;
	#3000
	@ (posedge clk_50M);
	chem_out = 8'b0011_1111;
	#3000
	@ (posedge clk_50M);
	chem_out = 8'b0111_1111;
	#3000
	@ (posedge clk_50M);
	chem_out = 8'b1111_1111;
	#2000
	@ (posedge clk_50M);
	chem_out = 8'b0000_0000;
end

spi_code_gen code_gen(
	.clk_50M(clk_50M),
	.rst_n(rst_n),
	
	.reg_map_addr(reg_map_addr),

	.sck(sck), 
	.mosi(mosi),
	.miso(miso), 
	.cs_n(cs_n)
);

reg [ELE_NUM-1:0]      ELE_MUX_PIXEL_PROBE;
reg [ELE_CHEM_NUM-1:0] ELE_CHEM_MUX_PIXEL_PROBE;
MAIN_FSM main_fsm(
    .clk_50M(clk_50M),        //Chip clock 
    .clk_3p2M(clk_3p2M),
    .rst_n(rst_n),      // Asynchronous rst_n
	.rst_n_block(rst_n_block),

	.code(code),
	.addr(addr),
	.data_in(data_in),
	.data_out(data_out),//reg_map 三态门
	
	.data_to_elec(data_to_elec),
	.clk_to_elec(clk_to_elec),
	.data_to_elec_chem(data_to_elec_chem),
	.clk_to_elec_chem(clk_to_elec_chem),
	
	.rst_n_to_probe(rst_n_to_probe),	
	.chem_out(chem_out),
	//clk_CB_LOGIC, //给CB_LOGIC的时钟
	//clk_ADC, //给ADC的时钟

    // Standard SPI interface
    .sck(sck),         // SPI clock
    .miso(miso),       // Master IN slave Out lsb first, Latched in in falling edge
    .mosi(mosi),       // Master Out slave IN lsb first, changed in falling edge
    .cs_n(cs_n),       // Chip select (low active)
    .p_data({(ROW_NUM){data_to_post}}),
	.s_data(s_data),
	.data_valid(data_valid)
);

// ELEC model in probe
integer ii;
always @(posedge clk_to_elec or negedge rst_n_to_probe) begin
	if(~rst_n_to_probe) begin
		for (ii = 0; ii < ELE_NUM/ELE_GROUP_WID; ii=ii+1) begin // ii from 0 to 63
			ELE_MUX_PIXEL_PROBE[ii*ELE_GROUP_WID+:ELE_GROUP_WID] = {(ELE_GROUP_WID){1'b0}};
		end
	end else begin
		ELE_MUX_PIXEL_PROBE <= {data_to_elec,ELE_MUX_PIXEL_PROBE[ELE_NUM-1:1]};
	end
end

// ELEC CHEM model in probe
always @(posedge clk_to_elec_chem or negedge rst_n_to_probe) begin
	if(~rst_n_to_probe) begin
		for (ii = 0; ii < ELE_CHEM_NUM/ELE_GROUP_WID; ii=ii+1) begin
			ELE_CHEM_MUX_PIXEL_PROBE[ii*ELE_GROUP_WID+:ELE_GROUP_WID] = {(ELE_GROUP_WID){1'b0}};
		end
	end else begin
		ELE_CHEM_MUX_PIXEL_PROBE <= {data_to_elec_chem,ELE_CHEM_MUX_PIXEL_PROBE[ELE_CHEM_NUM-1:1]};
	end
end


BLOCK_DIGITAL block_digital(
	.clk_3p2M(clk_3p2M),    // system clock
	.rst_n(rst_n_block),          // Asynchronous reset active low

	/* REG_MAP */
	// spi cmd, input from FSM
	.data_in(data_in),
	.addr(addr),
	.code(code),
	// reg_map address
	.reg_map_addr(reg_map_addr[23:16]),
	// spi read data, output to FSM
	.data_out(data_out),
	
	// output to analog, control state
	.Rec_0(Rec_0),
	.Rec_1(Rec_1),
	.Rec_2(Rec_2),
	.Rec_3(Rec_3),
/*
	// output to DAC
	.STIM_AMP_0(STIM_AMP_0), .STIM_AMP_1(STIM_AMP_1), .STIM_AMP_2(STIM_AMP_2), .STIM_AMP_3(STIM_AMP_3),  // DAC amplitude
	.OFF_STIM_0(OFF_STIM_0), .OFF_STIM_1(OFF_STIM_1), .OFF_STIM_2(OFF_STIM_2), .OFF_STIM_3(OFF_STIM_3),  // Enable Stim.
	.CB_CHNL_0 (CB_CHNL_0 ), .CB_CHNL_1 (CB_CHNL_1 ), .CB_CHNL_2 (CB_CHNL_2 ), .CB_CHNL_3 (CB_CHNL_3),   // balance electric charge 4bit
	.SW_ANO_N_0(SW_ANO_N_0), .SW_ANO_N_1(SW_ANO_N_1), .SW_ANO_N_2(SW_ANO_N_2), .SW_ANO_N_3(SW_ANO_N_3),  // channel 4bit
	.SW_CAN_0  (SW_CAN_0  ), .SW_CAN_1  (SW_CAN_1  ), .SW_CAN_2  (SW_CAN_2  ), .SW_CAN_3  (SW_CAN_3  ),    // channel 4bit
	.AZ_CLK_0  (AZ_CLK_0  ), .AZ_CLK_1  (AZ_CLK_1  ), .AZ_CLK_2  (AZ_CLK_2  ), .AZ_CLK_3  (AZ_CLK_3  ),
	.AZ_CLK_N_0(AZ_CLK_N_0), .AZ_CLK_N_1(AZ_CLK_N_1), .AZ_CLK_N_2(AZ_CLK_N_2), .AZ_CLK_N_3(AZ_CLK_N_3),
	.AMP_ON_0  (AMP_ON_0  ), .AMP_ON_1  (AMP_ON_1  ), .AMP_ON_2  (AMP_ON_2  ), .AMP_ON_3  (AMP_ON_3  ),
	// input from DAC
	.AMP_OUT_0 (AMP_OUT_0 ), .AMP_OUT_1(AMP_OUT_1), .AMP_OUT_2(AMP_OUT_2), .AMP_OUT_3(AMP_OUT_3),
	.AMP_X50_0 (AMP_X50_0 ), .AMP_X50_1(AMP_X50_1), .AMP_X50_2(AMP_X50_2), .AMP_X50_3(AMP_X50_3),
	//.SAMP_RATE_MUX(SAMP_RATE_MUX),
	.elec_mux(elec_mux),
*/
	.D_HP(D_HP),
	/* FSM_BLOCK */
	// adc_ready,
	// .fsm_block_addr(fsm_block_addr[x*ROW_BLOCK_NUM + y]),
	// data_from_adc0,
	// data_from_adc1,
	// data_from_adc2,
	// data_from_adc3,
	.data_from_pre(data_from_pre),
	.data_to_post(data_to_post),

	.COMP(COMP),
	.SAMP(SAMP),
	.SAMP_analog(SAMP_analog),
	.WP0(WP0),
	.WP1(WP1),
	.WP2(WP2),
	.WP3(WP3)
	//.WN0(WN0),
	//.WN1(WN1),
	//.WN2(WN2),
	//.WN3(WN3)
);

assign daisy_chain[0] = {(BITS_ADC+1){1'b1}};
assign data_from_pre = daisy_chain[ROW_BLOCK_NUM-1];
assign daisy_chain[ROW_BLOCK_NUM] = data_to_post;

generate
	genvar i;
	for (i = 0; i < ROW_BLOCK_NUM-1; i=i+1) begin : block_e
FSM_BLOCK_SIM fsm_block(
	.clk(clk_3p2M),
	.rst_n(rst_n_block),

    .adc_ready(SAMP),       // ADC data ready, posedge valid
    .data_from_pre(daisy_chain[i]),   // data from pre BLOCK
    .data_to_post(daisy_chain[i+1])   // data to post BLOCK
    /** remove other useless port declare **/
);
	end
endgenerate

// monitor STIM REG
S2P s2p(
    .clk(clk_50M),
    .rst_n(rst_n_block),
    .s_data(s_data[0]),
    .data_valid(data_valid[0]),
    .data_from_blk_0_ch_3(data_from_blk_0_ch_3),
    .data_from_blk_1_ch_3(data_from_blk_1_ch_3),
    .data_from_blk_2_ch_3(data_from_blk_2_ch_3),
    .data_from_blk_3_ch_3(data_from_blk_3_ch_3),
    .data_from_blk_4_ch_3(data_from_blk_4_ch_3),
    .data_from_blk_5_ch_3(data_from_blk_5_ch_3),
    .data_from_blk_6_ch_3(data_from_blk_6_ch_3),
    .data_from_blk_7_ch_3(data_from_blk_7_ch_3),
    .data_from_blk_0_ch_2(data_from_blk_0_ch_2),
    .data_from_blk_1_ch_2(data_from_blk_1_ch_2),
    .data_from_blk_2_ch_2(data_from_blk_2_ch_2),
    .data_from_blk_3_ch_2(data_from_blk_3_ch_2),
    .data_from_blk_4_ch_2(data_from_blk_4_ch_2),
    .data_from_blk_5_ch_2(data_from_blk_5_ch_2),
    .data_from_blk_6_ch_2(data_from_blk_6_ch_2),
    .data_from_blk_7_ch_2(data_from_blk_7_ch_2),
    .data_from_blk_0_ch_1(data_from_blk_0_ch_1),
    .data_from_blk_1_ch_1(data_from_blk_1_ch_1),
    .data_from_blk_2_ch_1(data_from_blk_2_ch_1),
    .data_from_blk_3_ch_1(data_from_blk_3_ch_1),
    .data_from_blk_4_ch_1(data_from_blk_4_ch_1),
    .data_from_blk_5_ch_1(data_from_blk_5_ch_1),
    .data_from_blk_6_ch_1(data_from_blk_6_ch_1),
    .data_from_blk_7_ch_1(data_from_blk_7_ch_1),
    .data_from_blk_0_ch_0(data_from_blk_0_ch_0),
    .data_from_blk_1_ch_0(data_from_blk_1_ch_0),
    .data_from_blk_2_ch_0(data_from_blk_2_ch_0),
    .data_from_blk_3_ch_0(data_from_blk_3_ch_0),
    .data_from_blk_4_ch_0(data_from_blk_4_ch_0),
    .data_from_blk_5_ch_0(data_from_blk_5_ch_0),
    .data_from_blk_6_ch_0(data_from_blk_6_ch_0),
    .data_from_blk_7_ch_0(data_from_blk_7_ch_0)
);



endmodule

