//Verilog HDL for "SJTU_SAR_ADC_12BIT_exlayout_ideal", "sar_adc_logic_12bit_v4_single_input_fs"
//"functional"
//20220718 power optimization test
//20220722 pulse use shift register 0
//20220725 revised clock gating logic
module sar_adc_logic_12bit_v4_single_input_fs_v2 ( CLK, RSTN, SAMP_analog,DR, 
        SAMP_RATE_MUX,  WP_RSTN, PULSE);
input CLK;
input RSTN;
input [1:0] SAMP_RATE_MUX;
output DR;
 reg SAMP;
//output [3:0] counter_out;
output reg WP_RSTN;
output reg SAMP_analog;
wire CLKADC;
output reg [11:0]PULSE;

wire CONV_START;

reg SAMP_1d;
reg SAMP_2d;
reg [11:0] counter;
assign DR = SAMP_1d;

assign CONV_START = !(SAMP | SAMP_2d);
assign CLKADC = CONV_START & CLK;

always @(posedge CLK or negedge RSTN)
  begin
     if(!RSTN)
	   begin
	    counter <= 0;
	   end

	 else if (counter == 79 && (SAMP_RATE_MUX==2'b11))
	   begin
	     counter <= 0;
       end

	 else if (counter == 159 && (SAMP_RATE_MUX==2'b10))
	   begin
	     counter <= 0;
       end

	 else if (counter == 199 && (SAMP_RATE_MUX==2'b01))
	   begin
	     counter <= 0;
       end

	 else if (counter == 3199 && (SAMP_RATE_MUX==2'b00))
	   begin
	     counter <= 0;
       end

     else 
        begin
            counter <= counter + 1;
        end  	   
  end

always@(negedge CLK or negedge RSTN)
  begin
    if(!RSTN)
	   begin

		 SAMP_1d <= 1'b1;
		 SAMP_2d <= 1'b1;		 		 
	   end
	 else    
            begin
			   SAMP_1d<=SAMP;
			   SAMP_2d<=SAMP_1d;
            end
  end   

always@(negedge CLK or negedge RSTN)
  begin
    if(!RSTN)
	   begin
		 SAMP	<=	1'b1;		 		 
	   end
	 else
	   begin		
	     if (counter < 14 )
            begin
                SAMP<=1'b0; 		      
           end 	
         else
            begin
			   SAMP<=1'b1;
            end
       end
  end   

always@(posedge CLK or negedge RSTN)
  begin
    if(!RSTN)
	   begin
		 SAMP_analog			<=	1'b1;		 		 
	   end
	 else begin
		 if (counter < 52 )
            begin
               SAMP_analog <=1'b0;               
           end
		else
            begin
               SAMP_analog<=1'b1;
            end 	
       end
  end 

always@(posedge CLK or negedge RSTN)
  begin
    if(!RSTN)
	   begin
		 WP_RSTN <= 1'b1;
	   end
	 else
	   begin	
		 if (counter == 50 )
            begin
                WP_RSTN <=	1'b0;               
           end
         else 
			begin
                WP_RSTN <=	1'b1;
			end				

       end
  end  

always@(posedge CLKADC or negedge WP_RSTN)
	begin
		if(!WP_RSTN)
	   begin
		 PULSE <= 12'b1111_1111_1110;
	   end
	 else
	   begin	
		 PULSE <= {PULSE[0],PULSE[11:1]};
       end
	end


endmodule
