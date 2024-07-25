module Handshake_syn #(parameter WIDTH=32) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;
// ===============================================================
//                      reg & wire
// ===============================================================
// ===============================================================
//                      dest control
// ===============================================================
always @(posedge dclk or negedge rst_n) begin
    if(~rst_n) begin
        dack <= 0;
    end
    else if(!dbusy && dreq) begin
        dack <= 1;
    end
    else begin
        dack <= 0;
    end
end

// ===============================================================
//                      src control
// ===============================================================
reg [31:0] data_tmp;

always @(posedge sclk or negedge rst_n) begin
    if(~rst_n) begin
        data_tmp <= 0;
    end 
    else if(sready && !sack) begin
        data_tmp <= din;
    end
end

always @(posedge sclk or negedge rst_n) begin
    if(~rst_n) begin
        sreq <= 0;
    end
    else if(sready && !sack) begin
        sreq <= 1;
    end
    else if( sack ) begin
        sreq <= 0;
    end
    else begin
        sreq <= sreq;
    end
end

assign sidle = !sreq;

NDFF_syn s1(.D    (sreq), .Q    (dreq), .clk  (dclk), .rst_n(rst_n));
NDFF_syn s2(.D    (dack), .Q    (sack), .clk  (sclk), .rst_n(rst_n));

//din stable
always @(posedge dclk or negedge rst_n) begin
    if(~rst_n) begin
        dvalid <= 0;
    end 
    else if( dreq && !dbusy) begin
        dvalid <= 1;
    end
    else begin
        dvalid <= 0;
    end
end

always @(posedge dclk or negedge rst_n) begin
    if(~rst_n) begin
        dout <= 0;
    end 
    else if( dreq && !dbusy) begin
        dout <= data_tmp;
    end
      
end

endmodule