//Dual-port RAM - one read port, one write port
//Global Phase Maintenance
module ram_amplitude_control #(parameter num_qubit = 3, complex_bit = 24, fp_bit = 22, mem_width = 2*complex_bit)(
input clk, input rst,
//Write Global Phase:
input wr_enable1, input [mem_width-1:0] write_amplitude1, input [num_qubit-1:0] wr_address1,
input wr_enable2, input [mem_width-1:0] write_amplitude2, input [num_qubit-1:0] wr_address2,
input wr_enable3, input [mem_width-1:0] write_amplitude3, input [num_qubit-1:0] wr_address3,
input wr_enable4, input [mem_width-1:0] write_amplitude4, input [num_qubit-1:0] wr_address4,
output ram_amplitude_busy,
//Read Global Phase:
input [num_qubit-1:0] rd_address0, input [num_qubit-1:0] rd_address1, input rd_enable1, input [num_qubit-1:0] rd_address2, input rd_enable2,
input [num_qubit-1:0] rd_address3, input rd_enable3, input [num_qubit-1:0] rd_address4, input rd_enable4, output [2*complex_bit-1:0] read_amplitude
);

reg [2*complex_bit-1:0] amplitude_reset; reg amplitude_reset_en; reg [num_qubit-1:0] amplitude_reset_address;

/******************************************************RAM FOR AMPLITUDE STORAGE*****************************************************/
/*Write Amplitude*/
reg [mem_width-1:0] write_amplitude; reg [num_qubit-1:0] wr_address; wire wr_enable;
wire wr_enable0; wire [mem_width-1:0] write_amplitude0; wire [num_qubit-1:0] wr_address0;

assign ram_amplitude_busy = wr_enable | rd_enable1 | rd_enable2 | rd_enable3 | rd_enable4;

//Write 0: Reset amplitude to 1 at location 0 (Internal) 
assign wr_enable0 = amplitude_reset_en;
assign write_amplitude0 = amplitude_reset;
assign wr_address0 = amplitude_reset_address;

//Select input to write to memory
assign wr_enable = wr_enable0 | wr_enable1 | wr_enable2 | wr_enable3 | wr_enable4;

always@(*)
begin
	if(wr_enable0)
	begin
		wr_address <= wr_address0;
		write_amplitude <= write_amplitude0;
	end
	else if(wr_enable1)
	begin
		wr_address <= wr_address1;
		write_amplitude <= write_amplitude1;
	end
	else if (wr_enable2)
	begin
		wr_address <= wr_address2;
		write_amplitude <= write_amplitude2;
	end
	else if (wr_enable3)
	begin
		wr_address <= wr_address3;
		write_amplitude <= write_amplitude3;
	end
	else if (wr_enable4)
	begin
		wr_address <= wr_address4;
		write_amplitude <= write_amplitude4;
	end
	else
	begin
		wr_address <= {num_qubit{1'b0}};
		write_amplitude <= {mem_width{1'b0}};
	end
end

/*Read Amplitude*/
//Select input address to read from memory
reg [num_qubit-1:0] rd_address;
always@(*)
begin
	if(rd_enable1==1'd1)        //Read amplitude for verification
	begin
		rd_address <= rd_address1;
	end
	else if(rd_enable2==1'd1)   //Read amplitude for beta update
	begin
		rd_address <= rd_address2;
	end
	else if(rd_enable3==1'd1)   //Read amplitude for nonstabilizer phase shift update
	begin
		rd_address <= rd_address3;
	end
	else if(rd_enable4==1'd1)   //Read amplitude for stabilizer alpha update
	begin
		rd_address <= rd_address4;
	end
	else                        //For alpha global phase update
	begin
		rd_address <= rd_address0;
	end
end

/*Memory instantiation*/
ram ram_amplitude (.clk(clk), .write_en(wr_enable), .write_address(wr_address), .read_address(rd_address), 
.write_data(write_amplitude), .read_data(read_amplitude));
defparam ram_amplitude.addr_width = num_qubit; defparam ram_amplitude.mem_width = mem_width;


/***********************************************SET AMPLITUDE LOCATION 0 TO ONE UPON RESET*********************************************/
integer i;
reg state; localparam S0 = 1'd0, S1 = 1'd1;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state <= S0;
		for(i=0;i<2*complex_bit;i=i+1)
		begin
			amplitude_reset[i] <= 1'b0;
		end
		amplitude_reset_en <= 1'b0;
		amplitude_reset_address <= {num_qubit{1'b0}};
	end
	else
	begin
		case(state)
			S0:
			begin
				state <= S1;
				for(i=0;i<2*complex_bit;i=i+1)
				begin
					amplitude_reset[i] <= 1'b0;
				end
				amplitude_reset[complex_bit+fp_bit] <= 1'b1; //=> For now set it to 1 assume integer is used. UPDATE THIS LATER!!!
				amplitude_reset_en <= 1'b1;
				amplitude_reset_address <= {num_qubit{1'b0}};
			end
			S1:
			begin
				state <= S1;
				for(i=0;i<2*complex_bit;i=i+1)
				begin
					amplitude_reset[i] <= 1'b0;
				end
				amplitude_reset_en <= 1'b0;
				amplitude_reset_address <= {num_qubit{1'b0}};
			end
		endcase
	end
end 
	
endmodule 
