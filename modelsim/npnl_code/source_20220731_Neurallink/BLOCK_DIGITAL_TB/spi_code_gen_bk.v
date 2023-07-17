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

localparam FSM_CLK_PERIOD = 16;
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

initial begin
    sck = 1'b0;
    forever begin
        #SPI_CLK_HALF_PERIOD sck = ~sck; //5MHz
    end
end


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
reg [31:0] spi_cmd[31:0];
reg [31:0] spi_cmd_cnt;
reg [31:0] read_data_out;
/*
initial begin 
	$readmemb("./memory.list",spi_cmd);
	//$readmemb("/proj/BMI/guotongtong/analog/XT018_pro/1_CMD_LIST/memory.list",spi_cmd);
	for(j=0;j<=21;j=j+1)begin//
		$display("spi_cmd: %b",spi_cmd[j]);
	end
end
*/
/**************************************
* sck period             : 200ns
* spi data packet period : 6.4us
*
**************************************/
integer m;
reg [511:0] elec_data_read;
reg [15:0] elec_data_write;
integer fd,err,str;
initial begin
	fd = $fopen("result.txt","w");
	err = $ferror(fd,str);
	if(!err) begin
		$display("File open success");
	end
    elec_reg0 <= 1'b0;
	read_data_out <= 32'b0;
	elec_data_write <= 16'b0;
	elec_data_read <= 512'b0;
    cs_n <= 1'b1;
	mosi <= 0;
	spi_cmd_cnt <= 'b0;
	#2000 
	@(posedge sck);
	// $display("ddddddddddd %h",block_digital.fsm_block.DAC_0);
	/*************************************************************************************
	*                                 AFE function test                                  *
	*************************************************************************************/ 
	$display("NeuralLink SPI CMD begin!");

	cs_n <= 1'b0;

//	$monitor("
// Rec_0 = %b;
// Rec_1 = %b;
// Rec_2 = %b;
// Rec_3 = %b ",
//		block_digital.fsm_block.Rec_0,
//		block_digital.fsm_block.Rec_1,
//		block_digital.fsm_block.Rec_2,
//		block_digital.fsm_block.Rec_3
//	);
	Write_Register(6'b10_1101,10'd6,16'b0110_11010010_1101); // Remove global AFE reset, just CMD high 6 bit valid
	cs_n <= 1'b1;

	repeat(32) @(posedge sck);
	cs_n <= 1'b0;
	Write_Register(6'd8,10'd4,16'b0); // Remove global AFE reset, just CMD high 6 bit valid
	//$display("fsm_block.Rec_0 = %h",block_digital.fsm_block.Rec_0);
	//$display("fsm_block.Rec_0 = %h",block_digital.fsm_block.Rec_1);
	//$display("fsm_block.Rec_0 = %h",block_digital.fsm_block.Rec_2);
	//$display("fsm_block.Rec_0 = %h",block_digital.fsm_block.Rec_3);
	$display("Remove global AFE reset finish!!!");
	repeat(2*32) @(posedge sck);

	Write_Register(6'd4,{8'd2,2'd0},16'b0000_0_0_000_0_0_1110_0); // set BLOCK2-CH0, EN_HP 0, EN_GAIN 0;
	$display("Write REC, BLOCK2-CH0 finish!!!");
	repeat(10*32) @(posedge sck);
	Write_Register(6'd4,{8'd2,2'd0},16'b0000_0_0_000_0_0_1110_0 | 16'b0000_1_0_000_00_0000_0); // remove reset BLOCK2-CH0
	repeat(2*32) @(posedge sck);

	Write_Register(6'd4,{8'd2,2'd1},16'b0000_0_0_000_0_1_1101_0); // set BLOCK2-CH1, EN_HP 0, EN_GAIN 1;
	$display("Write REC, BLOCK2-CH1 finish!!!");
	repeat(10*32) @(posedge sck);
	Write_Register(6'd4,{8'd2,2'd1},16'b0000_0_0_000_0_1_1101_0 | 16'b0000_1_0_000_00_0000_0); // remove reset BLOCK2-CH0
	repeat(2*32) @(posedge sck);

	Write_Register(6'd4,{8'd2,2'd2},16'b0000_0_0_000_1_0_1011_0); // set BLOCK2-CH2, EN_HP 1, EN_GAIN 0;
	$display("Write REC, BLOCK2-CH2 finish!!!");
	repeat(10*32) @(posedge sck);
	Write_Register(6'd4,{8'd2,2'd2},16'b0000_0_0_000_1_0_1011_0 | 16'b0000_1_0_000_00_0000_0); // remove reset BLOCK2-CH0
	repeat(2*32) @(posedge sck);

	Write_Register(6'd4,{8'd2,2'd3},16'b0000_0_0_000_1_1_1000_0); // set BLOCK2-CH3, EN_HP 1, EN_GAIN 1;
	$display("Write REC, BLOCK2-CH3 finish!!!");
	repeat(10*32) @(posedge sck);
	Write_Register(6'd4,{8'd2,2'd3},16'b0000_0_0_000_1_1_1000_0 | 16'b0000_1_0_000_00_0000_0); // remove reset BLOCK2-CH0
	repeat(2*32) @(posedge sck);

	repeat(128*32) @(posedge sck);//4096*200ns=0.8192ms
	$display("AFE Config OK!!!");

	Write_Register(6'd4,{8'd3,2'd3},16'b0000_0_0_000_1_1_1000_0); // change reg_map addr, test reg_map_addr;
	repeat(2*32) @(posedge sck);

	/*************************************************************************************
	*                                   DAC function test                                *
	**************************************************************************************/
//	$monitor("
// DAC_0 = %b;
// DAC_1 = %b;
// DAC_2 = %b;
// DAC_3 = %b;",
//		block_digital.fsm_block.DAC_0,
//		block_digital.fsm_block.DAC_1,
//		block_digital.fsm_block.DAC_2,
//		block_digital.fsm_block.DAC_3
//	);

	// DAC parameter: OFF_STIM + CH[1:0] + AMP_X50 + comp_en + Pol[1:0] + STIM_AMP[8:0]
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_1_00_100000000); // BLOCK2-CH2-ELE1, Compensate first
	$display("Write Stim, BLOCK2-CH2-ELE1: Compensate first. Current AMP:50uA, finish!!!");
	repeat(2*32) @(posedge sck);	
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_00_100000000); // BLOCK2-CH2-ELE1, Comp set low
	repeat(2*32) @(posedge sck);

	$display("READING CB_OK!");
	while(read_data_out[0] === 1'b0 || read_data_out[0] === 1'bz)begin
		Write_Register(6'd3,{8'd2,2'd2},16'b0);// Read Register
		$display("Read Stim, BLOCK2-CH2 ");
		repeat(32) @(posedge sck);
		for(m=SPI_DATA_LEN-1;m>=0;m=m-1) begin
 			@(negedge sck);
 			read_data_out[SPI_DATA_LEN-1-m] = miso;
		end
		repeat(32-SPI_DATA_LEN) @(negedge sck);
		@(posedge sck);
	end
	$display("read_data_out: %b",read_data_out);
	Write_Register(6'd18,{8'd2,2'd2},16'b0); // test[19]: Set CB_OK Low;
	read_data_out <= 32'b0;
    // begin stim
	// spi_cmd_cnt <= spi_cmd_cnt + 1'b1;
	repeat(2*32) @(posedge sck);	
	$display("STIM --> 1");
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_01_101000000); // BLOCK2-CH2-ELE1, stim negedge 101000000
	$display("Write Stim, BLOCK2-CH2-ELE1: Stim Current POL: N ; AMP:62.5uA, finish!!!");
	repeat(20*32) @(posedge sck);	// delay 128us

	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_00_101000000); // BLOCK2-CH2-ELE1, output 0
	repeat(5*32) @(posedge sck);	// delay 32us

	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_10_101000000); // BLOCK2-CH2-ELE1, stim posedge, AMP*50
	$display("Write Stim, BLOCK2-CH2-ELE1: Stim Current POL: P ; AMP:62.5uA, finish!!!");
	repeat(20*32) @(posedge sck);	// delay 128us

	$display("STIM --> 2");
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_01_001000000); // BLOCK2-CH2-ELE1, stim negedge
	$display("Write Stim, BLOCK2-CH2-ELE1: Stim Current POL: N ; AMP:12.5uA, finish!!!");
	repeat(20*32) @(posedge sck);	// delay 128us

	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_00_001000000); // BLOCK2-CH2-ELE1, output 0
	repeat(5*32) @(posedge sck);	// delay 32us

	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_10_111000000); // BLOCK2-CH2-ELE1, stim posedge, AMP*50
	repeat(20*32) @(posedge sck);	// delay 128us

	$display("STIM --> 3");
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_01_000001000); // BLOCK2-CH2-ELE1, stim negedge
	repeat(20*32) @(posedge sck);	// delay 128us

	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_00_000001000); // BLOCK2-CH2-ELE1, output 0
	repeat(5*32) @(posedge sck);	// delay 32us

	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_10_000001000); // BLOCK2-CH2-ELE1, stim posedge, AMP*50
	repeat(20*32) @(posedge sck);	// delay 128us
	

	// DAC parameter: OFF_STIM + CH[1:0] + AMP_X50 + comp_en + Pol[1:0] + STIM_AMP[8:0]
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_1_00_010000000); // BLOCK2-CH2-ELE1, compensate after first stim
	repeat(2*32) @(posedge sck);
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_1_0_00_010000000); // test[11]: BLOCK2-CH2-ELE1, comp_en low
	repeat(2*32) @(posedge sck);
	$display("READING CB_OK --> 2");
	while(read_data_out[0] === 1'b0 || read_data_out[0] === 1'bx)begin
		Write_Register(3,{8'd2,2'd2},16'b0);//read DAC
		repeat(32) @(posedge sck);
		for(m=SPI_DATA_LEN-1;m>=0;m=m-1) begin
 			@(negedge sck);
 			read_data_out[SPI_DATA_LEN-1-m] = miso;
		end
		repeat(32-SPI_DATA_LEN) @(negedge sck);
		@(posedge sck);	
	end 
	$display("read_data_out: %b",read_data_out);
	Write_Register(6'd18,{8'd2,2'd2},16'b0); // test[19]: Set CB_OK Low;
	read_data_out <= 32'b0;
	repeat(2*32) @(posedge sck);	

	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_0_0_01_101000000); // BLOCK2-CH2-ELE1, stim negedge, AMP*0.5
	repeat(6*32) @(posedge sck);	
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_0_0_00_101000000); // test[13]: BLOCK2-CH2-ELE1, output 0, AMP*0.5
	repeat(2*32) @(posedge sck);	
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_0_0_10_101000000); // test[14]: BLOCK2-CH2-ELE1, stim posedge, AMP*0.5
	repeat(6*32) @(posedge sck);

	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_0_0_01_111000000); // test[12]: BLOCK2-CH2-ELE1, stim negedge, AMP*0.5
	repeat(6*32) @(posedge sck);	
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_0_0_00_101000000); // test[13]: BLOCK2-CH2-ELE1, output 0, AMP*0.5
	repeat(2*32) @(posedge sck);	
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_0_0_10_001000000); // test[14]: BLOCK2-CH2-ELE1, stim posedge, AMP*0.5
	repeat(6*32) @(posedge sck);

	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_0_0_01_101001111); // test[12]: BLOCK2-CH2-ELE1, stim negedge, AMP*0.5
	repeat(6*32) @(posedge sck);	
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_0_0_00_101010000); // test[13]: BLOCK2-CH2-ELE1, output 0, AMP*0.5
	repeat(2*32) @(posedge sck);	
	Write_Register(6'd6,{8'd2,2'd2},16'b0_01_0_0_10_111111111); // test[14]: BLOCK2-CH2-ELE1, stim posedge, AMP*0.5
	repeat(6*32) @(posedge sck);


	Write_Register(6'd6,{8'd2,2'd2},16'b1_01_0_0_10_101000000); // close stim
	repeat(2*32) @(posedge sck);
	
	/**********************************************************************
	*                       ELEC function test Neural Link                *
	**********************************************************************/ 
/*	
	$display("ELEC function test Neural Link");
	Write_Register(6'd16,{8'd2,2'd0},16'b0110_1000_0001_0000); // test[20]: BLOCK ELE WRITE MUX,11_10_01_00 NeuralLink
	repeat(2*32) @(posedge sck);
	Write_Register(6'd17,{8'd2,2'd0},16'b0); // test[21]: BLOCK ELE READ MUX              NeuralLink
	repeat(32) @(posedge sck);
	for(m=SPI_DATA_LEN-1;m>=0;m=m-1) begin
 		@(negedge sck);
 		read_data_out[SPI_DATA_LEN-1-m] = miso;
	end
	repeat(32-SPI_DATA_LEN) @(negedge sck);
	@(posedge sck);	
	if(16'b0110_1000_0001_0000==read_data_out[15:0])begin
		$display("NeuralLink spi_cmd : %h",16'b0110_1000_0001_0000);
		$display("NeuralLink read_data_out[15:0]: %h",read_data_out);
		$display("NeuralLink elec write and read Success!"); 
	end else begin
		$display("NeuralLink spi_cmd : %h",16'b0110_1000_0001_0000);
		$display("NeuralLink read_data_out[15:0]: %h",read_data_out);
		$display("NeuralLink elec write and read Fail!");
	end

	// after write elec, reset AFE and remove reset
	Write_Register(6'd7,10'd0,16'b0); // global AFE reset, just CMD high 6 bit valid
	$display("Remove global AFE reset finish!!!");
	repeat(20*32) @(posedge sck);

	Write_Register(6'd8,10'd0,16'b0); // Remove global AFE reset, just CMD high 6 bit valid
	$display("Remove global AFE reset finish!!!");
	repeat(2*32) @(posedge sck);
*/
	/**********************************************************************
	*                       ELEC function test Neural pixel               *
	**********************************************************************/ 
	// ELE group 0 test
	Write_Register(6'd24,10'd0,16'b0101_0101_1110_1101); //send wirte elec chem code
	Write_Register(6'd23,10'd0,16'b1111_0000_0010_1101); //send wirte elec code
	Write_Register(6'd20,0,0);
	$display("Write out to CHEM ELEC in probe");
	repeat(32*8*12) @(posedge sck); //waiting for writing finish
	Write_Register(6'd21,10'd0,0);
	$display("Read CHEM ELEC REG RAM");
	repeat(32*8*12) @(posedge sck); //waiting for reading finish
	for(m=0;m<=15;m=m+1) begin
	@(negedge sck);
		read_data_out[m] = miso;
	end
	for(m=0;m<=15;m=m+1) begin
		@(negedge sck);
	end
	if(read_data_out==16'b0101_0101_1110_1101) begin
		$display("elec chem write and read Success!"); 
	end else begin
		$display("elec chem write and read Fail!");
	end
	@(posedge sck);

	/****************************/ 
	Write_Register(6'd10,0,0);
	$display("Write out to ELEC in probe");
	repeat(32*8*12) @(posedge sck); //waiting for writing finish
	Write_Register(6'd11,10'd0,0);
	$display("Read CHEM ELEC REG RAM");
	repeat(32*8*12) @(posedge sck); //waiting for reading finish
	for(m=0;m<=15;m=m+1) begin
	@(negedge sck);
		read_data_out[m] = miso;
	end
	for(m=0;m<=15;m=m+1) begin
		@(negedge sck);
	end
	if(read_data_out==16'b1111_0000_0010_1101) begin
		$display("elec write and read Success!"); 
	end else begin
		$display("elec write and read Fail!");
	end
	@(posedge sck);

	// ELE group 5 test
	Write_Register(6'd24,10'd5,16'b0101_1101_1010_1101); //send wirte elec chem code
	Write_Register(6'd23,10'd5,16'b1111_0111_0010_1101); //send wirte elec code
	Write_Register(6'd20,0,0);
	$display("Write out to CHEM ELEC in probe");
	repeat(32*8*12) @(posedge sck); //waiting for writing finish
	Write_Register(6'd21,10'd5,0);
	$display("Read CHEM ELEC REG RAM");
	repeat(32*8*12) @(posedge sck); //waiting for reading finish
	for(m=0;m<=15;m=m+1) begin
	@(negedge sck);
		read_data_out[m] = miso;
	end
	for(m=0;m<=15;m=m+1) begin
		@(negedge sck);
	end
	if(read_data_out==16'b0101_1101_1010_1101) begin
		$display("elec chem write and read Success!"); 
	end else begin
		$display("elec chem write and read Fail!");
	end
	@(posedge sck);

	/****************************/ 
	Write_Register(6'd10,0,0);
	$display("Write out to ELEC in probe");
	repeat(32*8*12) @(posedge sck); //waiting for writing finish
	Write_Register(6'd11,10'd5,0);
	$display("Read CHEM ELEC REG RAM");
	repeat(32*8*12) @(posedge sck); //waiting for reading finish
	for(m=0;m<=15;m=m+1) begin
	@(negedge sck);
		read_data_out[m] = miso;
	end
	for(m=0;m<=15;m=m+1) begin
		@(negedge sck);
	end
	if(read_data_out==16'b1111_0111_0010_1101) begin
		$display("elec write and read Success!"); 
	end else begin
		$display("elec write and read Fail!");
	end
	@(posedge sck);

	// reset REG in probe
	Write_Register(6'd12,10'd0,16'b0); //send reset elec code
	Write_Register(6'd22,10'd0,16'b0); //send reset elec chem code

	/**********************************************************************
	*                       ADC data read out test                        *
	**********************************************************************/ 
	Write_Register(6'd19,{8'd2,2'd3},16'b0);//read ADC
	repeat(32) @(posedge sck);
	for(m=SPI_DATA_LEN-1;m>=0;m=m-1) begin
 		@(negedge sck);
 		read_data_out[SPI_DATA_LEN-1-m] = miso;
	end
	repeat(32-SPI_DATA_LEN) @(negedge sck);
	@(posedge sck);	

	Write_Register(6'd19,{8'd2,2'd2},16'b0);//read ADC
	repeat(32) @(posedge sck);
	for(m=SPI_DATA_LEN-1;m>=0;m=m-1) begin
 		@(negedge sck);
 		read_data_out[SPI_DATA_LEN-1-m] = miso;
	end
	repeat(32-SPI_DATA_LEN) @(negedge sck);
	@(posedge sck);	

	Write_Register(6'd19,{8'd2,2'd1},16'b0);//read ADC
	repeat(32) @(posedge sck);
	for(m=SPI_DATA_LEN-1;m>=0;m=m-1) begin
 		@(negedge sck);
 		read_data_out[SPI_DATA_LEN-1-m] = miso;
	end
	repeat(32-SPI_DATA_LEN) @(negedge sck);
	@(posedge sck);	

	Write_Register(6'd19,{8'd2,2'd0},16'b0);//read ADC
	repeat(32) @(posedge sck);
	for(m=SPI_DATA_LEN-1;m>=0;m=m-1) begin
 		@(negedge sck);
 		read_data_out[SPI_DATA_LEN-1-m] = miso;
	end
	repeat(32-SPI_DATA_LEN) @(negedge sck);
	@(posedge sck);	

	cs_n <= 1'b1;
	repeat(128*32) @(posedge sck);//4096*200ns=0.8192ms
	$fclose(fd);
	$finish;
end


/* BMI_DIGITAL_TOP BMI_top(
	.clk_50M(clk_50M),  // system clock
	.rst_n(rst_n),      // Asynchronous reset active low
	
	// spi wire
	.sck(sck),
	.miso(miso),
	.mosi(mosi),
	.cs_n(cs_n),

	// elec control
	.data_to_elec(data_to_elec),
	.clk_to_elec(clk_to_elec),
	.rst_n_to_elec(rst_n_to_elec),
	.elec_reg0(elec_reg0),

	.s_data(s_data),
	.data_valid(data_valid)
); */

task Write_Register(input [SPI_CODE_LEN-1:0] code, input [SPI_ADDR_LEN-1:0] addr, input [SPI_DATA_LEN-1:0] data);   
	begin
	//16bitdata
	for(i=SPI_DATA_LEN-1;i>=0;i=i-1) begin
		mosi=data[SPI_DATA_LEN-1-i];
		@(posedge sck);
	end
	//10bitaddr
	for(i=SPI_ADDR_LEN-1;i>=0;i=i-1) begin
		mosi=addr[SPI_ADDR_LEN-1-i];
		@(posedge sck);
	end	
	//Code
	for(i=SPI_CODE_LEN-1;i>=0;i=i-1) begin
		mosi=code[SPI_CODE_LEN-1-i];
		@(posedge sck);
	end	
	end
endtask





endmodule
