// Library - SJTU_SAR_ADC_12BIT_v5, Cell -
//sar_adc_logic_12bit_v4_single_input_v1_x4, View - schematic
// LAST TIME SAVED: Jul  9 11:19:55 2022
// NETLIST TIME: Jul  9 23:16:32 2022
`timescale 1ns / 10ps 

module sar_adc_logic_12bit_v4_single_input_v2_x4 ( D0, D1, D2, D3,
     DR, SAMP_analog,WP0, WP1, WP2, WP3, CLK, COMP,
     RSTN, SAMP_RATE_MUX );

output  DR;
output SAMP_analog;
input   CLK, RSTN;

output [11:0]  D3;
output [11:0]  D2;
output [11:0]  D0;
output [11:0]  D1;
output [11:0]  WP0;
output [11:0]  WP1;
output [11:0]  WP2;
output [11:0]  WP3;

input [3:0]  COMP;
input [1:0]  SAMP_RATE_MUX;

// Buses in the design

wire  [11:0]  PULSE;

sar_adc_logic_12bit_v4_single_input_conv_v1 I0[3:0] ( {SAR_REG3,
     SAR_REG2, SAR_REG1, SAR_REG0}, {WP3[11:0], WP2[11:0], WP1[11:0],
     WP0[11:0]}, COMP[3:0], PULSE[11:1], WP_RSTN);
sar_adc_logic_12bit_v4_single_input_fs_v2 I1 ( .PULSE(PULSE[11:0]),
     .DR(DR),.SAMP_analog(SAMP_analog), .CLK(CLK), .RSTN(RSTN),
     .SAMP_RATE_MUX(SAMP_RATE_MUX[1:0]), .WP_RSTN(WP_RSTN));

assign D3[11:0] = {WP3[11:1],SAR_REG3};
assign D2[11:0] = {WP2[11:1],SAR_REG2};
assign D1[11:0] = {WP1[11:1],SAR_REG1};
assign D0[11:0] = {WP0[11:1],SAR_REG0};
//verilog_short I7 ( .out(D3[11:0]), .in({WP3[11:1], SAR_REG3}));
//verilog_short I6 ( .out(D2[11:0]), .in({WP2[11:1], SAR_REG2}));
//verilog_short I5 ( .out(D1[11:0]), .in({WP1[11:1], SAR_REG1}));
//verilog_short I4 ( .out(D0[11:0]), .in({WP0[11:1], SAR_REG0}));

endmodule