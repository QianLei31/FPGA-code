// Author      : GTT
// Change date : 2022/06/28
// Change log  : add clock gate
// Change date : 2022/07/07
// Change log  : change data_valid low valid
// Change date : 2022/08/15
// Change log  : buffer p_data in 3.2MHz
// Change date : 2022/08/25
// Change log  : modify clock gate: (~(clk_gate_en_l & p_data_syn[BITS_ADC])) ==> (~(clk_gate_en_l));
// Change date : 2022/08/31
// Change log  : modify data_valid: assign data_valid = clk_gate_en_l_1d;

module P2S(
	p_data,
	clk_50M,
	clk_3p2M,
	rst_n,
	s_data,
	data_valid
);

parameter NUM_COL = 8;   // Block number in one Column
parameter BITS_ADC = 12;
//parameter DATA_LENGTHS = BITS_ADC + 1;

input [BITS_ADC:0] p_data; // MSB is the flag of starting P2S
input			   clk_50M;
input			   clk_3p2M;
input              rst_n;
output             s_data;
output   	       data_valid;

reg [BITS_ADC:0] p_data_syn; // sample in 3.2MHz clock negedge
always @(negedge clk_3p2M or negedge rst_n) begin 
	if(!rst_n) begin 
		p_data_syn <= {(BITS_ADC){1'b1}};
	end else begin 
		p_data_syn <= p_data;
	end
end

reg clk_gate_en_l;
wire gate_clk;
always @(negedge clk_50M or negedge rst_n) begin 
	if(!rst_n) begin 
		clk_gate_en_l <= 1'b1;
	end else begin 
		clk_gate_en_l <= p_data_syn[BITS_ADC];
	end
end
reg clk_gate_en_l_1d;
always @(negedge clk_50M or negedge rst_n) begin 
	if(!rst_n) begin 
		clk_gate_en_l_1d <= 1'b1;
	end else begin 
		clk_gate_en_l_1d <= clk_gate_en_l;
	end
end

assign gate_clk = clk_50M & (~(clk_gate_en_l));

reg	[4:0]	cnt_12; // negedge sample, loop counter from 0 to 11 when p_data_syn valid
always @(negedge gate_clk or negedge rst_n) begin 
	if(!rst_n) begin 
		cnt_12 <= 'b0;
	end else if (p_data_syn[BITS_ADC]==0) begin 
		if (cnt_12 < BITS_ADC-1) begin
			cnt_12 <= cnt_12 + 1;
		end else begin 
			cnt_12 <= 'b0;
		end
	end else begin 
		cnt_12 <= 'b0;
	end
end

reg [BITS_ADC:0] p_buffer;
always @(negedge gate_clk or negedge rst_n) begin 
	if(!rst_n) begin 
		p_buffer <= 'b0;
	end else if ((p_data_syn[BITS_ADC]==0) && (cnt_12 == 'b0)) begin // when p_data_syn valid and cnt equal 0, assign new data for serial output
		p_buffer <= p_data_syn[BITS_ADC:0];
		//s_data   <= p_buffer[0];
	end else begin // ADC data output serially
		p_buffer <= {1'b0,p_buffer[BITS_ADC:1]};
	end
end

assign s_data = p_buffer[0];
assign data_valid = clk_gate_en_l_1d;
// always @(negedge gate_clk or negedge rst_n) begin // external device can sample s_data using posedge clk_50M when data_valid is low
// 	if(!rst_n) begin 
// 		data_valid <= 1'b1;
// 	end else if (p_data_syn[BITS_ADC]==0) begin // s_data valid, aligned with the falling edge of the clock
// 		data_valid <= 1'b0;
// 	end else begin 
// 		data_valid <= 1'b1;
// 	end
// end

endmodule