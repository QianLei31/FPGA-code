vsim -gui -novopt +nospecify work.BLOCK_DIGITAL_TB


vsim -gui -novopt \
-sdfmax {/BLOCK_DIGITAL_TB/block_digital \
=D:/XFAB180_Neural_Link_or_Pixel_202205/1_BMI_2022_DIGITAL_ALL_2022_6_9/source_20220724\BLOCK_DIGITAL_TB/BLOCK_DIGITAL.sdf} \
-sdfmax {/BLOCK_DIGITAL_TB/main_fsm \
=D:/XFAB180_Neural_Link_or_Pixel_202205/1_BMI_2022_DIGITAL_ALL_2022_6_9/source_20220724\BLOCK_DIGITAL_TB/MAIN_FSM.sdf} \
-sdfnoerror -sdfnowarn work.BLOCK_DIGITAL_TB 




vcd file BLOCK_DIGITAL.vcd
vcd add block_digital/*

vcd file MAIN_FSM.vcd
vcd add main_fsm/*

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/code_gen/clk_50M \
sim:/BLOCK_DIGITAL_TB/code_gen/cs_n \
sim:/BLOCK_DIGITAL_TB/code_gen/data_valid \
sim:/BLOCK_DIGITAL_TB/code_gen/elec_data_read \
sim:/BLOCK_DIGITAL_TB/code_gen/elec_data_write \
sim:/BLOCK_DIGITAL_TB/code_gen/elec_reg0 \
sim:/BLOCK_DIGITAL_TB/code_gen/miso \
sim:/BLOCK_DIGITAL_TB/code_gen/mosi \
sim:/BLOCK_DIGITAL_TB/code_gen/read_data_out \
sim:/BLOCK_DIGITAL_TB/code_gen/reg_map_addr \
sim:/BLOCK_DIGITAL_TB/code_gen/rst_n \
sim:/BLOCK_DIGITAL_TB/code_gen/s_data \
sim:/BLOCK_DIGITAL_TB/code_gen/sck \
sim:/BLOCK_DIGITAL_TB/code_gen/spi_cmd



add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/adc_ready \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/adc_ready_pos \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/adc_ready_z \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/block_cnt \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/clk_3p2M \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/clk_shift \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/data_from_pre \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/data_to_post \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/en_clk_shift_l \
sim:/BLOCK_DIGITAL_TB/block_digital/daisy_chain/rst_n

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_adc0 \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_adc1 \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_adc2 \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_adc3

add wave -position insertpoint  \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_adc0 \
{sim:/BLOCK_DIGITAL_TB/block_e[14]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[13]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[12]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[11]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[10]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[9]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[8]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[7]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[6]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[5]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[4]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[3]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[2]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[1]/fsm_block/data_from_adc0} \
{sim:/BLOCK_DIGITAL_TB/block_e[0]/fsm_block/data_from_adc0} \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_adc1 \
{sim:/BLOCK_DIGITAL_TB/block_e[14]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[13]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[12]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[11]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[10]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[9]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[8]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[7]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[6]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[5]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[4]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[3]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[2]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[1]/fsm_block/data_from_adc1} \
{sim:/BLOCK_DIGITAL_TB/block_e[0]/fsm_block/data_from_adc1} \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_adc2 \
{sim:/BLOCK_DIGITAL_TB/block_e[14]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[13]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[12]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[11]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[10]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[9]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[8]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[7]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[6]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[5]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[4]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[3]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[2]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[1]/fsm_block/data_from_adc2} \
{sim:/BLOCK_DIGITAL_TB/block_e[0]/fsm_block/data_from_adc2} \
sim:/BLOCK_DIGITAL_TB/block_digital/fsm_block/data_from_adc3 \
{sim:/BLOCK_DIGITAL_TB/block_e[14]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[13]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[12]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[11]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[10]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[9]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[8]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[7]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[6]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[5]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[4]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[3]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[2]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[1]/fsm_block/data_from_adc3} \
{sim:/BLOCK_DIGITAL_TB/block_e[0]/fsm_block/data_from_adc3} 

