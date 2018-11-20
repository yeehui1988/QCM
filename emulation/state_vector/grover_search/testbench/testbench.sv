`timescale 1ns/1ns 

module testbench #(parameter num_bit = 3, fixedpoint_bit = 24, num_sample = 2**num_bit)();

reg clk, rst, start; 
reg [(num_bit-1):0] target_search;
wire signed [(fixedpoint_bit-1):0] output_r [0:(num_sample-1)]; wire done;

grover_search grover1(.clk(clk), .rst(rst), .start(start), .target_search(target_search), .output_r(output_r), .done(done));

	initial
	begin
		clk = 1'b0;
		forever
			#5			//period=40ns
			clk = ~clk;
	end

	initial
	begin
		rst = 1'b1; 
		#10
		rst = 1'b0;	target_search = 'd0; start = 1'b1;
		#100;
//		rst = 1'b0;	target_search = 'd1; start = 1'b0;
//		#80;
//		rst = 1'b0;	target_search = 'd2; start = 1'b0;
//		#80;
//		rst = 1'b0;	target_search = 'd3; start = 1'b0;
//		#80;
		$stop;
	end

endmodule
