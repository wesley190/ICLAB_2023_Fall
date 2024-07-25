//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//      Date        : 2023/10
//      Version     : v1.0
//      File Name   : SORT_IP.v
//      Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output [IP_WIDTH*4-1:0] OUT_character;
genvar i,j,k;
reg clk;
wire [3:0] char_comb[0:IP_WIDTH-1];
//reg [3:0] char[0:IP_WIDTH-1];
wire [4:0] weight_comb[0:IP_WIDTH-1];
//reg[4:0] weight[0:IP_WIDTH-1];

// ===============================================================
// Design
// ===============================================================

generate
    for(i = 0;i<IP_WIDTH;i = i+1)begin
        
        assign char_comb[i] = IN_character[(IP_WIDTH-i)*4-1:(IP_WIDTH-i-1)*4];
        assign weight_comb[i] = IN_weight[(IP_WIDTH-i)*5-1:(IP_WIDTH-i-1)*5];
        
    end
endgenerate

/*generate
    for(i=0;i<IP_WIDTH;i=i+1)begin
        always @(*) begin 
            char[i] = char_comb[i];
            weight[i] = weight_comb[i];
        end
    end
endgenerate*/
reg [3:0] char_big[0:18], char_sma[0:18];
reg [4:0] weight_big[0:18], weight_sma[0:18];
generate
    case (IP_WIDTH)
        2: begin
            comp C1(.char1(char_comb[0]), .char2(char_comb[1]), .weight1(weight_comb[0]),
                     .weight2(weight_comb[1]), .char_bigger(char_big[0]), .char_small(char_sma[0]));
            assign OUT_character = {char_big[0], char_sma[0]};
        end
        3: begin
            comp C2(.char1(char_comb[0]), .char2(char_comb[2]), .weight1(weight_comb[0]),.weight2(weight_comb[2]),
             .char_bigger(char_big[0]), .char_small(char_sma[0]), .weight_bigger(weight_big[0]), .weight_small(weight_sma[0]));

            comp C3(.char1(char_big[0]), .char2(char_comb[1]), .weight1(weight_big[0]),.weight2(weight_comb[1]),
             .char_bigger(char_big[1]), .char_small(char_sma[1]), .weight_bigger(weight_big[1]), .weight_small(weight_sma[1]));

            comp C4(.char1(char_sma[1]), .char2(char_sma[0]), .weight1(weight_sma[1]),.weight2(weight_sma[0]),
             .char_bigger(char_big[2]), .char_small(char_sma[2]), .weight_bigger(weight_big[2]), .weight_small(weight_sma[2]));
            assign OUT_character = {char_big[1], char_big[2], char_sma[2]};
        end
        4: begin
            comp C5(.char1(char_comb[0]), .char2(char_comb[2]), .weight1(weight_comb[0]),.weight2(weight_comb[2]),
             .char_bigger(char_big[0]), .char_small(char_sma[0]), .weight_bigger(weight_big[0]), .weight_small(weight_sma[0]));
            comp C6(.char1(char_comb[1]), .char2(char_comb[3]), .weight1(weight_comb[1]),.weight2(weight_comb[3]),
             .char_bigger(char_big[1]), .char_small(char_sma[1]), .weight_bigger(weight_big[1]), .weight_small(weight_sma[1]));

            comp C7(.char1(char_big[0]), .char2(char_big[1]), .weight1(weight_big[0]),.weight2(weight_big[1]),
             .char_bigger(char_big[2]), .char_small(char_sma[2]), .weight_bigger(weight_big[2]), .weight_small(weight_sma[2]));
            comp C8(.char1(char_sma[0]), .char2(char_sma[1]), .weight1(weight_sma[0]),.weight2(weight_sma[1]),
             .char_bigger(char_big[3]), .char_small(char_sma[3]), .weight_bigger(weight_big[3]), .weight_small(weight_sma[3]));

            comp C9(.char1(char_sma[2]), .char2(char_big[3]), .weight1(weight_sma[2]),.weight2(weight_big[3]),
             .char_bigger(char_big[4]), .char_small(char_sma[4]), .weight_bigger(weight_big[4]), .weight_small(weight_sma[4]));

            assign OUT_character = {char_big[2], char_big[4], char_sma[4], char_sma[3]};
        end
        5: begin
            comp C10(.char1(char_comb[0]), .char2(char_comb[3]), .weight1(weight_comb[0]),.weight2(weight_comb[3]),
             .char_bigger(char_big[0]), .char_small(char_sma[0]), .weight_bigger(weight_big[0]), .weight_small(weight_sma[0]));
            comp C11(.char1(char_comb[1]), .char2(char_comb[4]), .weight1(weight_comb[1]),.weight2(weight_comb[4]),
             .char_bigger(char_big[1]), .char_small(char_sma[1]), .weight_bigger(weight_big[1]), .weight_small(weight_sma[1]));

            comp C12(.char1(char_big[0]), .char2(char_comb[2]), .weight1(weight_big[0]),.weight2(weight_comb[2]),
             .char_bigger(char_big[2]), .char_small(char_sma[2]), .weight_bigger(weight_big[2]), .weight_small(weight_sma[2]));
            comp C13(.char1(char_big[1]), .char2(char_sma[0]), .weight1(weight_big[1]),.weight2(weight_sma[0]),
             .char_bigger(char_big[3]), .char_small(char_sma[3]), .weight_bigger(weight_big[3]), .weight_small(weight_sma[3]));

            comp C14(.char1(char_big[2]), .char2(char_big[3]), .weight1(weight_big[2]),.weight2(weight_big[3]),
             .char_bigger(char_big[4]), .char_small(char_sma[4]), .weight_bigger(weight_big[4]), .weight_small(weight_sma[4]));
            comp C15(.char1(char_sma[2]), .char2(char_sma[1]), .weight1(weight_sma[2]),.weight2(weight_sma[1]),
             .char_bigger(char_big[5]), .char_small(char_sma[5]), .weight_bigger(weight_big[5]), .weight_small(weight_sma[5]));

            comp C16(.char1(char_sma[4]), .char2(char_big[5]), .weight1(weight_sma[4]),.weight2(weight_big[5]),
             .char_bigger(char_big[6]), .char_small(char_sma[6]), .weight_bigger(weight_big[6]), .weight_small(weight_sma[6]));
            comp C17(.char1(char_sma[3]), .char2(char_sma[5]), .weight1(weight_sma[3]),.weight2(weight_sma[5]),
             .char_bigger(char_big[7]), .char_small(char_sma[7]), .weight_bigger(weight_big[7]), .weight_small(weight_sma[7]));

            comp C18(.char1(char_sma[6]), .char2(char_big[7]), .weight1(weight_sma[6]),.weight2(weight_big[7]),
             .char_bigger(char_big[8]), .char_small(char_sma[8]), .weight_bigger(weight_big[8]), .weight_small(weight_sma[8]));
            assign OUT_character = {char_big[4], char_big[6], char_big[8], char_sma[8], char_sma[7]};
        end
        6: begin
            comp C19(.char1(char_comb[1]), .char2(char_comb[3]), .weight1(weight_comb[1]),.weight2(weight_comb[3]),
             .char_bigger(char_big[0]), .char_small(char_sma[0]), .weight_bigger(weight_big[0]), .weight_small(weight_sma[0]));
            comp C20(.char1(char_comb[0]), .char2(char_comb[5]), .weight1(weight_comb[0]),.weight2(weight_comb[5]),
             .char_bigger(char_big[1]), .char_small(char_sma[1]), .weight_bigger(weight_big[1]), .weight_small(weight_sma[1]));
            comp C21(.char1(char_comb[2]), .char2(char_comb[4]), .weight1(weight_comb[2]),.weight2(weight_comb[4]),
             .char_bigger(char_big[2]), .char_small(char_sma[2]), .weight_bigger(weight_big[2]), .weight_small(weight_sma[2]));

            comp C22(.char1(char_big[0]), .char2(char_big[2]), .weight1(weight_big[0]),.weight2(weight_big[2]),
             .char_bigger(char_big[3]), .char_small(char_sma[3]), .weight_bigger(weight_big[3]), .weight_small(weight_sma[3]));
            comp C23(.char1(char_sma[0]), .char2(char_sma[2]), .weight1(weight_sma[0]),.weight2(weight_sma[2]),
             .char_bigger(char_big[4]), .char_small(char_sma[4]), .weight_bigger(weight_big[4]), .weight_small(weight_sma[4]));

            comp C24(.char1(char_big[1]), .char2(char_big[4]), .weight1(weight_big[1]),.weight2(weight_big[4]),
             .char_bigger(char_big[5]), .char_small(char_sma[5]), .weight_bigger(weight_big[5]), .weight_small(weight_sma[5]));
            comp C25(.char1(char_sma[3]), .char2(char_sma[1]), .weight1(weight_sma[3]),.weight2(weight_sma[1]),
             .char_bigger(char_big[6]), .char_small(char_sma[6]), .weight_bigger(weight_big[6]), .weight_small(weight_sma[6]));

            comp C26(.char1(char_big[5]), .char2(char_big[3]), .weight1(weight_big[5]),.weight2(weight_big[3]),
             .char_bigger(char_big[7]), .char_small(char_sma[7]), .weight_bigger(weight_big[7]), .weight_small(weight_sma[7]));
            comp C27(.char1(char_big[6]), .char2(char_sma[5]), .weight1(weight_big[6]),.weight2(weight_sma[5]),
             .char_bigger(char_big[8]), .char_small(char_sma[8]), .weight_bigger(weight_big[8]), .weight_small(weight_sma[8]));
            comp C28(.char1(char_sma[4]), .char2(char_sma[6]), .weight1(weight_sma[4]),.weight2(weight_sma[6]),
             .char_bigger(char_big[9]), .char_small(char_sma[9]), .weight_bigger(weight_big[9]), .weight_small(weight_sma[9]));

            comp C29(.char1(char_sma[7]), .char2(char_big[8]), .weight1(weight_sma[7]),.weight2(weight_big[8]),
             .char_bigger(char_big[10]), .char_small(char_sma[10]), .weight_bigger(weight_big[10]), .weight_small(weight_sma[10]));
            comp C30(.char1(char_sma[8]), .char2(char_big[9]), .weight1(weight_sma[8]),.weight2(weight_big[9]),
             .char_bigger(char_big[11]), .char_small(char_sma[11]), .weight_bigger(weight_big[11]), .weight_small(weight_sma[11]));
            assign OUT_character = {char_big[7], char_big[10], char_sma[10], char_big[11], char_sma[11], char_sma[9]};
        end
        7: begin
           comp C31(.char1(char_comb[0]), .char2(char_comb[6]), .weight1(weight_comb[0]),.weight2(weight_comb[6]),
             .char_bigger(char_big[0]), .char_small(char_sma[0]), .weight_bigger(weight_big[0]), .weight_small(weight_sma[0]));
           comp C32(.char1(char_comb[2]), .char2(char_comb[3]), .weight1(weight_comb[2]),.weight2(weight_comb[3]),
             .char_bigger(char_big[1]), .char_small(char_sma[1]), .weight_bigger(weight_big[1]), .weight_small(weight_sma[1]));
           comp C33(.char1(char_comb[4]), .char2(char_comb[5]), .weight1(weight_comb[4]),.weight2(weight_comb[5]),
             .char_bigger(char_big[2]), .char_small(char_sma[2]), .weight_bigger(weight_big[2]), .weight_small(weight_sma[2]));

           comp C34(.char1(char_comb[1]), .char2(char_big[2]), .weight1(weight_comb[1]),.weight2(weight_big[2]),
             .char_bigger(char_big[3]), .char_small(char_sma[3]), .weight_bigger(weight_big[3]), .weight_small(weight_sma[3]));
           comp C35(.char1(char_big[0]), .char2(char_big[1]), .weight1(weight_big[0]),.weight2(weight_big[1]),
             .char_bigger(char_big[4]), .char_small(char_sma[4]), .weight_bigger(weight_big[4]), .weight_small(weight_sma[4]));
           comp C36(.char1(char_sma[1]), .char2(char_sma[0]), .weight1(weight_sma[1]),.weight2(weight_sma[0]),
             .char_bigger(char_big[5]), .char_small(char_sma[5]), .weight_bigger(weight_big[5]), .weight_small(weight_sma[5]));

           comp C37(.char1(char_big[4]), .char2(char_big[3]), .weight1(weight_big[4]),.weight2(weight_big[3]),
             .char_bigger(char_big[6]), .char_small(char_sma[6]), .weight_bigger(weight_big[6]), .weight_small(weight_sma[6]));
           comp C38(.char1(char_big[5]), .char2(char_sma[3]), .weight1(weight_big[5]),.weight2(weight_sma[3]),
             .char_bigger(char_big[7]), .char_small(char_sma[7]), .weight_bigger(weight_big[7]), .weight_small(weight_sma[7]));
           comp C39(.char1(char_sma[4]), .char2(char_sma[2]), .weight1(weight_sma[4]),.weight2(weight_sma[2]),
             .char_bigger(char_big[8]), .char_small(char_sma[8]), .weight_bigger(weight_big[8]), .weight_small(weight_sma[8]));

           comp C40(.char1(char_sma[6]), .char2(char_big[8]), .weight1(weight_sma[6]),.weight2(weight_big[8]),
             .char_bigger(char_big[9]), .char_small(char_sma[9]), .weight_bigger(weight_big[9]), .weight_small(weight_sma[9]));
           comp C41(.char1(char_sma[7]), .char2(char_sma[5]), .weight1(weight_sma[7]),.weight2(weight_sma[5]),
             .char_bigger(char_big[10]), .char_small(char_sma[10]), .weight_bigger(weight_big[10]), .weight_small(weight_sma[10]));

           comp C42(.char1(char_sma[9]), .char2(char_big[7]), .weight1(weight_sma[9]),.weight2(weight_big[7]),
             .char_bigger(char_big[11]), .char_small(char_sma[11]), .weight_bigger(weight_big[11]), .weight_small(weight_sma[11]));
           comp C43(.char1(char_big[10]), .char2(char_sma[8]), .weight1(weight_big[10]),.weight2(weight_sma[8]),
             .char_bigger(char_big[12]), .char_small(char_sma[12]), .weight_bigger(weight_big[12]), .weight_small(weight_sma[12]));

           comp C44(.char1(char_big[9]), .char2(char_big[11]), .weight1(weight_big[9]),.weight2(weight_big[11]),
             .char_bigger(char_big[13]), .char_small(char_sma[13]), .weight_bigger(weight_big[13]), .weight_small(weight_sma[13]));
           comp C45(.char1(char_sma[11]), .char2(char_big[12]), .weight1(weight_sma[11]),.weight2(weight_big[12]),
             .char_bigger(char_big[14]), .char_small(char_sma[14]), .weight_bigger(weight_big[14]), .weight_small(weight_sma[14]));
           comp C46(.char1(char_sma[12]), .char2(char_sma[10]), .weight1(weight_sma[12]),.weight2(weight_sma[10]),
             .char_bigger(char_big[15]), .char_small(char_sma[15]), .weight_bigger(weight_big[15]), .weight_small(weight_sma[15]));

           assign OUT_character = {char_big[6], char_big[13], char_sma[13], char_big[14], char_sma[14], char_big[15], char_sma[15]};
        end
        8: begin
            comp C47(.char1(char_comb[1]), .char2(char_comb[3]), .weight1(weight_comb[1]),.weight2(weight_comb[3]),
             .char_bigger(char_big[0]), .char_small(char_sma[0]), .weight_bigger(weight_big[0]), .weight_small(weight_sma[0]));
            comp C48(.char1(char_comb[4]), .char2(char_comb[6]), .weight1(weight_comb[4]),.weight2(weight_comb[6]),
             .char_bigger(char_big[1]), .char_small(char_sma[1]), .weight_bigger(weight_big[1]), .weight_small(weight_sma[1]));
            comp C49(.char1(char_comb[0]), .char2(char_comb[2]), .weight1(weight_comb[0]),.weight2(weight_comb[2]),
             .char_bigger(char_big[2]), .char_small(char_sma[2]), .weight_bigger(weight_big[2]), .weight_small(weight_sma[2]));
            comp C50(.char1(char_comb[5]), .char2(char_comb[7]), .weight1(weight_comb[5]),.weight2(weight_comb[7]),
             .char_bigger(char_big[3]), .char_small(char_sma[3]), .weight_bigger(weight_big[3]), .weight_small(weight_sma[3]));

            comp C51(.char1(char_big[2]), .char2(char_big[1]), .weight1(weight_big[2]),.weight2(weight_big[1]),
             .char_bigger(char_big[4]), .char_small(char_sma[4]), .weight_bigger(weight_big[4]), .weight_small(weight_sma[4]));
            comp C52(.char1(char_big[0]), .char2(char_big[3]), .weight1(weight_big[0]),.weight2(weight_big[3]),
             .char_bigger(char_big[5]), .char_small(char_sma[5]), .weight_bigger(weight_big[5]), .weight_small(weight_sma[5]));
            comp C53(.char1(char_sma[2]), .char2(char_sma[1]), .weight1(weight_sma[2]),.weight2(weight_sma[1]),
             .char_bigger(char_big[6]), .char_small(char_sma[6]), .weight_bigger(weight_big[6]), .weight_small(weight_sma[6]));
            comp C54(.char1(char_sma[0]), .char2(char_sma[3]), .weight1(weight_sma[0]),.weight2(weight_sma[3]),
             .char_bigger(char_big[7]), .char_small(char_sma[7]), .weight_bigger(weight_big[7]), .weight_small(weight_sma[7]));

            comp C55(.char1(char_big[4]), .char2(char_big[5]), .weight1(weight_big[4]),.weight2(weight_big[5]),
             .char_bigger(char_big[8]), .char_small(char_sma[8]), .weight_bigger(weight_big[8]), .weight_small(weight_sma[8]));
            comp C56(.char1(char_big[6]), .char2(char_big[7]), .weight1(weight_big[6]),.weight2(weight_big[7]),
             .char_bigger(char_big[9]), .char_small(char_sma[9]), .weight_bigger(weight_big[9]), .weight_small(weight_sma[9]));
            comp C57(.char1(char_sma[4]), .char2(char_sma[5]), .weight1(weight_sma[4]),.weight2(weight_sma[5]),
             .char_bigger(char_big[10]), .char_small(char_sma[10]), .weight_bigger(weight_big[10]), .weight_small(weight_sma[10]));
            comp C58(.char1(char_sma[6]), .char2(char_sma[7]), .weight1(weight_sma[6]),.weight2(weight_sma[7]),
             .char_bigger(char_big[11]), .char_small(char_sma[11]), .weight_bigger(weight_big[11]), .weight_small(weight_sma[11]));

            comp C59(.char1(char_big[9]), .char2(char_big[10]), .weight1(weight_big[9]),.weight2(weight_big[10]),
             .char_bigger(char_big[12]), .char_small(char_sma[12]), .weight_bigger(weight_big[12]), .weight_small(weight_sma[12]));
            comp C60(.char1(char_sma[9]), .char2(char_sma[10]), .weight1(weight_sma[9]),.weight2(weight_sma[10]),
             .char_bigger(char_big[13]), .char_small(char_sma[13]), .weight_bigger(weight_big[13]), .weight_small(weight_sma[13]));

            comp C61(.char1(char_sma[8]), .char2(char_sma[12]), .weight1(weight_sma[8]),.weight2(weight_sma[12]),
             .char_bigger(char_big[14]), .char_small(char_sma[14]), .weight_bigger(weight_big[14]), .weight_small(weight_sma[14]));
            comp C62(.char1(char_big[13]), .char2(char_big[11]), .weight1(weight_big[13]),.weight2(weight_big[11]),
             .char_bigger(char_big[15]), .char_small(char_sma[15]), .weight_bigger(weight_big[15]), .weight_small(weight_sma[15]));

            comp C63(.char1(char_big[14]), .char2(char_big[12]), .weight1(weight_big[14]),.weight2(weight_big[12]),
             .char_bigger(char_big[16]), .char_small(char_sma[16]), .weight_bigger(weight_big[16]), .weight_small(weight_sma[16]));
            comp C64(.char1(char_big[15]), .char2(char_sma[14]), .weight1(weight_big[15]),.weight2(weight_sma[14]),
             .char_bigger(char_big[17]), .char_small(char_sma[17]), .weight_bigger(weight_big[17]), .weight_small(weight_sma[17]));
            comp C65(.char1(char_sma[13]), .char2(char_sma[15]), .weight1(weight_sma[13]),.weight2(weight_sma[15]),
             .char_bigger(char_big[18]), .char_small(char_sma[18]), .weight_bigger(weight_big[18]), .weight_small(weight_sma[18]));
            assign OUT_character = {char_big[8], char_big[16], char_sma[16], char_big[17], char_sma[17], char_big[18], char_sma[18], char_sma[11]};
        end
         
        default : assign OUT_character = 0;
    endcase
endgenerate


endmodule

module comp (
    char1, char2,
    weight1, weight2,
    char_bigger, char_small,
    weight_bigger, weight_small 
);
    
    input [3:0] char1, char2;
    input [4:0] weight1, weight2;
    output reg [3:0] char_bigger, char_small;
    output reg [4:0] weight_bigger, weight_small;

    always @(*) begin
        if(weight1 > weight2 || ((weight1 == weight2) && (char1>char2)))begin
            weight_bigger = weight1;
            weight_small = weight2;
            char_bigger = char1;
            char_small = char2;
        end
        else begin
            weight_bigger = weight2;
            weight_small = weight1;
            char_bigger = char2;
            char_small = char1;
        end
    end

endmodule