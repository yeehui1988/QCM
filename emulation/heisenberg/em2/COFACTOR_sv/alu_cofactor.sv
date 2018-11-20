module alu_cofactor #(parameter complex_bit = 24, num_qubit = 3)(
input clk, input rst,
input data_valid, input [num_qubit-1:0] in_location,
input [7:0] alpha,
input [2*complex_bit-1:0] amplitude_in, 
output reg [2*complex_bit-1:0] amplitude_out,
output write_en, output [num_qubit-1:0] write_location
);

integer i;
reg [2*complex_bit-1:0] reg_amplitude_in; reg [2*complex_bit-1:0] reg_amplitude_out2; reg [7:0] reg_alpha;
wire [2*complex_bit-1:0] amplitude_out1; wire [2*complex_bit-1:0] amplitude_out2;
reg reg_valid, reg2_valid;
reg [num_qubit-1:0] reg_location; reg [num_qubit-1:0] reg2_location; 

/*******************************Registers****************************/
//Input & Output Sequence: original_phase, duplicate_toggle
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0;i<2*complex_bit;i++)
		begin
			reg_amplitude_in[i] <= 1'd0;
			reg_amplitude_out2[i] <= 1'd0;
 		end
		for (i=0;i<num_qubit;i++)
		begin
			reg_location [i] <= 1'd0;
			reg2_location [i] <= 1'd0;
		end
		reg_alpha <= 8'd0;
		reg_valid <= 1'd0; reg2_valid <= 1'd0;	 
	end
	else
	begin
		i=0;
		reg_amplitude_in <= amplitude_in; 	    //amplitude1 => original_phase
		reg_amplitude_out2 <= amplitude_out2;	//amplitude2' => duplicate_toggle / new_location (zero)
		reg_alpha <= alpha;			            //alpha1 => original_phase
		reg_valid <= data_valid;		        //Sync with amplitude memory read
		reg2_valid <= reg_valid;		        //Sync with amplitudes join for mult_add
		reg_location <= in_location;		    //Sync with amplitude memory read
		reg2_location <= reg_location;		    //Sync with amplitudes join for mult_add
	end
end

//Multiply amplitudes with alphas and sum them accordingly
mult_add_amplitude_alpha mult_add_aa (.alpha1(reg_alpha), .alpha2(alpha), .amplitude_in1(reg_amplitude_in), .amplitude_in2(amplitude_in), .amplitude_out1(amplitude_out1), 
.amplitude_out2(amplitude_out2));
defparam mult_add_aa.complex_bit = complex_bit; 

/**********SELECT OUTPUT TO UPDATE AMPLITUDES IN MEMORY*********/
reg ori_dup_select;
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		ori_dup_select <= 1'd0; 
	end
	else
	begin
		if(reg2_valid)
		begin
			ori_dup_select <= ~ori_dup_select;
		end
	end
end

always@(*)
begin
	if(ori_dup_select == 0) //Select original_phase amplitude
	begin
		amplitude_out <= amplitude_out1;
	end
	else                    //Select duplicate_toggle amplitude
	begin
		amplitude_out <= reg_amplitude_out2;	
	end
end

assign write_location = reg2_location;
assign  write_en = reg2_valid;

endmodule
