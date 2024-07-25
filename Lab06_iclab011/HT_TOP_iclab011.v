//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
integer i;
genvar k;
reg [4:0] weight_reg[0:14];
reg out_mode_tmp, out_mode_tmp_comb;
reg [31:0] in_char;
reg [31:0] out_char;
reg [39:0] weight;

//reg [3:0] index_tmp;
reg [4:0] weight_tmp;
reg [3:0] char_index[0:7];
//huffman
reg [3:0] index[0:7];
//reg [7:0] child[0:14];
reg [3:0] bit_num[0:7];
reg [3:0] exe_count;
reg [3:0] node_count;
reg [6:0] code[0:7];

reg exe_finish, out_finish;
reg [2:0] curr_state, next_state;

parameter IDLE = 3'd0;
parameter INPUT = 3'd1;
parameter EXE = 3'd2;
parameter OUT = 3'd3;
// ===============================================================
// Design
// ===============================================================
reg [3:0] input_count;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        input_count <= 0;
    end else if(in_valid == 1) begin
        input_count <= input_count+1;
    end
    else begin
        input_count <=0;
    end
end

always @(*) begin
    out_mode_tmp_comb = out_mode_tmp;
    if (in_valid == 1 && input_count ==0) begin
        out_mode_tmp_comb = out_mode;
    end    
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_mode_tmp <= 0;
    else out_mode_tmp <= out_mode_tmp_comb;
end


always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		for(i = 0;i <= 14; i = i+1)begin
			weight_reg[i] <= 0;
		end
	end
    else if(next_state==IDLE)begin
        for(i = 0;i <= 14; i = i+1)begin
            weight_reg[i] <= 0;
        end
    end 
    else if(in_valid == 1) begin
		weight_reg[14-input_count] <= in_weight;

	end
    else if(curr_state==EXE)begin
        weight_reg[node_count] <= weight_tmp;
    end
end


always @(posedge clk or negedge rst_n) begin 
    if(~rst_n ) begin
        in_char <= 0;
    end
    else if(curr_state == IDLE)begin
        in_char <= 0;
    end
    else if(curr_state == INPUT) begin
        in_char <= {4'd14, 4'd13, 4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7};
    end
    else if(curr_state ==EXE) begin
        case (node_count)
            6: begin
                in_char[31:8] <= out_char[31:8];
                in_char[7:4] <= node_count;
                in_char[3:0] <= 'b0;
            end
            5: begin
                in_char[31:12] <= out_char[31:12];
                in_char[11:8] <= node_count;
                in_char[7:0] <= 'b0;
            end
            4: begin
                in_char[31:16] <= out_char[31:16];
                in_char[15:12] <= node_count;
                in_char[11:0] <= 'b0;
            end
            3: begin
                in_char[31:20] <= out_char[31:20];
                in_char[19:16] <= node_count;
                in_char[15:0] <= 'b0;
            end
            2: begin
                in_char[31:24] <= out_char[31:24];
                in_char[23:20] <= node_count;
                in_char[19:0] <= 'b0;
            end
            1: begin
                in_char[31:28] <= out_char[31:28];
                in_char[27:24] <= node_count;
                in_char[23:0] <= 'b0;
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        weight <= 0;
    end 
    else if(curr_state == INPUT) begin
        weight <= {weight_reg[14], weight_reg[13], weight_reg[12], weight_reg[11], weight_reg[10], 
                      weight_reg[9], weight_reg[8], weight_reg[7]};
    end
    else if(curr_state ==EXE) begin
        case (node_count)
            6: begin
                weight[39:35] <= weight_reg[index[0]];
                weight[34:30] <= weight_reg[index[1]];
                weight[29:25] <= weight_reg[index[2]];
                weight[24:20] <= weight_reg[index[3]];
                weight[19:15] <= weight_reg[index[4]];
                weight[14:10] <= weight_reg[index[5]];
                weight[9:5] <= weight_tmp;
                weight[4:0] <= 5'b0;
            end
            5: begin
                weight[39:35] <= weight_reg[index[0]];
                weight[34:30] <= weight_reg[index[1]];
                weight[29:25] <= weight_reg[index[2]];
                weight[24:20] <= weight_reg[index[3]];
                weight[19:15] <= weight_reg[index[4]];
                weight[14:10] <= weight_tmp;
                weight[9:0] <= 'b0;
            end
            4: begin
                weight[39:35] <= weight_reg[index[0]];
                weight[34:30] <= weight_reg[index[1]];
                weight[29:25] <= weight_reg[index[2]];
                weight[24:20] <= weight_reg[index[3]];
                weight[19:15] <= weight_tmp;
                weight[14:0] <= 'b0;
            end
            3: begin
                weight[39:35] <= weight_reg[index[0]];
                weight[34:30] <= weight_reg[index[1]];
                weight[29:25] <= weight_reg[index[2]];
                weight[24:20] <= weight_tmp;
                weight[19:0] <= 'b0;
            end
            2: begin
                weight[39:35] <= weight_reg[index[0]];
                weight[34:30] <= weight_reg[index[1]];
                weight[29:25] <= weight_tmp;
                weight[24:0] <= 'b0;
            end
            1: begin
                weight[39:35] <= weight_reg[index[0]];
                weight[34:30] <= weight_tmp;
                weight[29:0] <= 'b0;
            end
            default: weight<= 0;
        endcase

    end
    else begin
        weight <=0;
    end
end

// ===============================================================
// EXE
// ===============================================================
reg [3:0] big_index, sma_index;

SORT_IP S1(.IN_character(in_char), .IN_weight(weight), .OUT_character(out_char));

always @(*) begin
    index[0] = out_char[31:28];
    index[1] = out_char[27:24];
    index[2] = out_char[23:20];
    index[3] = out_char[19:16];
    index[4] = out_char[15:12];
    index[5] = out_char[11:8];
    index[6] = out_char[7:4];
    index[7] = out_char[3:0];
end
always @(*) begin
    weight_tmp = weight_reg[index[6- exe_count]] + weight_reg[index[7 - exe_count]];
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(i = 0;i <= 7; i = i+1)begin
            char_index[i] <= 0;
        end
    end else if(curr_state == INPUT) begin
        char_index[0] <= 4'd14;
        char_index[1] <= 4'd13;
        char_index[2] <= 4'd12;
        char_index[3] <= 4'd11;
        char_index[4] <= 4'd10;
        char_index[5] <= 4'd9;
        char_index[6] <= 4'd8;
        char_index[7] <= 4'd7;
    end
    else if(curr_state==EXE) begin
        for(i= 0;i<=7;i=i+1) begin
            if(char_index[i] == big_index || char_index[i] == sma_index)begin
                char_index[i] <= node_count;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        exe_count <= 0;
    end else if(curr_state==EXE ) begin
        exe_count <= exe_count+1;
    end 
    else begin
        exe_count <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        node_count <= 0;
    end else if(curr_state==INPUT) begin
        node_count <= 6;
    end else if(curr_state == EXE)begin
        node_count <= node_count-1;
    end
    else begin
        node_count <= 0;
    end
end

  

always @(*) begin
    case (node_count)
        6: begin
            big_index = out_char[7:4];
            sma_index = out_char[3:0];
        end
        5: begin
            big_index = out_char[11:8];
            sma_index = out_char[7:4];
        end
        4: begin
            big_index = out_char[15:12];
            sma_index = out_char[11:8];
        end
        3: begin
            big_index = out_char[19:16];
            sma_index = out_char[15:12];
        end
        2: begin
            big_index = out_char[23:20];
            sma_index = out_char[19:16];
        end
        1: begin
            big_index = out_char[27:24];
            sma_index = out_char[23:20];
        end
        0: begin
            big_index = out_char[31:28];
            sma_index = out_char[27:24];
        end
        default : begin
            big_index = 0;
            sma_index = 0;
        end
    endcase
end



generate
    for(k = 0 ;k<=7;k=k+1)begin
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin             
                bit_num[k] <= 0;
            end
            else if(curr_state == IDLE)begin
                bit_num[k] <= 0;
            end
            else if(curr_state==EXE)begin
                if(char_index[k] == big_index) begin
                     //push 0
                    bit_num[k] <= bit_num[k]+1;
                end 
                else if(char_index[k] == sma_index) begin
                    bit_num[k] <= bit_num[k]+1;
                end
            end
        end
    end
endgenerate

generate
    for(k = 0 ;k<=7;k=k+1)begin
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin             
                code[k] <= 0;
            end
            else if(curr_state == IDLE)begin
                code[k] <= 0;
            end
            else if(curr_state==EXE)begin
                if(char_index[k] == sma_index) begin
                    //push 1
                    case (bit_num[k])
                        0: code[k] <= code[k]+1;
                        1: code[k] <= code[k]+2;
                        2: code[k] <= code[k]+4;
                        3: code[k] <= code[k]+8;
                        4: code[k] <= code[k]+16;
                        5: code[k] <= code[k]+32;
                        6: code[k] <= code[k]+64;
                        default : code[k] <= code[k];
                    endcase
                end
            end
        end
    end
endgenerate

/*always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        exe_finish <= 0;
    end else if(curr_state == EXE) begin
        exe_finish <= (node_count==0)? 1 : 0;
    end
end*/
/*always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        index_tmp <= 0;
    end else if(curr_state == EXE) begin
        index_tmp <= 8+exe_count;
    end
end*/
//complete (only bit_num for a~V?)
/*always @(*) begin
    if(~rst_n) begin
        for(i=0;i<=14;i=i+1)begin
            bit_num[i] = 0;
        end
    end else begin
         <= ;
    end
end
//code
always @(*) begin
        
    if(curr_state == EXE) begin
        child[index_tmp] = {index[6- exe_count], index[7 - exe_count]};
    end
    else begin
        for(i=0;i<=14;i=i+1)begin
            child[i] = 0;
        end
    end
end*/
// ===============================================================
// OUT
// ===============================================================
reg out_code_tmp;
reg [3:0] out_count, count_idx;
reg [6:0] tmp;


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        count_idx <= 0;
    end
    else if(curr_state==IDLE)begin
        count_idx <= 4;
    end 
    else if(curr_state==OUT) begin
        if(out_count == bit_num[count_idx]-1 && out_mode_tmp == 0)begin
            count_idx <= (count_idx==7)? 3: count_idx+1;
        end
        else if(out_count == bit_num[count_idx]-1 && out_mode_tmp == 1)begin
            case(count_idx)
                4: count_idx<= 2;
                2: count_idx<= 5;
                5: count_idx<= 0;
                0: count_idx<= 1;
            endcase
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_count <= 0;
    end else if(curr_state==OUT) begin
        if(out_count == bit_num[count_idx]-1)begin
            out_count <=0;
        end
        else begin
            out_count <= out_count+1;
        end
    end
end

always @(*) begin
    if(curr_state == OUT) begin
        tmp = bit_num[count_idx]-1-out_count;
        out_code_tmp = code[count_idx][tmp];
    end
    else out_code_tmp = 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_valid <= 0;
    end else if(curr_state == OUT) begin
        out_valid <= 1;
    end
    else out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_code <= 0;
    end else if(curr_state == OUT) begin
       
        out_code <= out_code_tmp;
    end
    else begin
        out_code <= 0;
    end
end

always @(*) begin
    if(curr_state == OUT) begin
        if(out_mode_tmp==0)begin
            out_finish = (count_idx == 3 && out_count == bit_num[3] -1)? 1:0;
        end
        else begin
            out_finish = (count_idx == 1 && out_count == bit_num[1]-1)? 1:0;
        end
    end
    else begin
        out_finish = 0;
    end
end
// ===============================================================
// FSM
// ===============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        curr_state <= IDLE;
    end else begin
        curr_state <= next_state;
    end
end

always @(*) begin 
    case (curr_state)
        IDLE: next_state = (!in_valid)? IDLE : INPUT;
        INPUT: next_state = (!in_valid)? EXE : INPUT;
        EXE: next_state = (node_count==0)? OUT : EXE;
        OUT: next_state = (!out_finish)? OUT : IDLE;
        default: next_state = 2'b00;
    endcase
end



endmodule