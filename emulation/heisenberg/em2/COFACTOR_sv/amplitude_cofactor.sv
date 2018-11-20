module amplitude_cofactor #(parameter num_qubit = 4, max_vector = 2**num_qubit)( //Used to determine both alpha & beta
//General:
input clk, input rst_new,
//Input:
input determine_amplitude_nonstabilizer, input determine_amplitude_alpha, input determine_amplitude_beta, input determine_amplitude_stabilizer,
input [1:0] literals_in_Q1 [0:max_vector-1][0:num_qubit-1], input phase_in_Q1 [0:max_vector-1], input final_cofactor,
input [1:0] literals_in_Q2 [0:2**num_qubit-1][0:num_qubit-1], input phase_in_Q2 [0:2**num_qubit-1], input determine_amplitude2,
//Add in for handshaking:
input valid_out, input [31:0] counter_valid_vector, output done_alpha, 
//Output:
//Rotate left (literals only) shared for both P & Q
output reg done_amplitude, output ld_rotateLeft, output ld_rotateLeft_PQ_list, output ld_rotateLeft_Q2,
//Extracted amplitude is only possible to be: +1; -1; +i; -i (four possible values & sum of them & 0)
output signed [1:0] amplitude_r_Q_out, output signed [1:0] amplitude_i_Q_out,
output write_alpha_enable, output [num_qubit-1:0] write_alpha_address, output ready_cofactor, output fsm_amplitude_busy,
//For stabilizer alpha operation:
input [2:0] gate_type_ahead, output write_amplitude1_enable, output [7:0] write_amplitude1
);

integer i;
reg [31:0] count_amplitude; reg [31:0] counter_valid_ori; 
reg signed [1:0] amplitude_r_Q [0:max_vector-1]; reg signed [1:0] amplitude_i_Q [0:max_vector-1];
wire determine_amplitude;
reg [1:0] state_amp; 
localparam  S0=2'd0, S1=2'd1, S2=2'd2, S3=2'd3;
reg [1:0] stateA;
localparam SA0 = 2'd0, SA1 = 2'd1,  SA2 = 2'd2, SA3 = 2'd3;

wire select2; reg [1:0] literals_in_Q [0:max_vector-1][0:num_qubit-1]; reg phase_in_Q [0:max_vector-1]; reg ld_rotateLeft_pre;
always@(*)
begin
	if(select2)
	begin
		literals_in_Q <= literals_in_Q2; phase_in_Q <= phase_in_Q2;
	end
	else
	begin
		literals_in_Q <= literals_in_Q1; phase_in_Q <= phase_in_Q1;
	end
end 

assign determine_amplitude = determine_amplitude_nonstabilizer | determine_amplitude2 | determine_amplitude_stabilizer;
assign ld_rotateLeft_Q2 = ld_rotateLeft_pre && select2;
assign ld_rotateLeft = ld_rotateLeft_pre && !select2;
assign fsm_amplitude_busy = state_amp==S2;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		state_amp <= S0;
		count_amplitude <= 32'd0; done_amplitude <= 1'd0; counter_valid_ori <= 32'd0;
		for (i=0; i<max_vector; i=i+1)
		begin
			amplitude_r_Q[i] <= 2'd1; amplitude_i_Q[i] <= 2'd0;
		end
	end
	else
	begin
		case (state_amp)
			S0:
			begin
				//Maintain the amplitude for the case of first gate	
				amplitude_r_Q <= amplitude_r_Q; amplitude_i_Q <= amplitude_i_Q; counter_valid_ori <= counter_valid_ori;
				count_amplitude <= 32'd0; done_amplitude <= 1'd0; 
				if(determine_amplitude == 1'd1)
				begin
					count_amplitude <= 32'd1; counter_valid_ori <= counter_valid_vector;
					state_amp <= S1;
					for (i=0; i<max_vector; i=i+1)
					begin
						//For Q: Determine amplitude based on i factor contributed by Y literal(s) in Q & phase sign
						if(phase_in_Q[i] == 1'd1)           //Negative sign
						begin
							if(literals_in_Q[i][0] == 2'd3) //Y literal: i
							begin
								amplitude_r_Q[i] <= 2'd0; amplitude_i_Q[i] <= -2'd1; //-i
							end
							else
							begin
								amplitude_r_Q[i] <= -2'd1; amplitude_i_Q[i] <= 2'd0; //-1
							end
						end
						else //Positive sign
						begin
							if(literals_in_Q[i][0] == 2'd3) //Y literal: i
							begin
								amplitude_r_Q[i] <= 2'd0; amplitude_i_Q[i] <= 2'd1; //i
							end
							else
							begin
								amplitude_r_Q[i] <= 2'd1; amplitude_i_Q[i] <= 2'd0; //1
							end
						end
					end
				end
				else
				begin
					state_amp <= S0;
				end
			end
			S1:
			begin
				count_amplitude <= count_amplitude; done_amplitude <= 1'd0; counter_valid_ori <= counter_valid_ori; 				
				for (i=0; i<max_vector; i=i+1)
				begin
					//ROTATE LEFT Q					
					//Determine amplitude based on i factor contributed by Y literal(s) in Q
					if(literals_in_Q[i][0] == 2'd3)         //Y literal: i
					begin
						//These cases should be mutually exclusive
						if(amplitude_r_Q[i] == 2'd1)        //1*i = i
						begin
							amplitude_r_Q[i] <= 2'd0; amplitude_i_Q[i] <= 2'd1;
						end
						else if(amplitude_r_Q[i] == -2'd1)  //-1*i = -i
						begin   
							amplitude_r_Q[i] <= 2'd0; amplitude_i_Q[i] <= -2'd1;
						end
						else if(amplitude_i_Q[i] == 2'd1)   //i*i = -1
						begin
							amplitude_r_Q[i] <= -2'd1; amplitude_i_Q[i] <= 2'd0;
						end
						else if(amplitude_i_Q[i] == -2'd1)  //-i*i = 1 
						begin
							amplitude_r_Q[i] <= 2'd1; amplitude_i_Q[i] <= 2'd0;
						end						
					end
				end
				if(count_amplitude == num_qubit-1) 
				begin
					state_amp <= S2; done_amplitude <= 1'd1; count_amplitude <= 32'd0;
				end
				else 
				begin
					state_amp <= S1; count_amplitude <= count_amplitude + 32'd1;	
				end
			end
			S2: //Rotate amplitude registers to fill alpha into memory one by one
			begin
				done_amplitude <= 1'd0; counter_valid_ori <= counter_valid_ori; 
				if (count_amplitude == counter_valid_ori-1)
				begin
					count_amplitude <= 32'd0;
					if(stateA == SA1) //nonstabilizer cofactor alpha
					begin
						state_amp <= S3;
					end
					else
					begin
						state_amp <= S0;	
					end	
				end
				else
				begin
					state_amp <= S2;
					count_amplitude <= count_amplitude + 1;
				end
				//Rotate left		
				amplitude_r_Q[max_vector-1] <= amplitude_r_Q[0]; amplitude_i_Q[max_vector-1] <= amplitude_i_Q[0];
				for (i=0; i<max_vector-1; i=i+1)
				begin	
					amplitude_r_Q[i] <= amplitude_r_Q[i+1]; amplitude_i_Q [i] <= amplitude_i_Q[i+1];
				end
			end
			S3: //Hold done_alpha signal until all operations for alpha determination is completed. valid_out is asserted
			begin
				count_amplitude <= count_amplitude; done_amplitude <= 1'd0; amplitude_r_Q <= amplitude_r_Q; amplitude_i_Q <= amplitude_i_Q; 
				counter_valid_ori <= counter_valid_ori;
				if(valid_out)
				begin
					state_amp <= S0;	
				end
				else
				begin
					state_amp <= S3;	
				end
			end
			default: //Same as reset
			begin
				state_amp <= S0;		
				count_amplitude <= num_qubit; done_amplitude <= 1'd0; 
				for (i=0; i<max_vector; i=i+1)
				begin
					amplitude_r_Q[i] <= 2'd1; amplitude_i_Q[i] <= 2'd0;
				end
			end
		endcase
	end
end

assign ld_rotateLeft_PQ_list = (state_amp==S2 && !select2)? 1'd1: 1'd0; 

/************************MEALY MODEL FOR CONTROL SIGNALS FOR LOADING REGISTERS & RELATED MULTIPLEXER(S)*************************/
always@(*)
begin
	case(state_amp)
		S0:
		begin
			//Default:
			ld_rotateLeft_pre <= 1'd0; 
			if(determine_amplitude == 1'd1)
			begin
				//ROTATE LEFT P & Q
				ld_rotateLeft_pre <= 1'd1; 
			end
		end
		S1:
		begin
			ld_rotateLeft_pre <= 1'd1;
		end
		S2:
		begin
			ld_rotateLeft_pre <= 1'd0; 
		end
		S3:
		begin
			ld_rotateLeft_pre <= 1'd0; 
		end
		default:
		begin
			ld_rotateLeft_pre <= 1'd0; 
		end
	endcase
end

/*******************************************ASSIGN OUTPUT FOR USAGE IN OUTER MODULE*********************************************/
assign amplitude_r_Q_out = amplitude_r_Q[0]; assign amplitude_i_Q_out = amplitude_i_Q[0];	

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		stateA <= SA0;
	end
	else
	begin
		case(stateA)
			SA0:
			begin
				if(determine_amplitude_alpha)
				begin
					stateA <= SA1;
				end
				else if (determine_amplitude_beta || determine_amplitude_stabilizer)   
				begin
					stateA <= SA2;
				end
				else
				begin
					stateA <= SA0;
				end
			end
			SA1:    //Alpha
			begin
				if(valid_out)
				begin
					stateA <= SA0;
				end
				else
				begin
					stateA <= SA1;
				end
			end
			SA2:    //Beta
			begin
				if(valid_out)
				begin
					if(state_amp==S1 || state_amp==S2)
					begin
						stateA <= SA3;
					end
					else
					begin
						stateA <= SA0;
					end
				end
				else
				begin
					stateA <= SA2;
				end
			end
			SA3:    //Beta: For the case where valid_out signal comes earlier that writing to memory
			begin
				if(state_amp==S1 || state_amp==S2)
				begin
					stateA <= SA3;
				end
				else
				begin
					stateA <= SA0;
				end
			end
			default:
			begin
				stateA <= SA0;
			end
		endcase
	end
end

wire write_alpha_enable_pre;
assign write_alpha_enable_pre = (state_amp == S2 && count_amplitude < counter_valid_ori);
 
assign write_alpha_enable = (write_alpha_enable_pre && stateA == SA1) ? 1'd1: 1'd0;
assign write_alpha_address = count_amplitude[num_qubit-1:0];
assign done_alpha = (((state_amp == S2 && count_amplitude >= counter_valid_ori) || state_amp == S3) && stateA == SA1) ? 1'd1: 1'd0;
assign ready_cofactor = (state_amp == S0 || state_amp == S3)? 1'd1: 1'd0; //S0 is for the case of deterministic outcome

//Write amplitude of final beta to RAM ALPHA for the potential usage if the following gate is stabilizer gate (0: Hadamard, 1: Phase, 2:CNOT)

//From nonstabilizer: Next stabilizer gate, final cofactor beta
//From stabilizer: Next stabilizer gate, beta
assign write_amplitude1_enable = (write_alpha_enable_pre & (stateA == SA2 || stateA == SA3));  
assign write_amplitude1 = {4'd0, amplitude_r_Q_out, amplitude_i_Q_out};

/*****************************************DETERMINE AMPLITUDE2 FOR THE CASE OF HADAMARD GATE******************************************/
reg [1:0] state2;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		state2 <= S0;
	end
	else
	begin
		case(state2)
			S0:
			begin
				if(determine_amplitude2)
				begin
					state2 <= S1;
				end
				else
				begin
					state2 <= S0;
				end
			end
			S1:
			begin
				if(done_amplitude)
				begin
					state2 <= S0;
				end
				else
				begin
					state2 <= S1;
				end
			end
			default:
			begin
				state2 <= S0;
			end
		endcase
	end
end

assign select2 = (state2==S1) || determine_amplitude2;

endmodule
