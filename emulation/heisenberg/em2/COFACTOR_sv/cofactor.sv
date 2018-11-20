module cofactor #(parameter num_qubit = 3, complex_bit = 24)(
input clk, input rst,
//input new_cofactor, 
input [31:0] cofactor_pos,
input [1:0] literals_in [0:num_qubit-1], input phase_in [0:2**num_qubit-1], input valid_in,
input [1:0] literals_P_in [0:2**num_qubit-1][0:num_qubit-1], input valid_P, 
output [1:0] literals_out[0:num_qubit-1], output phase_out [0:2**num_qubit-1], output valid_out,
output valid_flag_anticommute, output flag_anticommute, output [31:0] counter_valid_vector,  
//For verification:
output basis_index [0:2**num_qubit-1][0:num_qubit-1],
//Pull out for debug:
//Move amplitude cofactor module to top level
output determine_amplitude, output determine_amplitude_alpha, output determine_amplitude_beta,
output [1:0] literals_Q [0:2**num_qubit-1][0:num_qubit-1], output phase_Q [0:2**num_qubit-1],
input done_amplitude, input ld_rotateLeft, input ld_PQ_list1_amp, input [1:0] amplitude_r_Q_out, input [1:0] amplitude_i_Q_out,
input write_alpha_enable, input [num_qubit-1:0] write_alpha_address, input done_alpha,
//Move ram amplitude control module to top level
output ram_amplitude_writein_en, output [2*complex_bit-1:0] ram_amplitude_writein, output [num_qubit-1:0] ram_amplitude_writein_address,
output [num_qubit-1:0] generator_amplitude_address, output generator_address_valid, input [2*complex_bit-1:0] ram_amplitude_out,
//For beta
output [num_qubit-1:0] ram_amplitude_beta_readout_address, output ram_amplitude_beta_readout_en, 
output ram_amplitude_beta_writein_en, output [2*complex_bit-1:0] ram_amplitude_beta_writein, output [num_qubit-1:0] ram_amplitude_beta_writein_address,
//For nonstabilizer gate operation:
input final_cofactor, input flag_cofactor [0:num_qubit-1], input phaseShift_toffoli, input rotateLeft_flag_nonstabilizer_update,
output flag_nonstabilizer_update0, output done_flag_nonstabilizer_update, output updating_beta,
//For stabilizer:
output basis_index_in [0:num_qubit-1], output ld_basis, //for basis index list 2
output ld_prodQ, output rotateLeft_Q2,                  //for productQ2
input write_amplitude1_enable, input [7:0] write_amplitude1,
input rotateLeft_stabilizer_basis, input basis_stabilizer [0:num_qubit-1], output basis_index_leftmost [0:num_qubit-1],
input [num_qubit-1:0] read_ram_alpha_stabilizer_address, input read_ram_alpha_stabilizer_en, output [7:0] read_alpha_out,
//For stabilizer beta operation: 
input [1:0] literals_out_stabilizer [0:num_qubit-1], input phase_out_stabilizer [0:2**num_qubit-1], input valid_P_stabilizer,
input ld_prodQ_stabilizer, input rotateLeft_Q_flag_basis_stabilizer, input determine_amplitude_stabilizer,
//For verification:
output [1:0] literal_reg [0:num_qubit-1][0:num_qubit-1],
output phase_reg [0:num_qubit-1][0:2**num_qubit-1]
);

wire ld_reg, ld_cofactor_info, rst_flag, anticommute, mux_phase_shift_in, valid_ori_phase_write; 
wire [1:0] shift_rotate_array; wire [31:0] reg_cofactor_pos; wire [2:0] mux_shift_in; 
wire [1:0] literals_register_array_in [0:num_qubit-1]; wire phase_register_array_in [0:2**num_qubit-1]; 
wire [1:0] literals_anticommute [0:num_qubit-1]; wire phase_anticommute [0:2**num_qubit-1];
wire phase_right_in[0:num_qubit-1];  
wire reg_toggle_phase_vector [0:num_qubit-1]; 
wire [num_qubit-1:0] mapped_reg_toggle_phase_vector; wire phase_left_out[0:num_qubit-1]; 
wire [7:0] ram_alpha_readout; wire ld_rotateLeft_basis;
wire [31:0] counter_valid_phase;
wire [num_qubit-1:0] index_location; wire valid_second_round; wire valid_index_readout; 

//For beta
wire update_flag_basis, rotateLeft_flag_basis, rotateLeft_Q_beta; 
//For nonstabilizer:
wire rotateLeft_P_nonstabilizer, valid_P_nonstabilizer; 
wire flag_nonstabilizer_update [0:2**num_qubit-1];

assign determine_amplitude = determine_amplitude_alpha | determine_amplitude_beta;
assign flag_nonstabilizer_update0 = flag_nonstabilizer_update[0];

/*********************************************************REGISTER ARRAY*********************************************************/
register_array_cofactor reg_array_cofactor (.clk(clk), .rst(rst), .ld_reg(ld_reg), .shift_rotate_array(shift_rotate_array), 
.literals_in(literals_register_array_in), .phase_in(phase_register_array_in), .literals_out(literals_out), .phase_out(phase_out), 
.phase_right_in(phase_right_in), .phase_left_out(phase_left_out), .cofactor_pos(cofactor_pos), .ld_cofactor_info(ld_cofactor_info), 
.reg_cofactor_pos(reg_cofactor_pos)
,.literal_reg(literal_reg), .phase_reg(phase_reg));
defparam reg_array_cofactor.num_qubit = num_qubit;

/******************************************************COMUTATIVITY LITERAL******************************************************/
commutativity_literal comm_literal(.clk(clk), .rst(rst), .rst_flag(rst_flag), .literals_in(literals_in), .phase_in(phase_in), 
.mux_shift_in(mux_shift_in), .literals_shift_out(literals_out), .phase_shift_out(phase_out), .literals_shift_in(literals_register_array_in), 
.phase_shift_in(phase_register_array_in), .flag_anticommute(flag_anticommute), .anticommute(anticommute), .literals_anticommute(literals_anticommute),
.phase_anticommute(phase_anticommute), .flag_nonstabilizer_update(flag_nonstabilizer_update));
defparam comm_literal.num_qubit = num_qubit; 

/********************************************************UPDATE ADD PHASE********************************************************/
update_add_phase update_phase (.clk(clk), .rst(rst), .mux_phase_shift_in(mux_phase_shift_in), .phase_left_out(phase_left_out), 
.phase_right_in(phase_right_in), .reg_toggle_phase_vector(reg_toggle_phase_vector), .mapped_reg_toggle_phase_vector(mapped_reg_toggle_phase_vector), 
.valid_index_readout(valid_index_readout), .valid_second_round(valid_second_round), .counter_valid_vector(counter_valid_vector));
defparam update_phase.num_qubit = num_qubit;

/*******************************************************RAM INDEX CONTROL********************************************************/
ram_index_control index_control (.clk(clk), .rst(rst), .valid_ori_phase_write(valid_ori_phase_write), .ori_phase_vector(phase_left_out),
.output_valid(valid_index_readout), .output_index(index_location), .valid_second_round(valid_second_round), .counter_valid_phase(counter_valid_phase),
.reg_toggle_phase_vector(reg_toggle_phase_vector), .mapped_reg_toggle_phase_vector(mapped_reg_toggle_phase_vector), .done_alpha(done_alpha));
defparam index_control.num_qubit = num_qubit;

/**********************************************************CONTROL UNIT***********************************************************/
control_unit_cofactor cu_cofactor (.clk(clk), .rst(rst), .valid_in(valid_in), .flag_anticommute(flag_anticommute),
.anticommute(anticommute), .reg_cofactor_pos(reg_cofactor_pos), .counter_valid_vector(counter_valid_vector), .ld_cofactor_info(ld_cofactor_info),
.ld_reg(ld_reg), .shift_rotate_array(shift_rotate_array), .rst_flag(rst_flag), .valid_out(valid_out), .valid_ori_phase_write(valid_ori_phase_write),
.mux_shift_in(mux_shift_in), .mux_phase_shift_in(mux_phase_shift_in), .valid_flag_anticommute(valid_flag_anticommute), .done_alpha(done_alpha), 
.state(), .ld_rotateLeft_basis(ld_rotateLeft_basis), .update_flag_basis(update_flag_basis), .ld_prodQ(ld_prodQ), .final_cofactor(final_cofactor),
.rotateLeft_Q_beta(rotateLeft_Q_beta), .rotateLeft_flag_basis(rotateLeft_flag_basis), .literals_out(literals_out), .valid_P(valid_P),
.determine_amplitude_beta(determine_amplitude_beta), .rotateLeft_P_nonstabilizer(rotateLeft_P_nonstabilizer), .phaseShift_toffoli(phaseShift_toffoli),
.valid_P_nonstabilizer(valid_P_nonstabilizer), .done_flag_nonstabilizer_update(done_flag_nonstabilizer_update), .rotateLeft_Q2(rotateLeft_Q2)); 
defparam cu_cofactor.num_qubit = num_qubit;

/******************************************************UPDATE AMPLITUDE COFACTOR*********************************************************/
update_amplitude_cofactor update_amplitude_cof (.clk(clk), .rst(rst), .counter_valid_phase(counter_valid_phase), .valid_second_round(valid_second_round), 
.valid_index_readout(valid_index_readout), .index_location(index_location), .ram_alpha_readout(ram_alpha_readout), .ram_amplitude_readout(ram_amplitude_out), 
.generator_amplitude_address(generator_amplitude_address), .generator_address_valid(generator_address_valid), .ram_amplitude_writein(ram_amplitude_writein), 
.ram_amplitude_writein_en(ram_amplitude_writein_en), .ram_amplitude_writein_address(ram_amplitude_writein_address));
defparam update_amplitude_cof.num_qubit = num_qubit; defparam update_amplitude_cof.complex_bit = complex_bit; 

/******************************************************DETERMINE ALPHA BASIS INDEX********************************************************/
determine_alpha_basis_index alpha_basis_index (.clk(clk), .rst(rst), .literals_P_in(literals_P_in), .valid_P(valid_P), 
.literals_anticommute(literals_anticommute), .phase_anticommute(phase_anticommute), .valid_flag_anticommute(valid_flag_anticommute), 
.flag_anticommute(flag_anticommute), .reg_cofactor_pos(reg_cofactor_pos), .read_alpha_address(generator_amplitude_address), 
.alpha1_out_r(ram_alpha_readout[7:6]), .alpha1_out_i(ram_alpha_readout[5:4]), .alpha2_out_r(ram_alpha_readout[3:2]), .alpha2_out_i(ram_alpha_readout[1:0]), 
.valid_index_readout(valid_index_readout), .valid_second_round(valid_second_round), .ld_rotateLeft_basis(ld_rotateLeft_basis), .basis_index(basis_index), 
.determine_amplitude(determine_amplitude_alpha), .literals_Q(literals_Q), .phase_Q(phase_Q), .done_amplitude(done_amplitude), .ld_rotateLeft(ld_rotateLeft),
.ld_PQ_list1_amp(ld_PQ_list1_amp), .amplitude_r_Q_out(amplitude_r_Q_out), .amplitude_i_Q_out(amplitude_i_Q_out), .write_alpha_enable(write_alpha_enable),
.write_alpha_address(write_alpha_address), .update_flag_basis(update_flag_basis), .ld_prodQ(ld_prodQ), .rotateLeft_Q_beta(rotateLeft_Q_beta), 
.rotateLeft_flag_basis(rotateLeft_flag_basis), .literals_out(literals_out), .phase_out(phase_out), .flag_cofactor(flag_cofactor), 
.rotateLeft_P_nonstabilizer(rotateLeft_P_nonstabilizer), .valid_P_nonstabilizer(valid_P_nonstabilizer), .flag_nonstabilizer_update(flag_nonstabilizer_update),
.rotateLeft_flag_nonstabilizer_update(rotateLeft_flag_nonstabilizer_update), .phaseShift_toffoli(phaseShift_toffoli), .basis_index_in(basis_index_in),
.ld_basis(ld_basis), .write_amplitude1_enable(write_amplitude1_enable), .write_amplitude1(write_amplitude1), .basis_stabilizer(basis_stabilizer),
.rotateLeft_stabilizer_basis(rotateLeft_stabilizer_basis), .basis_index_leftmost(basis_index_leftmost), 
.read_ram_alpha_stabilizer_address(read_ram_alpha_stabilizer_address), .read_ram_alpha_stabilizer_en(read_ram_alpha_stabilizer_en), .read_alpha_out(read_alpha_out),
.valid_P_stabilizer(valid_P_stabilizer), .ld_prodQ_stabilizer(ld_prodQ_stabilizer), .rotateLeft_Q_flag_basis_stabilizer(rotateLeft_Q_flag_basis_stabilizer),
.literals_out_stabilizer(literals_out_stabilizer), .phase_out_stabilizer(phase_out_stabilizer));
defparam alpha_basis_index.num_qubit = num_qubit;

/************************************************DETERMINE & UPDATE AMPLITUDE BETA**************************************************/
update_amplitude_beta update_amp_beta (.clk(clk), .rst(rst), .determine_amplitude_beta(determine_amplitude_beta), .done_amplitude(done_amplitude),
.counter_valid_vector(counter_valid_vector), .ram_amplitude_beta_readout_address(ram_amplitude_beta_readout_address),
.ram_amplitude_beta_readout_en(ram_amplitude_beta_readout_en), .ram_amplitude_beta_readout(ram_amplitude_out), 
.beta_r(amplitude_r_Q_out), .beta_i(amplitude_i_Q_out), .ram_amplitude_beta_writein_en(ram_amplitude_beta_writein_en), .updating_beta(updating_beta),
.ram_amplitude_beta_writein(ram_amplitude_beta_writein), .ram_amplitude_beta_writein_address(ram_amplitude_beta_writein_address),
.determine_amplitude_stabilizer(determine_amplitude_stabilizer));
defparam update_amp_beta.num_qubit = num_qubit; defparam update_amp_beta.complex_bit = complex_bit; 

endmodule 
