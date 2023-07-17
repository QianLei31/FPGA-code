// Author      : GTT
// Change date : 2022/06/28
// Change log  : single block s2p

module S2P_BLOCK(
    clk,
    rst_n,
    s_data,
    data_valid,
    data_from_ch0,
    data_from_ch1,
    data_from_ch2,
    data_from_ch3
);


parameter BITS_ADC = 12;
parameter DATA_LENGTHS = BITS_ADC + 1;

input                     s_data; 
input                     data_valid; 
input			          clk;
input                     rst_n;
 
output [BITS_ADC-1:0] data_from_ch0;
output [BITS_ADC-1:0] data_from_ch1;
output [BITS_ADC-1:0] data_from_ch2;
output [BITS_ADC-1:0] data_from_ch3;


reg [BITS_ADC-1:0] data_from_ch[3:0];

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
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        data_from_ch[3]  <= 'b0;
        data_from_ch[2]  <= 'b0;
        data_from_ch[1]  <= 'b0;
        data_from_ch[0]  <= 'b0;
        ch_cnt  <= 'b0;
    end else begin
        if (1'b0 == data_valid) begin
            if ('d11==cnt) begin
                data_from_ch[ch_cnt] <= {s_data,data_out_buf[11:1]};
                if ('d3==ch_cnt) begin
                    ch_cnt <= 'b0;
                end else begin
                    ch_cnt <= ch_cnt + 1'b1;
                end
            end
        end else begin
            ch_cnt <= ch_cnt;
        end
        
    end
end


assign data_from_ch0 = data_from_ch[3];
assign data_from_ch1 = data_from_ch[2];
assign data_from_ch2 = data_from_ch[1];
assign data_from_ch3 = data_from_ch[0];

endmodule