# 38.4MHz domain  
ideal net  : clk_50M  ;#Chip clock  
ideal net  : rst_n    ;# Asynchronous rst_n
input net  : chem_out ;# input from probe

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

output net : data_to_elec ;# data to ELEC in probe
output net : clk_to_elec  ;# clk to ELEC in probe
output net : data_to_elec_chem  ;# data to ELEC CHEM in probe
output net : clk_to_elec_chem   ;# data to ELE

output net : rst_n_to_probe ;# Reset ALL ELEC 

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
Date   : Sun Aug 21 14:32:37 2022
****************************************


  Timing Path Group 'CLK_3P2M'
  -----------------------------------
  Levels of Logic:               6.00
  Critical Path Length:         14.03
  Critical Path Slack:           9.97
  Critical Path Clk Period:    312.00
  Total Negative Slack:          0.00
  No. of Violating Paths:        0.00
  Worst Hold Violation:          0.00
  Total Hold Violation:          0.00
  No. of Hold Violations:        0.00
  -----------------------------------

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
  Hierarchical Cell Count:        166
  Hierarchical Port Count:       1030
  Leaf Cell Count:               6597
  Buf/Inv Cell Count:             456
  Buf Cell Count:                 194
  Inv Cell Count:                 262
  CT Buf/Inv Cell Count:           17
  Combinational Cell Count:      3580
  Sequential Cell Count:         3017
  Macro Count:                      0
  -----------------------------------


  Area
  -----------------------------------
  Combinational Area:    53105.839564
  Noncombinational Area:
                        220945.067116
  Buf/Inv Area:           7390.321566
  Total Buffer Area:          5400.76
  Total Inverter Area:        1989.56
  Macro/Black Box Area:      0.000000
  Net Area:              14744.784064
  -----------------------------------
  Cell Area:            274050.906680
  Design Area:          288795.690743


  Design Rules
  -----------------------------------
  Total Number of Nets:          6722
  Nets With Violations:           114
  Max Trans Violations:           114
  Max Cap Violations:               3
  -----------------------------------


  Hostname: kilicontech02

  Compile CPU Statistics
  -----------------------------------------
  Resource Sharing:                    1.58
  Logic Optimization:                  2.88
  Mapping Optimization:               22.34
  -----------------------------------------
  Overall Compile Time:               57.33
  Overall Compile Wall Clock Time:    58.16

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

违例主要是 transition违例,但是时间都在3.5ns左右,并没有超过库里面定义的最大transition(5ns左右), \
并且这个transition并没有导致setup和hold违例,因此就放在Innovus去修。
