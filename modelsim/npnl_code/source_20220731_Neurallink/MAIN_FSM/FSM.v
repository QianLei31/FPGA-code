// Author      : XKK
// Change date : 2022/06/24
// Change log  : negedge trigger rx_output assign code/addr/data
// Author      : XKK
// Change date : 2022/07/29
// Change log  : modify elec register control
// Change date : 2022/08/09
// Change log  : modify elec register control clk,3.2MHz
// Change date : 2022/08/13
// Change log  : modify interface with BLOCK
// Change date : 2022/08/20
// Change log  : assign rst_n_to_probe = rst_n_to_elec & rst_n_to_elec_chem;
// Change date : 2022/08/22
// Change log  : delete ELE probe logic 
module FSM(
    clk,        //Chip clock 38.4MHz
    rst_n,      // Asynchronous rst_n PAD in
	
	rx_output,     // output to spi, spi cmd
	rdy_spi,       // output to spi, data ready
	spi_busy,      // output to spi, data busy
	push_tx,       // output to spi, push data to buffer that output to ex. device
	ack_fetch_spi, // output to spi

	tx_input,  // input from spi

	code,     // spi bus
	addr,     // spi bus
	data_in,  // spi bus
	data_out, // spi bus
	
	// data_to_elec, // data to ELEC in probe
	// clk_to_elec,  // clk to ELEC in probe
	// data_to_elec_chem,  // data to ELEC CHEM in probe
	// clk_to_elec_chem,   // data to ELEC CHEM in probe

	// rst_n_to_probe, // Reset ALL ELEC in probe
	
	clk_3p2M  // output to ALL BLOCK

	// chem_out // input from Probe
);

parameter LEN_SPI = 32 ; //packet data only after decoding and header removeal
parameter SPI_ADDR_LEN = 10;
parameter SPI_DATA_LEN = 16;
parameter SPI_CODE_LEN = 6;

parameter ELE_NUM       = 1024; // NeuralPixel : Eletrode number 0-1023
parameter ELE_CHEM_NUM  = 1024; // NeuralPixel : Chem Eletrode number 0-1023
parameter ELE_GROUP_WID = 16;   // NeuralPixel : ALL Eletrode group width: 16. 1024/16=64 group in total

localparam IDLE             = 5'b00001;
localparam WRITE_ELEC       = 5'b00010;
localparam READ_ELEC        = 5'b00100;
localparam FINISH_READ_ELEC	= 5'b01000;
localparam RESET_ELEC       = 5'b10000;

input clk;
input rst_n;

input [LEN_SPI-1:0] rx_output;
input rdy_spi;
input spi_busy;
output reg [LEN_SPI-1:0] tx_input;
output push_tx;
output reg ack_fetch_spi;

// output data_to_elec;       // NP, data to ELE MUX in probe
// output clk_to_elec;        // NP, clk to ELE MUX in probe
// output data_to_elec_chem;  // NP, data to ELE CHEM MUX in probe
// output clk_to_elec_chem;   // NP, clk to ELE CHEM MUX in probe
// output rst_n_to_probe;     // NP, rst_n to probe

// wire   rst_n_to_elec;      // NP, reset to ELE MUX in probe
// wire   rst_n_to_elec_chem; // NP, reset to ELE CHEM MUX in probe
// assign rst_n_to_probe = rst_n_to_elec & rst_n_to_elec_chem;
// spi bus : code addr data_in data_out
output [SPI_CODE_LEN-1:0] code;
output [SPI_ADDR_LEN-1:0] addr;
output [SPI_DATA_LEN-1:0] data_in;
inout  [SPI_DATA_LEN-1:0] data_out;

wire data_out_en; // data_out valid flag

output clk_3p2M;
// input [7:0] chem_out; // counter CHEM pulse

/******************************************************************************
* Function   : counter CHEM pulse                                             *
* Author     :                                                                *
* Description:                                                                *
******************************************************************************/ 
/*
reg  [7:0] chem_out_cnt_1d;
reg  [7:0] chem_out_cnt_2d;
wire [7:0] chem_out_cnt_pos;

reg [15:0] chem_out_cnt[7:0];
reg [15:0] chem_out_cnt_buf[7:0];
integer i; 
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		for (i = 0; i<8; i=i+1) begin
			chem_out_cnt[i] <= 16'b0;
		end
	end else begin
		for (i = 0; i<8; i=i+1) begin
			if (chem_out[i] == 1'b1) begin
				chem_out_cnt[i] <= chem_out_cnt[i] + 1'b1;
			end else if(chem_out_cnt_pos[i])begin 
				chem_out_cnt[i] <= 16'b0;
			end else begin 
				chem_out_cnt[i] <= chem_out_cnt[i];
			end
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		for (i = 0; i<8; i=i+1) begin
			chem_out_cnt_1d[i] <= 1'b0;
			chem_out_cnt_2d[i] <= 1'b0;
		end
	end else begin
		for (i = 0; i<8; i=i+1) begin
			chem_out_cnt_1d[i] <= chem_out[i];
			chem_out_cnt_2d[i] <= chem_out_cnt_1d[i];
		end
	end
end

assign chem_out_cnt_pos = chem_out_cnt_2d & ~chem_out_cnt_1d;

always @(negedge clk or negedge rst_n) begin
	if(~rst_n) begin
		for (i = 0; i<8; i=i+1) begin
			chem_out_cnt_buf[i] <= 16'b0;
		end
	end else begin
		for (i = 0; i<8; i=i+1) begin
			if (chem_out_cnt_pos[i] == 1'b1) begin
				chem_out_cnt_buf[i] <= chem_out_cnt[i];
			end else begin 
				chem_out_cnt_buf[i] <= chem_out_cnt_buf[i];
			end
		end
	end
end
*/
/******************************************************************************
* Function   : handshake with SPI                                             *
* Author     :                                                                *
* Description: spi --> code addr data_in; data_out <-- BLOCK                  *
******************************************************************************/ 
reg [LEN_SPI-1:0] rx_output_buf;
always @(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rx_output_buf <= {(LEN_SPI){1'b0}};
		ack_fetch_spi <= 1'b0;
	end else if(rdy_spi==1'b1 && spi_busy==1'b0) begin
		rx_output_buf <= rx_output;
		ack_fetch_spi <= 1'b1;
	end else begin
		ack_fetch_spi <= 1'b0;
	end
end

// reg [4:0]              current_state;
// reg [4:0]              next_state;
// reg [9:0]              counter_1024;
// reg [SPI_DATA_LEN-1:0] read_elec_data; // return ELE reg data
// reg [4:0]              current_state_chem;
// reg [4:0]              next_state_chem;
// reg [9:0]              counter_1024_chem;
// reg [SPI_DATA_LEN-1:0] read_elec_data_chem; // return ELE CHEM reg data
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin		
		tx_input <= {(LEN_SPI){1'b0}};
	end else if(data_out_en) begin // Read BLOCK REG Code
		tx_input <= {rx_output_buf[LEN_SPI-1:SPI_DATA_LEN],data_out};
	end/* else if(current_state == FINISH_READ_ELEC) begin // Read ELE in probe Code
		tx_input <= read_elec_data;
	end else if(current_state_chem == FINISH_READ_ELEC) begin // Read ELE CHEM in probe Code
		tx_input <= read_elec_data_chem;
	end else if(code == 25) begin // Read ELE CHEM in probe Code
		case (addr[2:0])
			3'd0: tx_input <= chem_out_cnt_buf[0];
			3'd1: tx_input <= chem_out_cnt_buf[1];
			3'd2: tx_input <= chem_out_cnt_buf[2];
			3'd3: tx_input <= chem_out_cnt_buf[3];
			3'd4: tx_input <= chem_out_cnt_buf[4];
			3'd5: tx_input <= chem_out_cnt_buf[5];
			3'd6: tx_input <= chem_out_cnt_buf[6];
			3'd7: tx_input <= chem_out_cnt_buf[7];
			default: ;
		endcase
	end */
end

/******************************************************************************
* Function   : handshake with BLOCK                                           *
* Author     :                                                                *
* Description: spi --> code addr data_in; data_out <-- BLOCK                  *
******************************************************************************/ 
reg [LEN_SPI-1:0] spi_bus; // spi bus to BLOCK
always @(posedge clk_3p2M or negedge rst_n) begin
	if(~rst_n) begin
		spi_bus <= {(LEN_SPI){1'b0}};
	end else begin
		spi_bus <= rx_output_buf;
	end
end
assign code    = spi_bus[LEN_SPI-1:LEN_SPI-SPI_CODE_LEN];
assign addr    = spi_bus[SPI_ADDR_LEN+SPI_DATA_LEN-1:SPI_DATA_LEN];
assign data_in = spi_bus[SPI_DATA_LEN-1:0];

// reg clk_3p2M_1d;
// wire clk_3p2M_pos;
// always @(posedge clk or negedge rst_n)begin
// 	if(!rst_n) begin
// 		clk_3p2M_1d <= 0;
// 	end else begin
// 		clk_3p2M_1d <= clk_3p2M;
// 	end
// end
// assign clk_3p2M_pos = clk_3p2M & ~clk_3p2M_1d;

reg data_out_en_1d;
reg data_out_en_2d;
reg data_out_en_3d;
always @(negedge clk_3p2M or negedge rst_n) begin
	if(!rst_n) begin
		data_out_en_1d <= 1'b0;
		data_out_en_2d <= 1'b0;
		data_out_en_3d <= 1'b0;
	end else if(code==1 || code==2 || code==3 || code==15 || code==17 || code==19) begin
		data_out_en_1d <= 1'b1;
		data_out_en_2d <= data_out_en_1d;
		data_out_en_3d <= data_out_en_2d;
	end else begin
		data_out_en_1d <= 1'b0;
		data_out_en_2d <= data_out_en_1d;
		data_out_en_3d <= data_out_en_2d;
	end
end
assign data_out_en = data_out_en_3d & data_out_en_1d;

// reg [2:0] data_out_en_buf; 
// always @(negedge clk_3p2M or negedge rst_n) begin
// 	if(!rst_n) begin
// 		data_out_en_buf <= 3'b0;
// 	end else if(code==1 || code==2 || code==3 || code==15 || code==17 || code==19) begin
// 		data_out_en_buf[0] <= 1'b1;
// 		data_out_en_buf[2:1] <= data_out_en_buf[1:0];
// 	end else begin
// 		data_out_en_buf[0]  <= 1'b0;
// 		data_out_en_buf[2:1] <= data_out_en_buf[1:0];
// 	end
// end
// assign data_out_en = data_out_en_buf[2] & data_out_en_buf[1];

assign data_out = 16'bz;

// Read Register
// reg push_tx_buf;
// always @(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		push_tx_buf <= 0;
// 	end
// 	else if(code==1 || code==2 || code==3 || code==11 || code == 15 || code == 17 || code == 19 || code==21) begin //Read register Code
// 		push_tx_buf <= 1;		
// 	end														//TODO
// end
assign push_tx = 1'b1;


/******************************************************************************
* Function   :  Control electrode in probe                                    *
* Author     :                                                                *
* Description: spi --> code addr data_in; data_out <-- BLOCK                  *
******************************************************************************/ 
/*
wire 	reg_cache_0;
always @(posedge clk_3p2M or negedge rst_n) begin
	if(!rst_n)
		current_state <= IDLE;
	else
		current_state <= next_state;
end

always @(*)
	case(current_state)
		IDLE:	
			if(code == 10)				next_state <= WRITE_ELEC;
			else if(code == 11)			next_state <= READ_ELEC;
			else if(code ==12)			next_state <= RESET_ELEC;
			else						next_state <= IDLE;
		WRITE_ELEC:
			if(counter_1024 == ELE_NUM-1) next_state <= IDLE;
			else						next_state <= WRITE_ELEC;
		READ_ELEC:
			if(counter_1024 == ELE_NUM-1) next_state <= FINISH_READ_ELEC;
			else						next_state <= READ_ELEC;
		FINISH_READ_ELEC:					next_state <= IDLE;
		RESET_ELEC:						next_state <= IDLE;

		default:						next_state <= IDLE;
			
	endcase

always @(posedge clk_3p2M or negedge rst_n) begin
	if(!rst_n)
		counter_1024 <= 0;
	else if(current_state==WRITE_ELEC || current_state == READ_ELEC) begin
		if(counter_1024 == ELE_NUM-1) 		counter_1024 <= 0;
		else						counter_1024 <= counter_1024 + 1;
	end
	else
		counter_1024 <= 0;		
end
assign clk_to_elec = ~clk_3p2M && (current_state == WRITE_ELEC);
assign data_to_elec = reg_cache_0;
assign rst_n_to_elec = rst_n && (~(code == 12));

reg [5:0] elec_addr;
always @(posedge clk_3p2M or negedge rst_n)
	if(!rst_n)
		elec_addr <= 0;
	else if(next_state == READ_ELEC && current_state == IDLE)
		elec_addr <= addr;
	else if(next_state == IDLE && current_state == IDLE)
		elec_addr <= 0;
		

always @(posedge clk_3p2M or negedge rst_n) begin
	if(!rst_n)
		read_elec_data <= 0;
	else if(current_state == READ_ELEC && (counter_1024>>4)==elec_addr)
		read_elec_data <= {reg_cache_0,read_elec_data[15:1]};		
end

//=========================================== chem reg =========================================================
wire 	reg_cache_0_chem;
always @(posedge clk_3p2M or negedge rst_n) begin
	if(!rst_n)
		current_state_chem <= IDLE;
	else
		current_state_chem <= next_state_chem;
end

always @(*)
	case(current_state_chem)
		IDLE:	
			if(code == 20)				next_state_chem <= WRITE_ELEC;
			else if(code == 21)			next_state_chem <= READ_ELEC;
			else if(code ==22)			next_state_chem <= RESET_ELEC;
			else						next_state_chem <= IDLE;
		WRITE_ELEC:
			if(counter_1024_chem == ELE_CHEM_NUM-1) next_state_chem <= IDLE;
			else						next_state_chem <= WRITE_ELEC;
		READ_ELEC:
			if(counter_1024_chem == ELE_CHEM_NUM-1) next_state_chem <= FINISH_READ_ELEC;
			else						next_state_chem <= READ_ELEC;
		FINISH_READ_ELEC:					next_state_chem <= IDLE;
		RESET_ELEC:						next_state_chem <= IDLE;

		default:						next_state_chem <= IDLE;
			
	endcase

always @(posedge clk_3p2M or negedge rst_n) begin
	if(!rst_n)
		counter_1024_chem <= 0;
	else if(current_state_chem==WRITE_ELEC || current_state_chem == READ_ELEC) begin
		if(counter_1024_chem == ELE_CHEM_NUM-1) 		counter_1024_chem <= 0;
		else						counter_1024_chem <= counter_1024_chem + 1;
	end
	else
		counter_1024_chem <= 0;		
end
assign clk_to_elec_chem = ~clk_3p2M && (current_state_chem == WRITE_ELEC);
assign data_to_elec_chem = reg_cache_0_chem;
assign rst_n_to_elec_chem = rst_n && (~(code == 22));

reg [5:0] elec_addr_chem;
always @(posedge clk_3p2M or negedge rst_n)
	if(!rst_n)
		elec_addr_chem <= 0;
	else if(next_state_chem == READ_ELEC && current_state_chem == IDLE)
		elec_addr_chem <= addr;
	else if(next_state_chem == IDLE && current_state_chem == IDLE)
		elec_addr_chem <= 0;
		

always @(posedge clk_3p2M or negedge rst_n) begin
	if(!rst_n)
		read_elec_data_chem <= 0;
	else if(current_state_chem == READ_ELEC && (counter_1024_chem>>4)==elec_addr_chem)
		read_elec_data_chem <= {reg_cache_0_chem,read_elec_data_chem[15:1]};		
end
*/
//==================================================================================================================================================

reg [3:0] cnt_12;
// system clock(3.2M*12Hz)-->3.2MHz
always @(posedge clk or negedge rst_n)

	if(!rst_n)
		cnt_12 <= 0;
	else if(cnt_12==11)
		cnt_12 <= 0;
	else
		cnt_12 <= cnt_12 + 1;
assign clk_3p2M = cnt_12>5 ? 1 : 0;

/*
wire 	write_cache_en;
assign 	write_cache_en = (code==23) ? 1 : 0;
elec_register_cache elec_register_cache_i1(
	.clk					(clk_3p2M),
	.rst_n				(rst_n),
						
	.state				(current_state[3:0]),
	.write_cache_en		(write_cache_en),
	.addr				(addr),
	.data_in				(data_in),
						 
	.data_out			(reg_cache_0)

);

wire 	write_cache_en_chem;
assign 	write_cache_en_chem = (code==24) ? 1 : 0;
elec_register_cache elec_register_cache_i2(
	.clk					(clk_3p2M),
	.rst_n				(rst_n),
						
	.state				(current_state_chem[3:0]),
	.write_cache_en		(write_cache_en_chem),
	.addr				(addr),
	.data_in				(data_in),
						 
	.data_out			(reg_cache_0_chem)

);
*/
endmodule
