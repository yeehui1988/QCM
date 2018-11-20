module initialBasis #(parameter num_qubit = 3)(
input clk,
input rst,
input start,
output reg [1:0] literals [0:num_qubit-1],
output reg phase 
);

//Finite state machine to setup the basis state literals
reg state;
localparam S0 = 1'd0, S1 = 1'd1;
integer i;
reg [31:0] counter;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state <= S0;
		for (i=1; i<num_qubit; i=i+1) 
		begin
			literals[i] <= 2'd0; //I literal
		end
		literals [0] <= 2'b01; 	//Z literal
		phase <= 1'b0;			//+ phase
		counter <= num_qubit;	//determine number of shift operation
	end
	else
	begin
		case (state)
			S0:
			begin
				phase <= 1'b0;
				if(start)
				begin
					state <= S1;
					counter <= counter - 32'd1;
				end
				else
				begin
					state <= S0;
				end
			end
			S1:
			begin
				phase <= 1'b0;
				counter <= counter - 32'd1;
				for (i=1; i<num_qubit; i=i+1) 
				begin
					literals[i] <= literals[i-1]; 			//shift right
				end
				literals [0] <= literals [num_qubit-1]; 	//rotate
				if(counter == 32'd0)
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

endmodule
