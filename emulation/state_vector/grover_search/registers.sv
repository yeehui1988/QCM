module registers #(parameter sample_size = 4, complexnum_bit = 24) (
input clk, rst, en,
input signed [(complexnum_bit-1):0] in[0:(sample_size-1)],
output reg signed [(complexnum_bit-1):0] out[0:(sample_size-1)]);

	integer i;
	always@(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			for (i = 0; i < sample_size; i = i + 1) 
			begin
				out[i] <= 'd0;
			end
		end
		else
		begin
			i=0; 
			if(en)
				out <= in;
		end
	end

endmodule
