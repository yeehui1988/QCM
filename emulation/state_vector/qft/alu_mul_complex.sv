module alu_mul_complex #(parameter sample_size = 8, complexnum_bit = 24, fp_bit = 22)(
input signed [(complexnum_bit-1):0] in_real, 	input signed [(complexnum_bit-1):0] in_imag,
input signed [(complexnum_bit-1):0] const_real,	input signed [(complexnum_bit-1):0] const_imag,		
output signed [(complexnum_bit-1):0] out_real,	output signed [(complexnum_bit-1):0] out_imag);

	//(const_real + const_imag i)(in_real + in_imag i)
	//(const_real*in_real - const_imag*in_imag) + (const_real*in_imag + const_imag*in_real)i
	wire signed [((complexnum_bit*2)-1):0] out_double_real1, out_double_real2;
	wire signed [((complexnum_bit*2)-1):0] out_double_imag1, out_double_imag2;
	//For real part	
	assign out_double_real1 = const_real * in_real;
	assign out_double_real2 = const_imag * in_imag;
	assign out_real = out_double_real1[(fp_bit+complexnum_bit-1):fp_bit] - out_double_real2[(fp_bit+complexnum_bit-1):fp_bit];
	//For imaginary part	
	assign out_double_imag1 = const_real * in_imag;
	assign out_double_imag2 = const_imag * in_real;
	assign out_imag = out_double_imag1[(fp_bit+complexnum_bit-1):fp_bit] + out_double_imag2[(fp_bit+complexnum_bit-1):fp_bit];
endmodule
