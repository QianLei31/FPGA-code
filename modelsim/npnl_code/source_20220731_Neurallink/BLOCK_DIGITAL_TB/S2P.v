
module S2P(
    clk,
    rst_n,
    s_data,
    data_valid,
    data_from_blk_0_ch_3,
    data_from_blk_1_ch_3,
    data_from_blk_2_ch_3,
    data_from_blk_3_ch_3,
    data_from_blk_4_ch_3,
    data_from_blk_5_ch_3,
    data_from_blk_6_ch_3,
    data_from_blk_7_ch_3,
    data_from_blk_0_ch_2,
    data_from_blk_1_ch_2,
    data_from_blk_2_ch_2,
    data_from_blk_3_ch_2,
    data_from_blk_4_ch_2,
    data_from_blk_5_ch_2,
    data_from_blk_6_ch_2,
    data_from_blk_7_ch_2,
    data_from_blk_0_ch_1,
    data_from_blk_1_ch_1,
    data_from_blk_2_ch_1,
    data_from_blk_3_ch_1,
    data_from_blk_4_ch_1,
    data_from_blk_5_ch_1,
    data_from_blk_6_ch_1,
    data_from_blk_7_ch_1,
    data_from_blk_0_ch_0,
    data_from_blk_1_ch_0,
    data_from_blk_2_ch_0,
    data_from_blk_3_ch_0,
    data_from_blk_4_ch_0,
    data_from_blk_5_ch_0,
    data_from_blk_6_ch_0,
    data_from_blk_7_ch_0,
);

parameter NUM_COL = 8;   // Block number in one Column
parameter BITS_ADC = 12;
parameter DATA_LENGTHS = BITS_ADC + 1;

input                     s_data; 
input                     data_valid; 
input			          clk;
input                     rst_n;
 
output [BITS_ADC-1:0] data_from_blk_0_ch_3;
output [BITS_ADC-1:0] data_from_blk_1_ch_3;
output [BITS_ADC-1:0] data_from_blk_2_ch_3;
output [BITS_ADC-1:0] data_from_blk_3_ch_3;
output [BITS_ADC-1:0] data_from_blk_4_ch_3;
output [BITS_ADC-1:0] data_from_blk_5_ch_3;
output [BITS_ADC-1:0] data_from_blk_6_ch_3;
output [BITS_ADC-1:0] data_from_blk_7_ch_3;
output [BITS_ADC-1:0] data_from_blk_0_ch_2;
output [BITS_ADC-1:0] data_from_blk_1_ch_2;
output [BITS_ADC-1:0] data_from_blk_2_ch_2;
output [BITS_ADC-1:0] data_from_blk_3_ch_2;
output [BITS_ADC-1:0] data_from_blk_4_ch_2;
output [BITS_ADC-1:0] data_from_blk_5_ch_2;
output [BITS_ADC-1:0] data_from_blk_6_ch_2;
output [BITS_ADC-1:0] data_from_blk_7_ch_2;
output [BITS_ADC-1:0] data_from_blk_0_ch_1;
output [BITS_ADC-1:0] data_from_blk_1_ch_1;
output [BITS_ADC-1:0] data_from_blk_2_ch_1;
output [BITS_ADC-1:0] data_from_blk_3_ch_1;
output [BITS_ADC-1:0] data_from_blk_4_ch_1;
output [BITS_ADC-1:0] data_from_blk_5_ch_1;
output [BITS_ADC-1:0] data_from_blk_6_ch_1;
output [BITS_ADC-1:0] data_from_blk_7_ch_1;
output [BITS_ADC-1:0] data_from_blk_0_ch_0;
output [BITS_ADC-1:0] data_from_blk_1_ch_0;
output [BITS_ADC-1:0] data_from_blk_2_ch_0;
output [BITS_ADC-1:0] data_from_blk_3_ch_0;
output [BITS_ADC-1:0] data_from_blk_4_ch_0;
output [BITS_ADC-1:0] data_from_blk_5_ch_0;
output [BITS_ADC-1:0] data_from_blk_6_ch_0;
output [BITS_ADC-1:0] data_from_blk_7_ch_0;


reg [BITS_ADC-1:0]        data_from_ch[31:0];

// parameter CNT_WIDTH = $clog2(12*32);
reg [11:0] data_out_buf;
// reg [CNT_WIDTH:0] cnt;
reg [9:0] cnt;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        data_out_buf <= 'b0;
        cnt <= 'b0;
    end else begin
        if (1'b0 == data_valid) begin
            data_out_buf <= {s_data,data_out_buf[11:1]};
            if ('d11==cnt) begin
                cnt <= 'b0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end else begin
            cnt <= 'b0;
        end
        
    end
end

// generate
//     genvar i;
//     for (i = 0; i < 32; i++) begin
//         data_from_ch[i] <= 'b0;
//     end
// endgenerate
reg [6:0] ch_cnt;
reg valid_before;
reg valid;
reg conv_finish;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        data_from_ch[31] <= 'b0;
        data_from_ch[30] <= 'b0;
        data_from_ch[29] <= 'b0;
        data_from_ch[28] <= 'b0;
        data_from_ch[27] <= 'b0;
        data_from_ch[26] <= 'b0;
        data_from_ch[25] <= 'b0;
        data_from_ch[24] <= 'b0;
        data_from_ch[23] <= 'b0;
        data_from_ch[22] <= 'b0;
        data_from_ch[21] <= 'b0;
        data_from_ch[20] <= 'b0;
        data_from_ch[19] <= 'b0;
        data_from_ch[18] <= 'b0;
        data_from_ch[17] <= 'b0;
        data_from_ch[16] <= 'b0;
        data_from_ch[15] <= 'b0;
        data_from_ch[14] <= 'b0;
        data_from_ch[13] <= 'b0;
        data_from_ch[12] <= 'b0;
        data_from_ch[11] <= 'b0;
        data_from_ch[10] <= 'b0;
        data_from_ch[9]  <= 'b0;
        data_from_ch[8]  <= 'b0;
        data_from_ch[7]  <= 'b0;
        data_from_ch[6]  <= 'b0;
        data_from_ch[5]  <= 'b0;
        data_from_ch[4]  <= 'b0;
        data_from_ch[3]  <= 'b0;
        data_from_ch[2]  <= 'b0;
        data_from_ch[1]  <= 'b0;
        data_from_ch[0]  <= 'b0;
        ch_cnt  <= 'b0;
    end else begin
        if (1'b0 == data_valid) begin
            if ('d11==cnt) begin
                data_from_ch[ch_cnt] <= {s_data,data_out_buf[11:1]};
                if ('d31==ch_cnt) begin
                    ch_cnt <= 'b0;
                end else begin
                    ch_cnt <= ch_cnt + 1'b1;
                end
            end
        end else begin
            ch_cnt <= 'b0;
        end
        
    end
end
assign data_from_blk_0_ch_3 = data_from_ch[31];
assign data_from_blk_1_ch_3 = data_from_ch[30];
assign data_from_blk_2_ch_3 = data_from_ch[29];
assign data_from_blk_3_ch_3 = data_from_ch[28];
assign data_from_blk_4_ch_3 = data_from_ch[27];
assign data_from_blk_5_ch_3 = data_from_ch[26];
assign data_from_blk_6_ch_3 = data_from_ch[25];
assign data_from_blk_7_ch_3 = data_from_ch[24];
assign data_from_blk_0_ch_2 = data_from_ch[23];
assign data_from_blk_1_ch_2 = data_from_ch[22];
assign data_from_blk_2_ch_2 = data_from_ch[21];
assign data_from_blk_3_ch_2 = data_from_ch[20];
assign data_from_blk_4_ch_2 = data_from_ch[19];
assign data_from_blk_5_ch_2 = data_from_ch[18];
assign data_from_blk_6_ch_2 = data_from_ch[17];
assign data_from_blk_7_ch_2 = data_from_ch[16];
assign data_from_blk_0_ch_1  = data_from_ch[15];
assign data_from_blk_1_ch_1  = data_from_ch[14];
assign data_from_blk_2_ch_1  = data_from_ch[13];
assign data_from_blk_3_ch_1  = data_from_ch[12];
assign data_from_blk_4_ch_1  = data_from_ch[11];
assign data_from_blk_5_ch_1  = data_from_ch[10];
assign data_from_blk_6_ch_1  = data_from_ch[9];
assign data_from_blk_7_ch_1  = data_from_ch[8];
assign data_from_blk_0_ch_0  = data_from_ch[7];
assign data_from_blk_1_ch_0  = data_from_ch[6];
assign data_from_blk_2_ch_0  = data_from_ch[5];
assign data_from_blk_3_ch_0  = data_from_ch[4];
assign data_from_blk_4_ch_0  = data_from_ch[3];
assign data_from_blk_5_ch_0  = data_from_ch[2];
assign data_from_blk_6_ch_0  = data_from_ch[1];
assign data_from_blk_7_ch_0  = data_from_ch[0];

endmodule