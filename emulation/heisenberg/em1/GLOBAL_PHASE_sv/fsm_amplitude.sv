module fsm_amplitude #(parameter num_qubit = 4)(
//General:
input clk, input rst_new,
//Input:
input determine_amplitude, input matchQ_index, input matchQ2_index, 
input [1:0] reg_literals_Q [0:num_qubit-1], input reg_phase_Q,
input [1:0] reg_literals_Q2 [0:num_qubit-1], input reg_phase_Q2,
//Output:
output reg done_amplitude, 
output reg ld_Q_loadP, output reg ld_Q_loadMultQ, output reg ld_Q_rotateLeft, output reg ld_Q2_loadP, 
output reg ld_Q2_loadMultQ, output reg ld_Q2_rotateLeft,
output reg signed [31:0] amplitude_r, output reg signed [31:0] amplitude_i, output reg signed [31:0] amplitude2_r, 
output reg signed [31:0] amplitude2_i
);

reg [31:0] count_amplitude;
reg state_amp; localparam  S0=1'd0, S1=1'd1;

//Extracted amplitude is only possible to be: +1; -1; +i; -i (four possible values & sum of them)
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		state_amp <= S0;
		amplitude_r <= 32'd1; amplitude_i <= 32'd0; amplitude2_r <= 32'd0; amplitude2_i <= 32'd0;
		count_amplitude <= num_qubit; done_amplitude <= 1'd0; 
	end
	else
	begin
		case (state_amp)
			S0:
			begin
				//Maintain the amplitude for the case of first gate
				amplitude_r <= amplitude_r; amplitude_i <= amplitude_i;
				amplitude2_r <= amplitude2_r; amplitude2_i <= amplitude2_i;				
				count_amplitude <= num_qubit; done_amplitude <= 1'd0; 
				if(determine_amplitude == 1'd1)
				begin
					count_amplitude <= count_amplitude - 32'd1;
					state_amp <= S1;
					//Determine amplitude based on i factor contributed by Y literal(s) in Q & phase sign
					if(reg_phase_Q == 1'd1) //Negative sign
					begin
						if(reg_literals_Q[0] == 2'd3) //Y literal: i
						begin
							amplitude_r <= 32'd0; amplitude_i <= -32'd1; //-i
						end
						else
						begin
							amplitude_r <= -32'd1; amplitude_i <= 32'd0; //-1
						end
					end
					else //Positive sign
					begin
						if(reg_literals_Q[0] == 2'd3) //Y literal: i
						begin
							amplitude_r <= 32'd0; amplitude_i <= 32'd1; //i
						end
						else
						begin
							amplitude_r <= 32'd1; amplitude_i <= 32'd0; //1
						end
					end
					//Determine amplitude2 based on i factor contributed by Y literal(s) in Q2 & phase sign
					if(reg_phase_Q2 == 1'd1) //Negative sign
					begin
						if(reg_literals_Q2[0] == 2'd3) //Y literal: i
						begin
							amplitude2_r <= 32'd0; amplitude2_i <= -32'd1; //-i
						end
						else
						begin
							amplitude2_r <= -32'd1; amplitude2_i <= 32'd0; //-1
						end
					end
					else //Positive sign
					begin
						if(reg_literals_Q2[0] == 2'd3) //Y literal: i
						begin
							amplitude2_r <= 32'd0; amplitude2_i <= 32'd1; //i
						end
						else
						begin
							amplitude2_r <= 32'd1; amplitude2_i <= 32'd0; //1
						end
					end
					//ROTATE LEFT Q		
				end
				else
				begin
					state_amp <= S0;
				end
			end
			S1:
			begin
				count_amplitude <= count_amplitude; done_amplitude <= 1'd0; 				
				//Default: Amplitudes remain unchanged 
				amplitude_r <= amplitude_r; amplitude_i <= amplitude_i;
				amplitude2_r <= amplitude2_r; amplitude2_i <= amplitude2_i;
				if(count_amplitude > 32'd0)
				begin
					state_amp <= S1;
					count_amplitude <= count_amplitude - 32'd1;	
					//ROTATE LEFT Q					
					//Determine amplitude based on i factor contributed by Y literal(s) in Q
					if(reg_literals_Q[0] == 2'd3) //Y literal: i
					begin
						//These cases should be mutually exclusive
						if(amplitude_r == 32'd1) //1*i = i
						begin
							amplitude_r <= 32'd0; amplitude_i <= 32'd1;
						end
						else if(amplitude_r == -32'd1) //-1*i = -i
						begin
							amplitude_r <= 32'd0; amplitude_i <= -32'd1;
						end
						else if(amplitude_i == 32'd1) //i*i = -1
						begin
							amplitude_r <= -32'd1; amplitude_i <= 32'd0;
						end
						else if(amplitude_i == -32'd1) //-i*i = 1 
						begin
							amplitude_r <= 32'd1; amplitude_i <= 32'd0;
						end						
					end
					//Determine amplitude2 based on i factor contributed by Y literal(s) in Q2
					if(reg_literals_Q2[0] == 2'd3) //Y literal: i
					begin
						//The cases should me mutually exclusive
						if(amplitude2_r == 32'd1)       //1*i = i
						begin
							amplitude2_r <= 32'd0; amplitude2_i <= 32'd1;
						end
						else if(amplitude2_r == -32'd1) //-1*i = -i
						begin
							amplitude2_r <= 32'd0; amplitude2_i <= -32'd1;
						end
						else if(amplitude2_i == 32'd1)  //i*i = -1
						begin
							amplitude2_r <= -32'd1; amplitude2_i <= 32'd0;
						end
						else if(amplitude2_i == -32'd1) //-i*i = 1 
						begin
							amplitude2_r <= 32'd1; amplitude2_i <= 32'd0;
						end						
					end
				end
				else //count_amplitude == 32'd0
				begin
					state_amp <= S0; done_amplitude <= 1'd1;
					if(matchQ_index == 1'd0)
					begin
						amplitude_r <= 32'd0; amplitude_i <= 32'd0; 
					end
					if(matchQ2_index == 1'd0)
					begin
						amplitude2_r <= 32'd0; amplitude2_i <= 32'd0;
					end
				end
			end
			default: //Same as reset
			begin
				state_amp <= S0;
				amplitude_r <= 32'd1; amplitude_i <= 32'd0; amplitude2_r <= 32'd0; amplitude2_i <= 32'd0;				
				count_amplitude <= num_qubit; done_amplitude <= 1'd0; 
			end
		endcase
	end
end

/*******************MEALY MODEL FOR CONTROL SIGNALS FOR LOADING REGISTERS & RELATED MULTIPLEXER(S)********************/
always@(*)
begin
	case(state_amp)
		S0:
		begin
			//Default:
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
			if(determine_amplitude == 1'd1)
			begin
				//ROTATE LEFT Q
				ld_Q_rotateLeft <= 1'd1; ld_Q2_rotateLeft <= 1'd1;
			end
		end
		S1:
		begin
			//Default:
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
			if(count_amplitude > 32'd0)
			begin
				//ROTATE LEFT Q
				ld_Q_rotateLeft <= 1'd1; ld_Q2_rotateLeft <= 1'd1;
			end
		end
		default:
		begin
			ld_Q_loadP <= 1'd0; ld_Q_loadMultQ <= 1'd0; ld_Q_rotateLeft <= 1'd0; ld_Q2_loadP <= 1'd0; 
			ld_Q2_loadMultQ <= 1'd0; ld_Q2_rotateLeft <= 1'd0;
		end
	endcase
end
	
endmodule
