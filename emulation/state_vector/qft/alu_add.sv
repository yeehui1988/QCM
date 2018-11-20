module alu_add #(parameter sample_size = 4, complexnum_bit = 24, fp_bit = 22)(
input signed [(complexnum_bit-1):0] in1, 	input signed [(complexnum_bit-1):0] in2,
input signed [complexnum_bit:0] in3,	output signed [(complexnum_bit-1):0] out);
//out = (in1 + in2) * in3;
	wire signed [complexnum_bit:0] temp;
	wire signed [(((complexnum_bit+1)*2)-1):0] out_double;

	assign temp = in1 + in2;				//answer with extra 1-bit to prevent overflow
	//Use hardware multiplier
	assign out_double = temp * in3;		//answer with double of the original bit
	assign out = out_double[(fp_bit + complexnum_bit - 1):fp_bit];	//shift the answer for fixed point mul correction 
	
endmodule
