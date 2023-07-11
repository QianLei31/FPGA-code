# simulation do file for the debug SPI /NP/NL 20230707
# do D:/FPGA/gtt/test_np/POST_SIM_20220922/TB/run_sim.do





#

#vlog D:/FPGA/gtt/test_np/POST_SIM_20220922/MAIN_FSM/MAIN_FSM_phys_phycell.v

#restart -nowave
add wave -position insertpoint sim:/BLOCK_DIGITAL_TB/main_fsm/spi_slave/*
add wave -position 12 sim:/BLOCK_DIGITAL_TB/main_fsm/spi_slave/N166
add wave -position 12 sim:/BLOCK_DIGITAL_TB/main_fsm/spi_slave/tr_cycle_buffer
add wave -position 12 sim:/BLOCK_DIGITAL_TB/main_fsm/spi_slave/N127
add wave -position 12 sim:/BLOCK_DIGITAL_TB/main_fsm/spi_slave/cnt_rx


add wave -position 1 sim:/BLOCK_DIGITAL_TB/code_gen/*
add wave -position 1 sim:/BLOCK_DIGITAL_TB/code_gen/dly_ns_display
add wave -position 1 sim:/BLOCK_DIGITAL_TB/code_gen/clk_50M

run 300ms

