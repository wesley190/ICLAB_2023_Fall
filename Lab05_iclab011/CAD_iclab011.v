module CAD(
    //Input Port
    clk,
    rst_n,
    in_valid,
    in_valid2,
    matrix_size,
    matrix,
    matrix_idx,
    mode,

    //Output Port
    out_valid,
    out_value
    );

input rst_n, clk, in_valid, in_valid2, mode;
input [1:0] matrix_size;
input [7:0] matrix;
input [3:0] matrix_idx;

output reg  out_valid;
output reg signed out_value;
//---------------------------------------------------------------------
//   reg & wire
//---------------------------------------------------------------------
parameter IDLE = 3'd0;
parameter INPUT_1 = 3'd1;
parameter WAIT = 3'd2;
parameter INPUT_2 = 3'd3;
parameter EXE = 3'd4;
parameter OUT = 3'd5;

reg [2:0] curr_state;
reg [2:0] next_state;
//SRAM
reg signed[7:0] input_tmp;
reg signed[7:0] image_in_1, image_in_2, image_in_3, image_in_4, image_in_5, image_in_6, image_in_7, image_in_8, image_in_9,
          image_in_10, image_in_11, image_in_12, image_in_13, image_in_14, image_in_15, image_in_16;
reg signed[7:0] image_out_1, image_out_2, image_out_3, image_out_4, image_out_5, image_out_6, image_out_7, image_out_8, image_out_9,
          image_out_10, image_out_11, image_out_12, image_out_13, image_out_14, image_out_15, image_out_16 ;
reg signed[7:0] ker_in_1, ker_in_2, ker_in_3, ker_in_4, ker_in_5, ker_in_6, ker_in_7, ker_in_8, ker_in_9, ker_in_10, 
          ker_in_11, ker_in_12, ker_in_13, ker_in_14, ker_in_15, ker_in_16;
reg signed[7:0] ker_out_1, ker_out_2, ker_out_3, ker_out_4, ker_out_5, ker_out_6, ker_out_7, ker_out_8, ker_out_9, 
          ker_out_10, ker_out_11, ker_out_12, ker_out_13, ker_out_14, ker_out_15, ker_out_16;
reg [5:0] ker_add_1, ker_add_2, ker_add_3, ker_add_4, ker_add_5, ker_add_6, ker_add_7, ker_add_8, 
          ker_add_9, ker_add_10, ker_add_11, ker_add_12, ker_add_13, ker_add_14, ker_add_15, ker_add_16; 
reg [9:0] image_add_1, image_add_2, image_add_3, image_add_4, image_add_5, image_add_6, image_add_7, image_add_8, 
          image_add_9, image_add_10, image_add_11, image_add_12, image_add_13, image_add_14, image_add_15, image_add_16;
//addr comntrol
reg [5:0] ker_add_comb, ker_add_control;
reg [4:0] image_matrix_num, ker_matrix_num;
reg mode_tmp, mode_tmp_comb;
reg [9:0] image_add_control;
reg [9:0] image_limit;
//
reg [4:0] matrix_size_reg;
reg [2:0] in_valid2_count;
reg [3:0] image_idx, image_idx_comb, ker_idx, ker_idx_comb;
//conv
reg [9:0] conv_addr, left_side;
reg [2:0] count_5, change_line; 
reg [4:0] count_5_A;
reg [4:0] conv_count;
reg signed [7:0] mul_a, mul_b;
reg signed [20:0] sum, sum_tmp;
reg [20:0] mul_count;
reg [4:0] count_24;
reg [9:0] compare_count, count_limit;

reg exe_finish;
reg out_flag;
//---------------------------------------------------------------------
//   SRAM CONTROL
//---------------------------------------------------------------------
reg  MEM_switch;      
reg image_web_1, image_web_2, image_web_3, image_web_4, image_web_5, image_web_6, image_web_7, image_web_8, 
    image_web_9, image_web_10, image_web_11, image_web_12, image_web_13, image_web_14, image_web_15, image_web_16;
reg kernel_web_1, kernel_web_2, kernel_web_3, kernel_web_4, kernel_web_5, kernel_web_6, kernel_web_7, kernel_web_8, 
    kernel_web_9, kernel_web_10, kernel_web_11, kernel_web_12, kernel_web_13, kernel_web_14, kernel_web_15, kernel_web_16;

// store input matrix
RA1SH_1024_8 SRAM1(
.A0(image_add_1[0]), .A1(image_add_1[1]), .A2(image_add_1[2]), .A3(image_add_1[3]), .A4(image_add_1[4]), 
.A5(image_add_1[5]), .A6(image_add_1[6]), .A7(image_add_1[7]), .A8(image_add_1[8]), .A9(image_add_1[9]), 
.DI0(image_in_1[0]), .DI1(image_in_1[1]), .DI2(image_in_1[2]), .DI3(image_in_1[3]), .DI4(image_in_1[4]), 
.DI5(image_in_1[5]), .DI6(image_in_1[6]), .DI7(image_in_1[7]), 
.DO0(image_out_1[0]), .DO1(image_out_1[1]), .DO2(image_out_1[2]), .DO3(image_out_1[3]), .DO4(image_out_1[4]), 
.DO5(image_out_1[5]), .DO6(image_out_1[6]), .DO7(image_out_1[7]), 
.CS(1'b1), .WEB (image_web_1), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM2(
.A0(image_add_2[0]), .A1(image_add_2[1]), .A2(image_add_2[2]), .A3(image_add_2[3]), .A4(image_add_2[4]), 
.A5(image_add_2[5]), .A6(image_add_2[6]), .A7(image_add_2[7]), .A8(image_add_2[8]), .A9(image_add_2[9]), 
.DI0(image_in_2[0]), .DI1(image_in_2[1]), .DI2(image_in_2[2]), .DI3(image_in_2[3]), .DI4(image_in_2[4]), 
.DI5(image_in_2[5]), .DI6(image_in_2[6]), .DI7(image_in_2[7]), 
.DO0(image_out_2[0]), .DO1(image_out_2[1]), .DO2(image_out_2[2]), .DO3(image_out_2[3]), .DO4(image_out_2[4]), 
.DO5(image_out_2[5]), .DO6(image_out_2[6]), .DO7(image_out_2[7]), 
.CS(1'b1), .WEB (image_web_2), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM3(
.A0(image_add_3[0]), .A1(image_add_3[1]), .A2(image_add_3[2]), .A3(image_add_3[3]), .A4(image_add_3[4]), 
.A5(image_add_3[5]), .A6(image_add_3[6]), .A7(image_add_3[7]), .A8(image_add_3[8]), .A9(image_add_3[9]), 
.DI0(image_in_3[0]), .DI1(image_in_3[1]), .DI2(image_in_3[2]), .DI3(image_in_3[3]), .DI4(image_in_3[4]), 
.DI5(image_in_3[5]), .DI6(image_in_3[6]), .DI7(image_in_3[7]), 
.DO0(image_out_3[0]), .DO1(image_out_3[1]), .DO2(image_out_3[2]), .DO3(image_out_3[3]), .DO4(image_out_3[4]), 
.DO5(image_out_3[5]), .DO6(image_out_3[6]), .DO7(image_out_3[7]), 
.CS(1'b1), .WEB (image_web_3), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM4(
.A0(image_add_4[0]), .A1(image_add_4[1]), .A2(image_add_4[2]), .A3(image_add_4[3]), .A4(image_add_4[4]), 
.A5(image_add_4[5]), .A6(image_add_4[6]), .A7(image_add_4[7]), .A8(image_add_4[8]), .A9(image_add_4[9]), 
.DI0(image_in_4[0]), .DI1(image_in_4[1]), .DI2(image_in_4[2]), .DI3(image_in_4[3]), .DI4(image_in_4[4]), 
.DI5(image_in_4[5]), .DI6(image_in_4[6]), .DI7(image_in_4[7]), 
.DO0(image_out_4[0]), .DO1(image_out_4[1]), .DO2(image_out_4[2]), .DO3(image_out_4[3]), .DO4(image_out_4[4]), 
.DO5(image_out_4[5]), .DO6(image_out_4[6]), .DO7(image_out_4[7]), 
.CS(1'b1), .WEB (image_web_4), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM5(
.A0(image_add_5[0]), .A1(image_add_5[1]), .A2(image_add_5[2]), .A3(image_add_5[3]), .A4(image_add_5[4]), 
.A5(image_add_5[5]), .A6(image_add_5[6]), .A7(image_add_5[7]), .A8(image_add_5[8]), .A9(image_add_5[9]), 
.DI0(image_in_5[0]), .DI1(image_in_5[1]), .DI2(image_in_5[2]), .DI3(image_in_5[3]), .DI4(image_in_5[4]), 
.DI5(image_in_5[5]), .DI6(image_in_5[6]), .DI7(image_in_5[7]), 
.DO0(image_out_5[0]), .DO1(image_out_5[1]), .DO2(image_out_5[2]), .DO3(image_out_5[3]), .DO4(image_out_5[4]), 
.DO5(image_out_5[5]), .DO6(image_out_5[6]), .DO7(image_out_5[7]), 
.CS(1'b1), .WEB (image_web_5), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM6(
.A0(image_add_6[0]), .A1(image_add_6[1]), .A2(image_add_6[2]), .A3(image_add_6[3]), .A4(image_add_6[4]), 
.A5(image_add_6[5]), .A6(image_add_6[6]), .A7(image_add_6[7]), .A8(image_add_6[8]), .A9(image_add_6[9]), 
.DI0(image_in_6[0]), .DI1(image_in_6[1]), .DI2(image_in_6[2]), .DI3(image_in_6[3]), .DI4(image_in_6[4]), 
.DI5(image_in_6[5]), .DI6(image_in_6[6]), .DI7(image_in_6[7]), 
.DO0(image_out_6[0]), .DO1(image_out_6[1]), .DO2(image_out_6[2]), .DO3(image_out_6[3]), .DO4(image_out_6[4]), 
.DO5(image_out_6[5]), .DO6(image_out_6[6]), .DO7(image_out_6[7]), 
.CS(1'b1), .WEB (image_web_6), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM7(
.A0(image_add_7[0]), .A1(image_add_7[1]), .A2(image_add_7[2]), .A3(image_add_7[3]), .A4(image_add_7[4]), 
.A5(image_add_7[5]), .A6(image_add_7[6]), .A7(image_add_7[7]), .A8(image_add_7[8]), .A9(image_add_7[9]), 
.DI0(image_in_7[0]), .DI1(image_in_7[1]), .DI2(image_in_7[2]), .DI3(image_in_7[3]), .DI4(image_in_7[4]), 
.DI5(image_in_7[5]), .DI6(image_in_7[6]), .DI7(image_in_7[7]), 
.DO0(image_out_7[0]), .DO1(image_out_7[1]), .DO2(image_out_7[2]), .DO3(image_out_7[3]), .DO4(image_out_7[4]), 
.DO5(image_out_7[5]), .DO6(image_out_7[6]), .DO7(image_out_7[7]), 
.CS(1'b1), .WEB (image_web_7), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM8(
.A0(image_add_8[0]), .A1(image_add_8[1]), .A2(image_add_8[2]), .A3(image_add_8[3]), .A4(image_add_8[4]), 
.A5(image_add_8[5]), .A6(image_add_8[6]), .A7(image_add_8[7]), .A8(image_add_8[8]), .A9(image_add_8[9]), 
.DI0(image_in_8[0]), .DI1(image_in_8[1]), .DI2(image_in_8[2]), .DI3(image_in_8[3]), .DI4(image_in_8[4]), 
.DI5(image_in_8[5]), .DI6(image_in_8[6]), .DI7(image_in_8[7]), 
.DO0(image_out_8[0]), .DO1(image_out_8[1]), .DO2(image_out_8[2]), .DO3(image_out_8[3]), .DO4(image_out_8[4]), 
.DO5(image_out_8[5]), .DO6(image_out_8[6]), .DO7(image_out_8[7]), 
.CS(1'b1), .WEB (image_web_8), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM9(
.A0(image_add_9[0]), .A1(image_add_9[1]), .A2(image_add_9[2]), .A3(image_add_9[3]), .A4(image_add_9[4]), 
.A5(image_add_9[5]), .A6(image_add_9[6]), .A7(image_add_9[7]), .A8(image_add_9[8]), .A9(image_add_9[9]), 
.DI0(image_in_9[0]), .DI1(image_in_9[1]), .DI2(image_in_9[2]), .DI3(image_in_9[3]), .DI4(image_in_9[4]), 
.DI5(image_in_9[5]), .DI6(image_in_9[6]), .DI7(image_in_9[7]), 
.DO0(image_out_9[0]), .DO1(image_out_9[1]), .DO2(image_out_9[2]), .DO3(image_out_9[3]), .DO4(image_out_9[4]), 
.DO5(image_out_9[5]), .DO6(image_out_9[6]), .DO7(image_out_9[7]), 
.CS(1'b1), .WEB (image_web_9), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM10(
.A0(image_add_10[0]), .A1(image_add_10[1]), .A2(image_add_10[2]), .A3(image_add_10[3]), .A4(image_add_10[4]), 
.A5(image_add_10[5]), .A6(image_add_10[6]), .A7(image_add_10[7]), .A8(image_add_10[8]), .A9(image_add_10[9]), 
.DI0(image_in_10[0]), .DI1(image_in_10[1]), .DI2(image_in_10[2]), .DI3(image_in_10[3]), .DI4(image_in_10[4]), 
.DI5(image_in_10[5]), .DI6(image_in_10[6]), .DI7(image_in_10[7]), 
.DO0(image_out_10[0]), .DO1(image_out_10[1]), .DO2(image_out_10[2]), .DO3(image_out_10[3]), .DO4(image_out_10[4]), 
.DO5(image_out_10[5]), .DO6(image_out_10[6]), .DO7(image_out_10[7]), 
.CS(1'b1), .WEB (image_web_10), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM11(
.A0(image_add_11[0]), .A1(image_add_11[1]), .A2(image_add_11[2]), .A3(image_add_11[3]), .A4(image_add_11[4]), 
.A5(image_add_11[5]), .A6(image_add_11[6]), .A7(image_add_11[7]), .A8(image_add_11[8]), .A9(image_add_11[9]), 
.DI0(image_in_11[0]), .DI1(image_in_11[1]), .DI2(image_in_11[2]), .DI3(image_in_11[3]), .DI4(image_in_11[4]), 
.DI5(image_in_11[5]), .DI6(image_in_11[6]), .DI7(image_in_11[7]), 
.DO0(image_out_11[0]), .DO1(image_out_11[1]), .DO2(image_out_11[2]), .DO3(image_out_11[3]), .DO4(image_out_11[4]), 
.DO5(image_out_11[5]), .DO6(image_out_11[6]), .DO7(image_out_11[7]), 
.CS(1'b1), .WEB (image_web_11), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM12(
.A0(image_add_12[0]), .A1(image_add_12[1]), .A2(image_add_12[2]), .A3(image_add_12[3]), .A4(image_add_12[4]), 
.A5(image_add_12[5]), .A6(image_add_12[6]), .A7(image_add_12[7]), .A8(image_add_12[8]), .A9(image_add_12[9]), 
.DI0(image_in_12[0]), .DI1(image_in_12[1]), .DI2(image_in_12[2]), .DI3(image_in_12[3]), .DI4(image_in_12[4]), 
.DI5(image_in_12[5]), .DI6(image_in_12[6]), .DI7(image_in_12[7]), 
.DO0(image_out_12[0]), .DO1(image_out_12[1]), .DO2(image_out_12[2]), .DO3(image_out_12[3]), .DO4(image_out_12[4]), 
.DO5(image_out_12[5]), .DO6(image_out_12[6]), .DO7(image_out_12[7]), 
.CS(1'b1), .WEB (image_web_12), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM13(
.A0(image_add_13[0]), .A1(image_add_13[1]), .A2(image_add_13[2]), .A3(image_add_13[3]), .A4(image_add_13[4]), 
.A5(image_add_13[5]), .A6(image_add_13[6]), .A7(image_add_13[7]), .A8(image_add_13[8]), .A9(image_add_13[9]), 
.DI0(image_in_13[0]), .DI1(image_in_13[1]), .DI2(image_in_13[2]), .DI3(image_in_13[3]), .DI4(image_in_13[4]), 
.DI5(image_in_13[5]), .DI6(image_in_13[6]), .DI7(image_in_13[7]), 
.DO0(image_out_13[0]), .DO1(image_out_13[1]), .DO2(image_out_13[2]), .DO3(image_out_13[3]), .DO4(image_out_13[4]), 
.DO5(image_out_13[5]), .DO6(image_out_13[6]), .DO7(image_out_13[7]), 
.CS(1'b1), .WEB (image_web_13), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM14(
.A0(image_add_14[0]), .A1(image_add_14[1]), .A2(image_add_14[2]), .A3(image_add_14[3]), .A4(image_add_14[4]), 
.A5(image_add_14[5]), .A6(image_add_14[6]), .A7(image_add_14[7]), .A8(image_add_14[8]), .A9(image_add_14[9]), 
.DI0(image_in_14[0]), .DI1(image_in_14[1]), .DI2(image_in_14[2]), .DI3(image_in_14[3]), .DI4(image_in_14[4]), 
.DI5(image_in_14[5]), .DI6(image_in_14[6]), .DI7(image_in_14[7]), 
.DO0(image_out_14[0]), .DO1(image_out_14[1]), .DO2(image_out_14[2]), .DO3(image_out_14[3]), .DO4(image_out_14[4]), 
.DO5(image_out_14[5]), .DO6(image_out_14[6]), .DO7(image_out_14[7]), 
.CS(1'b1), .WEB (image_web_14), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM15(
.A0(image_add_15[0]), .A1(image_add_15[1]), .A2(image_add_15[2]), .A3(image_add_15[3]), .A4(image_add_15[4]), 
.A5(image_add_15[5]), .A6(image_add_15[6]), .A7(image_add_15[7]), .A8(image_add_15[8]), .A9(image_add_15[9]), 
.DI0(image_in_15[0]), .DI1(image_in_15[1]), .DI2(image_in_15[2]), .DI3(image_in_15[3]), .DI4(image_in_15[4]), 
.DI5(image_in_15[5]), .DI6(image_in_15[6]), .DI7(image_in_15[7]), 
.DO0(image_out_15[0]), .DO1(image_out_15[1]), .DO2(image_out_15[2]), .DO3(image_out_15[3]), .DO4(image_out_15[4]), 
.DO5(image_out_15[5]), .DO6(image_out_15[6]), .DO7(image_out_15[7]), 
.CS(1'b1), .WEB (image_web_15), .OE  (1'b1), .CK(clk)  );
RA1SH_1024_8 SRAM16(
.A0(image_add_16[0]), .A1(image_add_16[1]), .A2(image_add_16[2]), .A3(image_add_16[3]), .A4(image_add_16[4]), 
.A5(image_add_16[5]), .A6(image_add_16[6]), .A7(image_add_16[7]), .A8(image_add_16[8]), .A9(image_add_16[9]), 
.DI0(image_in_16[0]), .DI1(image_in_16[1]), .DI2(image_in_16[2]), .DI3(image_in_16[3]), .DI4(image_in_16[4]), 
.DI5(image_in_16[5]), .DI6(image_in_16[6]), .DI7(image_in_16[7]), 
.DO0(image_out_16[0]), .DO1(image_out_16[1]), .DO2(image_out_16[2]), .DO3(image_out_16[3]), .DO4(image_out_16[4]), 
.DO5(image_out_16[5]), .DO6(image_out_16[6]), .DO7(image_out_16[7]), 
.CS(1'b1), .WEB (image_web_16), .OE  (1'b1), .CK(clk)  );
RA1SH_64_8 KER1(.A0(ker_add_1[0]), .A1(ker_add_1[1]), .A2(ker_add_1[2]), .A3(ker_add_1[3]), .A4(ker_add_1[4]), .A5(ker_add_1[5]), 
.DI0(ker_in_1[0]), .DI1(ker_in_1[1]), .DI2(ker_in_1[2]), .DI3(ker_in_1[3]), .DI4(ker_in_1[4]), .DI5(ker_in_1[5]), .DI6(ker_in_1[6]), .DI7(ker_in_1[7]), 
.DO0(ker_out_1[0]), .DO1(ker_out_1[1]), .DO2(ker_out_1[2]), .DO3(ker_out_1[3]), .DO4(ker_out_1[4]), .DO5(ker_out_1[5]), .DO6(ker_out_1[6]), .DO7(ker_out_1[7]), 
.CS(1'b1), .WEB (kernel_web_1), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER2(.A0(ker_add_2[0]), .A1(ker_add_2[1]), .A2(ker_add_2[2]), .A3(ker_add_2[3]), .A4(ker_add_2[4]), .A5(ker_add_2[5]), 
.DI0(ker_in_2[0]), .DI1(ker_in_2[1]), .DI2(ker_in_2[2]), .DI3(ker_in_2[3]), .DI4(ker_in_2[4]), .DI5(ker_in_2[5]), .DI6(ker_in_2[6]), .DI7(ker_in_2[7]), 
.DO0(ker_out_2[0]), .DO1(ker_out_2[1]), .DO2(ker_out_2[2]), .DO3(ker_out_2[3]), .DO4(ker_out_2[4]), .DO5(ker_out_2[5]), .DO6(ker_out_2[6]), .DO7(ker_out_2[7]), 
.CS(1'b1), .WEB (kernel_web_2), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER3(.A0(ker_add_3[0]), .A1(ker_add_3[1]), .A2(ker_add_3[2]), .A3(ker_add_3[3]), .A4(ker_add_3[4]), .A5(ker_add_3[5]), 
.DI0(ker_in_3[0]), .DI1(ker_in_3[1]), .DI2(ker_in_3[2]), .DI3(ker_in_3[3]), .DI4(ker_in_3[4]), .DI5(ker_in_3[5]), .DI6(ker_in_3[6]), .DI7(ker_in_3[7]), 
.DO0(ker_out_3[0]), .DO1(ker_out_3[1]), .DO2(ker_out_3[2]), .DO3(ker_out_3[3]), .DO4(ker_out_3[4]), .DO5(ker_out_3[5]), .DO6(ker_out_3[6]), .DO7(ker_out_3[7]), 
.CS(1'b1), .WEB (kernel_web_3), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER4(.A0(ker_add_4[0]), .A1(ker_add_4[1]), .A2(ker_add_4[2]), .A3(ker_add_4[3]), .A4(ker_add_4[4]), .A5(ker_add_4[5]), 
.DI0(ker_in_4[0]), .DI1(ker_in_4[1]), .DI2(ker_in_4[2]), .DI3(ker_in_4[3]), .DI4(ker_in_4[4]), .DI5(ker_in_4[5]), .DI6(ker_in_4[6]), .DI7(ker_in_4[7]), 
.DO0(ker_out_4[0]), .DO1(ker_out_4[1]), .DO2(ker_out_4[2]), .DO3(ker_out_4[3]), .DO4(ker_out_4[4]), .DO5(ker_out_4[5]), .DO6(ker_out_4[6]), .DO7(ker_out_4[7]), 
.CS(1'b1), .WEB (kernel_web_4), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER5(.A0(ker_add_5[0]), .A1(ker_add_5[1]), .A2(ker_add_5[2]), .A3(ker_add_5[3]), .A4(ker_add_5[4]), .A5(ker_add_5[5]), 
.DI0(ker_in_5[0]), .DI1(ker_in_5[1]), .DI2(ker_in_5[2]), .DI3(ker_in_5[3]), .DI4(ker_in_5[4]), .DI5(ker_in_5[5]), .DI6(ker_in_5[6]), .DI7(ker_in_5[7]), 
.DO0(ker_out_5[0]), .DO1(ker_out_5[1]), .DO2(ker_out_5[2]), .DO3(ker_out_5[3]), .DO4(ker_out_5[4]), .DO5(ker_out_5[5]), .DO6(ker_out_5[6]), .DO7(ker_out_5[7]), 
.CS(1'b1), .WEB (kernel_web_5), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER6(.A0(ker_add_6[0]), .A1(ker_add_6[1]), .A2(ker_add_6[2]), .A3(ker_add_6[3]), .A4(ker_add_6[4]), .A5(ker_add_6[5]), 
.DI0(ker_in_6[0]), .DI1(ker_in_6[1]), .DI2(ker_in_6[2]), .DI3(ker_in_6[3]), .DI4(ker_in_6[4]), .DI5(ker_in_6[5]), .DI6(ker_in_6[6]), .DI7(ker_in_6[7]), 
.DO0(ker_out_6[0]), .DO1(ker_out_6[1]), .DO2(ker_out_6[2]), .DO3(ker_out_6[3]), .DO4(ker_out_6[4]), .DO5(ker_out_6[5]), .DO6(ker_out_6[6]), .DO7(ker_out_6[7]), 
.CS(1'b1), .WEB (kernel_web_6), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER7(.A0(ker_add_7[0]), .A1(ker_add_7[1]), .A2(ker_add_7[2]), .A3(ker_add_7[3]), .A4(ker_add_7[4]), .A5(ker_add_7[5]), 
.DI0(ker_in_7[0]), .DI1(ker_in_7[1]), .DI2(ker_in_7[2]), .DI3(ker_in_7[3]), .DI4(ker_in_7[4]), .DI5(ker_in_7[5]), .DI6(ker_in_7[6]), .DI7(ker_in_7[7]), 
.DO0(ker_out_7[0]), .DO1(ker_out_7[1]), .DO2(ker_out_7[2]), .DO3(ker_out_7[3]), .DO4(ker_out_7[4]), .DO5(ker_out_7[5]), .DO6(ker_out_7[6]), .DO7(ker_out_7[7]), 
.CS(1'b1), .WEB (kernel_web_7), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER8(.A0(ker_add_8[0]), .A1(ker_add_8[1]), .A2(ker_add_8[2]), .A3(ker_add_8[3]), .A4(ker_add_8[4]), .A5(ker_add_8[5]), 
.DI0(ker_in_8[0]), .DI1(ker_in_8[1]), .DI2(ker_in_8[2]), .DI3(ker_in_8[3]), .DI4(ker_in_8[4]), .DI5(ker_in_8[5]), .DI6(ker_in_8[6]), .DI7(ker_in_8[7]), 
.DO0(ker_out_8[0]), .DO1(ker_out_8[1]), .DO2(ker_out_8[2]), .DO3(ker_out_8[3]), .DO4(ker_out_8[4]), .DO5(ker_out_8[5]), .DO6(ker_out_8[6]), .DO7(ker_out_8[7]), 
.CS(1'b1), .WEB (kernel_web_8), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER9(.A0(ker_add_9[0]), .A1(ker_add_9[1]), .A2(ker_add_9[2]), .A3(ker_add_9[3]), .A4(ker_add_9[4]), .A5(ker_add_9[5]), 
.DI0(ker_in_9[0]), .DI1(ker_in_9[1]), .DI2(ker_in_9[2]), .DI3(ker_in_9[3]), .DI4(ker_in_9[4]), .DI5(ker_in_9[5]), .DI6(ker_in_9[6]), .DI7(ker_in_9[7]), 
.DO0(ker_out_9[0]), .DO1(ker_out_9[1]), .DO2(ker_out_9[2]), .DO3(ker_out_9[3]), .DO4(ker_out_9[4]), .DO5(ker_out_9[5]), .DO6(ker_out_9[6]), .DO7(ker_out_9[7]), 
.CS(1'b1), .WEB (kernel_web_9), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER10(.A0(ker_add_10[0]), .A1(ker_add_10[1]), .A2(ker_add_10[2]), .A3(ker_add_10[3]), .A4(ker_add_10[4]), .A5(ker_add_10[5]), 
.DI0(ker_in_10[0]), .DI1(ker_in_10[1]), .DI2(ker_in_10[2]), .DI3(ker_in_10[3]), .DI4(ker_in_10[4]), .DI5(ker_in_10[5]), .DI6(ker_in_10[6]), .DI7(ker_in_10[7]), 
.DO0(ker_out_10[0]), .DO1(ker_out_10[1]), .DO2(ker_out_10[2]), .DO3(ker_out_10[3]), .DO4(ker_out_10[4]), .DO5(ker_out_10[5]), .DO6(ker_out_10[6]), .DO7(ker_out_10[7]), 
.CS(1'b1), .WEB (kernel_web_10), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER11(.A0(ker_add_11[0]), .A1(ker_add_11[1]), .A2(ker_add_11[2]), .A3(ker_add_11[3]), .A4(ker_add_11[4]), .A5(ker_add_11[5]), 
.DI0(ker_in_11[0]), .DI1(ker_in_11[1]), .DI2(ker_in_11[2]), .DI3(ker_in_11[3]), .DI4(ker_in_11[4]), .DI5(ker_in_11[5]), .DI6(ker_in_11[6]), .DI7(ker_in_11[7]), 
.DO0(ker_out_11[0]), .DO1(ker_out_11[1]), .DO2(ker_out_11[2]), .DO3(ker_out_11[3]), .DO4(ker_out_11[4]), .DO5(ker_out_11[5]), .DO6(ker_out_11[6]), .DO7(ker_out_11[7]), 
.CS(1'b1), .WEB (kernel_web_11), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER12(.A0(ker_add_12[0]), .A1(ker_add_12[1]), .A2(ker_add_12[2]), .A3(ker_add_12[3]), .A4(ker_add_12[4]), .A5(ker_add_12[5]), 
.DI0(ker_in_12[0]), .DI1(ker_in_12[1]), .DI2(ker_in_12[2]), .DI3(ker_in_12[3]), .DI4(ker_in_12[4]), .DI5(ker_in_12[5]), .DI6(ker_in_12[6]), .DI7(ker_in_12[7]), 
.DO0(ker_out_12[0]), .DO1(ker_out_12[1]), .DO2(ker_out_12[2]), .DO3(ker_out_12[3]), .DO4(ker_out_12[4]), .DO5(ker_out_12[5]), .DO6(ker_out_12[6]), .DO7(ker_out_12[7]), 
.CS(1'b1), .WEB (kernel_web_12), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER13(.A0(ker_add_13[0]), .A1(ker_add_13[1]), .A2(ker_add_13[2]), .A3(ker_add_13[3]), .A4(ker_add_13[4]), .A5(ker_add_13[5]), 
.DI0(ker_in_13[0]), .DI1(ker_in_13[1]), .DI2(ker_in_13[2]), .DI3(ker_in_13[3]), .DI4(ker_in_13[4]), .DI5(ker_in_13[5]), .DI6(ker_in_13[6]), .DI7(ker_in_13[7]), 
.DO0(ker_out_13[0]), .DO1(ker_out_13[1]), .DO2(ker_out_13[2]), .DO3(ker_out_13[3]), .DO4(ker_out_13[4]), .DO5(ker_out_13[5]), .DO6(ker_out_13[6]), .DO7(ker_out_13[7]), 
.CS(1'b1), .WEB (kernel_web_13), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER14(.A0(ker_add_14[0]), .A1(ker_add_14[1]), .A2(ker_add_14[2]), .A3(ker_add_14[3]), .A4(ker_add_14[4]), .A5(ker_add_14[5]), 
.DI0(ker_in_14[0]), .DI1(ker_in_14[1]), .DI2(ker_in_14[2]), .DI3(ker_in_14[3]), .DI4(ker_in_14[4]), .DI5(ker_in_14[5]), .DI6(ker_in_14[6]), .DI7(ker_in_14[7]), 
.DO0(ker_out_14[0]), .DO1(ker_out_14[1]), .DO2(ker_out_14[2]), .DO3(ker_out_14[3]), .DO4(ker_out_14[4]), .DO5(ker_out_14[5]), .DO6(ker_out_14[6]), .DO7(ker_out_14[7]), 
.CS(1'b1), .WEB (kernel_web_14), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER15(.A0(ker_add_15[0]), .A1(ker_add_15[1]), .A2(ker_add_15[2]), .A3(ker_add_15[3]), .A4(ker_add_15[4]), .A5(ker_add_15[5]), 
.DI0(ker_in_15[0]), .DI1(ker_in_15[1]), .DI2(ker_in_15[2]), .DI3(ker_in_15[3]), .DI4(ker_in_15[4]), .DI5(ker_in_15[5]), .DI6(ker_in_15[6]), .DI7(ker_in_15[7]), 
.DO0(ker_out_15[0]), .DO1(ker_out_15[1]), .DO2(ker_out_15[2]), .DO3(ker_out_15[3]), .DO4(ker_out_15[4]), .DO5(ker_out_15[5]), .DO6(ker_out_15[6]), .DO7(ker_out_15[7]), 
.CS(1'b1), .WEB (kernel_web_15), .OE  (1'b1), .CK(clk) );
RA1SH_64_8 KER16(.A0(ker_add_16[0]), .A1(ker_add_16[1]), .A2(ker_add_16[2]), .A3(ker_add_16[3]), .A4(ker_add_16[4]), .A5(ker_add_16[5]), 
.DI0(ker_in_16[0]), .DI1(ker_in_16[1]), .DI2(ker_in_16[2]), .DI3(ker_in_16[3]), .DI4(ker_in_16[4]), .DI5(ker_in_16[5]), .DI6(ker_in_16[6]), .DI7(ker_in_16[7]), 
.DO0(ker_out_16[0]), .DO1(ker_out_16[1]), .DO2(ker_out_16[2]), .DO3(ker_out_16[3]), .DO4(ker_out_16[4]), .DO5(ker_out_16[5]), .DO6(ker_out_16[6]), .DO7(ker_out_16[7]), 
.CS(1'b1), .WEB (kernel_web_16), .OE  (1'b1), .CK(clk) );

//store conv result

//---------------------------------------------------------------------
//   input
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        input_tmp <= 0;
    end else if(next_state == INPUT_1) begin
        input_tmp <= matrix;
    end
end

// SRAM of image
always @(posedge clk ) begin
    case (image_matrix_num)
        1 : image_in_1 <= input_tmp;
        2 : image_in_2 <= input_tmp;
        3 : image_in_3 <= input_tmp;
        4 : image_in_4 <= input_tmp;
        5 : image_in_5 <= input_tmp;
        6 : image_in_6 <= input_tmp;
        7 : image_in_7 <= input_tmp;
        8 : image_in_8 <= input_tmp;
        9 : image_in_9 <= input_tmp;
        10 : image_in_10 <= input_tmp;
        11 : image_in_11 <= input_tmp;
        12 : image_in_12 <= input_tmp;
        13 : image_in_13 <= input_tmp;
        14 : image_in_14 <= input_tmp;
        15 : image_in_15 <= input_tmp;
        16 : image_in_16 <= input_tmp;
    endcase
end

always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 1)begin
        image_web_1 <= 0;
    end
    else begin
        image_web_1 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 2)begin
        image_web_2 <= 0;
    end
    else begin
        image_web_2 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 3)begin
        image_web_3 <= 0;
    end
    else begin
        image_web_3 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 4)begin
        image_web_4 <= 0;
    end
    else begin
        image_web_4 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 5)begin
        image_web_5 <= 0;
    end
    else begin
        image_web_5 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 6)begin
        image_web_6 <= 0;
    end
    else begin
        image_web_6 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 7)begin
        image_web_7 <= 0;
    end
    else begin
        image_web_7 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 8)begin
        image_web_8 <= 0;
    end
    else begin
        image_web_8 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 9)begin
        image_web_9 <= 0;
    end
    else begin
        image_web_9 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 10)begin
        image_web_10 <= 0;
    end
    else begin
        image_web_10 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 11)begin
        image_web_11 <= 0;
    end
    else begin
        image_web_11 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 12)begin
        image_web_12 <= 0;
    end
    else begin
        image_web_12 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 13)begin
        image_web_13 <= 0;
    end
    else begin
        image_web_13 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 14)begin
        image_web_14 <= 0;
    end
    else begin
        image_web_14 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 15)begin
        image_web_15 <= 0;
    end
    else begin
        image_web_15 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && image_matrix_num == 16)begin
        image_web_16 <= 0;
    end
    else begin
        image_web_16 <= 1;
    end
end

always @(posedge clk) begin
    image_add_1 <= image_add_control;
    image_add_2 <= image_add_control;
    image_add_3 <= image_add_control;
    image_add_4 <= image_add_control;
    image_add_5 <= image_add_control;
    image_add_6 <= image_add_control;
    image_add_7 <= image_add_control;
    image_add_8 <= image_add_control;
    image_add_9 <= image_add_control;
    image_add_10 <= image_add_control;
    image_add_11 <= image_add_control;
    image_add_12 <= image_add_control;
    image_add_13 <= image_add_control;
    image_add_14 <= image_add_control;
    image_add_15 <= image_add_control;
    image_add_16 <= image_add_control;
end
//SRAM of kernel
always @(posedge clk ) begin
    if(curr_state == INPUT_1 && image_matrix_num >=17) begin
        case (ker_matrix_num)
            1 : ker_in_1 <= input_tmp;
            2 : ker_in_2 <= input_tmp;
            3 : ker_in_3 <= input_tmp;
            4 : ker_in_4 <= input_tmp;
            5 : ker_in_5 <= input_tmp;
            6 : ker_in_6 <= input_tmp;
            7 : ker_in_7 <= input_tmp;
            8 : ker_in_8 <= input_tmp;
            9 : ker_in_9 <= input_tmp;
            10 : ker_in_10 <= input_tmp;
            11 : ker_in_11 <= input_tmp;
            12 : ker_in_12 <= input_tmp;
            13 : ker_in_13 <= input_tmp;
            14 : ker_in_14 <= input_tmp;
            15 : ker_in_15 <= input_tmp;
            16 : ker_in_16 <= input_tmp;      
        endcase
    end
    
end

always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 1 && image_matrix_num== 17)begin
        kernel_web_1 <= 0;
    end
    else begin
        kernel_web_1 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 2)begin
        kernel_web_2 <= 0;
    end
    else begin
        kernel_web_2 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 3)begin
        kernel_web_3 <= 0;
    end
    else begin
        kernel_web_3 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 4)begin
        kernel_web_4 <= 0;
    end
    else begin
        kernel_web_4 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 5)begin
        kernel_web_5 <= 0;
    end
    else begin
        kernel_web_5 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 6)begin
        kernel_web_6 <= 0;
    end
    else begin
        kernel_web_6 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 7)begin
        kernel_web_7 <= 0;
    end
    else begin
        kernel_web_7 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 8)begin
        kernel_web_8 <= 0;
    end
    else begin
        kernel_web_8 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 9)begin
        kernel_web_9 <= 0;
    end
    else begin
        kernel_web_9 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 10)begin
        kernel_web_10 <= 0;
    end
    else begin
        kernel_web_10 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 11)begin
        kernel_web_11 <= 0;
    end
    else begin
        kernel_web_11 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 12)begin
        kernel_web_12 <= 0;
    end
    else begin
        kernel_web_12 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 13)begin
        kernel_web_13 <= 0;
    end
    else begin
        kernel_web_13 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 14)begin
        kernel_web_14 <= 0;
    end
    else begin
        kernel_web_14 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 15)begin
        kernel_web_15 <= 0;
    end
    else begin
        kernel_web_15 <= 1;
    end
end
always @(posedge clk) begin
    if(curr_state == INPUT_1 && ker_matrix_num == 16)begin
        kernel_web_16 <= 0;
    end
    else begin
        kernel_web_16 <= 1;
    end
end

always @(posedge clk) begin
    ker_add_1 <= ker_add_control;
    ker_add_2 <= ker_add_control;
    ker_add_3 <= ker_add_control;
    ker_add_4 <= ker_add_control;
    ker_add_5 <= ker_add_control;
    ker_add_6 <= ker_add_control;
    ker_add_7 <= ker_add_control;
    ker_add_8 <= ker_add_control;
    ker_add_9 <= ker_add_control;
    ker_add_10 <= ker_add_control;
    ker_add_11 <= ker_add_control;
    ker_add_12 <= ker_add_control;
    ker_add_13 <= ker_add_control;
    ker_add_14 <= ker_add_control;
    ker_add_15 <= ker_add_control;
    ker_add_16 <= ker_add_control;
end
// save matrix size
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        matrix_size_reg <= 0;
    else if(next_state == INPUT_1 && curr_state == IDLE)begin
        if(matrix_size == 0) 
            matrix_size_reg <= 7;
        else if(matrix_size == 1)
            matrix_size_reg <= 15;
        else
            matrix_size_reg <= 31;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        in_valid2_count <= 0;
    end else if(in_valid2) begin
        in_valid2_count <= in_valid2_count + 1;
    end
    else in_valid2_count <= 0;
end

// save mode
always @(*) begin
    mode_tmp_comb = mode_tmp;
    if (in_valid2 == 1 && in_valid2_count == 0) begin //03gate
        mode_tmp_comb = mode;
    end    
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        mode_tmp <= 0;
    else mode_tmp <= mode_tmp_comb;
end

// save matrix_idx
always @(*) begin
    image_idx_comb = image_idx;
    if (in_valid2 == 1 && in_valid2_count == 0) begin 
        image_idx_comb = matrix_idx;
    end    
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        image_idx <= 0;
    else image_idx <= image_idx_comb;
end

always @(*) begin
    ker_idx_comb = ker_idx;
    if (in_valid2 == 1 && in_valid2_count == 1) begin
        ker_idx_comb = matrix_idx;
    end    
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ker_idx <= 0;
    else ker_idx <= ker_idx_comb;
end

//set input number
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        image_limit <= 0;
    end else if(next_state == INPUT_1) begin
        case (matrix_size)
            0 : image_limit <= 63;
            1 : image_limit <= 255;
            2 : image_limit <= 1023;
        endcase
    end
end

//cal input matrix
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        image_matrix_num <= 0;
    else if(next_state == INPUT_1)begin
        image_matrix_num <= (image_add_control == image_limit)? image_matrix_num + 1: image_matrix_num;
    end 
    else if(next_state == IDLE)begin
        image_matrix_num <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        ker_matrix_num <= 0;
    else if(next_state == INPUT_1)begin
        if(image_matrix_num <= 16) ker_matrix_num <= 1;
        else ker_matrix_num <= (ker_add_control == 24)? ker_matrix_num + 1: ker_matrix_num;
    end 
    else if(next_state == IDLE)begin
        ker_matrix_num <= 0;
    end
end

// control input matrix SRAM addr
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        image_add_control <= 0;
    else if(next_state == INPUT_1)begin
        if(image_add_control == image_limit || image_matrix_num == 17)begin
            image_add_control <= 0;
        end
        else begin
            image_add_control <= image_add_control + 1;
        end  
    end
    else if(next_state == INPUT_2)begin
        image_add_control <= 0;
    end
    else if(curr_state == EXE)begin
        if(mode_tmp == 0) begin
            image_add_control <= conv_addr;
        end
        else begin
            if(image_add_control == image_limit)begin
                image_add_control <= 0;
            end
            else begin
                image_add_control <= image_add_control + 1;
            end
        end
    end
    else if(next_state == IDLE)begin
        image_add_control <= 0;
    end
end
// control weight matrix SRAM addr
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        ker_add_control <= 0;
    else if(next_state == INPUT_1)begin
        if(ker_add_control == 24 || image_matrix_num <= 16)begin
            ker_add_control <= 0;
        end
        else begin
            ker_add_control <= ker_add_control + 1;
        end  
    end
    else if(next_state == INPUT_2)begin
        ker_add_control <= 0;
    end
    else if(curr_state == EXE)begin
        if(ker_add_control == 24)begin
            ker_add_control <= 0;
        end
        else begin
            ker_add_control <= ker_add_control + 1;
        end 
    end
    else if(next_state == IDLE)begin
        ker_add_control <= 0;
    end
end
//---------------------------------------------------------------------
//   CONV
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        count_5 <= 0;
    end else if(next_state == EXE) begin
        if(count_5 == 4)
            count_5 <= 0;
        else
            count_5 <= count_5 + 1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        change_line <= 0;
    end else if(next_state == EXE) begin
        if(change_line == 4 && count_5 == 4) begin
            change_line <= 0;
        end
        else if(count_5 == 4)begin
            change_line <= change_line +1 ;
        end        
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        count_5_A <= 0;
    end else if(next_state == EXE) begin
        if(change_line == 4 && count_5 == 4)begin
            count_5_A <= count_5_A+1;
        end
        else if(count_5_A == 4) begin
            count_5_A <= 0;
        end
    end
end
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        conv_count <= 0;
    end else if(next_state == EXE) begin
        if(change_line == 4 && count_5 == 4)begin
            conv_count <= conv_count +1;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        left_side <= 0;
    end else if(next_state == EXE) begin
        if(change_line == 0 && count_5==0)begin
            left_side <= conv_addr;
        end
    end
end

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        conv_addr <= 0;
    end else if(next_state ==EXE) begin
        if(matrix_size_reg == 7) begin
            if(conv_count == 16) begin
                conv_addr <= 0;
            end
            else if(count_5_A == 3 && change_line == 4 && count_5 == 4)begin
                conv_addr <= left_side+5;
            end
            else if(change_line == 4 && count_5 == 4)begin
                conv_addr <= left_side+1;
            end
            else if(count_5 == 4)begin
                conv_addr <= conv_addr+4;
            end
            else begin
                conv_addr <= conv_addr+1;
            end
        end
        else if(matrix_size_reg == 15) begin
            if(conv_count == 144) begin
                conv_addr <= 0;
            end
            else if(count_5_A == 11 && change_line == 4 && count_5 == 4)begin
                conv_addr <= left_side+5;
            end
            else if(change_line == 4 && count_5 == 4)begin
                conv_addr <= left_side+1;
            end
            else if(count_5 == 4)begin
                conv_addr <= conv_addr+12;
            end
            else begin
                conv_addr <= conv_addr+1;
            end
        end
        else if(matrix_size_reg == 31) begin
            if(conv_count == 784) begin
                conv_addr <= 0;
            end
            else if(count_5_A == 27 && change_line == 4 && count_5 == 4)begin
                conv_addr <= left_side+5;
            end
            else if(change_line == 4 && count_5 == 4)begin
                conv_addr <= left_side+1;
            end
            else if(count_5 == 4)begin
                conv_addr <= conv_addr+28;
            end
            else begin
                conv_addr <= conv_addr+1;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        count_24 <= 0;
    end else if(next_state == EXE && mul_count >= 3) begin
        if(count_24 == 24)
            count_24 <= 0;
        else
            count_24 <= count_24+1;
    end
end
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        count_limit <= 0;
    end else if(next_state == EXE && mul_count >= 3) begin
        if(count_limit == image_limit)
            count_limit <= 0;
        else
            count_limit <= count_limit+1;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        compare_count <= 0;
    end else if(next_state == EXE) begin
        if(count_24 == 24)begin
            compare_count <= compare_count+1;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_count <= 0;
    end else if(curr_state == EXE) begin
        mul_count <= mul_count +1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_a <= 0;
    end else if(next_state == EXE) begin // && mode_tmp == 0
        case (image_idx)
            0 : mul_a <= image_out_1;
            1 : mul_a <= image_out_2;
            2 : mul_a <= image_out_3;
            3 : mul_a <= image_out_4;
            4 : mul_a <= image_out_5;
            5 : mul_a <= image_out_6;
            6 : mul_a <= image_out_7;
            7 : mul_a <= image_out_8;
            8 : mul_a <= image_out_9;
            9 : mul_a <= image_out_10;
            10 : mul_a <= image_out_11;
            11 : mul_a <= image_out_12;
            12 : mul_a <= image_out_13;
            13 : mul_a <= image_out_14;
            14 : mul_a <= image_out_15;
            15 : mul_a <= image_out_16;
            default : mul_a <= 0;
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_b <= 0;
    end else if(next_state ==EXE) begin// && mode_tmp == 0
        case (ker_idx)
            0 : mul_b <= ker_out_1;
            1 : mul_b <= ker_out_2;
            2 : mul_b <= ker_out_3;
            3 : mul_b <= ker_out_4;
            4 : mul_b <= ker_out_5;
            5 : mul_b <= ker_out_6;
            6 : mul_b <= ker_out_7;
            7 : mul_b <= ker_out_8;
            8 : mul_b <= ker_out_9;
            9 : mul_b <= ker_out_10;
            10 : mul_b <= ker_out_11;
            11 : mul_b <= ker_out_12;
            12 : mul_b <= ker_out_13;
            13 : mul_b <= ker_out_14;
            14 : mul_b <= ker_out_15;
            15 : mul_b <= ker_out_16;
            default : mul_b <= 0;
        endcase
    end
end
always @(*) begin
    if(next_state == EXE && mul_count >= 3)begin
        sum_tmp = mul_a*mul_b;
    end
    else sum_tmp = 0;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        sum <= 0;
    end else if(next_state == EXE && mul_count >= 3) begin// && mode_tmp == 0
        if(count_24 == 24)begin
            sum <= 0;
        end
        else begin
            sum <= sum + sum_tmp ;
        end
    end
end

//---------------------------------------------------------------------
//   MAX pooling(ha ha ha sb)
//---------------------------------------------------------------------
reg signed [19:0] compare_2[0:1], compare_6[0:5], compare_14[0:13];
reg signed [19:0] compare_B[0:55];
reg signed [19:0] comp_a, comp_b, comp_c, comp_d, comp_e, comp_final, comp_g, comp_h;
reg signed [19:0] comp_lev2_a, comp_lev2_b, comp_lev2_c, comp_lev2_d, comp_lev2_e;
reg signed [19:0] sol_a, sol_b, sol_c, sol_d; 
reg signed [19:0] comp_lev2_6[0:5], comp_lev2_14[0:13];
reg signed [19:0] comp_tmp_a, comp_tmp_b, comp_tmp_c, comp_tmp_d, comp_tmp_e, comp_tmp_g, comp_tmp_h;
reg signed [19:0] comp_2nd_a, comp_2nd_b, comp_2nd_c, comp_2nd_d, comp_2nd_e, comp_2nd_final;
integer i,j;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        compare_2[0] <= 0;
        compare_2[1] <= 0;
    end else if(next_state == EXE) begin// && mode_tmp == 0
        if(count_24 == 24 && matrix_size_reg ==7)begin
            compare_2[1] <= sum + sum_tmp;
            compare_2[0] <= compare_2[1];
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for( i =0;i<=5;i = i+1)begin
            compare_6[i] <= 0;
        end
    end else if(next_state == EXE) begin// && mode_tmp == 0
        if(count_24 == 24 && matrix_size_reg ==15)begin
            compare_6[5] <= sum + sum_tmp;
            for(i = 4;i>=0;i= i-1)begin
                compare_6[i] <= compare_6[i+1];
            end 
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for( i =0;i<=13;i = i+1)begin
            compare_14[i] <= 0;
        end
    end else if(next_state == EXE) begin// && mode_tmp == 0
        if(count_24 == 24 && matrix_size_reg ==31)begin
            compare_14[13] <= sum + sum_tmp;
            for(i = 12;i>=0;i= i-1)begin
                compare_14[i] <= compare_14[i+1];
            end 
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        comp_a <= 0;
        comp_b <= 0;
        comp_c <= 0;
        comp_d <= 0;
        comp_e <= 0;
        comp_g <= 0;
        comp_final <= 0;
    end else if(next_state == EXE) begin// && mode_tmp == 0
        case (matrix_size_reg)
            7: begin
                if(compare_count % 2 == 0)begin
                    comp_final <= (compare_2[1] >= compare_2[0])? compare_2[1] : compare_2[0];
                end
            end
            15: begin
                if(compare_count % 6 == 0)begin
                    comp_a <= (compare_6[0] >= compare_6[1])? compare_6[0] : compare_6[1];
                    comp_b <= (compare_6[2] >= compare_6[3])? compare_6[2] : compare_6[3];
                    comp_c <= (compare_6[4] >= compare_6[5])? compare_6[4] : compare_6[5];
                end
            end
            31 : begin
                if(compare_count % 14 == 0)begin
                    comp_a <= (compare_14[0] >= compare_14[1])? compare_14[0] : compare_14[1];
                    comp_b <= (compare_14[2] >= compare_14[3])? compare_14[2] : compare_14[3];
                    comp_c <= (compare_14[4] >= compare_14[5])? compare_14[4] : compare_14[5];
                    comp_d <= (compare_14[6] >= compare_14[7])? compare_14[6] : compare_14[7];
                    comp_e <= (compare_14[8] >= compare_14[9])? compare_14[8] : compare_14[9];
                    comp_g <= (compare_14[10] >= compare_14[11])? compare_14[10] : compare_14[11];
                    comp_h <= (compare_14[12] >= compare_14[13])? compare_14[12] : compare_14[13];
                end
            end
            default : comp_final <= 0;
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        comp_lev2_a <= 0;
        comp_lev2_b <= 0;
        comp_lev2_c <= 0;
        comp_lev2_d <= 0;
    end 
    else if(next_state == EXE) begin
        if(matrix_size_reg == 15)begin
            comp_lev2_a <= (comp_a >= comp_b)? comp_a : comp_b;
            comp_final <= (comp_lev2_a >= comp_c)? comp_lev2_a : comp_c;
        end
        else if(matrix_size_reg == 31)begin
            comp_lev2_a <= (comp_a >= comp_b)? comp_a : comp_b;
            comp_lev2_b <= (comp_c >= comp_d)? comp_c : comp_d;
            comp_lev2_c <= (comp_e >= comp_g)? comp_e : comp_g;
            comp_lev2_d <= (comp_lev2_a >= comp_h)? comp_lev2_a : comp_h;
            comp_lev2_e <= (comp_lev2_b >= comp_lev2_c)? comp_lev2_b : comp_lev2_c;

            comp_final <= (comp_lev2_d >= comp_lev2_e)? comp_lev2_d : comp_lev2_e;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for( i =0;i<=55;i = i+1)begin
            compare_B[i] <= 0;
        end
    end else if(next_state == EXE) begin// && mode_tmp == 0
        case (matrix_size_reg)
            7 : begin
                if(compare_count % 2 == 0 && count_24 ==1)begin
                    compare_B[7] <= comp_final;
                    for(i = 6;i>=0;i=i-1)begin
                        compare_B[i] <= compare_B[i+1];
                    end
                end
            end
            15 : begin
                if(compare_count % 6 == 0 && count_24 ==2)begin
                    compare_B[23] <= comp_final;
                    for(i = 22;i>=0;i=i-1)begin
                        compare_B[i] <= compare_B[i+1];
                    end
                end
            end
            31 : begin
                if(compare_count % 14 == 0 && count_24 ==2)begin
                    compare_B[55] <= comp_final;
                    for(i = 54;i>=0;i=i-1)begin
                        compare_B[i] <= compare_B[i+1];
                    end
                end
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(i = 0;i<=5;i = i+1)begin
            comp_lev2_6[i] <= 0;
        end
    end else if(next_state == EXE) begin
        if(matrix_size_reg == 15 && compare_count==144)begin
            case(count_24)
                3 : begin
                     comp_lev2_6[0] <= compare_B[0];
                     comp_lev2_6[1] <= compare_B[2];
                     comp_lev2_6[2] <= compare_B[4];
                     comp_lev2_6[3] <= compare_B[6];
                     comp_lev2_6[4] <= compare_B[8];
                     comp_lev2_6[5] <= compare_B[10];
                 end
                4 : begin
                     comp_lev2_6[0] <= compare_B[1];
                     comp_lev2_6[1] <= compare_B[3];
                     comp_lev2_6[2] <= compare_B[5];
                     comp_lev2_6[3] <= compare_B[7];
                     comp_lev2_6[4] <= compare_B[9];
                     comp_lev2_6[5] <= compare_B[11];
                 end
                5 : begin
                     comp_lev2_6[0] <= compare_B[12];
                     comp_lev2_6[1] <= compare_B[14];
                     comp_lev2_6[2] <= compare_B[16];
                     comp_lev2_6[3] <= compare_B[18];
                     comp_lev2_6[4] <= compare_B[20];
                     comp_lev2_6[5] <= compare_B[22];
                 end
                6 : begin
                     comp_lev2_6[0] <= compare_B[13];
                     comp_lev2_6[1] <= compare_B[15];
                     comp_lev2_6[2] <= compare_B[17];
                     comp_lev2_6[3] <= compare_B[19];
                     comp_lev2_6[4] <= compare_B[21];
                     comp_lev2_6[5] <= compare_B[23];
                 end
             endcase
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(i = 0;i<=13;i = i+1)begin
            comp_lev2_14[i] <= 0;
        end
    end else if(next_state == EXE) begin
        if(matrix_size_reg == 31 && compare_count==784)begin
            case(count_24)
                8 : begin
                     comp_lev2_14[0] <= compare_B[0];
                     comp_lev2_14[1] <= compare_B[2];
                     comp_lev2_14[2] <= compare_B[4];
                     comp_lev2_14[3] <= compare_B[6];
                     comp_lev2_14[4] <= compare_B[8];
                     comp_lev2_14[5] <= compare_B[10];
                     comp_lev2_14[6] <= compare_B[12];
                     comp_lev2_14[7] <= compare_B[14];
                     comp_lev2_14[8] <= compare_B[16];
                     comp_lev2_14[9] <= compare_B[18];
                     comp_lev2_14[10] <= compare_B[20];
                     comp_lev2_14[11] <= compare_B[22];
                     comp_lev2_14[12] <= compare_B[24];
                     comp_lev2_14[13] <= compare_B[26];                    
                 end
                9 : begin
                     comp_lev2_14[0] <= compare_B[1];
                     comp_lev2_14[1] <= compare_B[3];
                     comp_lev2_14[2] <= compare_B[5];
                     comp_lev2_14[3] <= compare_B[7];
                     comp_lev2_14[4] <= compare_B[9];
                     comp_lev2_14[5] <= compare_B[11];
                     comp_lev2_14[6] <= compare_B[13];
                     comp_lev2_14[7] <= compare_B[15];
                     comp_lev2_14[8] <= compare_B[17];
                     comp_lev2_14[9] <= compare_B[19];
                     comp_lev2_14[10] <= compare_B[21];
                     comp_lev2_14[11] <= compare_B[23];
                     comp_lev2_14[12] <= compare_B[25];
                     comp_lev2_14[13] <= compare_B[27];     
                 end
                10 : begin
                     comp_lev2_14[0] <= compare_B[28];
                     comp_lev2_14[1] <= compare_B[30];
                     comp_lev2_14[2] <= compare_B[32];
                     comp_lev2_14[3] <= compare_B[34];
                     comp_lev2_14[4] <= compare_B[36];
                     comp_lev2_14[5] <= compare_B[38];
                     comp_lev2_14[6] <= compare_B[40];
                     comp_lev2_14[7] <= compare_B[42];
                     comp_lev2_14[8] <= compare_B[44];
                     comp_lev2_14[9] <= compare_B[46];
                     comp_lev2_14[10] <= compare_B[48];
                     comp_lev2_14[11] <= compare_B[50];
                     comp_lev2_14[12] <= compare_B[52];
                     comp_lev2_14[13] <= compare_B[54];        
                 end
                11 : begin
                     comp_lev2_14[0] <= compare_B[29];
                     comp_lev2_14[1] <= compare_B[31];
                     comp_lev2_14[2] <= compare_B[33];
                     comp_lev2_14[3] <= compare_B[35];
                     comp_lev2_14[4] <= compare_B[37];
                     comp_lev2_14[5] <= compare_B[39];
                     comp_lev2_14[6] <= compare_B[41];
                     comp_lev2_14[7] <= compare_B[43];
                     comp_lev2_14[8] <= compare_B[45];
                     comp_lev2_14[9] <= compare_B[47];
                     comp_lev2_14[10] <= compare_B[49];
                     comp_lev2_14[11] <= compare_B[51];
                     comp_lev2_14[12] <= compare_B[53];
                     comp_lev2_14[13] <= compare_B[55];        
                 end
             endcase
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        comp_tmp_a <= 0;
        comp_tmp_b <= 0;
        comp_tmp_c <= 0;
        comp_tmp_d <= 0;
        comp_tmp_e <= 0;
        comp_tmp_g <= 0;
        comp_tmp_h <= 0;

    end else if(next_state == EXE) begin// && mode_tmp == 0
        case (matrix_size_reg)
            15: begin
                if(compare_count % 6 == 0)begin
                    comp_tmp_a <= (comp_lev2_6[0] >= comp_lev2_6[1])? comp_lev2_6[0] : comp_lev2_6[1];
                    comp_tmp_b <= (comp_lev2_6[2] >= comp_lev2_6[3])? comp_lev2_6[2] : comp_lev2_6[3];
                    comp_tmp_c <= (comp_lev2_6[4] >= comp_lev2_6[5])? comp_lev2_6[4] : comp_lev2_6[5];
                end
            end
            31 : begin
                if(compare_count % 14 == 0)begin
                    comp_tmp_a <= (comp_lev2_14[0] >= comp_lev2_14[1])? comp_lev2_14[0] : comp_lev2_14[1];
                    comp_tmp_b <= (comp_lev2_14[2] >= comp_lev2_14[3])? comp_lev2_14[2] : comp_lev2_14[3];
                    comp_tmp_c <= (comp_lev2_14[4] >= comp_lev2_14[5])? comp_lev2_14[4] : comp_lev2_14[5];
                    comp_tmp_d <= (comp_lev2_14[6] >= comp_lev2_14[7])? comp_lev2_14[6] : comp_lev2_14[7];
                    comp_tmp_e <= (comp_lev2_14[8] >= comp_lev2_14[9])? comp_lev2_14[8] : comp_lev2_14[9];
                    comp_tmp_g <= (comp_lev2_14[10] >= comp_lev2_14[11])? comp_lev2_14[10] : comp_lev2_14[11];
                    comp_tmp_h <= (comp_lev2_14[12] >= comp_lev2_14[13])? comp_lev2_14[12] : comp_lev2_14[13];
                end
            end
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        comp_2nd_a <= 0;
        comp_2nd_b <= 0;
        comp_2nd_c <= 0;
        comp_2nd_d <= 0;
        comp_2nd_e <= 0;
        comp_2nd_final <= 0;
    end 
    else if(next_state == EXE) begin
        if(matrix_size_reg == 15)begin
            comp_2nd_a <= (comp_tmp_a >= comp_tmp_b)? comp_tmp_a : comp_tmp_b;
            comp_2nd_final <= (comp_2nd_a >= comp_tmp_c)? comp_2nd_a : comp_tmp_c;
        end
        else if(matrix_size_reg == 31)begin
            comp_2nd_a <= (comp_tmp_a >= comp_tmp_b)? comp_tmp_a : comp_tmp_b;
            comp_2nd_b <= (comp_tmp_c >= comp_tmp_d)? comp_tmp_c : comp_tmp_d;
            comp_2nd_c <= (comp_tmp_e >= comp_tmp_g)? comp_tmp_e : comp_tmp_g;
            comp_2nd_d <= (comp_2nd_a >= comp_tmp_h)? comp_2nd_a : comp_tmp_h;
            comp_2nd_e <= (comp_2nd_b >= comp_2nd_c)? comp_2nd_b : comp_2nd_c;

            comp_2nd_final <= (comp_2nd_d >= comp_2nd_e)? comp_2nd_d : comp_2nd_e;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        sol_a <= 0;
        sol_b <= 0;
        sol_c <= 0;
        sol_d <= 0;
    end else if(next_state == EXE) begin
        case (matrix_size_reg)
            7: begin
                if(compare_count == 16 && count_24 == 2)begin
                    sol_a <= (compare_B[2] >= compare_B[0])? compare_B[2] : compare_B[0];
                    sol_b <= (compare_B[3] >= compare_B[1])? compare_B[3] : compare_B[1];
                    sol_c <= (compare_B[6] >= compare_B[4])? compare_B[6] : compare_B[4];
                    sol_d <= (compare_B[7] >= compare_B[5])? compare_B[7] : compare_B[5];
                end
            end
            15: begin
                if(compare_count == 144)begin
                    if(count_24 == 7)begin
                        sol_a <= comp_2nd_final;
                    end
                    else if(count_24 == 8)begin
                        sol_b <= comp_2nd_final;
                    end
                    else if(count_24 == 9)begin
                        sol_c <= comp_2nd_final;
                    end
                    else if(count_24 == 10)begin
                        sol_d <= comp_2nd_final;
                    end
                end
            end
            31 : begin
                if(compare_count == 784)begin
                    if(count_24 == 12)begin
                        sol_a <= comp_2nd_final;
                    end
                    else if(count_24 == 13)begin
                        sol_b <= comp_2nd_final;
                    end
                    else if(count_24 == 14)begin
                        sol_c <= comp_2nd_final;
                    end
                    else if(count_24 == 15)begin
                        sol_d <= comp_2nd_final;
                    end
                end
            end
            default :begin
                sol_a <= 0;
                sol_b <= 0;
                sol_c <= 0;
                sol_d <= 0;
            end
        endcase
    end
end
//---------------------------------------------------------------------
//   DECONV(not done)
//---------------------------------------------------------------------
reg signed [7:0] ker_matrix[0:4][0:4], image_matrix_8[0:7][0:7], image_matrix_16[0:15][0:15], image_matrix_32[0:31][0:31];
reg signed [19:0] deconv_12[0:11][0:11], deconv_20[0:19][0:19], deconv_36[0:35][0:35];

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        for(i = 0; i<=4;i=i+1)begin
            for(j =0;j<=4;j=j+1)begin
                ker_matrix[i][j] <= 0;
            end
        end
    end else if(curr_state == EXE && mul_count >=3) begin
        ker_matrix[count_24/5][count_24%5] <= mul_b;
    end
end
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        for(i = 0; i<=7;i=i+1)begin
            for(j =0;j<=7;j=j+1)begin
                image_matrix_8[i][j] <= 0;
            end
        end
    end else if(curr_state == EXE && mul_count >=3) begin
        if(matrix_size_reg == 7)begin
            image_matrix_8[(count_limit)/8][(count_limit)%8] <= mul_a;
        end
    end
end
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        for(i = 0; i<=15;i=i+1)begin
            for(j =0;j<=15;j=j+1)begin
                image_matrix_16[i][j] <= 0;
            end
        end
    end else if(curr_state == EXE && mul_count >=3) begin
        if(matrix_size_reg == 15)begin
            image_matrix_16[(count_limit)/16][(count_limit)%16] <= mul_a;
        end
    end
end
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        for(i = 0; i<=31;i=i+1)begin
            for(j =0;j<=31;j=j+1)begin
                image_matrix_32[i][j] <= 0;
            end
        end
    end else if(curr_state == EXE && mul_count >=3) begin
        if(matrix_size_reg == 31)begin
            image_matrix_32[(count_limit)/32][(count_limit)%32] <= mul_a;
        end
    end
end

integer m, n;
reg [5:0] out_i, out_j;


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        // Reset the output buffer
        for (i = 0; i <=11 ; i = i + 1) begin
            for (j = 0; j <=11; j = j + 1) begin
                deconv_12[i][j] <= 'b0;
            end
        end
    end else if(curr_state ==EXE ) begin
        if(matrix_size_reg == 7 && mul_count==67)begin
            // Transposed convolution operation
            for (i = 0; i <= 7; i = i + 1) begin
                for (j = 0; j <= 7; j = j + 1) begin
                    // For each input pixel, distribute its value to the output pixels
                    for (m = 0; m <= 4; m = m + 1) begin
                        for (n = 0; n <= 4; n = n + 1) begin
                            // Calculate the output pixel coordinates
                            out_i = i + m;
                            out_j = j + n;
                            // Perform the transposed convolution operation
                            if (out_i <= 11 && out_j <= 11) begin
                            deconv_12[out_i][out_j] <= deconv_12[out_i][out_j] + (ker_matrix[m][n] * image_matrix_8[i][j]);
                            end
                        end
                    end
                end
            end
        end
        
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        // Reset the output buffer
        for (i = 0; i <=19 ; i = i + 1) begin
            for (j = 0; j <=19; j = j + 1) begin
                deconv_20[i][j] <= 'b0;
            end
        end
    end else if(curr_state ==EXE ) begin
        if(matrix_size_reg == 15 && mul_count==259)begin
            // Transposed convolution operation
            for (i = 0; i <= 15; i = i + 1) begin
                for (j = 0; j <= 15; j = j + 1) begin
                    // For each input pixel, distribute its value to the output pixels
                    for (m = 0; m <= 4; m = m + 1) begin
                        for (n = 0; n <= 4; n = n + 1) begin
                            // Calculate the output pixel coordinates
                            out_i = i + m;
                            out_j = j + n;
                            // Perform the transposed convolution operation
                            if (out_i <= 19 && out_j <= 19) begin
                            deconv_20[out_i][out_j] <= deconv_20[out_i][out_j] + (ker_matrix[m][n] * image_matrix_16[i][j]);
                            end
                        end
                    end
                end
            end
        end
        
    end
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        // Reset the output buffer
        for (i = 0; i <=35 ; i = i + 1) begin
            for (j = 0; j <=35; j = j + 1) begin
                deconv_36[i][j] <= 8'b0;
            end
        end
    end else if(curr_state ==EXE ) begin
        if(matrix_size_reg == 31 && mul_count==1027)begin
            // Transposed convolution operation
            for (i = 0; i <= 31; i = i + 1) begin
                for (j = 0; j <= 31; j = j + 1) begin
                    // For each input pixel, distribute its value to the output pixels
                    for (m = 0; m <= 4; m = m + 1) begin
                        for (n = 0; n <= 4; n = n + 1) begin
                            // Calculate the output pixel coordinates
                            out_i = i + m;
                            out_j = j + n;
                            // Perform the transposed convolution operation
                            if (out_i <= 35 && out_j <= 35) begin
                            deconv_36[out_i][out_j] <= deconv_36[out_i][out_j] + (ker_matrix[m][n] * image_matrix_32[i][j]);
                            end
                        end
                    end
                end
            end
        end
        
    end
end
//---------------------------------------------------------------------
//   EXE
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        exe_finish <= 0;
    end else if(curr_state == EXE) begin
        if(mode_tmp == 0)begin
            case (matrix_size_reg)
                7: if(compare_count == 17) exe_finish <= 1;
                15: if(compare_count == 145) exe_finish <= 1;
                31: if(compare_count == 785) exe_finish <= 1;
                default : exe_finish <= 0;
            endcase
        end
        else begin
            case (matrix_size_reg)
                7: if(mul_count == 67) exe_finish <= 1;
                15: if(mul_count == 259) exe_finish <= 1;
                31: if(mul_count == 1027) exe_finish <= 1;
                default : exe_finish <= 0;
            endcase
        end
    end
end
//---------------------------------------------------------------------
//   FSM BLOCK
//---------------------------------------------------------------------
//  Current State Block
reg out_finish;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        curr_state <= IDLE;
    end
    else begin
        curr_state <= next_state;
    end
end

//  Next State Block
always@(*)begin
    if(!rst_n)
        next_state = IDLE ;
    else begin
        case(curr_state)
        IDLE:
            next_state = (!in_valid)? IDLE : INPUT_1 ;
        INPUT_1:
            next_state = (!in_valid) ? WAIT : INPUT_1 ;
        WAIT:
            next_state = (!in_valid2)? WAIT : INPUT_2;
        INPUT_2:
            next_state = (!in_valid2)? EXE : INPUT_2;
        EXE: 
            next_state = (!exe_finish)? EXE : OUT;
        OUT: 
            next_state = (!out_finish)? OUT : WAIT;

        default :
            next_state = IDLE ;
        endcase
    end
end

//---------------------------------------------------------------------
//   OUT BLOCK(should out when out_valid high)
//---------------------------------------------------------------------
reg signed out_tmp;
reg signed [19:0] serial_out;
reg [10:0] out_count;
reg [4:0] count_out_20;
reg [5:0] tar_x, tar_y;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) out_valid <= 'd0;
    else if(curr_state == OUT) out_valid <= 'd1;
    else out_valid <= 'd0; 
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_finish <= 0;
    end 
    else if(curr_state == OUT) begin
        if(mode_tmp == 1)begin
            case (matrix_size_reg)
                7: out_finish <= (out_count == 144) ? 1:0;
                15: out_finish <= (out_count == 400) ? 1:0;
                31: out_finish <= (out_count == 1296) ? 1:0;
            endcase
        end
        else begin
            out_finish <= (out_count == 4) ? 1:0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_count <= 0;
    end else if(out_valid) begin
        if(count_out_20 ==19)begin
            out_count <= out_count+1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        count_out_20 <= 0;
    end else if(out_valid) begin
        if (count_out_20 == 19) begin
            count_out_20 <= 0;
        end
        else
            count_out_20 <= count_out_20 +1;
    end
end

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        tar_x <= 0;
    end else if(curr_state == OUT && count_out_20 == 19) begin
        case (matrix_size_reg)
            7: begin
                if(tar_y == 11)begin
                    tar_x <= tar_x +1;
                end
            end
            15: begin
                if(tar_y == 19)begin
                    tar_x <= tar_x +1;
                end
            end
            31: begin
                if(tar_y == 35)begin
                    tar_x <= tar_x +1;
                end
            end         
            
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        tar_y <= 0;
    end else if(curr_state == OUT && count_out_20 == 19) begin
        case (matrix_size_reg)
            7: begin
                if(tar_y == 11)begin
                    tar_y <= 0;
                end
                else begin
                    tar_y <= tar_y +1;
                end
            end
            15: begin
                if(tar_y == 19)begin
                    tar_y <= 0;
                end
                else begin
                    tar_y <= tar_y +1;
                end
            end
            31: begin
                if(tar_y == 35)begin
                    tar_y <= 0;
                end
                else begin
                    tar_y <= tar_y +1;
                end
            end
        endcase
    end
end
always @(*) begin
    if(curr_state == OUT ) begin
        if(mode_tmp == 1)begin
            case (matrix_size_reg)
            7:  serial_out = deconv_12[tar_x][tar_y];
            15: serial_out = deconv_20[tar_x][tar_y];
            31: serial_out = deconv_36[tar_x][tar_y];
            default: serial_out = 0;
            endcase
        end
        else begin
            case (out_count)
                0: serial_out = sol_a;
                1: serial_out = sol_b;
                2: serial_out = sol_c;
                3: serial_out = sol_d;
                    
                default : serial_out = 0;
            endcase
        end
    end
    else serial_out = 0;
    
end
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        serial_out <= 0;
    end else if(curr_state == OUT)begin
        if(count_out_20 < 19) serial_out <= serial_out>>1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_tmp <= 0;
    end else if(curr_state ==OUT) begin
        out_tmp <= serial_out[0];
 
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) out_value <= 'd0;
    // summation along antidiagonal direction will always equal to the summation of out_temp 0 ~ 15
    else if(curr_state == OUT)begin
        out_value <= out_tmp;
    end
    else out_value <= 'd0;
end

endmodule