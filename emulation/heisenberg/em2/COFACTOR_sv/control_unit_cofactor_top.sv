module control_unit_cofactor_top #(parameter num_qubit = 3)(
input clk, input rst,
//input new_cofactor,
//FOR COFACTOR:
//From cofactor
input valid_out_cofactor, input valid_flag_anticommute, input flag_anticommute,
input [1:0] literals_out_cofactor [0:num_qubit-1], input phase_out_cofactor [0:2**num_qubit-1],
//To cofactor
output valid_P_cofactor, output reg valid_in_cofactor, 
output reg [1:0] literals_in_cofactor [0:num_qubit-1], output reg phase_in_cofactor [0:2**num_qubit-1],
//FOR CANONICAL:
//From canonical
input valid_out_canonical, input [1:0] literals_out_canonical [0:num_qubit-1], input phase_out_canonical [0:2**num_qubit-1],
//To canonical
output rst_canonical, output reg valid_in_canonical,
output reg [1:0] literals_in_canonical [0:num_qubit-1], output reg phase_in_canonical [0:2**num_qubit-1],
//For overall control:
output reg [1:0] literals_out[0:num_qubit-1], output reg phase_out [0:2**num_qubit-1], output reg valid_out,
//For current testing purpose:
input [1:0] literals_in [0:num_qubit-1], input phase_in [0:2**num_qubit-1], input valid_in, input valid_P 
);

integer i; reg [31:0] counter;
reg [2:0] state;
localparam [2:0] S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4, S5 = 3'd5, S6 = 3'd6, S7 = 3'd7;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state <= S1; //S0; 
		counter <= 32'd0;
	end
	else
	begin
		case(state)
/*		
			//Take output from cofactor module. 
			S0:
			begin
				counter <= 32'd0;
				if(new_cofactor)
				begin
					state <= S1;
				end
				else
				begin
					state <= S0;
				end
			end
*/			
			//Cofactor take input from external module
			S1: //literals, phase & valid signals send to cofactor module (first round - alpha)
			begin
				counter <= 32'd0;
				if(valid_flag_anticommute)
				begin
					if(flag_anticommute)    //Randomized cofactor outcome
					begin
						state <= S2;
					end
					else				    //Deterministic cofactor outcome
					begin
						state <= S1; 
					end
				end
				else
				begin
					state <= S1;
				end
			end
			//Canonical take input from cofactor module
			S2: //Cofactor alpha
			begin
				if(valid_out_cofactor)
				begin
					counter <= counter + 32'd1;
				end
				else
				begin
					counter <= counter;
				end
				if(counter == num_qubit)
				begin
					state <= S3;
					counter <= 32'd0;
				end
				else
				begin
					state <= S2;
				end
			end
			//Cofactor take input from canonical module
			S3: //Canonical Reduction
			begin
				counter <= 32'd0;
				if(valid_P) //Valid P should come after valid signal
				begin
					state <= S1; 
				end
				else
				begin
					state <= S3;
				end		
			end
			default:
			begin
				state <= S1; 
				counter <= 32'd0;
			end	
		endcase
	end
end

//Selection for overall output
always@(*)
begin
	case(state)	
/*	
		S0: //Either deterministic or randomized outcomes both end up with this state to produce valid output: From cofactor
		begin
			valid_out <= valid_out_cofactor; literals_out <= literals_out_cofactor; phase_out <= phase_out_cofactor; i=0;
		end
*/		
		S1:         //Valid output might appear at this state if deterministic outcome is obtained
		begin
			valid_out <= valid_out_cofactor; literals_out <= literals_out_cofactor; phase_out <= phase_out_cofactor; i=0;
		end
		default:    //Overall not valid
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
	endcase
end

//Selection for input to canonical: 
always@(*)
begin
	case(state)
		S2: //For now only from cofactor
		begin
			valid_in_canonical <= valid_out_cofactor; literals_in_canonical <= literals_out_cofactor; phase_in_canonical <= phase_out_cofactor; i=0;
		end
		default: //Overall not valid
		begin
			valid_in_canonical <= 1'd0; 
			for(i=0;i<num_qubit;i=i+1)
			begin
				literals_in_canonical [i] <= 2'd0; 
			end
			for(i=0;i<2**num_qubit;i=i+1)
			begin
				phase_in_canonical [i] <= 1'd0; 
			end
		end
	endcase
end

//Selection for input to cofactor: 
always@(*)
begin
	case(state)
		S1:     //Cofactor alpha: from external
		begin
			valid_in_cofactor <= valid_in; literals_in_cofactor <= literals_in; phase_in_cofactor <= phase_in; i=0;
		end
		S3:     //Cofactor beta: from canonical
		begin
			valid_in_cofactor <= valid_out_canonical; literals_in_cofactor <= literals_out_canonical; phase_in_cofactor <= phase_out_canonical; i=0;
		end
		default: //Overall not valid
		begin
			valid_in_cofactor <= 1'd0; 
			for(i=0;i<num_qubit;i=i+1)
			begin
				literals_in_cofactor [i] <= 2'd0; 
			end
			for(i=0;i<2**num_qubit;i=i+1)
			begin
				phase_in_cofactor [i] <= 1'd0; 
			end
		end
	endcase
end

assign valid_P_cofactor = (state == S1 || state == S3) && valid_P;
assign rst_canonical = rst; 

endmodule 
