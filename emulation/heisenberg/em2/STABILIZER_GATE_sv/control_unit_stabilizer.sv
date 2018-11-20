module control_unit_stabilizer #(parameter num_qubit = 4)(
input clk, input rst,
input valid_in_stabilizer, input done_amplitude, input [31:0] counter_valid_vector,
input [2:0] gate_type_norm, input [31:0] qubit_pos_ahead, output reg determine_amplitude2, input ram_amplitude_busy,
output [num_qubit-1:0] read_ram_alpha_stabilizer_address, output read_ram_alpha_stabilizer_en,
output read_amplitude_alpha_stabilizer_en, output [num_qubit-1:0] read_amplitude_alpha_stabilizer_address,
output write_amplitude_alpha_stabilizer_en, output [num_qubit-1:0] write_amplitude_alpha_stabilizer_address,
output rotateLeft_stabilizer_basis, output rotateLeft_stabilizer_basis2, output rotateLeft_Q2_individual,
output reg valid_out_stabilizer, input valid_out_canonical_mask, output mask_stabilizer_operation, output reg valid_P_stabilizer, 
output reg valid_P_from_stabilizer_to_nonstabilizer,
//To determine productQ in stabilizer operation
input [1:0] literals_out_stabilizer [0:num_qubit-1], output reg rotateLeft_reg_beta, output reg rotateDown_reg_beta, 
output reg ld_prodQ_stabilizer, output reg rotateLeft_Q_flag_basis_stabilizer,
//To determine amplitude beta
output reg determine_amplitude_stabilizer
);

//** basis_index for list 2 is maintained in parallel with any basis_index list 1 update => previous alpha stage or toffoli update (nonstabilizer case)
//** productQ for list 2 is determined in parallel with list 1 => previous beta stage (both stabilizer & nonstabilizer cases)
//** For first gate, amplitude1 is assigned to 1 whereas amplitude2 is assign to 0 

//CASE Current gate: stabilizer (general)
//---Operation is completed for previous gate---
//=> Take amplitude list from the beta operation of previous operation
//=> Load new gate info
//=> If(Hadamard gate), determine amplitude list 2. Have to store amplitude list 1 somewhere before this. 
//=> Determine alpha
//=> Update global phase with alpha (in parallel with basis_index list 2 determination & basis_index list 1 update based on initial_alpha_zero case)
//=> Determine basis_index list 2 (load next gate info, stabilizer case)

//---Receive literals & phases from cba + canonical module---
//=> Determine productQ based on corresponding basis index (after global phase alpha & basis_index list 2 updates)
//=> Determine beta
//=> Update global phase with beta

//CASE Current gate: Hadamard
//=> ProductQ for list 2 is determined based in basis index2 (have to check match_basis_index else amplitude is assign to 0) from previous beta operation 
//=> Determine amplitude list 2. Have to store amplitude list 1 somewhere before this. 
//=> Determine alpha. Update basis index for intial_alpha_zero case

reg reg1_enable, reg2_enable, reg3_enable, reg4_enable, reg5_enable;
reg [num_qubit-1:0] reg1_address; reg [num_qubit-1:0] reg2_address; reg [num_qubit-1:0] reg3_address; reg [num_qubit-1:0] reg4_address; 
reg [num_qubit-1:0] reg5_address;
wire rotate_one_round, first_count; //2**num_qubit clock
reg reg_rotate_one_round; reg done_alpha_stabilizer;

reg [2:0] state; reg [31:0] counter;
localparam [2:0] S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4, S5 = 3'd5, S6 = 3'd6, S7 = 3'd7;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state <= S0; determine_amplitude2 <= 1'd0; counter <= 0; done_alpha_stabilizer <= 1'd0;
	end
	else
	begin
		case(state)
			S0:	//Idle: Wait for new stabilizer gate
			begin
				determine_amplitude2 <= 1'd0; counter <= 0; done_alpha_stabilizer <= 1'd0;
				if(valid_in_stabilizer)
				begin
					state <= S1; counter <= 1;
				end
				else
				begin
					state <= S0;
				end
			end
			/************************************************ALPHA STAGE*********************************************************/
			//Step 1: Determine amplitude2 (if gate_type is Hadamard)
			//Step 2: Determine alpha based on gate_info_norm (certain amplitude2 might be zero, checked compliance of basis_index2 && productQ2)
			S1: 	//Make sure beta update on global phase of previous gate is completed before determine amplitude2
			begin
				determine_amplitude2 <= 1'd0; counter <= counter; done_alpha_stabilizer <= 1'd0;
				if(valid_in_stabilizer)
				begin
					counter <= counter + 1;
				end
				if(ram_amplitude_busy==1'd0)
				begin
					if(gate_type_norm == 3'd0) //Hadamard
					begin
						state <= S2; determine_amplitude2 <= 1'd1;
					end
					else //Phase or CNOT
					begin
						if(counter==num_qubit)
						begin
							state <= S3; counter <= 1;
						end
						else
						begin
							state <= S1;
						end
					end
				end
				else
				begin
					state <= S1;
				end
			end
			S2: 	//Hadamard: Wait for amplitude2 determination to be completed
			begin
				determine_amplitude2 <= 1'd0; counter <= 0; done_alpha_stabilizer <= 1'd0;
				if(done_amplitude)
				begin
					state <= S3; counter <= 1; //Avoid counter checking condition in the next stage
				end
				else
				begin
					state <= S2;
				end
			end
			S3: //Read amplitude 1 from RAM ALPHA (for basis index continues to 2**num_qubit)
			begin
				determine_amplitude2 <= 1'd0; done_alpha_stabilizer <= 1'd0;
				if (counter == 2**num_qubit-1)//(counter == counter_valid_vector-1) Ready for beta operation
				begin
					state <= S4;
					counter <= 32'd0;
				end
				else
				begin
					state <= S3;
					counter <= counter + 1;
				end
			end
			S4: //Wait for basis index to finish update. Then ready for stabilizer beta operation.
			begin
				determine_amplitude2 <= 1'd0; counter <= 32'd0; done_alpha_stabilizer <= 1'd1;
				if(valid_out_stabilizer)
				begin
					if(valid_in_stabilizer) //Current and next gates are stabilizer gates
					begin
						state <= S1; counter <= 1;
					end
					else
					begin
						state <= S0;
					end	
				end
				else
				begin
					state <= S4;
				end
			end
			default:
			begin
				state <= S0; determine_amplitude2 <= 1'd0; counter <= 0; done_alpha_stabilizer <= 1'd0;
			end
		endcase
	end
end
//Set to 1 during stabilizer operation
assign mask_stabilizer_operation = state != S0 && state != S1 && state != S2;

//Read previously stored amplitude1 from RAM ALPHA
assign first_count = (state==S1 && ram_amplitude_busy==1'd0 && gate_type_norm != 3'd0 && counter == num_qubit) || (state==S2 && done_amplitude);
assign read_ram_alpha_stabilizer_address = first_count? {num_qubit{1'd0}} : counter [num_qubit-1:0];
assign read_ram_alpha_stabilizer_en = (state==S3 && counter < counter_valid_vector) || first_count;

assign rotate_one_round = state==S3 || first_count;


/********************************************************SYNCHRONIZATION**************************************************************/
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		reg1_enable <= 1'd0; reg2_enable <= 1'd0; reg3_enable <= 1'd0; reg4_enable <= 1'd0; reg5_enable <= 1'd0; reg_rotate_one_round <= 1'd0;
		reg1_address <= {num_qubit{1'b0}}; reg2_address <= {num_qubit{1'b0}}; reg3_address <= {num_qubit{1'b0}}; reg4_address <= {num_qubit{1'b0}}; 
		reg5_address <= {num_qubit{1'b0}}; 
	end
	else
	begin
		reg_rotate_one_round <= rotate_one_round;
		reg1_enable <= read_ram_alpha_stabilizer_en; reg1_address <= read_ram_alpha_stabilizer_address;
		reg2_enable <= reg1_enable; reg2_address <= reg1_address;
		reg3_enable <= reg2_enable; reg3_address <= reg2_address;
		reg4_enable <= reg3_enable; reg4_address <= reg3_address;
		reg5_enable <= reg4_enable; reg5_address <= reg4_address;
	end
end

assign read_amplitude_alpha_stabilizer_en = reg2_enable; assign read_amplitude_alpha_stabilizer_address = reg2_address;
assign write_amplitude_alpha_stabilizer_en = reg5_enable; assign write_amplitude_alpha_stabilizer_address = reg5_address;

//basis_index2 is rotated ahead for determination of match_Q_basis_index for amplitude2
assign rotateLeft_stabilizer_basis = reg_rotate_one_round;
assign rotateLeft_stabilizer_basis2 = rotate_one_round | reg_rotate_one_round;
assign rotateLeft_Q2_individual = read_ram_alpha_stabilizer_en;


//FSM to handle beta operation
reg [2:0] state_beta; reg [31:0] counter_beta; reg [31:0] counter_rotate_left;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state_beta <= S0; counter_beta <= 32'd0; valid_out_stabilizer <= 1'd0; valid_P_stabilizer <= 1'd0; counter_rotate_left <= 32'd0;
		determine_amplitude_stabilizer <= 1'd0;
	end
	else
	begin
		case(state_beta)
			S0: //For stabilizer gate input
			begin
				counter_beta <= 32'd0; valid_out_stabilizer <= 1'd0; valid_P_stabilizer <= 1'd0; counter_rotate_left <= 32'd0; 
				valid_P_from_stabilizer_to_nonstabilizer <= 1'd0; determine_amplitude_stabilizer <= 1'd0;
				if(valid_in_stabilizer)
				begin
					state_beta <= S1;
				end
				else
				begin
					state_beta <= S0;
				end
			end
			S1: //After canonical reduction is completed
			begin
				counter_beta <= counter_beta; valid_out_stabilizer <= 1'd0; valid_P_stabilizer <= 1'd0; counter_rotate_left <= 32'd0;
				valid_P_from_stabilizer_to_nonstabilizer <= 1'd0; determine_amplitude_stabilizer <= 1'd0;
				if(valid_out_canonical_mask)
				begin
					counter_beta <= counter_beta + 1;
				end
				if(counter_beta==num_qubit)
				begin
					state_beta <= S2; valid_P_stabilizer <= 1'd1;
				end
				else
				begin
					state_beta <= S1;
				end
			end
			S2: //After alpha operation is completed
			begin
				counter_beta <= 32'd0; valid_out_stabilizer <= 1'd0; valid_P_stabilizer <= 1'd0; counter_rotate_left <= 32'd0;
				valid_P_from_stabilizer_to_nonstabilizer <= 1'd0; determine_amplitude_stabilizer <= 1'd0;
				if(done_alpha_stabilizer)
				begin
					state_beta <= S3; 
				end
				else
				begin
					state_beta <= S2;
				end
			end
			S3: //Determine productQ & productQ2 based on basis_index & basis_index2, respectively
			begin
				counter_rotate_left <= counter_rotate_left; counter_beta <= counter_beta; valid_out_stabilizer <= 1'd0; valid_P_stabilizer <= 1'd0;
				valid_P_from_stabilizer_to_nonstabilizer <= 1'd0; determine_amplitude_stabilizer <= 1'd0;
				if(literals_out_stabilizer[0][1]==1'd1)     //bottom left corner literal is X or Y
				begin
					//UPDATE Q & FLAG BASIS
					//SHIFT DOWN LITERALS
					if (counter_beta!=num_qubit-1)
					begin
						counter_beta <= counter_beta+1;
					end
				end
				else 									    //bottom left corner literal is Z or I
				begin
					//ROTATE LEFT LITERALS
					//ROTATE LEFT FLAG BASIS & Q
					counter_rotate_left <= counter_rotate_left + 1;
				end
				if	(counter_rotate_left==num_qubit-1)
				begin
					state_beta <= S6; 
					counter_rotate_left <= counter_rotate_left; counter_beta <= counter_beta;
					//START DETERMINE BETA & UDPATE RAM GLOBAL PHASE
					determine_amplitude_stabilizer <= 1'd1;
				end
				else
				begin
					state_beta <= S3;
				end	
			end
			//Determine amplitude
			S4: //Shift down to make sure literals & phase are back to order. Determine beta
			begin
				valid_P_from_stabilizer_to_nonstabilizer <= 1'd0; determine_amplitude_stabilizer <= 1'd0;
				if(counter_beta==num_qubit-1)
				begin
					state_beta <= S5; 
					valid_out_stabilizer <= 1'd1; counter_beta <= 32'd1; valid_P_stabilizer <= 1'd0; counter_rotate_left <= 32'd0;
				end
				else
				begin
					state_beta <= S4;
					valid_out_stabilizer <= 1'd0; counter_beta <= counter_beta+1; valid_P_stabilizer <= 1'd0; counter_rotate_left <= 32'd0;
				end	
			end
			S5: //Shift out literals & phase. In parallel: Read & Update & Write to RAM global phase
			begin
				valid_out_stabilizer <= 1'd1; valid_P_stabilizer <= 1'd0; counter_rotate_left <= 32'd0; valid_P_from_stabilizer_to_nonstabilizer <= 1'd0;
				determine_amplitude_stabilizer <= 1'd0;
				if(counter_beta == num_qubit-1)
				begin
					state_beta <= S0; 
					counter_beta <= 32'd0; 
					if(qubit_pos_ahead>3) //If the following gate is nonstabilizer gate
					begin
						valid_P_from_stabilizer_to_nonstabilizer <= 1'd1;
					end
				end
				else
				begin
					counter_beta <= counter_beta + 32'd1;
				end	
			end
			S6: //Added state to synchronize rotate left
			begin
				valid_out_stabilizer <= 1'd0; valid_P_stabilizer <= 1'd0; valid_P_from_stabilizer_to_nonstabilizer <= 1'd0; determine_amplitude_stabilizer <= 1'd0;
				state_beta <= S4; counter_beta <= counter_beta; counter_rotate_left <= counter_rotate_left;
			end
			default:
			begin
				state_beta <= S0; counter_beta <= 32'd0; valid_out_stabilizer <= 1'd0; valid_P_stabilizer <= 1'd0; counter_rotate_left <= 32'd0;
				valid_P_from_stabilizer_to_nonstabilizer <= 1'd0; determine_amplitude_stabilizer <= 1'd0;
			end
		endcase
	end
end



always@(*)
begin
	case(state_beta)
		S3:
		begin
			rotateLeft_reg_beta <= 1'd0; rotateDown_reg_beta <= 1'd0; ld_prodQ_stabilizer <= 1'd0; 
			rotateLeft_Q_flag_basis_stabilizer <= 1'd0;
			if(literals_out_stabilizer[0][1]==1'd1) 	//bottom left corner literal is X or Y
			begin
				//UPDATE Q (Q * literal_out) & FLAG BASIS (current flag basis ^ literal out [i][1])
				ld_prodQ_stabilizer <= 1'd1; 
				//ROTATE DOWN LITERALS
				rotateDown_reg_beta <= 1'd1; 
			end
			else
			begin
				//ROTATE LEFT LITERALS & FLAG BASIS & Q
				rotateLeft_reg_beta <= 1'd1; rotateLeft_Q_flag_basis_stabilizer <= 1'd1;
			end		
			if (counter_rotate_left==num_qubit-1) 
			begin
				rotateDown_reg_beta <= 1'd0; rotateLeft_reg_beta <= 1'd0; rotateLeft_Q_flag_basis_stabilizer <= 1'd0; 
			end
		end
		S4: //Make sure literals & basis index back to order before shift out (Rotate down if necessary)
		begin
			rotateLeft_reg_beta <= 1'd0; ld_prodQ_stabilizer <= 1'd0; rotateLeft_Q_flag_basis_stabilizer <= 1'd0;
			//ROTATE DOWN LITERALS - At least rotate once for it to be back to order 
			rotateDown_reg_beta <= 1'd1; 
		end
		S6:
		begin
			rotateLeft_reg_beta <= 1'd0; ld_prodQ_stabilizer <= 1'd0; rotateLeft_Q_flag_basis_stabilizer <= 1'd0;	rotateDown_reg_beta <= 1'd0; 
			rotateLeft_reg_beta <= 1'd1; rotateLeft_Q_flag_basis_stabilizer <= 1'd1;
		end
		default:
		begin
			rotateLeft_reg_beta <= 1'd0; rotateDown_reg_beta <= 1'd0; ld_prodQ_stabilizer <= 1'd0; 
			rotateLeft_Q_flag_basis_stabilizer <= 1'd0;
		end
	endcase
end
	
endmodule 
