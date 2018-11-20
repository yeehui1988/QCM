module module_alpha #(parameter num_qubit = 4, complex_bit = 24, fp_bit = 22)(
input clk, input rst,
input [2:0] gate_type_norm, input [31:0] qubit_pos_norm, 
//For odd even determination:
input basis_index_leftmost [0:num_qubit-1],
//For amplitude1:
input [7:0] read_alpha_out, 
//For amplitude2:
input [1:0] amplitude_r_Q_out, input [1:0] amplitude_i_Q_out, 
//For amplitude2: Determine if match, else assign amplitude2 to zero
input basis_index2_leftmost [0:num_qubit-1], input Q2_msb_leftmost [0:num_qubit-1], 
//For basis index update:
output reg initial_alpha_zero,
//For global phase update:
input [complex_bit-1:0] ram_amplitude_out_r, input [complex_bit-1:0] ram_amplitude_out_i, input first_gate,
output [2*complex_bit-1:0] write_amplitude_alpha_stabilizer
);

localparam signed [complex_bit-1:0] hadamard_constant = 0.707107 * (2**fp_bit);
integer i;
//With extended sign bit
wire [2:0] amplitude1_pre_r; wire [2:0] amplitude1_pre_i; wire [2:0] amplitude1_r; wire [2:0] amplitude1_i;
assign amplitude1_pre_r[1:0] = read_alpha_out[3:2]; assign amplitude1_pre_i[1:0] = read_alpha_out[1:0];
assign amplitude1_pre_r[2] = read_alpha_out[3]; assign amplitude1_pre_i[2] = read_alpha_out[1];
//For first gate: amplitude1 is 1, amplitude2 is 0
assign amplitude1_r = (first_gate)? 3'd1: amplitude1_pre_r;
assign amplitude1_i = (first_gate)? 3'd0: amplitude1_pre_i;

reg [complex_bit-1:0] write_amplitude_alpha_stabilizer_r; reg [complex_bit-1:0] write_amplitude_alpha_stabilizer_i; 
assign write_amplitude_alpha_stabilizer = {write_amplitude_alpha_stabilizer_r,write_amplitude_alpha_stabilizer_i};

reg signed [2:0] alpha_H_r; reg signed [2:0] alpha_H_i; reg signed [2:0] alpha_P_r; reg signed [2:0] alpha_P_i; 
wire signed [2:0] alpha_CNOT_r; wire signed [2:0] alpha_CNOT_i; reg signed [2:0] alpha_selected_r; reg signed [2:0] alpha_selected_i; 
reg signed [2:0] reg_alpha_selected_r; reg signed [2:0] reg_alpha_selected_i;
reg signed [complex_bit-1:0] alpha_Phase_CNOT_r; reg signed [complex_bit-1:0] alpha_Phase_CNOT_i;
wire signed [complex_bit-1:0] alpha_Hadamard_r; wire signed [complex_bit-1:0] alpha_Hadamard_i;
reg signed [complex_bit-1:0] alpha_r; reg signed [complex_bit-1:0] alpha_i; 
wire signed [complex_bit-1:0] global_phase_alpha_r; wire signed [complex_bit-1:0] global_phase_alpha_i;

wire odd_even, odd_zero, even_zero; 
wire [2:0] hadamard_even_r; wire [2:0] hadamard_even_i; 
wire [2:0] hadamard_even_replace_r; wire [2:0] hadamard_even_replace_i; 
wire [2:0] hadamard_odd_r; wire [2:0] hadamard_odd_i;

//Odd & Even case
assign odd_even = (basis_index_leftmost[qubit_pos_norm])? 1'd1:1'd0; //odd:even

//For amplitude2:
reg match_basis_index_Q2; reg [2:0] amplitude2_r; reg [2:0] amplitude2_i;
always@(*)
begin
	match_basis_index_Q2 = 1'd1;
	for (i=0;i<num_qubit;i=i+1)
	begin
		if(basis_index2_leftmost[i] != Q2_msb_leftmost[i] || first_gate)
		begin
			match_basis_index_Q2 = match_basis_index_Q2 & 1'd0;
		end
		else
		begin
			match_basis_index_Q2 = match_basis_index_Q2 & 1'd1;
		end
	end
end

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		amplitude2_r <= 3'd0; amplitude2_i <= 3'd0;
	end
	else
	begin
		if(match_basis_index_Q2 && gate_type_norm==3'd0) //Only for Hadamard gate
		begin
			//With extended sign bit
			amplitude2_r[1:0] <= amplitude_r_Q_out; amplitude2_i[1:0] <= amplitude_i_Q_out;
			amplitude2_r[2] <= amplitude_r_Q_out[1]; amplitude2_i[2] <= amplitude_i_Q_out[1];
		end
		else
		begin
			amplitude2_r <= 3'd0; amplitude2_i <= 3'd0;
		end
	end
end

/***********************************************************FOR HADAMARD GATE******************************************************/
//For Hadamard: Even case
assign hadamard_even_r = amplitude1_r + amplitude2_r; 
assign hadamard_even_i = amplitude1_i + amplitude2_i;
assign hadamard_even_replace_r = amplitude1_r - amplitude2_r;
assign hadamard_even_replace_i = amplitude1_i - amplitude2_i;

//For Hadamard: Odd case
assign hadamard_odd_r = amplitude2_r - amplitude1_r; 
assign hadamard_odd_i = amplitude2_i - amplitude1_i;

//For exception case: Initial alpha is zero
assign even_zero = (hadamard_even_r == 3'd0 && hadamard_even_i == 3'd0)? 1'd1:1'd0;
assign odd_zero = (hadamard_odd_r == 3'd0 && hadamard_odd_i == 3'd0)? 1'd1:1'd0;

always@(*)
begin
	initial_alpha_zero <= 1'd0;
	if(odd_even == 1'd0)	//Even
	begin
		if(even_zero==0) 	//Nonzero
		begin
			//alpha_r <= amplitude_r + amplitude2_r; alpha_i <= amplitude_i + amplitude2_i;
			alpha_H_r <= hadamard_even_r; alpha_H_i <= hadamard_even_i;
		end
		else				//Initially zero
		begin
			//alpha_r <= amplitude_r - amplitude2_r; alpha_i <= amplitude_i - amplitude2_i;
			alpha_H_r <= hadamard_even_replace_r; alpha_H_i <= hadamard_even_replace_i; initial_alpha_zero <= 1'd1;
		end	
	end
	else					//Odd
	begin
		if(odd_zero==0)	//Nonzero
		begin
			//alpha_r <= amplitude2_r - amplitude_r; alpha_i <= amplitude2_i - amplitude_i;
			alpha_H_r <= hadamard_odd_r; alpha_H_i <= hadamard_odd_i;
		end
		else					//Initially zero
		begin
			//alpha_r <= amplitude2_r + amplitude_r; alpha_i <= amplitude2_i + amplitude_i; => hadamard_even
			alpha_H_r <= hadamard_even_r; alpha_H_i <= hadamard_even_i; initial_alpha_zero <= 1'd1;
		end	
	end
end

/**********************************************************FOR PHASE GATE***********************************************************/
always@(*)
begin
	if(odd_even == 1'd0)    //Even
	begin
		alpha_P_r <= amplitude1_r; alpha_P_i <= amplitude1_i;
	end
	else 				    //Odd
	begin
		alpha_P_r <= -amplitude1_i; alpha_P_i <= amplitude1_r;
	end
end

/********************************************************FOR CNOT GATE*************************************************************/
assign alpha_CNOT_r = amplitude1_r; assign alpha_CNOT_i = amplitude1_i;

/************************************************ALPHA SELECTION BASED ON GATE TYPE************************************************/
//Select alpha based on gate type
always@(*)
begin
	if (gate_type_norm==3'd0)	 	    //Hadamard gate
	begin
		alpha_selected_r <= alpha_H_r; alpha_selected_i <= alpha_H_i;
	end
	else if (gate_type_norm==3'd1)	    //Phase gate
	begin
		alpha_selected_r <= alpha_P_r; alpha_selected_i <= alpha_P_i;
	end
	else								//CNOT gate
	begin
		alpha_selected_r <= alpha_CNOT_r; alpha_selected_i <= alpha_CNOT_i;
	end
end

//Convert to fixed point & update alpha with Hadamard constant for the case of Hadamard gate
//For Phase & CNOT gates: +1; -1; +i; -i; (1+i)/sqrt(2); (1-i)/sqrt(2)
always@(*)
begin
	for(i=0;i<fp_bit;i=i+1)
	begin
		alpha_Phase_CNOT_r [i] = 1'd0;
		alpha_Phase_CNOT_i [i] = 1'd0;
	end
	alpha_Phase_CNOT_r [fp_bit] = reg_alpha_selected_r[0];
	alpha_Phase_CNOT_i [fp_bit] = reg_alpha_selected_i[0];
	for(i=fp_bit+1;i<complex_bit;i=i+1) //Extend signed bit
	begin
		alpha_Phase_CNOT_r [i] = reg_alpha_selected_r[1];
		alpha_Phase_CNOT_i [i] = reg_alpha_selected_i[1];
	end
end

assign alpha_Hadamard_r = hadamard_constant * reg_alpha_selected_r; assign alpha_Hadamard_i = hadamard_constant * reg_alpha_selected_i; 

/***********************************************UPDATE GLOBAL PHASE WITH ALPHA**************************************************/
reg [complex_bit-1:0] reg_ram_amplitude_out_r; reg [complex_bit-1:0] reg_ram_amplitude_out_i;
reg signed [complex_bit-1:0] reg_alpha_r; reg signed [complex_bit-1:0] reg_alpha_i; 

//Complex number multiplication:
complex_mult complex_mult_stabilizer_alpha (.in_r1(reg_ram_amplitude_out_r), .in_i1(reg_ram_amplitude_out_i), .in_r2(reg_alpha_r), .in_i2(reg_alpha_i), 
.out_r(global_phase_alpha_r), .out_i(global_phase_alpha_i));
defparam complex_mult_stabilizer_alpha.complex_bit = complex_bit; defparam complex_mult_stabilizer_alpha.fp_bit = fp_bit;

//Insert register to reduce CPD
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		reg_alpha_selected_r <= 3'd0; reg_alpha_selected_i <= 3'd0;
		alpha_r <= {complex_bit{1'b0}}; alpha_i <= {complex_bit{1'b0}}; 
		reg_alpha_r <= {complex_bit{1'b0}}; reg_alpha_i <= {complex_bit{1'b0}};
		reg_ram_amplitude_out_r <= {complex_bit{1'b0}}; reg_ram_amplitude_out_i <= {complex_bit{1'b0}};
		write_amplitude_alpha_stabilizer_r <= {complex_bit{1'b0}}; write_amplitude_alpha_stabilizer_i <= {complex_bit{1'b0}}; 
	end
	else
	begin
		reg_alpha_selected_r <= alpha_selected_r; reg_alpha_selected_i <= alpha_selected_i;
		write_amplitude_alpha_stabilizer_r <= global_phase_alpha_r; write_amplitude_alpha_stabilizer_i <= global_phase_alpha_i; 
		reg_ram_amplitude_out_r <= ram_amplitude_out_r; reg_ram_amplitude_out_i <= ram_amplitude_out_i;
		reg_alpha_r <= alpha_r; reg_alpha_i <= alpha_i;
		if(gate_type_norm==3'd0) //Hadamard Gate
		begin
			alpha_r <= alpha_Hadamard_r; alpha_i <= alpha_Hadamard_i;
		end
		else
		begin
			alpha_r <= alpha_Phase_CNOT_r; alpha_i <= alpha_Phase_CNOT_i;
		end
	end
end

endmodule 
