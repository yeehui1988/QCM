module update_amplitude_beta #(parameter num_qubit = 4, complex_bit = 24)(
input clk, input rst,
input determine_amplitude_beta, input determine_amplitude_stabilizer, input done_amplitude, input [31:0] counter_valid_vector,
output [num_qubit-1:0] ram_amplitude_beta_readout_address, output ram_amplitude_beta_readout_en, input [2*complex_bit-1:0] ram_amplitude_beta_readout,
input signed [1:0] beta_r, input signed [1:0] beta_i, 
output reg ram_amplitude_beta_writein_en, output [2*complex_bit-1:0] ram_amplitude_beta_writein, output reg [num_qubit-1:0] ram_amplitude_beta_writein_address,
output updating_beta	
);

integer i;
reg [1:0] state;
localparam [1:0] S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;
reg [31:0] counter;
wire signed [complex_bit-1:0] ram_amplitude_beta_readout_r; wire signed [complex_bit-1:0] ram_amplitude_beta_readout_i;
reg signed [complex_bit-1:0] ram_amplitude_beta_writein_r; reg signed [complex_bit-1:0] ram_amplitude_beta_writein_i;
reg signed [1:0] reg_beta_r; reg signed [1:0] reg_beta_i;

assign ram_amplitude_beta_readout_r = ram_amplitude_beta_readout [2*complex_bit-1:complex_bit];
assign ram_amplitude_beta_readout_i = ram_amplitude_beta_readout [complex_bit-1:0];
assign ram_amplitude_beta_writein = {ram_amplitude_beta_writein_r,ram_amplitude_beta_writein_i};
assign updating_beta = (state==S1 || state==S2)? 1'd1:1'd0;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state <= S0; counter <= 32'd0;
	end
	else
	begin
		case(state)
			S0:
			begin
				counter <= 32'd0;
				if(determine_amplitude_beta | determine_amplitude_stabilizer)
				begin
					state <= S1;
				end
				else
				begin
					state <= S0;
				end
			end
			S1:
			begin
				counter <= 32'd0;
				if(done_amplitude)
				begin
					counter <= counter + 1;
					if(counter_valid_vector==1)
					begin
						state <= S0; counter <= 32'd0;
					end
					else
					begin
						state <= S2;
					end
				end
				else
				begin
					state <= S1;
				end
			end
			S2:
			begin
				if(counter == counter_valid_vector-1) //counter_valid_vector is at least 2
				begin
					state <= S0;
					counter <= 32'd0;
				end
				else
				begin
					state <= S2;
					counter <= counter + 1;
				end
			end
			default:
			begin
				state <= S0;
				counter <= 32'd0;
			end
		endcase
	end
end

assign ram_amplitude_beta_readout_en = (state==S2) || (state==S1 && done_amplitude);
assign ram_amplitude_beta_readout_address = counter [num_qubit-1:0];

//ADD PIPELINE REGISTER TO REDUCE OVERALL CPD
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		ram_amplitude_beta_writein_en <= 1'd0;
		ram_amplitude_beta_writein_address <= {num_qubit{1'd0}};
		reg_beta_r <= 2'd0; reg_beta_i <= 2'd0;
	end
	else
	begin
		ram_amplitude_beta_writein_en <= ram_amplitude_beta_readout_en;
		ram_amplitude_beta_writein_address <= ram_amplitude_beta_readout_address;
		reg_beta_r <= beta_r; reg_beta_i <= beta_i; //sync with read data from ram global phase
	end
end

always@(*)
begin
	if(reg_beta_r==2'd1)        //divide by +1: Remain Unchanged
	begin
		ram_amplitude_beta_writein_r = ram_amplitude_beta_readout_r;
		ram_amplitude_beta_writein_i = ram_amplitude_beta_readout_i;
	end
	else if(reg_beta_r==-2'd1)  //divide by -1: Multiply by -1
	begin
		ram_amplitude_beta_writein_r = -ram_amplitude_beta_readout_r;
		ram_amplitude_beta_writein_i = -ram_amplitude_beta_readout_i;
	end
	else if(reg_beta_i==2'd1)   //divide by i: Multiply by -i
	begin
		//(global_phase_r * beta_r) - (global_phase_i * beta_i);
		ram_amplitude_beta_writein_r = ram_amplitude_beta_readout_i;
		//(global_phase_i * beta_r) + (global_phase_r * beta_i);
		ram_amplitude_beta_writein_i = -ram_amplitude_beta_readout_r;
	end
	else if(reg_beta_i==-2'd1)  //divide by -i: Multiply by i
	begin
		//(global_phase_r * alpha_r) - (global_phase_i * alpha_i); 
		ram_amplitude_beta_writein_r = -ram_amplitude_beta_readout_i;
		//(global_phase_i * alpha_r) + (global_phase_r * alpha_i); 
		ram_amplitude_beta_writein_i = ram_amplitude_beta_readout_r;
	end
	else
	begin
		ram_amplitude_beta_writein_r = ram_amplitude_beta_readout_r;
		ram_amplitude_beta_writein_i = ram_amplitude_beta_readout_i;
	end
end

endmodule 
