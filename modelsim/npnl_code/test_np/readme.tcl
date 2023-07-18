sar_adc_logic_12bit_v4_single_input_conv_v1.v

DFRRSQHDLLX0 I39 ( .Q(WP[0]), .D(LOGIC0), .C(LOGIC0), .SN(PULSE[1]),
     .RN(WP_RSTN));

这两个引脚(C和RN)时序问题,上升沿太近会有违例.
前仿的时候,没有线延时,这两个信号的边沿有一个相对固定的延时时间,看了蔡博的前仿波形,这个时间大概是400ps,不会违反库里定义的320ps的设置,所以前仿没有看出来问题
后仿的时候,由于布局布线的线延时会导致这两个信号的上升沿的间隔时间不固定,可能比400ps高也可能低
如果延时变高,那没问题,不会有违例
如果延时变低就会违例
现在想着是插一个delay_cell,让时钟固定先延时1ns

没有直接修改sar_adc_logic_12bit_v4_single_input_conv_v1.v文件的网表,而是在已有的版图上面做了ECO,手动添加了DLY CELL。