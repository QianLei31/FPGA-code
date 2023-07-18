vsim -gui -novopt +nospecify work.BLOCK_DIGITAL_TB


vsim -gui -novopt \
-sdfmin {/BLOCK_DIGITAL_TB/block_digital \
=../BLOCK_DIGITAL/BLOCK_DIGITAL_fast_1_98V_m40C.sdf} \
-sdfmin {/BLOCK_DIGITAL_TB/main_fsm \
=../MAIN_FSM/MAIN_FSM_fast_1_98V_m40C.sdf} \
-sdfnoerror -sdfnowarn work.BLOCK_DIGITAL_TB 

vsim -gui -novopt \
-sdfmax {/BLOCK_DIGITAL_TB/block_digital \
=../BLOCK_DIGITAL/BLOCK_DIGITAL_slow_1_62V_175C.sdf} \
-sdfmax {/BLOCK_DIGITAL_TB/main_fsm \
=../MAIN_FSM/MAIN_FSM_slow_1_62V_125C.sdf} \
-sdfnoerror -sdfnowarn work.BLOCK_DIGITAL_TB 


+notimingchecks

vsim -gui -novopt \
-sdfmax {/BLOCK_DIGITAL_TB/main_fsm \
=D:/XFAB180_Neural_Link_or_Pixel_202205/1_BMI_2022_DIGITAL_ALL_2022_6_9/source_20220731_Neuralpixel/POST_SIM/MAIN_FSM/MAIN_FSM_slow_1_62V_125C.sdf} \
-sdfnoerror -sdfnowarn work.BLOCK_DIGITAL_TB 



counter_1024_chem_reg_3_

vcd file BLOCK_DIGITAL.vcd
vcd add block_digital/*

vcd file MAIN_FSM.vcd
vcd add main_fsm/*

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/code_gen/read_data_out

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/ELE_CHEM_MUX_PIXEL_PROBE \
sim:/BLOCK_DIGITAL_TB/ELE_MUX_PIXEL_PROBE

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/ack_fetch_spi \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/addr \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/chem_out \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/chem_out_cnt \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/chem_out_cnt_1d \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/chem_out_cnt_2d \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/chem_out_cnt_buf \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/chem_out_cnt_pos \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_3p2M \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_3p2M_clone1 \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_3p2M_clone2 \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_3p2M_clone3 \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_clone1 \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_clone2 \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_clone3 \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_clone4 \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_to_elec \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/clk_to_elec_chem \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/code \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/counter_1024 \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/counter_1024_chem \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/current_state \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/current_state_chem \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/data_in \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/data_out \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/data_out_en_1d \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/data_out_en_2d \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/data_out_en_3d \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/data_to_elec \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/data_to_elec_chem \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/elec_addr \
sim:/BLOCK_DIGITAL_TB/main_fsm/fsm/elec_addr_chem


add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/main_fsm/p_data \
sim:/BLOCK_DIGITAL_TB/main_fsm/rdy_spi \
sim:/BLOCK_DIGITAL_TB/main_fsm/rst_n \
sim:/BLOCK_DIGITAL_TB/main_fsm/rst_n_block \
sim:/BLOCK_DIGITAL_TB/main_fsm/rst_n_to_probe \
sim:/BLOCK_DIGITAL_TB/main_fsm/rst_syn_n \
sim:/BLOCK_DIGITAL_TB/main_fsm/rx_output \
sim:/BLOCK_DIGITAL_TB/main_fsm/s_data \
sim:/BLOCK_DIGITAL_TB/main_fsm/sck \
sim:/BLOCK_DIGITAL_TB/main_fsm/spi_busy \
sim:/BLOCK_DIGITAL_TB/main_fsm/tx_input

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_adc0 \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_adc1 \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_adc2 \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_adc3 \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_pre \
sim:/BLOCK_DIGITAL_TB/block_digital/data_to_post

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_adc_buffer \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_pre \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_pre_buf