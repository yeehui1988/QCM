module conjugation_by_action #(parameter num_qubit = 4)(
input clk,
input rst,
input start,
input [1:0] gate_type, //0: Hadamard; 1: Phase; 2: CNOT
input [31:0] qubit_pos,
input [31:0] qubit_pos2,
input [1:0] literals_in [0:num_qubit-1],
input phase_in, input valid_in,
output [1:0] literals_out [0:num_qubit-1],
output phase_out,
output valid_out
);

integer i;

wire rst_new, ld_literal; 
assign rst_new = rst | start;
wire [1:0] update_literal [0:num_qubit-1];
wire toggle_phase [0:num_qubit-1];
wire control_target;
wire [1:0] left_out [0:num_qubit-1];
wire ld_phase[0:num_qubit-1]; 
wire shift_rotate_literal, shift_toggle_phase, rotate_update_literal;
reg [1:0] c_reg [0:num_qubit-1];	
reg [1:0] t_reg [0:num_qubit-1];	
wire ld_c, ld_t;

/*******************************************REGISTER ARRAY: LITERAL & PHASE*****************************************/
register_array_cba #(num_qubit) cba
(.clk(clk), .rst(rst_new), .ld_literal(ld_literal), .ld_phase(ld_phase), 
.shift_rotate_literal(shift_rotate_literal), .shift_toggle_phase(shift_toggle_phase), .literals_in(literals_in),
.phase_in(phase_in), .rotate_update_literal(rotate_update_literal), .update_literal(update_literal), 
.left_out(left_out),
.literals_out(literals_out), .phase_out(phase_out));
//defparam cba.num_qubit = num_qubit;

/***********************************REGISTER: STORE LITERAL AT C & T QUBIT POSITION*********************************/
//For conjugation-by-action literal update => during rotate left operation
//For the case of CNOT, store the interested C and T literals from first round rotation,
//and perform update during second round rotation

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0; i<num_qubit; i=i+1) //each row 
		begin
			c_reg [i] <= 2'd0;
			t_reg [i] <= 2'd0;
		end
	end
	else
	begin
		if(ld_c)
		begin
			for (i=0; i<num_qubit; i=i+1) //each row 
			begin
				c_reg [i] <= left_out[i];
			end
		end
		if(ld_t)
		begin
			for (i=0; i<num_qubit; i=i+1) //each row 
			begin
				t_reg [i] <= left_out[i];
			end
		end
	end
end

/****************************DETERMINE LITERAL-OF-INTEREST UPDATE ACCORDING TO LUT*******************************/
literal_update #(num_qubit) lit_update 
(.control_target(control_target), .gate_type(gate_type), .left_out(left_out), 
.update_literal(update_literal), .toggle_phase(toggle_phase), .c_reg(c_reg), .t_reg(t_reg));
//defparam lit_update.num_qubit = num_qubit;

/*************************************************CONTROL UNIT*************************************************/
control_unit_cba #(num_qubit) cu_cba 
(.clk(clk), .rst(rst), .toggle_phase(toggle_phase), .gate_type(gate_type), .start(start),
.qubit_pos(qubit_pos), .qubit_pos2(qubit_pos2), .ld_literal(ld_literal), .ld_c(ld_c), .ld_t(ld_t),
.valid_out(valid_out), .rotate_update_literal(rotate_update_literal), .shift_rotate_literal(shift_rotate_literal),
.control_target(control_target), .shift_toggle_phase(shift_toggle_phase), .ld_phase(ld_phase), .valid_in(valid_in));
//defparam cu_cba.num_qubit = num_qubit;

endmodule
