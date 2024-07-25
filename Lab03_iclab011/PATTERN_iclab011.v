`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
    AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [12:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data; 

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;

real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;
integer pat_read;
integer PAT_NUM;
integer total_latency, latency;
integer assert_cycle;
integer i_pat, a, idx;

initial begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r");
    reset_signal_task;

    i_pat = 0;
    total_latency = 0;
    $fscanf(pat_read, "%d", PAT_NUM);
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        $display("PASS input NO.%4d", i_pat);
        wait_out_valid_task;
        check_ans_task;
        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);

    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM);
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);
    YOU_PASS_task;
end
//////////////////////////////////////////////////////////////////////
// Wire and reg
//////////////////////////////////////////////////////////////////////
reg [63:0] golden_data;
reg [63:0] check_temp;
reg [7:0] check_temp_1[0:7], golden_data_1[0:7];
reg direc;
reg [12:0] addr_dram_temp;
reg [15:0] addr_sd_temp;


//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////

task reset_signal_task; begin
    rst_n = 'b1;
    in_valid = 'b0;
    direction = 'bx;
    addr_dram = 'bx;
    addr_sd = 'bx;
    total_latency = 0;
    force clk = 0;

    #10; rst_n = 0;
    #10; rst_n = 1;
    if(out_valid !== 1'b0 || out_data !== 'b0|| AW_ADDR !== 'b0 || AW_VALID !== 'b0 || W_VALID !== 'b0 
        || W_DATA !== 'b0 || B_READY !== 'b0 || AR_ADDR !== 'b0 || AR_VALID !== 'b0 || R_READY !== 'b0 || MOSI !== 'b1) begin
        $display("************************************************************");  
        $display("                       SPEC MAIN-1 FAIL                   ");    
        $display("*  Output signal should be 0 after initial RESET at %8t   *",$time);
        $display("************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end

    
    #10; release clk;

end endtask 

task input_task; begin
    in_valid = 1;
    a = $fscanf(pat_read, "%d %d %d", direction, addr_dram, addr_sd);
    direc = direction;
    addr_dram_temp = addr_dram;
    addr_sd_temp = addr_sd;
    @(negedge clk);

    direction = 'bx;
    addr_dram = 'bx;
    addr_sd = 'bx;
    in_valid = 0;
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
        if(out_data !== 'b0) begin
        $display("********************************************************");     
        $display("                     SPEC MAIN-2 FAIL                   ");
        $display("*  The out_data should be reset when your out_valid is low. *");//over max
        $display("********************************************************");
        repeat(2)@(negedge clk);
        $finish;
        end
      latency = latency + 1;
      if( latency == 10000) begin
          $display("********************************************************");     
          $display("                     SPEC MAIN-3 FAIL                   ");
          $display("*  The execution latency are over 10000 cycles  at %8t   *",$time);//over max
          $display("********************************************************");
        repeat(2)@(negedge clk);
        $finish;
      end
     @(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    assert_cycle = 0;
    if (direc == 0) begin
        // Read from DRAM and write to SD card
        golden_data = u_DRAM.DRAM[addr_dram_temp];
        

    end else if (direc == 1) begin
        golden_data = u_SD.SD[addr_sd_temp];

        // Read from SD card and write to DRAM
    end else begin
        // Invalid direction
        $display("Invalid direction: %d at pattern %d", direction, i_pat);
        YOU_FAIL_task;
    end
    golden_data_1[7] = golden_data[63:56];
    golden_data_1[6] = golden_data[55:48];
    golden_data_1[5] = golden_data[47:40];
    golden_data_1[4] = golden_data[39:32];
    golden_data_1[3] = golden_data[31:24];
    golden_data_1[2] = golden_data[23:16];
    golden_data_1[1] = golden_data[15:8];
    golden_data_1[0] = golden_data[7:0];

    idx = 7;
    while(out_valid === 1) begin
        

        if(assert_cycle == 8)begin
          $display("********************************************************");     
          $display("                     SPEC MAIN-4 FAIL                   ");
          $display("*  The out_valid and out_data must be asserted in 8 cycles. *");//over max
          $display("********************************************************");
          repeat(2)@(negedge clk);
        $finish;
        end

        if( direc == 0 && golden_data !== u_SD.SD[addr_sd_temp])begin
          $display("********************************************************");     
          $display("                        SPEC MAIN-6 FAIL                   ");
          $display("*  The data in the DRAM and SD card should be correct when out_valid is high. *");//over max
          $display("********************************************************");
          repeat(2)@(negedge clk);
        $finish;
        end

        
        if( direc == 1 && golden_data !== u_DRAM.DRAM[addr_dram_temp])begin
          $display("********************************************************");     
          $display("                        SPEC MAIN-6 FAIL                   ");
          $display("*  The data in the DRAM and SD card should be correct when out_valid is high. *");//over max
          $display("********************************************************");
          repeat(2)@(negedge clk);
        $finish;
        end

        check_temp_1[idx] = out_data;

        if(golden_data_1[idx] !== check_temp_1[idx])begin
            $display("********************************************************");     
            $display("                     SPEC MAIN-5 FAIL                   ");
            $display("*  The out_data should be correct when out_valid is high *");//over max
            $display("********************************************************");
            repeat(2)@(negedge clk);
            $finish;
        end



        idx = idx-1;

        /*check_temp_1[7] = out_data;
        if(golden_data_1[7] !== check_temp_1[7])begin
            $display("********************************************************");     
            $display("                     SPEC MAIN-5 FAIL                   ");
            $display("*  The out_data should be correct when out_valid is high *");//over max
            $display("********************************************************");
            repeat(2)@(negedge clk);
            $finish;
        end
        for(idx = 6; idx>=0 ; idx = idx-1) begin
            @(negedge clk);
            check_temp_1[idx] = out_data;
            if(golden_data_1[idx] !== check_temp_1[idx])begin
                $display("********************************************************");     
                $display("                     SPEC MAIN-5 FAIL                   ");
                $display("*  The out_data should be correct when out_valid is high *");//over max
                $display("********************************************************");
                repeat(2)@(negedge clk);
                $finish;
            end
            
        end*/
    
    assert_cycle = assert_cycle+1;
    @(negedge clk);
    end

    if(assert_cycle < 8)begin
        $display("********************************************************");     
        $display("                     SPEC MAIN-4 FAIL                   ");
        $display("*  The out_valid and out_data must be asserted in 8 cycles. *");//over max
        $display("********************************************************");
        repeat(2)@(negedge clk);
        $finish;
    end 
    else begin
        @(negedge clk);    
    end


    
end endtask



//////////////////////////////////////////////////////////////////////

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    // write address channel
    .AW_ADDR(AW_ADDR),
    .AW_VALID(AW_VALID),
    .AW_READY(AW_READY),
    // write data channel
    .W_VALID(W_VALID),
    .W_DATA(W_DATA),
    .W_READY(W_READY),
    // write response channel
    .B_VALID(B_VALID),
    .B_RESP(B_RESP),
    .B_READY(B_READY),
    // read address channel
    .AR_ADDR(AR_ADDR),
    .AR_VALID(AR_VALID),
    .AR_READY(AR_READY),
    // read data channel
    .R_DATA(R_DATA),
    .R_VALID(R_VALID),
    .R_RESP(R_RESP),
    .R_READY(R_READY)
);

pseudo_SD u_SD (
    .clk(clk),
    .MOSI(MOSI),
    .MISO(MISO)
);

endmodule