// Author      : GTT
// Description : frequency division
// Change date : 2022/06/20
// Change log  : None
module CLK_12P(
	clk_50M,
	rst_n,

	clk_3p2M
);

input  clk_50M;
input  rst_n;
output clk_3p2M;

reg [3:0] cnt_12;
// system clock(3.2M*12Hz)-->3.2MHz
always @(posedge clk_50M or negedge rst_n) begin
	if(!rst_n) begin
		cnt_12 <= 0;
	end else if(cnt_12==11) begin
		cnt_12 <= 0;
	end else begin
		cnt_12 <= cnt_12 + 1'b1;
	end
end

assign clk_3p2M = cnt_12>5 ? 1 : 0;

endmodule
