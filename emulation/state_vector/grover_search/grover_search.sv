module grover_search #(parameter num_bit = 10, fixedpoint_bit = 24, 
//num_sample: to be mapped into function; fixed point representation: 1 sign bit, 1 integer bit, 22 mantissa bits 
num_sample = (2**num_bit), sqrt_num_sample = 2**(num_bit/2.0), equalProb = 2**((fixedpoint_bit-2)-(num_bit/2.0)), 
PI = 3.14159265, num_ite = (PI/4.0) * sqrt_num_sample -0.5)
//Compute value of equal probability, 1/sqrt(num_sample) with fixed point adjustment (multiply by mantissa bits) 
//After mathematical simplification becomes pow(2,((fixedpoint_bit-2)-(num_bit/2))) 
//Number of iteration required by Grover's algorithm is equal to PI/4*sqrt(num_sample) given number of solution M in the search elements is less than num_sample/2
//Floor of number of iteration (obey the equation) is obtained by subtracting 0.5 from the computed value
(input clk, input rst, input start, input [(num_bit-1):0] target_search,
output reg signed [(fixedpoint_bit-1):0] output_r [0:(num_sample-1)], output reg done);

	integer i;	genvar x; 
	reg [1:0] state, next_state;
	reg signed [(fixedpoint_bit-1):0] regIn [0:(num_sample-1)];
	wire signed [(fixedpoint_bit-1):0] regOut [0:(num_sample-1)];
	wire signed [(fixedpoint_bit-1):0] grover_phaseInvert_out [0:(num_sample-1)];
	wire signed [(fixedpoint_bit-1):0] grover_invertMean_out [0:(num_sample-1)];
	reg [(num_bit-1):0] ite_counter; 
	reg [1:0] sel_regIn;

	//Convert fraction number to integer
	function integer getNumIte(logic [31:0] in);
	begin
		getNumIte = in;
	end
	endfunction
	
	//Initialization for equal probability
	wire signed [(fixedpoint_bit-1):0] grover_equalProb [0:(num_sample-1)];
	generate
	for (x = 0; x < num_sample; x = x + 1)
	begin:init_equalProb
		assign grover_equalProb [x] = equalProb;
	end:init_equalProb
	endgenerate

	//Shared registers for storage
	registers regGrover (.clk(clk), .rst(rst), .en(1'b1), .in(regIn), .out(regOut));
	defparam regGrover.sample_size = num_sample; defparam regGrover.complexnum_bit = fixedpoint_bit;
	
//	//Grover operator
//	grover_operator groverOp (.target_search(target_search), .phaseInvert_in(regOut), .invertMean(groverOp_out));
//	defparam groverOp.num_bit = num_bit; defparam groverOp.fixedpoint_bit = fixedpoint_bit; defparam groverOp.num_sample = num_sample; 
	
	//Grover Operator: Phase Inversion
	grover_phaseInvert groverOp1 (.target_search(target_search), .phaseInvert_in(regOut), .phaseInvert_out(grover_phaseInvert_out));
	defparam groverOp1.num_bit = num_bit; defparam groverOp1.fixedpoint_bit = fixedpoint_bit; defparam groverOp1.num_sample = num_sample;
	
	//Grover Operator: Inversion About Mean
	grover_invertMean groverOp2 (.phaseInvert_out(regOut), .invertMean(grover_invertMean_out));
	defparam groverOp2.num_bit = num_bit; defparam groverOp2.fixedpoint_bit = fixedpoint_bit; defparam groverOp2.num_sample = num_sample;

	assign output_r = regOut;
	
	//Iteration counter for FSM control
	always_ff@(posedge clk or posedge rst)
	begin
		if(rst)begin
			ite_counter = 'd0;
		end
		else begin
			case (state)
				0: ite_counter = 'd0;
				1: ite_counter = ite_counter;
				2: ite_counter = ite_counter + 'd1;
				3: ite_counter = ite_counter;
				default: ite_counter = ite_counter; 
			endcase
		end
	end
	
	//Multiplexer for shared registers inputs
	always_comb
	begin
		case (sel_regIn)
			0:	begin regIn <= grover_equalProb; end
			1: begin regIn <= grover_phaseInvert_out; end
			2: begin regIn <= grover_invertMean_out; end
			3: begin regIn <= regOut; end
			default:	begin regIn <= regOut; end
		endcase
	end
	
	//FSM for the serial control
	//For change of state
	always_ff@(posedge clk or posedge rst)
	begin
		if(rst)begin
			state <= 'd0;
		end
		else begin
			state <= next_state;
		end
	end
	
	//For control in each state
	always_comb
	begin
		case (state)
			0: begin done = 1'd0; sel_regIn = 2'd0; if(start) next_state = 2'd1; else next_state = 2'd0;  end
			1: begin done = 1'd0; sel_regIn = 2'd1; next_state = 2'd2;  end
			2: begin done = 1'd0; sel_regIn = 2'd2; if(ite_counter==(getNumIte(num_ite)-1)) next_state = 2'd3; else next_state = 2'd1; ; end
			3: begin done = 1'd1; sel_regIn = 2'd3; next_state = 2'd3;  end
			default: begin done = 1'd0; sel_regIn = 2'd3; next_state = 2'd0;  end
		endcase
	end
 
endmodule
