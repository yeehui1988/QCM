module address_generator_cofactor #(parameter num_qubit = 3)(
input clk, input rst,
input index_fifo_empty, input [num_qubit:0] index_in,
input [31:0] counter_vector,
output reg [num_qubit-1:0] read_address, output reg address_valid, output reg read_index
);

reg [num_qubit-1:0] reg_index_in;
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		reg_index_in <= {num_qubit{1'b0}};
	end
	else
	begin
		reg_index_in <= index_in[num_qubit-1:0];
	end
end

reg [1:0] state;
localparam S0=2'd0, S1=2'd1, S2=2'd2, S3=2'd3;
reg [31:0] counter; reg [31:0] counter_vector_updated;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state <= S0; counter <= 32'd0; counter_vector_updated <= 32'd0;
	end
	else
	begin
		case(state)
			S0:
			begin
				counter <= 32'd0; counter_vector_updated <= counter_vector_updated;
				if(index_fifo_empty==1'd0) //FIFO index not empty
				begin
					state <= S1; counter_vector_updated <= counter_vector;
				end
				else
				begin
					state <= S0;
				end
			end
			S1:
			begin
				if(index_in[num_qubit] == 1'd0) //No valid pair exist - Add new amplitude
				begin
					counter <= counter + 1; counter_vector_updated <= counter_vector_updated + 1;
					state <= S3;
				end
				else //Valid pair exist
				begin
					counter_vector_updated <= counter_vector_updated;
					if(index_in[num_qubit-1:0] > counter) //Paired amplitude HAVEN'T UPDATED
					begin
						counter <= counter + 1;
						state <= S2;
					end
					else //Paired amplitude ALREADY UPDATED
					begin
						if(counter == counter_vector-1) //Current counter should be counter + 1 (typically update by the following clock)
						begin
							state <= S0;
							counter <= 32'd0;
						end
						else
						begin
							state <= S1;
							counter <= counter + 1;
						end
					end
				end
			end
			S2: //Valid pair exist. Paired amplitude HAVEN'T UPDATED
			begin
				counter <= counter; counter_vector_updated <= counter_vector_updated;
				if(counter == counter_vector)
				begin
					state <= S0;
				end
				else
				begin
					state <= S1;
				end
			end
			S3: //No valid pair exist - Add new amplitude
			begin
				counter <= counter; counter_vector_updated <= counter_vector_updated;
				if(counter == counter_vector)
				begin
					state <= S0;
				end
				else
				begin
					state <= S1;
				end
			end
		endcase
	end
end


always@(*)
begin
	case(state)
		S0:
		begin
			if(index_fifo_empty==1'd0)
			begin
				//Current clock read from FIFO, next clock valid index_in is available	
				read_index <= 1'd1;
				address_valid <= 1'd0;
				read_address <= {num_qubit{1'b0}};	
			end
			else
			begin
				read_index <= 1'd0;
				address_valid <= 1'd0;
				read_address <= {num_qubit{1'b0}};
			end
		end
		S1: 
		begin
			if(index_in[num_qubit] == 1'd0) //No valid pair exist - Add new amplitude
			begin
				read_index <= 1'd0;
				address_valid <= 1'd1;
				read_address <= counter[num_qubit-1:0];
			end
			else //Valid pair exist
			begin
				if(index_in[num_qubit-1:0] > counter[num_qubit-1:0]) //Paired amplitude HAVEN'T UPDATED
				begin
					read_index <= 1'd0;
					address_valid <= 1'd1;
					read_address <= counter[num_qubit-1:0];
				end
				else //Paired amplitude ALREADY UPDATED => No operation. Continue to next
				begin
					if(counter == counter_vector-1)
					begin
						read_index <= 1'd0;
						address_valid <= 1'd0;
						read_address <= {num_qubit{1'b0}};
					end
					else
					begin
						read_index <= 1'd1;
						address_valid <= 1'd0;
						read_address <= {num_qubit{1'b0}};
					end
				end
			end
		end
		S2: //Phase vector pair (duplicate_toggle) location	
		begin
			if(counter == counter_vector)
			begin
				read_index <= 1'd0;
				address_valid <= 1'd1;
				read_address <= reg_index_in;
			end
			else
			begin
				read_index <= 1'd1;
				address_valid <= 1'd1;
				read_address <= reg_index_in;
			end
		end
		S3: //No valid pair exist - Add new amplitude
		begin
			if(counter == counter_vector)
			begin
				read_index <= 1'd0;
				address_valid <= 1'd1;
				read_address <= counter_vector_updated [num_qubit-1:0] - 1'b1;
			end
			else
			begin
				read_index <= 1'd1;
				address_valid <= 1'd1;
				read_address <= counter_vector_updated [num_qubit-1:0] - 1'b1;
			end
		end
	endcase
end

endmodule
