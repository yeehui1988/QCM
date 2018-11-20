//Dual-port RAM - one read port, one write port
module ram_alpha_control #(parameter num_qubit = 3)(
input clk,
input [num_qubit-1:0] read_address, input [num_qubit-1:0] write_address, input write_enable, 
input [7:0] write_alpha, output [7:0] read_alpha	
);

//Memory instantiation
ram ram_alpha (.clk(clk), .write_en(write_enable), .write_address(write_address), .read_address(read_address), 
.write_data(write_alpha), .read_data(read_alpha));
defparam ram_alpha.addr_width = num_qubit; defparam ram_alpha.mem_width = 32'd8;
	
endmodule 
