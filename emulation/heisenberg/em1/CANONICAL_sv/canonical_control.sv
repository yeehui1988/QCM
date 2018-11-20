module canonical_control #(parameter num_qubit = 4)(
input clk,
input rst_new,
input valid_in,
output reg ld_trans,
output reg ld_store,
output second_stage,
output reg [0:(2*num_qubit)-1] second_CR
);

integer i;
localparam [1:0] S0=2'd0, S1=2'd1, S2=2'd2, S3=2'd3;
reg [1:0] state;
reg [31:0] counter;
reg second_CR_activate;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		state <= S0; counter <= 32'd0; second_CR_activate <= 1'd0;
	end
	else
	begin
		case(state)
			S0: //Waiting state
			begin
				second_CR_activate <= 1'd0;
				if(valid_in)
				begin
					state<=S1; counter <= counter + 32'd1;
				end
				else
				begin
					state<=S0; counter <= 32'd0;
				end
			end
			S1: //Looping for Round 1 CR
			begin
				if(counter == (3*num_qubit)) //X-block + Z-block + literals rows input = 3N clock cycles
				begin
					state<=S2; counter <= 32'd1; second_CR_activate <= 1'd1;
				end
				else
				begin
					state<=S1; second_CR_activate <= 1'd0; counter <= counter + 32'd1;	
				end
			end
			S2:
			begin
				second_CR_activate <= 1'd0; 
				if(counter == (4*num_qubit)) //2N * 2 = 4N clock cycles
				begin
					state<=S0; counter <= 32'd1;
				end
				else
				begin
					state<=S2; counter <= counter + 32'd1;
				end
			end
			default: //Should not come to this state
			begin
				state <= S0; counter <= 32'd0; second_CR_activate <= 1'd0;
			end
		endcase
	end
end

assign second_stage = (state==S2)? 1'd1:1'd0;

//Generate control signals based on Mealy model
always@(*)
begin
	case(state)
		S0:
		begin
			if(valid_in)
			begin
				ld_trans<=1'd1; ld_store<=1'd1;
			end
			else
			begin
				ld_trans<=1'd0; ld_store<=1'd0;
			end
		end
		S1:
		begin
			ld_trans<=1'd1; ld_store<=1'd1;
		end
		S2:
		begin
			ld_trans<=1'd1; ld_store<=1'd1;
		end
		default:
		begin
			ld_trans <= 1'd0;	ld_store <= 1'd0;
		end
	endcase	
end

//A seperate FSM for second_CR signals
reg [1:0] state2;
reg [31:0] count_row;
reg [0:(2*num_qubit)-1] second_CR_pre;
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		state2 <= S0;
		count_row <= 32'd0;
		for (i=0; i<(2*num_qubit); i=i+1) 
		begin
			second_CR_pre[i] <= 1'd0;
		end
	end
	else
	begin
		case(state2)
			S0:
			begin
				count_row <= 32'd0;
				if(second_CR_activate == 1'd1)
				begin
					state2 <= S1;
					for (i=0; i<(2*num_qubit); i=i+1) 
					begin
						second_CR_pre[i] <= 1'd0;
					end
					second_CR_pre[0] <= 1'd1; //Set first bit to 1
				end
				else
				begin
					state2 <= S0;
					for (i=0; i<(2*num_qubit); i=i+1) 
					begin
						second_CR_pre[i] <= 1'd0;
					end
				end
			end
			S1:
			begin
				second_CR_pre <= second_CR_pre;
				count_row <= count_row;
				if(count_row == 2 * num_qubit)	//DOUBLE CHECK THIS VALUE!!!
				begin
					state2 <= S0;
				end
				else
				begin
					state2 <= S2;
				end
			end
			S2:	//Hold for 1 clock cycle
			begin
				count_row <= count_row + 32'd1;
				state2 <= S1;
				//right shift one bit
				for (i=1; i<(2*num_qubit); i=i+1) 
				begin
					second_CR_pre[i] <= second_CR_pre[i-1];
				end
				second_CR_pre[0] <= 1'd0; 
			end
			default:
			begin
				count_row <= 32'd0;
				state2 <= S0;
				for (i=0; i<(2*num_qubit); i=i+1) 
				begin
					second_CR_pre[i] <= 1'd0;
				end
			end
		endcase
	end
end

//Ensure signal alternate shift out from storage to transition
always@(*)
begin
	if(state2 == S1)
	begin
		i=0;
		second_CR <= second_CR_pre;
	end
	else
	begin
		for (i=0; i<(2*num_qubit); i=i+1) 
		begin
			second_CR[i] <= 1'd0;
		end
	end
end

endmodule
