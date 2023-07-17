// Standard SPI module (slave mode)
// Function:
// Two separate clocks for internal and external communication.
// Internal interface to FSM is parallel. It can be converted to serial via a SIPO with proper handshake with this code.
// Change Log:
// 2013         Yan Liu     Initial version
// 13/08/2014   Song Luan   Code clean-up, added tri-state on MISO.
// 15/11/2014   Yan Liu     correct BUSY.
// 17/10/2019   Yan Liu     Dual clock to latch the busy and data.
//LSB first, 
 //sck cs_n in-active high
//data MISO change at the rising edge, bit0 will be ready after cs_n is low,
//latch results from MOSI, 1st falling edge as in CANDO4
module spi_std_slave (
    // Standard SPI interface
    sck,        // SPI clock
    miso,       // Master IN slave Out lsb first, Latched in in falling edge
    mosi,       // Master Out slave IN lsb first, changed in falling edge
    cs_n,        // Chip select (low active)

    // Tristate pad control on MISO
    //HiZ_on,     // Turn on HiZ state on MISO pad (high active) 

    // Internal parallel interface


    clk,        //Chip clock 
    rst_n,      // Asynchronous rst_n
    tx_input,   // Transmission data in FSM-> SPI -> SPI MASTER
    rx_output,  // Receiving data SPI MASTER -> SPI -> FSM
    push_tx,  //high to update data.
    spi_busy,  // Transceiver is busy (high active), will be low if is idel or tx rx finished
    ack_fetch_spi, //from fsm to inform the spi engine that fectch is done.
    rdy_spi //transceiver is ready , data is valid during when rdy is high.

);

parameter LEN_SPI = 32 ; //packet data only after decoding and header removeal
parameter BITS_CNT_SPI = 6 ;

// SPI interface
input sck, mosi, cs_n;
output reg miso;

// Tristate pad control on MISO
//output wire HiZ_on;

// Internal parallel interface to FSM
input rst_n,clk;
input [LEN_SPI-1:0] tx_input;
input push_tx,ack_fetch_spi;

output reg [LEN_SPI-1:0] rx_output;
output reg spi_busy;
output rdy_spi;

reg [LEN_SPI-1:0] fifo_tx;
reg [2:0] st_ctrl_spi;

// internal registers and variables
reg [LEN_SPI-1:0] tr_cycle_buffer;  // Shift registers for transceiver
reg [BITS_CNT_SPI-1:0] cnt_tx,cnt_rx;
reg mosi_latched;

//cycle through tx buffer 
always @(posedge sck or negedge rst_n) begin
    if (!rst_n) begin
        // rst_n
        tr_cycle_buffer <= 'd0;
        cnt_tx <= 0;
    end
    else if (cs_n == 1'b0) begin
        // If chip is selected
        case (cnt_tx)
            0: begin 
                tr_cycle_buffer [LEN_SPI-2: 0] <= fifo_tx[LEN_SPI-1 : 1];
                tr_cycle_buffer [LEN_SPI-1] <= mosi_latched;
                cnt_tx <= cnt_tx + 1;
            end
            LEN_SPI-1: begin 
                cnt_tx <= 0;
                tr_cycle_buffer <= {mosi_latched,tr_cycle_buffer[LEN_SPI-1:1]};
            end
            default : begin
                /* default */
                cnt_tx <= cnt_tx + 1;
                tr_cycle_buffer <= {mosi_latched,tr_cycle_buffer[LEN_SPI-1:1]};
            end
        endcase
    end
end

//miso is changed depends on the number of edge
always @(cs_n,cnt_tx,fifo_tx,tr_cycle_buffer) begin
    miso = 0;
    if(~cs_n && cnt_tx==0) begin
        miso = fifo_tx[0];
    end
    if(~cs_n && cnt_tx!=0) begin
        miso = tr_cycle_buffer[0];
    end
end

//cycle through rx buffer
//latch results from MOSI, 1st falling edge as in CANDO4
always @(negedge sck or negedge rst_n) begin
    if (~rst_n) begin
        // rst_n
        mosi_latched <=0;
        cnt_rx <=0;
    end
    else if(cs_n) begin 
        mosi_latched <=0;
        cnt_rx <=0;
    end
    else begin
      if (cs_n == 1'b0) begin
        // If chip is selected
        mosi_latched <= mosi;
        cnt_rx <=cnt_rx+1;
        if (cnt_rx == LEN_SPI-1) begin 
          cnt_rx<= 0;
        end
      end
    end
end
// master £º miso poseedge output
// slave  £º miso negedge read
 
reg [2:0] sck_z;
reg [2:0] cs_n_z;
//statemachine for spi controller
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
    	sck_z <= 0;
        cs_n_z <= 0;
        fifo_tx <= 0;
        st_ctrl_spi <= 0;
    end else begin
        fifo_tx <= fifo_tx;
        cs_n_z[2:0] <= {cs_n_z[1:0],cs_n};
        sck_z[2:0] <= {sck_z[1:0],sck};
        if (sck_z[2:1]==2'b01 ) begin //rising edge
	        case (st_ctrl_spi)
	            3'b000: begin //idle
	              if (cnt_rx != 0) begin 
	                  st_ctrl_spi <= 3'b001;
	              end
	              else begin 
	                  st_ctrl_spi <= 3'b000;
	              end
	            end
	            3'b001: begin //wait for transmission finished
	              if (cnt_tx == LEN_SPI-1) begin 
	                  st_ctrl_spi <= 3'b010;
	              end
	              else begin 
	                  st_ctrl_spi <= 3'b001;
	              end
	            end
	            3'b010: begin //wait for transmission finished
	              if (cnt_tx == 0) begin 
	                  st_ctrl_spi <= 3'b011;
	              end
	              else begin 
	                  st_ctrl_spi <= 3'b010;
	              end
	            end

	            3'b011: begin //wait for data to be fetched
	              if (cnt_rx != 0) begin 
	                  st_ctrl_spi <= 3'b010;
	              end
	              else begin
	                if (ack_fetch_spi == 1) begin 
	                    st_ctrl_spi <= 3'b000;
	                end
	                else begin 
	                    st_ctrl_spi <= 3'b011;
	                end
	              end
	            end
	            default : st_ctrl_spi <= 3'b000;
	        endcase
	        //if push tx high, the fifo get pushed, warning, will clear the previous data.
        end
    	if (push_tx && (cnt_rx == 0)) begin 
            fifo_tx <= tx_input;
        end
    end
end


reg rdy_spi_buf;
reg rdy_spi_buf_d1;
always @(posedge clk or negedge rst_n)
	if(!rst_n)
		rdy_spi_buf_d1 <= 0;
	else 
		rdy_spi_buf_d1 <= rdy_spi_buf;

assign rdy_spi = (rdy_spi_buf==1 && rdy_spi_buf_d1==0);

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		spi_busy <= 0;
        rdy_spi_buf <= 0;
        rx_output <= 0;
	end
	else begin
		  case (st_ctrl_spi)
			  3'b000: begin //idle
				spi_busy <= 0;
				rdy_spi_buf <= 0;
				rx_output <= 0;
			  end
			  3'b001: begin //wait for transmission finished
				spi_busy <= 1;
				rdy_spi_buf <= 0;
				rx_output <= 0;
			  end
			  3'b010: begin //wait for transmission finished
				spi_busy <= 1;
				rdy_spi_buf <= 0;
				rx_output <= 0;
			  end
			  3'b011: begin //wait for data to be fetched
				spi_busy <= 0;
				rdy_spi_buf <= 1;
				rx_output <= tr_cycle_buffer;
			  end
			  default :begin
				spi_busy <= 0;
				rdy_spi_buf <= 0;
				//rx_output <= 0;
			  end 
		  endcase
	end

end

endmodule