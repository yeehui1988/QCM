//Dual-port RAM & control to store and read index
module ram_index_control #(parameter num_qubit = 3)(
input clk, input rst,
input valid_ori_phase_write,					//Valid index data to be written to memory (from register array)
input ori_phase_vector [0:num_qubit-1] ,		//Connect from phase vector: write_address 
input done_alpha,								//Synchoronize with phase vector rotation wait state
output output_valid, 							//Flag for valid content (MSB in memory)
output [num_qubit-1:0] output_index,			//Location of corresponding toggle_phase_vector -> Readout from memory
output valid_second_round, output reg[31:0] counter_valid_phase,
output reg reg_toggle_phase_vector [0:num_qubit-1], output reg [num_qubit-1:0] mapped_reg_toggle_phase_vector
);

integer i;
localparam mem_width = num_qubit+1;

wire [mem_width-1:0] read_index; reg [mem_width-1:0] write_index;
wire wr_enable; reg [num_qubit-1:0] wr_address; 
reg [31:0] counter; 
reg reg_ori_phase_vector [0:num_qubit-1];  
reg toggle_phase_vector [0:num_qubit-1]; 	    //Connect from phase vector with toggle phase at anticommuting row
always@(*)
begin
	for (i=0; i<num_qubit-1; i=i+1)
	begin
		toggle_phase_vector[i] <= ori_phase_vector[i];
	end
	if(ori_phase_vector[num_qubit-1]==1'd0)
		toggle_phase_vector[num_qubit-1] <= 1'd1;
	else
		toggle_phase_vector[num_qubit-1] <= 1'd0;
end

//Mapping from unpacked to packed array
reg [num_qubit-1:0] mapped_ori_phase_vector; reg [num_qubit-1:0] mapped_toggle_phase_vector; 
reg [num_qubit-1:0] mapped_reg_ori_phase_vector; 
always@(*)
begin
	for(i=0; i<num_qubit; i=i+1)
	begin
		mapped_ori_phase_vector[num_qubit-1-i] <= ori_phase_vector[i];
		mapped_toggle_phase_vector[num_qubit-1-i] <= toggle_phase_vector[i]; 
		mapped_reg_ori_phase_vector[num_qubit-1-i] <= reg_ori_phase_vector[i];
		mapped_reg_toggle_phase_vector[num_qubit-1-i] <= reg_toggle_phase_vector[i]; 
	end
end

ram ram_index (.clk(clk), .write_en(wr_enable), .write_address(wr_address), .read_address(mapped_toggle_phase_vector), 
.write_data(write_index), .read_data(read_index));
defparam ram_index.addr_width = num_qubit; defparam ram_index.mem_width = mem_width;


//One clk delay for secound round operation
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0; i<num_qubit; i=i+1) //each bit 
		begin
			reg_ori_phase_vector [i] <= 1'd0;
			reg_toggle_phase_vector [i] <= 1'd0;
		end
	end
	else
	begin
		reg_ori_phase_vector <= ori_phase_vector; i=0;
		reg_toggle_phase_vector <= toggle_phase_vector;
	end
end

reg [1:0] state;
localparam S0=2'd0, S1=2'd1, S2=2'd2, S3=2'd3;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state <= S0; counter <= 32'd0; counter_valid_phase <= 32'd0; 
	end
	else
	begin
		case(state)
			S0:
			begin
				if(valid_ori_phase_write)
				begin
					state <= S1; counter <= 32'd1; counter_valid_phase <= 32'd1; 
				end
				else
				begin
					state <= S0; counter <= 32'd0; counter_valid_phase <= counter_valid_phase; 
				end
			end
			S1:
			begin
				counter = counter + 32'd1; counter_valid_phase <= counter_valid_phase;
				if(counter == ((2**num_qubit))) 
				begin
					counter  = 32'd0;
					if(done_alpha)
					begin
						state <= S2; 
					end
					else
					begin
						state <= S3;
					end
				end
				else
				begin
					state <= S1;
				end
				if(valid_ori_phase_write)
				begin
					counter_valid_phase <= counter_valid_phase + 32'd1;
				end
			end
			S2:
			begin
				counter = counter + 32'd1; counter_valid_phase <= counter_valid_phase;
				if(counter == ((2**num_qubit)+1)) 
				begin
					state <= S0; 
				end
				else
				begin
					state <= S2;
				end
			end
			S3: //Additional wait state to synchoronize with phase vector rotation wait for alpha write to be completed
			begin
				counter <= counter; counter_valid_phase <= counter_valid_phase; 
				if(done_alpha)
				begin
					state <= S2; 
				end
				else
				begin
					state <= S3;
				end
			end
			default:
			begin
				state <= S0; counter <= 32'd0; counter_valid_phase <= 32'd0; 
			end
		endcase
	end
end

//Memory clearance has one clock delay from the 2nd round phase vector input
assign valid_second_round = (state==S2 & counter>0 & counter <= counter_valid_phase)? 1'd1:1'd0;

assign wr_enable = valid_ori_phase_write | valid_second_round;
always@(*)
begin
	if(valid_ori_phase_write) //First round write index into memory
	begin
		write_index <= {1'd1, counter[num_qubit-1:0]};
		wr_address <= mapped_ori_phase_vector; i=0;
	end
	else        //Second round clear index from memory after read out
	begin
		for (i=0; i<mem_width; i=i+1)       //each bit include valid bit
		begin
			write_index[i] = 1'd0;
		end
		if(read_index[mem_width-1] == 1'd1) //valid pair exists, clear data after read out
		begin
			wr_address <= mapped_reg_toggle_phase_vector;
		end
		else	//valid pair not exists, clear data of the original phase vector location
		begin
			wr_address <= mapped_reg_ori_phase_vector;
		end
	end
end

//Assign valid output bit from memory to external module
assign output_valid = read_index[mem_width-1] & valid_second_round;	//Flag for valid content (MSB) == [num_qubit]
assign output_index = read_index[num_qubit-1:0];         			//Valid location (LSB)

endmodule
