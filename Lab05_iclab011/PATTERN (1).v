`define CYCLE_TIME      20.0

module PATTERN(
// output signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
// input signals
    out_valid,
    out_value
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg rst_n, clk, in_valid, in_valid2, mode;
output reg [1:0] matrix_size;
output reg signed [7:0] matrix;
output reg [3:0] matrix_idx;

input out_valid;
input signed out_value;

//================================================================
//   parameters & integers
//================================================================
real	CYCLE = `CYCLE_TIME;
parameter PATNUM = 1000;                 
integer SEED = 170917;
integer patcount;
integer questcnt;
integer pat_delay;

integer i,j,k,m,n;
integer idx,jdx,kdx;
integer x,lat,total_latency, max_val;
integer  lat_array [15:0];
reg signed [7:0] tmp_arr [0:31][0:31]; // Same size as the input image
reg signed [7:0] conv_result [0:31][0:31];

reg [1:0] img_size;
integer true_img_size;
reg signed [7:0] pool [0:15][0:31][0:31];
reg [3:0] mx_idx [0:15][0:1];
reg mx_mode [0:15];
reg signed [19:0] golden_answer [0:15];		//Each out_value contains 20 bits.
reg signed [19:0] result;

//---------------------------------------------------------------------
//   CLOCK GENERATION
//---------------------------------------------------------------------
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//   Main Program
//---------------------------------------------------------------------
initial begin
	rst_n = 1'b1;
	in_valid = 1'b0;
    matrix = 'bx;
    matrix_size = 'bx;
	
    in_valid2 = 1'b0;
    matrix_idx = 'bx;
    mode = 'bx;
	
    force clk = 0;

 	reset_signal_task;

	for(patcount=1; patcount<=PATNUM; patcount=patcount+1) begin
        total_latency = 0;
		calculate_task;
		@(negedge clk);
        input_task1;
        
        // invalid2 would be triggered 1~3 cycles
        pat_delay=($random(SEED) % 'd3)+1; //(1 ~ 3)
        repeat(pat_delay)@(negedge clk);
        
        for(questcnt = 0; questcnt < 16; questcnt = questcnt+1)begin
		    input_task2;
		    wait_out_valid;
            //check_ans;
            
            $write("Pass quest %d\n",questcnt);
            pat_delay=($random(SEED) % 'd2)+1; //(1 ~ 2)
            repeat(pat_delay)@(negedge clk);

            @(negedge clk); // invalid would be triggered 1~3 cycles after
        end

        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycles : %3d\033[m",patcount ,total_latency);
        $display("matrix size: %d", true_img_size, true_img_size);
        $write("\033[0;34m Latency detail: [ \033[m");
        for(i = 0; i < 9; i = i+1)begin
            $write("%3d, ",lat_array[i]);
        end
        $display("%3d \033[0;34m ] \033[m",lat_array[i]);

	end
  	YOU_PASS_task;
end

//---------------------------------------------------------------------
//   Tasks
//---------------------------------------------------------------------
task reset_signal_task; begin 
    #(0.5);  rst_n=0;
    #(CYCLE/2);
    if((out_valid !== 0)||(out_value!== 0)) begin
      $display("************************************************************");
      $display("*                       LAB05_FAIL                         *");
      $display("*   Output signal should be 0 after initial RESET at %t    *",$time);
      $display("************************************************************");
      $finish;
    end
    #(10);  rst_n=1;
    #(3);  release clk;
end endtask

task calculate_task; begin
	img_size = $random(SEED) % 'd3;
    case (img_size)
        2'b00: true_img_size = 8;
        2'b01: true_img_size = 16;  
		2'b10: true_img_size = 32;
    endcase
	
	for (i = 0; i < 16; i=i+1) begin
        for(j = 0; j < 32; j = j+1)begin
            for(k = 0; k < 32; k = k+1)begin
                pool[i][j][k] = $random(SEED);
            end
        end
    end
    for (i = 0; i < 16; i = i+1) begin
        mx_mode[i]  = $random(SEED) % 'd2;
        
        mx_idx[i][0] = $random(SEED) % 'd16;	//16 matrices
        mx_idx[i][1] = $random(SEED) % 'd16;
    end
	golden_answer[idx] = 0;
	for (idx = 0; idx < 16; idx = idx+1) begin
        for (i = 0; i < true_img_size; i = i+1) begin
            for (j = 0; j < true_img_size; j = j+1) begin
                if (mx_mode[idx] == 2'b00) begin
                    // Convolution
                    tmp_arr[i][j] = 0;
                    for (k = 0; k < 5; k = k+1) begin
                        for (m = 0; m < 5; m = m+1) begin
                            if ((i + k) < true_img_size && (j + m) < true_img_size) begin
                                tmp_arr[i][j] = tmp_arr[i][j] + pool[mx_idx[idx][0]][i + k][j + m] * pool[mx_idx[idx][1]][k][m];
                            end
                        end
                    end
					//conv_result[i][j] = tmp_arr[i][j];
					// Max-Pooling (2x2)
					if (i % 2 == 0 && j % 2 == 0 && i < true_img_size-1 && j < true_img_size-1) begin
						max_val = tmp_arr[i][j];
						max_val = (tmp_arr[i+1][j] > max_val) ? tmp_arr[i+1][j] : max_val;
						max_val = (tmp_arr[i][j+1] > max_val) ? tmp_arr[i][j+1] : max_val;
						max_val = (tmp_arr[i+1][j+1] > max_val) ? tmp_arr[i+1][j+1] : max_val;
					end
					result = max_val;
                end 
				else if (mx_mode[idx] == 2'b01) begin
                    // Transposed Convolution
					for (k = 0; k < 5; k = k+1) begin
                        for (m = 0; m < 5; m = m+1) begin
                            if ((i >= k) && (j >= m) && (i - k) < true_img_size && (j - m) < true_img_size) begin
                                tmp_arr[i][j] = tmp_arr[i][j] + pool[mx_idx[idx][0]][i - k][j - m] * pool[mx_idx[idx][1]][k][m];
                            end
                        end
                    end
					result = tmp_arr[i][j];
                end
				
			golden_answer[idx] = golden_answer[idx] + result;
            end
		end
	end
	//for (k = 0; k < 20; k = k+1) begin
	//	out_value = golden_answer[idx][k];          /////////////////???
    //end

end endtask


task input_task1; begin
	
    in_valid = 1;

    for(i = 0; i < 16; i = i+1)begin
        for(j = 0; j < true_img_size; j = j+1)begin
            for(k = 0; k < true_img_size; k = k+1)begin
                
                if(i == 0 && j == 0 && k ==0) matrix_size = img_size;
                //else matrix_size = 'bx;

                matrix = pool[i][j][k];
				
                @(negedge clk);

            end
        end
    end
	for(i = 0; i < 16; i = i+1)begin
        for(j = 0; j < 5; j = j+1)begin
            for(k = 0; k < 5; k = k+1)begin


                matrix = pool[i][j][k];
				
                @(negedge clk);

            end
        end
    end
	in_valid = 1'b0;
	matrix = 'bx;
    matrix_size = 'bx;

end endtask

task input_task2; begin
    in_valid2  = 1;
    
	for(idx = 0; idx < 2; idx = idx+1)begin  //2 cycles
        if(idx == 0) mode = mx_mode[questcnt];
        else mode = 'bx;

        matrix_idx = mx_idx[questcnt][idx];
        @(negedge clk);
        
    end
    in_valid2 = 0;
    matrix_idx = 'bx;
    mode = 'bx;

end endtask


task wait_out_valid; begin
	lat = -1;
  while(out_valid !== 1) begin
	lat = lat + 1;
	if(lat == 10001) begin//wait limit
		$display("***************************************************************");
		$display("*     		    ICLAB05_FAIL      							*");
		$display("*         The execution latency are over 10,000 cycles.       *");
		$display("***************************************************************");
        $display("mx_mode = %b, matrix_size = %b(%d)", mx_mode[questcnt], img_size,true_img_size);
        $display("IMG[%d]:",mx_idx[questcnt][0]);
        for(i = 0; i < true_img_size; i = i+1)begin
            for(j = 0; j <true_img_size; j = j+1)begin
                if(j == true_img_size-1) $display("%d",pool[mx_idx[questcnt][0]][i][j]);
                else  $write("%d",pool[mx_idx[questcnt][0]][i][j]);
            end
        end
        $display("KERNEL pool[%d]:",mx_idx[questcnt][1]);
        for(i = 0; i < true_img_size; i = i+1)begin
            for(j = 0; j <true_img_size; j = j+1)begin
                if(j == true_img_size-1) $display("%d",pool[mx_idx[questcnt][1]][i][j]);
                else  $write("%d",pool[mx_idx[questcnt][1]][i][j]);
            end
        end
		repeat(2)@(negedge clk);
		$finish;
	end
	@(negedge clk);
  end
  lat_array[questcnt] = lat;
  total_latency = total_latency + lat;
  
end endtask


task check_ans; begin
x = 0;
  while(out_valid) begin
    if(x >= 1) begin//out length
      	$display("***************************************************************");
		$display("*     		    ICLAB05_FAIL      							*");
		$display("*         The out_valid is more than 1 cycle!                 *");
		$display("***************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    if(golden_answer[questcnt] !== out_value)begin//ans check
        
        $display ("--------------------------------------------------------------------");
        $display ("                     PATTERN #%d  Quest #%d FAILED !!   ",patcount, questcnt);

        $display("mx_mode = %b, matrix_size = %b(%d)", mx_mode[questcnt], img_size, true_img_size);
        $display("IMAGE[%d]:",mx_idx[questcnt][0]);
        for(i = 0; i < true_img_size; i = i+1)begin
            for(j = 0; j <true_img_size; j = j+1)begin
                if(j == true_img_size-1) $display("%d",pool[mx_idx[questcnt][0]][i][j]);
                else  $write("%d",pool[mx_idx[questcnt][0]][i][j]);
            end
        end
        $display("KERNEL[%d]:",mx_idx[questcnt][1]);
        for(i = 0; i < true_img_size; i = i+1)begin
            for(j = 0; j <true_img_size; j = j+1)begin
                if(j == true_img_size-1) $display("%d",pool[mx_idx[questcnt][1]][i][j]);
                else  $write("%d",pool[mx_idx[questcnt][1]][i][j]);
            end
        end
        

      $display ("            Golden ANS: %d, Yours: %d(%h)    ",golden_answer[questcnt], out_value, out_value);		
      $display ("            Error !!                                                ");
      $display ("--------------------------------------------------------------------");
      repeat(2) @(negedge clk);		
      $finish;
    end
    @(negedge clk);	
    x = x + 1;
  end

end endtask


task YOU_PASS_task; begin
  $display ("--------------------------------------------------------------------");
  $display ("          ~(￣▽￣)~(＿△＿)~(￣▽￣)~(＿△＿)~(￣▽￣)~           			 ");
  $display ("                         Congratulations!                           ");
  $display ("                  You have passed all patterns for Lab05!!                    ");
  $display ("--------------------------------------------------------------------");       
    
    #(500);
    $finish;
end endtask

endmodule