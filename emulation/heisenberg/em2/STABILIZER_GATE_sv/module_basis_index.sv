module module_basis_index #(parameter num_qubit=4)(
input clk, input rst,
//Stsbilizer    => 0: Hadamard; 1: Phase; 2: CNOT; 
//Nonstabilizer => 3: Measurement; 4: Controlled Phase-Shift; 5: Toffoli 
input [2:0] gate_type_norm, 
input [31:0] qubit_pos_norm, input [31:0] qubit_pos2_norm, //[0:num_qubit-1]
input [31:0] qubit_pos_ahead,
input basis_index_in [0:num_qubit-1], input basis_index_leftmost [0:num_qubit-1], input ld_basis_index_in, //basis_index rotate left right in
input initial_alpha_zero, input rotateLeft_stabilizer_basis2,
output reg basis_index_update [0:num_qubit-1], output reg basis_index2 [0:2**num_qubit-1][0:num_qubit-1], 
output basis_index2_leftmost [0:num_qubit-1]
);

integer i,j;
reg select_basis_index2 [0:num_qubit-1];  
wire ld_basis_index2; reg rotate_update; //0: rotateLeft; 1: rotateLeft + update

assign basis_index2_leftmost = basis_index2[0];

/********************************************FOR HADAMARD & CNOT: UPDATE BASIS INDEX LIST1******************************************/

always@(*)
begin
	//Possible case for Hadamard: first calculated alpha is equal to 0
	if(initial_alpha_zero == 1'd1 && gate_type_norm == 2'd0)
	begin
		basis_index_update <= basis_index_leftmost;
		//Take equivalent basis_index2
		if(basis_index_leftmost[qubit_pos_norm]) //Toggle the bit
		begin
			basis_index_update [qubit_pos_norm] <= 1'd0;
		end
		else
		begin
			basis_index_update [qubit_pos_norm] <= 1'd1;
		end
	end
	//For CNOT gate
	else if(gate_type_norm == 2'd2)
	begin
		basis_index_update <= basis_index_leftmost;
		//If control qubit equals to 1
		if(basis_index_leftmost[qubit_pos_norm] == 1'd1)
		begin
			//Toggle target qubit
			if(basis_index_leftmost[qubit_pos2_norm] == 1'd1)
			begin
				basis_index_update [qubit_pos2_norm] <= 1'd0;
			end
			else
			begin
				basis_index_update [qubit_pos2_norm] <= 1'd1;
			end
		end
	end
	else
	begin
		basis_index_update <= basis_index_leftmost;
	end
end


/**************************************************FOR HADAMARD: BASIS INDEX LIST2**************************************************/
//Basis index list2 is contructed ahead based on the following gate qubit position (for the next gate if it is Hadamard)
always@(*)
begin
	select_basis_index2 <= basis_index_in;
	if(basis_index_in[qubit_pos_ahead]) //Toggle the bit
	begin
		select_basis_index2 [qubit_pos_ahead] <= 1'd0;
	end
	else
	begin
		select_basis_index2 [qubit_pos_ahead] <= 1'd1;
	end
end

always@(*)
begin
	if(ld_basis_index_in | rotateLeft_stabilizer_basis2)
	begin
		rotate_update <= 1'd1;
	end
	else
	begin
		rotate_update <= 1'd0;
	end
end

assign ld_basis_index2 = ld_basis_index_in | rotateLeft_stabilizer_basis2;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for(i=0;i<2**num_qubit;i=i+1)
		begin
			for(j=0;j<num_qubit;j=j+1)
			begin
				basis_index2[i][j] <= 1'd0;
			end
		end
	end
	else
	begin
		i=0; j=0;
		if(ld_basis_index2) //rotate left & load content based on basis_index
		begin		
			if(rotate_update) //1: rotateLeft + update
			begin
				for(i=0;i<2**num_qubit-1;i=i+1)
				begin
					for(j=0;j<num_qubit;j=j+1)
					begin
						basis_index2[i][j] <= basis_index2[i+1][j];
						basis_index2[2**num_qubit-1][j] <= select_basis_index2[j];
					end
				end
			end
			else	//0: rotateLeft
			begin
				for(i=0;i<2**num_qubit-1;i=i+1)
				begin
					for(j=0;j<num_qubit;j=j+1)
					begin
						basis_index2[i][j] <= basis_index2[i+1][j];
						basis_index2[2**num_qubit-1][j] <= basis_index2[0][j];
					end
				end
			end			
		end
		else
		begin
			basis_index2 <= basis_index2;
		end
	end
end

endmodule 
