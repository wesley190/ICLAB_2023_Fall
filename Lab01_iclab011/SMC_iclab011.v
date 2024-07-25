//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab01 Exercise             : Supper MOSFET Calculator
//   Author                     : Lin-Hung Lai (lhlai@ieee.org)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SMC.v
//   Module Name : SMC
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module SMC(
    // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
    // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
output reg [7:0] out_n;

//================================================================
//    Wire & Registers 
//================================================================
//
genvar index;
parameter MAXN = 5 ;
//
wire [2:0] W_[0:MAXN], V_GS[0:MAXN], V_DS[0:MAXN];
//
wire [2:0] ID_Tri_A[0:MAXN];
wire [3:0] ID_Tri_B[0:MAXN];
wire [2:0] ID_Sat_A[0:MAXN], ID_Sat_B[0:MAXN];
wire [2:0] gm_Tri_A[0:MAXN], gm_Tri_B[0:MAXN];
wire [2:0] gm_Sat_A[0:MAXN], gm_Sat_B[0:MAXN];
//
wire Tri_flag[0:MAXN];
//

//
wire [6:0] sol;
reg [6:0] cal[0:MAXN];
wire [6:0] tmp[0:MAXN], tmp1[0:2];
//================================================================
//    DESIGN
//================================================================

assign W_ = {W_0, W_1, W_2, W_3, W_4, W_5};
assign V_DS = {V_DS_0, V_DS_1, V_DS_2, V_DS_3, V_DS_4, V_DS_5};
assign V_GS = {V_GS_0, V_GS_1, V_GS_2, V_GS_3, V_GS_4, V_GS_5};

// assign ID/gm value in Tri/Sat mode
generate
    for( index=0 ; index<=MAXN ; index=index+1 ) begin
        //
        assign ID_Tri_A[index] = V_DS[index] ;
        assign ID_Tri_B[index] = 2*V_GS[index] - V_DS[index] - 2 ;
        //
        assign gm_Tri_A[index] = 2 ;
        assign gm_Tri_B[index] = V_DS[index] ;
        //
        assign ID_Sat_A[index] = V_GS[index] - 1 ;
        assign ID_Sat_B[index] = ID_Sat_A[index] ;      // V_GS[index] - 1
        //
        assign gm_Sat_A[index] = 2 ;
        assign gm_Sat_B[index] = ID_Sat_A[index] ;      // V_GS[index] - 1
    end
endgenerate

// flag Tri/Sat mode
generate
    for( index=0 ; index<=MAXN ; index=index+1 ) begin
        assign Tri_flag[index] = ( (V_GS[index]-1)>V_DS[index] ) ? 1'b1 : 1'b0 ;
    end
endgenerate

Cal calculation( .ID_Tri_A(ID_Tri_A[0]), .ID_Tri_B(ID_Tri_B[0]), .ID_Sat_A(ID_Sat_A[0]), .ID_Sat_B(ID_Sat_B[0]),
                 .gm_Tri_A(gm_Tri_A[0]), .gm_Tri_B(gm_Tri_B[0]), .gm_Sat_A(gm_Sat_A[0]), .gm_Sat_B(gm_Sat_B[0]),
                 .W(W_[0]), .flag(Tri_flag[0]), .mode(mode[0]), .sol(cal[0]) );
Cal calculation1( .ID_Tri_A(ID_Tri_A[1]), .ID_Tri_B(ID_Tri_B[1]), .ID_Sat_A(ID_Sat_A[1]), .ID_Sat_B(ID_Sat_B[1]),
                  .gm_Tri_A(gm_Tri_A[1]), .gm_Tri_B(gm_Tri_B[1]), .gm_Sat_A(gm_Sat_A[1]), .gm_Sat_B(gm_Sat_B[1]),
                  .W(W_[1]), .flag(Tri_flag[1]), .mode(mode[0]), .sol(cal[1]) );
Cal calculation2( .ID_Tri_A(ID_Tri_A[2]), .ID_Tri_B(ID_Tri_B[2]), .ID_Sat_A(ID_Sat_A[2]), .ID_Sat_B(ID_Sat_B[2]),
                  .gm_Tri_A(gm_Tri_A[2]), .gm_Tri_B(gm_Tri_B[2]), .gm_Sat_A(gm_Sat_A[2]), .gm_Sat_B(gm_Sat_B[2]),
                  .W(W_[2]), .flag(Tri_flag[2]), .mode(mode[0]), .sol(cal[2]) );
Cal calculation3( .ID_Tri_A(ID_Tri_A[3]), .ID_Tri_B(ID_Tri_B[3]), .ID_Sat_A(ID_Sat_A[3]), .ID_Sat_B(ID_Sat_B[3]),
                  .gm_Tri_A(gm_Tri_A[3]), .gm_Tri_B(gm_Tri_B[3]), .gm_Sat_A(gm_Sat_A[3]), .gm_Sat_B(gm_Sat_B[3]),
                  .W(W_[3]), .flag(Tri_flag[3]), .mode(mode[0]), .sol(cal[3]) );
Cal calculation4( .ID_Tri_A(ID_Tri_A[4]), .ID_Tri_B(ID_Tri_B[4]), .ID_Sat_A(ID_Sat_A[4]), .ID_Sat_B(ID_Sat_B[4]),
                  .gm_Tri_A(gm_Tri_A[4]), .gm_Tri_B(gm_Tri_B[4]), .gm_Sat_A(gm_Sat_A[4]), .gm_Sat_B(gm_Sat_B[4]),
                  .W(W_[4]), .flag(Tri_flag[4]), .mode(mode[0]), .sol(cal[4]) );
Cal calculation5( .ID_Tri_A(ID_Tri_A[5]), .ID_Tri_B(ID_Tri_B[5]), .ID_Sat_A(ID_Sat_A[5]), .ID_Sat_B(ID_Sat_B[5]),
                  .gm_Tri_A(gm_Tri_A[5]), .gm_Tri_B(gm_Tri_B[5]), .gm_Sat_A(gm_Sat_A[5]), .gm_Sat_B(gm_Sat_B[5]),
                  .W(W_[5]), .flag(Tri_flag[5]), .mode(mode[0]), .sol(cal[5]) );


// sort
Sort sort(  .in0(cal[0]), .in1(cal[1]), .in2(cal[2]), .in3(cal[3]), .in4(cal[4]), .in5(cal[5]),
            .out0(tmp[0]) , .out1(tmp[1]) , .out2(tmp[2]) , .out3(tmp[3]) , .out4(tmp[4]) , .out5(tmp[5]) );

// based on mode[1], choose larger/smaller values
assign tmp1[0] = ( mode[1]==1'b1 ) ? tmp[0] : tmp[3] ;
assign tmp1[1] = ( mode[1]==1'b1 ) ? tmp[1] : tmp[4] ;
assign tmp1[2] = ( mode[1]==1'b1 ) ? tmp[2] : tmp[5] ;

always @(*) begin
    case(mode[0])
        1'b0: out_n = ( tmp1[0]+tmp1[1]+tmp1[2] )/3;
        1'b1: out_n = ( 3*tmp1[0] + 4*tmp1[1] + 5*tmp1[2] )/12;        //( 3*n1 + 4*n2 + 5*n3 )/12
        
    endcase
end




endmodule

//================================================================
//   SUB MODULE
//================================================================
//
//calculate vaiue of ID/gm
module Cal(
    // input
    ID_Tri_A, ID_Tri_B, ID_Sat_A, ID_Sat_B,
    gm_Tri_A, gm_Tri_B, gm_Sat_A, gm_Sat_B, W, flag, mode,
    // output
    sol
    );
input flag, mode;
input [2:0] ID_Tri_A, ID_Sat_A, ID_Sat_B, gm_Tri_A, gm_Tri_B, gm_Sat_A, gm_Sat_B, W;
input [3:0] ID_Tri_B;
output [6:0] sol;

wire [2:0] ID_A, gm_A, gm_B;
wire [3:0] ID_B;

wire [2:0] final_A;
wire [3:0] final_B;

//base on flag, set ID/gm value we want
assign ID_A = ( flag==1'b1 ) ? ID_Tri_A : ID_Sat_A ;
assign ID_B = ( flag==1'b1 ) ? ID_Tri_B : ID_Sat_B ;
assign gm_A = ( flag==1'b1 ) ? gm_Tri_A : gm_Sat_A ;
assign gm_B = ( flag==1'b1 ) ? gm_Tri_B : gm_Sat_B ;
//
//base on mode[0], set multiple element final_A/final_B
assign final_A = ( mode==1'b1 ) ? ID_A : gm_A ;
assign final_B = ( mode==1'b1 ) ? ID_B : gm_B ;
//
//calculate the value of ID/gm
assign sol = ( final_A * final_B * W )/3;


endmodule


// sort 6 elements
module Sort(
    // Input signals
    in0, in1, in2, in3, in4, in5,
    // Output signals
    out0, out1, out2, out3, out4, out5
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [6:0] in0, in1, in2, in3, in4, in5;
output [6:0] out0, out1, out2, out3, out4, out5;
//================================================================
//    Wire & Registers 
//================================================================
wire [6:0] a[0:5], b[0:5], c[0:5], d[0:5], e[0:5];
//================================================================
//    DESIGN
//================================================================
//
assign a[0] = ( in0>in1 ) ? in0 : in1 ;
assign a[1] = ( in0>in1 ) ? in1 : in0 ;
assign a[2] = ( in2>in3 ) ? in2 : in3 ;
assign a[3] = ( in2>in3 ) ? in3 : in2 ;
assign a[4] = ( in4>in5 ) ? in4 : in5 ;
assign a[5] = ( in4>in5 ) ? in5 : in4 ;

assign b[0] = ( a[0]>a[2] ) ? a[0] : a[2];
assign b[1] = ( a[0]>a[2] ) ? a[2] : a[0];
assign b[2] = ( a[1]>a[4] ) ? a[1] : a[4];
assign b[3] = ( a[1]>a[4] ) ? a[4] : a[1];
assign b[4] = ( a[3]>a[5] ) ? a[3] : a[5];
assign b[5] = ( a[3]>a[5] ) ? a[5] : a[3];

assign c[0] = ( b[0]>b[2] ) ? b[0] : b[2];
assign c[1] = ( b[0]>b[2] ) ? b[2] : b[0];
assign c[2] = ( b[1]>b[4] ) ? b[1] : b[4];
assign c[3] = ( b[1]>b[4] ) ? b[4] : b[1];
assign c[4] = ( b[3]>b[5] ) ? b[3] : b[5];
assign c[5] = ( b[3]>b[5] ) ? b[5] : b[3];

assign d[0] = ( c[1]>c[2] ) ? c[1] : c[2];
assign d[1] = ( c[1]>c[2] ) ? c[2] : c[1];
assign d[2] = ( c[3]>c[4] ) ? c[3] : c[4];
assign d[3] = ( c[3]>c[4] ) ? c[4] : c[3];

assign d[4] = ( d[1]>d[2] ) ? d[1] : d[2];
assign d[5] = ( d[1]>d[2] ) ? d[2] : d[1];

assign out0 = c[0];
assign out1 = d[0];
assign out2 = d[4];
assign out3 = d[5];
assign out4 = d[3];
assign out5 = c[5];

endmodule


// module BBQ (meat,vagetable,water,cost);
// input XXX;
// output XXX;
// 
// endmodule

// --------------------------------------------------
// Example for using submodule 
// BBQ bbq0(.meat(meat_0), .vagetable(vagetable_0), .water(water_0),.cost(cost[0]));
// --------------------------------------------------
// Example for continuous assignment
// assign out_n = XXX;
// --------------------------------------------------
// Example for procedure assignment
// always@(*) begin 
//  out_n = XXX; 
// end
// --------------------------------------------------
// Example for case statement
// always @(*) begin
//  case(op)
//      2'b00: output_reg = a + b;
//      2'b10: output_reg = a - b;
//      2'b01: output_reg = a * b;
//      2'b11: output_reg = a / b;
//      default: output_reg = 0;
//  endcase
// end
// --------------------------------------------------


