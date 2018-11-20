module fsm_productQ #(parameter num_qubit = 4)(
//General:
input clk, input rst_new,
//Input:
input determine_multQ, input [1:0] reg_gate_type, input [1:0] literals_out[0:num_qubit-1], input valid_P,
input flag_basis_pos [0:num_qubit-1], input flag_basis_pos2 [0:num_qubit-1],
//Output:
output reg done_multQ, output reg ld_basis_index2, output reg ld_flag_pos, output reg [1:0] load_update_flag, 
output reg ld_flag_pos2, output reg ld_reg0, output reg ld_reg1, output reg ld_reg2, output reg ld_Q_loadP, 
output reg ld_Q_loadMultQ, output reg ld_Q_rotateLeft, output reg ld_Q2_loadP, output reg ld_Q2_loadMultQ, 
output reg ld_Q2_rotateLeft
);

localparam  S0=3'd0, S1=3'd1, S2=3'd2, S3=3'd3, S4=3'd4, S5=3'd5, S6=3'd6, S7=3'd7;
reg [2:0] state_multQ;
reg [31:0] count_row; reg [31:0] count_col;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		state_multQ <= S0;
		count_row <= num_qubit-1; count_col <= num_qubit-1; done_multQ <= 1'd0;
	end
	else
	begin
		case(state_multQ)
		S0: //Idle Waiting State
		begin
			//Default setting for control signals & registers
			count_row <= num_qubit-1; count_col <= num_qubit-1; done_multQ <= 1'd0;
			//Wait for start signal
			if(determine_multQ)
			begin
				if(reg_gate_type == 2'd0) 
				begin
					state_multQ <= S1;
				end
				//For other gate type, proceed to column rotation and alignment 
				else
				begin
					state_multQ <= S2;
				end
			end
			else
			begin
				state_multQ <= S0;
			end
		end
		S1: //For CNOT: 2nd basis state & flag
		begin
			//Default setting for control signals & registers
			count_row <= count_row; count_col <= count_col; done_multQ <= 1'd0;
			state_multQ <= S2;	
		end
		S2: //Literal-of-interest is at bottom left corner. Align literals array and Q with that. Rotate left
		begin
			//Default setting for control signals & registers
			count_row <= count_row; count_col <= count_col; done_multQ <= 1'd0;
			//Continue to rotate until flagged position(s) is align at the bottom left corner
			if(count_col > 32'd0)
			begin
				if (flag_basis_pos[0] == 1'd1 || flag_basis_pos2[0] == 1'd1)
				begin
					state_multQ <= S3;
				end
				else
				begin
					//ROTATE LEFT - continue until flagged position is found or till the last column
					count_col <= count_col-1; state_multQ <= S2;
				end
			end
			else //count_col == 32'd0
			begin				
				if (flag_basis_pos[0] == 1'd1 || flag_basis_pos2[0] == 1'd1)
				begin
					state_multQ <= S3;
				end
				else
				begin
					state_multQ <= S4;
				end
			end
		end
		S3: //Search for ROW with matched flag position for Q computation - ROTATE DOWN
		begin
			//Default setting for control signals & registers
			count_row <= count_row; count_col <= count_col; done_multQ <= 1'd0;
			//Search for matched row and flag
			if(count_row > 32'd0)
			begin
				//Q * ROW: Update Q & flag
				//X or Y literal at the bottom left corner match with flag
				if(literals_out[0][1]==1'd1 && (flag_basis_pos[0] == 1'd1 || flag_basis_pos2[0] == 1'd1)) 
				begin
					if(count_col==32'd0)
					begin
						state_multQ <= S4;
					end
					else
					begin
						state_multQ <= S2;
					end
				end
				else
				begin
					//ROTATE DOWN
					count_row <= count_row-1; state_multQ <= S3;
				end
			end
			else //count_row == 32'd0
			begin
				//Q*ROW: Update Q & flag
				//X or Y literal at the bottom left corner match with flag
				state_multQ <= S4;
			end		
		end
		S4: //Clear up remaining rotation to ensure literal back to order: COLUMN-WISE
		begin
			//Default setting for control signals & registers
			count_row <= count_row; count_col <= count_col; done_multQ <= 1'd0;
			//Clear up remaining rotation
			if(count_col==32'd0)
			begin
				state_multQ <= S5;
				count_col <= count_col;
			end
			else
			begin
				state_multQ <= S4;
				count_col <= count_col-1;
			end
		end
		S5: //Clear up remaining rotation to ensure literal back to order: ROW-WISE
		begin
			//Default setting for control signals & registers
			count_row <= count_row; count_col <= count_col; done_multQ <= 1'd0;
			//No down rotation has been performed. Hence, no adjustment is needed
			if(count_row==(num_qubit-1))
			begin
				state_multQ <= S6;
			end
			else 
			begin
				//ROTATE DOWN
				if(count_row==0)
				begin
					state_multQ <= S6;
					count_row <= count_row;
				end
				else
				begin
					state_multQ <= S5;
					count_row <= count_row-1;
				end
			end
		end
		S6: //Done_multQ
		begin
			//Default setting for control signals & registers
			count_row <= count_row; count_col <= count_col; done_multQ <= 1'd0;
			//Reset based on valid_P
			if(valid_P == 1'd0)
			begin
				state_multQ <= S6;
				done_multQ <= 1'd1;
			end
			else
			begin
				state_multQ <= S0;
				done_multQ <= 1'd0;
			end
		end
		default:
		begin
			//Default setting for control signals & registers
			count_row <= count_row; count_col <= count_col; done_multQ <= 1'd0; state_multQ <= S0;
		end
		endcase
	end
end

/*******************MEALY MODEL FOR CONTROL SIGNALS FOR LOADING REGISTERS & RELATED MULTIPLEXER(S)********************/
always@(*)
begin
	case(state_multQ)
		S0:
		begin
			//Default:
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
			ld_flag_pos <= 1'd0; load_update_flag <= 2'd0; ld_flag_pos2 <= 1'd0; ld_basis_index2 <= 1'd0;
			ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd0;
			if(determine_multQ)
			begin
				//Load P into Q and Q2
				ld_Q_loadP <= 1'd1; ld_Q2_loadP <= 1'd1; 
				//Load flag based on basis index - first one only
				ld_flag_pos <= 1'd1; load_update_flag <= 2'd0; 
				//For Hadamard gate, determine the 2nd basis index
				if(reg_gate_type == 2'd0) 
				begin
					ld_basis_index2 <= 1'd1; 
				end
			end
		end
		S1:
		begin
			//Default:
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
			ld_flag_pos <= 1'd0; load_update_flag <= 2'd0; ld_flag_pos2 <= 1'd0; ld_basis_index2 <= 1'd0;
			ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd0;
			//Load flag based on basis index - second one only
			ld_flag_pos2 <= 1'd1; load_update_flag <= 2'd0;
		end
		S2:
		begin
			//Default:
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
			ld_flag_pos <= 1'd0; load_update_flag <= 2'd0; ld_flag_pos2 <= 1'd0; ld_basis_index2 <= 1'd0;
			ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd0; 
			//Continue to rotate until flagged position(s) is align at the bottom left corner
			if(count_col > 32'd0)
			begin
				if (flag_basis_pos[0] != 1'd1 && flag_basis_pos2[0] != 1'd1)
				begin
					//ROTATE LEFT - continue until flagged position is found or till the last column
					ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd1; 
					ld_flag_pos <= 1'd1; ld_flag_pos2 <= 1'd1; load_update_flag <= 2'd2; 
					ld_Q_rotateLeft <= 1'd1; ld_Q2_rotateLeft <= 1'd1; 
				end
			end
		end
		S3:
		begin
			//Default:
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
			ld_flag_pos <= 1'd0; load_update_flag <= 2'd0; ld_flag_pos2 <= 1'd0; ld_basis_index2 <= 1'd0;
			ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd0; 
			if(count_row > 32'd0)
			begin
				//Q * ROW: Update Q & flag
				//X or Y literal at the bottom left corner match with flag
				if(literals_out[0][1]==1'd1 && (flag_basis_pos[0] == 1'd1 || flag_basis_pos2[0] == 1'd1)) 
				begin
					//Update Q with Q * ROW
					//load_rotate_Q <= 1'd0; load_Q_mux <= 1'd1; //1: Update Q with Q * ROW  
					//Update flag synchronized with Q x ROW operation
					load_update_flag <= 2'd1; //2'd1: Update flag
					if(flag_basis_pos[0] == 1'd1)
					begin
						ld_Q_loadMultQ <= 1'd1;  	
						ld_flag_pos <= 1'd1;
					end
					if(flag_basis_pos2[0] == 1'd1)
					begin
						ld_Q2_loadMultQ <= 1'd1;  
						ld_flag_pos2 <= 1'd1;
					end
				end
				else
				begin
					//ROTATE DOWN
					ld_reg0 <= 1'd0; ld_reg1 <= 1'd1; ld_reg2 <= 1'd0;
				end
			end
			else //count_row == 32'd0
			begin
				//Q*ROW: Update Q & flag
				//X or Y literal at the bottom left corner match with flag
				if(literals_out[0][1]==1'd1 && (flag_basis_pos[0] == 1'd1 || flag_basis_pos2[0] == 1'd1)) 
				begin
					load_update_flag <= 2'd1; //2'd1: Update flag synchronized with Q x ROW operation
					if(flag_basis_pos[0] == 1'd1)
					begin
						ld_Q_loadMultQ <= 1'd1; 
						ld_flag_pos <= 1'd1;
					end
					if(flag_basis_pos2[0] == 1'd1)
					begin
						ld_Q2_loadMultQ <= 1'd1; 
						ld_flag_pos2 <= 1'd1;
					end
				end
			end		
		end
		S4:
		begin
			//Default:
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
			ld_flag_pos <= 1'd0; load_update_flag <= 2'd0; ld_flag_pos2 <= 1'd0; ld_basis_index2 <= 1'd0;
			ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd0;
			//ADJUST FOR COLUMN: ROTATE LEFT
			ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd1;
			ld_flag_pos <= 1'd1; ld_flag_pos2 <= 1'd1; load_update_flag <= 2'd2; 
			ld_Q_rotateLeft <= 1'd1; ld_Q2_rotateLeft <= 1'd1;
		end
		S5:
		begin
			//Default:
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
			ld_flag_pos <= 1'd0; load_update_flag <= 2'd0; ld_flag_pos2 <= 1'd0; ld_basis_index2 <= 1'd0;
			ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd0;
			if(count_row!=(num_qubit-1))
			begin
				//ADJUST FOR ROW: ROTATE DOWN
				ld_reg0 <= 1'd0; ld_reg1 <= 1'd1; ld_reg2 <= 1'd0;
			end
		end
		S6:
		begin
			//Default:
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0; 
			ld_flag_pos <= 1'd0; load_update_flag <= 2'd0; ld_flag_pos2 <= 1'd0; ld_basis_index2 <= 1'd0;
			ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd0;
		end
		default:
		begin
			//Registers for Q 
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
			//Registers for flag_pos
			ld_flag_pos <= 1'd0; load_update_flag <= 2'd0; ld_flag_pos2 <= 1'd0; 
			//Register array
			ld_reg0 <= 1'd0; ld_reg1 <= 1'd0; ld_reg2 <= 1'd0;
			//Register for basis_index
			ld_basis_index2 <= 1'd0;
		end
	endcase
end

endmodule
