module elec_register_cache(
	clk,
	rst_n,
	
	state,
	write_cache_en,
	addr,
	data_in,
	
	data_out

);
`include "../parameter.v"
input	clk;
input	rst_n;
input	[3:0] state;
input	write_cache_en;
input	[SPI_ADDR_LEN-1:0]	addr;
input	[SPI_DATA_LEN-1:0]	data_in;
output	data_out;

reg 	[1023:0] 	reg_cache;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		reg_cache <= 0;
	else if(write_cache_en) begin
		case(addr)
			0: reg_cache[15:0] <= data_in;
			1: reg_cache[31:16] <= data_in;
			2: reg_cache[47:32] <= data_in;
			3: reg_cache[63:48] <= data_in;
			4: reg_cache[79:64] <= data_in;
			5: reg_cache[95:80] <= data_in;
			6: reg_cache[111:96] <= data_in;
			7: reg_cache[127:112] <= data_in;
			8: reg_cache[143:128] <= data_in;
			9: reg_cache[159:144] <= data_in;
			10: reg_cache[175:160] <= data_in;
			11: reg_cache[191:176] <= data_in;
			12: reg_cache[207:192] <= data_in;
			13: reg_cache[223:208] <= data_in;
			14: reg_cache[239:224] <= data_in;
			15: reg_cache[255:240] <= data_in;
			16: reg_cache[271:256] <= data_in;
			17: reg_cache[287:272] <= data_in;
			18: reg_cache[303:288] <= data_in;
			19: reg_cache[319:304] <= data_in;
			20: reg_cache[335:320] <= data_in;
			21: reg_cache[351:336] <= data_in;
			22: reg_cache[367:352] <= data_in;
			23: reg_cache[383:368] <= data_in;
			24: reg_cache[399:384] <= data_in;
			25: reg_cache[415:400] <= data_in;
			26: reg_cache[431:416] <= data_in;
			27: reg_cache[447:432] <= data_in;
			28: reg_cache[463:448] <= data_in;
			29: reg_cache[479:464] <= data_in;
			30: reg_cache[495:480] <= data_in;
			31: reg_cache[511:496] <= data_in;
			32: reg_cache[527:512] <= data_in;
			33: reg_cache[543:528] <= data_in;
			34: reg_cache[559:544] <= data_in;
			35: reg_cache[575:560] <= data_in;
			36: reg_cache[591:576] <= data_in;
			37: reg_cache[607:592] <= data_in;
			38: reg_cache[623:608] <= data_in;
			39: reg_cache[639:624] <= data_in;
			40: reg_cache[655:640] <= data_in;
			41: reg_cache[671:656] <= data_in;
			42: reg_cache[687:672] <= data_in;
			43: reg_cache[703:688] <= data_in;
			44: reg_cache[719:704] <= data_in;
			45: reg_cache[735:720] <= data_in;
			46: reg_cache[751:736] <= data_in;
			47: reg_cache[767:752] <= data_in;
			48: reg_cache[783:768] <= data_in;
			49: reg_cache[799:784] <= data_in;
			50: reg_cache[815:800] <= data_in;
			51: reg_cache[831:816] <= data_in;
			52: reg_cache[847:832] <= data_in;
			53: reg_cache[863:848] <= data_in;
			54: reg_cache[879:864] <= data_in;
			55: reg_cache[895:880] <= data_in;
			56: reg_cache[911:896] <= data_in;
			57: reg_cache[927:912] <= data_in;
			58: reg_cache[943:928] <= data_in;
			59: reg_cache[959:944] <= data_in;
			60: reg_cache[975:960] <= data_in;
			61: reg_cache[991:976] <= data_in;
			62: reg_cache[1007:992] <= data_in;
			63: reg_cache[1023:1008] <= data_in;			
		endcase
	end
	else if(state==4'b0010 || state==4'b0100)
		reg_cache <= {reg_cache[0],reg_cache[1023:1]};
end




assign data_out = reg_cache[0];
endmodule