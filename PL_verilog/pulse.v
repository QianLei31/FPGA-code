//detects the rising edge of the start signal and generates a pulse of severial clock cycles to start the read adc data process
`timescale 1ns/10ps
module pulse(

input   wire           CLK               ,    // System Clock.
input   wire           RST_N              ,    // System Reset. Low Active
input   wire           START              ,    // Start  
output  wire           finish              // Finish flag 
);


reg start_before;
reg start;
reg start_init;
reg [7:0] start_cnt;
reg     [ 7 : 0]    state          ;
reg     [ 7 : 0]    state_nxt      ;
localparam  ST_IDLE          = 8'h01;
localparam  ST_START          = 8'h04;
localparam  ST_FINISH        = 8'h80; 
always @ (posedge CLK or negedge RST_N) begin 
        if(!RST_N)
            state          <= ST_IDLE;
        else 
            state          <= state_nxt;        
    end
always @ (*) begin 
        state_nxt   =   ST_IDLE;
        
        case(state)
            ST_IDLE:begin
                if(start_before == 0 && start == 1)
                    state_nxt = ST_START;
                else 
                    state_nxt = ST_IDLE;    
            end
			ST_START:begin
				if (start_cnt==8'h8)
					state_nxt = ST_FINISH;
				else begin
					state_nxt = ST_START;
				end
			end
            ST_FINISH:begin
                state_nxt   =   ST_IDLE;
            end  
            default:begin
                state_nxt   =   ST_IDLE;    
            end   
		endcase
end  
always @( posedge CLK )
	begin
		if ( RST_N == 1'b0 )
	    begin
	      start  <= 0;
		  start_before <= 0;
		  start_init <= 0;
		  start_cnt <= 0;
	    end 
	    else begin
			start<=start;
			start_before <= start_before;
			start_init <= start_init;
			start_cnt <= start_cnt;
			case (state)
				ST_IDLE:begin
					start_before <= start;
	        		start<=START;
					start_cnt <= 0;
					start_init <= 0;					


				end
				ST_START:begin
					start_before <= start;
	        		start<=START;
					start_init <= 1;
					start_cnt <= start_cnt + 1;
				end
				ST_FINISH:begin
					start_init <= 0;
					start_cnt <= 0;
					start_before <= start;
	        		start<=START;
				end
				default:begin
					start <= 0;
					start_cnt <= 0;
				end
			endcase
		end
	end

assign finish = start_init;


endmodule