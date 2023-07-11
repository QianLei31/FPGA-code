`timescale 1ns / 1ps
module SPI_Master(
    input   wire           CLK               ,    // System Clock.
    input   wire           RST_N              ,    // System Reset. Low Active
    input   wire           START              ,    // Start  
    //====== Rx Interface =========================
    input   wire  [ 31 : 0] SPI_CMD         ,    // Rx Read Data
    //====== Tx Interface =====================
    output  wire  [ 31 : 0] spi_miso_data         ,    // Tx Write Data
    //====== ReRAM SPI Interface ===================
    output  wire           SPI_SCLK           ,    // SPI Clock 
    output  wire           SPI_CSN            ,    // SPI Chip Select 
    output  wire           SPI_MOSI           ,    // SPI Master Output 
    input   wire           SPI_MISO                // SPI Master Input
);  
    parameter LEN_SPI=32; //SPI length
    parameter RATIO_SCK       = 10;    // Ratio between sck and CLK
    parameter CYCLES_CS_TO_SCK_DLY = 8'd12; // SPI Chip Select Delay Cycles
    parameter LSB_FIRST       = 1'b1;  // LSB First
    parameter FALLING_LATCH  =1'b1; //Latch the MISO in falling edge
    parameter CSN_WID = 60;//SPI Chip Select KEEP 1 Width
//==============================================================
// Local Registe Declare 
//==============================================================
    reg      en_sck_b; // enable not for sck 
    reg     [ 31 : 0]    shift_reg_spi   ;// Tx Write Data 
    reg     [31:0]       reg_spi_miso_data;
// SPI Interface
    reg                 buf_miso       ;//
    reg                 r_csn          ;// SPI Chip Select
    reg     [ 7 : 0]    cnt_cs_to_sck      ;// SPI Chip Select Count
    reg     [ 7 : 0]    cnt_csn  ;// SPI Clock Count
    reg sck; //SPI Clock always on
    (* dont_touch = "yes" *)(* mark_debug = "true" *)reg     [ 31 : 0]    cnt_spi_shift ;// SPI Write / Read Address Count 
    (* dont_touch = "yes" *)(* mark_debug = "true" *)reg     [ 7 : 0]    state          ;// FSM Current State 
    (* dont_touch = "yes" *)(* mark_debug = "true" *)reg     [ 7 : 0]    state_nxt      ;// ---   Next State
    (* dont_touch = "yes" *)(* mark_debug = "true" *)reg     [ 7 : 0]    cnt_sck_to_sclk  ;
//==============================================================
// Local Parameter Declare 
//==============================================================  
    localparam  ST_IDLE          = 8'h01;    // Idle  State
    localparam  ST_CSN_cnt       = 8'h05;    // Chip  Select Enable
    localparam  ST_CSN_ENABLE    = 8'h02;    // Chip  Select Enable
    localparam  ST_SCK_GATE      = 8'h03;    // SCK Gate State 
    localparam  ST_DATA          = 8'h04;    // Write State Initial  
    localparam  ST_CSN_DISABLE   = 8'h40;    // Chip  Select Disable
    localparam  ST_SCK_READ      = 8'h50;    // SCK Read State 
    localparam  ST_FINISH        = 8'h80;    // Finish State 
//==============================================================
// Generate SPI Clock  sck ，分频比为 RATIO_SCK
//==============================================================
    always @ (posedge CLK or negedge RST_N)begin 
        if(!RST_N) begin
            sck   <=  1'b0;
            cnt_sck_to_sclk <= 0;
        end
        else begin
            if(cnt_sck_to_sclk[7:0]==(RATIO_SCK>>1)-1) begin
                sck   <=  ~sck;
                cnt_sck_to_sclk <=0;
            end
            else begin
                cnt_sck_to_sclk=cnt_sck_to_sclk+1;
                sck <= sck;
            end
        end
    end


 
//==============================================================
// SPI FSM Part 1/3
//==============================================================   
    always @ (posedge sck or negedge RST_N) begin 
        if(!RST_N)
            state          <= ST_IDLE;
        else 
            state          <= state_nxt;        
    end
 
//==============================================================
// SPI FSM Part 2/3
//==============================================================   
    always @ (*) begin 
        state_nxt   =   ST_IDLE;
        
        case(state)
            ST_IDLE:begin
                if(START)begin
                    state_nxt = ST_CSN_cnt;
                end
                else begin
                    state_nxt = ST_IDLE;
                end    
            end
            ST_CSN_cnt:begin
                if(cnt_csn==CSN_WID)begin
                    state_nxt = ST_CSN_ENABLE;   
                end
                else begin
                    state_nxt = ST_CSN_cnt;
                end
            end     
            //======chip select enable===========================
            ST_CSN_ENABLE:begin
                if(cnt_cs_to_sck==CYCLES_CS_TO_SCK_DLY)begin
                        state_nxt = ST_SCK_GATE;   
                end
                else begin
                    state_nxt = ST_CSN_ENABLE;
                end
            end
            ST_SCK_GATE:begin
                state_nxt = ST_DATA;
            end  
            //===========write data===========================
            ST_DATA:begin
                if(cnt_spi_shift == LEN_SPI-1) begin
                    state_nxt = ST_SCK_READ;   //write finish
                end
                else begin
                    state_nxt = ST_DATA;
                end                    
            end
            ST_SCK_READ:begin

                state_nxt = ST_CSN_DISABLE;
                               
            end  
            //===========read data===========================            
            //======chip  disable============================
            ST_CSN_DISABLE:begin
                if((cnt_cs_to_sck==CYCLES_CS_TO_SCK_DLY))begin
                    state_nxt = ST_FINISH;     
                end
                else begin
                    state_nxt = ST_CSN_DISABLE;
                end            
            end  
            //============finish=============================
            ST_FINISH:begin
                state_nxt   =   ST_IDLE;
            end  
            default:begin
                state_nxt   =   ST_IDLE;    
            end        
        endcase                  
    end     

//==============================================================
// SPI FSM Part 3/3
//==============================================================   
    always @ (posedge sck  or negedge RST_N) begin 
        if(!RST_N)begin

            cnt_cs_to_sck <= 0;
            reg_spi_miso_data <= 0;
            r_csn <= 1'b1;
            shift_reg_spi     <= 0;
            cnt_spi_shift <= 0;   
            en_sck_b <= 1;
            cnt_csn <= 0;
            

        end    
        else begin

            reg_spi_miso_data    <= reg_spi_miso_data;
            cnt_cs_to_sck <= cnt_cs_to_sck;
            r_csn <= r_csn;
            shift_reg_spi <= shift_reg_spi;
            cnt_spi_shift <= cnt_spi_shift;

            case(state) 
                ST_IDLE:begin                
                    cnt_cs_to_sck <= 0;
                    shift_reg_spi    <= 0;
                    cnt_spi_shift <= 0;
                    cnt_csn <= 0;
                    
                end 
                ST_CSN_cnt:begin
                    cnt_csn <= cnt_csn + 1'b1;
                end
                //==========chip enable========================
                ST_CSN_ENABLE:begin
                    
                    r_csn <= 1'b0;
                    cnt_cs_to_sck <= cnt_cs_to_sck + 1'b1; 
                  

                end
                ST_SCK_GATE:begin
                    en_sck_b <= 0;                  
                    shift_reg_spi <= SPI_CMD; 
                    cnt_spi_shift <= cnt_spi_shift+1'b1;
                end 
                //===========write data=========================
                ST_DATA:begin           
                    
                    cnt_cs_to_sck <= 0;  
                    r_csn <= 1'b0;    
                    
                    shift_reg_spi <= FALLING_LATCH ? {buf_miso,shift_reg_spi[LEN_SPI-1:1]}:{SPI_MISO,shift_reg_spi[LEN_SPI-1:1]};
                    cnt_spi_shift <= cnt_spi_shift+1'b1;                       
                end
                ST_SCK_READ:begin
                    en_sck_b <= 1;
                    shift_reg_spi <= FALLING_LATCH ? {buf_miso,shift_reg_spi[LEN_SPI-1:1]}:{SPI_MISO,shift_reg_spi[LEN_SPI-1:1]};
                    
                end
                                           
                //========chip  disable============================
                ST_CSN_DISABLE:begin
                    en_sck_b <= 1;
                    reg_spi_miso_data   <=  shift_reg_spi;
                    cnt_cs_to_sck <= cnt_cs_to_sck + 1'b1;
                    r_csn <= 1'b0;
                end
                ST_FINISH:begin   
                    cnt_cs_to_sck <= 0;     
                    r_csn <= 1'b1; 
                    //do nothing
                end
                //========default============================
                default:begin
                    reg_spi_miso_data    <= 0;
                    cnt_cs_to_sck <= 0;
                    r_csn <= 1'b0;
                    shift_reg_spi    <= 0;
                    cnt_spi_shift <= 0;
                end                                                 
            
            endcase  
        end       
    end
    


// latch the MISO in falling edge, effective only when FALLING_LATCH is valid (1)
    always @ (negedge sck)begin
                buf_miso   <= SPI_MISO;   
    end
    //assign  spi_miso_data    =  !r_csn ? shift_reg_spi : 32'd0;
    assign  spi_miso_data    =  reg_spi_miso_data;

//==============================================================
// SPI  Output
//==============================================================  

    assign    SPI_SCLK    =  en_sck_b | sck;
    assign    SPI_CSN     =  r_csn;
    assign    SPI_MOSI    =  LSB_FIRST ? shift_reg_spi[0] : shift_reg_spi[LEN_SPI-1] ;

endmodule

