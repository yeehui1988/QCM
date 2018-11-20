module module_Q #(parameter num_qubit = 4, max_vector = 2**num_qubit)(
input clk, input rst,
//Make sure P do not overwrite the content in Q2 before determine amplitude2 operation is completed. (From nonstabilizer operation)
input valid_P_beta, input [1:0] literals_P [0:max_vector-1][0:num_qubit-1],
//From two possible sources (a) register array cofactor (b) register array stabilizer
input [1:0] literals_out [0:num_qubit-1], input phase_out [0:2**num_qubit-1],
input rotateLeft_Q2_individual, input ld_rotateLeft_Q2, //from amplitude cofactor (determine amplitude2)
input rotateLeft_Q2_from_nonstabilizer,  input ld_prodQ2_from_nonstabilizer, input rotateLeft_Q2_from_stabilizer,  input ld_prodQ2_from_stabilizer,
input basis_index2 [0:2**num_qubit-1][0:num_qubit-1],
output reg Q2_msb_leftmost [0:num_qubit-1],
output reg [1:0] literals_Q2 [0:max_vector-1][0:num_qubit-1], output reg phase_Q2 [0:max_vector-1],
//For stabilizer beta operation:
input valid_P_stabilizer, input [1:0] literals_out_stabilizer [0:num_qubit-1], input phase_out_stabilizer [0:2**num_qubit-1] 
);

integer i,j; genvar k;

reg [1:0] select_literals_Q2 [0:max_vector-1][0:num_qubit-1]; reg select_phase_Q2 [0:max_vector-1]; 
wire [1:0] literals_prodQ2_from_nonstabilizer [0:max_vector-1][0:num_qubit-1]; wire phase_prodQ2_from_nonstabilizer [0:max_vector-1];
wire [1:0] literals_prodQ2_from_stabilizer [0:max_vector-1][0:num_qubit-1]; wire phase_prodQ2_from_stabilizer [0:max_vector-1];
reg flag_basis2 [0:max_vector-1][0:num_qubit-1]; wire ld_Q2; wire rotateLeft_Q2;

assign  rotateLeft_Q2 = rotateLeft_Q2_from_nonstabilizer | rotateLeft_Q2_from_stabilizer | ld_rotateLeft_Q2;

assign ld_Q2 = valid_P_beta | rotateLeft_Q2 | rotateLeft_Q2_individual | ld_prodQ2_from_nonstabilizer | valid_P_stabilizer | ld_prodQ2_from_stabilizer;

always@(*)
begin
	i=0; j=0;
	if(valid_P_beta) 					    //Case 1: Initialize Q2 with P (from nonstabilizer operation)
	begin
		select_literals_Q2 <= literals_P;
		for (i=0; i<max_vector; i=i+1) 
		begin
			select_phase_Q2[i] <= 1'd0; 
		end
	end
	else if(rotateLeft_Q2)				    //Case 2: Rotate left (individual literals)
	begin
		select_phase_Q2 <= phase_Q2; //Phase remains unchanged
		for (i=0; i<max_vector; i=i+1) 
		begin
			select_literals_Q2 [i][num_qubit-1] <= literals_Q2 [i][0]; 
			for (j=0; j<num_qubit-1; j=j+1)	
			begin
				select_literals_Q2 [i][j] <= literals_Q2 [i][j+1]; 
			end
		end
	end
	else if(rotateLeft_Q2_individual) 	    //Case 3: Rotate left (individual Q)
	begin
		select_literals_Q2 [max_vector-1] <= literals_Q2 [0]; 
		select_phase_Q2 [max_vector-1] <= phase_Q2 [0];
		for (i=0; i<max_vector-1; i=i+1) 
		begin
			select_literals_Q2 [i] <= literals_Q2 [i+1];
			select_phase_Q2 [i] <= phase_Q2 [i+1];
		end	
	end
	else if(ld_prodQ2_from_nonstabilizer)   //Case 4: Update Q with product of Q and literals out
	begin
		j=0;
		for (i=0; i<max_vector; i=i+1) //Each phase pair
		begin
			if(flag_basis2[i][0]) //Flagged
			begin
				select_literals_Q2[i] <= literals_prodQ2_from_nonstabilizer[i]; select_phase_Q2 [i] <= phase_prodQ2_from_nonstabilizer[i];
			end
			else
			begin
				select_literals_Q2[i] <= literals_Q2[i]; select_phase_Q2[i] <= phase_Q2[i]; 
			end
		end
	end
	else if(ld_prodQ2_from_stabilizer) 	    //Case 5: Update Q with product of Q and literals out stabilizer
	begin
		j=0;
		for (i=0; i<max_vector; i=i+1) //Each phase pair
		begin
			if(flag_basis2[i][0]) //Flagged
			begin
				select_literals_Q2[i] <= literals_prodQ2_from_stabilizer[i]; select_phase_Q2 [i] <= phase_prodQ2_from_stabilizer[i];
			end
			else
			begin
				select_literals_Q2[i] <= literals_Q2[i]; select_phase_Q2[i] <= phase_Q2[i]; 
			end
		end
	end
	else if(valid_P_stabilizer) 			//Case 6: Initialize Q2 with P (from stabilizer operation)
	begin
		select_literals_Q2 <= literals_P;
		for (i=0; i<max_vector; i=i+1) 
		begin
			select_phase_Q2[i] <= 1'd0; 
		end
	end
	else
	begin
		select_literals_Q2 <= literals_Q2; select_phase_Q2 <= phase_Q2;
	end
end

/********************************************************ROW MULT Q & LITERALS OUT*****************************************************/
//From nonstabilizer operation:
generate
for (k=0; k<max_vector; k=k+1)
begin: gen_prodQ2
row_mult_single rm_prodQ2 (.literals_in1(literals_Q2[k]), .phase_in1(phase_Q2[k]), .literals_in2(literals_out), .phase_in2(phase_out[k]), 
.literals_out(literals_prodQ2_from_nonstabilizer[k]), .phase_out(phase_prodQ2_from_nonstabilizer[k]));
defparam rm_prodQ2.num_qubit = num_qubit; 
end: gen_prodQ2
endgenerate

//From stabilizer operation:

generate
for (k=0; k<max_vector; k=k+1)
begin: gen_prodQ2_stabilizer
row_mult_single rm_prodQ2 (.literals_in1(literals_Q2[k]), .phase_in1(phase_Q2[k]), .literals_in2(literals_out_stabilizer), .phase_in2(phase_out_stabilizer[k]), 
.literals_out(literals_prodQ2_from_stabilizer[k]), .phase_out(phase_prodQ2_from_stabilizer[k]));
defparam rm_prodQ2.num_qubit = num_qubit; 
end: gen_prodQ2_stabilizer
endgenerate


always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0; i<max_vector; i=i+1)
		begin
			phase_Q2[i] <= 1'd0;
			for (j=0; j<num_qubit; j=j+1)	//each vector pair
			begin
				literals_Q2[i][j] <= 2'd0;
			end
		end
	end
	else
	begin
		i=0;j=0;
		if(ld_Q2)
		begin
			literals_Q2 <= select_literals_Q2; phase_Q2 <= select_phase_Q2;
		end
		else
		begin
			literals_Q2 <= literals_Q2; phase_Q2 <= phase_Q2;
		end
	end
end

always@(*)
begin
	for(i=0;i<num_qubit;i=i+1)
	begin
		Q2_msb_leftmost[i] <= literals_Q2[0][i][1];
	end
end

//Flag basis for productQ2
reg select_flag_basis2 [0:max_vector-1][0:num_qubit-1];
reg mux_flag_basis2;
wire ld_flag_basis2;

assign ld_flag_basis2 = valid_P_beta | rotateLeft_Q2 | ld_prodQ2_from_nonstabilizer | valid_P_stabilizer;

always@(*)
begin
	i=0; j=0;
	if(valid_P_beta | valid_P_stabilizer)	//mux_flag_basis==1'd0: Load P literals XOR basis index as initial flag basis (sync with valid P)
	begin
		for (i=0;i<max_vector;i=i+1)
		begin
			for (j=0;j<num_qubit;j=j+1)
			begin
				select_flag_basis2[i][j] <= literals_P[i][j][1] ^ basis_index2[i][j];
			end
		end
	end
	else if(rotateLeft_Q2)
	begin
		for (i=0; i<max_vector; i=i+1) //Each phase pair
		begin
			select_flag_basis2 [i][num_qubit-1] <= flag_basis2 [i][0]; //[pair_index][literal_index]
			for (j=0; j<num_qubit-1; j=j+1)	//Each literal in each phase pair
			begin
				select_flag_basis2 [i][j] <= flag_basis2 [i][j+1]; //[pair_index][literal_index]
			end
		end
	end
	else if (ld_prodQ2_from_nonstabilizer)	//mux_flag_basis==1'd1: Update with flag basis XOR literals out as productQ is updated 
	begin
		j=0;
		for (i=0;i<max_vector;i=i+1)
		begin
			if (flag_basis2[i][0]) //Update if flagged
			begin
				for (j=0;j<num_qubit;j=j+1)
				begin
					select_flag_basis2[i][j] <= flag_basis2[i][j] ^ literals_out[j][1];
				end
			end
			else //No changes
			begin
				select_flag_basis2[i] <= flag_basis2[i];
			end
		end
	end
	else if (ld_prodQ2_from_stabilizer)	//mux_flag_basis==1'd1: Update with flag basis XOR literals out as productQ is updated 
	begin
		j=0;
		for (i=0;i<max_vector;i=i+1)
		begin
			if (flag_basis2[i][0]) //Update if flagged
			begin
				for (j=0;j<num_qubit;j=j+1)
				begin
					select_flag_basis2[i][j] <= flag_basis2[i][j] ^ literals_out_stabilizer[j][1];
				end
			end
			else //No changes
			begin
				select_flag_basis2[i] <= flag_basis2[i];
			end
		end
	end
	else //No changes
	begin
		select_flag_basis2 <= flag_basis2;
	end
end

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0;i<max_vector;i=i+1)
		begin
			for (j=0;j<num_qubit;j=j+1)
			begin
				flag_basis2 [i][j] <= 1'd0;
			end
		end
	end
	else
	begin
		i=0; j=0;
		if(ld_flag_basis2)
		begin
			flag_basis2 <= select_flag_basis2;
		end
	end
end


endmodule 
