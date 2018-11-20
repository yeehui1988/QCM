module register_array_cba #(parameter num_qubit = 4)(
//General:
input clk,
input rst,
//Input:
input ld_literal, input ld_phase[0:num_qubit-1],
input shift_rotate_literal, 	//0: shift down; 1: rotate left
input shift_toggle_phase, 		//0: shift down; 1: toggle; 
input [1:0] literals_in [0:num_qubit-1], input phase_in,
input rotate_update_literal,    //Mux to select input to right input of literal registers: 0: rotate; 1: update
input [1:0] update_literal [0:num_qubit-1],
//Output
output [1:0] left_out [0:num_qubit-1], 	//[row] => output from literal registers during rotate left operation
output [1:0] literals_out [0:num_qubit-1],
output phase_out
);

integer i, j;
genvar k;

/**************************************************LITERAL REGISTERS**************************************************/
reg [1:0] bidirect_reg [0:num_qubit-1][0:num_qubit-1];      //[row][column]
reg [1:0] bidirect_reg_pre [0:num_qubit-1][0:num_qubit-1];  //[row][column]
wire [1:0] right_in [0:num_qubit-1];    //[row] => input to literal registers during rotate left operation

//For literal registers
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		//Reset all to 0 => I
		for (i=0; i<num_qubit; i=i+1) 	    //each row 
		begin
			for (j=0; j<num_qubit; j=j+1)   //each column
			begin
				bidirect_reg [i][j] <= 2'd0;
			end
		end
	end
	else
	begin
		i=0;j=0;
		if(ld_literal == 1'd1)
		begin
			bidirect_reg <= bidirect_reg_pre;
		end	
	end
end

//Pull out wires from left most column of bidirect_reg => For rotate left function
generate
for (k=0; k<num_qubit; k=k+1) 
begin: left_output
	assign left_out [k] = bidirect_reg [k][0];
end: left_output
endgenerate

//Mux to select input to right most column of bidirect_reg (rotate left function)
generate
for (k=0; k<num_qubit; k=k+1) 
begin: rotate_update_mux
	assign right_in [k] = (rotate_update_literal==1'd0)? left_out [k]: update_literal[k]; //0: Rotate; 1: Update
end: rotate_update_mux
endgenerate

/*******************************************MUX FOR LITERALS INPUT SELECTION******************************************/
always@(*)
begin
	//Shift Down
	if(shift_rotate_literal == 1'd0) 
	begin
		j = 0;
		bidirect_reg_pre [0] <= literals_in; 		
		for (i=1; i<num_qubit; i=i+1) 	        //each row 
		begin
			bidirect_reg_pre [i] <= bidirect_reg [i-1]; 
		end
	end
	//Rotate Left
	else 
	begin
		for (i=0; i<num_qubit; i=i+1)           //each row 
		begin
			bidirect_reg_pre [i][num_qubit-1] <= right_in[i];
			for (j=0; j<(num_qubit-1); j=j+1)   //each column
			begin
				bidirect_reg_pre [i][j] <= bidirect_reg [i][j+1];
			end
		end
	end
end

/**************************************************PHASE REGISTERS**************************************************/
//For phase registers
reg phase_reg [0:num_qubit-1];	    //[row]
reg phase_reg_pre [0:num_qubit-1];	//[row]	

//For phase registers
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0; i<num_qubit; i=i+1) 	//each row 
		begin
			phase_reg [i] <= 1'd0; 
		end
	end
	else
	begin
		for (i=0; i<num_qubit; i=i+1) 	//each row 
		begin
			if(ld_phase [i] == 1'd1) 
			begin	
				phase_reg [i] <= phase_reg_pre[i];
			end
			else
			begin	
				phase_reg [i] <= phase_reg [i];
			end
		end
	end
end

//Mux to select input to phase registers
always@(*)
begin
	//Shift Down
	if(shift_toggle_phase == 1'd0) 
	begin
		phase_reg_pre [0] <= phase_in;
		for (i=1; i<num_qubit; i=i+1) //each row 
		begin
			phase_reg_pre [i] <= phase_reg [i-1];
		end
	end
	//Toggle Phase
	else 
	begin
		for (i=0; i<num_qubit; i=i+1) //each row 
		begin
			phase_reg_pre [i] <= ~phase_reg [i];
		end
	end
end

//Assign to output for readout
assign literals_out = bidirect_reg[num_qubit-1];
assign phase_out = phase_reg[num_qubit-1]; 


endmodule
