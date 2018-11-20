module grover_phaseInvert #(parameter num_bit = 3, fixedpoint_bit = 24, num_sample = 2**num_bit)
//num_sample: to be mapped into function; fixed point representation: 1 sign bit, 1 integer bit, 22 mantissa bits 
(input [(num_bit-1):0] target_search, input signed [(fixedpoint_bit-1):0] phaseInvert_in [0:(num_sample-1)], output reg signed [(fixedpoint_bit-1):0] phaseInvert_out [0:(num_sample-1)]);

integer i;

//Phase Inversion Sub-Module
//Dummy Oracle Function: Recognize by position
always_comb
begin
	for (i = 0; i < num_sample; i = i + 1) 
	begin
		if(i==target_search)
			phaseInvert_out[i] = -phaseInvert_in[i];	//invert phase for match solution
		else
			phaseInvert_out[i] = phaseInvert_in[i];
	end
end
endmodule
