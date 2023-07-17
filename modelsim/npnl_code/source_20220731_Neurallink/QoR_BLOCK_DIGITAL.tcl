report_qor

****************************************
Report : qor
Design : BLOCK_DIGITAL
Version: N-2017.09
Date   : Sun Aug 21 21:04:20 2022
****************************************


  Timing Path Group 'CLK_3p2M'
  -----------------------------------
  Levels of Logic:              10.00
  Critical Path Length:          8.58
  Critical Path Slack:         139.68
  Critical Path Clk Period:    312.00
  Total Negative Slack:          0.00
  No. of Violating Paths:        0.00
  Worst Hold Violation:         -0.05
  Total Hold Violation:         -0.05
  No. of Hold Violations:        1.00
  -----------------------------------

  Timing Path Group 'CLK_200K'
  -----------------------------------
  Levels of Logic:               6.00
  Critical Path Length:          5.72
  Critical Path Slack:        4976.28
  Critical Path Clk Period:   4992.00
  Total Negative Slack:          0.00
  No. of Violating Paths:        0.00
  Worst Hold Violation:          0.00
  Total Hold Violation:          0.00
  No. of Hold Violations:        0.00
  -----------------------------------


  Cell Count
  -----------------------------------
  Hierarchical Cell Count:         24
  Hierarchical Port Count:        648
  Leaf Cell Count:               1640
  Buf/Inv Cell Count:             502
  Buf Cell Count:                  59
  Inv Cell Count:                 443
  CT Buf/Inv Cell Count:            2
  Combinational Cell Count:      1213
  Sequential Cell Count:          427
  Macro Count:                      0
  -----------------------------------


  Area
  -----------------------------------
  Combinational Area:    13303.444783
  Noncombinational Area: 30819.166649
  Buf/Inv Area:           3899.451267
  Total Buffer Area:           609.36
  Total Inverter Area:        3290.10
  Macro/Black Box Area:      0.000000
  Net Area:               3161.725341
  -----------------------------------
  Cell Area:             44122.611432
  Design Area:           47284.336774


  Design Rules
  -----------------------------------
  Total Number of Nets:          1717
  Nets With Violations:            53
  Max Trans Violations:            53
  Max Cap Violations:               0
  -----------------------------------


  Hostname: kilicontech02

  Compile CPU Statistics
  -----------------------------------------
  Resource Sharing:                    0.57
  Logic Optimization:                  0.69
  Mapping Optimization:                3.39
  -----------------------------------------
  Overall Compile Time:               16.83
  Overall Compile Wall Clock Time:    17.44

  --------------------------------------------------------------------

  Design  WNS: 0.00  TNS: 0.00  Number of Violating Paths: 0


  Design (Hold)  WNS: 0.05  TNS: 0.05  Number of Violating Paths: 1

  --------------------------------------------------------------------


get_alternative_lib_cells fsm_block/U790
get_alternative_lib_cells fsm_block/U20
get_alternative_lib_cells fsm_block/U791
get_alternative_lib_cells fsm_block/U788

size_cell fsm_block/U790 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO3HDLLX1
size_cell fsm_block/U20  D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO3HDLLX1
size_cell fsm_block/U791 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO3HDLLX1
size_cell fsm_block/U788 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO3HDLLX1


get_alternative_lib_cells fsm_block/U558
size_cell fsm_block/U558 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO2HDLLX1


Innovus:
floorPlan -s 466.2 70 15 8.5 15 20

