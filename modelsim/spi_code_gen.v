//test_spi 

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

localparam FSM_CLK_PERIOD = 400;
localparam FSM_CLK_HALF_PERIOD = FSM_CLK_PERIOD/2;
localparam SPI_CLK_PERIOD = 4000;
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


generate
	genvar ii;
	for(ii=0;ii<64;ii=ii+1)begin
		assign reg_map_addr[ii*8+7:ii*8] = ii;
	end
endgenerate


integer j;
real i;
reg [31:0] read_data_out;
real dly_ns,dly_ns_display;
real ttt;
/**************************************
* sck period             : 200ns
* spi data packet period : 6.4us
*
**************************************/
parameter NUM_DLY = 1024;
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
	#2001 
	/*************************************************************************************
	*                                 AFE function test                                  *
	*************************************************************************************/ 
	$display("NeuralLink SPI CMD begin!");
	
		ttt=1.0;
	$display("dly resolution = %f",ttt*FSM_CLK_HALF_PERIOD/(NUM_DLY*2));
	//先把spi sck和clk_50M进行对齐，使得sck的上升沿/下降沿在clk_50M的下降沿，然后加入±延时
	for(i=0;i<NUM_DLY;i=i+1) begin
		
		@(posedge clk_50M); //align to 50MHz clock
		//@(negedge clk_50M); //align to 50MHz clock
		//dly_ns = (FSM_CLK_HALF_PERIOD+(i-NUM_DLY/2)*FSM_CLK_HALF_PERIOD/(NUM_DLY*2));
		dly_ns = (FSM_CLK_HALF_PERIOD+(i-NUM_DLY/2)/(NUM_DLY)*0.8*FSM_CLK_PERIOD);
		#(dly_ns);
		dly_ns_display=dly_ns-FSM_CLK_HALF_PERIOD;

		$display("pos edge of sck aligned to NEG edge of clk with dly_ns = %f",dly_ns_display);
		#(SPI_CLK_HALF_PERIOD)
		//Write_Register({6'd8,10'd4,16'b0},read_data_out); // Remove global AFE reset, just CMD high 6 bit valid
		Write_Register({6'd19,{8'd2,2'd2},16'b0},read_data_out);//read ADC
	end
	
	#80000 
	$fclose(adc_data_gen_f);
	$fclose(adc_data_result_f);
	$finish;
end






task Write_Register;
	input  [LEN_SPI-1:0] spi_data_w; 
	output [LEN_SPI-1:0] spi_data_r; 
    integer i;
	integer dly_mosi;
    begin
        #(SPI_CLK_PERIOD*2);
        #SPI_CLK_HALF_PERIOD;
        cs_n = 0;
        sck = 1;
        #(SPI_CLK_PERIOD*2);

		
	    dly_mosi=$urandom%10;//对MOSI的输入加入随机延时
        // spi_master_data_ready<=0;
        for (i = 0 ; i<LEN_SPI; i=i+1 ) begin
			#dly_mosi;
            mosi = spi_data_w[i];
            #(SPI_CLK_HALF_PERIOD-dly_mosi) sck = 0;
            spi_data_r[i] = miso ;
            #SPI_CLK_HALF_PERIOD sck = 1;
        end
        // spi_master_data_ready =1;
        mosi = 0;
        #SPI_CLK_HALF_PERIOD;
        #(SPI_CLK_PERIOD*2);
        cs_n = 1;
        #SPI_CLK_HALF_PERIOD;
        #(SPI_CLK_PERIOD*2);
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
