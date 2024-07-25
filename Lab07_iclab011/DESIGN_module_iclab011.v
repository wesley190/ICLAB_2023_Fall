module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

reg [31:0] out_tmp_comb;
always @(*) begin 
    out_tmp_comb = seed_out;
    if(in_valid) out_tmp_comb = seed_in;
end
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        seed_out <= 0;
    end 
    else begin
        seed_out <= out_tmp_comb;      
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_valid <= 0;
    end 
    else if(out_idle && in_valid) begin
        out_valid <= 1;
    end
    else if(!out_idle) begin
        out_valid <= 0;
    end
end





endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output out_valid;
output [31:0] rand_num;
output busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

// ===============================================================
//                      reg & wire
// ===============================================================

reg [31:0] in_tmp, shift_A, shift_B, shift_C;
reg [8:0] exe_count;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        exe_count <= 0;
    end 
    else if(busy) begin
        exe_count <= exe_count + 1;  
    end
    else if(fifo_full) begin
        exe_count <= exe_count;
    end
    else if(in_valid) begin
        exe_count <= 0;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        in_tmp <= 0;
    end 
    else if(in_valid) begin
        in_tmp <= seed;  
    end
    else if(!fifo_full) begin
        in_tmp <= shift_C;
    end
end

always @(*) begin
    
    shift_A = in_tmp ^ (in_tmp << 13);
    shift_B = shift_A ^ (shift_A >> 17);
    shift_C = shift_B ^ (shift_B << 5);
    
end

reg busy_reg;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        busy_reg <= 0;
    end 
    else if(in_valid && exe_count==0) begin
        busy_reg <= 1;
    end
    else if(exe_count == 257)begin
        busy_reg <= 0;
    end
end

assign busy = busy_reg;
assign out_valid =  (exe_count >= 1 && exe_count <= 258 && !fifo_full)? 1 : 0;
assign rand_num =  shift_C;


endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

reg [8:0] out_count;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_count <= 0;
    end 
    else if(out_count == 258)begin
        out_count <= 0;
    end
    else if(fifo_rinc) begin
        out_count <= out_count +1;
    end
    
end


always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        out_valid <= 0;
        rand_num <= 0;
    end 
    else if(fifo_rinc && out_count>=2 && out_count<=257) begin
        rand_num <= fifo_rdata;
        out_valid <= 1;
    end
    else begin
        out_valid <=0;
        rand_num <= 0;
    end
end
assign fifo_rinc = (!fifo_empty)? 1 : 0;

endmodule