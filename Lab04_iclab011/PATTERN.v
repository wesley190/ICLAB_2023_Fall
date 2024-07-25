//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network
//   Author     		: Jia-Yu Lee (maggie8905121@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME      50.0
`define SEED_NUMBER     28825252
`define PATTERN_NUMBER 10000

module PATTERN(
    //Output Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,
    //Input Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg          clk, rst_n, in_valid;
output reg [31:0]  Img;
output reg [31:0]  Kernel;
output reg [31:0]  Weight;
output reg  [ 1:0]  Opt;
input           out_valid;
input   [31:0]  out;

reg [31:0] input_img [0:95];
reg [31:0] input_kernel [0:26];
reg [31:0] input_weight [0:3];
reg [1:0] input_opt;
reg [31:0] golden_out;
//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;

integer pat_read,out_read;
integer PAT_NUM;
integer total_latency, lat;
integer i_pat,i;
real out_fp, golden_out_fp, dif;
real CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;
initial begin
    pat_read = $fopen("../00_TESTBED/input.txt", "r");
    out_read = $fopen("../00_TESTBED/output.txt", "r");
    reset_signal_task;
    i_pat = 0;
    total_latency = 0;
    $fscanf(pat_read, "%d", PAT_NUM);
    //PAT_NUM
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        total_latency = total_latency + lat;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);
    $fclose(out_read);
    YOU_PASS_task;
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
task reset_signal_task; begin
    rst_n = 1'b1;
    in_valid = 1'b0;
    force clk = 1'b0;
    #(0.5*CYCLE); rst_n = 1'b0;
    #(CYCLE);
    if(out_valid!==0 || out!==0)begin
        $display("*************************************************************************");
        $display("");
        $display("                Output should be 0 after RESET at %4t ",$time);
        $display("");
        $display("*************************************************************************");
        $finish;
    end
    #(CYCLE); rst_n = 1'b1;
    #(CYCLE); release clk;
end 
endtask
task input_task; begin
    $fscanf(out_read, "%h",golden_out);
   $fscanf(pat_read, "%d",input_opt);
   for(i=0;i<96;i=i+1)begin
    $fscanf(pat_read, "%h",input_img[i]);
   end
   for(i=0;i<27;i=i+1)begin
    $fscanf(pat_read, "%h",input_kernel[i]);
   end
   for(i=0;i<4;i=i+1)begin
    $fscanf(pat_read, "%h",input_weight[i]);
   end
   repeat($urandom_range(3,5)) @(negedge clk);
   in_valid = 1'b1;
   for(i=0;i<96;i=i+1)begin
    Img = input_img[i];
    if(i<27) Kernel = input_kernel[i];
    else Kernel = 'bx;
    if(i<4) Weight = input_weight[i];
    else Weight = 'bx;
    if(i<1) Opt = input_opt;
    else Opt = 'bx;   
    if(out_valid)begin
        $display("*************************************************************************");
        $display("");
        $display("        The out_valid cannot overlap with in_valid!");
        $display("");
        $display("*************************************************************************");
		$finish;
    end
    @(negedge clk);
    end
    
   in_valid = 1'b0;
   Img = 'bx;
end endtask

task out_rst_task; begin
		if(out !== 0) begin
			repeat(2)@(negedge clk);
            $display("*************************************************************************");
            $display("");
            $display("        out_data should be reset when your out_valid is low!");
            $display("");
            $display("*************************************************************************");
			$finish;
		end
end endtask

task wait_out_valid_task; begin
   lat = -1;
	while(out_valid === 0) begin
		lat = lat + 1;
        out_rst_task;
		if(lat >= 1000) begin
			repeat(2)@(negedge clk);
            $display("*************************************************************************");
            $display("");
            $display("            The execution latency are over 1000 cycles");
            $display("");
            $display("*************************************************************************");
			$finish;
		end
	@(negedge clk);
	end
    total_latency = total_latency + lat;
end endtask

task check_ans_task; begin
    out_fp = $bitstoshortreal(out);
    golden_out_fp = $bitstoshortreal(golden_out);
    dif    = $abs(out_fp - golden_out_fp)/golden_out_fp;
    if(out!=golden_out)begin
        $display("*************************************************************************");
        $display("*                                                                       *");
        $display("*  The out_data should be correct when out_valid is high!               *");
        $display("*  Your        : %08h %22.16f                      *", out, out_fp);
        $display("*  Gloden      : %08h %22.16f                      *", golden_out, golden_out_fp);
        $display("*  Difference  :            %12.8f                              *", dif);
        $display("*                                                                       *");
        $display("*************************************************************************");
        repeat(2)@(negedge clk);
        $finish;
    end    
    @(negedge clk);
    if(out_valid)begin
        $display("*************************************************************************");
        $display("");
        $display("            out_valid and out_data must be asserted in only one cycle!");
        $display("");
        $display("*************************************************************************");
        repeat(2)@(negedge clk);
		$finish;
    end
end endtask

task YOU_PASS_task; begin
  $display("***********************************************************************");
  $display("*                           \033[0;32mCongratulations!\033[m                          *");
  $display("*  Your execution cycles = %18d   cycles                *", total_latency);
  $display("*  Your clock period     = %20.1f ns                    *", CYCLE);
  $display("*  Total Latency         = %20.1f ns                    *", total_latency*CYCLE);
  $display("***********************************************************************");
  $finish;
end endtask

endmodule


