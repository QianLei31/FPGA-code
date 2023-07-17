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
integer fd,err,str;
initial begin
	fd = $fopen("result.txt","w");
	err = $ferror(fd,str);
	if(!err) begin
		$display("File open success");
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

	Write_Register({6'd16,{8'd2,2'd0},16'b0110_1001_0001_0000},read_data_out); // NL MUX
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


	/*************************************************************************************
	*                                   DAC function test                                *
	**************************************************************************************/

	// DAC parameter: OFF_STIM + CH[1:0] + AMP_X50 + comp_en + Pol[1:0] + STIM_AMP[8:0]
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_1_00_100000000},read_data_out); // BLOCK2-CH2-ELE1, Compensate first
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_00_100000000},read_data_out); // BLOCK2-CH2-ELE1, Comp set low
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	$display("READING CB_OK!");
	read_data_out <= 32'b0;
	while(read_data_out[0] === 1'b0 || read_data_out[0] === 1'bz)begin
		Write_Register({6'd3,{8'd2,2'd2},16'b0},read_data_out);// Read Register
	end
	$display("read_data_out: %b",read_data_out);
	Write_Register({6'd18,{8'd2,2'd2},16'b0},read_data_out); // test[19]: Set CB_OK Low;
	//read_data_out <= 32'b0;
    // begin stim
	// spi_cmd_cnt <= spi_cmd_cnt + 1'b1;
	$display("STIM --> 1");
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_01_101000000},read_data_out); // BLOCK2-CH2-ELE1, stim negedge 101000000
	$display("Write Stim, BLOCK2-CH2-ELE1: Stim Current POL: N ; AMP:62.5uA, finish!!!");
	#12800	// delay 12.8us

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_00_101000000},read_data_out); // BLOCK2-CH2-ELE1, output 0
	#3200	// delay 32us

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_10_101000000},read_data_out); // BLOCK2-CH2-ELE1, stim posedge, AMP*50
	$display("Write Stim, BLOCK2-CH2-ELE1: Stim Current POL: P ; AMP:62.5uA, finish!!!");
	#12800	// delay 128us

	$display("STIM --> 2");
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_01_001000000},read_data_out); // BLOCK2-CH2-ELE1, stim negedge
	$display("Write Stim, BLOCK2-CH2-ELE1: Stim Current POL: N ; AMP:12.5uA, finish!!!");
	#12800	// delay 128us

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_00_001000000},read_data_out); // BLOCK2-CH2-ELE1, output 0
	#3200	// delay 32us

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_10_111000000},read_data_out); // BLOCK2-CH2-ELE1, stim posedge, AMP*50
	#12800	// delay 128us

	$display("STIM --> 3");
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_01_000001000},read_data_out); // BLOCK2-CH2-ELE1, stim negedge
	#12800	// delay 128us

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_00_000001000},read_data_out); // BLOCK2-CH2-ELE1, output 0
	#3200	// delay 32us

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_10_000001000},read_data_out); // BLOCK2-CH2-ELE1, stim posedge, AMP*50
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#12800	// delay 128us
	
	// DAC parameter: OFF_STIM + CH[1:0] + AMP_X50 + comp_en + Pol[1:0] + STIM_AMP[8:0]
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_1_00_010000000},read_data_out); // BLOCK2-CH2-ELE1, compensate after first stim
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_1_0_00_010000000},read_data_out); // test[11]: BLOCK2-CH2-ELE1, comp_en low
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	$display("READING CB_OK --> 2");
	read_data_out = 32'b0;
	Write_Register({6'd3,{8'd2,2'd2},16'b0},read_data_out);//read DAC
	Write_Register({6'd3,{8'd2,2'd2},16'b0},read_data_out);//read DAC
	Write_Register({6'd3,{8'd2,2'd2},16'b0},read_data_out);//read DAC
	while(read_data_out[0] === 1'b0 || read_data_out[0] === 1'bx)begin
		Write_Register({6'd3,{8'd2,2'd2},16'b0},read_data_out);//read DAC
	end 

	$display("read_data_out: %b",read_data_out);
	Write_Register({6'd18,{8'd2,2'd2},16'b0},read_data_out); // test[19]: Set CB_OK Low;
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_0_0_01_101000000},read_data_out); // BLOCK2-CH2-ELE1, stim negedge, AMP*0.5
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#12800	// delay 128us
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_0_0_00_101000000},read_data_out); // test[13]: BLOCK2-CH2-ELE1, output 0, AMP*0.5
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#3200	// delay 32us
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_0_0_10_101000000},read_data_out); // test[14]: BLOCK2-CH2-ELE1, stim posedge, AMP*0.5
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#12800	// delay 128us

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_0_0_01_111000000},read_data_out); // test[12]: BLOCK2-CH2-ELE1, stim negedge, AMP*0.5
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#12800	// delay 128us
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_0_0_00_101000000},read_data_out); // test[13]: BLOCK2-CH2-ELE1, output 0, AMP*0.5
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#3200	// delay 32us
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_0_0_10_001000000},read_data_out); // test[14]: BLOCK2-CH2-ELE1, stim posedge, AMP*0.5
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#12800	// delay 128us

	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_0_0_01_101001111},read_data_out); // test[12]: BLOCK2-CH2-ELE1, stim negedge, AMP*0.5
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#12800	// delay 128us
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_0_0_00_101010000},read_data_out); // test[13]: BLOCK2-CH2-ELE1, output 0, AMP*0.5
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#3200	// delay 32us
	Write_Register({6'd6,{8'd2,2'd2},16'b0_01_0_0_10_111111111},read_data_out); // test[14]: BLOCK2-CH2-ELE1, stim posedge, AMP*0.5
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi
	#12800	// delay 128us


	Write_Register({6'd6,{8'd2,2'd2},16'b1_01_0_0_10_101000000},read_data_out); // close stim
	Write_Register({6'd0,10'd0,16'b0},read_data_out); // dummy spi

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

	Write_Register({6'd17,{8'd2,2'd0},16'b0},read_data_out);//read MUX
	Write_Register({6'd17,{8'd2,2'd0},16'b0},read_data_out);//read MUX
	Write_Register({6'd17,{8'd2,2'd0},16'b0},read_data_out);//read MUX

	Write_Register({6'd17,{8'd2,2'd0},16'b0},read_data_out);//read MUX
	Write_Register({6'd17,{8'd2,2'd0},16'b0},read_data_out);//read MUX
	Write_Register({6'd17,{8'd2,2'd0},16'b0},read_data_out);//read MUX

	#80000
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
