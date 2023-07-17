// Author      : GTT
// Description : BLOCK DIGITAL TB
// Change date : 2022/06/21
// Change log  : None
`timescale 1ns/10ps
module BLOCK_DIGITAL_TB ();

`include "../parameter.v"

parameter ROW_BLOCK_NUM = 8;
parameter ROW_NUM = 8;

wire rst_n;
wire clk_3p2M;

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
/*
//检测SAMP上升沿，data_from_pre输出变化，32个周期后不变，更好的接近实际情况
reg SAMP_Z;
wire SAMP_POS;
always @(posedge clk_3p2M or negedge rst_n) begin
    if(~rst_n) begin
        SAMP_Z <= 1'b0;
    end else begin
        SAMP_Z <= SAMP;
    end
end
assign SAMP_POS = ~SAMP_Z & SAMP;

reg [5:0] clock_3p2M_cnt; //计数到32
always @(posedge clk_3p2M or negedge rst_n) begin
    if(~rst_n) begin
        clock_3p2M_cnt <= {{(5){1'b1}}};
    end else begin
        if (SAMP_POS == 1'b1) begin
            clock_3p2M_cnt <= 0;
        end else if (clock_3p2M_cnt == 6'b10_0010) begin
            clock_3p2M_cnt <= clock_3p2M_cnt;
        end else begin
            clock_3p2M_cnt <= clock_3p2M_cnt + 1;
        end
    end
end
//检测SAMP上升沿，data_from_pre输出变化，32个周期后不变，更好的接近实际情况
always @(posedge clk_3p2M or negedge rst_n) begin
	if(~rst_n) begin
		data_from_pre <= 'b0;
	end else begin
		if (clock_3p2M_cnt == {{(5){1'b1}}}) begin
			data_from_pre <= {{(DATA_LENGTHS){1'b1}}};
		end else begin
			data_from_pre <= data_from_pre + 'd45;

		end
	end
end
*/
/*
//检测SAMP上升沿，data_from_pre输出变化，32个周期后不变，更好的接近实际情况
always @(posedge clk_3p2M or negedge rst_n) begin
	if(~rst_n) begin
		data_from_pre <= 'b0;
	end else begin
		if (block_digital.daisy_chain.block_cnt == 6'h21) begin
			data_from_pre <= {{(DATA_LENGTHS){1'b1}}};
		end else begin
			data_from_pre <= data_from_pre + 'd45;

		end
	end
end
*/
/*reg [11:0] adc_data_temp;
initial begin
	adc_data_temp = 12'b1011_0000_1111_0100;
	forever begin
		@(posedge block_digital.daisy_chain.adc_ready)
		force block_digital.daisy_chain.data_from_adc0 = adc_data_temp;
		force block_digital.daisy_chain.data_from_adc1 = adc_data_temp+45;
		force block_digital.daisy_chain.data_from_adc2 = adc_data_temp+821;
		force block_digital.daisy_chain.data_from_adc3 = adc_data_temp+120;
		adc_data_temp = adc_data_temp+345;
	end
	//data_out_temp = 16'b1;
end
*/
//比较器输出一直在变，更好的接近实际情况
reg  [3:0]  COMP;
always @(posedge clk_3p2M or negedge rst_n) begin
	if(~rst_n) begin
		COMP <= 'b0;
	end else begin
		COMP <= {$random} % 16;
		// $display("COMP: %d",COMP);
	end
end

//模拟CB_OK拉高
//reg [SPI_DATA_LEN-1:0] data_out_temp;
integer cb_ok_cnt;
initial begin //1243 us 读
	AMP_OUT_0 = 1'b0;
	AMP_OUT_1 = 1'b0;
	AMP_OUT_2 = 1'b0;
	AMP_OUT_3 = 1'b0;
	
/*	cb_ok_cnt = 0;
	@(posedge block_digital.CB_Logic_i2.CB_ON)
	while(cb_ok_cnt<60)begin
		AMP_OUT_2 = 1'b0;
		#3000
		AMP_OUT_2 = 1'b1;
		#3000
		cb_ok_cnt = cb_ok_cnt+1;
	end
	cb_ok_cnt = 0;

	@(posedge block_digital.CB_Logic_i2.CB_ON)
	while(cb_ok_cnt<60)begin
		AMP_OUT_2 = 1'b1;
		#3000
		AMP_OUT_2 = 1'b0;
		#3000
		cb_ok_cnt = cb_ok_cnt+1;
	end
	cb_ok_cnt = 0;

	force block_digital.fsm_block.data_adc_buffer[0] = 1'b1;
	#1543000
	force block_digital.CB_Logic_i2.CB_OK = 1'b1;
	#40000
	//release block_digital.CB_Logic_i2.CB_OK;

	force block_digital.CB_Logic_i2.CB_OK = 1'b0;
	#1100000
	force block_digital.CB_Logic_i2.CB_OK = 1'b1;
	//data_out_temp = 16'b1;
*/
	#500000
	AMP_OUT_2 = 1'b1;
	#100000
	AMP_OUT_2 = 1'b0;

	#300000
	AMP_OUT_2 = 1'b1;
	#1100000
	AMP_OUT_2 = 1'b0;

end
//assign data_out = data_out_temp;

initial begin 
	chem_out = 8'b0;
	#3000
	chem_out = 8'b0000_0001;
	#3000
	chem_out = 8'b0000_0011;
	#3000
	chem_out = 8'b0000_0111;
	#3000
	chem_out = 8'b0000_1111;
	#3000
	chem_out = 8'b0001_1111;
	#3000
	chem_out = 8'b0011_1111;
	#3000
	chem_out = 8'b0111_1111;
	#3000
	chem_out = 8'b1111_1111;
	#2000
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
	.rst_n(rst_n),          // Asynchronous reset active low

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

wire [BITS_ADC:0] daisy_chain[ROW_BLOCK_NUM:0];

assign daisy_chain[0] = {(BITS_ADC+1){1'b1}};
assign data_from_pre = daisy_chain[ROW_BLOCK_NUM-1];
assign daisy_chain[ROW_BLOCK_NUM] = data_to_post;

generate
	genvar i;
	for (i = 0; i < ROW_BLOCK_NUM-1; i=i+1) begin : block_e
FSM_BLOCK fsm_block(
	.clk(clk_3p2M),
	.rst_n(rst_n),

    .adc_ready(SAMP),       // ADC data ready, posedge valid
    .data_from_adc0(i),  // data from CH0
    .data_from_adc1(i+16),  // data from CH1
    .data_from_adc2(i+32),  // data from CH2
    .data_from_adc3(i+48),  // data from CH3
    .data_from_pre(daisy_chain[i]),   // data from pre BLOCK
    .data_to_post(daisy_chain[i+1])   // data to post BLOCK
    /** remove other useless port declare **/
);
	end
endgenerate
/*
// monitor AFE REG
initial begin
	$monitor("Rec_0,Rec_1,Rec_2,Rec_3 in BLOCK %b %b %b %b",
		block_digital.fsm_block.Rec_0,
		block_digital.fsm_block.Rec_1,
		block_digital.fsm_block.Rec_2,
		block_digital.fsm_block.Rec_3
	);
end
*/
// monitor STIM REG

endmodule

