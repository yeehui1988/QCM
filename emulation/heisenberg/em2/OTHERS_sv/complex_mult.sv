module complex_mult #(parameter complex_bit = 24, fp_bit = 22)(
input signed [(complex_bit-1):0] in_r1, 	input signed [(complex_bit-1):0] in_i1,
input signed [(complex_bit-1):0] in_r2,	input signed [(complex_bit-1):0] in_i2,		
output reg signed [(complex_bit-1):0] out_r,	output reg signed [(complex_bit-1):0] out_i);

	//(const_real + const_imag i)(in_real + in_imag i)
	//(const_real*in_real - const_imag*in_imag) + (const_real*in_imag + const_imag*in_real)i
	wire signed [((complex_bit*2)-1):0] out_double_real1, out_double_real2;
	wire signed [((complex_bit*2)-1):0] out_double_imag1, out_double_imag2;
	wire signed [((complex_bit*2)-1):0] out_real; wire signed [((complex_bit*2)-1):0] out_imag; 
	
	//For real part	
	assign out_double_real1 = in_r1 * in_r2;
	assign out_double_real2 = in_i1 * in_i2;
	//assign out_r = out_double_real1[(fp_bit+complex_bit-1):fp_bit] - out_double_real2[(fp_bit+complex_bit-1):fp_bit];
	assign out_real = out_double_real1 - out_double_real2;
	assign out_r = out_real[(fp_bit+complex_bit-1):fp_bit];
	
	//For imaginary part	
	assign out_double_imag1 = in_r1 * in_i2;
	assign out_double_imag2 = in_i1 * in_r2;
	//assign out_i = out_double_imag1[(fp_bit+complex_bit-1):fp_bit] + out_double_imag2[(fp_bit+complex_bit-1):fp_bit];
	assign out_imag = out_double_imag1 + out_double_imag2;
	assign out_i = out_imag[(fp_bit+complex_bit-1):fp_bit];

endmodule 