module CB_Logic (
    CH,         // channel
    CLK,        // clock 100KHz-200KHz
    RST_N,      // reset
    AMP_OUT,    // from DAC
    CB_ON,      // control something
    CAN_STI,    // pol[0]
    ANO_STI,    // pol[1]

    AZ_CLK,
    AZ_CLK_N,
    AMP_ON,
    CB_OK,

    CB_CHNL,    //  to DAC

    SW_ANO_N,   // channel to DAC
    SW_CAN      // channel to DAC
);

input CLK;
input AMP_OUT;
input CB_ON;
input RST_N;
input CAN_STI;
input ANO_STI;
input [1:0] CH;


output reg AZ_CLK;
output reg AZ_CLK_N;
output reg AMP_ON;
//output reg ANO_ON_N;
//output reg CAN_ON;
reg ANO_ON_N;
reg CAN_ON;

output reg CB_OK;

output reg [3:0] CB_CHNL;

output reg [3:0] SW_ANO_N;
output reg [3:0] SW_CAN;


reg AMP_OUT_SV;
reg [1:0] AMP_MOD;

reg FST_DATA;

always @(RST_N,  CAN_STI, ANO_STI, AMP_MOD, CB_OK, FST_DATA, AMP_OUT_SV)    //CB CURRENT CHANGE
    begin
        if(RST_N == 1'b0)
            begin
                ANO_ON_N <= 1'b1;
                CAN_ON <= 1'b0; 
            end
        else if(CAN_STI ==1'b1)
            begin
                ANO_ON_N <= 1'b1;
                CAN_ON <= 1'b1; 
            end
        else if(ANO_STI ==1'b1)
            begin
                ANO_ON_N <= 1'b0;
                CAN_ON <= 1'b0; 
            end
        else if((AMP_MOD ==2'b10)&& CB_OK == 1'b0 && FST_DATA == 1'b1)
            begin
                if (AMP_OUT_SV == 1'b0) begin
                    ANO_ON_N <= 1'b0;
                    CAN_ON <= 1'b0;
                end
                else begin
                    ANO_ON_N <= 1'b1;
                    CAN_ON <= 1'b1;
                end
            end
        else
            begin
                ANO_ON_N <= 1'b1;
                CAN_ON <= 1'b0;
            end
    end

always @(*) begin
    if(~RST_N) begin
        SW_ANO_N = 4'b0;
        SW_CAN = 4'b0;
    end else begin
        case (CH)
            2'b00: begin 
                SW_ANO_N[0] = ANO_ON_N;
                SW_CAN[0] = CAN_ON;
                SW_ANO_N[1] = 1'b1;
                SW_CAN[1] = 1'b0;
                SW_ANO_N[2] = 1'b1;
                SW_CAN[2] = 1'b0;
                SW_ANO_N[3] = 1'b1;
                SW_CAN[3] = 1'b0;
            end
            2'b01: begin 
                SW_ANO_N[1] = ANO_ON_N;
                SW_CAN[1] = CAN_ON;
                SW_ANO_N[0] = 1'b1;
                SW_CAN[0] = 1'b0;
                SW_ANO_N[2] = 1'b1;
                SW_CAN[2] = 1'b0;
                SW_ANO_N[3] = 1'b1;
                SW_CAN[3] = 1'b0;
            end
            2'b10: begin 
                SW_ANO_N[2] = ANO_ON_N;
                SW_CAN[2] = CAN_ON;
                SW_ANO_N[0] = 1'b1;
                SW_CAN[0] = 1'b0;
                SW_ANO_N[1] = 1'b1;
                SW_CAN[1] = 1'b0;
                SW_ANO_N[3] = 1'b1;
                SW_CAN[3] = 1'b0;
            end
            2'b11: begin 
                SW_ANO_N[3] = ANO_ON_N;
                SW_CAN[3] = CAN_ON;
                SW_ANO_N[0] = 1'b1;
                SW_CAN[0] = 1'b0;
                SW_ANO_N[1] = 1'b1;
                SW_CAN[1] = 1'b0;
                SW_ANO_N[2] = 1'b1;
                SW_CAN[2] = 1'b0;
            end
        endcase
    end
end

always @(*) begin
    if(~RST_N) begin
        CB_CHNL = 4'b0;
    end else begin
        case (CH)
            2'b00: begin 
                CB_CHNL[0] = CB_ON & ~CB_OK;
                CB_CHNL[3] = 1'b0;
                CB_CHNL[2] = 1'b0;
                CB_CHNL[1] = 1'b0;
            end
            2'b01: begin 
                CB_CHNL[1] = CB_ON & ~CB_OK;
                CB_CHNL[3] = 1'b0;
                CB_CHNL[2] = 1'b0;
                CB_CHNL[0] = 1'b0;
            end
            2'b10: begin 
                CB_CHNL[2] = CB_ON & ~CB_OK;
                CB_CHNL[3] = 1'b0;
                CB_CHNL[1] = 1'b0;
                CB_CHNL[0] = 1'b0;
            end
            2'b11: begin 
                CB_CHNL[3] = CB_ON & ~CB_OK;
                CB_CHNL[2] = 1'b0;
                CB_CHNL[1] = 1'b0;
                CB_CHNL[0] = 1'b0;                
            end
        endcase
    end
end



always @(posedge CLK  or negedge RST_N)    //AMP MODS CHANGE
    begin                                   //00:OFF  10: AZ 11:AZ_AMP 01:Null
        if(RST_N == 1'b0)   
            begin
                AMP_MOD <= 2'b00;
            end
        else if(CB_ON == 1'b0)
            begin
                AMP_MOD <=2'b00;
            end
        else if(AMP_MOD == 2'b00 && CB_OK == 1'b0)  //start CB
            begin
                AMP_MOD <= 2'b10;
            end
        else if(AMP_MOD == 2'b10 && CB_OK == 1'b1 && FST_DATA==1'b1)   //pulse injection ends
            begin
                AMP_MOD <= 2'b00;
            end   
        else if(AMP_MOD == 2'b10)   // AZ, next is AZ_AMP
            begin
                AMP_MOD <= 2'b11;
            end
        else if(AMP_MOD == 2'b11)   //AZ_AMP, next is AZ
            begin
                AMP_MOD <= 2'b10;
            end  
        else
            AMP_MOD <= 2'b00;
    end


always @(posedge CLK  or negedge RST_N)    //CB ajudgement
    begin
        if(RST_N == 1'b0)
            begin
                FST_DATA <= 1'b0;
                CB_OK <= 1'b0;
                AMP_OUT_SV <=1'b0;
            end
        else if(CB_ON == 1'b0)
            begin
                FST_DATA <= 1'b0;
                CB_OK <= 1'b0;
                AMP_OUT_SV <=1'b0;
            end
        else if(AMP_MOD == 2'b11 && FST_DATA==1'b0)   // pulse inject
            begin
                AMP_OUT_SV <= AMP_OUT;
                FST_DATA <= 1'b1;
            end
        else if(AMP_MOD == 2'b11 && FST_DATA == 1'b1)
            begin
                if(AMP_OUT_SV != AMP_OUT)begin
                    CB_OK <=1'b1;
                end
            end
        
    end
always @(RST_N, AMP_MOD)    //AMP switch CHANGE
    begin                              
        if(RST_N == 1'b0)   
            begin
                AZ_CLK <= 1'b1;
                AZ_CLK_N <= 1'b0;
                AMP_ON <= 1'b0;
            end
        else
            begin
                case(AMP_MOD)
                    2'd0:begin   //off
                            AZ_CLK <= 1'b1;
                            AZ_CLK_N <= 1'b0;
                            AMP_ON <= 1'b0;
                         end
                    2'd1:begin    //off
                            AZ_CLK <= 1'b1;
                            AZ_CLK_N <= 1'b0;
                            AMP_ON <= 1'b0;
                         end
                    2'd2:begin    // AZ
                            AZ_CLK <= 1'b1;
                            AZ_CLK_N <= 1'b0;
                            AMP_ON <= 1'b1;
                         end
                    2'd3:begin     //AZ_AMP
                            AZ_CLK <= 1'b0;
                            AZ_CLK_N <= 1'b1;
                            AMP_ON <= 1'b1;
                         end
                    default:begin
                            AZ_CLK <= 1'b1;
                            AZ_CLK_N <= 1'b0;
                            AMP_ON <= 1'b0;
                    end
                endcase 
            end
    end

endmodule