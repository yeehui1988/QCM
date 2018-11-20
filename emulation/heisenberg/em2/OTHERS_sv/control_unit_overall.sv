module control_unit_overall #(parameter num_qubit = 3, phase_lookup = 5)(
input clk, input rst,
//0: Hadamard; 1: Phase; 2: CNOT; 3: Measurement; 4: Controlled Phase-Shift; 5: Toffoli 
input [2:0] gate_type,
//For controlled phase-shift gate only
input [phase_lookup-1:0] phase_shift_index, 
//For Hadamard & Phase: qubit_pos is the target qubit
//For CNOT & Controlled Phase-Shift: qubit_pos is the control qubit, qubit_pos2 is the target qubit
//For Toffoli: qubit pos & qubit_pos1 are the control qubits, qubit_pos2 is the target qubit  
input [31:0] qubit_pos, input [31:0] qubit_pos2, input [31:0] qubit_pos3, output reg update_gate_info, input final_gate,
input valid_out_individual_cofactor, //update new gate info ahead for basis index2 & productQ2 determination (nonstabilizer gates)
output reg [2:0] gate_type_norm, output reg [phase_lookup-1:0] phase_shift_index_norm, 
output reg [31:0] qubit_pos_norm, output reg [31:0] qubit_pos2_norm, output reg [31:0] qubit_pos3_norm,
output reg [2:0] gate_type_ahead, output reg [31:0] qubit_pos_ahead, output first_gate, 
//For nonstabilizer:
output reg [1:0] literals_in_nonstabilizer [0:num_qubit-1], output reg phase_in_nonstabilizer [0:2**num_qubit-1], output reg valid_in_nonstabilizer,
input [1:0] literals_out_nonstabilizer_no_buffer [0:num_qubit-1], input phase_out_nonstabilizer_no_buffer [0:2**num_qubit-1], input valid_out_nonstabilizer_no_buffer,
input valid_out_nonstabilizer_buffer, output reg valid_P_nonstabilizer, output reg valid_out_nonstabilizer,
//For stabilizer:
output reg [1:0] literals_in_stabilizer [0:num_qubit-1], output reg phase_in_stabilizer [0:2**num_qubit-1], output reg valid_in_stabilizer,
input [1:0] literals_out_stabilizer [0:num_qubit-1], input phase_out_stabilizer [0:2**num_qubit-1], input valid_out_stabilizer,
//Overall:
output reg [1:0] literals_out [0:num_qubit-1], output reg phase_out [0:2**num_qubit-1], output reg valid_out,
//Input from external: for verification purposes only. Actual implementation will be initialized to basis state |0(x)n>
input [1:0] literals_in [0:num_qubit-1], input phase_in [0:2**num_qubit-1], input valid_in,
input [1:0] literals_P_in [0:2**num_qubit-1][0:num_qubit-1], input valid_P_in, input [1:0] literals_P_canonical [0:2**num_qubit-1][0:num_qubit-1],
output reg [1:0] literals_P [0:2**num_qubit-1][0:num_qubit-1] 
);

integer i;

reg [1:0] literals_out_nonstabilizer [0:num_qubit-1]; reg phase_out_nonstabilizer [0:2**num_qubit-1];  reg [2:0] gate_type_hold;
//Determine overall output selection for nonstabilizer output
always@(*)
begin
	if(gate_type_hold == 3'd5) //Special case for Toffoli outcome
	begin
		valid_out_nonstabilizer <= valid_out_nonstabilizer_no_buffer; 
		literals_out_nonstabilizer <= literals_out_nonstabilizer_no_buffer; phase_out_nonstabilizer <= phase_out_nonstabilizer_no_buffer;
	end
	else
	begin
		valid_out_nonstabilizer <= valid_out_nonstabilizer_buffer; 
		literals_out_nonstabilizer <= literals_out_stabilizer; phase_out_nonstabilizer <= phase_out_stabilizer;
	end
end

//Select output for nonstabilizer literals and phases

reg [1:0] state_info;
localparam S0=2'd0, S1=2'd1, S2=2'd2, S3=2'd3;
reg [phase_lookup-1:0] phase_shift_index_ahead; reg [31:0] qubit_pos2_ahead; reg [31:0] qubit_pos3_ahead;
reg [31:0] counter_valid;

/****************************************************FSM TO LOAD & UPDATE GATE INFO**************************************************/
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state_info <= S0; counter_valid <= 32'd0; update_gate_info <= 1'd0;
		gate_type_norm <= 3'd0; gate_type_ahead <= 3'd0; gate_type_hold <= 3'd0;
		qubit_pos_norm <= 32'd0; qubit_pos2_norm <= 32'd0;  qubit_pos3_norm <= 32'd0;  
		qubit_pos_ahead <= 32'd0; qubit_pos2_ahead <= 32'd0;  qubit_pos3_ahead <= 32'd0;  
		phase_shift_index_norm <= {phase_lookup{1'd0}}; 
		phase_shift_index_ahead <= {phase_lookup{1'd0}}; 
	end
	else
	begin
		case(state_info)
			S0: //First gate: Load both current gate info directly from input (current info first valid clock, next info second valid clock)
			begin
				gate_type_norm <= gate_type; gate_type_ahead <= gate_type; gate_type_hold <= gate_type;
				qubit_pos_norm <= qubit_pos; qubit_pos2_norm <= qubit_pos2;  qubit_pos3_norm <= qubit_pos3;  
				qubit_pos_ahead <= qubit_pos; qubit_pos2_ahead <= qubit_pos2;  qubit_pos3_ahead <= qubit_pos3;  
				phase_shift_index_norm <= phase_shift_index; phase_shift_index_ahead <= phase_shift_index; 
				counter_valid <= 32'd0; update_gate_info <= 1'd0;
				if(valid_in)
				begin
					update_gate_info <= 1'd1;
					if(gate_type_norm > 3'd3) //Nonstabilizer:
					begin
						state_info <= S1; counter_valid <= 32'd1;
					end
					else //Stabilizer: 
					begin
						state_info <= S2; counter_valid <= 32'd1;
					end
				end				
				else
				begin
					state_info <= S0;
				end
			end
			S1: //Nonstabilizer Gates
			begin
				//Remain unchanged
				gate_type_norm <= gate_type_norm; phase_shift_index_norm <= phase_shift_index_norm; counter_valid <= counter_valid; update_gate_info <= 1'd0;
				qubit_pos_norm <= qubit_pos_norm; qubit_pos2_norm <= qubit_pos2_norm; qubit_pos3_norm <= qubit_pos3_norm;
				gate_type_ahead <= gate_type_ahead; qubit_pos_ahead <= qubit_pos_ahead; gate_type_hold <= gate_type_hold;
				phase_shift_index_ahead <= phase_shift_index_ahead; qubit_pos2_ahead <= qubit_pos2_ahead; qubit_pos3_ahead <= qubit_pos3_ahead;			
				counter_valid <= 0;
				if(valid_out_individual_cofactor) //Nonstabilizer: Load ahead gate info from external
				begin
					//Load gate info ahead: for ahead determination of basis_index list2 & productQ2 
					gate_type_ahead <= gate_type; phase_shift_index_ahead <= phase_shift_index; gate_type_hold <= gate_type_norm; 
					qubit_pos_ahead <= qubit_pos; qubit_pos2_ahead <= qubit_pos2; qubit_pos3_ahead <= qubit_pos3;
					state_info <= S3;
				end
				else
				begin
					state_info <= S1;
				end
							
			end
			S2: //Stabilizer gate: Assume next gate info is updated by second valid clock!!!
			begin
				gate_type_norm <= gate_type_norm; phase_shift_index_norm <= phase_shift_index_norm; counter_valid <= counter_valid; update_gate_info <= 1'd0;
				qubit_pos_norm <= qubit_pos_norm; qubit_pos2_norm <= qubit_pos2_norm; qubit_pos3_norm <= qubit_pos3_norm; gate_type_hold <= gate_type_hold;
				gate_type_ahead <= gate_type_ahead; qubit_pos_ahead <= qubit_pos_ahead; gate_type_hold <= gate_type_hold;
				phase_shift_index_ahead <= phase_shift_index_ahead; qubit_pos2_ahead <= qubit_pos2_ahead; qubit_pos3_ahead <= qubit_pos3_ahead;
				if(valid_in_stabilizer) //Stabilizer: Load ahead gate info from external
				begin
					counter_valid <= counter_valid + 1;
					if(counter_valid==num_qubit-1)
					begin
						state_info <= S3; 
						gate_type_ahead <= gate_type; phase_shift_index_ahead <= phase_shift_index;  gate_type_hold <= gate_type_norm;
						qubit_pos_ahead <= qubit_pos; qubit_pos2_ahead <= qubit_pos2; qubit_pos3_ahead <= qubit_pos3;
					end
					else
					begin
						state_info <= S2;
					end
				end
				else
				begin
					state_info <= S2;
				end
			end
			S3:
			begin
				gate_type_norm <= gate_type_norm; phase_shift_index_norm <= phase_shift_index_norm; counter_valid <= 32'd0; update_gate_info <= 1'd0;
				qubit_pos_norm <= qubit_pos_norm; qubit_pos2_norm <= qubit_pos2_norm; qubit_pos3_norm <= qubit_pos3_norm;
				gate_type_ahead <= gate_type_ahead; qubit_pos_ahead <= qubit_pos_ahead; gate_type_hold <= gate_type_hold;
				phase_shift_index_ahead <= phase_shift_index_ahead; qubit_pos2_ahead <= qubit_pos2_ahead; qubit_pos3_ahead <= qubit_pos3_ahead;
				if (valid_in_nonstabilizer) //Nonstabilizer:
				begin
					update_gate_info <= 1'd1;
					gate_type_norm <= gate_type_ahead; phase_shift_index_norm <= phase_shift_index_ahead; counter_valid <= 32'd1;
					qubit_pos_norm <= qubit_pos_ahead; qubit_pos2_norm <= qubit_pos2_ahead; qubit_pos3_norm <= qubit_pos3_ahead;
					state_info <= S1;
				end
				else if(valid_in_stabilizer) //Stabilizer:
				begin
					update_gate_info <= 1'd1;
					gate_type_norm <= gate_type_ahead; phase_shift_index_norm <= phase_shift_index_ahead; counter_valid <= 32'd1;
					qubit_pos_norm <= qubit_pos_ahead; qubit_pos2_norm <= qubit_pos2_ahead; qubit_pos3_norm <= qubit_pos3_ahead; 
					state_info <= S2;
				end
				else
				begin
					state_info <= S3;
				end
			end
		endcase
	end
end

//Signals to indicate first gate: stabilizer operation
reg [1:0] stateF;
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		stateF <= S0; 
	end
	else
	begin
		case(stateF)
			S0:
			begin
				if(valid_in_nonstabilizer || valid_in_stabilizer)
				begin
					stateF <= S1;
				end
				else
				begin
					stateF <= S0; 
				end
			end
			S1:
			begin
				if(valid_out_nonstabilizer || valid_out_stabilizer)
				begin
					stateF <= S2;
				end
				else
				begin
					stateF <= S1; 
				end
			end
			S2:
			begin
				stateF <= S2;
			end
			default:
			begin
				stateF <= S0; 
			end
		endcase
	end
end

assign first_gate = stateF==S0 || stateF==S1;

/**********************************************MANAGE LITERALS, PHASES, VALID SIGNALS************************************************/
reg [1:0] stateM; reg [31:0] counterM;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		stateM <= S0; counterM <= 0; valid_P_nonstabilizer <= 1'd0;
	end
	else
	begin
		case(stateM)
			S0: //First input
			begin
				valid_P_nonstabilizer <= 1'd0;
				if(valid_in)
				begin
					counterM <= counterM +1;
				end
				else
				begin
					counterM <= counterM;
				end
				if(counterM==num_qubit)
				begin
					counterM <= 0;	stateM <= S1; 
				end
				else
				begin
					stateM <= S0;
				end
			end
			S1: 
			begin
				stateM <= S1;  counterM <= counterM; valid_P_nonstabilizer <= 1'd0;
				//Generate valid P
				if(gate_type_ahead > 3'd3) //Nonstabilizer
				begin
					if(valid_out_nonstabilizer_buffer | valid_out_stabilizer)
					begin
						counterM <= counterM + 1;
					end
					else if(counterM == num_qubit)
					begin
						counterM <= 0; valid_P_nonstabilizer <= 1'd1;
					end
				end
			end
			default:
			begin
				stateM <= S0; counterM <= 0; valid_P_nonstabilizer <= 1'd0;
			end
		endcase
	end
end

always@(*)
begin
	case(stateM)
		S0:
		begin
			//Default for final output:
			literals_out <= literals_out_nonstabilizer; phase_out <= phase_out_nonstabilizer; valid_out <= 1'd0;
			literals_in_nonstabilizer <= literals_in; phase_in_nonstabilizer <= phase_in; 
			literals_in_stabilizer <= literals_in; phase_in_stabilizer <= phase_in; 
			//Input to stabilizer or nonstabilizer module
			if(gate_type_ahead > 3'd3) //Nonstabilizer gate
			begin
				valid_in_nonstabilizer <= valid_in; valid_in_stabilizer <= 1'd0;
			end
			else //Stabilizer gate
			begin
				valid_in_stabilizer <= valid_in; valid_in_nonstabilizer <= 1'd0;
			end
		end
		S1:
		begin
			/*Literals & Phases*/
			//Final output:
			if(valid_out_nonstabilizer) //Nonstabilizer -> Final Output
			begin
				literals_out <= literals_out_nonstabilizer; phase_out <= phase_out_nonstabilizer; 
			end
			else //Stabilizer -> Final Output 
			begin
				literals_out <= literals_out_stabilizer; phase_out <= phase_out_stabilizer; 
			end
			////Nonstabilizer input: Both nonstabilizer buffer & stabilizer output come from stabilizer operation module
			//Stabilizer input:
			if(valid_out_nonstabilizer) //Nonstabilizer -> Stabilizer/Nonstabilizer 
			begin
				literals_in_stabilizer <= literals_out_nonstabilizer; phase_in_stabilizer <= phase_out_nonstabilizer; 
				literals_in_nonstabilizer <= literals_out_nonstabilizer; phase_in_nonstabilizer <= phase_out_nonstabilizer;
			end
			else //Stabilizer -> Stabilizer/Nonstabilizer 
			begin
				literals_in_stabilizer <= literals_out_stabilizer; phase_in_stabilizer <= phase_out_stabilizer; 
				literals_in_nonstabilizer <= literals_out_stabilizer; phase_in_nonstabilizer <= phase_out_stabilizer;
			end
			/*Valid Signal*/
			if(final_gate)
			begin
				valid_out <= valid_out_nonstabilizer | valid_out_stabilizer;  
				valid_in_nonstabilizer <= 1'd0; valid_in_stabilizer <= 1'd0;
			end
			else if(gate_type_ahead > 3'd3) //Nonstabilizer gate: Stabilizer -> Nonstabilizer; Nonstabilizer -> Nonstabilizer (input: nonstabilizer buffer)
			begin
				valid_in_nonstabilizer <= valid_out_nonstabilizer | valid_out_stabilizer; 
				valid_out <= 1'd0; valid_in_stabilizer <= 1'd0;
			end 
			else //Stabilizer gate:  
			begin
				valid_in_stabilizer <= valid_out_nonstabilizer | valid_out_stabilizer; 
				valid_out <= 1'd0; valid_in_nonstabilizer <= 1'd0;
			end
		end
		default:
		begin
			//Default for final output:
			literals_out <= literals_out_nonstabilizer; phase_out <= phase_out_nonstabilizer; valid_out <= 1'd0;
			literals_in_nonstabilizer <= literals_in; phase_in_nonstabilizer <= phase_in; valid_in_nonstabilizer <= 1'd0;
			literals_in_stabilizer <= literals_in; phase_in_stabilizer <= phase_in; valid_in_stabilizer <= 1'd0;
		end
	endcase
end

/******************************************************P LITERALS & VALID SIGNALS******************************************************/
//For P literals: Temporary for verification purposes
always@(*)
begin
	if(valid_P_in) 
	begin
		literals_P <= literals_P_in;
	end
	else
	begin
		literals_P <= literals_P_canonical;
	end
end

endmodule 
