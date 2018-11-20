//ROM for controlled phase shift: Address is offset by 2 start from R(2) at address 0
module phase_imag_rom
#(parameter DATA_WIDTH=24, parameter ADDR_WIDTH=5)
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output reg [(DATA_WIDTH-1):0] q
);

	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
	
	initial
	begin
		$readmemh("phase_i_init.txt", rom);
	end

	always @ (posedge clk)
	begin
		q <= rom[addr];
	end

endmodule
