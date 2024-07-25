module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

reg [$clog2(WORDS):0] wptr_b;
reg [$clog2(WORDS):0] rptr_b;

// rdata
//  Add one more register stage to rdata
always @(posedge rclk) begin
    if (rinc)
        rdata <= rdata_q;
end

DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(!winc),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(wptr_b[0]),
    .A1(wptr_b[1]),
    .A2(wptr_b[2]),
    .A3(wptr_b[3]),
    .A4(wptr_b[4]),
    .A5(wptr_b[5]),
    .B0(rptr_b[0]),
    .B1(rptr_b[1]),
    .B2(rptr_b[2]),
    .B3(rptr_b[3]),
    .B4(rptr_b[4]),
    .B5(rptr_b[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIA8(wdata[8]),
    .DIA9(wdata[9]),
    .DIA10(wdata[10]),
    .DIA11(wdata[11]),
    .DIA12(wdata[12]),
    .DIA13(wdata[13]),
    .DIA14(wdata[14]),
    .DIA15(wdata[15]),
    .DIA16(wdata[16]),
    .DIA17(wdata[17]),
    .DIA18(wdata[18]),
    .DIA19(wdata[19]),
    .DIA20(wdata[20]),
    .DIA21(wdata[21]),
    .DIA22(wdata[22]),
    .DIA23(wdata[23]),
    .DIA24(wdata[24]),
    .DIA25(wdata[25]),
    .DIA26(wdata[26]),
    .DIA27(wdata[27]),
    .DIA28(wdata[28]),
    .DIA29(wdata[29]),
    .DIA30(wdata[30]),
    .DIA31(wdata[31]),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15]),
    .DOB16(rdata_q[16]),
    .DOB17(rdata_q[17]),
    .DOB18(rdata_q[18]),
    .DOB19(rdata_q[19]),
    .DOB20(rdata_q[20]),
    .DOB21(rdata_q[21]),
    .DOB22(rdata_q[22]),
    .DOB23(rdata_q[23]),
    .DOB24(rdata_q[24]),
    .DOB25(rdata_q[25]),
    .DOB26(rdata_q[26]),
    .DOB27(rdata_q[27]),
    .DOB28(rdata_q[28]),
    .DOB29(rdata_q[29]),
    .DOB30(rdata_q[30]),
    .DOB31(rdata_q[31])
);

wire [6:0] wgray_comb, rgray_comb;
wire [6:0] wptr_b_comb, rptr_b_comb;
wire wfull_comb;
    //define the write and read pointer and 
    //pay attention to the size of pointer which should be greater one to normal

    //write data to fifo buffer and wptr control
    always@(posedge wclk or negedge rst_n) begin
        if(!rst_n) begin
            wptr_b <= 0;
        end
        else  begin
            wptr_b <= wptr_b_comb;
        end

    end

    //read data from fifo buffer and rptr control
    always@(posedge rclk or negedge rst_n) begin
        if(!rst_n) begin
            rptr_b <= 0;
        end
        else  begin
            rptr_b <= rptr_b_comb;
        end
    end

    //wptr and rptr translate into gray code
    always @(posedge rclk or negedge rst_n) begin
        if(~rst_n) begin
            rptr <= 0;
        end 
        else begin
            rptr <= rgray_comb;
        end
    end

    always @(posedge wclk or negedge rst_n) begin
        if(~rst_n) begin
            wptr <= 0;
        end 
        else begin
            wptr <= wgray_comb;
        end
    end
    assign wptr_b_comb = (winc && ~wfull)? wptr_b+1 : wptr_b;
    assign rptr_b_comb = (rinc && ~rempty)? rptr_b+1 : rptr_b;

    assign wgray_comb = wptr_b_comb ^ (wptr_b_comb >> 1);
    assign rgray_comb = rptr_b_comb ^ (rptr_b_comb >> 1);

reg [$clog2(WORDS) : 0]  wr_ptr_grr, rd_ptr_grr; 

NDFF_BUS_syn #(7) s1(.D    (wptr), .Q    (wr_ptr_grr), .clk  (rclk), .rst_n(rst_n));
NDFF_BUS_syn #(7) s2(.D    (rptr), .Q    (rd_ptr_grr), .clk  (wclk), .rst_n(rst_n));

    // judge wfull or rempty

    always@(posedge rclk or negedge rst_n) begin
        if(!rst_n) rempty <= 1;
        else if(wr_ptr_grr == rgray_comb) begin
            rempty <= 1;
        end
        else rempty <= 0;
    end

    always@(posedge wclk or negedge rst_n) begin
        if(!rst_n) wfull <= 0;
        else begin
            wfull <= wfull_comb;
        end
    end

    assign wfull_comb = (wgray_comb == {~rd_ptr_grr[6:5], rd_ptr_grr[4:0]});


endmodule

