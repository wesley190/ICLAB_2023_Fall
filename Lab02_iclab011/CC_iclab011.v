module CC(
    //Input Port
    clk,
    rst_n,
    in_valid,
    mode,
    xi,
    yi,

    //Output Port
    out_valid,
    xo,
    yo
    );
//Input 
input               clk, rst_n, in_valid;
input       [1:0]   mode;
input       [7:0]   xi, yi;  
//Output 
output reg          out_valid;
output reg  [7:0]   xo, yo;
//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter IDLE = 3'd0;
parameter EXE = 3'd1;
parameter TRAP_REND = 3'd2;
parameter CIR_LINE = 3'd3;
parameter AREA = 3'd4;
//==============================================//
//                 reg declaration              //
//==============================================//
reg  signed[7:0] x_reg[0:3], y_reg[0:3];
reg [1:0] mode_reg;
reg  signed out_valid_temp;
reg  signed[7:0] xo_temp, yo_temp;
reg [1:0] counter, counter_temp;
//==============================================//
//            FSM State Declaration             //
//==============================================//
reg [2:0]curr_state, next_state;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        curr_state <= IDLE;
        counter <= 2'b00;
    end else begin
        curr_state <= next_state;
        counter <= counter_temp;
    end
end

always @(*) begin 
    case (curr_state)
        IDLE: begin
            if (!in_valid)
                next_state = IDLE;
            else
                next_state = EXE;
        end
        EXE: begin
            if (counter == 2) begin
                case (mode)
                    2'b00: next_state = TRAP_REND;
                    2'b01: next_state = CIR_LINE;
                    2'b10: next_state = AREA;
                    default: next_state = EXE;
                endcase
            end else begin
                next_state = EXE;
            end
        end
        TRAP_REND: begin
            if (xo_temp == x_reg[1] && yo_temp == y_reg[1])
                next_state = IDLE;
            else
                next_state = TRAP_REND;
        end
        CIR_LINE: next_state = IDLE;
        AREA: next_state = IDLE;
        default: next_state = 2'b00;
    endcase
end

always @(*) begin 
    if (&counter)
        counter_temp = 2'b00;
    else if (curr_state == EXE)
        counter_temp = counter + 2'b01;
    else
        counter_temp = 2'b00;
end
//==============================================//
//                  Input Block                 //
//==============================================//
genvar idx;

generate
    for (idx=0; idx<3; idx=idx+1) begin
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)begin
                x_reg[idx] <= 0;
                y_reg[idx] <= 0;
            end
            else if(in_valid) begin
                x_reg[idx] <= x_reg[idx+1];
                y_reg[idx] <= y_reg[idx+1];
            end
       end
    end
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)begin
                x_reg[3] <= 0;
                y_reg[3] <= 0;
            end
            else if(in_valid) begin
                x_reg[3] <= xi;
                y_reg[3] <= yi;
            end
            
        end
endgenerate
//==============================================//
//              Calculation Block1              //
//==============================================//
wire signed[8:0] part_y, part_xl, part_xr;

assign part_y = y_reg[0] - y_reg[2];
assign part_xl = x_reg[0] - x_reg[2];
assign part_xr = x_reg[1] - x_reg[3];

reg signed[8:0] count_x, count_y;
wire change_line_x, change_line_y;

reg signed[16:0] bound_left;
reg signed[16:0] bound_right;
reg signed[16:0] answer_xl1, answer_xl2, answer_xr1, answer_xr2;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_x <= 0;
        count_y <= 0;
    end else begin
        count_x <= (curr_state == TRAP_REND && !change_line_x) ? count_x + 1 : 0;
        count_y <= (curr_state == TRAP_REND && !change_line_y) ? count_y + 1 :
                    (curr_state == TRAP_REND && change_line_y) ? count_y : 0;
    end
end

assign change_line_x = (count_x == (bound_right - bound_left)) ? 1 : 0;
assign change_line_y = (change_line_x) ? 0 : 1;

// Calculate X-coordinate
always @(*) begin   

    answer_xl1 = (x_reg[2] + count_y * part_xl / part_y);
    answer_xl2 = answer_xl1 - 1;

    answer_xr1 = (x_reg[3] + count_y * part_xr / part_y);
    answer_xr2 = answer_xr1 - 1;
    
    if (part_xl * part_y < 0)
        bound_left = (count_y * part_xl % part_y == 0) ? answer_xl1 : answer_xl2;
    else
        bound_left = answer_xl1;
    
    if (part_xr * part_y < 0)
        bound_right = (count_y * part_xr % part_y == 0) ? answer_xr1 : answer_xr2;
    else
        bound_right = answer_xr1;
end



//==============================================//
//              Calculation Block2              //
//==============================================//
reg signed[8:0] a, b;
reg signed[16:0] c, line;
reg signed[50:0] square_A, square_B, square_R;
always @(*) begin
    if(curr_state == CIR_LINE) begin
        a = y_reg[0] - y_reg[1];
        b = x_reg[1] - x_reg[0];
        c = x_reg[0]*y_reg[1] - x_reg[1]*y_reg[0];

        line = a*x_reg[2] + b*y_reg[2] + c;
        square_A = line*line;
        square_B = a*a+b*b;
        square_R = (x_reg[2] - x_reg[3])*(x_reg[2] - x_reg[3]) + (y_reg[2] - y_reg[3])*(y_reg[2] - y_reg[3]);
    end
    else begin
        a=0;
        b=0;
        c=0;

        line=0;
        square_A=0;
        square_B=0;
        square_R=0;
    end
end
//==============================================//
//              Calculation Block3              //
//==============================================//
reg signed[8:0] part1, part2, part3, part4;
reg signed[16:0] area_pre;
reg signed[16:0] area;
always @(*) begin
    if(curr_state == AREA) begin
        part1 = y_reg[1] - y_reg[3];
        part2 = x_reg[0] - x_reg[2];
        part3 = y_reg[0] - y_reg[2];
        part4 = x_reg[3] - x_reg[1];
        area_pre = (part1*part2 + part3*part4)/2;
        area = (area_pre > 0) ? area_pre : -1*area_pre;
    end
    else begin
        part1=0;
        part2=0;
        part3=0;
        part4=0;
        area_pre=0;
        area=0;

    end
end



//==============================================//
//                Output Block                  //
//==============================================//
// Valid signal generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 0;
    else
        out_valid <= (curr_state == TRAP_REND || curr_state == CIR_LINE || curr_state == AREA);
end

// X-coordinate calculation
always @(*) begin
    case (curr_state)
        TRAP_REND: xo_temp = bound_left + count_x;
        AREA: xo_temp = area[15:8];
        default: xo_temp = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        xo <= 0;
    else
        xo <= xo_temp;
end

// Y-coordinate calculation
always @(*) begin
    case (curr_state)
        TRAP_REND: yo_temp = y_reg[2] + count_y;
        CIR_LINE: begin
            if (square_A > square_B * square_R)
                yo_temp = 0;
            else if (square_A == square_B * square_R)
                yo_temp = 2;
            else
                yo_temp = 1;
        end
        AREA: yo_temp = area[7:0];
        default: yo_temp = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        yo <= 0;
    else
        yo <= yo_temp;
end

endmodule 
