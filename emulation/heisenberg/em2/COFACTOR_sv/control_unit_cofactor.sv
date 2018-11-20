module control_unit_cofactor #(parameter num_qubit = 4)(
//Input:
input clk, input rst, 
//New cofactor set signal should come before first valid row
//input new_cofactor, 
input valid_in, input flag_anticommute, input anticommute, input done_alpha, input valid_P, input final_cofactor,
input [31:0] reg_cofactor_pos, input [31:0] counter_valid_vector, //from update_add_phase module
//Output:
output reg ld_cofactor_info, output ld_reg, output reg [1:0] shift_rotate_array, output reg rst_flag, output reg valid_out, output reg valid_ori_phase_write,
//0: No changes; 1: Zn...I; 2: Mult with first anticommuting row; 3: External input
output reg [2:0] mux_shift_in, 
//0: No changes (phases rotate left); 1: Append new phase(s) or zero
output reg mux_phase_shift_in,
//Connect to global CU both flag and valid signals
output reg valid_flag_anticommute,
//Connect to determine_alpha_basis_index to synchronize the rotation
output reg ld_rotateLeft_basis,
//For beta:
output reg update_flag_basis, output reg ld_prodQ, output reg rotateLeft_Q_beta, output reg rotateLeft_flag_basis, input [1:0] literals_out [0:num_qubit-1], 
output determine_amplitude_beta, 
//Pull out for debug:
output reg [4:0] state, 
//For nonstabilizer:
output rotateLeft_P_nonstabilizer, output reg valid_P_nonstabilizer, input phaseShift_toffoli, output done_flag_nonstabilizer_update,
//For stabilizer:
output rotateLeft_Q2 
);

localparam [4:0] S0=5'd0, S1=5'd1, S2=5'd2, S3=5'd3, S4=5'd4, S5=5'd5, S6=5'd6, S7=5'd7, S8=5'd8, S9=5'd9, S10=5'd10, 
					  S11=5'd11, S12=5'd12, S13=5'd13, S14=5'd14, S15=5'd15, S16=5'd16, S17=5'd17, S18=5'd18, S19=5'd19; 

reg [31:0] counter; reg [31:0] counter_rotate_left; reg [31:0] counter_ori_vector; reg [31:0] anticommuting_row_index; reg flag_valid_P;

//COMBINE THESE 3 SIGNALS!!!
//0: shift down (both literals & phases); 1: rotate left (literals only); 2: rotate left (phases only)
reg ld_cu_reg0, ld_cu_reg1, ld_cu_reg2; 
assign ld_reg = ld_cu_reg0 | ld_cu_reg1 | ld_cu_reg2;
assign rotateLeft_Q2 = ld_cu_reg1;
always@(*)
begin
	if(ld_cu_reg1)
	begin
		shift_rotate_array <= 2'd1;
	end
	else if (ld_cu_reg2)
	begin
		shift_rotate_array <= 2'd2;
	end
	else 
	begin
		shift_rotate_array <= 2'd0;
	end
end

//For nonstabilizer
assign rotateLeft_P_nonstabilizer = (state==S16)? 1'd1:1'd0;
assign done_flag_nonstabilizer_update = (rotateLeft_P_nonstabilizer && (counter==2**num_qubit-1))? 1'd1:1'd0;

always@(*)
begin
	if((state == S3 && counter == num_qubit-1 && final_cofactor && flag_anticommute==0) || (state == S13 && counter == num_qubit-1 && final_cofactor))
	begin
		valid_P_nonstabilizer <= 1'd1;
	end
	else
	begin
		valid_P_nonstabilizer <= 1'd0;
	end
end

/***************************************************FINITE STATE MACHINE********************************************************/
always@(posedge clk or posedge rst)
begin	
	if(rst)
	begin
		counter <= 32'd0; counter_rotate_left <= 32'd0; counter_ori_vector <= 32'd0; state <= S1; //S0; 
		ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; flag_valid_P <= 1'd0; 
	end
	else
	begin
		case(state)
/*			//Not necessary to have a seperate signal to indicate cofactor operation. Valid input to the module is controlled by valid signals
			S0: //Idle wait state
			begin
				counter <= 32'd0; counter_rotate_left <= 32'd0; counter_ori_vector <= counter_ori_vector;
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; flag_valid_P <= 1'd0;
				if(new_cofactor)
				begin
					state <= S1; ld_cofactor_info <= 1'd1; 
				end
				else
				begin
					state <= S0; ld_cofactor_info <= 1'd0; 
				end
			end
*/			
			S1: //Load input literals and phase from external. 
			begin
				counter_rotate_left <= 32'd0; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0;  
				ld_cofactor_info <= 1'd0;  valid_out <= 1'd0; valid_flag_anticommute <= 1'd0;
				if(valid_in)
				begin
					counter <= counter+1;
				end
				else
				begin
					counter <= counter;
				end				
				if(valid_in & counter == 32'd0)
				begin
					ld_cofactor_info <= 1'd1; 
				end
				else
				begin
					ld_cofactor_info <= 1'd0; 
				end				
				if(counter == num_qubit-1 && valid_in)
				begin
					counter <= 32'd0;
					//Valid reg_cofactor_pos only load at third valid in signal clock - Work fine for 3-qubit circuit & above
					if(reg_cofactor_pos==0) //Cofactor column is already aligned to left. No need rotate left
					begin
						state <= S3;  
					end
					else //Align cofactor column to the left
					begin
						state <= S2;  
					end
				end
				else
				begin
					state <= S1; 
				end
			end
			S2: //Rotate left to align column-of-interest for cofactor to the left
			begin
				counter <= 32'd0; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0; 
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0;	counter_rotate_left <=  counter_rotate_left + 1; 
				valid_flag_anticommute <= 1'd0;
				if(counter_rotate_left == reg_cofactor_pos-1)
				begin
					state <= S3; 	 
				end
				else
				begin
					state <= S2; 	
				end
			end
			S3: //Shift down one round to check for commutativity and update literals and phase for randomized outcome
			begin
				counter_rotate_left <= counter_rotate_left; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0;
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; 
				if(counter == num_qubit-1) 
				begin
					valid_flag_anticommute <= 1'd1; 
					counter <= 32'd0;
					if(counter_rotate_left == 0) //No left rotation was performed previously, no adjustment is required
					begin
						//Randomized outcome
						if(flag_anticommute)
						begin
							state <= S5; 	
						end
						//Deterministic outcome
						else
						begin	
							if(final_cofactor)
							begin
								state <= S16; counter <= 0; 
							end
							else
							begin
								state <= S15; counter <= 32'd1; valid_out <= 1'd1;
							end									
						end
					end
					else
					begin		
						if(flag_anticommute)
						begin
							state <= S4;
						end
						else
						begin
							if(final_cofactor)
							begin
								state <= S16; counter <= 0; 
							end
							else
							begin
								state <= S4;
							end	
						end										
					end
				end
				else
				begin
					state <= S3; counter <= counter + 1;	
				end
			end
			S4: //Rotate left until register array back to order
			begin
				counter <= 32'd0; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0; 
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0;
				if(counter_rotate_left == num_qubit-1)
				begin
					counter_rotate_left <= 32'd0;
					//Randomized outcome
					if(flag_anticommute)
					begin
						state <= S5; 	
					end
					//Deterministic outcome
					else
					begin
						state <= S15; counter <= 32'd1; valid_out <= 1'd1;											
					end
				end
				else
				begin
					state <= S4; counter_rotate_left <= counter_rotate_left + 1;	
				end
			end
			/**************************************************For Randomized Outcome*************************************************/
			//Step 1: Rotate down to anticommuting row (based on identified row index from the first round). To facilitate phase vector update at later stage. 
			//Step 2: Rotate left (phase only) one full round to fill up index table. Assert respective signal. 2**n clock cycles. 
			//      : Meanwhile, fill up alpha table (store in registers then rotate & write to memory)
			//      : Meanwhile, store basis index1 & 2 in registers. Rotate basis_index1 to end of the list
			//Step 3: Rotate left (phase only) up to the last original valid phase vector. Append newly added phase vector from FIFO. Update counter_vector
			//		  : Meanwhile, rotate basis_index2 and append the necessary ones to basis_index1 shift registers.
			//Step 4: Rotate down (phases & literals) if necessary to ensure they are back in correct order
			//Step 5: Shift out literal & phase rows for canonical reduction operation
			//Step 6: Shift in resulted literal & phase rows (from canonical row reduction). --KIV
			//Step 7: Extract beta (extract_specific based on basis_index1). Update amplitude (one-by-one in background). --KIV
			//Step 8: Shift out literal & phase rows for next operation --KIV
			/***********************************************************************************************************************/
			S5: //Randomized outcome Step 1: Rotate down to align anticommuting row at the bottom			
			begin			
				counter_rotate_left <= 32'd0; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0; 
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0;
				if(counter == anticommuting_row_index)
				begin
					state <= S6;
					counter <= counter; counter_ori_vector <= counter_valid_vector;
				end
				else
				begin
					state <= S5;
					counter <= counter + 32'd1;
				end
			end
			S6: //Randomized outcome Step 2: Rotate left (phase only) one full round to fill up index table
			begin
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0;
				if(counter_rotate_left == 2**num_qubit-1)
				begin
					counter_rotate_left <= 32'd0;
					if(done_alpha)
					begin
						state <= S7;  
					end
					else //Wait until memory write for alpha is completed
					begin
						state <= S9; 
					end
				end
				else
				begin
					state <= S6; counter_rotate_left <= counter_rotate_left + 1;	
				end
			end
			S7: //Randomized outcome Step 3: Rotate left (phase only)& append newly added phase vector from FIFO. 
			begin
				counter <= counter; counter_ori_vector <= counter_ori_vector;	flag_valid_P <= 1'd0; 
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; 
				if(counter_rotate_left == 2**num_qubit-1) 
				begin
					counter_rotate_left <= 32'd0;
					if(counter == 0) //No rotate down is required. Register array is in order
					begin
						state <= S10; counter <= 32'd1; valid_out <= 1'd1;
					end
					else
					begin
						state <= S8;
					end
				end
				else
				begin
					counter_rotate_left <= counter_rotate_left + 1;
					state <= S7;
				end
			end
			S8: //Randomized outcome Step 4: Rotate down (phases & literals) to ensure they are back in correct order
			begin
				counter_rotate_left <= 32'd0; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0; 
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0;
				if(counter == num_qubit-1)
				begin
					counter <= 32'd0;
					state <= S10; counter <= 32'd1; valid_out <= 1'd1;
				end
				else
				begin
					state <= S8; counter <= counter + 32'd1;
				end
			end
			S9: //Additional wait state for handshaking. Ensure write alpha in memory is completed before amplitude update 
			begin
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; counter_ori_vector <= counter_ori_vector;
				counter_rotate_left <= counter_rotate_left; counter <= counter; flag_valid_P <= 1'd0; 
				if(done_alpha)
				begin
					state <= S7;
				end
				else
				begin
					state <= S9;
				end
			end
			S10: //Final state - shift literals & phases out -> Randomized outcome (alpha)
			begin
				counter_rotate_left <= 32'd0; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0; 
				ld_cofactor_info <= 1'd0; valid_out <= 1'd1; valid_flag_anticommute <= 1'd0;
				if(counter == num_qubit) 
				begin
					state <= S11; counter <= 32'd0; valid_out <= 1'd0; 	 
				end
				else
				begin
					state <= S10; counter <= counter + 1; valid_out <= 1'd1;
				end	
			end
			S11: //Second round cofactor beta: Take output from canonical form reduction module
			begin
				counter_rotate_left <= 32'd0; counter_ori_vector <= counter_ori_vector; flag_valid_P <= flag_valid_P; 
				ld_cofactor_info <= 1'd0;  valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; 
				if(valid_P)
				begin
					flag_valid_P <= 1'd1;
				end
				if(valid_in)
				begin
					counter <= counter+1;
				end
				else
				begin
					counter <= counter;
				end
				if (counter == num_qubit & (valid_P | flag_valid_P)) 
				begin
					counter <= 32'd0;
					state <= S12;
				end
				else
				begin
					state <= S11; 
				end
			end
			S12: //Second round cofactor beta: Determine product Q
			begin
				counter_rotate_left <= counter_rotate_left; counter_ori_vector <= counter_ori_vector; counter <= counter;  
				ld_cofactor_info <= 1'd0;  valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; flag_valid_P <= 1'd0; 
				if(literals_out[0][1]==1'd1) 	//bottom left corner literal is X or Y
				begin
					//UPDATE Q & FLAG BASIS
					//SHIFT DOWN LITERALS
					if (counter!=num_qubit-1)
					begin
						counter <= counter+1;
					end
				end
				else 							//bottom left corner literal is Z or I
				begin
					//ROTATE LEFT LITERALS
					//ROTATE LEFT FLAG BASIS & Q
					counter_rotate_left <= counter_rotate_left + 1;
				end
				if	(counter_rotate_left==num_qubit-1)
				begin
					state <= S13;
					counter_rotate_left <= counter_rotate_left; counter <= counter;
					//START DETERMINE BETA & UDPATE RAM GLOBAL PHASE
				end
				else
				begin
					state <= S12;
				end
			end
			S13: //Make sure literals & basis index back to order before shift out (rotate down if necessary)
			begin
				counter_rotate_left <= counter_rotate_left; counter_ori_vector <= counter_ori_vector; counter <= counter;  
				ld_cofactor_info <= 1'd0;  valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; flag_valid_P <= 1'd0; 
				//SHIFT DOWN LITERALS
				counter <= counter+1;
				if(counter==num_qubit-1) 
				begin
					if(final_cofactor)
					begin
						state <= S16; counter <= 32'd0; 
					end
					else
					begin
						state <= S14;
					end			
				end
				else
				begin
					state <= S13;
				end
			end
			S14: //Make sure literals & basis index back to order before shift out (rotate left if necessary)
			begin
				counter_rotate_left <= counter_rotate_left; counter_ori_vector <= counter_ori_vector; counter <= counter;  
				ld_cofactor_info <= 1'd0;  valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; flag_valid_P <= 1'd0; 
				//ROTATE LEFT LITERALS
				counter_rotate_left <= counter_rotate_left + 1;
				if(counter_rotate_left==num_qubit-1) 
				begin
					state <= S15; counter <= 32'd1; valid_out <= 1'd1;
				end
				else
				begin
					state <= S14;
				end
			end					
			S15: //Final state - shift literals & phases out -> Deterministic outcome & Randomized outcome (beta)
			begin
				counter_rotate_left <= 32'd0; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0; 
				ld_cofactor_info <= 1'd0; valid_out <= 1'd1; valid_flag_anticommute <= 1'd0;
				if(counter == num_qubit) 
				begin
					state <= S1;
					counter <= 32'd0; valid_out <= 1'd0; 	 
				end
				else
				begin
					state <= S15; counter <= counter + 1; valid_out <= 1'd1;
				end	
			end		
			S16:
			begin
				counter_rotate_left <= counter_rotate_left; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0;
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; 
				counter <= counter + 1; 
				if(counter==2**num_qubit-1)
				begin
					if(phaseShift_toffoli==0) //Toffoli
					begin
						state <= S17; counter <= 0;
					end
					else //Phase shift: Update is performed in nonstabilizer_operation module. Proceeed to shift out result
					begin
						counter <= 0;
						if(counter_rotate_left==0)
						begin
							state <= S15; counter <= 32'd1; valid_out <= 1'd1;
						end
						else
						begin
							state <= S14;
						end
					end
				end
				else
				begin
					state <= S16;
				end
			end
			S17: //Toffoli gate update: Align target qubit column to the left
			begin
				counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0; ld_cofactor_info <= 1'd0; valid_out <= 1'd0; 
				valid_flag_anticommute <= 1'd0; counter <= counter; counter_rotate_left <= counter_rotate_left;
				if(counter_rotate_left==reg_cofactor_pos)
				begin
					state <= S18;
				end
				else
				begin
					state <= S17;
					if(counter_rotate_left==num_qubit-1)
					begin
						counter_rotate_left <= 0;
					end
					else if (counter_rotate_left==reg_cofactor_pos)
					begin
						counter_rotate_left <= counter_rotate_left;
					end
					else
					begin
						counter_rotate_left <= counter_rotate_left + 1;
					end
				end
			end
			S18: //Toffoli gate update
			begin
				counter_rotate_left <= counter_rotate_left; counter_ori_vector <= counter_ori_vector; flag_valid_P <= 1'd0;
				ld_cofactor_info <= 1'd0; valid_out <= 1'd0; valid_flag_anticommute <= 1'd0; 
				if(counter==num_qubit-1)
				begin
					if(counter_rotate_left==0)
					begin
						state <= S15; counter <= 32'd1; valid_out <= 1'd1;
					end
					else
					begin
						state <= S14;
					end
				end
				else
				begin
					state <= S18; counter <= counter + 1;
				end
			end								
			default:
			begin
				ld_cofactor_info <= 1'd0; counter <= 32'd0;	valid_out <= 1'd0; counter_rotate_left <= 32'd0; flag_valid_P <= 1'd0;
				state <= S1; //S0; 
			end
		endcase
	end
end

assign determine_amplitude_beta = (state == S13)? 1'd1 : 1'd0;

//Store row index of anticommuting row 
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		anticommuting_row_index <= 32'd0;
	end
	else
	begin
		if(state==S3 && anticommute && flag_anticommute == 1'd0)
		begin
			anticommuting_row_index <= counter;
		end
		else
		begin
			anticommuting_row_index <= anticommuting_row_index;
		end
	end
end

//Mealy model for generating control signals
always@(*)
begin
	case(state)
/*	
	S0: //Idle wait state
	begin
		rst_flag <= 1'd0; mux_shift_in <= 2'd0; valid_ori_phase_write <= 1'd0; mux_phase_shift_in <= 1'd0;
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0; 
	end
*/	
	S1: //Load input literals and phase from external. 
	begin
		rst_flag <= 1'd1;		//Reset anticommute registers and flag
		mux_shift_in <= 3'd3; 	//Select input from external
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; valid_ori_phase_write <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		if(valid_in)
		begin
			ld_cu_reg0 <= 1'd1; //Shift down
		end
	end
	S2: //Rotate left to align column-of-interest for cofactor to the left
	begin
		mux_shift_in <= 3'd0; valid_ori_phase_write <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		rst_flag <= 1'd1;       //Reset anticommute registers and flag
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd1; ld_cu_reg2 <= 1'd0; //Rotate left literals only			
	end
	S3: //Shift down one round to check for commutativity and update literals and phase for randomized outcome
	begin
		rst_flag <= 1'd0; valid_ori_phase_write <= 1'd0; ld_cu_reg0 <= 1'd1; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		if(anticommute==1'd1)
		begin
			if(flag_anticommute==1'd0)	//First anticommuting row_global, replace literals with Zn row
			begin
				mux_shift_in <= 3'd1; 	//Select Zn row
			end
			else
			begin
				mux_shift_in <= 3'd2; 	//Select output from multiplication module
			end
		end
		else
		begin
			mux_shift_in <= 3'd0; 		//No changes. Rotate function
		end
	end
	S4: //Rotate left (literals only) until register array back to order
	begin
		mux_shift_in <= 3'd0; rst_flag <= 1'd0; valid_ori_phase_write <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd1; ld_cu_reg2 <= 1'd0; //Rotate left		
	end
	S5: //Randomized outcome Step 1: Rotate down to align anticommuting row at the bottom
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; valid_ori_phase_write <= 1'd0; mux_phase_shift_in <= 1'd0;
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		if(counter == anticommuting_row_index)
		begin
			ld_cu_reg0 <= 1'd0;
		end
		else
		begin
			ld_cu_reg0 <= 1'd1; mux_shift_in <= 3'd0; //Rotate down (phases & literals)
		end
	end
	S6: //Randomized outcome Step 2: Rotate left (phase only) one full round to fill up index table
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		ld_cu_reg2 <= 1'd1;	
		if(counter_rotate_left < counter_ori_vector)
		begin
			valid_ori_phase_write <= 1'd1;
		end
		else
		begin
			valid_ori_phase_write <= 1'd0;
		end
	end
	S7: //Randomized outcome Step 3: Rotate left (phase only) & append newly added phase vector from FIFO. 
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; valid_ori_phase_write <= 1'd0; 
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		mux_phase_shift_in <= 1'd0;
		ld_cu_reg2 <= 1'd1;	
		if (counter_rotate_left >= counter_ori_vector)  //Append new phases or 0 after valid phase vectors
		begin
			mux_phase_shift_in <= 1'd1;
		end
	end
	S8: //Randomized outcome Step 4: Rotate down (phases & literals) to ensure they are back in correct order
	begin
		rst_flag <= 1'd0; valid_ori_phase_write <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		ld_cu_reg0 <= 1'd1; mux_shift_in <= 3'd0; 		//No changes. Rotate function
	end
	S9: //Additional wait state for handshaking. Ensure write alpha in memory is completed before amplitude update 
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; valid_ori_phase_write <= 1'd0; 
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; mux_phase_shift_in <= 1'd0; 
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
	end
	S10: //Final state - shift literals & phases out -> Randomized outcome (alpha)
	begin
		rst_flag <= 1'd0; valid_ori_phase_write <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		ld_cu_reg0 <= 1'd1; mux_shift_in <= 3'd0; 		//No changes. Rotate function
	end
	S11: //Second round cofactor beta: Take output from canonical form reduction module
	begin
		//ld_reg signal taken directly from valid_in, instant load
		rst_flag <= 1'd1;	    //Reset anticommute registers and flag
		mux_shift_in <= 3'd3; 	//Select input from external
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; valid_ori_phase_write <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		if(valid_in)
		begin
			ld_cu_reg0 <= 1'd1; //Shift down
		end
	end
	S12: //Second round cofactor beta: Determine product Q
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; valid_ori_phase_write <= 1'd0; mux_phase_shift_in <= 1'd0;
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		if(literals_out[0][1]==1'd1) 	//bottom left corner literal is X or Y
		begin
			update_flag_basis <= 1'd1; ld_prodQ <= 1'd1; 
			//ROTATE DOWN LITERALS
			ld_cu_reg0 <= 1'd1; mux_shift_in <= 3'd0;
		end
		else    				//bottom left corner literal is Z or I
		begin
			//ROTATE LEFT LITERALS
			ld_cu_reg1 <= 1'd1; 
			//ROTATE LEFT FLAG BASIS & Q
			rotateLeft_Q_beta <= 1'd1; rotateLeft_flag_basis <= 1'd1;
		end		
		if (counter_rotate_left==num_qubit-1) 
		begin
			ld_cu_reg1 <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		end
		if (counter==num_qubit-1 || counter_rotate_left==num_qubit-1) 
		begin
			ld_cu_reg0 <= 1'd0; 
		end
	end	
	S13: //Make sure literals & basis index back to order before shift out (Rotate down if necessary)
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; valid_ori_phase_write <= 1'd0; mux_phase_shift_in <= 1'd0;
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		//ROTATE DOWN LITERALS - At least rotate once for it to be back to order 
		ld_cu_reg0 <= 1'd1; mux_shift_in <= 3'd0;
	end
	S14: //Make sure literals & basis index back to order before shift out (Rotate left if necessary)
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; valid_ori_phase_write <= 1'd0; mux_phase_shift_in <= 1'd0;
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		//ROTATE LEFT LITERALS - At least rotate once for it to be back to order
		ld_cu_reg1 <= 1'd1; 
	end	
	S15: //Final state - shift literals & phases out -> Randomized outcome (beta)
	begin
		rst_flag <= 1'd0; valid_ori_phase_write <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		ld_cu_reg0 <= 1'd1; mux_shift_in <= 3'd0; 		//No changes. Rotate function
	end
	S16:
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; valid_ori_phase_write <= 1'd0; 
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; mux_phase_shift_in <= 1'd0; 
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
	end
	S17: //Toffoli align target column to the left
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; valid_ori_phase_write <= 1'd0; 
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; mux_phase_shift_in <= 1'd0; 
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
		if(counter_rotate_left==reg_cofactor_pos)
		begin
			ld_cu_reg1 <= 1'd0;	
		end
		else
		begin
			ld_cu_reg1 <= 1'd1; 
		end
	end
	S18: //Toffoli phase update: rotate down & replace
	begin
		rst_flag <= 1'd0; valid_ori_phase_write <= 1'd0; ld_cu_reg0 <= 1'd1; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; mux_phase_shift_in <= 1'd0;
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0; 
		if(literals_out[0]==2'd1) //Row of which target qubit contains Z literals
		begin
			mux_shift_in <= 3'd4;
		end
		else
		begin
			mux_shift_in <= 3'd0;
		end
	end
	default:
	begin
		rst_flag <= 1'd0; mux_shift_in <= 3'd0; valid_ori_phase_write <= 1'd0; 
		ld_cu_reg0 <= 1'd0; ld_cu_reg1 <= 1'd0; ld_cu_reg2 <= 1'd0; mux_phase_shift_in <= 1'd0; 
		update_flag_basis <= 1'd0; ld_prodQ <= 1'd0; rotateLeft_Q_beta <= 1'd0; rotateLeft_flag_basis <= 1'd0;
	end
	endcase
end

always@(posedge clk or posedge rst)
begin
	if (rst)
	begin
		ld_rotateLeft_basis <= 1'd0;
	end
	else
	begin
		if(state == S7)
		begin
			ld_rotateLeft_basis <= 1'd1;
		end
		else
		begin
			ld_rotateLeft_basis <= 1'd0;
		end
	end
end

endmodule
