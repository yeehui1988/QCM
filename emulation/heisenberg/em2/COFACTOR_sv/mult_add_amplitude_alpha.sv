module mult_add_amplitude_alpha #(parameter complex_bit = 24)(
input [7:0] alpha1, input [7:0] alpha2,
input [2*complex_bit-1:0] amplitude_in1, input [2*complex_bit-1:0] amplitude_in2,
output [2*complex_bit-1:0] amplitude_out1, output [2*complex_bit-1:0] amplitude_out2
);

/*****************************************************************/
//Matched pair found:
//amplitude1' = amplitude1 * alpha1_1 + amplitude2 * alpha2_2
//amplitude2' = amplitude1 * alpha1_2 + amplitude2 * alpha2_1 

//Matched pair NOT found:
//amplitude1' = amplitude1 * alpha1_1
//amplitude_new = amplitude1 * alpha1_2
/*****************************************************************/

/********Separate signals for operations********/
wire signed [1:0] alpha1_1_r; wire signed [1:0] alpha1_1_i; wire signed [1:0] alpha1_2_r; wire signed [1:0] alpha1_2_i; //original_phase_vector
wire signed [1:0] alpha2_1_r; wire signed [1:0] alpha2_1_i; wire signed [1:0] alpha2_2_r; wire signed [1:0] alpha2_2_i; //duplicate_toggle / new_location (don't care)
assign alpha1_1_r = alpha1 [7:6]; assign alpha1_1_i = alpha1 [5:4]; assign alpha1_2_r = alpha1 [3:2]; assign alpha1_2_i = alpha1 [1:0];
assign alpha2_1_r = alpha2 [7:6]; assign alpha2_1_i = alpha2 [5:4]; assign alpha2_2_r = alpha2 [3:2]; assign alpha2_2_i = alpha2 [1:0];

wire signed [complex_bit-1:0] amplitude_in1_r; wire signed [complex_bit-1:0] amplitude_in1_i;
wire signed [complex_bit-1:0] amplitude_in2_r; wire signed [complex_bit-1:0] amplitude_in2_i;
assign amplitude_in1_r = amplitude_in1 [2*complex_bit-1:complex_bit]; assign amplitude_in1_i = amplitude_in1 [complex_bit-1:0];
assign amplitude_in2_r = amplitude_in2 [2*complex_bit-1:complex_bit]; assign amplitude_in2_i = amplitude_in2 [complex_bit-1:0];

wire signed [complex_bit-1:0] amplitude_out1_1_r; wire signed [complex_bit-1:0] amplitude_out1_1_i;
wire signed [complex_bit-1:0] amplitude_out1_2_r; wire signed [complex_bit-1:0] amplitude_out1_2_i;
wire signed [complex_bit-1:0] amplitude_out2_1_r; wire signed [complex_bit-1:0] amplitude_out2_1_i;
wire signed [complex_bit-1:0] amplitude_out2_2_r; wire signed [complex_bit-1:0] amplitude_out2_2_i;

/********Multiply amplitude with alpha********/
//amplitude1_1 =  amplitude1 * alpha1_1
mult_amplitude_alpha mult_aa1_1 (.alpha_r(alpha1_1_r), .alpha_i(alpha1_1_i), .amplitude_in_r(amplitude_in1_r), .amplitude_in_i(amplitude_in1_i), 
.amplitude_out_r(amplitude_out1_1_r), .amplitude_out_i(amplitude_out1_1_i));
defparam mult_aa1_1.complex_bit = complex_bit; 

//amplitude1_2 =  amplitude1 * alpha1_2
mult_amplitude_alpha mult_aa1_2 (.alpha_r(alpha1_2_r), .alpha_i(alpha1_2_i), .amplitude_in_r(amplitude_in1_r), .amplitude_in_i(amplitude_in1_i), 
.amplitude_out_r(amplitude_out1_2_r), .amplitude_out_i(amplitude_out1_2_i));
defparam mult_aa1_2.complex_bit = complex_bit; 

//amplitude2_1 =  amplitude2 * alpha2_1
mult_amplitude_alpha mult_aa2_1 (.alpha_r(alpha2_1_r), .alpha_i(alpha2_1_i), .amplitude_in_r(amplitude_in2_r), .amplitude_in_i(amplitude_in2_i), 
.amplitude_out_r(amplitude_out2_1_r), .amplitude_out_i(amplitude_out2_1_i));
defparam mult_aa2_1.complex_bit = complex_bit; 

//amplitude2_2 =  amplitude2 * alpha2_2
mult_amplitude_alpha mult_aa2_2 (.alpha_r(alpha2_2_r), .alpha_i(alpha2_2_i), .amplitude_in_r(amplitude_in2_r), .amplitude_in_i(amplitude_in2_i), 
.amplitude_out_r(amplitude_out2_2_r), .amplitude_out_i(amplitude_out2_2_i));
defparam mult_aa2_2.complex_bit = complex_bit; 

/***************Summation***************/
wire signed [complex_bit-1:0] amplitude_out1_r; wire signed [complex_bit-1:0] amplitude_out1_i;
wire signed [complex_bit-1:0] amplitude_out2_r; wire signed [complex_bit-1:0] amplitude_out2_i;

//amplitude1 = amplitude1_1 + amplitude2_2
assign amplitude_out1_r = amplitude_out1_1_r + amplitude_out2_2_r;
assign amplitude_out1_i = amplitude_out1_1_i + amplitude_out2_2_i;

//amplitude2 = amplitude1_2 + amplitude2_1
assign amplitude_out2_r = amplitude_out1_2_r + amplitude_out2_1_r;
assign amplitude_out2_i = amplitude_out1_2_i + amplitude_out2_1_i;

assign amplitude_out1 = {amplitude_out1_r,amplitude_out1_i}; assign amplitude_out2 = {amplitude_out2_r,amplitude_out2_i};

endmodule
