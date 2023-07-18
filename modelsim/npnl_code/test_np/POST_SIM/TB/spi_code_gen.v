//Verilog HDL for "BMI_2022_NeuralLink_TOP_sim_v1", "spi_code_gen" "functional"
// add elec control cmd 2022/06/18
// adjust cmd 
// after change ELEC, reset AFE and remove reset, set different channel in different mode(Gain and Hp). 2022/06/20

`timescale 1ns/10ps
module spi_code_gen (
	clk_50M,
	rst_n,
	
	reg_map_addr,

	sck, 
	mosi,
	miso, 
	cs_n
);

//`include "parameter.v"
parameter LEN_SPI = 32 ; //packet data only after decoding and header removeal
parameter SPI_ADDR_LEN = 10;
parameter SPI_DATA_LEN = 16;
parameter SPI_CODE_LEN = 6;

parameter BITS_ADC = 12;

localparam FSM_CLK_PERIOD = 26;
localparam FSM_CLK_HALF_PERIOD = FSM_CLK_PERIOD/2;
localparam SPI_CLK_PERIOD = 200;
localparam SPI_CLK_HALF_PERIOD = SPI_CLK_PERIOD/2;

/*************************************************************
*                         CMD table                          *
**************************************************************
0  									16 ： Write Ele. Neurallink			
1  : Read REC.						17 ： Read Ele. Neurallink			
2  : Read Switch					18 ： CB_OK拉低			
3  : Read Stim.						19 ： Read ADC data			
4  : Write REC.						20 ： Write ChemEle. Neuralpixel			
5  : Write D_HP.					21 ： Read  ChemEle. Neuralpixel			
6  : Write Stim.					22 ： Global ChemEle. Reset	
7  : Global AFE Reset				23 ： Write Ele Cache. Neuralpixel			
8  : Global AFE remove Reset		24 ： Write Chem Ele Cache. Neuralpixel			
9  : Global DAC turn on STIM		25 ： 			
10 : Write Ele. Neuralpixel			26 ： 			
11 : Read Ele. Neuralpixel			27 ： 			
12 : Global Ele. Reset				28 ： 			
13 : Global DAC turn off stim		29 ： 			
14 : Write Sample rate				30 ： 			
15 : Read Sample rate				31 ： 			
**************************************************************
**************************************************************/

output reg clk_50M;
output reg rst_n;
output reg sck, mosi, cs_n;
input wire miso;

output [64*8-1:0] reg_map_addr;

reg  elec_reg0;

/*************************************************************/
initial begin
    clk_50M = 1'b0;
    forever begin
        #FSM_CLK_HALF_PERIOD clk_50M = ~clk_50M; //50MHz
    end
end

// initial begin
//     sck = 1'b0;
//     forever begin
//         #SPI_CLK_HALF_PERIOD sck = ~sck; //5MHz
//     end
// end


initial begin
	// reset function test
    rst_n = 1'b0;
    #(273) rst_n = 1'b1;
end

// Asynchronous reset, synchronous release
// output reg rst_asyn_n;
// always @(posedge clk_50M or negedge rst_n) begin
// 	if(~rst_n) begin
// 		rst_asyn_n <= 0;
// 	end else begin
// 		rst_asyn_n <= 1'b1;
// 	end
// end
// reg_map_addr initial
generate
	genvar ii;
	for(ii=0;ii<64;ii=ii+1)begin
		assign reg_map_addr[ii*8+7:ii*8] = ii;
	end
endgenerate


integer i,j;

reg [31:0] read_data_out;

/**************************************
* sck period             : 200ns
* spi data packet period : 6.4us
*
**************************************/
integer m;
integer adc_data_gen_f,adc_data_result_f,err,str;
initial begin
	adc_data_gen_f    = $fopen("adc_data_gen.txt","w");
	adc_data_result_f = $fopen("adc_data_result.txt","w");
	err = $ferror(adc_data_gen_f,str);
	if(!err) begin
		$display("adc_data_gen.txt File open success");
	end
    elec_reg0 <= 1'b0;
	read_data_out <= 32'b0;
	sck = 1'b1;
    cs_n <= 1'b1;
	mosi <= 0;
	#2000 
	/*************************************************************************************
	*                                 AFE function test                                  *
	*************************************************************************************/ 
	$display("NeuralLink SPI CMD begin!");

	Write_Register({6'd8,10'd4,16'b0},read_data_out); // Remove global AFE reset, just CMD high 6 bit valid
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#64000

	Write_Register({6'd4,{8'd2,2'd0},16'b0000_0_0_000_0_0_1110_1},read_data_out); // set BLOCK2-CH0, EN_HP 0, EN_GAIN 0;
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd4,{8'd2,2'd0},16'b0000_0_0_000_0_0_1110_1 | 16'b0000_1_0_000_00_0000_0},read_data_out); // remove reset BLOCK2-CH0
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd4,{8'd2,2'd1},16'b0000_0_0_000_0_1_1101_0},read_data_out); // set BLOCK2-CH1, EN_HP 0, EN_GAIN 1;
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd4,{8'd2,2'd1},16'b0000_0_0_000_0_1_1101_0 | 16'b0000_1_0_000_00_0000_0},read_data_out); // remove reset BLOCK2-CH0
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd4,{8'd2,2'd2},16'b0000_0_0_000_1_0_1011_0},read_data_out); // set BLOCK2-CH2, EN_HP 1, EN_GAIN 0;
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd4,{8'd2,2'd2},16'b0000_0_0_000_1_0_1011_0 | 16'b0000_1_0_000_00_0000_0},read_data_out); // remove reset BLOCK2-CH0
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd4,{8'd2,2'd3},16'b0000_0_0_000_1_1_1000_0},read_data_out); // set BLOCK2-CH3, EN_HP 1, EN_GAIN 1;
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd4,{8'd2,2'd3},16'b0000_0_0_000_1_1_1000_0 | 16'b0000_1_0_000_00_0000_0},read_data_out); // remove reset BLOCK2-CH0
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	$display("AFE Config OK!!!");
	#80000 // 80us


	/**********************************************************************
	*                       ELEC function test Neural pixel               *
	**********************************************************************/ 
	// ELE group 0 test
	Write_Register({6'd24,10'd0,16'b0101_0101_1110_1101},read_data_out); //send wirte elec chem cache code
	Write_Register({6'd23,10'd0,16'b1111_0000_0010_1101},read_data_out); //send wirte elec cache code
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd20,10'd0,16'd0},read_data_out); // wirte elec chem
	Write_Register({6'd0,10'd0,16'b0},read_data_out);  // dummy spi
	$display("Write out to CHEM ELEC in probe");
	#250000
	Write_Register({6'd21,10'd0,16'd0},read_data_out); // read elec chem
	Write_Register({6'd0,10'd0,16'b0},read_data_out);  // dummy spi
	$display("Read CHEM ELEC REG RAM");
	#250000 // waiting for reading finish
	
	Write_Register({6'd21,10'd0,16'd0},read_data_out); // read elec chem
	Write_Register({6'd21,10'd0,16'd0},read_data_out); // read elec chem
	Write_Register({6'd21,10'd0,16'd0},read_data_out); // read elec chem

	/****************************/ 
	Write_Register({6'd10,10'd0,16'd0},read_data_out); // wirte elec
	Write_Register({6'd0,10'd0,16'b0},read_data_out);  // dummy spi
	$display("Write out to ELEC in probe");
	#250000
	Write_Register({6'd11,10'd0,16'd0},read_data_out); // read elec
	Write_Register({6'd0,10'd0,16'b0},read_data_out);  // dummy spi
	$display("Read CHEM ELEC REG RAM");
	#250000
	Write_Register({6'd11,10'd0,16'd0},read_data_out); // read elec
	Write_Register({6'd11,10'd0,16'd0},read_data_out); // read elec
	Write_Register({6'd11,10'd0,16'd0},read_data_out); // read elec


	// reset REG in probe
	Write_Register({6'd12,10'd0,16'b0},read_data_out); //send reset elec code
	Write_Register({6'd22,10'd0,16'b0},read_data_out); //send reset elec chem code

	/**********************************************************************
	*                       ADC data read out test                        *
	**********************************************************************/ 
	Write_Register({6'd19,{8'd2,2'd3},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd3},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd3},16'b0},read_data_out);//read ADC

	Write_Register({6'd19,{8'd2,2'd2},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd2},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd2},16'b0},read_data_out);//read ADC

	Write_Register({6'd19,{8'd2,2'd1},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd1},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd1},16'b0},read_data_out);//read ADC

	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC
	Write_Register({6'd12,10'd0,16'b0},read_data_out); //send reset elec code
	Write_Register({6'd22,10'd0,16'b0},read_data_out); //send reset elec chem code
	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC
	Write_Register({6'd19,{8'd2,2'd0},16'b0},read_data_out);//read ADC

	#80000 
	$fclose(adc_data_gen_f);
	$fclose(adc_data_result_f);
	$finish;
end


always @(posedge block_e[0].fsm_block.adc_ready_pos or negedge rst_n) begin
	if(~rst_n) begin
		// <= 0;
	end else begin
		$fdisplay(adc_data_gen_f,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h ",
			block_e[0].fsm_block.data_from_adc0, block_e[0].fsm_block.data_from_adc1, block_e[0].fsm_block.data_from_adc2, block_e[0].fsm_block.data_from_adc3,
			block_e[1].fsm_block.data_from_adc0, block_e[1].fsm_block.data_from_adc1, block_e[1].fsm_block.data_from_adc2, block_e[1].fsm_block.data_from_adc3,
			block_e[2].fsm_block.data_from_adc0, block_e[2].fsm_block.data_from_adc1, block_e[2].fsm_block.data_from_adc2, block_e[2].fsm_block.data_from_adc3,
			block_e[3].fsm_block.data_from_adc0, block_e[3].fsm_block.data_from_adc1, block_e[3].fsm_block.data_from_adc2, block_e[3].fsm_block.data_from_adc3,
			block_e[4].fsm_block.data_from_adc0, block_e[4].fsm_block.data_from_adc1, block_e[4].fsm_block.data_from_adc2, block_e[4].fsm_block.data_from_adc3,
			block_e[5].fsm_block.data_from_adc0, block_e[5].fsm_block.data_from_adc1, block_e[5].fsm_block.data_from_adc2, block_e[5].fsm_block.data_from_adc3,
			block_e[6].fsm_block.data_from_adc0, block_e[6].fsm_block.data_from_adc1, block_e[6].fsm_block.data_from_adc2, block_e[6].fsm_block.data_from_adc3,
			block_digital.fsm_block.data_from_adc0, block_digital.fsm_block.data_from_adc1, block_digital.fsm_block.data_from_adc2, block_digital.fsm_block.data_from_adc3
			); 
	end
end

always @(posedge s2p.data_valid or negedge rst_n) begin
	if(~rst_n) begin
		// <= 0;
	end else begin
		$fdisplay(adc_data_result_f,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h ",
			s2p.data_from_blk_0_ch_0, s2p.data_from_blk_0_ch_1, s2p.data_from_blk_0_ch_2, s2p.data_from_blk_0_ch_3,
			s2p.data_from_blk_1_ch_0, s2p.data_from_blk_1_ch_1, s2p.data_from_blk_1_ch_2, s2p.data_from_blk_1_ch_3,
			s2p.data_from_blk_2_ch_0, s2p.data_from_blk_2_ch_1, s2p.data_from_blk_2_ch_2, s2p.data_from_blk_2_ch_3,
			s2p.data_from_blk_3_ch_0, s2p.data_from_blk_3_ch_1, s2p.data_from_blk_3_ch_2, s2p.data_from_blk_3_ch_3,
			s2p.data_from_blk_4_ch_0, s2p.data_from_blk_4_ch_1, s2p.data_from_blk_4_ch_2, s2p.data_from_blk_4_ch_3,
			s2p.data_from_blk_5_ch_0, s2p.data_from_blk_5_ch_1, s2p.data_from_blk_5_ch_2, s2p.data_from_blk_5_ch_3,
			s2p.data_from_blk_6_ch_0, s2p.data_from_blk_6_ch_1, s2p.data_from_blk_6_ch_2, s2p.data_from_blk_6_ch_3,
			s2p.data_from_blk_7_ch_0, s2p.data_from_blk_7_ch_1, s2p.data_from_blk_7_ch_2, s2p.data_from_blk_7_ch_3
			); 
	end
end




task Write_Register;
	input  [LEN_SPI-1:0] spi_data_w; 
	output [LEN_SPI-1:0] spi_data_r; 
    integer i;
    begin
        #SPI_CLK_HALF_PERIOD;
        cs_n = 0;
        sck = 1;
        // spi_master_data_ready<=0;
        for (i = 0 ; i<LEN_SPI; i=i+1 ) begin
            mosi = spi_data_w[i];
            #SPI_CLK_HALF_PERIOD sck = 0;
            spi_data_r[i] = miso ;
            #SPI_CLK_HALF_PERIOD sck = 1;
        end
        // spi_master_data_ready =1;
        mosi = 0;
        #SPI_CLK_HALF_PERIOD;
        cs_n = 1;
        #SPI_CLK_HALF_PERIOD;
	end
endtask

// task Write_Register({input [SPI_CODE_LEN-1:0] code, input [SPI_ADDR_LEN-1:0] addr, input [SPI_DATA_LEN-1:0] data);   
// 	begin
// 	//16bitdata
// 	for(i=SPI_DATA_LEN-1;i>=0;i=i-1) begin
// 		mosi=data[SPI_DATA_LEN-1-i];
// 		@(posedge sck);
// 	end
// 	//10bitaddr
// 	for(i=SPI_ADDR_LEN-1;i>=0;i=i-1) begin
// 		mosi=addr[SPI_ADDR_LEN-1-i];
// 		@(posedge sck);
// 	end	
// 	//Code
// 	for(i=SPI_CODE_LEN-1;i>=0;i=i-1) begin
// 		mosi=code[SPI_CODE_LEN-1-i];
// 		@(posedge sck);
// 	end	
// 	end
// endtask





endmodule
