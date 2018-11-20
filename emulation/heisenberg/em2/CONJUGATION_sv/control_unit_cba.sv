module control_unit_cba #(parameter num_qubit = 4)(
//General:
input clk,
input rst, 
//Input:
input valid_in,
input [2:0] gate_type, //0: Hadamard; 1: Phase; 2: CNOT
input [31:0] qubit_pos, input [31:0] qubit_pos2,
input toggle_phase [0:num_qubit-1],
//Output:
output reg ld_literal, output reg ld_c, output reg ld_t, output reg valid_out, output reg rotate_update_literal, 
output reg shift_rotate_literal, output reg control_target, output reg shift_toggle_phase, 
output reg ld_phase[0:num_qubit-1]
);

integer i;

//DOUBLE CHECK CONTROL SIGNALS FOR THE CASE OF COUNTER == 0 OR COUNTER == NUM_QUBIT-1

/**********************************************CONTROL UNIT**********************************************/
//For literal registers	: ld_literal, shift_rotate, rotate_update
//For literal update	: control_target, ld_c, ld_t
//For phase registers	: ld_phase, shift_toggle
//Others 				: start, gate_type, qubit_pos, qubit_pos2, valid

reg [2:0] state;
localparam  S0=3'd0, S1=3'd1, S2=3'd2, S3=3'd3, S4=3'd4, S5=3'd5, S6=3'd6, S7=3'd7;
reg [31:0] n_counter;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state <= S1; n_counter <= 32'd0;	valid_out <= 1'd0;	
	end
	else
	begin
		case(state)
/*		
			S0: //Waiting - Idle
			begin
				valid_out <= 1'd0; n_counter <= 32'd0;
				if(start)
				begin
					state <= S1;
				end
				else
				begin
					state <= S0;
				end
			end		
*/			
			S1: //Load literals and phases from external input into registers
			begin
				//Default:
				valid_out <= 1'd0; n_counter <= n_counter;
				//Update counter with each valid input row of literals and phase
				if(valid_in)
				begin
					n_counter <= n_counter + 32'd1;	
				end
				else
				begin
					n_counter <= n_counter;
				end	
				//Change of state after num_qubit rows of literals and phases are loaded into register
				if(n_counter == num_qubit) 
				begin
					n_counter <= 32'd0; //reset counter
					if(gate_type == 3'd0 || gate_type == 3'd1)  //For Hadamard or Phase gate
					begin
						state <= S2;
					end
					else if(gate_type == 3'd2)	                //For CNOT gate
					begin
						state <= S3;
					end
					else
					begin
						state <= S1;
					end
				end
				else
				begin
					state <= S1;
				end
			end
			S2: //For Hadamard or Phase gate
			begin
				//For change of state and control bit for literal registers
				//Extra one rotation to make literals back in order 
				if(n_counter == (num_qubit - 32'd1))  
				begin
					n_counter <= 32'd0; valid_out <= 1'd1;
					state <= S4;
				end
				else
				begin
					n_counter <= n_counter + 32'd1; valid_out <= 1'd0;
					state <= S2;
				end
			end
			S3: //For CNOT gate
			begin
				//For change of state and control bit for literal registers
				//Extra one rotation to make literals back in order 
				//1st round to retrieve literal; 2nd round to update
				if(n_counter == (2*num_qubit - 32'd1)) 
				begin
					n_counter <= 32'd0; valid_out <= 1'd1;
					state <= S4;
				end
				else
				begin
					n_counter <= n_counter + 32'd1; valid_out <= 1'd0;
					state <= S3;
				end		
			end
			S4: //Shift resulted literals and phases out from registers as output
			begin
				if(n_counter == (num_qubit - 32'd1))
				begin
					n_counter <= 32'd0; valid_out <= 1'd0; state <= S1;
				end
				else
				begin
					n_counter <= n_counter + 32'd1; valid_out <= 1'd1; state <= S4;
				end
			end
			default:
			begin
				state <= S1; n_counter <= 32'd0;	valid_out <= 1'd0;				
			end
		endcase
	end
end

/*********************************GENERATE CONTROL SIGNALS THROUGH MEALY MODEL*********************************/
always@(*)
begin
	case(state)
/*	
		S0:
		begin
			//Default:
			ld_c <= 1'd0; ld_t <= 1'd0; shift_rotate_literal <= 1'd0; control_target <= 1'd0;  ld_literal <= 1'd0; 
			rotate_update_literal <= 1'd0; shift_toggle_phase <= 1'd0; //Shift down phases				
			for (i=0; i<num_qubit; i=i+1) 	//each row 
			begin
				ld_phase[i] <= 1'd0;
			end	
		end
*/		
		S1:
		begin
			//Default:
			shift_rotate_literal <= 1'd0; shift_toggle_phase <= 1'd0; ld_c <= 1'd0; ld_t <= 1'd0; 
			control_target <= 1'd0; rotate_update_literal <= 1'd0;
			for (i=0; i<num_qubit; i=i+1) 	    //each row 
			begin
				ld_phase[i] <= 1'd0;
			end
			//Load valid literals phases
			if(valid_in)
			begin
				ld_literal <= 1'd1; 
				for (i=0; i<num_qubit; i=i+1) 	//each row 
				begin
					ld_phase[i] <= 1'd1;
				end	
			end
			else
			begin
				ld_literal <= 1'd0; 
				for (i=0; i<num_qubit; i=i+1) 	//each row 
				begin
					ld_phase[i] <= 1'd0;
				end
			end
		end
		S2: //For Hadamard & Phase gate
		begin
			ld_literal <= 1'd1; shift_rotate_literal <= 1'd1;	ld_c <= 1'd0; ld_t <= 1'd0; control_target <= 1'd0; 
			//For update of literal and phase registers based on LUT
			if(n_counter == qubit_pos)
			begin
				rotate_update_literal <= 1'd1; shift_toggle_phase <= 1'd1; 
				for (i=0; i<num_qubit; i=i+1) 	//each row 
				begin
					if (toggle_phase[i] == 1'd1)
					begin
						ld_phase[i] = 1'd1; 
					end
					else
					begin
						ld_phase[i] = 1'd0; 
					end
				end
			end
			else
			begin
				rotate_update_literal <= 1'd0; shift_toggle_phase <= 1'd0; 
				for (i=0; i<num_qubit; i=i+1) 	//each row 
				begin
					ld_phase [i] <= 1'd0; 
				end
			end
		end
		S3: //For CNOT gate
		begin
			ld_literal <= 1'd1; shift_rotate_literal <= 1'd1;	
			//For update of literal and phase registers based on LUT
			if (n_counter == qubit_pos) 		//Store control qubit
			begin
				ld_c <= 1'd1; ld_t <= 1'd0; 
				control_target <= 1'd0; rotate_update_literal <= 1'd0; shift_toggle_phase <= 1'd0; 
				for (i=0; i<num_qubit; i=i+1) 	//each row 
				begin
					ld_phase [i] <= 1'd0; 
				end
			end
			else if (n_counter == qubit_pos2) 	//Store target qubit
			begin
				ld_c <= 1'd0; ld_t <= 1'd1; 
				control_target <= 1'd0; rotate_update_literal <= 1'd0; shift_toggle_phase <= 1'd0;
				for (i=0; i<num_qubit; i=i+1) 	//each row 
				begin
					ld_phase [i] <= 1'd0; 
				end
			end
			else if (n_counter == (qubit_pos + num_qubit)) //Update control qubit
			begin
				rotate_update_literal <= 1'd1; control_target <= 1'd0; 
				ld_c <= 1'd0; ld_t <= 1'd0; shift_toggle_phase <= 1'd0;
				for (i=0; i<num_qubit; i=i+1) 	//each row 
				begin
					ld_phase [i] <= 1'd0; 
				end
			end
			else if (n_counter == (qubit_pos2 + num_qubit)) //Update target qubit & phase
			begin
				rotate_update_literal <= 1'd1; control_target <= 1'd1; shift_toggle_phase <= 1'd1; 
				ld_c <= 1'd0; ld_t <= 1'd0;  
				for (i=0; i<num_qubit; i=i+1) 	//each row 
				begin
					if (toggle_phase[i] == 1'd1)
					begin
						ld_phase[i] = 1'd1; 
					end
					else
					begin
						ld_phase[i] = 1'd0; 
					end
				end
			end
			else
			begin
				ld_c <= 1'd0; ld_t <= 1'd0; control_target <= 1'd0; rotate_update_literal <= 1'd0;
				shift_toggle_phase <= 1'd0; 
				for (i=0; i<num_qubit; i=i+1)   //each row 
				begin
					ld_phase [i] <= 1'd0; 
				end
			end
		end
		S4:
		begin
			shift_rotate_literal <= 1'd0; shift_toggle_phase <= 1'd0; ld_c <= 1'd0; ld_t <= 1'd0; 
			control_target <= 1'd0; rotate_update_literal <= 1'd0;
			ld_literal <= 1'd1; 
			for (i=0; i<num_qubit; i=i+1) 	    //each row 
			begin
				ld_phase[i] <= 1'd1;
			end
		end
		default:
		begin
			ld_literal <= 1'd0; ld_c <= 1'd0; ld_t <= 1'd0; rotate_update_literal <= 1'd0; 
			shift_rotate_literal <= 1'd0; control_target <= 1'd0; shift_toggle_phase <= 1'd0; 
			for (i=0; i<num_qubit; i=i+1) 	    //each row 
			begin
				ld_phase[i] <= 1'd0;
			end			
		end
	endcase
end

endmodule
