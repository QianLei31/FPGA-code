vsim -gui -novopt +nospecify work.BLOCK_DIGITAL_TB


vsim -gui -novopt \
-sdfmax {/BLOCK_DIGITAL_TB/block_digital \
=../BLOCK_DIGITAL/BLOCK_DIGITAL_slow_1_62V_175C.sdf} \
-sdfmax {/BLOCK_DIGITAL_TB/main_fsm \
=../MAIN_FSM/MAIN_FSM_slow_1_62V_125C.sdf} \
-sdfnoerror -sdfnowarn work.BLOCK_DIGITAL_TB 


vsim -gui -novopt \
-sdfmin {/BLOCK_DIGITAL_TB/block_digital \
=../BLOCK_DIGITAL/BLOCK_DIGITAL_fast_1_98V_m40C.sdf} \
-sdfmin {/BLOCK_DIGITAL_TB/main_fsm \
=../MAIN_FSM/MAIN_FSM_fast_1_98V_m40C.sdf} \
-sdfnoerror -sdfnowarn work.BLOCK_DIGITAL_TB 


+notimingchecks 

vcd file BLOCK_DIGITAL.vcd
vcd add block_digital/*

vcd file MAIN_FSM.vcd
vcd add main_fsm/*

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/code_gen/clk_50M \
sim:/BLOCK_DIGITAL_TB/code_gen/cs_n \
sim:/BLOCK_DIGITAL_TB/code_gen/data_valid \
sim:/BLOCK_DIGITAL_TB/code_gen/miso \
sim:/BLOCK_DIGITAL_TB/code_gen/mosi \
sim:/BLOCK_DIGITAL_TB/code_gen/read_data_out \
sim:/BLOCK_DIGITAL_TB/code_gen/rst_n \
sim:/BLOCK_DIGITAL_TB/code_gen/s_data \
sim:/BLOCK_DIGITAL_TB/code_gen/sck 


add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/main_fsm/ack_fetch_spi \
sim:/BLOCK_DIGITAL_TB/main_fsm/addr \
sim:/BLOCK_DIGITAL_TB/main_fsm/clk_3p2M \
sim:/BLOCK_DIGITAL_TB/main_fsm/clk_50M \
sim:/BLOCK_DIGITAL_TB/main_fsm/code \
sim:/BLOCK_DIGITAL_TB/main_fsm/cs_n \
sim:/BLOCK_DIGITAL_TB/main_fsm/data_in \
sim:/BLOCK_DIGITAL_TB/main_fsm/data_out \
sim:/BLOCK_DIGITAL_TB/main_fsm/data_valid \
sim:/BLOCK_DIGITAL_TB/main_fsm/miso \
sim:/BLOCK_DIGITAL_TB/main_fsm/mosi

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/main_fsm/p_data \
sim:/BLOCK_DIGITAL_TB/main_fsm/rdy_spi \
sim:/BLOCK_DIGITAL_TB/main_fsm/rst_n \
sim:/BLOCK_DIGITAL_TB/main_fsm/rst_n_block \
sim:/BLOCK_DIGITAL_TB/main_fsm/rst_syn_n \
sim:/BLOCK_DIGITAL_TB/main_fsm/rx_output \
sim:/BLOCK_DIGITAL_TB/main_fsm/s_data \
sim:/BLOCK_DIGITAL_TB/main_fsm/sck \
sim:/BLOCK_DIGITAL_TB/main_fsm/spi_busy \
sim:/BLOCK_DIGITAL_TB/main_fsm/tx_input

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/code_gen/read_data_out

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/block_digital/rst_n \
sim:/BLOCK_DIGITAL_TB/block_digital/rst_syn_n
add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/block_digital/OFF_STIM_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/OFF_STIM_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/OFF_STIM_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/OFF_STIM_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/POL_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/POL_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/POL_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/POL_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/Rec_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/Rec_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/Rec_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/Rec_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/SAMP \
sim:/BLOCK_DIGITAL_TB/block_digital/SAMP_RATE_MUX \
sim:/BLOCK_DIGITAL_TB/block_digital/SAMP_analog \
sim:/BLOCK_DIGITAL_TB/block_digital/STIM_AMP_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/STIM_AMP_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/STIM_AMP_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/STIM_AMP_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/SW_ANO_N_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/SW_ANO_N_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/SW_ANO_N_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/SW_ANO_N_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/SW_CAN_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/SW_CAN_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/SW_CAN_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/SW_CAN_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/WP0 \
sim:/BLOCK_DIGITAL_TB/block_digital/WP1 \
sim:/BLOCK_DIGITAL_TB/block_digital/WP2 \
sim:/BLOCK_DIGITAL_TB/block_digital/WP3 \
sim:/BLOCK_DIGITAL_TB/block_digital/addr \
sim:/BLOCK_DIGITAL_TB/block_digital/clk_3p2M \
sim:/BLOCK_DIGITAL_TB/block_digital/clk_CB_LOGIC \
sim:/BLOCK_DIGITAL_TB/block_digital/code \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_adc0 \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_adc1 \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_adc2 \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_adc3 \
sim:/BLOCK_DIGITAL_TB/block_digital/data_from_pre \
sim:/BLOCK_DIGITAL_TB/block_digital/data_in \
sim:/BLOCK_DIGITAL_TB/block_digital/data_out \
sim:/BLOCK_DIGITAL_TB/block_digital/data_to_post \
sim:/BLOCK_DIGITAL_TB/block_digital/elec_mux \
sim:/BLOCK_DIGITAL_TB/block_digital/elec_sel_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/elec_sel_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/elec_sel_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/elec_sel_3
add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/block_digital/D_HP
add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_ON_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_ON_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_ON_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_ON_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_OUT_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_OUT_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_OUT_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_OUT_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_X50_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_X50_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_X50_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/AMP_X50_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/AZ_CLK_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/AZ_CLK_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/AZ_CLK_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/AZ_CLK_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/AZ_CLK_N_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/AZ_CLK_N_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/AZ_CLK_N_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/AZ_CLK_N_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_CHNL_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_CHNL_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_CHNL_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_CHNL_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_OK_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_OK_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_OK_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_OK_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_ON_0 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_ON_1 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_ON_2 \
sim:/BLOCK_DIGITAL_TB/block_digital/CB_ON_3 \
sim:/BLOCK_DIGITAL_TB/block_digital/COMP