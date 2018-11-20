module fsm_alpha #(parameter num_qubit = 4)(
//General:
input clk, input rst_new,
//Input:
input determine_alpha, input [1:0] reg_gate_type, input basis_index [0:num_qubit-1], input [31:0] reg_qubit_pos, 
input signed [31:0] amplitude_r, input signed [31:0] amplitude_i, 
input signed [31:0] amplitude2_r, input signed [31:0] amplitude2_i,
//Output:
output reg signed [31:0] alpha_r, output reg signed [31:0] alpha_i, output reg initial_alpha_zero, output reg done_alpha
);

localparam  S0=2'd0, S1=2'd1, S2=2'd2, S3=2'd3;
reg [1:0] state_alpha; 

//For Hadamard:
//if temp is even: 
//basis_index2 = basis_index + temp_const
//alpha = 0.707107 * (amplitude + amplitude2)
//**if obtained alpha is 0, update basis_index = basis_index2 and alpha = 0.707107 * (amplitude - amplitude2)
//else temp is odd:
//basis_index2 = basis_index - temp_const
//alpha = 0.707107 * (amplitude2 - amplitude)
//**if obtained alpha is 0, update basis_index = basis_index2 and alpha = 0.707107 * (amplitude + amplitude2)

//For Phase:
//if temp is even, alpha = basis_amplitude
//else temp is odd, alpha = basis_amplitude * i

//For CNOT:
//Update basis_index based on CNOT gate operation. No update on amplitude is required

always@(posedge clk or posedge rst_new)
begin 
	if(rst_new)
	begin
		state_alpha <= S0; done_alpha <= 1'd0; initial_alpha_zero <= 1'd0; alpha_r <= 32'd0; alpha_i <= 32'd0; 
	end
	else
	begin
		case(state_alpha)
			S0: //Idle waiting state
			begin
				alpha_r <= alpha_r; alpha_i <= alpha_i; done_alpha <= 1'd0; initial_alpha_zero <= initial_alpha_zero; 
				state_alpha <= S0;
				if(determine_alpha)
				begin
					if(reg_gate_type == 2'd0)           //Hadamard
					begin
						state_alpha <= S1;
						if(basis_index[reg_qubit_pos]==1'd0)    //Even: amplitude + amplitude2
						begin
							alpha_r <= amplitude_r + amplitude2_r; alpha_i <= amplitude_i + amplitude2_i;
						end
						else                                    //Odd: amplitude2 - amplitude 
						begin
							alpha_r <= amplitude2_r - amplitude_r; alpha_i <= amplitude2_i - amplitude_i;
						end
					end
					else if(reg_gate_type == 2'd1)      //Phase
					begin
						state_alpha <= S2;
						if(basis_index[reg_qubit_pos]==1'd0)    //Even: amplitude
						begin
							alpha_r <= amplitude_r; alpha_i <= amplitude_i;
						end
						else                                    //Odd: amplitude * i
						begin
							alpha_r <= -amplitude_i; alpha_i <= amplitude_r;
						end
					end
					else //if(reg_gate_type == 2'd2)    //CNOT
					begin
						state_alpha <= S2;
						//No modification is required for the case of CNOT
						alpha_r <= amplitude_r; alpha_i <= amplitude_i;
					end
				end
				else
				begin
					state_alpha <= S0;
				end
			end
			S1: //Special case for updating amplitude and basis index as first calculated alpha is zero
			begin
				alpha_r <= alpha_r; alpha_i <= alpha_i; done_alpha <= 1'd0; initial_alpha_zero <= 1'd0;
				state_alpha <= S2;
				if(alpha_r == 32'd0 && alpha_i == 32'd0)
				begin
					initial_alpha_zero <= 1'd1;
					if(basis_index[reg_qubit_pos]==1'd0)    //Even: amplitude - amplitude2
					begin
						alpha_r <= amplitude_r - amplitude2_r; alpha_i <= amplitude_i - amplitude2_i;
					end
					else                                    //Odd: amplitude2 + amplitude 
					begin
						alpha_r <= amplitude2_r + amplitude_r; alpha_i <= amplitude2_i + amplitude_i;
					end
				end
			end
			S2: //1 clock done signal
			begin
				state_alpha <= S0; done_alpha <= 1'd1; initial_alpha_zero <= initial_alpha_zero;
				alpha_r <= alpha_r; alpha_i <= alpha_i;
			end
			default:
			begin
				state_alpha <= S0; alpha_r <= 32'd0; alpha_i <= 32'd0;
				done_alpha <= 1'd0; initial_alpha_zero <= 1'd0;
			end
		endcase
	end
end
endmodule
