`timescale 1ns/1ns 

module testbench #(parameter sample_size = 32, complexnum_bit = 24)();
	
	reg clk, rst;
	reg signed [(complexnum_bit-1):0] in_r[0:(sample_size-1)];
	reg signed [(complexnum_bit-1):0] in_i[0:(sample_size-1)];
	wire signed [(complexnum_bit-1):0] out_r[0:(sample_size-1)];
	wire signed [(complexnum_bit-1):0] out_i[0:(sample_size-1)];
	integer write, read;
	
	qft5_emulate qft5 (.clk(clk), .rst(rst), .in_r(in_r), .in_i(in_i), .out_r(out_r), .out_i(out_i));
	
	integer fixed_r_SV, fixed_i_SV, fixed_r_C, fixed_i_C, i, count;
	
	initial
	begin
		clk = 1'b0;
		forever
			#10			//period=40ns
			clk = ~clk;
	end
	
	//Read input from text file
	always @ (read)
	begin
		if(read)
		begin
			fixed_r_C=$fopen("fixed_r_C.txt","r");
			fixed_i_C=$fopen("fixed_i_C.txt","r");
			for (i = 0; i < sample_size; i = i +1) 
			begin
				count = $fscanf(fixed_r_C, "%x", in_r[i]); 
				count = $fscanf(fixed_i_C, "%x", in_i[i]); 
			end
			$fclose(fixed_r_C);
			$fclose(fixed_i_C);
		end
	end
	
	//Write outputs to text file
	always @ (write)
	begin
		if(write)
		begin
			fixed_r_SV=$fopen("fixed_r_SV.txt","w");
			fixed_i_SV=$fopen("fixed_i_SV.txt","w");
			for (i = 0; i < sample_size; i = i +1) 
			begin
				if(out_r[i][complexnum_bit-1] == 1'b1)
					$fdisplay(fixed_r_SV, "%x",{8'hff,out_r[i][complexnum_bit-1:0]});	//append sign bit if the number is negative
				else
					$fdisplay(fixed_r_SV, "%x",out_r[i]);
					
				if(out_i[i][complexnum_bit-1] == 1'b1)
					$fdisplay(fixed_i_SV, "%x",{8'hff,out_i[i][complexnum_bit-1:0]});
				else	
					$fdisplay(fixed_i_SV, "%x",out_i[i]);
			end
			$fclose(fixed_r_SV);
			$fclose(fixed_i_SV);
		end
	end
	
	initial
	begin
		write = 0;
		read = 0;
		rst = 1'b1;
		#5
		read = 1;
		rst = 1'b0;
		#350
		write = 1;
		#40
		$stop;
	end
		
endmodule
