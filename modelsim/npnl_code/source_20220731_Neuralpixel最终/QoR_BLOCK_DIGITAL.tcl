report_qor

****************************************
Report : qor
Design : BLOCK_DIGITAL
Version: N-2017.09
Date   : Sun Aug 21 11:33:04 2022
****************************************


  Timing Path Group 'CLK_3p2M'
  -----------------------------------
  Levels of Logic:               9.00
  Critical Path Length:          7.24
  Critical Path Slack:         140.95
  Critical Path Clk Period:    312.00
  Total Negative Slack:          0.00
  No. of Violating Paths:        0.00
  Worst Hold Violation:         -0.05
  Total Hold Violation:         -0.05
  No. of Hold Violations:        1.00
  -----------------------------------


  Cell Count
  -----------------------------------
  Hierarchical Cell Count:         15
  Hierarchical Port Count:        447
  Leaf Cell Count:                797
  Buf/Inv Cell Count:             286
  Buf Cell Count:                  55
  Inv Cell Count:                 231
  CT Buf/Inv Cell Count:            2
  Combinational Cell Count:       547
  Sequential Cell Count:          250
  Macro Count:                      0
  -----------------------------------


  Area
  -----------------------------------
  Combinational Area:     5673.772800
  Noncombinational Area: 18430.041672
  Buf/Inv Area:           2262.734430
  Total Buffer Area:           547.04
  Total Inverter Area:        1715.70
  Macro/Black Box Area:      0.000000
  Net Area:               1617.646137
  -----------------------------------
  Cell Area:             24103.814472
  Design Area:           25721.460610


  Design Rules
  -----------------------------------
  Total Number of Nets:           858
  Nets With Violations:            48
  Max Trans Violations:            48
  Max Cap Violations:               0
  -----------------------------------


  Hostname: kilicontech02

  Compile CPU Statistics
  -----------------------------------------
  Resource Sharing:                    0.22
  Logic Optimization:                  0.42
  Mapping Optimization:                2.38
  -----------------------------------------
  Overall Compile Time:               13.61
  Overall Compile Wall Clock Time:    14.20

  --------------------------------------------------------------------

  Design  WNS: 0.00  TNS: 0.00  Number of Violating Paths: 0


  Design (Hold)  WNS: 0.05  TNS: 0.05  Number of Violating Paths: 1

get_alternative_lib_cells fsm_block/U58
size_cell fsm_block/U58 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO3HDLLX1

get_alternative_lib_cells fsm_block/U67
get_alternative_lib_cells fsm_block/U55
get_alternative_lib_cells fsm_block/U59


Innovus:
floorPlan -s 466.2 70 15 8.5 15 20

NP TOP有 M5的AVDD 穿过数字逻辑