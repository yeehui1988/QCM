module select_in #(parameter num_qubit = 3)(
//Input:
input clk, input rst_new,
output reg [1:0] literals_out [0:num_qubit-1], output reg phase_out, output reg valid_out
);

reg [1:0] stateInput; integer i; reg [31:0] counter;
localparam  S0=2'd0, S1=2'd1, S2=2'd2, S3=2'd3;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		stateInput <= S0; counter <= 32'd0;
	end
	else
	begin
		case(stateInput)
			S0:
			begin
				stateInput <= S1; counter <= 32'd0;
			end
			S1: //Initialize stabilizer matrix to basis state |0..0>
			begin
				if(counter == num_qubit)
				begin
					stateInput <= S2; counter <= 32'd0;
				end
				else
				begin
					stateInput <= S1; counter = counter + 1;
				end
			end
			S2:
			begin
				stateInput <= S2; counter <= 32'd0;
			end
			default:
			begin
				stateInput <= S0; counter <= 32'd0;
			end
		endcase
	end
end

always@(*)
begin
	case(stateInput)
		S1:
		begin
			if(counter == num_qubit)
			begin
				for (i=0; i<num_qubit; i=i+1)	//each column
				begin
					literals_out [i] <= 2'd0;
				end
				phase_out <= 1'd0; valid_out <= 1'd0; 
			end
			else
			begin
				for (i=0; i<num_qubit; i=i+1)	//each column
				begin
					literals_out [i] <= 2'd0;
				end
				phase_out <= 1'd0; literals_out [counter] <= 2'd1; valid_out <= 1'd1;
			end
		end
		S2:
		begin
			for (i=0; i<num_qubit; i=i+1)	    //each column
			begin
				literals_out [i] <= 2'd0;
			end
			phase_out <= 1'd0; valid_out <= 1'd0; 		
		end
		default:
		begin
			for (i=0; i<num_qubit; i=i+1)	    //each column
			begin
				literals_out [i] <= 2'd0;
			end
			phase_out <= 1'd0; valid_out <= 1'd0; 
		end
	endcase
end

endmodule
