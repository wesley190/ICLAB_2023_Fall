module Train(
    //Input Port
    clk,
    rst_n,
    in_valid,
    data,

    //Output Port
    out_valid,
    result
);

input        clk;
input        in_valid;
input        rst_n;
input  [3:0] data;
output   reg out_valid;
output   reg result; 
/************************************/
//*          reg                   *//
/************************************/
reg [2:0] curr_state, next_state;
reg [3:0] in_count;
reg [3:0] Num, require[0:9];
reg [3:0] in_num[0:9], bridge[0:9], gold[0:9];
reg cal_finish;

integer i, j;
genvar k;
parameter IDLE = 3'd0;
parameter INPUT = 3'd1;
parameter CAL= 3'd2;
parameter OUT = 3'd3;

/************************************/
//*          input                   *//
/************************************/

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        in_count <= 0;
    end 
    else if(next_state == IDLE)begin
        in_count <= 0;
    end
    else if(in_valid ==1) begin
        in_count <= in_count+1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        Num <= 0;
    end 
    else if(next_state == INPUT && in_count ==0) begin
        Num <= data;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(i=0;i<10;i=i+1)begin
            require[i] <= 0;
        end
    end 
    else if(curr_state == INPUT && in_valid == 1) begin
        require[in_count-1] <= data;
    end
end
/************************************/
//*          CAL                   *//
/************************************/
reg [3:0] gold_check, index, order;
reg [3:0] move_num;
reg [7:0] cal_count;
reg [3:0] move_num_tmp, sum;
reg out_tmp;

always @(posedge clk or negedge rst_n) begin 
     if(~rst_n) begin
        cal_count <= 0;
     end
     else if(curr_state == IDLE)begin
        cal_count <= 0;
     end
     else if(curr_state == CAL) begin
        cal_count <= cal_count +1;
     end
 end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        index <= 0;
    end
    else if(curr_state == IDLE)begin
        index <= 0;
    end 
    else if(curr_state == CAL) begin
        if(index < Num && in_num[0] != require[order])begin
            index <= index+1;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        order <= 0;
    end
    else if(curr_state == IDLE)begin
        order <= 0;
    end 
    else if(curr_state == CAL) begin
        if(in_num[0] == require[order])begin
            order <= order+1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin 
     if(~rst_n) begin
        for(i=0;i<10;i=i+1)begin
            in_num[i] <= 0;
        end
     end
     else if(curr_state == IDLE) begin
        for(i=0;i<10;i=i+1)begin
            in_num[i] <= 0;
        end
     end 
     else if(curr_state == CAL) begin
        if(in_num[0] == require[order])begin
            for(i=0;i<9;i=i+1)begin
                in_num[i] <= in_num[i+1];
            end
        end
        else begin
            for(i=1;i<10;i=i+1)begin
                in_num[i] <= in_num[i-1];
            end
            in_num [0] <= index;
        end
    end        
     
 end 
 


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cal_finish <= 0;
    end 
    else if(curr_state == CAL) begin
        if(order == Num || cal_count ==99) cal_finish <=1;
    end
    else begin
        cal_finish <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_tmp <= 0;
    end
    else if(curr_state == IDLE)begin
        out_tmp <= 0;
    end 
    else if(curr_state == CAL) begin
        if(order == Num)begin
            out_tmp <= 1;
        end
        else if(cal_count==99)begin
            out_tmp <=0;
        end
    end
end

/************************************/
//*          output                   *//
/************************************/
reg [2:0] out_count;
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        out_count <= 0;
    end
    else if(curr_state == IDLE)begin
        out_count <= 0;
    end 
    else if(curr_state == OUT) begin
        out_count <= out_count +1;
    end
end

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        result <= 0;
    end 
    else if(curr_state == OUT) begin
        result <= out_tmp;
    end
end
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        out_valid <= 0;
    end 
    else if(curr_state == OUT && out_count==0) begin
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end
/************************************/
//*          FSM                  *//
/************************************/
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        curr_state <= 0;
    end else begin
        curr_state <= next_state;
    end
end

always @(*) begin
    if(~rst_n) begin
        next_state = IDLE;
    end
    else begin
        case (curr_state)
            IDLE: next_state = (in_valid)? INPUT : IDLE;
            INPUT: next_state = (!in_valid)? CAL : INPUT;
            CAL: next_state = (cal_finish)? OUT : CAL;
            OUT: next_state = (out_valid)? OUT : IDLE;
            default : next_state = IDLE;
        endcase
    end
end

endmodule