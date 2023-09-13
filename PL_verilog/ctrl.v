`timescale 1ns/10ps
module ctrl(
input clk,
input rst,
input start,
input valid,
input [8191:0] ADC_data,
input S_AXIS_tready,
output reg S_AXIS_tvalid,
output reg S_AXIS_tlast,
output reg [31:0] S_AXIS_tdata
);

reg [1:0] state;
reg [31:0] cnt;
always@(posedge clk) begin
  if(!rst) begin 
    S_AXIS_tvalid <= 1'b0;
    S_AXIS_tlast <= 1'b0;
    S_AXIS_tdata <= 32'd0;
    state <= 0;
    cnt <= 32'd0;
   
  end
  else begin
    case(state) //状态机
    0: begin
      if(start&&S_AXIS_tready&&valid) begin //启动信号到来且FIFO可写
        S_AXIS_tvalid <= 1'b1;       //设置写FIFO有效
        state <= 1;
        cnt <= 32'd0;
        S_AXIS_tdata<=ADC_data[31:0];
      end
      else begin
        S_AXIS_tvalid <= 1'b0;
        state <= 0;
      end
    end
    1:begin
      if(S_AXIS_tready) begin //FIFO可写
        S_AXIS_tdata <= ADC_data[(cnt+1)*32+:32];
        cnt <= cnt + 32'b1;
        if(cnt == 32'd254) begin //判断是否结束
          S_AXIS_tlast <= 1'b1;//发送最后一个数据
          state <= 2;
        end
        else begin//等待数据发完
          S_AXIS_tlast <= 1'b0;
          state <= 1;
        end
      end
      else begin//等待FIFO可写
        S_AXIS_tdata <= S_AXIS_tdata;
        state <= 1;
      end
    end
    2:begin
      if(!S_AXIS_tready) begin //FIFO满则等待
        S_AXIS_tvalid <= 1'b1;
        S_AXIS_tlast <= 1'b1;
        S_AXIS_tdata <= S_AXIS_tdata;
        state <= 2;
      end
      else begin //写入结束
        S_AXIS_tvalid <= 1'b0;
        S_AXIS_tlast <= 1'b0;
        S_AXIS_tdata <= 32'd0;
        state <= 0;
        cnt <= 32'd0;
      end
    end
    default: state <=0;
    endcase
  end
end
endmodule