module buffer_mux #(parameter num_qubit = 4, total_gate = 30)(
//Input:
input clk, input rst_new, input gp_ready,
input [1:0] literals_in [0:num_qubit-1], input phase_in, input valid_in, input valid_P,
//Output:
output reg [1:0] literals_out [0:num_qubit-1], output reg phase_out, output reg valid_out, output reg valid_P_out,
output literal_phase_readout, output ld_flag_anticommute 
);

integer i,j;
reg [31:0] counter_gate;
//Buffer: n-literal-by-n-row
reg [1:0] buffer_literals [0:num_qubit-1][0:num_qubit-1];
reg buffer_phase [0:num_qubit-1]; reg buffer_valid [0:num_qubit-1];
reg shift_down; wire ld_buffer;

assign ld_buffer = shift_down | valid_in;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0; i<num_qubit; i=i+1) 	    //each row
		begin
			for (j=0; j<num_qubit; j=j+1)	//each column
			begin
				buffer_literals[i][j] <= 2'd0;
			end
			buffer_phase[i] <= 1'd0;	buffer_valid[i] <= 1'd0;
		end
	end
	else
	begin
		j=0;
		if(ld_buffer)
		begin
			buffer_literals[0] <= literals_in; buffer_phase[0] <= phase_in;	buffer_valid[0] <= valid_in;
			for (i=1; i<num_qubit; i=i+1) 	//each row
			begin
				buffer_literals[i] <= buffer_literals[i-1]; 
				buffer_phase[i] <= buffer_phase[i-1]; buffer_valid[i] <= buffer_valid[i-1];
			end
		end
	end
end

//FSM for output selection & synchronization
reg [1:0] state;
localparam  S0=2'd0, S1=2'd1, S2=2'd2, S3=2'd3;
reg output_mux; reg [31:0] counter;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		state <= S0; counter <= 32'd0;
	end
	else
	begin
		case(state)
			S0: 
			begin
				counter <= 32'd0;
				if(valid_in & counter_gate < total_gate) 
				begin			
						state <= S1; counter <= counter + 1;
				end
				else
				begin
					state <= S0; 
				end
			end
			S1:
			begin
				if(valid_in)
				begin
					if(counter == num_qubit-1)
					begin
						state <= S2; counter <= 32'd0;
					end
					else
					begin
						state <= S1; counter <= counter + 32'd1;
					end
				end
				else
				begin
					state <= S1; counter <= counter;
				end
			end
			S2:
			begin
				if(gp_ready)
				begin
					state <= S3; counter <= counter + 1;
				end
				else
				begin
					state <= S2; counter <= counter;
				end
			end
			S3:
			begin
				if(counter == num_qubit)
				begin
					state <= S0; counter <= 32'd0;
				end
				else
				begin
					state <= S3; counter <= counter+32'd1;
				end
			end
			default:
			begin
				state <= S0; counter <= 32'd0;
			end
		endcase
	end
end

assign ld_flag_anticommute = (state==S2) && gp_ready;

//Mealy model for control output
always@(*)
begin
	case(state)
		S0:
		begin	
			output_mux <= 1'd0;         //Select default I
			shift_down <= 1'd0;
		end
		S1:
		begin
			output_mux <= 1'd0;         //Select default I
			shift_down <= 1'd0;
		end
		S2:
		begin
			if(gp_ready)
			begin
				output_mux <= 1'd1;     //Select buffer output
				shift_down <= 1'd1;
			end
			else
			begin
				output_mux <= 1'd0;     //Select default I
				shift_down <= 1'd0;
			end
		end
		S3:
		begin
			output_mux <= 1'd1;         //Select buffer output
			shift_down <= 1'd1;
		end
		default:
		begin
			output_mux <= 1'd0;         //Select default I
			shift_down <= 1'd0;
		end
	endcase
end

always@(*)
begin
	if(state == S3 & counter == num_qubit-1 & counter_gate < total_gate) 
	begin
		valid_P_out <= 1'd1;
	end
	else
	begin
		valid_P_out <= 1'd0;
	end
end

//Multiplexer for output selection
always@(*)
begin
	case(output_mux)
		1'd0: //Select default output from canonical module
		begin
			for (i=0; i<num_qubit; i=i+1)	//each column
			begin
				literals_out[i] <= 2'd0; 
			end
			phase_out <= 1'd0; valid_out <= 1'd0;
		end
		1'd1: //Select output from buffer
		begin
			literals_out <= buffer_literals[num_qubit-1]; phase_out <= buffer_phase[num_qubit-1]; 
			valid_out <= buffer_valid[num_qubit-1]; i=0;
		end
	endcase
end

//Readout after overall simulation is completed
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		counter_gate <= 32'd0;
	end
	else
	begin
		if(valid_P_out)
		begin
			counter_gate <= counter_gate + 32'd1;  
		end
	end
end

assign literal_phase_readout = (counter_gate >= total_gate)? 1'd1: 1'd0;
 
endmodule
