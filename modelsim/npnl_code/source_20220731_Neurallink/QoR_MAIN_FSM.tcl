# 38.4MHz domain  
ideal net  : clk_50M  ;#Chip clock  
ideal net  : rst_n    ;# Asynchronous rst_n

input net  : p_data     ;# from data_to_post in BLOCK of one row
output net : s_data     ;# serially output to ex.
output net : data_valid ;# data valid

# 3.2MHz domain  
ideal net  : clk_3p2M
ideal net  : rst_n_block ;# Asynchronous rst_n

output net : code     ;# spi bus
output net : addr     ;# spi bus
output net : data_in  ;# spi bus
output net : data_out ;# spi bus

#Standard SPI interface 
sck  ;# SPI clock
miso ;# Master IN slave Out lsb first Latched in in falling edge
mosi ;# Master Out slave IN lsb first changed in falling edge
cs_n ;# Chip select (low active)


report_qor



****************************************
Report : qor
Design : MAIN_FSM
Version: N-2017.09
Date   : Mon Aug 22 14:24:12 2022
****************************************


  Timing Path Group 'CLK_50M'
  -----------------------------------
  Levels of Logic:               0.00
  Critical Path Length:          2.21
  Critical Path Slack:           3.79
  Critical Path Clk Period:     26.00
  Total Negative Slack:          0.00
  No. of Violating Paths:        0.00
  Worst Hold Violation:          0.00
  Total Hold Violation:          0.00
  No. of Hold Violations:        0.00
  -----------------------------------

  Timing Path Group 'CLK_SPI'
  -----------------------------------
  Levels of Logic:               3.00
  Critical Path Length:          3.17
  Critical Path Slack:          86.76
  Critical Path Clk Period:    200.00
  Total Negative Slack:          0.00
  No. of Violating Paths:        0.00
  Worst Hold Violation:          0.00
  Total Hold Violation:          0.00
  No. of Hold Violations:        0.00
  -----------------------------------


  Cell Count
  -----------------------------------
  Hierarchical Cell Count:         16
  Hierarchical Port Count:        359
  Leaf Cell Count:                962
  Buf/Inv Cell Count:             158
  Buf Cell Count:                 120
  Inv Cell Count:                  38
  CT Buf/Inv Cell Count:           16
  Combinational Cell Count:       487
  Sequential Cell Count:          475
  Macro Count:                      0
  -----------------------------------


  Area
  -----------------------------------
  Combinational Area:    11023.772778
  Noncombinational Area: 35337.524590
  Buf/Inv Area:           5843.912725
  Total Buffer Area:          5561.71
  Total Inverter Area:         282.20
  Macro/Black Box Area:      0.000000
  Net Area:               2204.682988
  -----------------------------------
  Cell Area:             46361.297367
  Design Area:           48565.980355


  Design Rules
  -----------------------------------
  Total Number of Nets:          1072
  Nets With Violations:            42
  Max Trans Violations:            42
  Max Cap Violations:               0
  -----------------------------------


  Hostname: kilicontech02

  Compile CPU Statistics
  -----------------------------------------
  Resource Sharing:                    0.24
  Logic Optimization:                  0.61
  Mapping Optimization:                4.10
  -----------------------------------------
  Overall Compile Time:               17.28
  Overall Compile Wall Clock Time:    18.42

  --------------------------------------------------------------------

  Design  WNS: 0.00  TNS: 0.00  Number of Violating Paths: 0


  Design (Hold)  WNS: 0.00  TNS: 0.00  Number of Violating Paths: 0

  --------------------------------------------------------------------


VIO:
Net:
P2S_i[7].p2s/n4
P2S_i[6].p2s/n4
P2S_i[5].p2s/n4
P2S_i[4].p2s/n4
P2S_i[3].p2s/n4
P2S_i[2].p2s/n4
P2S_i[1].p2s/n4
P2S_i[0].p2s/n4

D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO4I3HDLLX1 
Cell:
P2S_i[7].p2s/U4
P2S_i[6].p2s/U4
P2S_i[5].p2s/U4
P2S_i[4].p2s/U4
P2S_i[3].p2s/U4
P2S_i[2].p2s/U4
P2S_i[1].p2s/U4
P2S_i[0].p2s/U4
CMD:
size_cell P2S_i[7].p2s/U4 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO4I3HDLLX1 
size_cell P2S_i[6].p2s/U4 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO4I3HDLLX1 
size_cell P2S_i[5].p2s/U4 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO4I3HDLLX1 
size_cell P2S_i[4].p2s/U4 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO4I3HDLLX1 
size_cell P2S_i[3].p2s/U4 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO4I3HDLLX1 
size_cell P2S_i[2].p2s/U4 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO4I3HDLLX1 
size_cell P2S_i[1].p2s/U4 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO4I3HDLLX1 
size_cell P2S_i[0].p2s/U4 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/NO4I3HDLLX1 


size_cell P2S_i[0].p2s/U11 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/BUHDLLX1
size_cell P2S_i[2].p2s/U11 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/BUHDLLX1
size_cell P2S_i[1].p2s/U11 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/BUHDLLX1


size_cell fsm/U38 D_CELLS_HDLL_LP5MOS_slow_1_62V_175C/ON21HDLLX2


违例主要是 transition违例,但是时间都在3.5ns左右,并没有超过库里面定义的最大transition(5ns左右), \
并且这个transition并没有导致setup和hold违例,因此就放在Innovus去修。
