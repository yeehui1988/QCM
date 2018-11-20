module fifo #(parameter data_width = 4, fifo_bit = 4)(
input clk, input rst,
input wr_en, input rd_en,
input [data_width-1:0] din,	
output reg [data_width-1:0] dout,
output empty, output full
);

localparam fifo_depth = 2**fifo_bit;

reg [data_width-1:0] queue [0:fifo_depth-1] /* synthesis ramstyle = "no_rw_check" */;
reg [fifo_bit-1:0] rd_ptr; reg [fifo_bit-1:0] wr_ptr;
reg [31:0] depth;

//Initialize all with zero
integer i;
initial 
begin 
	for(i=0; i<fifo_depth; i=i+1)
	begin
		queue[i] <= {data_width{1'b0}};
	end
end

//RAM-based storage 
always@(posedge clk)
begin
	if(wr_en)
	begin
		queue[wr_ptr] <= din;
	end
	dout <= queue[rd_ptr];	
end

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		rd_ptr <= {fifo_bit{1'b0}};
		wr_ptr <= {fifo_bit{1'b0}};
		depth <= 32'd0;	
	end
	else
	begin
		//Update pointer
		if(wr_en)
		begin
			wr_ptr <= (wr_ptr==fifo_depth-1)? {fifo_bit{1'b0}} : wr_ptr + {{fifo_bit-1{1'b0}},1'b1};
		end
		if(rd_en)
		begin
			rd_ptr <= (rd_ptr==fifo_depth-1)? {fifo_bit{1'b0}} : rd_ptr + {{fifo_bit-1{1'b0}},1'b1};
		end
		//Update depth
		if (wr_en & ~rd_en)
		begin
			depth <= depth + 32'd1;	
		end
		if (~wr_en & rd_en)
		begin
			depth <= depth - 32'd1;
		end
	end
end

//Signals to indicate if FIFO is full or empty
assign empty = (depth==32'd0)? 1'd1: 1'd0;
assign full = (depth==fifo_depth)? 1'd1: 1'd0;

//Display error message if read from empty FIFO or write to full FIFO
always @(posedge clk)
begin
    if(~rst)begin
       if (wr_en && full && !rd_en)
          $display(" %t: ERROR: Attempt to write to full FIFO: %m",$time);
       if (rd_en && empty)
          $display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
    end
end

endmodule

