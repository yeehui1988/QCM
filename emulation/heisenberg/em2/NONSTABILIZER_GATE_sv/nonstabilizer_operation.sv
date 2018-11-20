module nonstabilizer_operation #(parameter num_qubit = 4, complex_bit = 24, fp_bit = 22, phase_lookup = 5)(
input clk, input rst,
//Input literals for stabilizer gates should not be sent here. Assume valid_in signal has been filtered
//4: Controlled Phase-Shift; 5: Toffoli 
input [2:0] gate_type, input [phase_lookup-1:0] phase_shift_index, //For controlled phase-shift gate only
//For Hadamard & Phase: qubit_pos is the target qubit
//For CNOT & Controlled Phase-Shift: qubit_pos is the control qubit, qubit_pos2 is the target qubit
//For Toffoli: qubit pos & qubit_pos1 are the control qubits, qubit_pos2 is the target qubit  
input [31:0] qubit_pos, input [31:0] qubit_pos2, input [31:0] qubit_pos3, 
input [1:0] literals_in [0:num_qubit-1], input phase_in [0:2**num_qubit-1], input valid_in, 
input [1:0] literals_out_individual_cofactor [0:num_qubit-1], input phase_out_individual_cofactor [0:2**num_qubit-1], input valid_out_individual_cofactor,
output reg [1:0] literals_in_individual_cofactor [0:num_qubit-1], output reg  phase_in_individual_cofactor [0:2**num_qubit-1], output reg valid_in_individual_cofactor,
output reg [1:0] literals_out [0:num_qubit-1], output reg phase_out [0:2**num_qubit-1], output reg valid_out,
output reg [31:0] cofactor_pos, output final_cofactor, output reg flag_cofactor [0:num_qubit-1], output phaseShift_toffoli,
//For Toffoli: Feed canonical to ensure correct P literals are updated
input [1:0] literals_out_canonical [0:num_qubit-1], input phase_out_canonical [0:2**num_qubit-1], input valid_out_canonical,
output [1:0] literals_in_canonical_for_toffoli [0:num_qubit-1], output phase_in_canonical_for_toffoli [0:2**num_qubit-1], output valid_in_canonical_for_toffoli,
//For controlled phase-shift update
input [complex_bit-1:0] ram_amplitude_out_r, input [complex_bit-1:0] ram_amplitude_out_i, input done_flag_nonstabilizer_update,
output [num_qubit-1:0] ram_amplitude_nonstabilizer_readout_address, output ram_amplitude_nonstabilizer_readout_en, output rotateLeft_flag_nonstabilizer_update,
output reg ram_amplitude_nonstabilizer_writein_en, output reg [num_qubit-1:0] ram_amplitude_nonstabilizer_writein_address, input [31:0] counter_valid_vector,  
output reg [2*complex_bit-1:0] ram_amplitude_nonstabilizer_writein, input updating_beta, input flag_nonstabilizer_update0,
//Buffer input from register array stabilizer:
input valid_out_buffer, input [1:0] literals_out_stabilizer [0:num_qubit-1], input phase_out_stabilizer [0:2**num_qubit-1], output mask_valid_buffer 
);

//ADD IN PIPELINE REGISTER TO REDUCE OVERALL CPD
reg ram_amplitude_nonstabilizer_writein_en_pre; reg [num_qubit-1:0] ram_amplitude_nonstabilizer_writein_address_pre;
reg [2*complex_bit-1:0] ram_amplitude_nonstabilizer_writein_pre;

//output valid_P_nonstabilizer, 

integer i, j; reg [2:0] state; reg [31:0] counter;
localparam [2:0] S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4, S5 = 3'd5, S6 = 3'd6, S7 = 3'd7;
//reg [1:0] literal_buffer [0:num_qubit-1][0:num_qubit-1];		//[row][column]
//reg phase_buffer [0:num_qubit-1][0:2**num_qubit-1]; 			//[row_index][pair_index] 
//reg modified_valid_buffer;
//0: Toffoli; 1: Controlled Phase Shift
assign phaseShift_toffoli = (state == S1 || state == S2)? 1'd1 : 1'd0;

always@(posedge rst or posedge clk)
begin
	if(rst)
	begin
		state <= S0; counter <= 0;
	end
	else
	begin
		case(state)
			S0:
			begin
				if(valid_in)
				begin
					counter <= counter + 1;
				end
				else
				begin
					counter <= counter;
				end
				if(counter == num_qubit) //Gate info supposed to be maintained at this instant
				begin
					if(gate_type == 3'd4) //Controlled Phase-Shift
					begin
						state <= S1; counter <= 0;
					end
					else if(gate_type == 3'd5) //Toffoli
					begin
						state <= S3; counter <= 0;
					end
					else //Shouldn't come here. Assume valid_in signal for stabilizer gates has been filtered
					begin
						state <= S0;
					end
				end
				else
				begin
					state <= S0;
				end
			end
			//Controlled Phase-Shift: cofactor qubit_pos (control qubit)
			S1: 
			begin
				if (valid_out_individual_cofactor)
				begin
					counter <= counter + 1;
				end
				else
				begin
					counter <= counter;
				end
				if(counter == num_qubit)
				begin
					state <= S2;
					counter <= 0;
				end
				else
				begin
					state <= S1;
				end
			end
			//Controlled Phase-Shift: cofactor qubit_pos2 (target qubit)
			S2: 
			begin
				if (valid_out_individual_cofactor)
				begin
					counter <= counter + 1;
				end
				else
				begin
					counter <= counter;
				end
				if(counter == num_qubit)
				begin
					state <= S0;
					counter <= 0;
				end
				else
				begin
					state <= S2;
				end
			end
			S3: //Toffoli: cofactor qubit_pos (control qubit)
			begin
				if (valid_out_individual_cofactor)
				begin
					counter <= counter + 1;
				end
				else
				begin
					counter <= counter;
				end
				if(counter == num_qubit)
				begin
					state <= S4;
					counter <= 0;
				end
				else
				begin
					state <= S3;
				end
			end
			S4: //Toffoli: cofactor qubit_pos2 (control qubit)
			begin
				if (valid_out_individual_cofactor)
				begin
					counter <= counter + 1;
				end
				else
				begin
					counter <= counter;
				end
				if(counter == num_qubit)
				begin
					state <= S5;
					counter <= 0;
				end
				else
				begin
					state <= S4;
				end
			end
			//Toffoli: cofactor qubit_pos3 (target qubit)
			S5: 
			begin
				if (valid_out_individual_cofactor)
				begin
					counter <= counter + 1;
				end
				else
				begin
					counter <= counter;
				end
				if(counter == num_qubit)
				begin
					state <= S6;//S0;
					counter <= 0;
				end
				else
				begin
					state <= S5;
				end
			end
			//Toffoli: After cofactor & phase update for Toffoli operation. P literals should be updated accordingly
			//Current approach: Feed output literals & phases from cofactor to canonical module.
			S6: 
			begin
				if(valid_out_canonical)
				begin
					counter <= counter + 1;
				end
				else
				begin
					counter <= counter;
				end
				if(counter == num_qubit)
				begin
					//state <= S0;
					//counter <= 0;
					if(gate_type == 3'd4)       //Controlled Phase-Shift
					begin
						state <= S1; counter <= 0;
					end
					else if(gate_type == 3'd5)  //Toffoli
					begin
						state <= S3; counter <= 0;
					end
					else 
					begin
						state <= S0; counter <= 0;
					end
				end
				else
				begin
					state <= S6;
				end
			end
			default:
			begin
				state <= S0; counter <= 0;
			end	
		endcase
	end
end

assign final_cofactor = (state == S2 || state == S5)? 1'd1: 1'd0;

//For canonical reduction to update P after toffoli operation
assign literals_in_canonical_for_toffoli = literals_out_individual_cofactor;
assign phase_in_canonical_for_toffoli = phase_out_individual_cofactor;
assign valid_in_canonical_for_toffoli = (state==S5 & valid_out_individual_cofactor)? 1'd1: 1'd0;

//Select output of the overall nonstabilizer gate operation module
//For consequtive nonstabilizer gate operation, literals & phase has to go through buffer first
always@(*)
begin
	i=0;
	if(state==S2)       //Output for controlled phase shift
	begin
		valid_out <= valid_out_individual_cofactor;
		literals_out <= literals_out_individual_cofactor; phase_out <= phase_out_individual_cofactor;
	end
	else if(state==S6)  //Output for Toffoli
	begin
		valid_out <= valid_out_canonical; literals_out <= literals_out_canonical; phase_out <= phase_out_canonical;
	end
	else
	begin
		valid_out <= 1'd0; 
		for(i=0;i<num_qubit;i=i+1)
		begin
			literals_out[i] <= 2'd0;
		end
		for(i=0;i<2**num_qubit;i=i+1)
		begin
			phase_out[i] <= 1'd0;
		end
	end	
end

//Select output for cofactor pos
always@(*)
begin
	if(state == S0 || state == S1 || state == S3 || state == S6)
	begin
		cofactor_pos <= qubit_pos;
	end
	else if(state == S2 || state == S4)
	begin
		cofactor_pos <= qubit_pos2;
	end
	else if (state == S5)
	begin
		cofactor_pos <= qubit_pos3;
	end
	else //Default:
	begin
		cofactor_pos <= 0;
	end
end

//Select input to cofactor module
always@(*)
begin
	case(state)
		S0: //Take input from external
		begin
			literals_in_individual_cofactor <= literals_in; phase_in_individual_cofactor <= phase_in; valid_in_individual_cofactor <= valid_in;
		end
		S1:
		begin
			literals_in_individual_cofactor <= literals_out_stabilizer; phase_in_individual_cofactor <= phase_out_stabilizer; 
			valid_in_individual_cofactor <= valid_out_buffer;
		end
		S2:
		begin
			literals_in_individual_cofactor <= literals_out_stabilizer; phase_in_individual_cofactor <= phase_out_stabilizer; 
			valid_in_individual_cofactor <= valid_out_buffer; 
		end
		S3:
		begin
			literals_in_individual_cofactor <= literals_out_stabilizer; phase_in_individual_cofactor <= phase_out_stabilizer; 
			valid_in_individual_cofactor <= valid_out_buffer;
		end
		S4:
		begin
			literals_in_individual_cofactor <= literals_out_stabilizer; phase_in_individual_cofactor <= phase_out_stabilizer; 
			valid_in_individual_cofactor <= valid_out_buffer; 
		end
		S5:
		begin
			literals_in_individual_cofactor <= literals_out_stabilizer; phase_in_individual_cofactor <= phase_out_stabilizer; 
			valid_in_individual_cofactor <= valid_out_buffer;
		end
		S6:         //Take input from external
		begin
			literals_in_individual_cofactor <= literals_in; phase_in_individual_cofactor <= phase_in; valid_in_individual_cofactor <= valid_in;
		end
		default:    //No taking input
		begin
			literals_in_individual_cofactor <= literals_in; phase_in_individual_cofactor <= phase_in; valid_in_individual_cofactor <= 1'd0;
		end
	endcase
end

assign mask_valid_buffer = (state == S1 || state == S2 || state == S3 || state == S4 || state == S5)? 1'd1 : 1'd0;

//Flag cofactored qubit position for checking for nonstabilizer gate operation
reg [1:0] state_flag;
localparam [1:0] SB0 = 2'd0, SB1 = 2'd1, SB2 = 2'd2, SB3 = 2'd3;
reg [31:0] counter_flag; wire select_flag_cofactor;

//Flag (a) Control & target qubit for controlled phase-shift, (b) Two control qubits for Toffoli. 
assign select_flag_cofactor = (counter_flag == qubit_pos || counter_flag == qubit_pos2)? 1'd1: 1'd0; 

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state_flag <= SB0; counter_flag <= 32'd0;
		for (i=0;i<num_qubit;i=i+1)
		begin
			flag_cofactor [i] <= 1'd0;
		end
	end
	else
	begin
		case(state_flag)
			SB0:
			begin
				counter_flag <= 32'd0; flag_cofactor <= flag_cofactor;
				if((state == S0 || state == S6) && valid_in) //new nonstabilizer gate  MODIFIED HERE 16Nov
				begin
					state_flag <= SB1;
				end
				else
				begin
					state_flag <= SB0;
				end
			end
			SB1:
			begin
				counter_flag <= counter_flag + 1;
				//Rotate left
				flag_cofactor [num_qubit-1] <= select_flag_cofactor;
				for(i=0;i<num_qubit-1;i=i+1)
				begin
					flag_cofactor[i] <= flag_cofactor[i+1];
				end
				if(counter_flag == num_qubit-1)
				begin
					state_flag <= SB2; counter_flag <= 0;
				end
				else
				begin
					state_flag <= SB1;
				end
			end
			SB2:
			begin
				flag_cofactor <= flag_cofactor; counter_flag <= 0;
				if ((counter == num_qubit && state == S2) || (counter == num_qubit && state == S5))
				begin
					state_flag <= SB0;
				end
				else
				begin
					state_flag <= SB2;
				end
			end
			default:
			begin
				state_flag <= SB0; counter_flag <= 32'd0;
				for (i=0;i<num_qubit;i=i+1)
				begin
					flag_cofactor [i] <= 1'd0;
				end
			end	
		endcase
	end
end

/***************************************************FOR CONTROLLED PHASE SHIFT********************************************************/
//Controlled Phase-Shift:
//Update of global with phase shift fixed point constant to be done after all necessary cofactor
//Use lookup table ROM: up to R(33) as the value remain the same after that
//ROM address is offset by 2, start from R(2)

reg [1:0] state_phase; reg [31:0] counter_phase;
reg [complex_bit-1:0] ram_amplitude_nonstabilizer_writein_r; reg [complex_bit-1:0] ram_amplitude_nonstabilizer_writein_i;
wire [complex_bit-1:0] phase_mult_r; wire [complex_bit-1:0] phase_mult_i;
wire [complex_bit-1:0] phase_shift_r; wire [complex_bit-1:0] phase_shift_i;
reg [phase_lookup-1:0] reg_phase_shift_index_offset; reg reg_select_nonstabilizer; reg reg_ram_amplitude_nonstabilizer_readout_en;
wire [31:0] constant_sub; assign constant_sub = 32'd2; reg reg_flag_nonstabilizer_update0;
reg [complex_bit-1:0] reg_ram_amplitude_out_r; reg [complex_bit-1:0] reg_ram_amplitude_out_i;
reg reg_ram_amplitude_nonstabilizer_writein_en_pre; reg [num_qubit-1:0] reg_ram_amplitude_nonstabilizer_writein_address_pre;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		reg_ram_amplitude_nonstabilizer_readout_en <= 1'd0; 
		reg_flag_nonstabilizer_update0 <= 1'd0;
		reg_ram_amplitude_out_r <= {complex_bit{1'b0}}; reg_ram_amplitude_out_i <= {complex_bit{1'b0}};
		for(i=0;i<num_qubit;i=i+1)
		begin
			ram_amplitude_nonstabilizer_writein_address[i] <= 1'd0;
			ram_amplitude_nonstabilizer_writein_address_pre[i] <= 1'd0;
			reg_ram_amplitude_nonstabilizer_writein_address_pre[i] <= 1'd0;
		end
		for(i=0;i<phase_lookup;i=i+1)
		begin
			reg_phase_shift_index_offset[i] <= 1'd0;
		end
		ram_amplitude_nonstabilizer_writein_en <= 1'd0;
		reg_ram_amplitude_nonstabilizer_writein_en_pre <= 1'd0;
		for(i=0;i<2*complex_bit;i=i+1)
		begin
			ram_amplitude_nonstabilizer_writein [i] <= 1'd0;
		end
	end
	else
	begin
		i=0;
		if(state == S1 && counter != 0)	//if((state == S0 || state == S6) & valid_in)
		begin
			reg_phase_shift_index_offset <= phase_shift_index - constant_sub[phase_lookup-1:0]; //offset 2
		end
		else
		begin
			reg_phase_shift_index_offset <= reg_phase_shift_index_offset; 
		end
		reg_ram_amplitude_nonstabilizer_readout_en <= ram_amplitude_nonstabilizer_readout_en;
		ram_amplitude_nonstabilizer_writein_address_pre <= ram_amplitude_nonstabilizer_readout_address;
		reg_ram_amplitude_nonstabilizer_writein_address_pre <= ram_amplitude_nonstabilizer_writein_address_pre;
		ram_amplitude_nonstabilizer_writein_address <= reg_ram_amplitude_nonstabilizer_writein_address_pre;
		reg_flag_nonstabilizer_update0 <= flag_nonstabilizer_update0;
		reg_ram_amplitude_nonstabilizer_writein_en_pre <= ram_amplitude_nonstabilizer_writein_en_pre;
		ram_amplitude_nonstabilizer_writein_en <= reg_ram_amplitude_nonstabilizer_writein_en_pre;
		ram_amplitude_nonstabilizer_writein <= ram_amplitude_nonstabilizer_writein_pre;
		reg_ram_amplitude_out_r <= ram_amplitude_out_r; reg_ram_amplitude_out_i <= ram_amplitude_out_i;
	end
end 

//For real part:
phase_real_rom phase_r_lookup (.clk(clk), .addr(reg_phase_shift_index_offset[phase_lookup-1:0]), .q(phase_shift_r));
defparam phase_r_lookup.DATA_WIDTH = complex_bit; defparam phase_r_lookup.ADDR_WIDTH = phase_lookup; 

//For imaginary part:
phase_imag_rom phase_i_lookup (.clk(clk), .addr(reg_phase_shift_index_offset[phase_lookup-1:0]), .q(phase_shift_i));
defparam phase_i_lookup.DATA_WIDTH = complex_bit; defparam phase_i_lookup.ADDR_WIDTH = phase_lookup; 

//Complex number multiplication:

complex_mult complex_multiplication (.in_r1(phase_shift_r), .in_i1(phase_shift_i), .in_r2(reg_ram_amplitude_out_r), .in_i2(reg_ram_amplitude_out_i), 
.out_r(phase_mult_r), .out_i(phase_mult_i));
defparam complex_multiplication.complex_bit = complex_bit; defparam complex_multiplication.fp_bit = fp_bit;

assign ram_amplitude_nonstabilizer_writein_pre = {ram_amplitude_nonstabilizer_writein_r, ram_amplitude_nonstabilizer_writein_i};
assign ram_amplitude_nonstabilizer_readout_en = ((state_phase==SB2 && updating_beta==0) || (state_phase==SB3))? 1'd1: 1'd0;
assign ram_amplitude_nonstabilizer_readout_address = counter_phase[num_qubit-1:0]; 
assign rotateLeft_flag_nonstabilizer_update = ram_amplitude_nonstabilizer_readout_en;
assign ram_amplitude_nonstabilizer_writein_r = phase_mult_r; assign ram_amplitude_nonstabilizer_writein_i = phase_mult_i;
assign ram_amplitude_nonstabilizer_writein_en_pre = (reg_ram_amplitude_nonstabilizer_readout_en && reg_flag_nonstabilizer_update0)? 1'd1:1'd0;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state_phase <= SB0; counter_phase <= 0;
	end
	else
	begin
		case(state_phase)
			SB0:
			begin
				counter_phase <= 0;
				if(state==S1 && valid_out_individual_cofactor)  //Phase shift cofactor target qubit
				begin
					state_phase <= SB1; 
				end
				else
				begin
					state_phase <= SB0;
				end
			end
			SB1:
			begin
				counter_phase <= 0;
				if(done_flag_nonstabilizer_update)              //Done updating flag nonstabilizer
				begin
					state_phase <= SB2; 
				end
				else
				begin
					state_phase <= SB1;
				end
			end
			SB2:
			begin
				counter_phase <= 0;
				if(updating_beta==0) //Make sure beta update for the last cofactor is completed
				begin
					state_phase <= SB3; counter_phase <= counter_phase + 1;
				end
				else
				begin
					state_phase <= SB2;
				end
			end
			SB3:
			begin
				if(counter_phase == counter_valid_vector-1)
				begin
					state_phase <= SB0; counter_phase <= 0;
				end
				else
				begin
					state_phase <= SB3; counter_phase <= counter_phase + 1;
				end
			end
		endcase
	end
end

endmodule 
