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


module FSM_BLOCK(
	clk,
	rst_n,

	// spi bus
	data_in,  // spi cmd, input from FSM
	addr,     // spi cmd, input from FSM
	code,     // spi cmd, input from FSM
	data_out, // spi read data, output to FSM

	reg_map_addr, // BLOCK address

	SAMP_RATE_MUX,
    adc_ready,       // ADC data ready, posedge valid
    data_from_adc0,  // data from CH0
    data_from_adc1,  // data from CH1
    data_from_adc2,  // data from CH2
    data_from_adc3,  // data from CH3
    data_from_pre,   // data from pre BLOCK
    data_to_post,    // data to post BLOCK

	// to analog AFE
	Rec_0,	
	Rec_1,
	Rec_2,
	Rec_3,

	// to analog DAC
	elec_sel_0,
	elec_sel_1,
	elec_sel_2,
	elec_sel_3,
	
	POL_0,// REG_MAP to CB_Logic, polarity control
	POL_1,
	POL_2,
	POL_3,

	CB_ON_0,// REG_MAP to CB_Logic
	CB_ON_1,
	CB_ON_2,
	CB_ON_3,

	CB_OK_0,// from CB_Logic, compensate finish
	CB_OK_1,
	CB_OK_2,
	CB_OK_3,

	STIM_AMP_0,// REG_MAP to DAC, amplitude control
	STIM_AMP_1,
	STIM_AMP_2,
	STIM_AMP_3,

	OFF_STIM_0,// REG_MAP to DAC, stim on/off, Low valid
	OFF_STIM_1,
	OFF_STIM_2,
	OFF_STIM_3,

	AMP_X50_0,// REG_MAP to DAC, amplitude times control 
	AMP_X50_1,
	AMP_X50_2,
	AMP_X50_3,

	elec_mux,	
	D_HP,
	
	clk_CB_LOGIC
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
input      [BITS_ADC-1:0] data_from_adc0;
input      [BITS_ADC-1:0] data_from_adc1;
input      [BITS_ADC-1:0] data_from_adc2;
input      [BITS_ADC-1:0] data_from_adc3;  
input      [BITS_ADC:0]   data_from_pre;
output reg [BITS_ADC:0]   data_to_post;

output reg [REC_LEN-1:0] Rec_0;				
output reg [REC_LEN-1:0] Rec_1;			 						
output reg [REC_LEN-1:0] Rec_2;			 						
output reg [REC_LEN-1:0] Rec_3;
output reg [1:0]		 SAMP_RATE_MUX;
output reg [15:0]		 elec_mux;
output reg [3:0]		 D_HP;
output 					 clk_CB_LOGIC;

output [DAC_AMP_LEN-1:0] STIM_AMP_0	;
output [1:0]             POL_0;
output   	             OFF_STIM_0;
output 	                 CB_ON_0;
input  	                 CB_OK_0;
output 	                 AMP_X50_0;

output [DAC_AMP_LEN-1:0] STIM_AMP_1;
output [1:0]             POL_1;
output   	             OFF_STIM_1;
output 	                 CB_ON_1;
input  	                 CB_OK_1;
output 	                 AMP_X50_1;

output [DAC_AMP_LEN-1:0] STIM_AMP_2;
output [1:0]             POL_2;
output   	             OFF_STIM_2;
output 	                 CB_ON_2;
input  	                 CB_OK_2;
output 	                 AMP_X50_2;

output [DAC_AMP_LEN-1:0] STIM_AMP_3;
output [1:0]             POL_3;
output   	             OFF_STIM_3;
output 	                 CB_ON_3;
input  	                 CB_OK_3;
output 	                 AMP_X50_3;

// =========================DAIYSY_CHAIN======================================
reg [2:0] adc_ready_z;
wire adc_ready_pos;
reg [BITS_ADC-1:0] data_adc_buffer [3:0]; // buffer ADC data 
reg [BIT_CNT_SHIFT_CH-1:0] block_cnt;
//reg                      en_clk_shift; // enable clock for the shift register in daisy chain
reg                      en_clk_shift_l; // negative clock edge aligned clock enable
wire                     clk_shift; //clk_shift is the shift clock for daisy chain

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

//============================= DAC Control ============================================================
reg [SPI_DATA_LEN-1:0] DAC_0;		
always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		DAC_0 <= 16'b1000_0000_0000_0000;
	end else if(code==6 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==0) begin
		DAC_0 <= data_in;
	end else if(code==13) begin // Global DAC turn off stim
		DAC_0[SPI_DATA_LEN-1:0] <= 16'b1000_0000_0000_0000;
	end else if(code==9) begin  // Global DAC turn on stim
		DAC_0[SPI_DATA_LEN-1] <= 1'b0;
	end 
end  

wire   [1:0] POL_buf_0;
output [1:0] elec_sel_0;
wire         comp_en_0; //compensate flag, 1'b1:begin compensate; 1'b0:close compensate
assign 	STIM_AMP_0  = DAC_0[DAC_AMP_LEN-1:0];
assign	POL_buf_0	= DAC_0[DAC_AMP_LEN+1:DAC_AMP_LEN];
assign  comp_en_0   = DAC_0[DAC_AMP_LEN+2];
assign  AMP_X50_0   = DAC_0[DAC_AMP_LEN+3];
assign  elec_sel_0  = DAC_0[DAC_AMP_LEN+5:DAC_AMP_LEN+4];
assign	OFF_STIM_0  = DAC_0[SPI_DATA_LEN-1];


reg [3:0] next_state_0;
reg [3:0] current_state_0;
wire 	clk_DAC_state_gate_0;
assign	clk_DAC_state_gate_0 = (next_state_0 != S_IDLE) || (current_state_0 != S_IDLE);

reg		clk_DAC_state_gate_trigger_0;
always @(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		clk_DAC_state_gate_trigger_0 <= 0;
	end else begin
		clk_DAC_state_gate_trigger_0 <= clk_DAC_state_gate_0;
	end
end 

wire	clk_DAC_state_0;
assign 	clk_DAC_state_0 = clk_DAC_state_gate_trigger_0 && clk;


//reg [3:0] next_state_0;
reg [7:0] cnt_0;
always @(posedge clk_DAC_state_0 or negedge rst_n) begin
	if(!rst_n) begin
		current_state_0 <= S_IDLE;
	end else begin
		current_state_0 <= next_state_0;
	end 
end 

always @(*) begin
	case(current_state_0)
		S_IDLE:
			if		((code==6 && data_in[SPI_DATA_LEN-1]==0 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==0) || code==9) next_state_0<= S_STIM_ON;
			else						  	next_state_0<= S_IDLE;
		S_STIM_ON:
			if		(cnt_0==21)			next_state_0<= S_COMP_ON;
			else if	(OFF_STIM_0==1)			next_state_0<= S_IDLE;
			else							next_state_0<= S_STIM_ON;
		S_COMP_ON:
			if		(CB_OK_0==1 && code==18)			next_state_0<= S_STIM_READY;
			else if	(OFF_STIM_0==1)			next_state_0<= S_IDLE;
			else							next_state_0<= S_COMP_ON;	
		S_STIM_READY:
			if		(comp_en_0==1)			next_state_0<= S_COMP_ON;
			else if	(OFF_STIM_0==1)			next_state_0<= S_IDLE;
			else							next_state_0<= S_STIM_READY;
	endcase
end 

always @(posedge clk_DAC_state_0 or negedge rst_n) begin
	if(!rst_n) begin
		cnt_0 <= 0;
	end else if(cnt_0==21) begin
		cnt_0 <= 0;
	end else if(current_state_0==S_STIM_ON) begin
		cnt_0 <= cnt_0 + 1;
	end else begin
		cnt_0 <= 0;
	end 
end

assign CB_ON_0 = (current_state_0 == S_COMP_ON) ? 1 : 0;
assign POL_0 = (current_state_0 == S_COMP_ON) ? 'b00: (current_state_0 == S_STIM_READY ? POL_buf_0 : 0);


reg [SPI_DATA_LEN-1:0] DAC_1;		
always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		DAC_1 <= 16'b1000_0000_0000_0000;
	end else if(code==6 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==1) begin
		DAC_1 <= data_in;
	end else if(code==13) begin
		DAC_1[SPI_DATA_LEN-1:0] <= 16'b1000_0000_0000_0000;
	end else if(code==9) begin
		DAC_1[SPI_DATA_LEN-1] <= 1'b0;
	end 
end 

wire   [1:0] POL_buf_1;
output [1:0] elec_sel_1;
wire         comp_en_1; 
assign 	STIM_AMP_1  = DAC_1[DAC_AMP_LEN-1:0];
assign	POL_buf_1	= DAC_1[DAC_AMP_LEN+1:DAC_AMP_LEN];
assign 	comp_en_1 	= DAC_1[DAC_AMP_LEN+2];
assign 	AMP_X50_1   = DAC_1[DAC_AMP_LEN+3];
assign  elec_sel_1  = DAC_1[DAC_AMP_LEN+5:DAC_AMP_LEN+4];
assign	OFF_STIM_1  = DAC_1[SPI_DATA_LEN-1];


reg [3:0] next_state_1;

wire 	clk_DAC_state_gate_1;
reg [3:0] current_state_1;
assign	clk_DAC_state_gate_1 = (next_state_1 != S_IDLE)|| (current_state_1 != S_IDLE);

reg		clk_DAC_state_gate_trigger_1;
always @(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		clk_DAC_state_gate_trigger_1 <= 0;
	end else begin
		clk_DAC_state_gate_trigger_1 <= clk_DAC_state_gate_1;
	end
end 

wire	clk_DAC_state_1;
assign 	clk_DAC_state_1 = clk_DAC_state_gate_trigger_1 && clk;



//reg [3:0] next_state_1;
reg [7:0] cnt_1;
always @(posedge clk_DAC_state_1 or negedge rst_n) begin
	if(!rst_n) begin
		current_state_1 <= S_IDLE;
	end else begin
		current_state_1 <= next_state_1;
	end 
end 

always @(*)
	case(current_state_1)
		S_IDLE:
			if		((code==6 && data_in[SPI_DATA_LEN-1]==0 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==1) || code==9) next_state_1<= S_STIM_ON;
			else						  	next_state_1<= S_IDLE;
		S_STIM_ON:
			if		(cnt_1==21)			next_state_1<= S_COMP_ON;
			else if	(OFF_STIM_1==1)			next_state_1<= S_IDLE;
			else							next_state_1<= S_STIM_ON;
		S_COMP_ON:
			if		(CB_OK_1==1 && code==18)			next_state_1<= S_STIM_READY;
			else if	(OFF_STIM_1==1)			next_state_1<= S_IDLE;
			else							next_state_1<= S_COMP_ON;	
		S_STIM_READY:
			if		(comp_en_1==1)			next_state_1<= S_COMP_ON;
			else if	(OFF_STIM_1==1)			next_state_1<= S_IDLE;
			else							next_state_1<= S_STIM_READY;
	endcase

always @(posedge clk_DAC_state_1 or negedge rst_n) begin
	if(!rst_n) begin
		cnt_1 <= 0;
	end else if(cnt_1==21) begin
		cnt_1 <= 0;
	end else if(current_state_1==S_STIM_ON) begin
		cnt_1 <= cnt_1 + 1;
	end else begin
		cnt_1 <= 0;
	end 
end

assign CB_ON_1 = (current_state_1 == S_COMP_ON) ? 1 : 0;
assign POL_1 = (current_state_1 == S_COMP_ON) ? 'b00: (current_state_1 == S_STIM_READY ? POL_buf_1 : 0);


reg [SPI_DATA_LEN-1:0] DAC_2;		
always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		DAC_2 <= 16'b1000_0000_0000_0000;
	end else if(code==6 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==2) begin
		DAC_2 <= data_in;
	end else if(code==13) begin //DAC reset
		DAC_2[SPI_DATA_LEN-1:0] <= 16'b1000_0000_0000_0000;
	end else if(code==9) begin//modify
		DAC_2[SPI_DATA_LEN-1] <= 1'b0;
	end 
end 
wire   [1:0] POL_buf_2;
output [1:0] elec_sel_2;
wire         comp_en_2;
assign 	STIM_AMP_2  = DAC_2[DAC_AMP_LEN-1:0];
assign	POL_buf_2	= DAC_2[DAC_AMP_LEN+1:DAC_AMP_LEN];
assign  comp_en_2 	= DAC_2[DAC_AMP_LEN+2];
assign  AMP_X50_2   = DAC_2[DAC_AMP_LEN+3];
assign  elec_sel_2  = DAC_2[DAC_AMP_LEN+5:DAC_AMP_LEN+4];
assign	OFF_STIM_2  = DAC_2[SPI_DATA_LEN-1];


reg [3:0] next_state_2;
reg [3:0] current_state_2;
wire 	clk_DAC_state_gate_2;
assign	clk_DAC_state_gate_2 = (next_state_2 != S_IDLE) || (current_state_2 != S_IDLE);

reg		clk_DAC_state_gate_trigger_2;
always @(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		clk_DAC_state_gate_trigger_2 <= 0;
	end else begin
		clk_DAC_state_gate_trigger_2 <= clk_DAC_state_gate_2;
	end
end

wire	clk_DAC_state_2;
assign 	clk_DAC_state_2 = clk_DAC_state_gate_trigger_2 && clk;


//reg [3:0] next_state_2;
reg [7:0] cnt_2;
always @(posedge clk_DAC_state_2 or negedge rst_n) begin
	if(!rst_n) begin
		current_state_2 <= S_IDLE;
	end else begin
		current_state_2 <= next_state_2;
	end 
end 

always @(*)
	case(current_state_2)
		S_IDLE:
			if		((code==6 && data_in[SPI_DATA_LEN-1]==0 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==2) || code==9) next_state_2<= S_STIM_ON;
			else						  	next_state_2<= S_IDLE;
		S_STIM_ON:
			if		(cnt_2==21)			next_state_2<= S_COMP_ON;
			else if	(OFF_STIM_2==1)			next_state_2<= S_IDLE;
			else							next_state_2<= S_STIM_ON;
		S_COMP_ON:
			if		(CB_OK_2==1 && code==18)			next_state_2<= S_STIM_READY;
			else if	(OFF_STIM_2==1)			next_state_2<= S_IDLE;
			else							next_state_2<= S_COMP_ON;	
		S_STIM_READY:
			if		(comp_en_2==1)			next_state_2<= S_COMP_ON;
			else if	(OFF_STIM_2==1)			next_state_2<= S_IDLE;
			else							next_state_2<= S_STIM_READY;
	endcase

always @(posedge clk_DAC_state_2 or negedge rst_n) begin
	if(!rst_n) begin
		cnt_2 <= 0;
	end else if(cnt_2==21) begin
		cnt_2 <= 0;
	end else if(current_state_2==S_STIM_ON) begin
		cnt_2 <= cnt_2 + 1;
	end else begin
		cnt_2 <= 0;
	end 
end 

assign CB_ON_2 = (current_state_2 == S_COMP_ON) ? 1 : 0;
assign POL_2 = (current_state_2 == S_COMP_ON) ? 'b00: (current_state_2 == S_STIM_READY ? POL_buf_2 : 0);


reg [SPI_DATA_LEN-1:0] DAC_3;		
always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		DAC_3 <= 16'b1000_0000_0000_0000;
	end else if(code==6 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==3) begin
		DAC_3 <= data_in;
	end else if(code==13) begin //DAC reset
		DAC_3[SPI_DATA_LEN-1:0] <= 16'b1000_0000_0000_0000;
	end else if(code==9) begin//modify
		DAC_3[SPI_DATA_LEN-1] <= 1'b0;
	end 
end 

wire   [1:0] POL_buf_3;
output [1:0] elec_sel_3;
wire 	     comp_en_3; 
assign 	STIM_AMP_3  = DAC_3[DAC_AMP_LEN-1:0];
assign	POL_buf_3	= DAC_3[DAC_AMP_LEN+1:DAC_AMP_LEN];
assign  comp_en_3   = DAC_3[DAC_AMP_LEN+2];
assign  AMP_X50_3      = DAC_3[DAC_AMP_LEN+3];
assign  elec_sel_3  = DAC_3[DAC_AMP_LEN+5:DAC_AMP_LEN+4];
assign	OFF_STIM_3  = DAC_3[SPI_DATA_LEN-1];


reg [3:0] next_state_3;
reg [3:0] current_state_3;
wire 	clk_DAC_state_gate_3;
assign	clk_DAC_state_gate_3 = (next_state_3 != S_IDLE) || (current_state_3 != S_IDLE);

reg		clk_DAC_state_gate_trigger_3;
always @(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		clk_DAC_state_gate_trigger_3 <= 0;
	end else begin
		clk_DAC_state_gate_trigger_3 <= clk_DAC_state_gate_3;
	end
end

wire	clk_DAC_state_3;
assign 	clk_DAC_state_3 = clk_DAC_state_gate_trigger_3 && clk;


//reg [3:0] next_state_3;
reg [7:0] cnt_3;
always @(posedge clk_DAC_state_3 or negedge rst_n) begin
	if(!rst_n) begin
		current_state_3 <= S_IDLE;
	end else begin
		current_state_3 <= next_state_3;
	end
end

always @(*)
	case(current_state_3)
		S_IDLE:
			if		((code==6 && data_in[SPI_DATA_LEN-1]==0 && addr[SPI_ADDR_LEN-1:2]==reg_map_addr && addr[1:0]==3) || code==9) next_state_3<= S_STIM_ON;
			else						  	next_state_3<= S_IDLE;
		S_STIM_ON:
			if		(cnt_3==21)			next_state_3<= S_COMP_ON;
			else if	(OFF_STIM_3==1)			next_state_3<= S_IDLE;
			else							next_state_3<= S_STIM_ON;
		S_COMP_ON:
			if		(CB_OK_3==1 && code==18)			next_state_3<= S_STIM_READY;
			else if	(OFF_STIM_3==1)			next_state_3<= S_IDLE;
			else							next_state_3<= S_COMP_ON;	
		S_STIM_READY:
			if		(comp_en_3==1)			next_state_3<= S_COMP_ON;
			else if	(OFF_STIM_3==1)			next_state_3<= S_IDLE;
			else							next_state_3<= S_STIM_READY;
	endcase

always @(posedge clk_DAC_state_3 or negedge rst_n) begin
	if(!rst_n)
		cnt_3 <= 0;
	else if(cnt_3==21)
		cnt_3 <= 0;
	else if(current_state_3==S_STIM_ON)
		cnt_3 <= cnt_3 + 1;
	else
		cnt_3 <= 0;
end

assign CB_ON_3 = (current_state_3 == S_COMP_ON) ? 1 : 0;
assign POL_3 = (current_state_3 == S_COMP_ON) ? 'b00: (current_state_3 == S_STIM_READY ? POL_buf_3 : 0);

// Smple rate assignment
always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		SAMP_RATE_MUX <= 'b11;
	end else if(code==14) begin
		SAMP_RATE_MUX <= data_in[1:0];
	end 
end 		
		
// elec_mux 		
always @(posedge clk_reg or negedge rst_n) begin
	if(!rst_n) begin
		elec_mux <= 'b0000_0000_0000_0000;
	end else if(code==16 && addr[SPI_ADDR_LEN-1:2] == reg_map_addr) begin
		elec_mux <= data_in[15:0];
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
        3:begin // Read Stim.
        	case(addr[1:0])
        	2'b00: data_out_buf <= {DAC_0[SPI_DATA_LEN-1:1],CB_OK_0};
        	2'b01: data_out_buf <= {DAC_1[SPI_DATA_LEN-1:1],CB_OK_1};
        	2'b10: data_out_buf <= {DAC_2[SPI_DATA_LEN-1:1],CB_OK_2};
        	2'b11: data_out_buf <= {DAC_3[SPI_DATA_LEN-1:1],CB_OK_3};
        	endcase
        end
        15:begin // Read Sample rate
            data_out_buf <= SAMP_RATE_MUX;
        end
        17:begin // Read Ele. Neurallink
            data_out_buf <= elec_mux;
        end
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
assign data_out_en = data_out_en_2d;

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


reg [3:0] cnt_16_clk_ADC;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_16_clk_ADC <= 0;
	end else if(cnt_16_clk_ADC==15) begin
		cnt_16_clk_ADC <= 0;
	end else begin
		cnt_16_clk_ADC <= cnt_16_clk_ADC + 1;
	end
end
assign clk_CB_LOGIC = cnt_16_clk_ADC>7 ? 1 : 0;	

endmodule
