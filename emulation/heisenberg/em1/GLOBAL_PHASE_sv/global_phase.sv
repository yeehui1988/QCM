module global_phase #(parameter num_qubit = 4)(
//General:
input clk, input rst, input start,
//For register array & gate info & P 
input [1:0] gate_type, //0: Hadamard; 1: Phase; 2: CNOT
input [31:0] qubit_pos, input [31:0] qubit_pos2, 
input [1:0] literals_P [0:num_qubit-1], input phase_P, input valid_P,
input [1:0] literals_in [0:num_qubit-1], input phase_in, input valid_in, 
output basis_index[0:num_qubit-1], output basis_index2 [0:num_qubit-1],
output signed [31:0] alpha_r, output signed [31:0] alpha_i, output signed [31:0] beta_r, output signed [31:0] beta_i,
//For readout: literals & phases & count factor for H & global phase:
output [3:0] state_CU, output [1:0] reg_gate_type, output reg [1:0] reg2_gate_type,
input literal_phase_readout, output [31:0] count_H, //Keep track of the constant factor of count_H * 0.707107 
output [1:0] literals_out[0:num_qubit-1], output phase_out, output valid_out, output done_readout,
output signed [31:0] global_phase_r, output signed [31:0] global_phase_i, output gp_ready,
//For measurement:
input flag_anticommute 
);

integer i,j;
//start should be one clock pulse signal
wire rst_new;
assign rst_new = rst | start;

/***************************REGISTERS TO STORE STABILIZER MATRIX & GATE INFO & P*****************************/
wire ld_reg, ld_gate_info;
wire [1:0] shift_rotate_array; wire [31:0] reg_qubit_pos; wire [31:0] reg_qubit_pos2;
wire [1:0] reg_literals_P [0:num_qubit-1]; wire reg_phase_P; reg basis_index_P [0:num_qubit-1];
//wire [1:0] reg_gate_type; 
wire ld_measure_update;

register_array #(num_qubit) reg_array
(.clk(clk), .rst_new(rst_new), .rst(rst), .ld_reg(ld_reg), .literals_in(literals_in),
.shift_rotate_array(shift_rotate_array), .phase_in(phase_in), .literals_out(literals_out), .phase_out(phase_out), 
.gate_type(gate_type), .qubit_pos(qubit_pos), .qubit_pos2(qubit_pos2), .ld_gate_info(ld_gate_info), 
.reg_gate_type(reg_gate_type), .reg_qubit_pos(reg_qubit_pos), .reg_qubit_pos2(reg_qubit_pos2), 
.literals_P(literals_P), .phase_P(phase_P), .valid_P(valid_P), .reg_literals_P(reg_literals_P), 
.reg_phase_P(reg_phase_P));
//defparam reg_array.num_qubit = num_qubit; 

always@(*)
begin
	for(i=0;i<num_qubit;i++)
	begin
		basis_index_P [i] <= literals_P [i][1];
	end
end

/***************************REGISTERS TO STORE Q & Q2 AND MUX TO SELECT THE INPUT*****************************/
//Q is first initialized to P
//Then perform row mult with row in M with matching basis_index of interest
wire ld_Q, ld_Q2, load_rotate_Q, load_Q_mux;
wire [1:0] reg_literals_Q [0:num_qubit-1]; wire reg_phase_Q;
wire [1:0] reg_literals_Q2 [0:num_qubit-1]; wire reg_phase_Q2;

module_Q #(num_qubit) mod_Q 
(.clk(clk), .rst_new(rst_new), .ld_Q(ld_Q), .ld_Q2(ld_Q2), .load_rotate_Q(load_rotate_Q), 
.reg_literals_P(reg_literals_P), .reg_phase_P(reg_phase_P), .load_Q_mux(load_Q_mux), .literals_out(literals_out), 
.phase_out(phase_out), .reg_literals_Q(reg_literals_Q), .reg_phase_Q(reg_phase_Q), .reg_literals_Q2(reg_literals_Q2),
 .reg_phase_Q2(reg_phase_Q2));
//defparam mod_Q.num_qubit = num_qubit;

/*******************************************LITERAL TO BASIS CONVERSION*****************************************/
/*             L[0] ... L[num_qubit-1] 																						      */
/* B[31] ..0.. B [num_qubit-1] ... B[0]																						      */
/***************************************************************************************************************/

/************************************PRE-CALCULATION OF CONSTANT FOR ALPHA*************************************/
//Pre-calculate: Based on gate type and qubit position (CNOT does not need this)
//For Hadamard and Phase: 
//k_bit = num_qubit - (pos + 1)
//For HW implementation there is no need to compute 2^k and determine if it is odd or even
//Just have to check if qubit k of basis_index is 0 (even) or 1 (odd) to identify the specific gate element 
/*
wire [31:0] k_bit;
assign k_bit = num_qubit - reg_qubit_pos - 1;
*/
//Add another gate info registers which update triggered by valid_P
//reg [1:0] reg2_gate_type; 
reg [31:0] reg2_qubit_pos; //reg [31:0] reg2_qubit_pos2;
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		reg2_gate_type <= 2'd0; reg2_qubit_pos <= 32'd0; 
	end
	else
	begin
		if(valid_P == 1'd1)
		begin
			reg2_gate_type <= gate_type; reg2_qubit_pos <= qubit_pos; 
		end
	end
end

/*****************************REGISTERS TO STORE & UPDATE BASIS_INDEX & BASIS_INDEX2*****************************/
wire ld_basis_index, ld_basis_index2, initial_alpha_zero;

//Use gate info from update triggered by valid_P 
module_basis_index  #(num_qubit) mod_basisIndex 
(.clk(clk), .rst_new(rst_new), .ld_basis_index(ld_basis_index), 
.ld_basis_index2(ld_basis_index2), .initial_alpha_zero(initial_alpha_zero), .reg2_qubit_pos(reg2_qubit_pos), //.k_bit(k_bit2), 
.reg_gate_type(reg_gate_type), .reg_qubit_pos(reg_qubit_pos), .basis_index_P(basis_index_P), 
.reg_qubit_pos2(reg_qubit_pos2), .basis_index(basis_index), .basis_index2(basis_index2));
//defparam mod_basisIndex.num_qubit = num_qubit;

/***********************FLAG TO KEEP TRACK OF AMPLITUDE EXTRACTION OF SPECIFIC BASIS_INDEX************************/
wire ld_flag_pos, ld_flag_pos2; wire [1:0] load_update_flag;
wire flag_basis_pos [0:num_qubit-1]; wire flag_basis_pos2 [0:num_qubit-1];

flag_basis #(num_qubit) flagBasis 
(.clk(clk), .rst_new(rst_new), .ld_flag_pos(ld_flag_pos), .ld_flag_pos2(ld_flag_pos2), 
.load_update_flag(load_update_flag), .basis_index(basis_index), .basis_index2(basis_index2), 
.literals_out(literals_out), .flag_basis_pos(flag_basis_pos), .flag_basis_pos2(flag_basis_pos2)
, .reg_literals_P(reg_literals_P));
//defparam flagBasis.num_qubit = num_qubit;

/**********************FSM TO DETERMINE RESULTED PRODUCT OF Q & ROW AS PER BASIS-OF_INTEREST***********************/
//LOAD BASIS INDEX BEFORE DETERMINE PRODUCT OF Q!!!
//Use gate info from update triggered by valid_P 
wire determine_multQ, done_multQ;
wire ld_reg0_prodQ, ld_reg1_prodQ, ld_reg2_prodQ, ld_Q_loadP_prodQ, ld_Q_loadMultQ_prodQ, ld_Q_rotateLeft_prodQ, 
ld_Q2_loadP_prodQ, ld_Q2_loadMultQ_prodQ, ld_Q2_rotateLeft_prodQ; 

fsm_productQ #(num_qubit) prodQ 
(.clk(clk), .rst_new(rst_new), .determine_multQ(determine_multQ), .reg_gate_type(reg2_gate_type), 
.literals_out(literals_out), .valid_P(valid_P), .flag_basis_pos(flag_basis_pos), .flag_basis_pos2(flag_basis_pos2), 
.done_multQ(done_multQ), .ld_basis_index2(ld_basis_index2), .ld_flag_pos(ld_flag_pos), 
.load_update_flag(load_update_flag), .ld_flag_pos2(ld_flag_pos2), .ld_reg0(ld_reg0_prodQ), .ld_reg1(ld_reg1_prodQ), 
.ld_reg2(ld_reg2_prodQ), .ld_Q_loadP(ld_Q_loadP_prodQ), .ld_Q_loadMultQ(ld_Q_loadMultQ_prodQ), 
.ld_Q_rotateLeft(ld_Q_rotateLeft_prodQ), .ld_Q2_loadP(ld_Q2_loadP_prodQ), .ld_Q2_loadMultQ(ld_Q2_loadMultQ_prodQ), 
.ld_Q2_rotateLeft(ld_Q2_rotateLeft_prodQ));
//defparam prodQ.num_qubit = num_qubit;

/**********************CHECK IF RESULTED PRODUCT Q MATCH WITH DESIRED SPECIFIC BASIS INDEX***********************/
//Set the amplitude to 0 if this is unmatched
//0: Unmatched; 1: Matched
//DO THIS BEFORE EXTRACT OR FINALIZED EXTRACTED AMPLITUDE!!!
wire ld_matchQ_index;
reg matchQ_index, matchQ2_index;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		matchQ_index <= 1'd1; matchQ2_index <= 1'd1;
	end
	else
	begin
		if(ld_matchQ_index)
		begin
			matchQ_index <= 1'd1; matchQ2_index <= 1'd1;
			for(i=0;i<num_qubit;i++)
			begin
				if(reg_literals_Q[i][1] != basis_index[i])
				begin
					matchQ_index <= 1'd0;
				end
				if(reg_literals_Q2[i][1] != basis_index2[i])
				begin
					matchQ2_index <= 1'd0;
				end
			end
		end
	end
end

/********************************FSM TO DETERMINE AMPLITUDE(S) FROM RESULTED Q**********************************/
//AFTER RESULTED Q IS OBTAINED!!!
logic signed [31:0] amplitude_r; logic signed [31:0] amplitude_i; logic signed [31:0] amplitude2_r; 
logic signed [31:0] amplitude2_i;
wire determine_amplitude, done_amplitude, ld_Q_loadP_amp, ld_Q_loadMultQ_amp, ld_Q_rotateLeft_amp, ld_Q2_loadP_amp,
 ld_Q2_loadMultQ_amp, ld_Q2_rotateLeft_amp;

fsm_amplitude #(num_qubit) fsm_amp
(.clk(clk), .rst_new(rst_new), .determine_amplitude(determine_amplitude), 
.matchQ_index(matchQ_index), .matchQ2_index(matchQ2_index), .reg_literals_Q(reg_literals_Q), 
.reg_phase_Q(reg_phase_Q), .reg_literals_Q2(reg_literals_Q2), .reg_phase_Q2(reg_phase_Q2), 
.done_amplitude(done_amplitude), .amplitude_r(amplitude_r), .amplitude_i(amplitude_i), .amplitude2_r(amplitude2_r), 
.amplitude2_i(amplitude2_i), .ld_Q_loadP(ld_Q_loadP_amp), .ld_Q_loadMultQ(ld_Q_loadMultQ_amp), 
.ld_Q_rotateLeft(ld_Q_rotateLeft_amp), .ld_Q2_loadP(ld_Q2_loadP_amp), .ld_Q2_loadMultQ(ld_Q2_loadMultQ_amp), 
.ld_Q2_rotateLeft(ld_Q2_rotateLeft_amp));
//defparam fsm_amp.num_qubit = num_qubit; 

/*********************************************DETERMINE ALPHA & BETA**********************************************/
wire determine_alpha, done_alpha;

//beta is just taking the extracted amplitude no modification is required
assign beta_r = amplitude_r; assign beta_i = amplitude_i; 

//alpha is computed based on extracted amplitude as well as the current gate type and qubit position(s)
fsm_alpha #(num_qubit) fsmAlpha 
(.clk(clk), .rst_new(rst_new), .determine_alpha(determine_alpha), .reg_qubit_pos(reg_qubit_pos), //.k_bit(k_bit), 
.reg_gate_type(reg_gate_type), .basis_index(basis_index), .amplitude_r(amplitude_r), .amplitude_i(amplitude_i), 
.amplitude2_r(amplitude2_r), .amplitude2_i(amplitude2_i), .alpha_r(alpha_r), .alpha_i(alpha_i), 
.initial_alpha_zero(initial_alpha_zero), .done_alpha(done_alpha));
//defparam fsmAlpha.num_qubit = num_qubit;

/*******************************************GLOBAL PHASE MAINTENANCE*********************************************/
wire ld_global_phase, alpha_beta;

compute_global_phase #(num_qubit) comp_gp 
(.clk(clk), .rst_new(rst_new), .ld_global_phase(ld_global_phase), .ld_measure_update(ld_measure_update),
.reg_gate_type(reg_gate_type), .alpha_beta(alpha_beta), .alpha_r(alpha_r), .alpha_i(alpha_i), .beta_r(beta_r), 
.beta_i(beta_i), .global_phase_r(global_phase_r), .global_phase_i(global_phase_i), .count_H(count_H));
//defparam comp_gp.num_qubit = num_qubit;

/**************************************************CONTROL UNIT***************************************************/
control_unit #(num_qubit) cu 
(.clk(clk), .rst(rst), .start(start), .valid_in(valid_in), .ld_Q(ld_Q), .ld_Q2(ld_Q2), .flag_anticommute(flag_anticommute),
.load_rotate_Q(load_rotate_Q), .load_Q_mux(load_Q_mux), .done_alpha(done_alpha), .valid_P(valid_P), 
.literal_phase_readout(literal_phase_readout), .done_multQ(done_multQ), .done_amplitude(done_amplitude), 
.ld_reg(ld_reg), .shift_rotate_array(shift_rotate_array), .ld_gate_info(ld_gate_info), .done_readout(done_readout), 
.valid_out(valid_out), .determine_alpha(determine_alpha), .ld_basis_index(ld_basis_index), .reg_gate_type(reg_gate_type),
.ld_global_phase(ld_global_phase), .alpha_beta(alpha_beta), .determine_multQ(determine_multQ), 
.ld_matchQ_index(ld_matchQ_index), .determine_amplitude(determine_amplitude), .ld_reg0_prodQ(ld_reg0_prodQ), 
.ld_reg1_prodQ(ld_reg1_prodQ), .ld_reg2_prodQ(ld_reg2_prodQ), .ld_Q_loadP_prodQ(ld_Q_loadP_prodQ), 
.ld_Q_loadMultQ_prodQ(ld_Q_loadMultQ_prodQ), .ld_Q_rotateLeft_prodQ(ld_Q_rotateLeft_prodQ), 
.ld_Q2_loadP_prodQ(ld_Q2_loadP_prodQ), .ld_Q2_loadMultQ_prodQ(ld_Q2_loadMultQ_prodQ), 
.ld_Q2_rotateLeft_prodQ(ld_Q2_rotateLeft_prodQ), .ld_Q_loadP_amp(ld_Q_loadP_amp), .ld_measure_update(ld_measure_update),
.ld_Q_loadMultQ_amp(ld_Q_loadMultQ_amp), .ld_Q_rotateLeft_amp(ld_Q_rotateLeft_amp), 
.ld_Q2_loadP_amp(ld_Q2_loadP_amp), .ld_Q2_loadMultQ_amp(ld_Q2_loadMultQ_amp), 
.ld_Q2_rotateLeft_amp(ld_Q2_rotateLeft_amp), .state_CU(state_CU));
//defparam cu.num_qubit = num_qubit;  

//To ensure synchronization between canonical and global phase modules
assign gp_ready = (state_CU == 4'd4)? 1'd1: 1'd0;

endmodule
