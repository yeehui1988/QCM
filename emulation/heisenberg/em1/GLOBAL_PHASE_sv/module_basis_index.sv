module module_basis_index #(parameter num_qubit = 3)(
//General:
input clk, input rst_new,
//Input:
input ld_basis_index, input ld_basis_index2, input initial_alpha_zero, 
input [1:0] reg_gate_type, input [31:0] reg_qubit_pos, input [31:0] reg2_qubit_pos, input [31:0] reg_qubit_pos2, 
input basis_index_P [0:num_qubit-1],
//Output:
output reg basis_index [0:num_qubit-1], output reg basis_index2[0:num_qubit-1]
);

integer i;

/*************************************REGISTERS FOR BASIS INDEX & INPUT SELECTION***********************************/
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0;i<num_qubit;i=i+1)
		begin
			basis_index[i] <= 1'd0;
		end
	end
	else
	begin
		i=0;
		if(ld_basis_index)
		begin
			//Take basis_index2 (possible case for Hadamard) if first calculated alpha is 0
			//basis_index[i] = basis_index[i] + temp_const (for odd) or basis_index[i] + temp_const (for even) 
			//Equivalent to basis_index2
			if(initial_alpha_zero == 1'd1 && reg_gate_type == 2'd0)
			begin
				basis_index <= basis_index2;
			end
			//Update basis_index (for CNOT)
			else if(reg_gate_type == 2'd2)
			begin
				basis_index <= basis_index;
				//If control qubit equals to 1
				if(basis_index[reg_qubit_pos] == 1'd1) 
				begin
					//Toggle target qubit
					if (basis_index [reg_qubit_pos2] == 1'd1) //Equal to 1
					begin
						basis_index [reg_qubit_pos2] <= 1'd0;
					end
					else //Equal to 0
					begin
						basis_index [reg_qubit_pos2] <= 1'd1;
					end
				end
			end
			else if(reg_gate_type == 2'd3) //Measurement gate
			begin
				basis_index <= basis_index_P;
			end
			else 
			begin
				basis_index <= basis_index;
			end
		end
	end
end

/*************************************REGISTERS FOR BASIS INDEX2 & INPUT SELECTION***********************************/
//Only used for the case of Hadamard only

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0;i<num_qubit;i=i+1)
		begin
			basis_index2[i] <= 1'd0;
		end
	end
	else
	begin
		i=0;
		if(ld_basis_index2)
		begin
			if(basis_index[reg2_qubit_pos])
			begin
				basis_index2 <= basis_index;
				basis_index2 [reg2_qubit_pos] <= 1'd0;
			end
			else
			begin
				basis_index2 <= basis_index;
				basis_index2 [reg2_qubit_pos] <= 1'd1;
			end			
		end
	end
end

endmodule
