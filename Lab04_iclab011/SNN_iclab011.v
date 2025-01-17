//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise     : Siamese Neural Network 
//   Author             : Jia-Yu Lee (maggie8905121@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module SNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
    Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg  out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;
//---------------------------------------------------------------------
//   reg & wire
//---------------------------------------------------------------------
parameter IDLE = 3'd0;
parameter INPUT = 3'd1;
//parameter PAD = 3'd2;
parameter COV = 3'd3;
parameter FUL_C = 3'd4;
parameter OUT = 3'd5;

reg [2:0] curr_state;
reg [2:0] next_state;

reg [inst_sig_width+inst_exp_width:0] imgA_1[0:15], imgA_2[0:15], imgA_3[0:15];
reg [inst_sig_width+inst_exp_width:0] imgB_1[0:15], imgB_2[0:15], imgB_3[0:15];
reg [inst_sig_width+inst_exp_width:0] ker_1[0:8], ker_2[0:8], ker_3[0:8];
reg [inst_sig_width+inst_exp_width:0] weight_in[0:3];
reg [1:0] opt_tmp;

reg [6:0] load_count;

//conv
reg [31:0] mul_a[0:8], mul_ker[0:8];
reg [31:0] sum_a, sum_b, sum_c;
reg [4:0] mul_count;
reg [1:0] ker_count;
reg [6:0] cov_count;
reg cov_done;

wire [31:0] mul_out[0:8];
wire [31:0] add_tmp[0:3];
wire [31:0] sum_out;
//max
reg [31:0] max_pol[0:3];

wire [31:0] compare_tmp[0:1];
reg [31:0] com_a, com_b;
wire [31:0] com_c;
//feature map
reg [31:0] map_A[0:3], map_B[0:3];
reg [31:0] feature_A[0:3], map_tmp[0:3], feature_out[0:1];
reg [31:0] final_map_A[0:3], final_map_B[0:3];
reg [5:0] feature_count;

//normal
wire [31:0] max[0:3], min[0:3];
reg [31:0] L1_vec_A[0:3], L1_vec_B[0:3];
wire [31:0] max_scal_A, min_scal_A, max_scal_B, min_scal_B, mother_scal_A, mother_scal_B;
reg [31:0] normal_in, final_A, final_B;
reg [31:0] max_tmp[0:3], min_tmp[0:3];
wire [31:0] div_in, acti_in,exp_x, exp_nx, add_exp_nx, exp_x_sub_exp_nx, one, zero;
wire [31:0] out_tmp, out_max, out_min, out_tmpA;
reg [31:0] sum4[0:3];
assign one   = 32'b00111111100000000000000000000000;
assign zero  = 32'b00000000000000000000000000000000;

reg out_flag;
reg [31:0] out_last;

integer i,j,k;
//---------------------------------------------------------------------
//   input
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin        
        for(i = 0;i<=15;i=i+1)begin
                imgA_1[i] <= 0;
                imgA_2[i] <= 0;
                imgA_3[i] <= 0;
                imgB_1[i] <= 0;
                imgB_2[i] <= 0;
                imgB_3[i] <= 0; 
        end
    end else if(in_valid == 1 && load_count>=0 && load_count<=15) begin   
            
        imgA_1[15] <= Img;
        for (i = 14; i >= 0; i=i-1) begin
            imgA_1[i] <= imgA_1[i+1];
        end
    end else if(in_valid == 1 && load_count>=16 && load_count<=31) begin   
            
        imgA_2[15] <= Img;
        for (i = 14; i >= 0; i=i-1) begin
            imgA_2[i] <= imgA_2[i+1];
        end
    end else if(in_valid == 1 && load_count>=32 && load_count<=47) begin   
            
        imgA_3[15] <= Img;
        for (i = 14; i >= 0; i=i-1) begin
            imgA_3[i] <= imgA_3[i+1];
        end
    end else if(in_valid == 1 && load_count>=48 && load_count<=63) begin   
            
        imgB_1[15] <= Img;
        for (i = 14; i >= 0; i=i-1) begin
            imgB_1[i] <= imgB_1[i+1];
        end
    end else if(in_valid == 1 && load_count>=64 && load_count<=79) begin   
            
        imgB_2[15] <= Img;
        for (i = 14; i >= 0; i=i-1) begin
            imgB_2[i] <= imgB_2[i+1];
        end
    end else if(in_valid == 1 && load_count>=80 && load_count<=95) begin   
            
        imgB_3[15] <= Img;
        for (i = 14; i >= 0; i=i-1) begin
            imgB_3[i] <= imgB_3[i+1];
        end
    end
    else begin
        for(i = 0;i<=15;i=i+1)begin
                imgA_1[i] <= imgA_1[i];
                imgA_2[i] <= imgA_2[i];
                imgA_3[i] <= imgA_3[i];
                imgB_1[i] <= imgB_1[i];
                imgB_2[i] <= imgB_2[i];
                imgB_3[i] <= imgB_3[i]; 
        end
    end
end
reg [1:0] opt_comb;
always @(*) begin 
    opt_comb = opt_tmp;
    if(in_valid == 1&& load_count==0)begin
        opt_comb = Opt;
    end
    
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin        
        opt_tmp <= 0;
    end
    else opt_tmp <= opt_comb; 
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) load_count <= 'd0;
    else if(in_valid) load_count <= load_count + 'd1;
    else load_count <= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin        
        for(j = 0;j<=8;j=j+1)begin
            ker_1[j] <= 0;
            ker_2[j] <= 0;
            ker_3[j] <= 0;
      
        end
    end else if(in_valid == 1) begin    
        case(load_count)
            0: begin
                ker_1[0] <= Kernel;
            end
            1: begin
                ker_1[1] <= Kernel;
            end
            2: begin
                ker_1[2] <= Kernel;
            end
            3: begin
                ker_1[3] <= Kernel;
            end
            4: begin
                ker_1[4] <= Kernel;
            end
            5: begin
                ker_1[5] <= Kernel;
            end
            6: begin
                ker_1[6] <= Kernel;
            end
            7: begin
                ker_1[7] <= Kernel;
            end
            8: begin
                ker_1[8] <= Kernel;
            end
            9: begin
                ker_2[0] <= Kernel;
            end
            10: begin
                ker_2[1] <= Kernel;
            end
            11: begin
                ker_2[2] <= Kernel;
            end
            12: begin
                ker_2[3] <= Kernel;
            end
            13: begin
                ker_2[4] <= Kernel;
            end
            14: begin
                ker_2[5] <= Kernel;
            end
            15: begin
                ker_2[6] <= Kernel;
            end
            16: begin
                ker_2[7] <= Kernel;
            end
            17: begin
                ker_2[8] <= Kernel;
            end
            18: begin
                ker_3[0] <= Kernel;
            end
            19: begin
                ker_3[1] <= Kernel;
            end
            20: begin
                ker_3[2] <= Kernel;
            end
            21: begin
                ker_3[3] <= Kernel;
            end
            22: begin
                ker_3[4] <= Kernel;
            end
            23: begin
                ker_3[5] <= Kernel;
            end
            24: begin
                ker_3[6] <= Kernel;
            end
            25: begin
                ker_3[7] <= Kernel;
            end
            26: begin
                ker_3[8] <= Kernel;
            end
            
        endcase

    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin        
        for(k = 0;k<=3;k=k+1)begin
            weight_in[k] <= 0;
      
        end
    end else if(in_valid == 1) begin       
        case(load_count)
            0: begin
                weight_in[0] <= Weight;
            end
            1: begin
                weight_in[1] <= Weight;
            end
            2: begin
                weight_in[2] <= Weight;
            end
            3: begin
                weight_in[3] <= Weight;
            end
            
        endcase
    end

end

//---------------------------------------------------------------------
//   padding
//---------------------------------------------------------------------
/*always @(posedge clk or negedge rst_n) begin
    if(!rst_n) pad_cnt <= 'd0;
    else if(curr_state == PAD) pad_cnt <= pad_cnt + 'd1;
    else pad_cnt <= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) pad_done <= 0;
    else if(pad_cnt == 3) pad_done <= 1;
    else pad_done <=0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(i = 0;i<=35;i=i+1) begin
            imgA_1_pad[i] <= 0;
            imgA_2_pad[i] <= 0;
            imgA_3_pad[i] <= 0;
            imgB_1_pad[i] <= 0;
            imgB_2_pad[i] <= 0;
            imgB_3_pad[i] <= 0;
        end
    end
    else if(curr_state == PAD && opt_tmp[0] == 0) begin //Rerlication padding
        imgA_1_pad[7:10] <= imgA_1[0:3];
        imgA_1_pad[13:16] <= imgA_1[4:7];
        imgA_1_pad[19:22] <= imgA_1[8:11];
        imgA_1_pad[25:28] <= imgA_1[12:15];
        imgA_2_pad[7:10] <= imgA_2[0:3];
        imgA_2_pad[13:16] <= imgA_2[4:7];
        imgA_2_pad[19:22] <= imgA_2[8:11];
        imgA_2_pad[25:28] <= imgA_2[12:15];
        imgA_3_pad[7:10] <= imgA_3[0:3];
        imgA_3_pad[13:16] <= imgA_3[4:7];
        imgA_3_pad[19:22] <= imgA_3[8:11];
        imgA_3_pad[25:28] <= imgA_3[12:15];
        imgB_1_pad[7:10] <= imgB_1[0:3];
        imgB_1_pad[13:16] <= imgB_1[4:7];
        imgB_1_pad[19:22] <= imgB_1[8:11];
        imgB_1_pad[25:28] <= imgB_1[12:15];
        imgB_2_pad[7:10] <= imgB_2[0:3];
        imgB_2_pad[13:16] <= imgB_2[4:7];
        imgB_2_pad[19:22] <= imgB_2[8:11];
        imgB_2_pad[25:28] <= imgB_2[12:15];
        imgB_3_pad[7:10] <= imgB_3[0:3];
        imgB_3_pad[13:16] <= imgB_3[4:7];
        imgB_3_pad[19:22] <= imgB_3[8:11];
        imgB_3_pad[25:28] <= imgB_3[12:15];



        imgA_1_pad[0:5] <= imgA_1_pad[6:11];
        imgA_1_pad[30:35] <= imgA_1_pad[24:29];
        imgA_2_pad[0:5] <= imgA_2_pad[6:11];
        imgA_2_pad[30:35] <= imgA_2_pad[24:29];
        imgA_3_pad[0:5] <= imgA_3_pad[6:11];
        imgA_3_pad[30:35] <= imgA_3_pad[24:29];
        imgB_1_pad[0:5] <= imgB_1_pad[6:11];
        imgB_1_pad[30:35] <= imgB_1_pad[24:29];
        imgB_2_pad[0:5] <= imgB_2_pad[6:11];
        imgB_2_pad[30:35] <= imgB_2_pad[24:29];
        imgB_3_pad[0:5] <= imgB_3_pad[6:11];
        imgB_3_pad[30:35] <= imgB_3_pad[24:29];
        for(i=0;i<=35;i=i+1) begin
            if(i==0 || i==6 || i==12 || i==18 || i==24 || i==30) begin
                imgA_1_pad[i] <= imgA_1_pad[i+1];
                imgA_2_pad[i] <= imgA_2_pad[i+1];
                imgA_3_pad[i] <= imgA_3_pad[i+1];
                imgB_1_pad[i] <= imgB_1_pad[i+1];
                imgB_2_pad[i] <= imgB_2_pad[i+1];
                imgB_3_pad[i] <= imgB_3_pad[i+1];
            end
            else if(i==5 || i==11 || i==17 || i==23 || i==29 || i==35)begin
                imgA_1_pad[i] <= imgA_1_pad[i-1];
                imgA_2_pad[i] <= imgA_2_pad[i-1];
                imgA_3_pad[i] <= imgA_3_pad[i-1];
                imgB_1_pad[i] <= imgB_1_pad[i-1];
                imgB_2_pad[i] <= imgB_2_pad[i-1];
                imgB_3_pad[i] <= imgB_3_pad[i-1];
                
            end
        end

    end
    else if(curr_state == PAD && opt_tmp[0] == 1) begin //zero padding
        for(i=0;i<=35;i=i+1)begin
            imgA_1_pad[i] <= 0;
            imgA_2_pad[i] <= 0;
            imgA_3_pad[i] <= 0;
            imgB_1_pad[i] <= 0;
            imgB_2_pad[i] <= 0;
            imgB_3_pad[i] <= 0;
        end
        imgA_1_pad[7:10] <= imgA_1[0:3];
        imgA_1_pad[13:16] <= imgA_1[4:7];
        imgA_1_pad[19:22] <= imgA_1[8:11];
        imgA_1_pad[25:28] <= imgA_1[12:15];
        imgA_2_pad[7:10] <= imgA_2[0:3];
        imgA_2_pad[13:16] <= imgA_2[4:7];
        imgA_2_pad[19:22] <= imgA_2[8:11];
        imgA_2_pad[25:28] <= imgA_2[12:15];
        imgA_3_pad[7:10] <= imgA_3[0:3];
        imgA_3_pad[13:16] <= imgA_3[4:7];
        imgA_3_pad[19:22] <= imgA_3[8:11];
        imgA_3_pad[25:28] <= imgA_3[12:15];
        imgB_1_pad[7:10] <= imgB_1[0:3];
        imgB_1_pad[13:16] <= imgB_1[4:7];
        imgB_1_pad[19:22] <= imgB_1[8:11];
        imgB_1_pad[25:28] <= imgB_1[12:15];
        imgB_2_pad[7:10] <= imgB_2[0:3];
        imgB_2_pad[13:16] <= imgB_2[4:7];
        imgB_2_pad[19:22] <= imgB_2[8:11];
        imgB_2_pad[25:28] <= imgB_2[12:15];
        imgB_3_pad[7:10] <= imgB_3[0:3];
        imgB_3_pad[13:16] <= imgB_3[4:7];
        imgB_3_pad[19:22] <= imgB_3[8:11];
        imgB_3_pad[25:28] <= imgB_3[12:15];
    

    end
end*/

//---------------------------------------------------------------------
//   cov
//---------------------------------------------------------------------

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M0 (.a(mul_a[0]), .b(mul_ker[0]), .rnd(3'b000), .z(mul_out[0]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a(mul_a[1]), .b(mul_ker[1]), .rnd(3'b000), .z(mul_out[1]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2 (.a(mul_a[2]), .b(mul_ker[2]), .rnd(3'b000), .z(mul_out[2]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M3 (.a(mul_a[3]), .b(mul_ker[3]), .rnd(3'b000), .z(mul_out[3]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M4 (.a(mul_a[4]), .b(mul_ker[4]), .rnd(3'b000), .z(mul_out[4]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M5 (.a(mul_a[5]), .b(mul_ker[5]), .rnd(3'b000), .z(mul_out[5]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M6 (.a(mul_a[6]), .b(mul_ker[6]), .rnd(3'b000), .z(mul_out[6]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M7 (.a(mul_a[7]), .b(mul_ker[7]), .rnd(3'b000), .z(mul_out[7]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M8 (.a(mul_a[8]), .b(mul_ker[8]), .rnd(3'b000), .z(mul_out[8]));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S1 (.a(mul_out[0]), .b(mul_out[1]), .c(mul_out[2]), .z(add_tmp[0]), .rnd(3'b000));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S2 (.a(mul_out[3]), .b(mul_out[4]), .c(mul_out[5]), .z(add_tmp[1]), .rnd(3'b000));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S3 (.a(mul_out[6]), .b(mul_out[7]), .c(mul_out[8]), .z(add_tmp[2]), .rnd(3'b000));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S4 (.a( add_tmp[0]), .b( add_tmp[1]), .c( add_tmp[2]), .z(add_tmp[3]), .rnd(3'b000));

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S5 (.a(sum_a), .b(sum_b), .c(sum_c), .z(sum_out), .rnd(3'b000));



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cov_count <= 'd0;
    else if(curr_state == COV) begin
        cov_count <= cov_count + 'd1;
    end
    else cov_count <= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cov_done <= 'd0;
    else if(cov_count == 100) begin
        cov_done <= 1;
    end
    else cov_done <= 'd0;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) mul_count <= 'd0;
    else if(curr_state == COV) begin
        if(ker_count == 'd2)begin
            if(mul_count == 'd31) mul_count <= 'd0;
            else mul_count <= mul_count + 'd1;
        end
        else mul_count <= mul_count;
    end
    else mul_count <= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) ker_count <= 'd0;
    else if(curr_state == COV) begin
        ker_count <= (ker_count == 2)? 'd0 : ker_count+ 'd1;
    end
    else ker_count <= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        mul_a[0] <= 0;
        mul_a[1] <= 0;
        mul_a[2] <= 0;
        mul_a[3] <= 0;
        mul_a[4] <= 0;
        mul_a[5] <= 0;
        mul_a[6] <= 0;
        mul_a[7] <= 0;
        mul_a[8] <= 0;
    end
    else if(curr_state == COV) begin
        case (mul_count)

            0:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_1[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_1[0];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_1[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_1[0];
                    mul_a[4] <= imgA_1[0];
                    mul_a[5] <= imgA_1[1];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_1[4];
                    mul_a[7] <= imgA_1[4];
                    mul_a[8] <= imgA_1[5];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_2[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_2[0];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_2[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_2[0];
                    mul_a[4] <= imgA_2[0];
                    mul_a[5] <= imgA_2[1];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_2[4];
                    mul_a[7] <= imgA_2[4];
                    mul_a[8] <= imgA_2[5];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_3[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_3[0];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_3[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_3[0];
                    mul_a[4] <= imgA_3[0];
                    mul_a[5] <= imgA_3[1];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_3[4];
                    mul_a[7] <= imgA_3[4];
                    mul_a[8] <= imgA_3[5];
                end
            end 
            1: begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_1[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_1[1];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_1[2];
                    mul_a[3] <= imgA_1[0];
                    mul_a[4] <= imgA_1[1];
                    mul_a[5] <= imgA_1[2];
                    mul_a[6] <= imgA_1[4];
                    mul_a[7] <= imgA_1[5];
                    mul_a[8] <= imgA_1[6];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_2[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_2[1];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_2[2];
                    mul_a[3] <= imgA_2[0];
                    mul_a[4] <= imgA_2[1];
                    mul_a[5] <= imgA_2[2];
                    mul_a[6] <= imgA_2[4];
                    mul_a[7] <= imgA_2[5];
                    mul_a[8] <= imgA_2[6];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_3[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_3[1];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_3[2];
                    mul_a[3] <= imgA_3[0];
                    mul_a[4] <= imgA_3[1];
                    mul_a[5] <= imgA_3[2];
                    mul_a[6] <= imgA_3[4];
                    mul_a[7] <= imgA_3[5];
                    mul_a[8] <= imgA_3[6];
                end
            end
            4: begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_1[1];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_1[2];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_1[3];
                    mul_a[3] <= imgA_1[1];
                    mul_a[4] <= imgA_1[2];
                    mul_a[5] <= imgA_1[3];
                    mul_a[6] <= imgA_1[5];
                    mul_a[7] <= imgA_1[6];
                    mul_a[8] <= imgA_1[7];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_2[1];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_2[2];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_2[3];
                    mul_a[3] <= imgA_2[1];
                    mul_a[4] <= imgA_2[2];
                    mul_a[5] <= imgA_2[3];
                    mul_a[6] <= imgA_2[5];
                    mul_a[7] <= imgA_2[6];
                    mul_a[8] <= imgA_2[7];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_3[1];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_3[2];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_3[3];
                    mul_a[3] <= imgA_3[1];
                    mul_a[4] <= imgA_3[2];
                    mul_a[5] <= imgA_3[3];
                    mul_a[6] <= imgA_3[5];
                    mul_a[7] <= imgA_3[6];
                    mul_a[8] <= imgA_3[7];
                end
                
            end
            5: begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_1[2];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_1[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_1[3];
                    mul_a[3] <= imgA_1[2];
                    mul_a[4] <= imgA_1[3];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_1[3];
                    mul_a[6] <= imgA_1[6];
                    mul_a[7] <= imgA_1[7];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_1[7];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_2[2];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_2[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_2[3];
                    mul_a[3] <= imgA_2[2];
                    mul_a[4] <= imgA_2[3];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_2[3];
                    mul_a[6] <= imgA_2[6];
                    mul_a[7] <= imgA_2[7];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_2[7];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_3[2];
                    mul_a[1] <= (opt_tmp[0])? zero: imgA_3[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_3[3];
                    mul_a[3] <= imgA_3[2];
                    mul_a[4] <= imgA_3[3];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_3[3];
                    mul_a[6] <= imgA_3[6];
                    mul_a[7] <= imgA_3[7];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_3[7];
                end
                
            end
            2:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_1[0];
                    mul_a[1] <= imgA_1[0];
                    mul_a[2] <= imgA_1[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_1[4];
                    mul_a[4] <= imgA_1[4];
                    mul_a[5] <= imgA_1[5];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_1[8];
                    mul_a[7] <= imgA_1[8];
                    mul_a[8] <= imgA_1[9];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_2[0];
                    mul_a[1] <= imgA_2[0];
                    mul_a[2] <= imgA_2[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_2[4];
                    mul_a[4] <= imgA_2[4];
                    mul_a[5] <= imgA_2[5];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_2[8];
                    mul_a[7] <= imgA_2[8];
                    mul_a[8] <= imgA_2[9];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_3[0];
                    mul_a[1] <= imgA_3[0];
                    mul_a[2] <= imgA_3[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_3[4];
                    mul_a[4] <= imgA_3[4];
                    mul_a[5] <= imgA_3[5];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_3[8];
                    mul_a[7] <= imgA_3[8];
                    mul_a[8] <= imgA_3[9];
                end
                
            end
            3:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgA_1[0];
                    mul_a[1] <= imgA_1[1];
                    mul_a[2] <= imgA_1[2];
                    mul_a[3] <= imgA_1[4];
                    mul_a[4] <= imgA_1[5];
                    mul_a[5] <= imgA_1[6];
                    mul_a[6] <= imgA_1[8];
                    mul_a[7] <= imgA_1[9];
                    mul_a[8] <= imgA_1[10];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgA_2[0];
                    mul_a[1] <= imgA_2[1];
                    mul_a[2] <= imgA_2[2];
                    mul_a[3] <= imgA_2[4];
                    mul_a[4] <= imgA_2[5];
                    mul_a[5] <= imgA_2[6];
                    mul_a[6] <= imgA_2[8];
                    mul_a[7] <= imgA_2[9];
                    mul_a[8] <= imgA_2[10];
                end
                else begin
                    mul_a[0] <= imgA_3[0];
                    mul_a[1] <= imgA_3[1];
                    mul_a[2] <= imgA_3[2];
                    mul_a[3] <= imgA_3[4];
                    mul_a[4] <= imgA_3[5];
                    mul_a[5] <= imgA_3[6];
                    mul_a[6] <= imgA_3[8];
                    mul_a[7] <= imgA_3[9];
                    mul_a[8] <= imgA_3[10];
                end
            end
            6:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgA_1[1];
                    mul_a[1] <= imgA_1[2];
                    mul_a[2] <= imgA_1[3];
                    mul_a[3] <= imgA_1[5];
                    mul_a[4] <= imgA_1[6];
                    mul_a[5] <= imgA_1[7];
                    mul_a[6] <= imgA_1[9];
                    mul_a[7] <= imgA_1[10];
                    mul_a[8] <= imgA_1[11];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgA_2[1];
                    mul_a[1] <= imgA_2[2];
                    mul_a[2] <= imgA_2[3];
                    mul_a[3] <= imgA_2[5];
                    mul_a[4] <= imgA_2[6];
                    mul_a[5] <= imgA_2[7];
                    mul_a[6] <= imgA_2[9];
                    mul_a[7] <= imgA_2[10];
                    mul_a[8] <= imgA_2[11];  
                end
                else begin
                    mul_a[0] <= imgA_3[1];
                    mul_a[1] <= imgA_3[2];
                    mul_a[2] <= imgA_3[3];
                    mul_a[3] <= imgA_3[5];
                    mul_a[4] <= imgA_3[6];
                    mul_a[5] <= imgA_3[7];
                    mul_a[6] <= imgA_3[9];
                    mul_a[7] <= imgA_3[10];
                    mul_a[8] <= imgA_3[11];  
                end
                
            end
            7:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgA_1[2];
                    mul_a[1] <= imgA_1[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_1[3];
                    mul_a[3] <= imgA_1[6];
                    mul_a[4] <= imgA_1[7];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_1[7];
                    mul_a[6] <= imgA_1[10];
                    mul_a[7] <= imgA_1[11];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_1[11];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgA_2[2];
                    mul_a[1] <= imgA_2[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_2[3];
                    mul_a[3] <= imgA_2[6];
                    mul_a[4] <= imgA_2[7];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_2[7];
                    mul_a[6] <= imgA_2[10];
                    mul_a[7] <= imgA_2[11];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_2[11];    
                end
                else begin
                    mul_a[0] <= imgA_3[2];
                    mul_a[1] <= imgA_3[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_3[3];
                    mul_a[3] <= imgA_3[6];
                    mul_a[4] <= imgA_3[7];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_3[7];
                    mul_a[6] <= imgA_3[10];
                    mul_a[7] <= imgA_3[11];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_3[11];    
                end
                
            end
            8:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_1[4];
                    mul_a[1] <= imgA_1[4];
                    mul_a[2] <= imgA_1[5];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_1[8];
                    mul_a[4] <= imgA_1[8];
                    mul_a[5] <= imgA_1[9];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_1[12];
                    mul_a[7] <= imgA_1[12];
                    mul_a[8] <= imgA_1[13];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_2[4];
                    mul_a[1] <= imgA_2[4];
                    mul_a[2] <= imgA_2[5];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_2[8];
                    mul_a[4] <= imgA_2[8];
                    mul_a[5] <= imgA_2[9];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_2[12];
                    mul_a[7] <= imgA_2[12];
                    mul_a[8] <= imgA_2[13];  
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_3[4];
                    mul_a[1] <= imgA_3[4];
                    mul_a[2] <= imgA_3[5];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_3[8];
                    mul_a[4] <= imgA_3[8];
                    mul_a[5] <= imgA_3[9];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_3[12];
                    mul_a[7] <= imgA_3[12];
                    mul_a[8] <= imgA_3[13];  
                end
                
            end
            9:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgA_1[4];
                    mul_a[1] <= imgA_1[5];
                    mul_a[2] <= imgA_1[6];
                    mul_a[3] <= imgA_1[8];
                    mul_a[4] <= imgA_1[9];
                    mul_a[5] <= imgA_1[10];
                    mul_a[6] <= imgA_1[12];
                    mul_a[7] <= imgA_1[13];
                    mul_a[8] <= imgA_1[14];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgA_2[4];
                    mul_a[1] <= imgA_2[5];
                    mul_a[2] <= imgA_2[6];
                    mul_a[3] <= imgA_2[8];
                    mul_a[4] <= imgA_2[9];
                    mul_a[5] <= imgA_2[10];
                    mul_a[6] <= imgA_2[12];
                    mul_a[7] <= imgA_2[13];
                    mul_a[8] <= imgA_2[14];  
                end
                else begin
                    mul_a[0] <= imgA_3[4];
                    mul_a[1] <= imgA_3[5];
                    mul_a[2] <= imgA_3[6];
                    mul_a[3] <= imgA_3[8];
                    mul_a[4] <= imgA_3[9];
                    mul_a[5] <= imgA_3[10];
                    mul_a[6] <= imgA_3[12];
                    mul_a[7] <= imgA_3[13];
                    mul_a[8] <= imgA_3[14];  
                end
            end
            12:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgA_1[5];
                    mul_a[1] <= imgA_1[6];
                    mul_a[2] <= imgA_1[7];
                    mul_a[3] <= imgA_1[9];
                    mul_a[4] <= imgA_1[10];
                    mul_a[5] <= imgA_1[11];
                    mul_a[6] <= imgA_1[13];
                    mul_a[7] <= imgA_1[14];
                    mul_a[8] <= imgA_1[15];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgA_2[5];
                    mul_a[1] <= imgA_2[6];
                    mul_a[2] <= imgA_2[7];
                    mul_a[3] <= imgA_2[9];
                    mul_a[4] <= imgA_2[10];
                    mul_a[5] <= imgA_2[11];
                    mul_a[6] <= imgA_2[13];
                    mul_a[7] <= imgA_2[14];
                    mul_a[8] <= imgA_2[15];  
                end
                else begin
                    mul_a[0] <= imgA_3[5];
                    mul_a[1] <= imgA_3[6];
                    mul_a[2] <= imgA_3[7];
                    mul_a[3] <= imgA_3[9];
                    mul_a[4] <= imgA_3[10];
                    mul_a[5] <= imgA_3[11];
                    mul_a[6] <= imgA_3[13];
                    mul_a[7] <= imgA_3[14];
                    mul_a[8] <= imgA_3[15];  
                end
                
            end
            13:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgA_1[6];
                    mul_a[1] <= imgA_1[7];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_1[7];
                    mul_a[3] <= imgA_1[10];
                    mul_a[4] <= imgA_1[11];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_1[11];
                    mul_a[6] <= imgA_1[14];
                    mul_a[7] <= imgA_1[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_1[15];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgA_2[6];
                    mul_a[1] <= imgA_2[7];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_2[7];
                    mul_a[3] <= imgA_2[10];
                    mul_a[4] <= imgA_2[11];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_2[11];
                    mul_a[6] <= imgA_2[14];
                    mul_a[7] <= imgA_2[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_2[15];    
                end
                else begin
                    mul_a[0] <= imgA_3[6];
                    mul_a[1] <= imgA_3[7];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_3[7];
                    mul_a[3] <= imgA_3[10];
                    mul_a[4] <= imgA_3[11];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_3[11];
                    mul_a[6] <= imgA_3[14];
                    mul_a[7] <= imgA_3[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_3[15];    
                end
                
            end
            10:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_1[8];
                    mul_a[1] <= imgA_1[8];
                    mul_a[2] <= imgA_1[9];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_1[12];
                    mul_a[4] <= imgA_1[12];
                    mul_a[5] <= imgA_1[13];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_1[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_1[12];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_1[13];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_2[8];
                    mul_a[1] <= imgA_2[8];
                    mul_a[2] <= imgA_2[9];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_2[12];
                    mul_a[4] <= imgA_2[12];
                    mul_a[5] <= imgA_2[13];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_2[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_2[12];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_2[13];    
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgA_3[8];
                    mul_a[1] <= imgA_3[8];
                    mul_a[2] <= imgA_3[9];
                    mul_a[3] <= (opt_tmp[0])? zero: imgA_3[12];
                    mul_a[4] <= imgA_3[12];
                    mul_a[5] <= imgA_3[13];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_3[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_3[12];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_3[13];    
                end
                
            end
            11:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgA_1[8];
                    mul_a[1] <= imgA_1[9];
                    mul_a[2] <= imgA_1[10];
                    mul_a[3] <= imgA_1[12];
                    mul_a[4] <= imgA_1[13];
                    mul_a[5] <= imgA_1[14];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_1[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_1[13];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_1[14];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgA_2[8];
                    mul_a[1] <= imgA_2[9];
                    mul_a[2] <= imgA_2[10];
                    mul_a[3] <= imgA_2[12];
                    mul_a[4] <= imgA_2[13];
                    mul_a[5] <= imgA_2[14];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_2[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_2[13];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_2[14];    
                end
                else begin
                    mul_a[0] <= imgA_3[8];
                    mul_a[1] <= imgA_3[9];
                    mul_a[2] <= imgA_3[10];
                    mul_a[3] <= imgA_3[12];
                    mul_a[4] <= imgA_3[13];
                    mul_a[5] <= imgA_3[14];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_3[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_3[13];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_3[14];    
                end
                
            end
            14:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgA_1[9];
                    mul_a[1] <= imgA_1[10];
                    mul_a[2] <= imgA_1[11];
                    mul_a[3] <= imgA_1[13];
                    mul_a[4] <= imgA_1[14];
                    mul_a[5] <= imgA_1[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_1[13];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_1[14];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_1[15];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgA_2[9];
                    mul_a[1] <= imgA_2[10];
                    mul_a[2] <= imgA_2[11];
                    mul_a[3] <= imgA_2[13];
                    mul_a[4] <= imgA_2[14];
                    mul_a[5] <= imgA_2[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_2[13];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_2[14];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_2[15];    
                end
                else begin
                    mul_a[0] <= imgA_3[9];
                    mul_a[1] <= imgA_3[10];
                    mul_a[2] <= imgA_3[11];
                    mul_a[3] <= imgA_3[13];
                    mul_a[4] <= imgA_3[14];
                    mul_a[5] <= imgA_3[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_3[13];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_3[14];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_3[15];    
                end
                
            end
            15:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgA_1[10];
                    mul_a[1] <= imgA_1[11];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_1[11];
                    mul_a[3] <= imgA_1[14];
                    mul_a[4] <= imgA_1[15];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_1[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_1[14];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_1[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_1[15];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgA_2[10];
                    mul_a[1] <= imgA_2[11];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_2[11];
                    mul_a[3] <= imgA_2[14];
                    mul_a[4] <= imgA_2[15];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_2[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_2[14];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_2[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_2[15];    
                end
                else begin
                    mul_a[0] <= imgA_3[10];
                    mul_a[1] <= imgA_3[11];
                    mul_a[2] <= (opt_tmp[0])? zero: imgA_3[11];
                    mul_a[3] <= imgA_3[14];
                    mul_a[4] <= imgA_3[15];
                    mul_a[5] <= (opt_tmp[0])? zero: imgA_3[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgA_3[14];
                    mul_a[7] <= (opt_tmp[0])? zero: imgA_3[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgA_3[15];    
                end
                
            end
            16:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_1[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_1[0];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_1[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_1[0];
                    mul_a[4] <= imgB_1[0];
                    mul_a[5] <= imgB_1[1];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_1[4];
                    mul_a[7] <= imgB_1[4];
                    mul_a[8] <= imgB_1[5];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_2[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_2[0];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_2[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_2[0];
                    mul_a[4] <= imgB_2[0];
                    mul_a[5] <= imgB_2[1];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_2[4];
                    mul_a[7] <= imgB_2[4];
                    mul_a[8] <= imgB_2[5];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_3[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_3[0];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_3[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_3[0];
                    mul_a[4] <= imgB_3[0];
                    mul_a[5] <= imgB_3[1];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_3[4];
                    mul_a[7] <= imgB_3[4];
                    mul_a[8] <= imgB_3[5];
                end
            end 
            17: begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_1[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_1[1];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_1[2];
                    mul_a[3] <= imgB_1[0];
                    mul_a[4] <= imgB_1[1];
                    mul_a[5] <= imgB_1[2];
                    mul_a[6] <= imgB_1[4];
                    mul_a[7] <= imgB_1[5];
                    mul_a[8] <= imgB_1[6];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_2[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_2[1];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_2[2];
                    mul_a[3] <= imgB_2[0];
                    mul_a[4] <= imgB_2[1];
                    mul_a[5] <= imgB_2[2];
                    mul_a[6] <= imgB_2[4];
                    mul_a[7] <= imgB_2[5];
                    mul_a[8] <= imgB_2[6];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_3[0];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_3[1];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_3[2];
                    mul_a[3] <= imgB_3[0];
                    mul_a[4] <= imgB_3[1];
                    mul_a[5] <= imgB_3[2];
                    mul_a[6] <= imgB_3[4];
                    mul_a[7] <= imgB_3[5];
                    mul_a[8] <= imgB_3[6];
                end
            end
            20: begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_1[1];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_1[2];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_1[3];
                    mul_a[3] <= imgB_1[1];
                    mul_a[4] <= imgB_1[2];
                    mul_a[5] <= imgB_1[3];
                    mul_a[6] <= imgB_1[5];
                    mul_a[7] <= imgB_1[6];
                    mul_a[8] <= imgB_1[7];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_2[1];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_2[2];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_2[3];
                    mul_a[3] <= imgB_2[1];
                    mul_a[4] <= imgB_2[2];
                    mul_a[5] <= imgB_2[3];
                    mul_a[6] <= imgB_2[5];
                    mul_a[7] <= imgB_2[6];
                    mul_a[8] <= imgB_2[7];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_3[1];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_3[2];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_3[3];
                    mul_a[3] <= imgB_3[1];
                    mul_a[4] <= imgB_3[2];
                    mul_a[5] <= imgB_3[3];
                    mul_a[6] <= imgB_3[5];
                    mul_a[7] <= imgB_3[6];
                    mul_a[8] <= imgB_3[7];
                end
                
            end
            21: begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_1[2];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_1[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_1[3];
                    mul_a[3] <= imgB_1[2];
                    mul_a[4] <= imgB_1[3];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_1[3];
                    mul_a[6] <= imgB_1[6];
                    mul_a[7] <= imgB_1[7];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_1[7];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_2[2];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_2[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_2[3];
                    mul_a[3] <= imgB_2[2];
                    mul_a[4] <= imgB_2[3];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_2[3];
                    mul_a[6] <= imgB_2[6];
                    mul_a[7] <= imgB_2[7];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_2[7];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_3[2];
                    mul_a[1] <= (opt_tmp[0])? zero: imgB_3[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_3[3];
                    mul_a[3] <= imgB_3[2];
                    mul_a[4] <= imgB_3[3];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_3[3];
                    mul_a[6] <= imgB_3[6];
                    mul_a[7] <= imgB_3[7];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_3[7];
                end
                
            end
            18:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_1[0];
                    mul_a[1] <= imgB_1[0];
                    mul_a[2] <= imgB_1[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_1[4];
                    mul_a[4] <= imgB_1[4];
                    mul_a[5] <= imgB_1[5];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_1[8];
                    mul_a[7] <= imgB_1[8];
                    mul_a[8] <= imgB_1[9];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_2[0];
                    mul_a[1] <= imgB_2[0];
                    mul_a[2] <= imgB_2[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_2[4];
                    mul_a[4] <= imgB_2[4];
                    mul_a[5] <= imgB_2[5];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_2[8];
                    mul_a[7] <= imgB_2[8];
                    mul_a[8] <= imgB_2[9];
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_3[0];
                    mul_a[1] <= imgB_3[0];
                    mul_a[2] <= imgB_3[1];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_3[4];
                    mul_a[4] <= imgB_3[4];
                    mul_a[5] <= imgB_3[5];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_3[8];
                    mul_a[7] <= imgB_3[8];
                    mul_a[8] <= imgB_3[9];
                end
                
            end
            19:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgB_1[0];
                    mul_a[1] <= imgB_1[1];
                    mul_a[2] <= imgB_1[2];
                    mul_a[3] <= imgB_1[4];
                    mul_a[4] <= imgB_1[5];
                    mul_a[5] <= imgB_1[6];
                    mul_a[6] <= imgB_1[8];
                    mul_a[7] <= imgB_1[9];
                    mul_a[8] <= imgB_1[10];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgB_2[0];
                    mul_a[1] <= imgB_2[1];
                    mul_a[2] <= imgB_2[2];
                    mul_a[3] <= imgB_2[4];
                    mul_a[4] <= imgB_2[5];
                    mul_a[5] <= imgB_2[6];
                    mul_a[6] <= imgB_2[8];
                    mul_a[7] <= imgB_2[9];
                    mul_a[8] <= imgB_2[10];
                end
                else begin
                    mul_a[0] <= imgB_3[0];
                    mul_a[1] <= imgB_3[1];
                    mul_a[2] <= imgB_3[2];
                    mul_a[3] <= imgB_3[4];
                    mul_a[4] <= imgB_3[5];
                    mul_a[5] <= imgB_3[6];
                    mul_a[6] <= imgB_3[8];
                    mul_a[7] <= imgB_3[9];
                    mul_a[8] <= imgB_3[10];
                end
            end
            22:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgB_1[1];
                    mul_a[1] <= imgB_1[2];
                    mul_a[2] <= imgB_1[3];
                    mul_a[3] <= imgB_1[5];
                    mul_a[4] <= imgB_1[6];
                    mul_a[5] <= imgB_1[7];
                    mul_a[6] <= imgB_1[9];
                    mul_a[7] <= imgB_1[10];
                    mul_a[8] <= imgB_1[11];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgB_2[1];
                    mul_a[1] <= imgB_2[2];
                    mul_a[2] <= imgB_2[3];
                    mul_a[3] <= imgB_2[5];
                    mul_a[4] <= imgB_2[6];
                    mul_a[5] <= imgB_2[7];
                    mul_a[6] <= imgB_2[9];
                    mul_a[7] <= imgB_2[10];
                    mul_a[8] <= imgB_2[11];  
                end
                else begin
                    mul_a[0] <= imgB_3[1];
                    mul_a[1] <= imgB_3[2];
                    mul_a[2] <= imgB_3[3];
                    mul_a[3] <= imgB_3[5];
                    mul_a[4] <= imgB_3[6];
                    mul_a[5] <= imgB_3[7];
                    mul_a[6] <= imgB_3[9];
                    mul_a[7] <= imgB_3[10];
                    mul_a[8] <= imgB_3[11];  
                end
                
            end
            23:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgB_1[2];
                    mul_a[1] <= imgB_1[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_1[3];
                    mul_a[3] <= imgB_1[6];
                    mul_a[4] <= imgB_1[7];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_1[7];
                    mul_a[6] <= imgB_1[10];
                    mul_a[7] <= imgB_1[11];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_1[11];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgB_2[2];
                    mul_a[1] <= imgB_2[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_2[3];
                    mul_a[3] <= imgB_2[6];
                    mul_a[4] <= imgB_2[7];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_2[7];
                    mul_a[6] <= imgB_2[10];
                    mul_a[7] <= imgB_2[11];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_2[11];    
                end
                else begin
                    mul_a[0] <= imgB_3[2];
                    mul_a[1] <= imgB_3[3];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_3[3];
                    mul_a[3] <= imgB_3[6];
                    mul_a[4] <= imgB_3[7];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_3[7];
                    mul_a[6] <= imgB_3[10];
                    mul_a[7] <= imgB_3[11];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_3[11];    
                end
                
            end
            24:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_1[4];
                    mul_a[1] <= imgB_1[4];
                    mul_a[2] <= imgB_1[5];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_1[8];
                    mul_a[4] <= imgB_1[8];
                    mul_a[5] <= imgB_1[9];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_1[12];
                    mul_a[7] <= imgB_1[12];
                    mul_a[8] <= imgB_1[13];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_2[4];
                    mul_a[1] <= imgB_2[4];
                    mul_a[2] <= imgB_2[5];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_2[8];
                    mul_a[4] <= imgB_2[8];
                    mul_a[5] <= imgB_2[9];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_2[12];
                    mul_a[7] <= imgB_2[12];
                    mul_a[8] <= imgB_2[13];  
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_3[4];
                    mul_a[1] <= imgB_3[4];
                    mul_a[2] <= imgB_3[5];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_3[8];
                    mul_a[4] <= imgB_3[8];
                    mul_a[5] <= imgB_3[9];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_3[12];
                    mul_a[7] <= imgB_3[12];
                    mul_a[8] <= imgB_3[13];  
                end
                
            end
            25:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgB_1[4];
                    mul_a[1] <= imgB_1[5];
                    mul_a[2] <= imgB_1[6];
                    mul_a[3] <= imgB_1[8];
                    mul_a[4] <= imgB_1[9];
                    mul_a[5] <= imgB_1[10];
                    mul_a[6] <= imgB_1[12];
                    mul_a[7] <= imgB_1[13];
                    mul_a[8] <= imgB_1[14];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgB_2[4];
                    mul_a[1] <= imgB_2[5];
                    mul_a[2] <= imgB_2[6];
                    mul_a[3] <= imgB_2[8];
                    mul_a[4] <= imgB_2[9];
                    mul_a[5] <= imgB_2[10];
                    mul_a[6] <= imgB_2[12];
                    mul_a[7] <= imgB_2[13];
                    mul_a[8] <= imgB_2[14];  
                end
                else begin
                    mul_a[0] <= imgB_3[4];
                    mul_a[1] <= imgB_3[5];
                    mul_a[2] <= imgB_3[6];
                    mul_a[3] <= imgB_3[8];
                    mul_a[4] <= imgB_3[9];
                    mul_a[5] <= imgB_3[10];
                    mul_a[6] <= imgB_3[12];
                    mul_a[7] <= imgB_3[13];
                    mul_a[8] <= imgB_3[14];  
                end
            end
            28:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgB_1[5];
                    mul_a[1] <= imgB_1[6];
                    mul_a[2] <= imgB_1[7];
                    mul_a[3] <= imgB_1[9];
                    mul_a[4] <= imgB_1[10];
                    mul_a[5] <= imgB_1[11];
                    mul_a[6] <= imgB_1[13];
                    mul_a[7] <= imgB_1[14];
                    mul_a[8] <= imgB_1[15];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgB_2[5];
                    mul_a[1] <= imgB_2[6];
                    mul_a[2] <= imgB_2[7];
                    mul_a[3] <= imgB_2[9];
                    mul_a[4] <= imgB_2[10];
                    mul_a[5] <= imgB_2[11];
                    mul_a[6] <= imgB_2[13];
                    mul_a[7] <= imgB_2[14];
                    mul_a[8] <= imgB_2[15];  
                end
                else begin
                    mul_a[0] <= imgB_3[5];
                    mul_a[1] <= imgB_3[6];
                    mul_a[2] <= imgB_3[7];
                    mul_a[3] <= imgB_3[9];
                    mul_a[4] <= imgB_3[10];
                    mul_a[5] <= imgB_3[11];
                    mul_a[6] <= imgB_3[13];
                    mul_a[7] <= imgB_3[14];
                    mul_a[8] <= imgB_3[15];  
                end
                
            end
            29:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgB_1[6];
                    mul_a[1] <= imgB_1[7];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_1[7];
                    mul_a[3] <= imgB_1[10];
                    mul_a[4] <= imgB_1[11];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_1[11];
                    mul_a[6] <= imgB_1[14];
                    mul_a[7] <= imgB_1[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_1[15];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgB_2[6];
                    mul_a[1] <= imgB_2[7];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_2[7];
                    mul_a[3] <= imgB_2[10];
                    mul_a[4] <= imgB_2[11];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_2[11];
                    mul_a[6] <= imgB_2[14];
                    mul_a[7] <= imgB_2[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_2[15];    
                end
                else begin
                    mul_a[0] <= imgB_3[6];
                    mul_a[1] <= imgB_3[7];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_3[7];
                    mul_a[3] <= imgB_3[10];
                    mul_a[4] <= imgB_3[11];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_3[11];
                    mul_a[6] <= imgB_3[14];
                    mul_a[7] <= imgB_3[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_3[15];    
                end
                
            end
            26:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_1[8];
                    mul_a[1] <= imgB_1[8];
                    mul_a[2] <= imgB_1[9];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_1[12];
                    mul_a[4] <= imgB_1[12];
                    mul_a[5] <= imgB_1[13];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_1[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_1[12];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_1[13];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_2[8];
                    mul_a[1] <= imgB_2[8];
                    mul_a[2] <= imgB_2[9];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_2[12];
                    mul_a[4] <= imgB_2[12];
                    mul_a[5] <= imgB_2[13];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_2[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_2[12];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_2[13];    
                end
                else begin
                    mul_a[0] <= (opt_tmp[0])? zero: imgB_3[8];
                    mul_a[1] <= imgB_3[8];
                    mul_a[2] <= imgB_3[9];
                    mul_a[3] <= (opt_tmp[0])? zero: imgB_3[12];
                    mul_a[4] <= imgB_3[12];
                    mul_a[5] <= imgB_3[13];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_3[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_3[12];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_3[13];    
                end
                
            end
            27:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgB_1[8];
                    mul_a[1] <= imgB_1[9];
                    mul_a[2] <= imgB_1[10];
                    mul_a[3] <= imgB_1[12];
                    mul_a[4] <= imgB_1[13];
                    mul_a[5] <= imgB_1[14];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_1[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_1[13];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_1[14];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgB_2[8];
                    mul_a[1] <= imgB_2[9];
                    mul_a[2] <= imgB_2[10];
                    mul_a[3] <= imgB_2[12];
                    mul_a[4] <= imgB_2[13];
                    mul_a[5] <= imgB_2[14];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_2[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_2[13];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_2[14];    
                end
                else begin
                    mul_a[0] <= imgB_3[8];
                    mul_a[1] <= imgB_3[9];
                    mul_a[2] <= imgB_3[10];
                    mul_a[3] <= imgB_3[12];
                    mul_a[4] <= imgB_3[13];
                    mul_a[5] <= imgB_3[14];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_3[12];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_3[13];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_3[14];    
                end
                
            end
            30:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgB_1[9];
                    mul_a[1] <= imgB_1[10];
                    mul_a[2] <= imgB_1[11];
                    mul_a[3] <= imgB_1[13];
                    mul_a[4] <= imgB_1[14];
                    mul_a[5] <= imgB_1[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_1[13];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_1[14];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_1[15];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgB_2[9];
                    mul_a[1] <= imgB_2[10];
                    mul_a[2] <= imgB_2[11];
                    mul_a[3] <= imgB_2[13];
                    mul_a[4] <= imgB_2[14];
                    mul_a[5] <= imgB_2[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_2[13];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_2[14];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_2[15];    
                end
                else begin
                    mul_a[0] <= imgB_3[9];
                    mul_a[1] <= imgB_3[10];
                    mul_a[2] <= imgB_3[11];
                    mul_a[3] <= imgB_3[13];
                    mul_a[4] <= imgB_3[14];
                    mul_a[5] <= imgB_3[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_3[13];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_3[14];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_3[15];    
                end
                
            end
            31:begin
                if(ker_count == 'd0)begin
                    mul_a[0] <= imgB_1[10];
                    mul_a[1] <= imgB_1[11];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_1[11];
                    mul_a[3] <= imgB_1[14];
                    mul_a[4] <= imgB_1[15];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_1[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_1[14];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_1[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_1[15];
                end
                else if(ker_count == 'd1)begin
                    mul_a[0] <= imgB_2[10];
                    mul_a[1] <= imgB_2[11];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_2[11];
                    mul_a[3] <= imgB_2[14];
                    mul_a[4] <= imgB_2[15];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_2[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_2[14];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_2[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_2[15];    
                end
                else begin
                    mul_a[0] <= imgB_3[10];
                    mul_a[1] <= imgB_3[11];
                    mul_a[2] <= (opt_tmp[0])? zero: imgB_3[11];
                    mul_a[3] <= imgB_3[14];
                    mul_a[4] <= imgB_3[15];
                    mul_a[5] <= (opt_tmp[0])? zero: imgB_3[15];
                    mul_a[6] <= (opt_tmp[0])? zero: imgB_3[14];
                    mul_a[7] <= (opt_tmp[0])? zero: imgB_3[15];
                    mul_a[8] <= (opt_tmp[0])? zero: imgB_3[15];    
                end
                
            end  
        
            default : begin
                    mul_a[0] <= 0;
                    mul_a[1] <= 0;
                    mul_a[2] <= 0;
                    mul_a[3] <= 0;
                    mul_a[4] <= 0;
                    mul_a[5] <= 0;
                    mul_a[6] <= 0;
                    mul_a[7] <= 0;
                    mul_a[8] <= 0;
                end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mul_ker[0] <= 'd0;
        mul_ker[1] <= 'd0;
        mul_ker[2] <= 'd0;
        mul_ker[3] <= 'd0;
        mul_ker[4] <= 'd0;
        mul_ker[5] <= 'd0;
        mul_ker[6] <= 'd0;
        mul_ker[7] <= 'd0;
        mul_ker[8] <= 'd0;
    end
    else if(curr_state == COV)begin
        case(ker_count)
        0 : begin
            mul_ker[0] <= ker_1[0];
            mul_ker[1] <= ker_1[1];
            mul_ker[2] <= ker_1[2];
            mul_ker[3] <= ker_1[3];
            mul_ker[4] <= ker_1[4];
            mul_ker[5] <= ker_1[5];
            mul_ker[6] <= ker_1[6];
            mul_ker[7] <= ker_1[7];
            mul_ker[8] <= ker_1[8];
        end
        1 : begin
            mul_ker[0] <= ker_2[0];
            mul_ker[1] <= ker_2[1];
            mul_ker[2] <= ker_2[2];
            mul_ker[3] <= ker_2[3];
            mul_ker[4] <= ker_2[4];
            mul_ker[5] <= ker_2[5];
            mul_ker[6] <= ker_2[6];
            mul_ker[7] <= ker_2[7];
            mul_ker[8] <= ker_2[8];
        end 
        2 : begin
            mul_ker[0] <= ker_3[0];
            mul_ker[1] <= ker_3[1];
            mul_ker[2] <= ker_3[2];
            mul_ker[3] <= ker_3[3];
            mul_ker[4] <= ker_3[4];
            mul_ker[5] <= ker_3[5];
            mul_ker[6] <= ker_3[6];
            mul_ker[7] <= ker_3[7];
            mul_ker[8] <= ker_3[8];
        end
        default : begin
            mul_ker[0] <= 'd0;
            mul_ker[1] <= 'd0;
            mul_ker[2] <= 'd0;
            mul_ker[3] <= 'd0;
            mul_ker[4] <= 'd0;
            mul_ker[5] <= 'd0;
            mul_ker[6] <= 'd0;
            mul_ker[7] <= 'd0;
            mul_ker[8] <= 'd0;
        end
    endcase
    end
end

// sum a b c
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) sum_a <= 'd0;
    else if(curr_state == COV) begin
        sum_a <= (ker_count == 'd1)? add_tmp[3] : sum_a;
    end
    else sum_a <= 'd0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) sum_b <= 'd0;
    else if(curr_state == COV) begin
        sum_b <= (ker_count == 'd2)? add_tmp[3] : sum_b;
    end
    else sum_b <= 'd0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) sum_c <= 'd0;
    else if(curr_state == COV) begin
        sum_c <= (ker_count == 'd0)? add_tmp[3] : sum_c;
    end
    else sum_c <= 'd0;
end
//---------------------------------------------------------------------
//   max-pool
//---------------------------------------------------------------------
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1 ( .a(max_pol[0]), .b(max_pol[1]), .zctr(1'b1), .z0(compare_tmp[0]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2 ( .a(max_pol[2]), .b(max_pol[3]), .zctr(1'b1), .z0(compare_tmp[1]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C3 ( .a(com_a), .b(com_b), .zctr(1'b1), .z0(com_c));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) com_a <= 'd0;
    else if(curr_state == COV) begin
        com_a <= (mul_count >= 'd1)? compare_tmp[0] : com_a;
    end
    else com_a <= 'd0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) com_b <= 'd0;
    else if(curr_state == COV) begin
        com_b <= (mul_count >= 'd1)? compare_tmp[1] : com_b;
    end
    else com_b <= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(i = 0;i<=3;i = i+1)begin
            max_pol[i] <= 0;
        end
    end 
    else if(curr_state == COV && ker_count == 'd1) begin
        max_pol[3] <= sum_out;
        for(i = 2;i>=0;i = i-1)begin
            max_pol[i] <= max_pol[i+1];
        end
    end
    else begin
        max_pol[0] <= max_pol[0];
        max_pol[1] <= max_pol[1];
        max_pol[2] <= max_pol[2];
        max_pol[3] <= max_pol[3];        
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(i = 0;i<=3;i=i+1)begin
            map_A[i] <= 0;
            map_B[i] <= 0;
        end
    end else if(curr_state==COV) begin
         case (mul_count)
            1: map_B[3] <= com_c;
            5: map_A[0] <= com_c;
            9: map_A[1] <= com_c;
            13: map_A[2] <= com_c;
            17: map_A[3] <= com_c;
            21: map_B[0] <= com_c;
            25: map_B[1] <= com_c;
            29: map_B[2] <= com_c;
         
             default :begin
                map_A[0] <= map_A[0];
                map_A[1] <= map_A[1];
                map_A[2] <= map_A[2];
                map_A[3] <= map_A[3];
                map_B[0] <= map_B[0];
                map_B[1] <= map_B[1];
                map_B[2] <= map_B[2];
                map_B[3] <= map_B[3];
             end
         endcase
    end
    else begin
        map_A[0] <= map_A[0];
        map_A[1] <= map_A[1];
        map_A[2] <= map_A[2];
        map_A[3] <= map_A[3];
        map_B[0] <= map_B[0];
        map_B[1] <= map_B[1];
        map_B[2] <= map_B[2];
        map_B[3] <= map_B[3];
    end
end
//---------------------------------------------------------------------
//   feature
//---------------------------------------------------------------------
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M9 (.a(feature_A[0]), .b(weight_in[0]), .rnd(3'b000), .z(map_tmp[0]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M10 (.a(feature_A[1]), .b(weight_in[2]), .rnd(3'b000), .z(map_tmp[1]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M11 (.a(feature_A[2]), .b(weight_in[1]), .rnd(3'b000), .z(map_tmp[2]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M12 (.a(feature_A[3]), .b(weight_in[3]), .rnd(3'b000), .z(map_tmp[3]));

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A1(.a(map_tmp[0]), .b(map_tmp[1]), .rnd(3'b000), .z(feature_out[0]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A2(.a(map_tmp[2]), .b(map_tmp[3]), .rnd(3'b000), .z(feature_out[1]));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) feature_count <= 'd0;
    else if(curr_state == FUL_C) begin
        feature_count <= feature_count+1;
    
    end
        
    else feature_count <= 'd0;
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(i = 0;i<=3;i = i+1)begin
            feature_A[i] <= 0;
        end
    end
    else if(curr_state == FUL_C) begin
        case(feature_count)
            0: begin
                feature_A[0] <= map_A[0];
                feature_A[1] <= map_A[1];
                feature_A[2] <= map_A[0];
                feature_A[3] <= map_A[1];
            end
            1: begin
                feature_A[0] <= map_A[2];
                feature_A[1] <= map_A[3];
                feature_A[2] <= map_A[2];
                feature_A[3] <= map_A[3];
            end
            2: begin
                feature_A[0] <= map_B[0];
                feature_A[1] <= map_B[1];
                feature_A[2] <= map_B[0];
                feature_A[3] <= map_B[1];
            end
            3: begin
                feature_A[0] <= map_B[2];
                feature_A[1] <= map_B[3];
                feature_A[2] <= map_B[2];
                feature_A[3] <= map_B[3];
            end
            default:begin
                feature_A[0] <= 0;
                feature_A[1] <= 0;
                feature_A[2] <= 0;
                feature_A[3] <= 0;
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(i = 0;i<=3;i = i+1)begin
            final_map_A[i] <= 0;
            final_map_B[i] <= 0;
        end
    end
    else if(curr_state == FUL_C) begin
        case(feature_count)
            1: begin
                final_map_A[0] <= feature_out[0];
                final_map_A[1] <= feature_out[1];
            end
            2: begin
                final_map_A[2] <= feature_out[0];
                final_map_A[3] <= feature_out[1];
            end
            3: begin
                final_map_B[0] <= feature_out[0];
                final_map_B[1] <= feature_out[1];
            end
            4: begin
                final_map_B[2] <= feature_out[0];
                final_map_B[3] <= feature_out[1];
            end
            default:begin
                final_map_A[0] <= final_map_A[0];
                final_map_A[1] <= final_map_A[1];
                final_map_A[2] <= final_map_A[2];
                final_map_A[3] <= final_map_A[3];
                final_map_B[0] <= final_map_B[0];
                final_map_B[1] <= final_map_B[1];
                final_map_B[2] <= final_map_B[2];
                final_map_B[3] <= final_map_B[3];
            end
        endcase
    end
    else begin
        final_map_A[0] <= final_map_A[0];
        final_map_A[1] <= final_map_A[1];
        final_map_A[2] <= final_map_A[2];
        final_map_A[3] <= final_map_A[3];
        final_map_B[0] <= final_map_B[0];
        final_map_B[1] <= final_map_B[1];
        final_map_B[2] <= final_map_B[2];
        final_map_B[3] <= final_map_B[3];
    end
end
//---------------------------------------------------------------------
//   normalize
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        normal_in <= 0;
    end else if(curr_state==FUL_C) begin
        case (feature_count)
               6: normal_in <= final_map_A[0];
               7: normal_in <= final_map_A[1];
               8: normal_in <= final_map_A[2];
               9: normal_in <= final_map_A[3];
               10: normal_in <= final_map_B[0];
               11: normal_in <= final_map_B[1];
              12: normal_in <= final_map_B[2];
              13: normal_in <= final_map_B[3];
            
        
            default : begin
                normal_in <= 0;
            end
        endcase
    end
    else begin
        normal_in <= 0;
    end
end

reg [31:0] minus_A, minus_C, minus_B, minus_D;
reg [31:0] acti_tmp, exp_x_sub_exp_nx_tmp, add_exp_nx_tmp;

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C4 ( .a(final_map_A[0]), .b(final_map_A[1]), .zctr(1'b1), .z0(max[0]), .z1(min[0]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C5 ( .a(final_map_A[2]), .b(final_map_A[3]), .zctr(1'b1), .z0(max[1]), .z1(min[1]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C6 ( .a(max_tmp[0]), .b(max_tmp[1]), .zctr(1'b1), .z0(max_scal_A));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C7 ( .a(min_tmp[0]), .b(min_tmp[1]), .zctr(1'b1), .z1(min_scal_A));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C8 ( .a(final_map_B[0]), .b(final_map_B[1]), .zctr(1'b1), .z0(max[2]), .z1(min[2]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C9 ( .a(final_map_B[2]), .b(final_map_B[3]), .zctr(1'b1), .z0(max[3]), .z1(min[3]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C10 ( .a(max_tmp[2]), .b(max_tmp[3]), .zctr(1'b1), .z0(max_scal_B));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C11 ( .a(min_tmp[2]), .b(min_tmp[3]), .zctr(1'b1), .z1(min_scal_B));

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S6(.a(minus_A), .b(minus_B), .rnd(3'b000), .z(mother_scal_A));
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S7(.a(minus_C), .b(minus_D), .rnd(3'b000), .z(mother_scal_B));

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S8(.a(normal_in), .b(((feature_count<=10)? min_scal_A:min_scal_B)), .rnd(3'b000), .z(div_in));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) DIV1(.a(div_in), .b(((feature_count<=10)? mother_scal_A:mother_scal_B)), .z(acti_in), .rnd(3'b000));

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) EXPPX(.a(acti_tmp), .z(exp_x));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) EXPNX(.a({~acti_tmp[31], acti_tmp[30:0]}), .z(exp_nx));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADD(.a(((!opt_tmp[1])? one: exp_x)), .b(exp_nx), .rnd(3'b000), .z(add_exp_nx));
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) SUB(.a(exp_x), .b(exp_nx), .rnd(3'b000), .z(exp_x_sub_exp_nx));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) DIV(.a(((!opt_tmp[1])? one: exp_x_sub_exp_nx_tmp)), .b(add_exp_nx_tmp), .z(out_tmp), .rnd(3'b000));


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        acti_tmp <= 0;
    end else if(curr_state == FUL_C && feature_count >= 7) begin
        acti_tmp <= acti_in;
    end
    else acti_tmp <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        exp_x_sub_exp_nx_tmp <= 0;
    end else if(curr_state == FUL_C && feature_count >= 8) begin
        exp_x_sub_exp_nx_tmp <= exp_x_sub_exp_nx;
    end
    else exp_x_sub_exp_nx_tmp <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        add_exp_nx_tmp <= 0;
    end else if(curr_state == FUL_C && feature_count >= 8) begin
        add_exp_nx_tmp <= add_exp_nx;
    end
    else add_exp_nx_tmp <= 0;
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (i = 0; i <=3; i=i+1) begin
            max_tmp[i] <= 0;
            min_tmp[i] <= 0;
        end
    end 
    else if(curr_state == FUL_C) begin
        for (i = 0; i <= 3; i = i+1) begin
            max_tmp[i] <= (feature_count >= 4)? max[i] : max_tmp[i];
            min_tmp[i] <= (feature_count >= 4)? min[i] : min_tmp[i];
        end
    end
    else begin
        for (i = 0; i <=3; i=i+1) begin
            max_tmp[i] <= 0;
            min_tmp[i] <= 0;
        end
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        minus_A <= 0;
        minus_B <= 0;
        minus_C <= 0;
        minus_D <= 0;
    end 
    else if(curr_state == FUL_C && feature_count == 6) begin
        minus_A <= max_scal_A;
        minus_B <= min_scal_A;
        minus_C <= max_scal_B;
        minus_D <= min_scal_B; 
    end
    else begin
        minus_A <= minus_A;
        minus_B <= minus_B;
        minus_C <= minus_C;
        minus_D <= minus_D;
    end
end


always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        for(i=0;i<=3;i=i+1)begin
           L1_vec_A[i] <= 0;
           L1_vec_B[i] <= 0; 
        end
    end 
    else if(curr_state==FUL_C) begin
        case (feature_count)
               
                9: L1_vec_A[0] <= out_tmp;
                10: L1_vec_A[1] <= out_tmp;
                11: L1_vec_A[2] <= out_tmp;
                12: L1_vec_A[3] <= out_tmp;
                13: L1_vec_B[0] <= out_tmp;
                14: L1_vec_B[1] <= out_tmp;
                15: L1_vec_B[2] <= out_tmp;
                16: L1_vec_B[3] <= out_tmp;            
        
            default : begin
                L1_vec_A[0] <= L1_vec_A[0];
                L1_vec_A[1] <= L1_vec_A[1];
                L1_vec_A[2] <= L1_vec_A[2];
                L1_vec_A[3] <= L1_vec_A[3];
                L1_vec_B[0] <= L1_vec_B[0];
                L1_vec_B[1] <= L1_vec_B[1];
                L1_vec_B[2] <= L1_vec_B[2];
                L1_vec_B[3] <= L1_vec_B[3];
            end
        endcase
    end
    else begin
        L1_vec_A[0] <= L1_vec_A[0];
        L1_vec_A[1] <= L1_vec_A[1];
        L1_vec_A[2] <= L1_vec_A[2];
        L1_vec_A[3] <= L1_vec_A[3];
        L1_vec_B[0] <= L1_vec_A[0];
        L1_vec_B[1] <= L1_vec_A[1];
        L1_vec_B[2] <= L1_vec_A[2];
        L1_vec_B[3] <= L1_vec_A[3];
    end
end


DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C12 ( .a(final_A), .b(final_B), .zctr(1'b1), .z0(out_max), .z1(out_min));
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S9(.a(out_max), .b(out_min), .rnd(3'b000), .z(out_tmpA));

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        final_A <= 0;
        final_B <= 0;
    end else if(curr_state==FUL_C) begin
        case (feature_count)

            14: begin
                final_A <= L1_vec_A[0];
                final_B <= L1_vec_B[0];
            end
            15: begin
                final_A <= L1_vec_A[1];
                final_B <= L1_vec_B[1];
            end
            16: begin
                final_A <= L1_vec_A[2];
                final_B <= L1_vec_B[2];
            end
            17: begin
                final_A <= L1_vec_A[3];
                final_B <= L1_vec_B[3];
            end
            
            default : begin
                final_A <= 0;
                final_B <= 0;
            end
        endcase
    end
    else begin
        final_A <= 0;
        final_B <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        for(i=0;i<=3;i=i+1)begin
           sum4[i] <= 0; 
        end
    end else if(curr_state==FUL_C) begin
        case (feature_count)

            15: begin
                sum4[0] <= out_tmpA;
            end
            16: begin
                sum4[1] <= out_tmpA;
            end
            17: begin
                sum4[2] <= out_tmpA;
            end
            18: begin
                sum4[3] <= out_tmpA;
            end
            
            default : begin
                sum4[0] <= sum4[0];
                sum4[1] <= sum4[1];
                sum4[2] <= sum4[2];
                sum4[3] <= sum4[3];
            end
        endcase
    end
    else begin
        sum4[0] <= sum4[0];
        sum4[1] <= sum4[1];
        sum4[2] <= sum4[2];
        sum4[3] <= sum4[3];
    end
end
DW_fp_sum4 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) Sum (.a(sum4[0]), .b(sum4[1]), .c(sum4[2]), .d(sum4[3]), .z(out_last), .rnd(3'b000));

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_flag <= 0;
    end else if(curr_state==FUL_C && feature_count == 19) begin
         out_flag <= 1;
    end
    else out_flag <= 0;
end
//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
//==============================================//
//             Current State Block              //
//==============================================//
always@(posedge  clk or negedge rst_n) begin
    if(!rst_n) curr_state <= IDLE;
    else curr_state <= next_state;
end

//==============================================//
//              Next State Block                //
//==============================================//
always@(*) begin
    if(!rst_n) next_state = IDLE;
    else begin
        case(curr_state)
            IDLE: next_state = (in_valid)? INPUT : IDLE;
            INPUT : next_state = (~in_valid)? COV : INPUT; 
            COV : next_state = (cov_done)? FUL_C:COV; 
            FUL_C : next_state = (out_flag)? OUT : FUL_C;
            OUT : next_state = (out_valid) ? OUT: IDLE;
            default: next_state = IDLE;
        endcase 
    end
end
//---------------------------------------------------------------------
//   output
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin        
        out_valid <= 0;
    end else if(out_flag) begin       
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin        
        out <= 'b0;
    end else if(out_flag) begin       
        out <= out_last;
    end
    else out <= 0;
end
endmodule
