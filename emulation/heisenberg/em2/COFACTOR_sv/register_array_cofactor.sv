module register_array_cofactor #(parameter num_qubit = 4, max_vector = 2**num_qubit)(
input clk, input rst, 
//0: shift down (both literals & phases); 1: rotate left (literals only); 2: rotate left (phases only)
input ld_reg, input [1:0] shift_rotate_array, 
input [1:0] literals_in [0:num_qubit-1], input phase_in [0:max_vector-1], 
output [1:0] literals_out[0:num_qubit-1], output phase_out [0:max_vector-1],
input phase_right_in[0:num_qubit-1], output phase_left_out[0:num_qubit-1],
//For cofactor information:
input [31:0] cofactor_pos, input ld_cofactor_info, output reg [31:0] reg_cofactor_pos,
//For verification:
output reg [1:0] literal_reg [0:num_qubit-1][0:num_qubit-1],
output reg phase_reg [0:num_qubit-1][0:2**num_qubit-1]
);

integer i, j;
genvar k;

/***************************REGISTERS TO STORE STABILIZER MATRIX (LITERALS & PHASES)*****************************/

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0; i<num_qubit; i=i+1) 		//each row
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
			//0: Shift down (both literals & phases), input control from outer module
			if(shift_rotate_array==2'd0)
			begin
				literal_reg [0] <= literals_in;
				phase_reg [0] <= phase_in;
				for (i=1; i<num_qubit; i=i+1) 		//For each row
				begin
					literal_reg [i] <= literal_reg [i-1];
					phase_reg [i] <= phase_reg [i-1];
				end
			end
			//1: Rotate left (literals only) 
			else if(shift_rotate_array==2'd1)
			begin
				phase_reg <= phase_reg;
				for (i=0; i<num_qubit; i=i+1) 		//For each row
				begin
					literal_reg [i][num_qubit-1] <= literal_reg [i][0];
					for (j=0; j<num_qubit-1; j=j+1) //For each column
					begin
						literal_reg [i][j] <= literal_reg [i][j+1];
					end
				end
			end
			//2: Shift left (phases only), input control from outer module
			else
			begin
				literal_reg <= literal_reg;
				for (i=0; i<num_qubit; i=i+1) 		//For each row
				begin
					phase_reg [i][max_vector-1] <= phase_right_in [i];	
					for (j=0; j<max_vector-1; j=j+1)//For each vector pair
					begin
						phase_reg [i][j] <= phase_reg [i][j+1];
					end
				end
			end
		end
	end
end

//Connect the last row out for processing
assign literals_out = literal_reg [num_qubit-1];
assign phase_out = phase_reg [num_qubit-1];
//Connect output of the leftmost phase vector
generate
for (k=0; k<num_qubit; k=k+1)
begin: phase_left_output
assign phase_left_out[k] = phase_reg[k][0];
end: phase_left_output
endgenerate

/*****************************************REGISTERS TO STORE COFACTOR INFO******************************************/
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		reg_cofactor_pos <= 32'd0; 
	end
	else
	begin
		if(ld_cofactor_info == 1'd1)
		begin
			reg_cofactor_pos <= cofactor_pos; 
		end
	end
end

endmodule
