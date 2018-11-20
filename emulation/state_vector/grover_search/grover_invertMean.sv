module grover_invertMean #(parameter num_bit = 3, fixedpoint_bit = 24, num_sample = 2**num_bit)
//num_sample: to be mapped into function; fixed point representation: 1 sign bit, 1 integer bit, 22 mantissa bits 
(input signed [(fixedpoint_bit-1):0] phaseInvert_out [0:(num_sample-1)], output reg signed [(fixedpoint_bit-1):0] invertMean [0:(num_sample-1)]);

integer j,k;

//Inversion About Mean Sub-Module: -I + 2A
reg signed [(fixedpoint_bit-1+num_bit):0] sum;		//Adder tree structure
wire signed [(fixedpoint_bit):0] twoMean;

always_comb
begin
sum = phaseInvert_out[0];
for (j = 1; j < num_sample; j = j + 1)
begin
	sum = sum + phaseInvert_out[j];
end
end

assign twoMean = sum[(fixedpoint_bit-1+num_bit):(num_bit-1)];	
reg signed [(fixedpoint_bit):0] temp;

always_comb
begin
for (k = 0; k < num_sample; k = k + 1)
begin
	temp = twoMean - phaseInvert_out[k];
	invertMean[k] = temp[(fixedpoint_bit-1):0];	//Truncate MSB, as the range of amplitudes are in the range [0,1], in fixed point bit
end
end

endmodule
