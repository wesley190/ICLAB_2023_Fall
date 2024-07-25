//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
    AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//

//================================================================
//  FSM parameter
//================================================================
reg [2:0] current_state, next_state;
parameter IDLE        = 3'd0;
parameter INPUT       = 3'd1;
parameter DRAM2SD_AXI = 3'd2;
parameter DRAM2SD_SPI = 3'd3;
parameter SD2DRAM_AXI = 3'd4;
parameter SD2DRAM_SPI = 3'd5;
parameter OUTPUT      = 3'd6;


//==============================================//
//           reg & wire declaration             //
//==============================================//
reg direction_reg;
reg command_flag, get_sd_data_flag;

genvar i;
integer idx;
reg [7:0] miso_temp = {8'b1};
reg [63:0] C_data_r;
reg [47:0] SD_command;


//==============================================//
// AXI read                                     //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                      AR_ADDR <= 0 ;
    else if(in_valid && !direction && current_state == DRAM2SD_AXI) AR_ADDR <= {19'b0, addr_dram};
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                        AR_VALID <= 0;
    else if(in_valid && !direction && current_state == DRAM2SD_AXI)   AR_VALID <= 1;
    else if(AR_READY )                 AR_VALID <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)        R_READY <= 0;
    else if(AR_READY) R_READY <= 1;
    else if(R_VALID)  R_READY <= 0;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)       C_data_r <= 0 ;
    else if(R_VALID) C_data_r <= R_DATA;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  out_valid <= 0 ;
    else if(B_VALID || R_VALID) out_valid <= 1;
    else out_valid <= 0 ;
end
//==============================================//
// SPI write                                    //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(current_state == DRAM2SD_SPI)begin
        SD_command <= {2'b01, 6'd24, 16'b0, addr_sd, }
        for(idx = )
    end
end
always @(posedge clk or negedge rst_n) begin
    if(current_state == DRAM2SD_SPI)begin
        miso_temp[7:0] <= {miso_temp[6:0], MISO};
        if(miso_temp == 8'b0)begin
            
        end
    end
end
generate
    if(current_state == DRAM2SD_SPI) begin
        for (i = 39; i >= 0; i= i-1) begin
            MOSI = AR_ADDR[i];
        end        
    end
endgenerate
//==============================================//
// SPI read                                     //
//==============================================//
//==============================================//
// AXI write                                    //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                     AW_ADDR <= 0 ;
    else if(in_valid && direction) AW_ADDR <= {19'd0, addr_dram};
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                     AW_VALID <= 0;
    else if(in_valid && direction) AW_VALID <= 1;
    else if(AW_READY)              AW_VALID <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)        W_VALID <= 0;
    else if(AW_READY) W_VALID <= 1;
    else if(W_READY)  W_VALID <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)        B_READY <= 0;
    else if(AW_READY) B_READY <= 1;
    else if(B_VALID)  B_READY <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                     W_DATA <= 0 ;
    // else if(in_valid && direction) W_DATA <= C_data_w;
end


//==============================================//
// FSM                                          //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)     current_state <= IDLE ;
    else            current_state <= next_state ;
end

always @(*) begin
    if (!rst_n) 
        next_state = IDLE;
    else begin
        case (current_state)
            IDLE        : begin
                if(in_valid)begin
                    if(!direction) next_state = DRAM2SD_AXI;
                    else next_state = SD2DRAM_SPI;
                end
                else next_state = IDLE;
            end
            DRAM2SD_AXI : next_state = (R_VALID)?DRAM2SD_SPI : DRAM2SD_AXI;
            DRAM2SD_SPI : next_state = (spi_fin)? OUTPUT : DRAM2SD_SPI;
            SD2DRAM_AXI : next_state = (B_VALID)? OUTPUT : SD2DRAM_AXI;
            SD2DRAM_SPI : next_state = (spi_fin)? SD2DRAM_AXI : SD2DRAM_SPI;
            OUTPUT      : next_state = (out_fin)? IDLE : OUTPUT     ;
            default: next_state = IDLE;
        endcase
    end
end

endmodule

