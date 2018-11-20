module stabilizer_operation #(parameter num_qubit=4, complex_bit = 24, fp_bit = 22)(
input clk, input rst,
input [2:0] gate_type_norm, input [31:0] qubit_pos_norm, input [31:0] qubit_pos2_norm, 
input [31:0] qubit_pos_ahead,
input [1:0] literals_in_stabilizer [0:num_qubit-1], input phase_in_stabilizer [0:2**num_qubit-1],
//For nonstabilizer buffer:
input valid_out_individual_cofactor, input ready_cofactor, input mask_valid_buffer,
input [1:0] literals_out_individual_cofactor [0:num_qubit-1], input phase_out_individual_cofactor [0:2**num_qubit-1], output valid_out_buffer,
output [1:0] literals_out_stabilizer [0:num_qubit-1], output phase_out_stabilizer [0:2**num_qubit-1], output valid_P_nonstabilizer_intermediate,
//For basis index list 2:
input basis_index_in [0:num_qubit-1], input ld_basis_index_in, //basis_index rotate left right in
//For productQ2:
input [1:0] literals_out_cofactor [0:num_qubit-1], input phase_out_cofactor [0:2**num_qubit-1], input valid_P_beta,
input [1:0] literals_P [0:2**num_qubit-1][0:num_qubit-1], input ld_prodQ, input rotateLeft_Q2, input ld_rotateLeft_Q2,
//For basis index update at alpha stage:
output rotateLeft_stabilizer_basis, output basis_stabilizer [0:num_qubit-1], input basis_index_leftmost [0:num_qubit-1],
//For alpha: amplitude1
output [num_qubit-1:0] read_ram_alpha_stabilizer_address, output read_ram_alpha_stabilizer_en, input [7:0] read_alpha_out,
input [1:0] amplitude_r_Q_out, input [1:0] amplitude_i_Q_out, input [complex_bit-1:0] ram_amplitude_out_r, input [complex_bit-1:0] ram_amplitude_out_i, 
output read_amplitude_alpha_stabilizer_en, output [num_qubit-1:0] read_amplitude_alpha_stabilizer_address,
output write_amplitude_alpha_stabilizer_en, output [num_qubit-1:0] write_amplitude_alpha_stabilizer_address, 
output [2*complex_bit-1:0] write_amplitude_alpha_stabilizer, input first_gate, 
input valid_in_stabilizer, input [31:0] counter_valid_vector, input done_amplitude, output determine_amplitude2, input ram_amplitude_busy,
output [1:0] literals_Q2 [0:2**num_qubit-1][0:num_qubit-1], output phase_Q2 [0:2**num_qubit-1], output valid_out_stabilizer, 
output valid_out_nonstabilizer_buffer,
//From cba module to canonical:
output [1:0] literals_out_cba [0:num_qubit-1], output phase_out_cba [0:2**num_qubit-1], output valid_out_cba,
//For stabilizer beta operation:
input [1:0] literals_out_canonical [0:num_qubit-1], input phase_out_canonical [0:2**num_qubit-1], input valid_out_canonical,
output valid_P_stabilizer,
//For nonstabilizer operation if the next gate is nonstabilizer gate
output valid_P_from_stabilizer_to_nonstabilizer, 
//For stabilizer beta operation
output ld_prodQ_stabilizer, output rotateLeft_Q_flag_basis_stabilizer, output determine_amplitude_stabilizer,
//For debugging:
output [1:0] literal_reg [0:num_qubit-1][0:num_qubit-1],	//[row][column]
output phase_reg [0:num_qubit-1][0:2**num_qubit-1] 	
);

wire basis_index2 [0:2**num_qubit-1][0:num_qubit-1]; wire basis_index2_leftmost [0:num_qubit-1];
wire Q2_msb_leftmost [0:num_qubit-1]; wire initial_alpha_zero, rotateLeft_Q2_individual, rotateLeft_stabilizer_basis2; wire mask_stabilizer_operation;
wire valid_out_canonical_mask, rotateLeft_reg_beta, rotateDown_reg_beta; 
assign valid_out_canonical_mask = mask_stabilizer_operation && valid_out_canonical;

/***********************************************************REGISTER ARRAY***********************************************************/
//Use for Case 1: buffer in between cofactor operation
//=> Move register array buffer in nonstabilizer operation module here!!!
//Use for Case 2: stabilizer operation for prodQ determination (alpha & beta) to update global phase
//=> Take input from canonical module (after conjugation-by-action + canonical form reduction)

register_array_stabilizer reg_array_stabilizer (.clk(clk), .rst(rst), .valid_out_individual_cofactor(valid_out_individual_cofactor),
.ready_cofactor(ready_cofactor), .literals_out_individual_cofactor(literals_out_individual_cofactor), 
.valid_P_nonstabilizer_intermediate(valid_P_nonstabilizer_intermediate),
.phase_out_individual_cofactor(phase_out_individual_cofactor), .literals_out_stabilizer(literals_out_stabilizer), .mask_valid_buffer(mask_valid_buffer),
.phase_out_stabilizer(phase_out_stabilizer), .valid_out_buffer(valid_out_buffer), .valid_out_nonstabilizer_buffer(valid_out_nonstabilizer_buffer),
.literals_out_canonical(literals_out_canonical), .phase_out_canonical(phase_out_canonical), .valid_out_canonical_mask(valid_out_canonical_mask),
.valid_out_stabilizer(valid_out_stabilizer), .rotateLeft_reg_beta(rotateLeft_reg_beta), .rotateDown_reg_beta(rotateDown_reg_beta),
.literal_reg(literal_reg), .phase_reg(phase_reg)
);
defparam reg_array_stabilizer.num_qubit = num_qubit; 

/*********************************************************BASIS INDEX*************************************************************/
//Determine & store basis index list 2 (for stabilizer Hadamard case)
//=> Implement this function first!!! Minimize alternation on the cofactor & nonstabilizer modules
//Update basis index list 1 - in parallel with alpha determination (for stabilizer Hadamard case based on initial_alpha_zero) 
//ASSIGN RELATED SIGNALS: initial_alpha_zero (for now put 0), basis_index_update (KIV the update for now)

module_basis_index basis_index_stabilizer (.clk(clk), .rst(rst), .gate_type_norm(gate_type_norm), .qubit_pos_norm(qubit_pos_norm), .qubit_pos2_norm(qubit_pos2_norm),
.qubit_pos_ahead(qubit_pos_ahead), .basis_index_in(basis_index_in), .ld_basis_index_in(ld_basis_index_in), 
.initial_alpha_zero(initial_alpha_zero), .basis_index_update(basis_stabilizer), .basis_index2(basis_index2), .basis_index2_leftmost(basis_index2_leftmost),
.rotateLeft_stabilizer_basis2(rotateLeft_stabilizer_basis2), .basis_index_leftmost(basis_index_leftmost));
defparam basis_index_stabilizer.num_qubit = num_qubit;

/***********************************************************PRODUCT Q2*************************************************************/
//Determine prodQ2 based on basis index list 2
//=> Include this function for the beta stage of stabilizer operation as well 
//=> Literal out for now take from (a) register array cofactor only (b) ADD IN register array stabilizer LATER!!!!!!
//=> Make sure the content of productQ is not written before all the necessary operation are performed!!!
//=> Make sure P do not overwrite the content in Q2 before determine amplitude2 operation is completed.

module_Q modQ2 (.clk(clk), .rst(rst), .valid_P_beta(valid_P_beta), .literals_P(literals_P), .literals_out(literals_out_cofactor), 
.phase_out(phase_out_cofactor), .literals_out_stabilizer(literals_out_stabilizer), .phase_out_stabilizer(phase_out_stabilizer),
.rotateLeft_Q2_from_nonstabilizer(rotateLeft_Q2), .ld_prodQ2_from_nonstabilizer(ld_prodQ), 
.rotateLeft_Q2_from_stabilizer(rotateLeft_Q_flag_basis_stabilizer), .ld_prodQ2_from_stabilizer(ld_prodQ_stabilizer), 
.rotateLeft_Q2_individual(rotateLeft_Q2_individual), .ld_rotateLeft_Q2(ld_rotateLeft_Q2), 
.literals_Q2(literals_Q2), .phase_Q2(phase_Q2), .basis_index2(basis_index2), .Q2_msb_leftmost(Q2_msb_leftmost), .valid_P_stabilizer(valid_P_stabilizer));
defparam modQ2.num_qubit = num_qubit;

/***********************************************************MODULE ALPHA*************************************************************/
module_alpha alpha_stabilizer (.clk(clk), .rst(rst), .gate_type_norm(gate_type_norm), .qubit_pos_norm(qubit_pos_norm), .basis_index_leftmost(basis_index_leftmost),
.read_alpha_out(read_alpha_out), .amplitude_r_Q_out(amplitude_r_Q_out), .amplitude_i_Q_out(amplitude_i_Q_out), .basis_index2_leftmost(basis_index2_leftmost), 
.Q2_msb_leftmost(Q2_msb_leftmost), .initial_alpha_zero(initial_alpha_zero), .ram_amplitude_out_r(ram_amplitude_out_r), .ram_amplitude_out_i(ram_amplitude_out_i),
.first_gate(first_gate), .write_amplitude_alpha_stabilizer(write_amplitude_alpha_stabilizer));
defparam alpha_stabilizer.num_qubit = num_qubit; defparam alpha_stabilizer.complex_bit = complex_bit; defparam alpha_stabilizer.fp_bit = fp_bit;

/***********************************************************CONTROL UNIT***********************************************************/
control_unit_stabilizer cu_stabilizer (.clk(clk), .rst(rst), .valid_in_stabilizer(valid_in_stabilizer), .done_amplitude(done_amplitude), 
.counter_valid_vector(counter_valid_vector), .gate_type_norm(gate_type_norm), .determine_amplitude2(determine_amplitude2), 
.ram_amplitude_busy(ram_amplitude_busy), .read_ram_alpha_stabilizer_address(read_ram_alpha_stabilizer_address), 
.read_ram_alpha_stabilizer_en(read_ram_alpha_stabilizer_en), .read_amplitude_alpha_stabilizer_en(read_amplitude_alpha_stabilizer_en), 
.read_amplitude_alpha_stabilizer_address(read_amplitude_alpha_stabilizer_address), .write_amplitude_alpha_stabilizer_en(write_amplitude_alpha_stabilizer_en), 
.write_amplitude_alpha_stabilizer_address(write_amplitude_alpha_stabilizer_address), .rotateLeft_stabilizer_basis(rotateLeft_stabilizer_basis), 
.rotateLeft_stabilizer_basis2(rotateLeft_stabilizer_basis2), .rotateLeft_Q2_individual(rotateLeft_Q2_individual), .valid_out_stabilizer(valid_out_stabilizer),
.valid_out_canonical_mask(valid_out_canonical_mask), .mask_stabilizer_operation(mask_stabilizer_operation), .valid_P_stabilizer(valid_P_stabilizer),
.literals_out_stabilizer(literals_out_stabilizer), .rotateLeft_reg_beta(rotateLeft_reg_beta), .rotateDown_reg_beta(rotateDown_reg_beta), 
.ld_prodQ_stabilizer(ld_prodQ_stabilizer), .qubit_pos_ahead(qubit_pos_ahead), .determine_amplitude_stabilizer(determine_amplitude_stabilizer),
.rotateLeft_Q_flag_basis_stabilizer(rotateLeft_Q_flag_basis_stabilizer), .valid_P_from_stabilizer_to_nonstabilizer(valid_P_from_stabilizer_to_nonstabilizer));
defparam cu_stabilizer.num_qubit = num_qubit;

/*******************************************************CONJUGATION-BY-ACTION*******************************************************/
conjugation_by_action cba (.clk(clk), .rst_new(rst), .gate_type(gate_type_norm), .qubit_pos(qubit_pos_norm), .qubit_pos2(qubit_pos2_norm), 
.literals_in(literals_in_stabilizer), .phase_in(phase_in_stabilizer), .valid_in(valid_in_stabilizer), .literals_out(literals_out_cba), 
.phase_out(phase_out_cba), .valid_out(valid_out_cba));
defparam cba.num_qubit = num_qubit;

endmodule 
