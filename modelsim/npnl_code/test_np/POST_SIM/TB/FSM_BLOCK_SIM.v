// Author      : XKK
// Description : DAC and AFE register control
// Change date : 2022/06/20
// Change log  : None
// Change date : 2022/06/22
// Change log  : Add clock gating
// Change date : 2022/06/23
// Change log  : DAC state machine clock gate control
// Change date : 2022/06/24
// Change log  : fix clock gate glitch
// Change date : 2022/06/26
// Change log  : modify Rec_x default and add register D_HP (write: code=5; read: code=1)
// Change date : 2022/06/27
// Change log  : modify for 60M system clock and 38.4M system clock
// Change date : 2022/07/16
// Change log  : modify for REC_x bit width is 12bit
// Change date : 2022/07/21
// Change log  : modify for elec_mux bit width from 8 to 16bit
// Change date : 2022/07/24
// Change log  : merge DAISY_CHAIN.v (buffer ADC data, then shift reg)
//				 and add ADC data SPI readout code
// Change date : 2022/08/18
// Change log  : delete DAC logic


module FSM_BLOCK_SIM(
	clk,
	rst_n,

	data_in,  // spi cmd, input from FSM
	addr,     // spi cmd, input from FSM
	code,     // spi cmd, input from FSM
	data_out, // spi read data, output to FSM

	reg_map_addr, // BLOCK address

	SAMP_RATE_MUX,
    adc_ready,       // ADC data ready, posedge valid
    // data_from_adc0,  // data from CH0
    // data_from_adc1,  // data from CH1
    // data_from_adc2,  // data from CH2
    // data_from_adc3,  // data from CH3
    data_from_pre,   // data from pre BLOCK
    data_to_post,    // data to post BLOCK

	// to analog 
	Rec_0,	
	Rec_1,
	Rec_2,
	Rec_3,
	D_HP
);

// `include "../parameter.v"
parameter LEN_SPI          = 32; //packet data only after decoding and header removeal
parameter BITS_CNT_SPI     = 6;
parameter SPI_ADDR_LEN     = 10;
parameter SPI_DATA_LEN     = 16;
parameter SPI_CODE_LEN     = 6;
parameter BITS_ADC         = 12; // ADC data width
parameter REC_LEN          = 12; // Record control REG
parameter DAC_AMP_LEN      = 9;  // DAC control REG
parameter BIT_CNT_SHIFT_CH = 7;  // counter bits for shift all the 32channels in one rows, add 2 cycles for clock enable

parameter S_IDLE 	   = 4'b0001;
parameter S_STIM_ON    = 4'b0010;
parameter S_COMP_ON	   = 4'b0100;
parameter S_STIM_READY = 4'b1000;

input clk;
input rst_n;
input [SPI_DATA_LEN-1:0] data_in;
input [SPI_ADDR_LEN-1:0] addr;
input [SPI_CODE_LEN-1:0] code;
input [SPI_ADDR_LEN-3:0] reg_map_addr;
inout [SPI_DATA_LEN-1:0] data_out;

input                     adc_ready;
// input      [BITS_ADC-1:0] data_from_adc0;
// input      [BITS_ADC-1:0] data_from_adc1;
// input      [BITS_ADC-1:0] data_from_adc2;
// input      [BITS_ADC-1:0] data_from_adc3;  
input      [BITS_ADC:0]   data_from_pre;
output reg [BITS_ADC:0]   data_to_post;

output reg [REC_LEN-1:0] Rec_0;				
output reg [REC_LEN-1:0] Rec_1;			 						
output reg [REC_LEN-1:0] Rec_2;			 						
output reg [REC_LEN-1:0] Rec_3;
output reg [1:0]		 SAMP_RATE_MUX;
output reg [3:0]		 D_HP;


// =========================DAIYSY_CHAIN======================================
reg [2:0] adc_ready_z;
wire adc_ready_pos;
reg [BITS_ADC-1:0] data_adc_buffer [3:0]; // buffer ADC data 
reg [BIT_CNT_SHIFT_CH-1:0] block_cnt;
reg                      en_clk_shift_l; // negative clock edge aligned clock enable
wire                     clk_shift; //clk_shift is the shift clock for daisy chain

// random generate ADC data
reg  [11:0]  data_from_adc0;
reg  [11:0]  data_from_adc1;
reg  [11:0]  data_from_adc2;
reg  [11:0]  data_from_adc3;
always @(posedge adc_ready or negedge rst_n) begin
    if(~rst_n) begin
        data_from_adc0 <= 'b0;
        data_from_adc1 <= 'b0;
        data_from_adc2 <= 'b0;
        data_from_adc3 <= 'b0;
    end else begin
        data_from_adc0 <= {$random} % {{1'b1},{(BITS_ADC-1){1'b0}}};
        data_from_adc1 <= {$random} % {{1'b1},{(BITS_ADC-1){1'b0}}};
        data_from_adc2 <= {$random} % {{1'b1},{(BITS_ADC-1){1'b0}}};
        data_from_adc3 <= {$random} % {{1'b1},{(BITS_ADC-1){1'b0}}};
        // $display("COMP: %d",COMP);
    end
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        adc_ready_z <= {{(3){1'b0}}};
    end else begin
        adc_ready_z[2:0] <= {adc_ready_z[1:0],adc_ready};
    end
end
assign adc_ready_pos = ~adc_ready_z[2] & adc_ready_z[1];

// counter based FSM, need to add clock enable 
always @(negedge clk or negedge rst_n) begin
    if(~rst_n) begin
        data_adc_buffer[0] <= {{(BITS_ADC){1'b1}}};
        data_adc_buffer[1] <= {{(BITS_ADC){1'b1}}};
        data_adc_buffer[2] <= {{(BITS_ADC){1'b1}}};
        data_adc_buffer[3] <= {{(BITS_ADC){1'b1}}};
    end else begin
        if (adc_ready_pos) begin
	        data_adc_buffer[0] <= data_from_adc0;
	        data_adc_buffer[1] <= data_from_adc1;
	        data_adc_buffer[2] <= data_from_adc2;
	        data_adc_buffer[3] <= data_from_adc3;
        end else begin
            data_adc_buffer[0] <= data_adc_buffer[0];
            data_adc_buffer[1] <= data_adc_buffer[1];
            data_adc_buffer[2] <= data_adc_buffer[2];
            data_adc_buffer[3] <= data_adc_buffer[3];
        end
    end
end

// counter based FSM, need to add clock enable 
always @(negedge clk or negedge rst_n) begin
    if(~rst_n) begin
        en_clk_shift_l <= 0; //disable clock
    end else begin
        if (adc_ready_pos) begin
            en_clk_shift_l <= 1; //enable clock
        end else if (block_cnt == 7'b010_0001) begin
            en_clk_shift_l <= 0; //disable clock
        end
    end
end
assign clk_shift = en_clk_shift_l & clk ; 

// counter based FSM, need to add clock enable 
always @(posedge clk_shift or negedge rst_n) begin
    if(~rst_n) begin
        block_cnt <= {{(BIT_CNT_SHIFT_CH){1'b1}}};
    end else begin
        if (adc_ready_pos == 1'b1) begin
            block_cnt <= 0;
        end /*else if (block_cnt == {1'b0, {(BIT_CNT_SHIFT_CH){1'b1}}}) begin
            block_cnt <= block_cnt + 1'b1;
        end*/ else begin
            block_cnt <= block_cnt + 1'b1;
        end
    end
end

reg [BITS_ADC:0]   data_from_pre_buf; // negedge clock buffer data_from_pre
always @(negedge clk_shift or negedge rst_n) begin
    if(~rst_n) begin
        data_from_pre_buf <= {{(BITS_ADC+1){1'b1}}};
    end else begin
        data_from_pre_buf <= data_from_pre;
    end
end

always @(posedge clk_shift or negedge rst_n) begin
    if(~rst_n) begin
        data_to_post <= {{(BITS_ADC+1){1'b1}}};
    end else begin
        if (block_cnt == 'd0) begin
            data_to_post <= {1'b0,data_adc_buffer[0]};
        end
        else if (block_cnt == 'd8) begin
            data_to_post <= {1'b0,data_adc_buffer[1]};
        end
        else if (block_cnt == 'd16) begin
            data_to_post <= {1'b0,data_adc_buffer[2]};
        end
        else if (block_cnt == 'd24) begin
            data_to_post <= {1'b0,data_adc_buffer[3]};
        end 
        else begin 
            data_to_post <= data_from_pre_buf;
        end
    end
end

/******************************************************************************
* Function   : write signal posedge dectect                                   *
* Author     :                                                                *
* Description:                                                                *
******************************************************************************/ 
wire 	clk_reg_gate;
assign	clk_reg_gate = (code==4 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr) || code==7 || code==8 || (code==6 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr) || code==13 || code==9 || code==14 || code==16 || code==5; //TODO改成只持续一个周期
reg 	clk_reg_gate_d1;
always @(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		clk_reg_gate_d1 <= 0;
	end else begin
		clk_reg_gate_d1 <= clk_reg_gate;
	end
end

reg clk_reg_gate_d2;
always @(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		clk_reg_gate_d2 <= 0;
	end else begin
		clk_reg_gate_d2 <= clk_reg_gate_d1;
	end
end

wire 	clk_reg;
assign	clk_reg = (clk_reg_gate_d1==1 && clk_reg_gate_d2==0);


always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		Rec_0 <= 'b0000_0111_1110;
	end else if(code==4 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==0) begin
		Rec_0 <= data_in[REC_LEN-1:0];
	end else if(code==7 ) begin//Rec reset
		Rec_0[REC_LEN-1] <= 1'b0;
	end else if(code==8 ) begin //Global set
		Rec_0[REC_LEN-1] <= 1'b1;
	end 
end 

always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		Rec_1 <= 'b0000_0111_1110;
	end else if(code==4 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==1) begin
		Rec_1 <= data_in[REC_LEN-1:0];
	end else if(code==7 ) begin //Rec reset
		Rec_1[REC_LEN-1] <= 1'b0;
	end else if(code==8 ) begin //Global set
		Rec_1[REC_LEN-1] <= 1'b1;
	end 
end 

always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		Rec_2 <= 'b0000_0111_1110;
	end else if(code==4 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==2) begin
		Rec_2 <= data_in[REC_LEN-1:0];
	end else if(code==7 ) begin //Rec reset
		Rec_2[REC_LEN-1] <= 1'b0;
	end else if(code==8 ) begin //Global set
		Rec_2[REC_LEN-1] <= 1'b1;
	end 
end 

always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		Rec_3 <= 'b0000_0111_1110;
	end else if(code==4 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==3) begin
		Rec_3 <= data_in[REC_LEN-1:0];
	end else if(code==7 ) begin //Rec reset
		Rec_3[REC_LEN-1] <= 1'b0;
	end else if(code==8 ) begin //Global set
		Rec_3[REC_LEN-1] <= 1'b1;
	end 
end 

// Smple rate assignment
always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		SAMP_RATE_MUX <= 'b11;
	end else if(code==14) begin
		SAMP_RATE_MUX <= data_in[1:0];
	end 
end 		
		
// D_HP assignment
always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		D_HP <= 'b1111;
	end else if(code==5 && addr[SPI_ADDR_LEN-1:2] == reg_map_addr) begin
		D_HP <= data_in[3:0];
	end
end

//====================================== Read data ========================================================
wire 	clk_data_out_buf_gate;
assign	clk_data_out_buf_gate = (addr[SPI_ADDR_LEN-1:2]==reg_map_addr) && ((code==1) || (code==3) || (code==15) || (code == 17) || (code==19) );

reg		clk_data_out_buf_gate_trigger;
always @(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		clk_data_out_buf_gate_trigger <= 0;
	end else begin
		clk_data_out_buf_gate_trigger <= clk_data_out_buf_gate;
	end
end

wire	clk_data_out_buf;
assign 	clk_data_out_buf = clk_data_out_buf_gate_trigger && clk;


reg [SPI_DATA_LEN-1:0] data_out_buf;
always @(posedge clk_data_out_buf or negedge rst_n) begin
	if(!rst_n)
		data_out_buf <= 0;
	else if(addr[SPI_ADDR_LEN-1:2]==reg_map_addr) begin
		case(code)
        1:begin // read rec.
        	case(addr[1:0])
        	2'b00: data_out_buf <= {Rec_0, D_HP};
        	2'b01: data_out_buf <= {Rec_1, D_HP};
        	2'b10: data_out_buf <= {Rec_2, D_HP};
        	2'b11: data_out_buf <= {Rec_3, D_HP};
        	endcase
        end
        //3:begin // Read Stim.
        //	case(addr[1:0])
        //	2'b00: data_out_buf <= {DAC_0[SPI_DATA_LEN-1:1],CB_OK_0};
        //	2'b01: data_out_buf <= {DAC_1[SPI_DATA_LEN-1:1],CB_OK_1};
        //	2'b10: data_out_buf <= {DAC_2[SPI_DATA_LEN-1:1],CB_OK_2};
        //	2'b11: data_out_buf <= {DAC_3[SPI_DATA_LEN-1:1],CB_OK_3};
        //	endcase
        //end
        15:begin // Read Sample rate
            data_out_buf <= SAMP_RATE_MUX;
        end
        //17:begin // Read Ele. Neurallink
        //    data_out_buf <= elec_mux;
        //end
        19:begin // Read ADC data
        	case(addr[1:0])
        	2'b00: data_out_buf <= data_adc_buffer[0];
        	2'b01: data_out_buf <= data_adc_buffer[1];
        	2'b10: data_out_buf <= data_adc_buffer[2];
        	2'b11: data_out_buf <= data_adc_buffer[3];
        	endcase
        end
        default: data_out_buf <= 0;
        endcase
	end else begin 
		data_out_buf <= 0;
	end
end

wire data_out_en;
reg data_out_en_1d;
reg data_out_en_2d;
always @(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_out_en_1d <= 1'b0;
		data_out_en_2d <= 1'b0;
	end else if((code==1 || code==2 || code==3 || code==15 || code==17 || code==19) && (addr[SPI_ADDR_LEN-1:2]==reg_map_addr)) begin
		data_out_en_1d <= 1'b1;
		data_out_en_2d <= data_out_en_1d;
	end else begin
		data_out_en_1d <= 1'b0;
		data_out_en_2d <= data_out_en_1d;
	end
end
assign data_out_en = data_out_en_2d & data_out_en_1d;

// reg data_out_en;
// always @(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		data_out_en <= 0;
// 	end else if((code == 1 || code == 2 || code == 3 || code == 15 || code == 17 || code == 19) && (addr[SPI_ADDR_LEN-1:2]==reg_map_addr)) begin
// 		data_out_en <= 1;
// 	end else begin
// 		data_out_en <= 0;
// 	end
// end
//wire 	data_out_en;
//assign	data_out_en = (code == 1 || code == 2 || code == 3 || code == 15 || code == 17) && (addr[SPI_ADDR_LEN-1:2]==reg_map_addr);
assign data_out =data_out_en ? data_out_buf : 16'bz; 


//reg [3:0] cnt_16_clk_ADC;
//always @(posedge clk or negedge rst_n) begin
//	if(!rst_n) begin
//		cnt_16_clk_ADC <= 0;
//	end else if(cnt_16_clk_ADC==15) begin
//		cnt_16_clk_ADC <= 0;
//	end else begin
//		cnt_16_clk_ADC <= cnt_16_clk_ADC + 1;
//	end
//end
//assign clk_CB_LOGIC = cnt_16_clk_ADC>7 ? 1 : 0;	

endmodule
