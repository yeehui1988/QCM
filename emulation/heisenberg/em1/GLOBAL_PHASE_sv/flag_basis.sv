module flag_basis #(parameter num_qubit = 4)(
//General:
input clk, input rst_new,
//Input:
input ld_flag_pos, input ld_flag_pos2, input [1:0] load_update_flag,
input basis_index [0:num_qubit-1], input basis_index2 [0:num_qubit-1],
input [1:0] literals_out[0:num_qubit-1],
input [1:0] reg_literals_P [0:num_qubit-1],
//Output:
output reg flag_basis_pos [0:num_qubit-1], output reg flag_basis_pos2 [0:num_qubit-1]
);

integer i;

/************************FLAG TO KEEP TRACK OF AMPLITUDE EXTRACTION OF SPECIFIC BASIS_INDEX*************************/
//Update after each valid row mult to Q registers
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for(i=0;i<num_qubit;i++)
		begin
			flag_basis_pos[i] <= 1'd0; flag_basis_pos2[i] <= 1'd0; 
		end
	end
	else
	begin
		if(ld_flag_pos)
		begin
			case(load_update_flag)
				2'd0: //Load flag from basis index
				begin
					for(i=0;i<num_qubit;i++)
					begin
						flag_basis_pos[i] <= (basis_index[i] ^ reg_literals_P[i][1]);
					end
				end
				2'd1: //Update of flag which to be synchronized with Q x ROW operation
				begin
					for(i=0;i<num_qubit;i++)
					begin
						flag_basis_pos[i] <= flag_basis_pos[i] ^ literals_out[i][1]; //XOR for X or Y literals
					end
				end
				2'd2: //Rotate left - to align literal-of-interest at the left corner
				begin
					flag_basis_pos[num_qubit-1] <= flag_basis_pos[0];
					for(i=0;i<(num_qubit-1);i++)
					begin
						flag_basis_pos[i] <= flag_basis_pos[i+1];
					end
				end
				default:
				begin
					flag_basis_pos <= flag_basis_pos;
				end
			endcase
		end
		if(ld_flag_pos2)
		begin
			case(load_update_flag)
				2'd0: //Load flag from basis index2
				begin
					for(i=0;i<num_qubit;i++)
					begin
						flag_basis_pos2[i] <= (basis_index2[i] ^ reg_literals_P[i][1]);					
					end
				end
				2'd1: //Update of flag which to be synchronized with Q2 x ROW operation
				begin
					for(i=0;i<num_qubit;i++)
					begin
						flag_basis_pos2[i] <= flag_basis_pos2[i] ^ literals_out[i][1]; //XOR for X or Y literal
					end
				end
				2'd2: //Rotate left - to align literal-of-interest at the left corner
				begin
					flag_basis_pos2[num_qubit-1] <= flag_basis_pos2[0];
					for(i=0;i<(num_qubit-1);i++)
					begin
						flag_basis_pos2[i] <= flag_basis_pos2[i+1];
					end
				end
				default:
				begin
					flag_basis_pos2 <= flag_basis_pos2;
				end
			endcase
		end
	end
end

endmodule
