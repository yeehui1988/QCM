module register_array_stabilizer #(parameter num_qubit = 4, max_vector = 2**num_qubit)(
input clk, input rst, 
//Output from cofactor module to use register array as buffer:
input valid_out_individual_cofactor, input ready_cofactor, input mask_valid_buffer,
input [1:0] literals_out_individual_cofactor [0:num_qubit-1], input phase_out_individual_cofactor [0:max_vector-1],
output valid_out_buffer, output valid_P_nonstabilizer_intermediate, output valid_out_nonstabilizer_buffer, input valid_out_canonical_mask,
//Output from canonical reduction for beta operation:
input [1:0] literals_out_canonical [0:num_qubit-1], input phase_out_canonical [0:2**num_qubit-1], 
//Rotate out stabilizer operation output:
input valid_out_stabilizer,
//To determine productQ during stabilizer beta operation:
input rotateLeft_reg_beta, input rotateDown_reg_beta,
//Output from stabilizer register array for (a) Intermediate buffer output in nonstabilizer operation (b) After stabilizer operation is completed
output [1:0] literals_out_stabilizer [0:num_qubit-1], output phase_out_stabilizer [0:max_vector-1],
//For debugging:
output reg [1:0] literal_reg [0:num_qubit-1][0:num_qubit-1],	//[row][column]
output reg phase_reg [0:num_qubit-1][0:max_vector-1] 			//[row_index][pair_index] 
);

integer i, j;
wire ld_reg; reg shift_rotate_array; 
reg [1:0] select_literals_in [0:num_qubit-1]; reg select_phase_in [0:max_vector-1]; reg valid_out_buffer_pre;

/**********************************************MUX TO SELECT INPUT TO REGISTER ARRAY***************************************************/
assign ld_reg = valid_out_individual_cofactor | valid_out_buffer_pre | valid_out_canonical_mask | valid_out_stabilizer | rotateLeft_reg_beta | rotateDown_reg_beta;
assign valid_out_nonstabilizer_buffer = (valid_out_buffer_pre==1'd1) && (valid_out_buffer==1'd0); //final nonstabilizer output after buffer

//For shift down or rotate down
always@(*)
begin
	//Take input from cofactor module for buffer purposes
	if(valid_out_individual_cofactor) //Buffer: Shift in
	begin
		select_literals_in <= literals_out_individual_cofactor; select_phase_in <= phase_out_individual_cofactor;
	end
	else if(valid_out_canonical_mask) //Stabilizer operation from canonical: Shift in
	begin
		select_literals_in <= literals_out_canonical; select_phase_in <= phase_out_canonical;
	end
	//ADD MORE CASES LATER
	//Default Rotate down
	else //(valid_out_buffer_pre || valid_out_stabilizer || rotateDown_reg_beta)
	begin
		select_literals_in <= literal_reg [num_qubit-1]; select_phase_in <= phase_reg[num_qubit-1];
	end
end

always@(*)
begin
	if(valid_out_individual_cofactor | valid_out_buffer_pre | valid_out_canonical_mask | valid_out_stabilizer | rotateDown_reg_beta)
	begin
		shift_rotate_array <= 1'd0;
	end
	else //(rotateLeft_reg_beta)
	begin
		shift_rotate_array <= 1'd1;
	end
end

/**************************************REGISTERS TO STORE STABILIZER MATRIX (LITERALS & PHASES)****************************************/
//Case 1: Use as buffer registers for nonstabilizer gate operation (input from cofactor module)
//Case 2: Use as register arrays for stabilizer beta operation (input from cba+canonical module)

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0; i<num_qubit; i=i+1) 		    //each row
		begin
			for (j=0; j<num_qubit; j=j+1)		//each column
			begin
				literal_reg [i][j] <= 2'd0;
			end
			for (j=0; j<max_vector; j=j+1)	    //each vector pair
			begin
				phase_reg [i][j] <= 1'd0;
			end
		end
	end
	else
	begin
		i=0;j=0;
		if(ld_reg)
		begin
			//0: Shift down (both literals & phases), input control from outer module
			if(shift_rotate_array==1'd0)
			begin
				literal_reg [0] <= select_literals_in;
				phase_reg [0] <= select_phase_in;
				for (i=1; i<num_qubit; i=i+1)       //For each row
				begin
					literal_reg [i] <= literal_reg [i-1];
					phase_reg [i] <= phase_reg [i-1];
				end
			end
			//1: Rotate left (literals only) 
			else 
			begin
				phase_reg <= phase_reg;
				for (i=0; i<num_qubit; i=i+1) 		//For each row
				begin
					literal_reg [i][num_qubit-1] <= literal_reg [i][0];
					for (j=0; j<num_qubit-1; j=j+1) //For each column
					begin
						literal_reg [i][j] <= literal_reg [i][j+1];
					end
				end
			end
		end
		else
		begin
			literal_reg <= literal_reg; phase_reg <= phase_reg;
		end
	end
end

//Connect the last row out for processing
assign literals_out_stabilizer = literal_reg [num_qubit-1];
assign phase_out_stabilizer = phase_reg [num_qubit-1];

/***********************FSM FOR CONTROL OF THE USAGE OF REGISTER ARRAY AS BUFFER BETWEEN COFACTOR OPERATION*************************/
reg state_buffer; reg [31:0] counter_valid_buffer; 
localparam SB0 = 1'd0, SB1 = 1'd1;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state_buffer <= SB0; counter_valid_buffer <= 32'd0;
		valid_out_buffer_pre <= 1'd0;
	end
	else
	begin
		case(state_buffer)
			SB0:
			begin
				if(valid_out_individual_cofactor)
				begin
					counter_valid_buffer <= counter_valid_buffer + 1;
				end
				else
				begin
					counter_valid_buffer <= counter_valid_buffer;
				end
				if(counter_valid_buffer == num_qubit & ready_cofactor)
				begin
					state_buffer <= SB1; counter_valid_buffer <= 1; valid_out_buffer_pre <= 1'd1;
				end
				else
				begin
					state_buffer <= SB0; valid_out_buffer_pre <= 1'd0;
				end
			end
			SB1:
			begin
				if(counter_valid_buffer == num_qubit) 
				begin
					state_buffer <= SB0; counter_valid_buffer <= 32'd0; valid_out_buffer_pre <= 1'd0; 	 
				end
				else
				begin
					state_buffer <= SB1; counter_valid_buffer <= counter_valid_buffer + 1; valid_out_buffer_pre <= 1'd1;
				end
			end
		endcase
	end
end

assign valid_P_nonstabilizer_intermediate = (state_buffer == SB1 && counter_valid_buffer == num_qubit && mask_valid_buffer)? 1'd1: 1'd0;
assign valid_out_buffer = valid_out_buffer_pre && mask_valid_buffer;

endmodule 
