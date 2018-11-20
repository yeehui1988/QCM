//Dual-port RAM - one read port, one write port
module ram #(parameter addr_width = 4, mem_width = 16)( 
input clk, input write_en,
input [addr_width-1:0] write_address,
input [addr_width-1:0] read_address,
input [mem_width-1:0] write_data,
output reg [mem_width-1:0] read_data
);

reg [mem_width-1:0] ram_array [0:2**addr_width-1] /* synthesis ramstyle = "no_rw_check" */;

//Initialize all with zero
integer i;
initial 
begin 
	for(i = 0; i < 2**addr_width; i = i + 1)
	begin
		ram_array[i] = {mem_width{1'b0}};
	end
end

always@(posedge clk)
begin
	if(write_en)
	begin
		// Read (if read_addr == write_addr, return OLD data).	
		// To return NEW data, use = (blocking write) rather than <= (non-blocking write) in the write assignment.	 
		// NOTE: NEW data may require extra bypass logic around the RAM.
		ram_array [write_address] = write_data;
	end
	read_data <= ram_array [read_address];
end
	
endmodule 