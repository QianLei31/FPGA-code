// HDL file for D_CELLS_HDLL, DFRRSQHDLLX0, functional.




// End HDL models

// Netlisted models

// HDL file - D_CELLS_HDLL, DFRRSQHDLLX0, functional.
// HDL file - D_CELLS_HDLL, DFRSQHDLLX0, functional.
// HDL file - D_CELLS_HDLL, DFRQHDLLX0, functional.
// Library - SJTU_SAR_ADC_12BIT_v5, Cell -
//sar_adc_logic_12bit_v4_single_input_conv_v1, View - schematic
// LAST TIME SAVED: Jul 18 19:19:34 2022
// NETLIST TIME: Jul 19 21:31:33 2022
`timescale 1ns / 1ps 

module sar_adc_logic_12bit_v4_single_input_conv_v1 (
     SAR_REG0, 
     WP, 
     COMP, 
     PULSE, 
     WP_RSTN);
   output SAR_REG0;
   output [11:0] WP;
   input COMP;
   input [11:1] PULSE;
   input WP_RSTN;

   // Internal wires
   wire FE_ECON10_n52;
   wire FE_ECON9_data_from_adc0_1;
   wire FE_ECON8_data_from_adc0_2;
   wire FE_ECON7_data_from_adc0_3;
   wire FE_ECON6_data_from_adc0_4;
   wire FE_ECON5_data_from_adc0_5;
   wire FE_ECON4_data_from_adc0_6;
   wire FE_ECON3_data_from_adc0_7;
   wire FE_ECON2_data_from_adc0_8;
   wire FE_ECON1_data_from_adc0_9;
   wire FE_ECON0_data_from_adc0_10;
   wire LOGIC0;

   DLY2HDLLX0 FE_ECOC10_n52 (.A(WP[0]),
     .Q(FE_ECON10_n52));
   DLY2HDLLX0 FE_ECOC9_data_from_adc0_1 (.A(WP[1]),
     .Q(FE_ECON9_data_from_adc0_1));
   DLY2HDLLX0 FE_ECOC8_data_from_adc0_2 (.A(WP[2]),
     .Q(FE_ECON8_data_from_adc0_2));
   DLY2HDLLX0 FE_ECOC7_data_from_adc0_3 (.A(WP[3]),
     .Q(FE_ECON7_data_from_adc0_3));
   DLY2HDLLX0 FE_ECOC6_data_from_adc0_4 (.A(WP[4]),
     .Q(FE_ECON6_data_from_adc0_4));
   DLY2HDLLX0 FE_ECOC5_data_from_adc0_5 (.A(WP[5]),
     .Q(FE_ECON5_data_from_adc0_5));
   DLY2HDLLX0 FE_ECOC4_data_from_adc0_6 (.A(WP[6]),
     .Q(FE_ECON4_data_from_adc0_6));
   DLY2HDLLX0 FE_ECOC3_data_from_adc0_7 (.A(WP[7]),
     .Q(FE_ECON3_data_from_adc0_7));
   DLY2HDLLX0 FE_ECOC2_data_from_adc0_8 (.A(WP[8]),
     .Q(FE_ECON2_data_from_adc0_8));
   DLY2HDLLX0 FE_ECOC1_data_from_adc0_9 (.A(WP[9]),
     .Q(FE_ECON1_data_from_adc0_9));
   DLY2HDLLX0 FE_ECOC0_data_from_adc0_10 (.A(WP[10]),
     .Q(FE_ECON0_data_from_adc0_10));
   DFRRSQHDLLX0 I39 (.C(LOGIC0),
     .D(LOGIC0),
     .Q(WP[0]),
     .RN(WP_RSTN),
     .SN(PULSE[1]));
   DFRRSQHDLLX0 I38 (.C(FE_ECON10_n52),
     .D(COMP),
     .Q(WP[1]),
     .RN(WP_RSTN),
     .SN(PULSE[2]));
   DFRRSQHDLLX0 I37 (.C(FE_ECON9_data_from_adc0_1),
     .D(COMP),
     .Q(WP[2]),
     .RN(WP_RSTN),
     .SN(PULSE[3]));
   DFRRSQHDLLX0 I36 (.C(FE_ECON8_data_from_adc0_2),
     .D(COMP),
     .Q(WP[3]),
     .RN(WP_RSTN),
     .SN(PULSE[4]));
   DFRRSQHDLLX0 I35 (.C(FE_ECON7_data_from_adc0_3),
     .D(COMP),
     .Q(WP[4]),
     .RN(WP_RSTN),
     .SN(PULSE[5]));
   DFRRSQHDLLX0 I34 (.C(FE_ECON6_data_from_adc0_4),
     .D(COMP),
     .Q(WP[5]),
     .RN(WP_RSTN),
     .SN(PULSE[6]));
   DFRRSQHDLLX0 I33 (.C(FE_ECON5_data_from_adc0_5),
     .D(COMP),
     .Q(WP[6]),
     .RN(WP_RSTN),
     .SN(PULSE[7]));
   DFRRSQHDLLX0 I32 (.C(FE_ECON4_data_from_adc0_6),
     .D(COMP),
     .Q(WP[7]),
     .RN(WP_RSTN),
     .SN(PULSE[8]));
   DFRRSQHDLLX0 I31 (.C(FE_ECON3_data_from_adc0_7),
     .D(COMP),
     .Q(WP[8]),
     .RN(WP_RSTN),
     .SN(PULSE[9]));
   DFRRSQHDLLX0 I30 (.C(FE_ECON2_data_from_adc0_8),
     .D(COMP),
     .Q(WP[9]),
     .RN(WP_RSTN),
     .SN(PULSE[10]));
   DFRRSQHDLLX0 I10 (.C(FE_ECON1_data_from_adc0_9),
     .D(COMP),
     .Q(WP[10]),
     .RN(WP_RSTN),
     .SN(PULSE[11]));
   DFRSQHDLLX0 I0 (.C(FE_ECON0_data_from_adc0_10),
     .D(COMP),
     .Q(WP[11]),
     .SN(WP_RSTN));
   LOGIC0DHDLL I41 (.Q(LOGIC0));
   DFRQHDLLX0 I42 (.C(PULSE[1]),
     .D(COMP),
     .Q(SAR_REG0));
endmodule
// End HDL models
