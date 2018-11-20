module register_array #(parameter num_qubit = 4, max_vector = 2**num_qubit)(
//General:
input clk, input rst_new, input rst,
//For literal_reg & phase_reg:
input ld_reg, input [1:0] shift_rotate_array, 
input [1:0] literals_in [0:num_qubit-1], input phase_in [0:max_vector-1], 
output [1:0] literals_out[0:num_qubit-1], output phase_out [0:max_vector-1],
//For gate information:
input [1:0] gate_type, input [31:0] qubit_pos,input [31:0] qubit_pos2, input ld_gate_info,
output reg [1:0] reg_gate_type, output reg [31:0] reg_qubit_pos, output reg [31:0] reg_qubit_pos2,
//For literals_P & phase_P:
input [1:0] literals_P [0:max_vector-1][0:num_qubit-1], input phase_P, input valid_P,
output reg [1:0] reg_literals_P [0:max_vector-1][0:num_qubit-1], output reg reg_phase_P
);

integer i,j;

/***************************REGISTERS TO STORE STABILIZER MATRIX (LITERALS & PHASES)*****************************/
reg [1:0] literal_reg [0:num_qubit-1][0:num_qubit-1];   //[row][column]
reg phase_reg [0:num_qubit-1][0:max_vector-1];          //[row_index][pair_index] 
//literal_reg & phase_reg => 0: Shift down (load input); 1: Rotate down; 2: Rotate left 
 
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0; i<num_qubit; i=i+1) 	    //each row
		begin
			for (j=0; j<num_qubit; j=j+1)	//each column
			begin
				literal_reg [i][j] <= 2'd0;
			end
			for (j=0; j<max_vector; j=j+1)	//each vector pair
			begin
				phase_reg [i][j] <= 1'd0;
			end
		end
	end
	else
	begin
		if(ld_reg)
		begin
			if(shift_rotate_array == 2'd0)      //Shift down (taking from input)
			begin
				literal_reg [0] <= literals_in;
				phase_reg [0] <= phase_in;
				for (i=1; i<num_qubit; i=i+1)   //For each row
				begin
					literal_reg [i] <= literal_reg [i-1];
					phase_reg [i] <= phase_reg [i-1];
				end
			end
			else if (shift_rotate_array == 2'd1) //Rotate down (navigate by row)
			begin
				literal_reg [0] <= literal_reg [num_qubit-1];
				phase_reg [0] <= phase_reg [num_qubit-1];
				for (i=1; i<num_qubit; i=i+1)   //For each row
				begin
					literal_reg [i] <= literal_reg [i-1];
					phase_reg [i] <= phase_reg [i-1];
				end
			end
			else if (shift_rotate_array == 2'd2) //Rotate left (navigate by column)
			begin
				phase_reg <= phase_reg;
				for (i=0; i<num_qubit; i=i+1)   //For each row
				begin
					literal_reg [i][num_qubit-1] <= literal_reg [i][0];
					for (j=0; j<num_qubit-1; j=j+1) //For each column
					begin
						literal_reg [i][j] <= literal_reg [i][j+1];
					end
				end
			end
		end
	end
end
//Connect the last row out for processing
assign literals_out = literal_reg [num_qubit-1];
assign phase_out = phase_reg [num_qubit-1];

/*****************************************REGISTERS TO STORE GATE INFO******************************************/
//Correct gate type and qubit_pos(s) has to be maintained until obtain alpha operation is completed 
//Process of getting alpha is supposed to be carried out in parallel with cba & canonical form reduction)
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		reg_gate_type <= 2'd0; reg_qubit_pos <= 32'd0; reg_qubit_pos2 <= 32'd0; 
	end
	else
	begin
		if(ld_gate_info == 1'd1)
		begin
			reg_gate_type <= gate_type; reg_qubit_pos <= qubit_pos; reg_qubit_pos2 <= qubit_pos2; 
		end
	end
end


/*********************************************REGISTERS TO STORE P**********************************************/
//Dependent on P from canonical form reduction
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0; i<max_vector; i=i+1)
		begin
			for (j=0; j<num_qubit; j=j+1)	//each vector pair
			begin
				reg_literals_P [i][j] <= 2'd0; 
			end
		end
		reg_phase_P <= 1'd0; 
	end
	else
	begin
		i=0; j=0;
		if(valid_P)
		begin
			reg_literals_P <= literals_P; 
			reg_phase_P <= phase_P; 
		end
	end
end

endmodule
