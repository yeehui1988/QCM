`timescale 1ns/1ns 

module testbench ();

parameter num_qubit = 3, total_gate = 30;
integer i;

/*******************************************READ GATE INFO FROM FILE**********************************************/
//--Make it automated later

/*******************************************TOP MODULE INSTANTIATION**********************************************/
reg clk, rst, start; reg [1:0] gate_type; reg [31:0] qubit_pos; reg [31:0] qubit_pos2;
wire phase_out, valid_out, done_readout, update_gate_info;
wire [1:0] literals_out[0:num_qubit-1]; wire [31:0] global_phase_r; wire [31:0] global_phase_i; wire [31:0] count_H;

stabilizer stabilizer_top (.clk(clk), .rst(rst), .start(start), .gate_type(gate_type), .qubit_pos(qubit_pos), 
.qubit_pos2(qubit_pos2), .literals_out(literals_out), .phase_out(phase_out), .valid_out(valid_out), 
.done_readout(done_readout), .global_phase_r(global_phase_r), .global_phase_i(global_phase_i), .count_H(count_H), 
.update_gate_info(update_gate_info));

defparam stabilizer_top.num_qubit = num_qubit; defparam stabilizer_top.total_gate = total_gate;

initial
begin
	clk = 1'b1;
	forever
	#5				//period=10ns (100MHz)
	clk = ~clk;
end

/*
	rst = 1'd0; start = 1'd0; literal_phase_readout = 1'd0; gate_type = 2'd0; qubit_pos = 32'd0; qubit_pos2 = 32'd0;
*/

wire [1:0] type_info [0:total_gate-1]; wire [31:0] pos_info [0:total_gate-1]; wire [31:0] pos2_info [0:total_gate-1];

/**********************************************RANDOMIZED 3-QUBIT STABILIZER GATES***********************************************/
/*
//Randomized Stabilizer gates: 3-qubit
assign type_info[0] = 2'd2;  assign pos_info[0] = 32'd0;  assign pos2_info[0] = 32'd2;  //GATE0 : CNOT 0,2
assign type_info[1] = 2'd0;  assign pos_info[1] = 32'd2;  assign pos2_info[1] = 32'd0;  //GATE1 : H 2
assign type_info[2] = 2'd1;  assign pos_info[2] = 32'd2;  assign pos2_info[2] = 32'd0;  //GATE2 : P 2
assign type_info[3] = 2'd0;  assign pos_info[3] = 32'd2;  assign pos2_info[3] = 32'd0;  //GATE3 : H 2
assign type_info[4] = 2'd0;  assign pos_info[4] = 32'd2;  assign pos2_info[4] = 32'd0;  //GATE4 : H 2
assign type_info[5] = 2'd2;  assign pos_info[5] = 32'd1;  assign pos2_info[5] = 32'd0;  //GATE5 : CNOT 1,0
assign type_info[6] = 2'd1;  assign pos_info[6] = 32'd1;  assign pos2_info[6] = 32'd0;  //GATE6 : P 1
assign type_info[7] = 2'd1;  assign pos_info[7] = 32'd2;  assign pos2_info[7] = 32'd0;  //GATE7 : P 2
assign type_info[8] = 2'd0;  assign pos_info[8] = 32'd0;  assign pos2_info[8] = 32'd0;  //GATE8 : H 0
assign type_info[9] = 2'd1;  assign pos_info[9] = 32'd1;  assign pos2_info[9] = 32'd0;  //GATE9 : P 1
assign type_info[10] = 2'd2; assign pos_info[10] = 32'd1; assign pos2_info[10] = 32'd0; //GATE10: CNOT 1,0
assign type_info[11] = 2'd0; assign pos_info[11] = 32'd2; assign pos2_info[11] = 32'd0; //GATE11: H 2
assign type_info[12] = 2'd0; assign pos_info[12] = 32'd1; assign pos2_info[12] = 32'd0; //GATE12: H 1 
assign type_info[13] = 2'd1; assign pos_info[13] = 32'd0; assign pos2_info[13] = 32'd0; //GATE13: P 0
assign type_info[14] = 2'd2; assign pos_info[14] = 32'd2; assign pos2_info[14] = 32'd1; //GATE14: CNOT 2,1
assign type_info[15] = 2'd0; assign pos_info[15] = 32'd0; assign pos2_info[15] = 32'd0; //GATE15: H 0
assign type_info[16] = 2'd2; assign pos_info[16] = 32'd0; assign pos2_info[16] = 32'd2; //GATE16: CNOT 0,2
assign type_info[17] = 2'd0; assign pos_info[17] = 32'd1; assign pos2_info[17] = 32'd0; //GATE17: H 1
assign type_info[18] = 2'd2; assign pos_info[18] = 32'd2; assign pos2_info[18] = 32'd1; //GATE18: CNOT 2,1
assign type_info[19] = 2'd1; assign pos_info[19] = 32'd0; assign pos2_info[19] = 32'd0; //GATE19: P 0
assign type_info[20] = 2'd0; assign pos_info[20] = 32'd1; assign pos2_info[20] = 32'd0; //GATE20: H 1
assign type_info[21] = 2'd1; assign pos_info[21] = 32'd0; assign pos2_info[21] = 32'd0; //GATE21: P 0
assign type_info[22] = 2'd2; assign pos_info[22] = 32'd0; assign pos2_info[22] = 32'd1; //GATE22: CNOT 0,1
assign type_info[23] = 2'd0; assign pos_info[23] = 32'd0; assign pos2_info[23] = 32'd0; //GATE23: H 0
assign type_info[24] = 2'd0; assign pos_info[24] = 32'd1; assign pos2_info[24] = 32'd0; //GATE24: H 1
assign type_info[25] = 2'd2; assign pos_info[25] = 32'd1; assign pos2_info[25] = 32'd2; //GATE25: CNOT 1,2
assign type_info[26] = 2'd0; assign pos_info[26] = 32'd1; assign pos2_info[26] = 32'd0; //GATE26: H 1
assign type_info[27] = 2'd0; assign pos_info[27] = 32'd2; assign pos2_info[27] = 32'd0; //GATE27: H 2
assign type_info[28] = 2'd0; assign pos_info[28] = 32'd0; assign pos2_info[28] = 32'd0; //GATE28: H 0
assign type_info[29] = 2'd1; assign pos_info[29] = 32'd0; assign pos2_info[29] = 32'd0; //GATE29: P 0
*/
/*
//Randomized Stabilizer gates: 3-qubit (3qubit_5)
assign type_info[0] = 2'd1;  assign pos_info[0] = 32'd0;  assign pos2_info[0] = 32'd0;  //GATE0 : P_0
assign type_info[1] = 2'd1;  assign pos_info[1] = 32'd0;  assign pos2_info[1] = 32'd0;  //GATE1 : P_0
assign type_info[2] = 2'd2;  assign pos_info[2] = 32'd0;  assign pos2_info[2] = 32'd2;  //GATE2 : CNOT_0,2
assign type_info[3] = 2'd1;  assign pos_info[3] = 32'd0;  assign pos2_info[3] = 32'd0;  //GATE3 : P_0
assign type_info[4] = 2'd1;  assign pos_info[4] = 32'd1;  assign pos2_info[4] = 32'd0;  //GATE4 : P_1
assign type_info[5] = 2'd2;  assign pos_info[5] = 32'd0;  assign pos2_info[5] = 32'd1;  //GATE5 : CNOT_0,1
assign type_info[6] = 2'd0;  assign pos_info[6] = 32'd2;  assign pos2_info[6] = 32'd0;  //GATE6 : H_2
assign type_info[7] = 2'd1;  assign pos_info[7] = 32'd0;  assign pos2_info[7] = 32'd0;  //GATE7 : P_0
assign type_info[8] = 2'd0;  assign pos_info[8] = 32'd2;  assign pos2_info[8] = 32'd0;  //GATE8 : H_2
assign type_info[9] = 2'd1;  assign pos_info[9] = 32'd0;  assign pos2_info[9] = 32'd0;  //GATE9 : P_0
assign type_info[10] = 2'd2; assign pos_info[10] = 32'd2; assign pos2_info[10] = 32'd1; //GATE10: CNOT_2,1
assign type_info[11] = 2'd0; assign pos_info[11] = 32'd0; assign pos2_info[11] = 32'd0; //GATE11: H_0
assign type_info[12] = 2'd2; assign pos_info[12] = 32'd1; assign pos2_info[12] = 32'd2; //GATE12: CNOT_1,2
assign type_info[13] = 2'd2; assign pos_info[13] = 32'd2; assign pos2_info[13] = 32'd1; //GATE13: CNOT_2,1
assign type_info[14] = 2'd1; assign pos_info[14] = 32'd0; assign pos2_info[14] = 32'd0; //GATE14: P_0
assign type_info[15] = 2'd2; assign pos_info[15] = 32'd0; assign pos2_info[15] = 32'd1; //GATE15: CNOT_0,1
assign type_info[16] = 2'd0; assign pos_info[16] = 32'd2; assign pos2_info[16] = 32'd0; //GATE16: H_2
assign type_info[17] = 2'd1; assign pos_info[17] = 32'd2; assign pos2_info[17] = 32'd0; //GATE17: P_2
assign type_info[18] = 2'd0; assign pos_info[18] = 32'd2; assign pos2_info[18] = 32'd0; //GATE18: H_2
assign type_info[19] = 2'd2; assign pos_info[19] = 32'd2; assign pos2_info[19] = 32'd0; //GATE19: CNOT_2,0
assign type_info[20] = 2'd0; assign pos_info[20] = 32'd2; assign pos2_info[20] = 32'd0; //GATE20: H_2
assign type_info[21] = 2'd2; assign pos_info[21] = 32'd1; assign pos2_info[21] = 32'd0; //GATE21: CNOT_1,0
assign type_info[22] = 2'd2; assign pos_info[22] = 32'd2; assign pos2_info[22] = 32'd1; //GATE22: CNOT_2,1
assign type_info[23] = 2'd2; assign pos_info[23] = 32'd1; assign pos2_info[23] = 32'd2; //GATE23: CNOT_1,2
assign type_info[24] = 2'd2; assign pos_info[24] = 32'd2; assign pos2_info[24] = 32'd1; //GATE24: CNOT_2,1
assign type_info[25] = 2'd0; assign pos_info[25] = 32'd2; assign pos2_info[25] = 32'd0; //GATE25: H_2
assign type_info[26] = 2'd2; assign pos_info[26] = 32'd0; assign pos2_info[26] = 32'd1; //GATE26: CNOT_0,1
assign type_info[27] = 2'd0; assign pos_info[27] = 32'd2; assign pos2_info[27] = 32'd0; //GATE27: H_2
assign type_info[28] = 2'd2; assign pos_info[28] = 32'd1; assign pos2_info[28] = 32'd0; //GATE28: CNOT_1,0
assign type_info[29] = 2'd0; assign pos_info[29] = 32'd0; assign pos2_info[29] = 32'd0; //GATE29: H_0
*/


//Randomized Stabilizer gates: 3-qubit (3qubit_7)
assign type_info[0] = 2'd1;  assign pos_info[0] = 32'd2;  assign pos2_info[0] = 32'd0;  //GATE0 : P_2
assign type_info[1] = 2'd2;  assign pos_info[1] = 32'd0;  assign pos2_info[1] = 32'd2;  //GATE1 : CNOT_0,2
assign type_info[2] = 2'd1;  assign pos_info[2] = 32'd1;  assign pos2_info[2] = 32'd0;  //GATE2 : P_1
assign type_info[3] = 2'd2;  assign pos_info[3] = 32'd2;  assign pos2_info[3] = 32'd1;  //GATE3 : CNOT_2,1
assign type_info[4] = 2'd1;  assign pos_info[4] = 32'd2;  assign pos2_info[4] = 32'd0;  //GATE4 : P_2
assign type_info[5] = 2'd0;  assign pos_info[5] = 32'd1;  assign pos2_info[5] = 32'd0;  //GATE5 : H_1
assign type_info[6] = 2'd2;  assign pos_info[6] = 32'd1;  assign pos2_info[6] = 32'd2;  //GATE6 : CNOT_1,2
assign type_info[7] = 2'd2;  assign pos_info[7] = 32'd0;  assign pos2_info[7] = 32'd1;  //GATE7 : CNOT_0,1
assign type_info[8] = 2'd0;  assign pos_info[8] = 32'd2;  assign pos2_info[8] = 32'd0;  //GATE8 : H_2
assign type_info[9] = 2'd2;  assign pos_info[9] = 32'd0;  assign pos2_info[9] = 32'd2;  //GATE9 : CNOT_0,2
assign type_info[10] = 2'd1; assign pos_info[10] = 32'd2; assign pos2_info[10] = 32'd0; //GATE10: P_2
assign type_info[11] = 2'd1; assign pos_info[11] = 32'd0; assign pos2_info[11] = 32'd0; //GATE11: P_0
assign type_info[12] = 2'd2; assign pos_info[12] = 32'd0; assign pos2_info[12] = 32'd1; //GATE12: CNOT_0,1
assign type_info[13] = 2'd1; assign pos_info[13] = 32'd2; assign pos2_info[13] = 32'd0; //GATE13: P_2
assign type_info[14] = 2'd1; assign pos_info[14] = 32'd1; assign pos2_info[14] = 32'd0; //GATE14: P_1
assign type_info[15] = 2'd2; assign pos_info[15] = 32'd2; assign pos2_info[15] = 32'd0; //GATE15: CNOT_2,0
assign type_info[16] = 2'd0; assign pos_info[16] = 32'd0; assign pos2_info[16] = 32'd0; //GATE16: H_0
assign type_info[17] = 2'd1; assign pos_info[17] = 32'd0; assign pos2_info[17] = 32'd0; //GATE17: P_0
assign type_info[18] = 2'd0; assign pos_info[18] = 32'd0; assign pos2_info[18] = 32'd0; //GATE18: H_0
assign type_info[19] = 2'd1; assign pos_info[19] = 32'd1; assign pos2_info[19] = 32'd0; //GATE19: P_1
assign type_info[20] = 2'd2; assign pos_info[20] = 32'd0; assign pos2_info[20] = 32'd1; //GATE20: CNOT_0,1
assign type_info[21] = 2'd1; assign pos_info[21] = 32'd1; assign pos2_info[21] = 32'd0; //GATE21: P_1
assign type_info[22] = 2'd2; assign pos_info[22] = 32'd2; assign pos2_info[22] = 32'd0; //GATE22: CNOT_2,0
assign type_info[23] = 2'd0; assign pos_info[23] = 32'd2; assign pos2_info[23] = 32'd0; //GATE23: H_2
assign type_info[24] = 2'd1; assign pos_info[24] = 32'd1; assign pos2_info[24] = 32'd0; //GATE24: P_1
assign type_info[25] = 2'd0; assign pos_info[25] = 32'd0; assign pos2_info[25] = 32'd0; //GATE25: H_0
assign type_info[26] = 2'd2; assign pos_info[26] = 32'd2; assign pos2_info[26] = 32'd0; //GATE26: CNOT_2,0
assign type_info[27] = 2'd0; assign pos_info[27] = 32'd0; assign pos2_info[27] = 32'd0; //GATE27: H_0
assign type_info[28] = 2'd0; assign pos_info[28] = 32'd1; assign pos2_info[28] = 32'd0; //GATE28: H_1
assign type_info[29] = 2'd0; assign pos_info[29] = 32'd1; assign pos2_info[29] = 32'd0; //GATE29: H_1


/*************************************************RANDOMIZED 3-QUBIT STABILIZER + MEASUREMENT GATES*************************************************/
/*
//3-qubit_measure_1
assign type_info[0] = 2'd0;  assign pos_info[0] = 32'd1;  assign pos2_info[0] = 32'd0;  //GATE0 : H_1
assign type_info[1] = 2'd3;  assign pos_info[1] = 32'd1;  assign pos2_info[1] = 32'd0;  //GATE1 : M_1
assign type_info[2] = 2'd3;  assign pos_info[2] = 32'd0;  assign pos2_info[2] = 32'd0;  //GATE2 : M_0
assign type_info[3] = 2'd1;  assign pos_info[3] = 32'd1;  assign pos2_info[3] = 32'd0;  //GATE3 : P_1
assign type_info[4] = 2'd2;  assign pos_info[4] = 32'd2;  assign pos2_info[4] = 32'd0;  //GATE4 : CNOT_2,0
assign type_info[5] = 2'd3;  assign pos_info[5] = 32'd2;  assign pos2_info[5] = 32'd0;  //GATE5 : M_2
assign type_info[6] = 2'd1;  assign pos_info[6] = 32'd1;  assign pos2_info[6] = 32'd0;  //GATE6 : P_1
assign type_info[7] = 2'd3;  assign pos_info[7] = 32'd2;  assign pos2_info[7] = 32'd0;  //GATE7 : M_2
assign type_info[8] = 2'd2;  assign pos_info[8] = 32'd0;  assign pos2_info[8] = 32'd1;  //GATE8 : CNOT_0,1
assign type_info[9] = 2'd0;  assign pos_info[9] = 32'd0;  assign pos2_info[9] = 32'd0;  //GATE9 : H_0
assign type_info[10] = 2'd3; assign pos_info[10] = 32'd2; assign pos2_info[10] = 32'd0; //GATE10: M_2
assign type_info[11] = 2'd3; assign pos_info[11] = 32'd2; assign pos2_info[11] = 32'd0; //GATE11: M_2
assign type_info[12] = 2'd0; assign pos_info[12] = 32'd0; assign pos2_info[12] = 32'd0; //GATE12: H_0
assign type_info[13] = 2'd1; assign pos_info[13] = 32'd0; assign pos2_info[13] = 32'd0; //GATE13: P_0
assign type_info[14] = 2'd1; assign pos_info[14] = 32'd2; assign pos2_info[14] = 32'd0; //GATE14: P_2
assign type_info[15] = 2'd3; assign pos_info[15] = 32'd2; assign pos2_info[15] = 32'd0; //GATE15: M_2
assign type_info[16] = 2'd2; assign pos_info[16] = 32'd0; assign pos2_info[16] = 32'd1; //GATE16: CNOT_0,1
assign type_info[17] = 2'd1; assign pos_info[17] = 32'd1; assign pos2_info[17] = 32'd0; //GATE17: P_1
assign type_info[18] = 2'd1; assign pos_info[18] = 32'd0; assign pos2_info[18] = 32'd0; //GATE18: P_0
assign type_info[19] = 2'd2; assign pos_info[19] = 32'd0; assign pos2_info[19] = 32'd1; //GATE19: CNOT_0,1
assign type_info[20] = 2'd2; assign pos_info[20] = 32'd2; assign pos2_info[20] = 32'd0; //GATE20: CNOT_2,0
assign type_info[21] = 2'd0; assign pos_info[21] = 32'd0; assign pos2_info[21] = 32'd0; //GATE21: H_0
assign type_info[22] = 2'd1; assign pos_info[22] = 32'd0; assign pos2_info[22] = 32'd0; //GATE22: P_0
assign type_info[23] = 2'd0; assign pos_info[23] = 32'd2; assign pos2_info[23] = 32'd0; //GATE23: H_2
assign type_info[24] = 2'd1; assign pos_info[24] = 32'd1; assign pos2_info[24] = 32'd0; //GATE24: P_1
assign type_info[25] = 2'd2; assign pos_info[25] = 32'd0; assign pos2_info[25] = 32'd2; //GATE25: CNOT_0,2
assign type_info[26] = 2'd3; assign pos_info[26] = 32'd0; assign pos2_info[26] = 32'd0; //GATE26: M_0
assign type_info[27] = 2'd0; assign pos_info[27] = 32'd2; assign pos2_info[27] = 32'd0; //GATE27: H_2
assign type_info[28] = 2'd0; assign pos_info[28] = 32'd1; assign pos2_info[28] = 32'd0; //GATE28: H_1
assign type_info[29] = 2'd2; assign pos_info[29] = 32'd2; assign pos2_info[29] = 32'd0; //GATE29: CNOT_2,0
*/

/*
//3-qubit_measure_2
assign type_info[0] = 2'd2;  assign pos_info[0] = 32'd0;  assign pos2_info[0] = 32'd1;  //GATE0 : CNOT_0,1
assign type_info[1] = 2'd0;  assign pos_info[1] = 32'd2;  assign pos2_info[1] = 32'd0;  //GATE1 : H_2
assign type_info[2] = 2'd0;  assign pos_info[2] = 32'd0;  assign pos2_info[2] = 32'd0;  //GATE2 : H_0
assign type_info[3] = 2'd3;  assign pos_info[3] = 32'd0;  assign pos2_info[3] = 32'd0;  //GATE3 : M_0
assign type_info[4] = 2'd1;  assign pos_info[4] = 32'd2;  assign pos2_info[4] = 32'd0;  //GATE4 : P_2
assign type_info[5] = 2'd1;  assign pos_info[5] = 32'd1;  assign pos2_info[5] = 32'd0;  //GATE5 : P_1
assign type_info[6] = 2'd3;  assign pos_info[6] = 32'd1;  assign pos2_info[6] = 32'd0;  //GATE6 : M_1
assign type_info[7] = 2'd1;  assign pos_info[7] = 32'd2;  assign pos2_info[7] = 32'd0;  //GATE7 : P_2
assign type_info[8] = 2'd1;  assign pos_info[8] = 32'd0;  assign pos2_info[8] = 32'd0;  //GATE8 : P_0
assign type_info[9] = 2'd2;  assign pos_info[9] = 32'd1;  assign pos2_info[9] = 32'd0;  //GATE9 : CNOT_1,0
assign type_info[10] = 2'd0; assign pos_info[10] = 32'd1; assign pos2_info[10] = 32'd0; //GATE10: H_1
assign type_info[11] = 2'd2; assign pos_info[11] = 32'd1; assign pos2_info[11] = 32'd0; //GATE11: CNOT_1,0
assign type_info[12] = 2'd3; assign pos_info[12] = 32'd2; assign pos2_info[12] = 32'd0; //GATE12: M_2
assign type_info[13] = 2'd3; assign pos_info[13] = 32'd1; assign pos2_info[13] = 32'd0; //GATE13: M_1
assign type_info[14] = 2'd1; assign pos_info[14] = 32'd1; assign pos2_info[14] = 32'd0; //GATE14: P_1
assign type_info[15] = 2'd3; assign pos_info[15] = 32'd0; assign pos2_info[15] = 32'd0; //GATE15: M_0
assign type_info[16] = 2'd3; assign pos_info[16] = 32'd1; assign pos2_info[16] = 32'd0; //GATE16: M_1
assign type_info[17] = 2'd0; assign pos_info[17] = 32'd0; assign pos2_info[17] = 32'd0; //GATE17: H_0
assign type_info[18] = 2'd2; assign pos_info[18] = 32'd2; assign pos2_info[18] = 32'd0; //GATE18: CNOT_2,0
assign type_info[19] = 2'd0; assign pos_info[19] = 32'd0; assign pos2_info[19] = 32'd0; //GATE19: H_0
assign type_info[20] = 2'd0; assign pos_info[20] = 32'd0; assign pos2_info[20] = 32'd0; //GATE20: H_0
assign type_info[21] = 2'd3; assign pos_info[21] = 32'd2; assign pos2_info[21] = 32'd0; //GATE21: M_2
assign type_info[22] = 2'd1; assign pos_info[22] = 32'd1; assign pos2_info[22] = 32'd0; //GATE22: P_1
assign type_info[23] = 2'd2; assign pos_info[23] = 32'd2; assign pos2_info[23] = 32'd0; //GATE23: CNOT_2,0
assign type_info[24] = 2'd2; assign pos_info[24] = 32'd2; assign pos2_info[24] = 32'd1; //GATE24: CNOT_2,1
assign type_info[25] = 2'd2; assign pos_info[25] = 32'd2; assign pos2_info[25] = 32'd0; //GATE25: CNOT_2,0
assign type_info[26] = 2'd3; assign pos_info[26] = 32'd0; assign pos2_info[26] = 32'd0; //GATE26: M_0
assign type_info[27] = 2'd2; assign pos_info[27] = 32'd2; assign pos2_info[27] = 32'd1; //GATE27: CNOT_2,1
assign type_info[28] = 2'd0; assign pos_info[28] = 32'd0; assign pos2_info[28] = 32'd0; //GATE28: H_0
assign type_info[29] = 2'd1; assign pos_info[29] = 32'd1; assign pos2_info[29] = 32'd0; //GATE29: P_1
*/

/*
//3-qubit_measure_3
assign type_info[0] = 2'd2;  assign pos_info[0] = 32'd1;  assign pos2_info[0] = 32'd2;  //GATE0 : CNOT_1,2
assign type_info[1] = 2'd1;  assign pos_info[1] = 32'd0;  assign pos2_info[1] = 32'd0;  //GATE1 : P_0
assign type_info[2] = 2'd0;  assign pos_info[2] = 32'd1;  assign pos2_info[2] = 32'd0;  //GATE2 : H_1
assign type_info[3] = 2'd3;  assign pos_info[3] = 32'd1;  assign pos2_info[3] = 32'd0;  //GATE3 : M_1
assign type_info[4] = 2'd1;  assign pos_info[4] = 32'd2;  assign pos2_info[4] = 32'd0;  //GATE4 : P_2
assign type_info[5] = 2'd3;  assign pos_info[5] = 32'd2;  assign pos2_info[5] = 32'd0;  //GATE5 : M_2
assign type_info[6] = 2'd0;  assign pos_info[6] = 32'd0;  assign pos2_info[6] = 32'd0;  //GATE6 : H_0
assign type_info[7] = 2'd2;  assign pos_info[7] = 32'd0;  assign pos2_info[7] = 32'd1;  //GATE7 : CNOT_0,1
assign type_info[8] = 2'd0;  assign pos_info[8] = 32'd2;  assign pos2_info[8] = 32'd0;  //GATE8 : H_2
assign type_info[9] = 2'd3;  assign pos_info[9] = 32'd0;  assign pos2_info[9] = 32'd0;  //GATE9 : M_0
assign type_info[10] = 2'd1; assign pos_info[10] = 32'd0; assign pos2_info[10] = 32'd0; //GATE10: P_0
assign type_info[11] = 2'd2; assign pos_info[11] = 32'd1; assign pos2_info[11] = 32'd2; //GATE11: CNOT_1,2
assign type_info[12] = 2'd2; assign pos_info[12] = 32'd0; assign pos2_info[12] = 32'd2; //GATE12: CNOT_0,2
assign type_info[13] = 2'd1; assign pos_info[13] = 32'd1; assign pos2_info[13] = 32'd0; //GATE13: P_1
assign type_info[14] = 2'd1; assign pos_info[14] = 32'd1; assign pos2_info[14] = 32'd0; //GATE14: P_1
assign type_info[15] = 2'd2; assign pos_info[15] = 32'd1; assign pos2_info[15] = 32'd0; //GATE15: CNOT_1,0
assign type_info[16] = 2'd2; assign pos_info[16] = 32'd1; assign pos2_info[16] = 32'd2; //GATE16: CNOT_1,2
assign type_info[17] = 2'd1; assign pos_info[17] = 32'd2; assign pos2_info[17] = 32'd0; //GATE17: P_2
assign type_info[18] = 2'd1; assign pos_info[18] = 32'd2; assign pos2_info[18] = 32'd0; //GATE18: P_2
assign type_info[19] = 2'd3; assign pos_info[19] = 32'd2; assign pos2_info[19] = 32'd0; //GATE19: M_2
assign type_info[20] = 2'd2; assign pos_info[20] = 32'd1; assign pos2_info[20] = 32'd2; //GATE20: CNOT_1,2
assign type_info[21] = 2'd2; assign pos_info[21] = 32'd0; assign pos2_info[21] = 32'd1; //GATE21: CNOT_0,1
assign type_info[22] = 2'd1; assign pos_info[22] = 32'd1; assign pos2_info[22] = 32'd0; //GATE22: P_1
assign type_info[23] = 2'd2; assign pos_info[23] = 32'd0; assign pos2_info[23] = 32'd2; //GATE23: CNOT_0,2
assign type_info[24] = 2'd0; assign pos_info[24] = 32'd1; assign pos2_info[24] = 32'd0; //GATE24: H_1
assign type_info[25] = 2'd1; assign pos_info[25] = 32'd1; assign pos2_info[25] = 32'd0; //GATE25: P_1
assign type_info[26] = 2'd1; assign pos_info[26] = 32'd0; assign pos2_info[26] = 32'd0; //GATE26: P_0
assign type_info[27] = 2'd2; assign pos_info[27] = 32'd1; assign pos2_info[27] = 32'd0; //GATE27: CNOT_1,0
assign type_info[28] = 2'd0; assign pos_info[28] = 32'd0; assign pos2_info[28] = 32'd0; //GATE28: H_0
assign type_info[29] = 2'd3; assign pos_info[29] = 32'd1; assign pos2_info[29] = 32'd0; //GATE29: M_1
*/

initial
begin
	//Reset
	rst = 1'd1; start = 1'd0; 
	#3
	rst = 1'd0; start = 1'd0; 
	#8 //start 
	rst = 1'd0; start = 1'd1;
	#10 
		rst = 1'd0; start = 1'd0; 
	#10000
	$stop;
end

reg [31:0] counter;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		gate_type <= type_info[0]; qubit_pos <= pos_info[0]; qubit_pos2 <= pos2_info[0];
		counter <= 32'd1;
	end
	else
	begin
		if(update_gate_info & counter < total_gate)
		begin
			gate_type <= type_info[counter]; qubit_pos <= pos_info[counter]; qubit_pos2 <= pos2_info[counter];
			counter <= counter + 32'd1;
		end
	end
end

endmodule
