module canonical_modular #(parameter num_qubit = 4, pivot_position = 0, block_type = 0)( 
//block_type: 0 for X-block; 1 for Z-block
//pivot_position: according to the row index of the respective block
input clk,
input rst_new,
input ld_trans,
input ld_store,
input second_CR,
input [1:0] literals_trans_in [0:num_qubit-1],
input phase_trans_in,
input flag_in, input second_stage,			
output reg [1:0] store_literal_output [0:num_qubit-1], output reg store_phase_output, output reg store_flag_output,			
output [1:0] trans_literal_retain_out[0:num_qubit-1], 
output trans_phase_retain_out, 		
output flag_retain_out,						
output [1:0] literals_trans_out [0:num_qubit-1],
output phase_trans_out,
output flag_out
);

/*********************************************VARIABLE INSTANTIATION*********************************************/
reg [1:0] store_literal_input [0:num_qubit-1];
reg [1:0] trans_literal_output [0:num_qubit-1];
reg [1:0] trans_literal_mux [0:num_qubit-1];
reg store_phase_input, trans_phase_output, trans_phase_mux;
reg store_flag_input, trans_flag_output, trans_flag_mux;
reg [1:0] sel_store;
reg [1:0] sel_trans;
wire [1:0] literal_mult [0:num_qubit-1];
wire phase_mult, pivot, occupy;
integer i;

/*********************************************PIVOT & OCCUPY SIGNAL*********************************************/
//Check if pivot condition is fulfilled for transition registers
//X or Y literal for X-block; Z literal for Z-block
assign pivot = ((trans_literal_output[pivot_position] > 2'd1 & block_type == 32'd0) || 
((trans_literal_output[pivot_position] == 2'd1 || trans_literal_output[pivot_position] == 2'd3) & 
block_type == 32'd1))? 1'd1: 1'd0; 
//To keep track if the storage register is occupied. 
assign occupy = store_flag_output;

/*****************************************TRANSITION & STORAGE REGISTERS*****************************************/
//Registers for transition & registers for storage
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0; i<num_qubit; i=i+1) 
		begin
			store_literal_output[i] <= 2'd0;
			trans_literal_output[i] <= 2'd0;	
		end
		store_phase_output <= 1'd0;
		trans_phase_output <= 1'd0;
		store_flag_output <= 1'd0;
		trans_flag_output <= 1'd0;
	end
	else
	begin
		i=0;
		if(ld_store)
		begin
			store_literal_output <= store_literal_input;
			store_phase_output <= store_phase_input;
			store_flag_output <= store_flag_input;
		end
		if(ld_trans)
		begin
			trans_literal_output <= literals_trans_in; 
			trans_phase_output <= phase_trans_in; 
			trans_flag_output <= flag_in; 
		end
	end
end

//Pull signals out as output
assign trans_literal_retain_out = trans_literal_output; 
assign trans_phase_retain_out = trans_phase_output; 
assign flag_retain_out = trans_flag_output; 

/*****************************************INPUT TO STORAGE REGISTERS*****************************************/
//Multiplexer for input to storage registers
always@(*)
begin
	//Literals row will be stored in storage registers
	if(occupy == 1'd0 && pivot == 1'd1 && second_stage == 1'd0)
	begin
		sel_store = 2'd0;
	end
	else if(second_CR == 1'd1) //For Round 2 shift literals, phase & flag out from storage register
	begin
		sel_store = 2'd1;
	end
	else 
	begin
		sel_store = 2'd2;
	end
end

always@(*)
begin
	case(sel_store)
		2'd0: //occupy == 1'd0 && pivot == 1'd1
		begin
			i=0;
			store_literal_input <= trans_literal_output;
			store_phase_input <= trans_phase_output;
			store_flag_input <= trans_flag_output;
		end
		2'd1: //second_CR == 1'd1: Clear data in storage register 
		begin
			for (i=0; i<num_qubit; i=i+1) 
			begin
				store_literal_input[i] <= 2'd0;
			end
			store_phase_input <= 1'd0;
			store_flag_input <= 1'd0;
		end
		default: //For other case(s): Retain
		begin
			i=0;
			store_literal_input <= store_literal_output;
			store_phase_input <= store_phase_output;
			store_flag_input <= store_flag_output;
		end
	endcase
end

/***********************************************ROW MULTIPLICATION***********************************************/
//Output from row mult module
row_mult_single rm1(.literals_in1(store_literal_output), .phase_in1(store_phase_output), 
.literals_in2(trans_literal_output), .phase_in2(trans_phase_output), .literals_out(literal_mult), 
.phase_out(phase_mult));
defparam rm1.num_qubit = num_qubit;

/*****************************************INPUT TO TRANSITION REGISTERS*****************************************/
//Multiplexer for transition output (output of the mux would be output signal of this module)
always@(*)
begin
	//Select from storage registers
	if(second_CR == 1'd1)
	begin
		sel_trans <= 2'd0;
	end
	//Select row multiplication output (row_trans * row_storage)
	else if(occupy == 1'd1 && pivot == 1'd1)
	begin
		sel_trans <= 2'd1;
	end
	//Select from previous trans registers (shift down) 
	else if(pivot == 1'd0 | second_stage == 1'd1)
	begin
		sel_trans <= 2'd2;
	end
	//Retain the original value of the registers
	//Applied to the case of pivot and !occupy, literal will be loaded to storage registers instead
	//These signals are coming from the module at the bottom to retain the value of the registers
	else
	begin
		sel_trans <= 2'd3;
	end
end

always@(*)
begin
	case(sel_trans)
		2'd0: //second_CR == 1'd1
		begin
			i=0;
			trans_literal_mux <= store_literal_output;	
			trans_phase_mux <= store_phase_output;
			trans_flag_mux <= store_flag_output;
		end
		2'd1: //occupy == 1'd1 && pivot == 1'd1
		begin
			i=0;
			trans_literal_mux <= literal_mult;
			trans_phase_mux <= phase_mult;
			trans_flag_mux <= trans_flag_output;
		end
		2'd2: //pivot == 1'd0
		begin
			i=0;
			trans_literal_mux <= trans_literal_output;
			trans_phase_mux <= trans_phase_output;
			trans_flag_mux <= trans_flag_output;
		end
		2'd3: //For other case(s): occupy == 1'd1 && pivot == 1'd1 => literals & phase are moved to storage registers
		begin
			for (i=0; i<num_qubit; i=i+1) 
			begin
				trans_literal_mux[i] <= 2'd0;
			end
			trans_phase_mux <= 1'd0;
			trans_flag_mux <= 1'd0;		
		end
	endcase
end

assign literals_trans_out = trans_literal_mux;
assign phase_trans_out = trans_phase_mux;
assign flag_out = trans_flag_mux;

endmodule
