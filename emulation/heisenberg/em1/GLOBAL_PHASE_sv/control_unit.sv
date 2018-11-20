module control_unit #(parameter num_qubit = 4)(
//General:
input clk, input rst, input start,
//Input:
input valid_in,  input done_alpha, input valid_P, input literal_phase_readout, input done_multQ, input flag_anticommute,
input done_amplitude, input ld_reg0_prodQ, input ld_reg1_prodQ, input ld_reg2_prodQ, input ld_Q_loadP_prodQ, 
input ld_Q_loadMultQ_prodQ, input ld_Q_rotateLeft_prodQ, input ld_Q2_loadP_prodQ, input ld_Q2_loadMultQ_prodQ, 
input ld_Q2_rotateLeft_prodQ, input ld_Q_loadP_amp, input ld_Q_loadMultQ_amp, input ld_Q_rotateLeft_amp, 
input ld_Q2_loadP_amp, input ld_Q2_loadMultQ_amp, input ld_Q2_rotateLeft_amp, input [1:0] reg_gate_type,
//Output:
output reg [3:0] state_CU,
output ld_Q, output ld_Q2, output reg load_rotate_Q, output reg load_Q_mux, output ld_reg, 
output reg [1:0] shift_rotate_array, output reg ld_gate_info, output reg done_readout, output reg valid_out, 
output reg determine_alpha, output reg ld_basis_index, output reg ld_global_phase, output reg alpha_beta, 
output reg determine_multQ, output reg ld_matchQ_index, output reg determine_amplitude, output reg ld_measure_update  
);

//reg [3:0] state_CU;
localparam  SCU0=4'd0, SCU1=4'd1, SCU2=4'd2, SCU3=4'd3, SCU4=4'd4, SCU5=4'd5, SCU6=4'd6, SCU7=4'd7, 
SCU8=4'd8, SCU9=4'd9, SCU10=4'd10, SCU11=4'd11, SCU12=4'd12, SCU13=4'd13, SCU14=4'd14, SCU15=4'd15;

wire ld_reg_readin; reg ld_reg_readout; reg [31:0] count_readout;
assign ld_reg_readin = valid_in;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state_CU <= SCU0;
		done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0;
	end
	else
	begin
		case(state_CU)
			SCU0: //Idle Waiting 
			begin
				//Default:
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0;				
				//Wait for start signal
				if(start)
				begin
					state_CU <= SCU1;
				end
				else 
				begin
					state_CU <= SCU0;
				end
			end
			SCU1: //Load gate type, qubit position(s)
			begin
				//Default:
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0;
				state_CU <= SCU2;
			end
			SCU2: //Initiate alpha determination
			begin
				//Default:
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0;	
				state_CU <= SCU3;
			end
			SCU3: //Alpha determination. Load basis index upon completion
			begin
				//Default:
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0;
				//Check if computation of alpha completed
				if(done_alpha == 0)
				begin
					state_CU <= SCU3;
				end
				else //Done computation of alpha
				begin
					state_CU <= SCU4;					
				end
			end
			SCU4: //Wait until valid_P, update global phase (global phase * alpha). Or readout literals at final stage
			begin
				//Default
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0;
				//Wait for output from canonical form reduction module
				if(valid_P)
				begin
					state_CU <= SCU5;	
				end
				//Read out final stabilizer matrix (literals and phases)
				else if(literal_phase_readout)
				begin
					state_CU <= SCU8;
					count_readout <= num_qubit-1;	valid_out <= 1'd1;
				end
				else
				begin
					state_CU <= SCU4;
				end
			end
			SCU5: //Initiate multQ determination
			begin
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0;
				state_CU <= SCU6;
			end
			SCU6: //multQ determination. Load matchQ_index & initiate amplitude determination upon completion. 
			begin
				//Default:
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0;
				if(done_multQ == 0)
				begin
					state_CU <= SCU6;
				end
				else
				begin
					//Load matchQ_index & determine amplitude
					state_CU <= SCU7;					
				end
			end
			SCU7: //Amplitude determination. Update global phase (global phase / beta) upon completion 
			begin
				//Default:
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0;
				if(done_amplitude == 0)
				begin
					state_CU <= SCU7;
				end
				else
				begin
					//Update global phase with beta
					state_CU <= SCU1;
				end
			end
			SCU8:
			begin
				//Default:
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= count_readout;
				//Read out literals and phase
				if(count_readout > 0)
				begin
					//ROTATE DOWN			
					state_CU <= SCU8;
					count_readout <= count_readout - 1; valid_out <= 1'd1;
				end
				else //(count_readout == 0) => last rotate down for literals array back to order
				begin
					state_CU <= SCU0;
					done_readout <= 1'd1; valid_out <= 1'd0; 
				end
			end
			default:
			begin
				//Default:
				done_readout <= 1'd0; valid_out <= 1'd0; count_readout <= 32'd0; state_CU <= SCU0;
			end
		endcase
	end
end

/****************MEALY MODEL FOR CONTROL SIGNALS FOR LOADING REGISTERS & RELATED MULTIPLEXER(S)******************/
always@(*)
begin
	case(state_CU)
		SCU0:
		begin
			//Default:
			determine_alpha <= 1'd0; determine_multQ <= 1'd0; determine_amplitude <= 1'd0; ld_gate_info <= 1'd0; 
			ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; alpha_beta <= 1'd0;	ld_matchQ_index <= 1'd0; ld_measure_update <= 1'd0; 
			ld_reg_readout <= 1'd0; 
		end
		SCU1:
		begin
			//Default:
			ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; alpha_beta <= 1'd0; determine_multQ <= 1'd0; ld_measure_update <= 1'd0; 
			ld_matchQ_index <= 1'd0; determine_amplitude <= 1'd0; ld_reg_readout <= 1'd0; determine_alpha <= 1'd0; 
			//Load gate information
			ld_gate_info <= 1'd1;
		end
		SCU2:
		begin
			//Default:
			ld_gate_info <= 1'd0; ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; alpha_beta <= 1'd0; ld_measure_update <= 1'd0; 
			determine_multQ <= 1'd0; ld_matchQ_index <= 1'd0; determine_amplitude <= 1'd0; ld_reg_readout <= 1'd0; 
			//Determine alpha
			determine_alpha <= 1'd1;
		end
		SCU3:
		begin
			//Default
			ld_gate_info <= 1'd0;  determine_alpha <= 1'd0; ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; ld_measure_update <= 1'd0; 
			alpha_beta <= 1'd0; determine_multQ <= 1'd0; ld_matchQ_index <= 1'd0; determine_amplitude <= 1'd0; 
			ld_reg_readout <= 1'd0;
			//Done computation of alpha
			if(done_alpha)
			begin
				ld_basis_index <= 1'd1; //Update basis_index based on gate info
			end
		end
		SCU4:
		begin
			//Default:
			ld_gate_info <= 1'd0;  determine_alpha <= 1'd0;	ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; ld_measure_update <= 1'd0; 
			alpha_beta <= 1'd0; determine_multQ <= 1'd0; ld_matchQ_index <= 1'd0; determine_amplitude <= 1'd0; 
			ld_reg_readout <= 1'd0; 
			//Wait for output from canonical form reduction module
			if(valid_P)
			begin
				if(reg_gate_type == 2'd3) //Measurement gate
				begin
					ld_basis_index <= 1'd1;
				end
				else //Stabilizer gates
				begin
					ld_global_phase<=1'd1; alpha_beta<=1'd0; //Update global phase with alpha
				end
			end
		end
		SCU5:
		begin
			//Default:
			ld_gate_info <= 1'd0; determine_alpha <= 1'd0; ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; ld_measure_update <= 1'd0; 
			alpha_beta <= 1'd0; ld_matchQ_index <= 1'd0; determine_amplitude <= 1'd0; ld_reg_readout <= 1'd0; 
			//Initiate multQ
			determine_multQ <= 1'd1;
		end
		SCU6:
		begin
			//Default:
			ld_gate_info <= 1'd0;  determine_alpha <= 1'd0; ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; ld_measure_update <= 1'd0; 
			alpha_beta <= 1'd0; determine_multQ <= 1'd0; ld_matchQ_index <= 1'd0; determine_amplitude <= 1'd0; 
			ld_reg_readout <= 1'd0; 
			if(done_multQ)
			begin
				ld_matchQ_index <= 1'd1; determine_amplitude <= 1'd1;
			end
		end
		SCU7:
		begin
			//Default:
			ld_gate_info <= 1'd0; determine_alpha <= 1'd0; ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; ld_measure_update <= 1'd0; 
			alpha_beta <= 1'd0; determine_multQ <= 1'd0; ld_matchQ_index <= 1'd0; determine_amplitude <= 1'd0; 
			ld_reg_readout <= 1'd0; 
			if(done_amplitude)
			begin
				if(reg_gate_type == 2'd3) //Measurement randomized outcome
				begin
					ld_global_phase<=1'd0; alpha_beta<=1'd0;
					if(flag_anticommute)
					begin
						ld_measure_update <= 1'd1;
					end
				end
				else
				begin
					ld_global_phase<=1'd1; alpha_beta<=1'd1; //Update global phase with beta
				end
			end
		end
		SCU8:
		begin
			//Default:
			ld_gate_info <= 1'd0;  determine_alpha <= 1'd0; ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; ld_measure_update <= 1'd0; 
			alpha_beta <= 1'd0; determine_multQ <= 1'd0; ld_matchQ_index <= 1'd0; determine_amplitude <= 1'd0; 
			ld_reg_readout <= 1'd0; 
			//Read out literals and phase - Rotate for num_qubit times, last rotation is to make literals back to order
			ld_reg_readout <= 1'd1;
		end
		default:
		begin
			//Default:
			determine_alpha <= 1'd0; determine_multQ <= 1'd0; determine_amplitude <= 1'd0; ld_gate_info <= 1'd0; 
			ld_basis_index <= 1'd0;	ld_global_phase <= 1'd0; alpha_beta <= 1'd0; ld_matchQ_index <= 1'd0; ld_measure_update <= 1'd0; 
			ld_reg_readout <= 1'd0; 
		end
	endcase
end


/************************************COMBINE SIGNALS FOR CONTROLLING Q REGISTERS**************************************/ 
assign ld_Q = ld_Q_loadP_amp | ld_Q_loadMultQ_amp | ld_Q_rotateLeft_amp | ld_Q_loadP_prodQ | ld_Q_loadMultQ_prodQ 
| ld_Q_rotateLeft_prodQ;
assign ld_Q2 = ld_Q2_loadP_amp | ld_Q2_loadMultQ_amp | ld_Q2_rotateLeft_amp | ld_Q2_loadP_prodQ | ld_Q2_loadMultQ_prodQ
| ld_Q2_rotateLeft_prodQ;

wire loadP, loadMultQ, rotateLeft;
assign loadP = ld_Q_loadP_amp | ld_Q_loadP_prodQ | ld_Q2_loadP_amp | ld_Q2_loadP_prodQ;
assign loadMultQ = ld_Q_loadMultQ_amp | ld_Q_loadMultQ_prodQ | ld_Q2_loadMultQ_amp | ld_Q2_loadMultQ_prodQ;
assign rotateLeft = ld_Q_rotateLeft_amp | ld_Q_rotateLeft_prodQ | ld_Q2_rotateLeft_amp | ld_Q2_rotateLeft_prodQ;

always@(*)
begin
	if(loadP)
	begin
		load_rotate_Q <= 1'd0;
		load_Q_mux <= 1'd0;
	end
	else if(loadMultQ)
	begin
		load_rotate_Q <= 1'd0;
		load_Q_mux <= 1'd1;
	end
	else if(rotateLeft)
	begin
		load_rotate_Q <= 1'd1;
		load_Q_mux <= 1'd0;
	end
	else //default
	begin
		load_rotate_Q <= 1'd0;
		load_Q_mux <= 1'd0;
	end
end

/********************************COMBINE SIGNALS FOR CONTROLLING REGISTER ARRAY**********************************/
assign ld_reg = ld_reg_readin | ld_reg_readout | ld_reg0_prodQ | ld_reg1_prodQ | ld_reg2_prodQ;
wire ld_reg0, ld_reg1, ld_reg2;
assign ld_reg0 = ld_reg_readin | ld_reg0_prodQ;
assign ld_reg1 = ld_reg_readout | ld_reg1_prodQ;
assign ld_reg2 = ld_reg2_prodQ;

always@(*)
begin
	if(ld_reg0)
	begin
		shift_rotate_array <= 2'd0;
	end
	else if(ld_reg1)
	begin
		shift_rotate_array <= 2'd1;
	end
	else if(ld_reg2)
	begin
		shift_rotate_array <= 2'd2;
	end
	else //default
	begin
		shift_rotate_array <= 2'd0;
	end
end

endmodule

