module update_amplitude_cofactor #(parameter num_qubit = 4, complex_bit = 24)(
input clk, input rst,
//From RAM Index:
input [31:0] counter_valid_phase, input valid_second_round, input valid_index_readout, input [num_qubit-1:0] index_location, 
//From RAM Alpha (read_alpha):
input [7:0] ram_alpha_readout,
//From RAM Amplitude (read amplitude):
input [2*complex_bit-1:0] ram_amplitude_readout,
//To RAM Alpha & RAM Amplitude (read alpha & amplitude):
output [num_qubit-1:0] generator_amplitude_address, output generator_address_valid,
//To RAM Amplitude (write amplitude):
output reg [2*complex_bit-1:0] ram_amplitude_writein, output reg ram_amplitude_writein_en, output reg [num_qubit-1:0] ram_amplitude_writein_address
);

integer i;
wire empty, read_index; 
wire [num_qubit:0] index_out;
wire [2*complex_bit-1:0] ram_amplitude_writein_pre; wire ram_amplitude_writein_en_pre; wire [num_qubit-1:0] ram_amplitude_writein_address_pre;

/**********************************************************FIFO INDEX***********************************************************/
fifo fifo_index (.clk(clk), .rst(rst), .wr_en(valid_second_round), .din({valid_index_readout,index_location}), .rd_en(read_index), .dout(index_out), 
.empty(empty), .full());
defparam fifo_index.data_width = num_qubit+1; defparam fifo_index.fifo_bit = num_qubit; 

/******************************************************ADDRESS GENERATOR*******************************************************/
address_generator_cofactor addr_gen (.clk(clk), .rst(rst), .index_fifo_empty(empty), .index_in(index_out), .counter_vector(counter_valid_phase), 
.read_index(read_index), .read_address(generator_amplitude_address), .address_valid(generator_address_valid));
defparam addr_gen.num_qubit = num_qubit;

/************************************************ALU FOR AMPLITUDE UPDATE******************************************************/ 
//Global phase maintenance (for cofactor alpha)
alu_cofactor alu (.clk(clk), .rst(rst), .data_valid(generator_address_valid), .in_location(generator_amplitude_address), .alpha(ram_alpha_readout), 
.amplitude_in(ram_amplitude_readout), .amplitude_out(ram_amplitude_writein_pre), .write_en(ram_amplitude_writein_en_pre), 
.write_location(ram_amplitude_writein_address_pre));
defparam alu.num_qubit = num_qubit; defparam alu.complex_bit = complex_bit;

//ADD PIPELINE REGISTERS TO REDUCE OVERALL CPD
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for(i=0;i<2*complex_bit;i=i+1)
		begin
			ram_amplitude_writein[i] <= 1'd0;
		end
		for(i=0;i<num_qubit;i=i+1)
		begin
			ram_amplitude_writein_address[i] <= 1'd0;
		end
		ram_amplitude_writein_en <= 1'd0;
	end
	else
	begin
		i=0;
		ram_amplitude_writein <= ram_amplitude_writein_pre;
		ram_amplitude_writein_address <= ram_amplitude_writein_address_pre;
		ram_amplitude_writein_en <= ram_amplitude_writein_en_pre;
	end
end

endmodule 
