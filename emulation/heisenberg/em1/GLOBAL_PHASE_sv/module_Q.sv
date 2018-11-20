module module_Q #(parameter num_qubit = 4)(
//General:
input clk, input rst_new,
//Input:
input ld_Q, input ld_Q2, input load_rotate_Q, //0: Load; 1: Rotate;
input [1:0] reg_literals_P [0:num_qubit-1], input reg_phase_P, input load_Q_mux, //0: Load P; 1: Load Q x ROW
input [1:0] literals_out[0:num_qubit-1], input phase_out,
//Output:
output reg [1:0] reg_literals_Q [0:num_qubit-1], output reg reg_phase_Q,
output reg [1:0] reg_literals_Q2 [0:num_qubit-1], output reg reg_phase_Q2
);

integer i;

/****************************************REGISTERS FOR Q & Q2 (LITERALS & PHASE)**************************************/
reg [1:0] literals_Q_in [0:num_qubit-1]; reg phase_Q_in;
reg [1:0] literals_Q2_in [0:num_qubit-1]; reg phase_Q2_in;
wire [1:0] mult_Q_row_literals [0:num_qubit-1]; wire mult_Q_row_phase;
wire [1:0] mult_Q2_row_literals [0:num_qubit-1]; wire mult_Q2_row_phase;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0; i<num_qubit; i=i+1)
		begin
			reg_literals_Q [i] <= 2'd0; reg_literals_Q2 [i] <= 2'd0;
		end
		reg_phase_Q <= 1'd0; reg_phase_Q2 <= 1'd0;
	end
	else
	begin
		if(ld_Q)
		begin
			if(load_rotate_Q == 1'd0) //load
			begin
				reg_literals_Q <= literals_Q_in; reg_phase_Q <= phase_Q_in;
			end
			else	//rotate left
			begin
				reg_literals_Q [num_qubit-1] <= reg_literals_Q [0];
				for (i=0; i<num_qubit-1; i=i+1)
				begin
					reg_literals_Q [i] <= reg_literals_Q [i+1];
				end
			end
		end
		if(ld_Q2)
		begin
			if(load_rotate_Q == 1'd0) //load
			begin
				reg_literals_Q2 <= literals_Q2_in; reg_phase_Q2 <= phase_Q2_in;
			end
			else	//rotate left
			begin
				reg_phase_Q2 <= reg_phase_Q2;
				reg_literals_Q2 [num_qubit-1] <= reg_literals_Q2 [0];
				for (i=0; i<num_qubit-1; i=i+1)
				begin
					reg_literals_Q2 [i] <= reg_literals_Q2 [i+1];
				end
			end
		end
	end
end

/****************************************MUX FOR INPUT TO REGISTERS FOR Q & Q2**************************************/
always@(*)
begin
	if(load_Q_mux == 1'd0) //Initialization with P: for each gate operation
	begin
		literals_Q_in <= reg_literals_P; phase_Q_in <= reg_phase_P;
		literals_Q2_in <= reg_literals_P; phase_Q2_in <= reg_phase_P;
	end
	else //Row multiplication
	begin
		literals_Q_in <= mult_Q_row_literals; phase_Q_in <= mult_Q_row_phase;
		literals_Q2_in <= mult_Q2_row_literals; phase_Q2_in <= mult_Q2_row_phase;
	end
end

/*********************************MULTIPLICATION OF Q & ROW (LITERAL_OUT & PHASE_OUT)*******************************/
row_mult_single rm_Q(.literals_in1(reg_literals_Q), .phase_in1(reg_phase_Q), .literals_in2(literals_out), 
.phase_in2(phase_out), .literals_out(mult_Q_row_literals), .phase_out(mult_Q_row_phase));
defparam rm_Q.num_qubit = num_qubit;

row_mult_single rm_Q2(.literals_in1(reg_literals_Q2), .phase_in1(reg_phase_Q2), .literals_in2(literals_out), 
.phase_in2(phase_out), .literals_out(mult_Q2_row_literals), .phase_out(mult_Q2_row_phase));
defparam rm_Q2.num_qubit = num_qubit;

endmodule
