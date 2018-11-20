module module_Q #(parameter num_qubit = 4, max_vector = 2**num_qubit)(
//General:
input clk, input rst_new,
//Input:
input ld_Q [0:max_vector-1], input ld_Q2 [0:max_vector-1], input load_rotate_Q, //0: Load; 1: Rotate;
input [1:0] reg_literals_P [0:max_vector-1][0:num_qubit-1], //[pair_index][column]
input reg_phase_P,  //phase for P is always zero!!!
input load_Q_mux,   //0: Load P; 1: Load Q x ROW 
input [1:0] literals_out[0:num_qubit-1], input phase_out[0:max_vector-1],
//Output:
output reg [1:0] reg_literals_Q [0:max_vector-1][0:num_qubit-1], output reg reg_phase_Q [0:max_vector-1],
output reg [1:0] reg_literals_Q2 [0:max_vector-1][0:num_qubit-1], output reg reg_phase_Q2 [0:max_vector-1]
);

integer i,j;

/****************************************REGISTERS FOR Q & Q2 (LITERALS & PHASE)**************************************/
reg [1:0] literals_Q_in [0:max_vector-1][0:num_qubit-1]; reg phase_Q_in [0:max_vector-1];
reg [1:0] literals_Q2_in [0:max_vector-1][0:num_qubit-1]; reg phase_Q2_in [0:max_vector-1];
wire [1:0] mult_Q_row_literals [0:max_vector-1][0:num_qubit-1]; wire mult_Q_row_phase[0:max_vector-1];
wire [1:0] mult_Q2_row_literals [0:max_vector-1][0:num_qubit-1]; wire mult_Q2_row_phase[0:max_vector-1];

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0; i<max_vector; i=i+1)
		begin
			for (j=0; j<num_qubit; j=j+1)
			begin
				reg_literals_Q [i][j] <= 2'd0; reg_literals_Q2 [i][j] <= 2'd0;
			end
			reg_phase_Q[i] <= 1'd0; reg_phase_Q2[i] <= 1'd0;
		end	
	end
	else
	begin
		for (i=0; i<max_vector; i=i+1)
		begin
			if(ld_Q[i])
			begin
				if(load_rotate_Q == 1'd0) //Load P or MULT output
				begin
					reg_literals_Q[i] <= literals_Q_in[i]; reg_phase_Q[i] <= phase_Q_in[i];
				end
				else //Rotate left
				begin
					reg_phase_Q[i] <= reg_phase_Q[i];
					reg_literals_Q [i][num_qubit-1] <= reg_literals_Q [i][0];
					for (j=0; j<num_qubit-1; j=j+1)
					begin
						reg_literals_Q [i][j] <= reg_literals_Q [i][j+1];
					end
				end
			end
			if(ld_Q2[i])
			begin
				if(load_rotate_Q == 1'd0) //Load P or MULT output
				begin
					reg_literals_Q2[i] <= literals_Q2_in[i]; reg_phase_Q2[i] <= phase_Q2_in[i];
				end
				else //Rotate left
				begin
					reg_phase_Q2[i] <= reg_phase_Q2[i];
					reg_literals_Q2[i][num_qubit-1] <= reg_literals_Q2[i][0];
					for (j=0; j<num_qubit-1; j=j+1)
					begin
						reg_literals_Q2[i][j] <= reg_literals_Q2[i][j+1];
					end
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
		for (i=0; i<max_vector; i=i+1)
		begin
			literals_Q_in[i] <= reg_literals_P[i]; phase_Q_in[i] <= reg_phase_P;
			literals_Q2_in[i] <= reg_literals_P[i]; phase_Q2_in[i] <= reg_phase_P;
		end
	end
	else //Row multiplication
	begin
		for (i=0; i<max_vector; i=i+1)
		begin
			literals_Q_in[i] <= mult_Q_row_literals[i]; phase_Q_in[i] <= mult_Q_row_phase[i];
			literals_Q2_in[i] <= mult_Q2_row_literals[i]; phase_Q2_in[i] <= mult_Q2_row_phase[i];
		end
	end
end

/*********************************MULTIPLICATION OF Q & ROW (LITERAL_OUT & PHASE_OUT)*******************************/
genvar k;
generate
	for (k=0; k<max_vector; k=k+1)
	begin: row_multQ
		//For Q
		row_mult_single rm_Q(.literals_in1(reg_literals_Q[k]), .phase_in1(reg_phase_Q[k]), .literals_in2(literals_out), 
		.phase_in2(phase_out[k]), .literals_out(mult_Q_row_literals[k]), .phase_out(mult_Q_row_phase[k]));
		defparam rm_Q.num_qubit = num_qubit; 
		//For Q2
		row_mult_single rm_Q2(.literals_in1(reg_literals_Q2[k]), .phase_in1(reg_phase_Q2[k]), .literals_in2(literals_out), 
		.phase_in2(phase_out[k]), .literals_out(mult_Q2_row_literals[k]), .phase_out(mult_Q2_row_phase[k]));
		defparam rm_Q2.num_qubit = num_qubit; 
	end: row_multQ
endgenerate

endmodule
