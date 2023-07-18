// Author      : GTT
// Change date : 2022/08/08
// Change log  : Asynchronous reset synchronous release

module RST_N_SYN(
    clk_sys,    // Chip clock 
    rst_n,      // Asynchronous rst_n
	rst_syn_n
);

input clk_sys;         // Chip clock 
input rst_n;           // external reset signal 
output reg rst_syn_n; // synchronous reset signal

reg rst_syn_n_buf;
always @(posedge clk_sys or negedge rst_n) begin
	if(~rst_n) begin
		rst_syn_n_buf <= 1'b0;
		rst_syn_n <= 1'b0;
	end else begin
		rst_syn_n_buf <= 1'b1;
		rst_syn_n <= rst_syn_n_buf;		
	end
end

endmodule
