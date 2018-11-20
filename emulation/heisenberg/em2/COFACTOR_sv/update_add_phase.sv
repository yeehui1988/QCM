module update_add_phase #(parameter num_qubit = 3)(
input clk, input rst,
input mux_phase_shift_in, //indicate that new phase can be read out from FIFO and added to register array if it is not empty
input phase_left_out[0:num_qubit-1], input reg_toggle_phase_vector [0:num_qubit-1], 
input [num_qubit-1:0] mapped_reg_toggle_phase_vector, input valid_index_readout, input valid_second_round,
output reg phase_right_in[0:num_qubit-1], output reg [31:0] counter_valid_vector
);

integer i;
wire add_toggle_valid_modified, add_toggle_valid, read_new_phase, empty, worst_case;
//Connect from new_phase_vector FIFO
wire [num_qubit-1:0] new_phase_vector; reg mapped_new_phase_vector [0:num_qubit-1];

//No matched pair is found. Add new phase vector.
assign add_toggle_valid = (valid_second_round==1'd1 & valid_index_readout==1'd0)? 1'd1: 1'd0;

//Mapping from packed to unpacked array
always@(*)
begin
	for(i=0; i<num_qubit; i=i+1)
	begin
		mapped_new_phase_vector[i] <= new_phase_vector[num_qubit-1-i];
	end
end

//FIFO not empty and append new phase vector stage
assign read_new_phase = (empty==1'd0 && mux_phase_shift_in ==1'd1)? 1'd1: 1'd0; 
assign worst_case = (add_toggle_valid == 1'd1 & empty == 1'd1 & mux_phase_shift_in ==1'd1)? 1'd1:1'd0;

//Exclude worst case (last valid phase vector induces new phase vector) from writing to FIFO 
assign add_toggle_valid_modified = (worst_case)? 1'd0: add_toggle_valid;

//Multiplexer to select left rotation or add in new valid phase vector (from FIFO) to the list
always@(*)
begin
	if(mux_phase_shift_in == 1'd0) //Rotate left. No changes.
	begin
		i=0;
		phase_right_in <= phase_left_out;
	end
	else
	begin
		i=0;
		if(empty == 1'd0) //FIFO NOT empty
		begin
			phase_right_in <= mapped_new_phase_vector;
		end
		else //FIFO empty
		begin
			if(worst_case) //valid new toggle phase vector from index table (worst case: last valid phase vector induces new phase vector)
			begin
				phase_right_in <= reg_toggle_phase_vector;
			end
			else
			begin
				for(i=0; i<num_qubit; i=i+1)
				begin
					phase_right_in[i] <= 1'b0;
				end
			end
		end
	end
end

//FIFO to store new phase vector to be added to register array
fifo_alter fifo_phase (.clk(clk), .rst(rst), .wr_en(add_toggle_valid_modified), .rd_en(read_new_phase), .din(mapped_reg_toggle_phase_vector), .dout(new_phase_vector), 
.empty(empty), .full());
defparam fifo_phase.data_width = num_qubit; defparam fifo_phase.fifo_bit = num_qubit-1; 

//Counter to keep track of valid vector pair
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		counter_valid_vector <= 32'd1;
	end
	else
	begin
		if(add_toggle_valid)
		begin
			counter_valid_vector <= counter_valid_vector + 1;
		end
		else
		begin
			counter_valid_vector <= counter_valid_vector;
		end
	end
end

endmodule 
