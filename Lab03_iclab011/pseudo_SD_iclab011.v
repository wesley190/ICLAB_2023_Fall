//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : pseudo_SD.v
//   Module Name : pseudo_SD
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_SD (
    clk,
    MOSI,
    MISO
);

input clk;
input MOSI;
output reg MISO;

parameter SD_p_r = "../00_TESTBED/SD_init.dat";

reg [63:0] SD [0:65535];
reg [87:0] read_data;
reg [79:0] write_data;
reg [63:0] finalw_data;
reg [32:0] SD_addr;
reg [7:0] start_token;
reg [5:0] SD_mode;
integer i,pat_read, pat_num, rand_n, counter;

reg [47:0] command;
initial begin
    $readmemh(SD_p_r, SD);
    pat_read = $fopen("../00_TESTBED/Input.txt","r");
    $fscanf(pat_read,"%d",pat_num);
    $display("%d", pat_num);
    for(i = 0; i < pat_num;i = i + 1)begin
        MISO = 1;
        counter = 0;
        read_data = 0;

        input_command_task;
        if(SD_mode === 17)begin
            command_check_task;
            zero_response_task;
            SD_read_task;
            
        end
        else begin
            command_check_task;
            zero_response_task;
            wait_task_2;
            SD_write_task;
            write_response_task;
            busy_task;
        end
        MISO = 1;
    end

end

task YOU_FAIL_task;begin
    $display("*                              FAIL!                                    *");
    $display("*                 Error message from pseudo_SD.v                        *");
    $finish;
end endtask

function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT;
    input [63:0] data;
    reg [15:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'h1021;
    
    begin
        crc = 16'd0;
        for(i = 0;i < 64; i = i + 1)begin
            data_in = data[63 - i];
            data_out = crc[15];
            crc = crc << 1;
            if(data_in ^ data_out)begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end
        
endfunction

//==============================================//
//                  SD read                     //
//==============================================//
task input_command_task;
    MISO = 1;
    while(MOSI !== 0)begin
        @(posedge clk);
    end
    command[47] = MOSI;
    for(i = 46;i >= 0;i = i - 1)begin
        @(posedge clk);
        command[i] = MOSI;      
    end
    SD_mode = command[45:40];
    SD_addr = command[39:8];
endtask

task command_check_task; begin
    
    if(command[47:46] !== 2'b01)begin
        $display("************************************************************");  
        $display("*                      SPEC SD-1 FAIL                      *");
        $display("                 start bit should be 2'b01                  *");
        $display("************************************************************");
        YOU_FAIL_task;
    end
    
    if(SD_mode !== 17 && SD_mode !== 24)begin
        $display("************************************************************");  
        $display("*                      SPEC SD-1 FAIL                      *");
        $display("                 SD_mode should be 17 or 24                  *");
        $display("************************************************************");
        YOU_FAIL_task;
    end
    if(SD_addr > 65535)begin
        $display("************************************************************");  
        $display("*                      SPEC SD-2 FAIL                      *");
        $display("   The address should be within the legal range (0~65535).   *");
        $display("************************************************************");
        YOU_FAIL_task;
    end
    if(command[7:1] !== CRC7(.data(command[47:8])))begin
        $display("************************************************************");  
        $display("*                      SPEC SD-3 FAIL                      *");
        $display("               CRC-7 check should be correct                  *");
        $display("************************************************************");
        YOU_FAIL_task;
    end
    if(command[0] !== 1)begin
        $display("************************************************************");  
        $display("*                      SPEC SD-1 FAIL                      *");
        $display("                  last bit should be 'b1                    *");
        $display("************************************************************");
        YOU_FAIL_task;
    end
end endtask

task zero_response_task;begin
    rand_n = $urandom_range(0,8);
    repeat(rand_n * 8)@(posedge clk);
    
    for(i = 0; i <= 7; i = i + 1)begin
        MISO = 0;
        @(posedge clk);
    end
end endtask 

task SD_read_task;begin
	MISO = 1;
    rand_n = $urandom_range(1,32);
    repeat(rand_n * 8)@(posedge clk);

    read_data = {8'hFE, SD[SD_addr], CRC16_CCITT(.data(SD[SD_addr]))};
    MISO = read_data[87];
    for(i = 86;i >= 0;i = i - 1)begin
        @(posedge clk);
        MISO = read_data[i];
    end
    @(posedge clk);
end endtask





//==============================================//
//                  SD write                     //
//==============================================//
task wait_task_2;
    MISO = 1;
    start_token = 0;
    while(start_token !== 8'b1111_1110)begin
        @(posedge clk);
        start_token[7:0] = {start_token[6:0],MOSI};
        counter = counter + 1;
    end
    if((counter - 8) % 8 != 0 || (counter - 8) === 0)begin
        $display("************************************************************");  
        $display("*                      SPEC SD-5 FAIL                      *");
        $display("             Only integer time units is allowed               *");
        $display("************************************************************");
        YOU_FAIL_task;
    end
    
endtask

task SD_write_task;begin
    MISO = 1;
    for(i = 79;i >= 0; i = i - 1)begin
        @(posedge clk);
        write_data[i] = MOSI;
    end
    finalw_data = write_data[79:16];

    if(write_data[15:0] !== CRC16_CCITT(.data(finalw_data)))begin
        $display("************************************************************");  
        $display("*                      SPEC SD-4 FAIL                      *");
        $display("             CRC-16-CCITT check should be correct             *");
        $display("************************************************************");
        YOU_FAIL_task;
    end
end endtask

reg [7:0] reponse;
assign reponse = 8'b0000_0101;
task write_response_task;
    for(i = 7; i >= 0;i = i - 1)begin
        MISO = reponse[i];
        @(posedge clk);
    end
endtask

task busy_task;
    MISO = 0;
    rand_n = $urandom_range(0 , 32);
    repeat(rand_n * 8)@( posedge clk);

    SD[SD_addr] = finalw_data;
    MISO = 1;
    
endtask


endmodule
