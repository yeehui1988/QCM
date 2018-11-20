module top #(parameter num_qubit = 10, complex_bit = 24, fp_bit = 22, phase_lookup = 5)(
input clk, input rst,
//0: Hadamard; 1: Phase; 2: CNOT; 3: Measurement; 4: Controlled Phase-Shift; 5: Toffoli 
//-- Current implementation does not consider measurement. Single qubit measurement can be implemented by simplying cofactor module 
input [2:0] gate_type, 
//For controlled phase-shift gate only
input [phase_lookup-1:0] phase_shift_index,
//For Hadamard & Phase: qubit_pos is the target qubit
//For CNOT & Controlled Phase-Shift: qubit_pos is the control qubit, qubit_pos2 is the target qubit
//For Toffoli: qubit pos & qubit_pos1 are the control qubits, qubit_pos2 is the target qubit  
input [31:0] qubit_pos, input [31:0] qubit_pos2, input [31:0] qubit_pos3, output update_gate_info, input final_gate,
input [1:0] literals_in [0:num_qubit-1], input phase_in [0:2**num_qubit-1], input valid_in,
input [1:0] literals_P_in [0:2**num_qubit-1][0:num_qubit-1], input valid_P_in, 
output [1:0] literals_out[0:num_qubit-1], output phase_out [0:2**num_qubit-1], output valid_out,
output [31:0] counter_valid_vector,  
//For verification:
input [num_qubit-1:0] read_amplitude_verification_address,
output [complex_bit-1:0] ram_amplitude_out_r, output [complex_bit-1:0] ram_amplitude_out_i, 
//For debugging:
output ram_amplitude_busy,
output valid_out_nonstabilizer, output valid_out_stabilizer
);

//For amplitude cofactor module
wire [1:0] literals_Q [0:2**num_qubit-1][0:num_qubit-1]; wire phase_Q [0:2**num_qubit-1];
wire determine_amplitude; 
wire done_amplitude; wire ld_rotateLeft; wire ld_PQ_list1_amp; wire [1:0] amplitude_r_Q_out; wire [1:0] amplitude_i_Q_out;
wire write_alpha_enable; wire [num_qubit-1:0] write_alpha_address; wire done_alpha, determine_amplitude_alpha, determine_amplitude_beta;

//For ram amplitude control module 
wire ram_amplitude_writein_en; wire [2*complex_bit-1:0] ram_amplitude_writein; wire [num_qubit-1:0] ram_amplitude_writein_address;
wire [num_qubit-1:0] generator_amplitude_address; wire generator_address_valid; wire [2*complex_bit-1:0] ram_amplitude_out;

//For cofactor: beta
wire [num_qubit-1:0] ram_amplitude_beta_readout_address; wire ram_amplitude_beta_readout_en;
wire ram_amplitude_beta_writein_en; wire [2*complex_bit-1:0] ram_amplitude_beta_writein; wire [num_qubit-1:0] ram_amplitude_beta_writein_address;

//For cofactor: top
wire valid_P_cofactor, valid_in_cofactor, valid_out_cofactor;
wire [1:0] literals_in_cofactor [0:num_qubit-1]; wire phase_in_cofactor [0:2**num_qubit-1]; 
wire [1:0] literals_out_cofactor [0:num_qubit-1]; wire phase_out_cofactor [0:2**num_qubit-1];
wire valid_flag_anticommute, flag_anticommute; wire [31:0] cofactor_pos;

//For cofactor: input to each round of cofactor: cofactor (default/alpha) + canonical + cofactor (beta) => based on deterministic or randomized outcome
wire valid_in_individual_cofactor, valid_out_individual_cofactor;
wire [1:0] literals_in_individual_cofactor [0:num_qubit-1]; wire phase_in_individual_cofactor [0:2**num_qubit-1];
wire [1:0] literals_out_individual_cofactor [0:num_qubit-1]; wire phase_out_individual_cofactor [0:2**num_qubit-1]; 
wire ready_cofactor, final_cofactor;

//For canonical:
wire rst_canonical, valid_in_canonical, valid_out_canonical, valid_P_canonical; 
reg [1:0] literals_in_canonical [0:num_qubit-1]; reg phase_in_canonical [0:2**num_qubit-1]; 
wire [1:0] literals_out_canonical [0:num_qubit-1]; wire phase_out_canonical [0:2**num_qubit-1];
wire [1:0] literals_P_canonical [0:2**num_qubit-1][0:num_qubit-1]; wire [1:0] literals_P [0:2**num_qubit-1][0:num_qubit-1];
wire [1:0] literals_in_canonical_for_toffoli [0:num_qubit-1]; wire phase_in_canonical_for_toffoli [0:2**num_qubit-1]; wire valid_in_canonical_for_toffoli;
wire [1:0] literals_in_canonical_for_cofactor [0:num_qubit-1]; wire phase_in_canonical_for_cofactor [0:2**num_qubit-1]; wire valid_in_canonical_for_cofactor;

//For nonstabilizer:
wire flag_cofactor [0:num_qubit-1]; wire phaseShift_toffoli; 
wire [num_qubit-1:0] ram_amplitude_nonstabilizer_readout_address; wire ram_amplitude_nonstabilizer_readout_en;
wire ram_amplitude_nonstabilizer_writein_en; wire [num_qubit-1:0] ram_amplitude_nonstabilizer_writein_address;
wire [2*complex_bit-1:0] ram_amplitude_nonstabilizer_writein; wire done_flag_nonstabilizer_update; wire updating_beta;
wire flag_nonstabilizer_update0; wire rotateLeft_flag_nonstabilizer_update;

//For stabilizer:
wire valid_out_buffer; wire mask_valid_buffer;
wire basis_index_in [0:num_qubit-1]; wire ld_basis, ld_prodQ, rotateLeft_Q2; 
wire write_amplitude1_enable; wire [7:0] write_amplitude1;
wire rotateLeft_stabilizer_basis; wire basis_stabilizer [0:num_qubit-1]; wire basis_index_leftmost [0:num_qubit-1];
wire [num_qubit-1:0] read_ram_alpha_stabilizer_address; wire read_ram_alpha_stabilizer_en; wire [7:0] read_alpha_out; wire valid_in_conjugation;
wire read_amplitude_alpha_stabilizer_en, first_gate; wire [num_qubit-1:0] read_amplitude_alpha_stabilizer_address;
wire write_amplitude_alpha_stabilizer_en; wire [num_qubit-1:0] write_amplitude_alpha_stabilizer_address; 
wire [2*complex_bit-1:0] write_amplitude_alpha_stabilizer; 
wire [1:0] literals_Q2 [0:2**num_qubit-1][0:num_qubit-1]; wire phase_Q2 [0:2**num_qubit-1]; wire determine_amplitude2, ld_rotateLeft_Q2;
wire [1:0] literals_out_cba [0:num_qubit-1]; wire phase_out_cba [0:2**num_qubit-1]; wire valid_out_cba;

//For overall control:
wire [2:0] gate_type_norm; wire [phase_lookup-1:0] phase_shift_index_norm; 
wire [31:0] qubit_pos_norm; wire [31:0] qubit_pos2_norm; wire [31:0] qubit_pos3_norm; wire [2:0] gate_type_ahead; wire [31:0] qubit_pos_ahead; 
wire [1:0] literals_in_nonstabilizer [0:num_qubit-1]; wire phase_in_nonstabilizer [0:2**num_qubit-1]; wire valid_in_nonstabilizer;
wire [1:0] literals_out_nonstabilizer_no_buffer [0:num_qubit-1]; wire phase_out_nonstabilizer_no_buffer [0:2**num_qubit-1]; wire valid_out_nonstabilizer_no_buffer; 
wire valid_out_nonstabilizer_buffer;
wire [1:0] literals_in_stabilizer [0:num_qubit-1]; wire phase_in_stabilizer [0:2**num_qubit-1]; wire valid_in_stabilizer;
wire [1:0] literals_out_stabilizer [0:num_qubit-1]; wire phase_out_stabilizer [0:2**num_qubit-1];

//Temporary:
wire valid_P_overall_nonstabilizer, valid_P_nonstabilizer, valid_P_nonstabilizer_intermediate, valid_P_canonical_mask, valid_P_from_stabilizer_to_nonstabilizer;
wire ld_prodQ_stabilizer, rotateLeft_Q_flag_basis_stabilizer, determine_amplitude_stabilizer, fsm_amplitude_busy, ram_amplitude_busy_pre;

assign valid_P_canonical_mask = valid_P_canonical && mask_valid_buffer;
assign valid_P_overall_nonstabilizer = valid_P_nonstabilizer | valid_P_nonstabilizer_intermediate | valid_P_canonical_mask | valid_P_from_stabilizer_to_nonstabilizer
| (valid_P_in & gate_type_norm >3'd3); 

wire rst_amplitude_cofactor, valid_P_stabilizer;
assign rst_amplitude_cofactor = valid_in_cofactor | valid_in_stabilizer | valid_P_stabilizer;

reg reg_ram_amplitude_busy_pre, reg2_ram_amplitude_busy_pre, reg3_ram_amplitude_busy_pre, reg_fsm_amplitude_busy, reg2_fsm_amplitude_busy;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		reg_ram_amplitude_busy_pre <= 1'd0; reg2_ram_amplitude_busy_pre <= 1'd0; reg3_ram_amplitude_busy_pre <= 1'd0;
		reg_fsm_amplitude_busy <= 1'd0; reg2_fsm_amplitude_busy <= 1'd0;
	end
	else
	begin
		reg_ram_amplitude_busy_pre <= ram_amplitude_busy_pre; 
		reg2_ram_amplitude_busy_pre <= reg_ram_amplitude_busy_pre;
		reg3_ram_amplitude_busy_pre <= reg2_ram_amplitude_busy_pre;
		reg_fsm_amplitude_busy <= fsm_amplitude_busy; reg2_fsm_amplitude_busy <= reg_fsm_amplitude_busy;
	end
end

assign ram_amplitude_busy = ram_amplitude_busy_pre | reg_ram_amplitude_busy_pre | reg2_ram_amplitude_busy_pre | reg3_ram_amplitude_busy_pre 
| fsm_amplitude_busy | reg_fsm_amplitude_busy | reg2_fsm_amplitude_busy | write_amplitude1_enable;


/*******************************************************DETERMINE AMPLITUDE********************************************************/
amplitude_cofactor amplitude_cof (.clk(clk), .rst_new(rst), .determine_amplitude_nonstabilizer(determine_amplitude), 
.determine_amplitude_stabilizer(determine_amplitude_stabilizer), .literals_in_Q1(literals_Q), .phase_in_Q1(phase_Q), .done_amplitude(done_amplitude), 
.ld_rotateLeft(ld_rotateLeft), .ld_rotateLeft_PQ_list(ld_PQ_list1_amp), .amplitude_r_Q_out(amplitude_r_Q_out), 
.amplitude_i_Q_out(amplitude_i_Q_out), .write_alpha_enable(write_alpha_enable), .write_alpha_address(write_alpha_address), .ready_cofactor(ready_cofactor), 
.valid_out(rst_amplitude_cofactor), .counter_valid_vector(counter_valid_vector), .done_alpha(done_alpha), .determine_amplitude_alpha(determine_amplitude_alpha),
.determine_amplitude_beta(determine_amplitude_beta), .final_cofactor(final_cofactor), .write_amplitude1_enable(write_amplitude1_enable), 
.write_amplitude1(write_amplitude1), .gate_type_ahead(gate_type_ahead), .determine_amplitude2(determine_amplitude2), .ld_rotateLeft_Q2(ld_rotateLeft_Q2),
.literals_in_Q2(literals_Q2), .phase_in_Q2(phase_Q2), .fsm_amplitude_busy(fsm_amplitude_busy));
defparam amplitude_cof.num_qubit = num_qubit; 


/*******************************************************RAM AMPLITUDE CONTROL********************************************************/
ram_amplitude_control amplitude_control (.clk(clk), .rst(rst), .ram_amplitude_busy(ram_amplitude_busy_pre),
.wr_enable1(ram_amplitude_writein_en), .write_amplitude1(ram_amplitude_writein), .wr_address1(ram_amplitude_writein_address), 
.wr_enable2(ram_amplitude_beta_writein_en), .write_amplitude2(ram_amplitude_beta_writein), .wr_address2(ram_amplitude_beta_writein_address), 
.wr_enable3(ram_amplitude_nonstabilizer_writein_en), .write_amplitude3(ram_amplitude_nonstabilizer_writein),
.wr_address3(ram_amplitude_nonstabilizer_writein_address), 
.wr_enable4(write_amplitude_alpha_stabilizer_en), .write_amplitude4(write_amplitude_alpha_stabilizer),
.wr_address4(write_amplitude_alpha_stabilizer_address), 
.rd_address0(read_amplitude_verification_address), .rd_address1(generator_amplitude_address), .rd_enable1(generator_address_valid), 
.rd_address2(ram_amplitude_beta_readout_address), .rd_enable2(ram_amplitude_beta_readout_en), .read_amplitude(ram_amplitude_out),
.rd_address3(ram_amplitude_nonstabilizer_readout_address), .rd_enable3(ram_amplitude_nonstabilizer_readout_en),
.rd_address4(read_amplitude_alpha_stabilizer_address), .rd_enable4(read_amplitude_alpha_stabilizer_en)
);
defparam amplitude_control.num_qubit = num_qubit; defparam amplitude_control.complex_bit = complex_bit; defparam amplitude_control.fp_bit = fp_bit; 

assign ram_amplitude_out_r = ram_amplitude_out [2*complex_bit-1:complex_bit]; assign ram_amplitude_out_i = ram_amplitude_out[complex_bit-1:0]; 


/*******************************************************CANONICAL REDUCTION***********************************************************/
//Apply Canonical Reduction for	(a) Cofactor in nonstabilizer operation (b) After Toffoli updated in nonstabilizer operation
//								(c) After conjugation-by-action in stabilizer operation
assign valid_in_canonical = valid_in_canonical_for_toffoli | valid_in_canonical_for_cofactor | valid_out_cba;
always@(*)
begin
	if(valid_in_canonical_for_cofactor)
	begin
		literals_in_canonical <= literals_in_canonical_for_cofactor; phase_in_canonical <= phase_in_canonical_for_cofactor;
	end
	else if(valid_out_cba)
	begin
		literals_in_canonical <= literals_out_cba; phase_in_canonical <= phase_out_cba;
	end
	else //valid_in_canonical_for_toffoli
	begin
		literals_in_canonical <= literals_in_canonical_for_toffoli; phase_in_canonical <= phase_in_canonical_for_toffoli;
	end
end

//valid_P_canonical --Take out for now
canonical canonical_top (.clk(clk), .rst_new(rst_canonical), .literals_in(literals_in_canonical), .phase_in(phase_in_canonical), 
.valid_in(valid_in_canonical), .literals_out(literals_out_canonical), .phase_out(phase_out_canonical), .flag_out(valid_out_canonical),
.literals_P(literals_P_canonical), .valid_P(valid_P_canonical)
, .phase_P(), .counter_P(), .trans_literal_retain_outX(), .trans_flag_retain_outX(), .trans_phase_retain_outX(), .trans_literal_retain_outZ(),
.trans_flag_retain_outZ(), .trans_phase_retain_outZ(), .storage_literal_outX(), .storage_flag_outX(), .storage_phase_outX(), .storage_literal_outZ(),
.storage_flag_outZ(), .storage_phase_outZ());
defparam canonical_top.num_qubit = num_qubit; 


/***********************************************************COFACTOR***************************************************************/
cofactor cofactor_module (.clk(clk), .rst(rst), .cofactor_pos(cofactor_pos), .literals_in(literals_in_cofactor), .determine_amplitude_beta(determine_amplitude_beta),
.phase_in(phase_in_cofactor), .valid_in(valid_in_cofactor), .literals_P_in(literals_P), .valid_P(valid_P_cofactor), .literals_out(literals_out_cofactor), 
.phase_out(phase_out_cofactor), .valid_out(valid_out_cofactor), .valid_flag_anticommute(valid_flag_anticommute), .flag_anticommute(flag_anticommute), 
.counter_valid_vector(counter_valid_vector), .basis_index(), .determine_amplitude(determine_amplitude), .literals_Q(literals_Q), 
.phase_Q(phase_Q), .done_amplitude(done_amplitude), .ld_rotateLeft(ld_rotateLeft), .ld_PQ_list1_amp(ld_PQ_list1_amp), .amplitude_r_Q_out(amplitude_r_Q_out), 
.amplitude_i_Q_out(amplitude_i_Q_out), .write_alpha_enable(write_alpha_enable), .write_alpha_address(write_alpha_address), .done_alpha(done_alpha), 
.ram_amplitude_writein_en(ram_amplitude_writein_en), .ram_amplitude_writein(ram_amplitude_writein), .determine_amplitude_alpha(determine_amplitude_alpha),
.ram_amplitude_writein_address(ram_amplitude_writein_address), .generator_amplitude_address(generator_amplitude_address), 
.generator_address_valid(generator_address_valid), .ram_amplitude_out(ram_amplitude_out), .final_cofactor(final_cofactor), .flag_cofactor(flag_cofactor),
.ram_amplitude_beta_readout_address(ram_amplitude_beta_readout_address), .ram_amplitude_beta_readout_en(ram_amplitude_beta_readout_en),
.ram_amplitude_beta_writein_en(ram_amplitude_beta_writein_en), .ram_amplitude_beta_writein(ram_amplitude_beta_writein), .phaseShift_toffoli(phaseShift_toffoli),
.ram_amplitude_beta_writein_address(ram_amplitude_beta_writein_address), .flag_nonstabilizer_update0(flag_nonstabilizer_update0), 
.done_flag_nonstabilizer_update(done_flag_nonstabilizer_update), .updating_beta(updating_beta), .basis_index_in(basis_index_in), .ld_basis(ld_basis), 
.rotateLeft_flag_nonstabilizer_update(rotateLeft_flag_nonstabilizer_update), .ld_prodQ(ld_prodQ), .rotateLeft_Q2(rotateLeft_Q2),
.literal_reg(), .phase_reg(), .write_amplitude1_enable(write_amplitude1_enable), .write_amplitude1(write_amplitude1),
.basis_stabilizer(basis_stabilizer), .rotateLeft_stabilizer_basis(rotateLeft_stabilizer_basis), .basis_index_leftmost(basis_index_leftmost), 
.read_ram_alpha_stabilizer_address(read_ram_alpha_stabilizer_address), .read_ram_alpha_stabilizer_en(read_ram_alpha_stabilizer_en), .read_alpha_out(read_alpha_out),
.valid_P_stabilizer(valid_P_stabilizer), .ld_prodQ_stabilizer(ld_prodQ_stabilizer), .rotateLeft_Q_flag_basis_stabilizer(rotateLeft_Q_flag_basis_stabilizer),
.literals_out_stabilizer(literals_out_stabilizer), .phase_out_stabilizer(phase_out_stabilizer), .determine_amplitude_stabilizer(determine_amplitude_stabilizer)
);  
defparam cofactor_module.num_qubit = num_qubit; defparam cofactor_module.complex_bit = complex_bit; //basis_index, 


/****************************************************COFACTOR OVERALL CONTROL********************************************************/
control_unit_cofactor_top cu_cofactor_top (.clk(clk), .rst(rst), .valid_out_cofactor(valid_out_cofactor), .valid_flag_anticommute(valid_flag_anticommute), 
.flag_anticommute(flag_anticommute), .literals_out_cofactor(literals_out_cofactor), .phase_out_cofactor(phase_out_cofactor), .valid_P_cofactor(valid_P_cofactor), 
.valid_in_cofactor(valid_in_cofactor), .literals_in_cofactor(literals_in_cofactor), .phase_in_cofactor(phase_in_cofactor), 
.valid_out_canonical(valid_out_canonical), .literals_out_canonical(literals_out_canonical), .phase_out_canonical(phase_out_canonical), 
.rst_canonical(rst_canonical), .valid_in_canonical(valid_in_canonical_for_cofactor), .literals_in_canonical(literals_in_canonical_for_cofactor), 
.phase_in_canonical(phase_in_canonical_for_cofactor), .literals_out(literals_out_individual_cofactor), .phase_out(phase_out_individual_cofactor), 
.valid_out(valid_out_individual_cofactor), .literals_in(literals_in_individual_cofactor), .phase_in(phase_in_individual_cofactor), 
.valid_in(valid_in_individual_cofactor), .valid_P(valid_P_overall_nonstabilizer));  
defparam cu_cofactor_top.num_qubit = num_qubit;


/*************************************************NONSTABILIZER OPERATION********************************************************/
//For nonstablizer gate operation, it calls cofactor (main & controller) & canonical modules
//This module initiate & control & synchoronize the usage of those modules based on the called nonstabilizer gates.
//In this work, the nonstabilizer gates that we consider are TOFFOLI & Controlled-Phase-Shift
//Input literals for stabilizer gates should not be sent here. Assume valid_in signal has been filtered

nonstabilizer_operation nonstabilizer_op (.clk(clk),  .rst(rst), .gate_type(gate_type_norm), .phase_shift_index(phase_shift_index_norm), 
.qubit_pos(qubit_pos_norm), .qubit_pos2(qubit_pos2_norm), .qubit_pos3(qubit_pos3_norm), 
.literals_in(literals_in_nonstabilizer), .phase_in(phase_in_nonstabilizer), .valid_in(valid_in_nonstabilizer), 
.literals_out(literals_out_nonstabilizer_no_buffer), .phase_out(phase_out_nonstabilizer_no_buffer), .valid_out(valid_out_nonstabilizer_no_buffer), 
.literals_out_individual_cofactor(literals_out_individual_cofactor), .phase_out_individual_cofactor(phase_out_individual_cofactor),
.valid_out_individual_cofactor(valid_out_individual_cofactor), .literals_in_individual_cofactor(literals_in_individual_cofactor), .flag_cofactor(flag_cofactor),
.phase_in_individual_cofactor(phase_in_individual_cofactor), .valid_in_individual_cofactor(valid_in_individual_cofactor), 
.cofactor_pos(cofactor_pos), .final_cofactor(final_cofactor), .phaseShift_toffoli(phaseShift_toffoli), 
.ram_amplitude_out_r(ram_amplitude_out_r), .ram_amplitude_out_i(ram_amplitude_out_i), .mask_valid_buffer(mask_valid_buffer),
.ram_amplitude_nonstabilizer_readout_address(ram_amplitude_nonstabilizer_readout_address), .flag_nonstabilizer_update0(flag_nonstabilizer_update0),
.ram_amplitude_nonstabilizer_readout_en(ram_amplitude_nonstabilizer_readout_en), .ram_amplitude_nonstabilizer_writein_en(ram_amplitude_nonstabilizer_writein_en),
.ram_amplitude_nonstabilizer_writein_address(ram_amplitude_nonstabilizer_writein_address), .ram_amplitude_nonstabilizer_writein(ram_amplitude_nonstabilizer_writein),
.done_flag_nonstabilizer_update(done_flag_nonstabilizer_update), .updating_beta(updating_beta), .counter_valid_vector(counter_valid_vector),
.rotateLeft_flag_nonstabilizer_update(rotateLeft_flag_nonstabilizer_update), .literals_in_canonical_for_toffoli(literals_in_canonical_for_toffoli), 
.phase_in_canonical_for_toffoli(phase_in_canonical_for_toffoli), .valid_in_canonical_for_toffoli(valid_in_canonical_for_toffoli), 
.literals_out_canonical(literals_out_canonical), .phase_out_canonical(phase_out_canonical), .valid_out_canonical(valid_out_canonical),
.valid_out_buffer(valid_out_buffer), .literals_out_stabilizer(literals_out_stabilizer), .phase_out_stabilizer(phase_out_stabilizer));
defparam nonstabilizer_op.num_qubit = num_qubit; defparam nonstabilizer_op.complex_bit = complex_bit; defparam nonstabilizer_op.fp_bit = fp_bit; 
defparam nonstabilizer_op.phase_lookup = phase_lookup; 

/*****************************************************STABILIZER OPERATION************************************************************/
stabilizer_operation stabilizer_op (.clk(clk), .rst(rst), .gate_type_norm(gate_type_norm), .qubit_pos_norm(qubit_pos_norm), .qubit_pos2_norm(qubit_pos2_norm), 
.qubit_pos_ahead(qubit_pos_ahead), .literals_P(literals_P), .valid_out_individual_cofactor(valid_out_individual_cofactor), 
.literals_out_individual_cofactor(literals_out_individual_cofactor), .phase_out_individual_cofactor(phase_out_individual_cofactor), 
.ready_cofactor(ready_cofactor), .valid_P_nonstabilizer_intermediate(valid_P_nonstabilizer_intermediate), .valid_out_buffer(valid_out_buffer),
.literals_out_stabilizer(literals_out_stabilizer), .phase_out_stabilizer(phase_out_stabilizer), .mask_valid_buffer(mask_valid_buffer),
.basis_index_in(basis_index_in), .ld_basis_index_in(ld_basis), .ld_prodQ(ld_prodQ), .valid_P_beta(valid_P_canonical_mask), .rotateLeft_Q2(rotateLeft_Q2), 
.literals_out_cofactor(literals_out_cofactor), .phase_out_cofactor(phase_out_cofactor), .rotateLeft_stabilizer_basis(rotateLeft_stabilizer_basis),
.basis_stabilizer(basis_stabilizer), .basis_index_leftmost(basis_index_leftmost), .read_ram_alpha_stabilizer_address(read_ram_alpha_stabilizer_address), 
.read_ram_alpha_stabilizer_en(read_ram_alpha_stabilizer_en), .read_alpha_out(read_alpha_out), .amplitude_r_Q_out(amplitude_r_Q_out), 
.amplitude_i_Q_out(amplitude_i_Q_out), .ram_amplitude_out_r(ram_amplitude_out_r), .ram_amplitude_out_i(ram_amplitude_out_i), .first_gate(first_gate),
.counter_valid_vector(counter_valid_vector), .done_amplitude(done_amplitude), .ram_amplitude_busy(ram_amplitude_busy),
.valid_in_stabilizer(valid_in_stabilizer), .valid_out_nonstabilizer_buffer(valid_out_nonstabilizer_buffer), .determine_amplitude2(determine_amplitude2), 
.literals_Q2(literals_Q2), .phase_Q2(phase_Q2), .valid_out_canonical(valid_out_canonical), .read_amplitude_alpha_stabilizer_en(read_amplitude_alpha_stabilizer_en), 
.read_amplitude_alpha_stabilizer_address(read_amplitude_alpha_stabilizer_address), .write_amplitude_alpha_stabilizer_en(write_amplitude_alpha_stabilizer_en), 
.write_amplitude_alpha_stabilizer_address(write_amplitude_alpha_stabilizer_address), .write_amplitude_alpha_stabilizer(write_amplitude_alpha_stabilizer),
.literals_in_stabilizer(literals_in_stabilizer), .phase_in_stabilizer(phase_in_stabilizer), .valid_out_stabilizer(valid_out_stabilizer),
.literals_out_cba(literals_out_cba), .phase_out_cba(phase_out_cba), .valid_out_cba(valid_out_cba), .determine_amplitude_stabilizer(determine_amplitude_stabilizer),
.literals_out_canonical(literals_out_canonical), .phase_out_canonical(phase_out_canonical), 
.valid_P_from_stabilizer_to_nonstabilizer(valid_P_from_stabilizer_to_nonstabilizer), .valid_P_stabilizer(valid_P_stabilizer),
.ld_prodQ_stabilizer(ld_prodQ_stabilizer), .rotateLeft_Q_flag_basis_stabilizer(rotateLeft_Q_flag_basis_stabilizer), .ld_rotateLeft_Q2(ld_rotateLeft_Q2), 
.literal_reg(), .phase_reg() 
); 
defparam stabilizer_op.num_qubit = num_qubit; defparam stabilizer_op.complex_bit = complex_bit; defparam stabilizer_op.fp_bit = fp_bit; 


/*****************************************************CONTROL UNIT OVERALL**********************************************************/
control_unit_overall cu_overall (.clk(clk), .rst(rst), .gate_type(gate_type), .phase_shift_index(phase_shift_index), .qubit_pos(qubit_pos), 
.qubit_pos2(qubit_pos2), .qubit_pos3(qubit_pos3), .valid_out_individual_cofactor(valid_out_cofactor), .update_gate_info(update_gate_info), 
.gate_type_norm(gate_type_norm), .phase_shift_index_norm(phase_shift_index_norm), .qubit_pos_norm(qubit_pos_norm), .qubit_pos2_norm(qubit_pos2_norm),
.qubit_pos3_norm(qubit_pos3_norm), .gate_type_ahead(gate_type_ahead), .qubit_pos_ahead(qubit_pos_ahead), .first_gate(first_gate), .final_gate(final_gate),
//For nonstabilizer:
.literals_in_nonstabilizer(literals_in_nonstabilizer), .phase_in_nonstabilizer(phase_in_nonstabilizer), .valid_in_nonstabilizer(valid_in_nonstabilizer), 
.literals_out_nonstabilizer_no_buffer(literals_out_nonstabilizer_no_buffer), .phase_out_nonstabilizer_no_buffer(phase_out_nonstabilizer_no_buffer), 
.valid_out_nonstabilizer(valid_out_nonstabilizer), .valid_out_nonstabilizer_no_buffer(valid_out_nonstabilizer_no_buffer), 
.valid_out_nonstabilizer_buffer(valid_out_nonstabilizer_buffer), .valid_P_nonstabilizer (valid_P_nonstabilizer), //Generate for nonstabilizer input
//For stabilizer:
.literals_in_stabilizer(literals_in_stabilizer), .phase_in_stabilizer(phase_in_stabilizer), .valid_in_stabilizer(valid_in_stabilizer), 
.literals_out_stabilizer(literals_out_stabilizer), .phase_out_stabilizer(phase_out_stabilizer), .valid_out_stabilizer(valid_out_stabilizer), 
//Overall:
.literals_out(literals_out), .phase_out(phase_out), .valid_out(valid_out),
//Input from external: for verification purposes only. Actual implementation will be initialized to basis state |0(x)n>
.literals_in(literals_in), .phase_in(phase_in), .valid_in(valid_in),
//For P:
.literals_P_in(literals_P_in), .valid_P_in(valid_P_in), .literals_P_canonical(literals_P_canonical), .literals_P(literals_P)
);
defparam cu_overall.num_qubit = num_qubit; defparam cu_overall.phase_lookup = phase_lookup; 

endmodule 
