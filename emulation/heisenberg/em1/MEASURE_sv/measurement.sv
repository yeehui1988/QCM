module measurement #(parameter num_qubit = 4)(
input clk, input rst_new,
//input [1:0] gate_type, //0: Hadamard; 1: Phase; 2: CNOT; 3: Measurement
input [31:0] qubit_pos, 
input [1:0] literals_in [0:num_qubit-1], input phase_in, input valid_in,
output [1:0] literals_out [0:num_qubit-1], output phase_out, output reg valid_out,
output reg flag_anticommute
);

integer i,j;
reg [1:0] measure_literals [0:num_qubit-1][0:num_qubit-1]; reg measure_phase [0:num_qubit-1]; 
reg [1:0] measure_literals_select [0:num_qubit-1][0:num_qubit-1]; reg measure_phase_select [0:num_qubit-1]; 
reg [1:0] literals_basis [0:num_qubit-1]; reg phase_basis; reg [1:0] literals_mult [0:num_qubit-1]; reg phase_mult;
reg [1:0] literals_anticommute [0:num_qubit-1]; reg phase_anticommute; reg rst_flag; wire anticommute;
wire ld_measure; wire rst_anticommute;
reg shiftDown_rotateLeft; //0: Shift down; 1: Rotate left
reg [1:0] mux_measure; reg shiftDown_measure, rotateLeft_measure;
reg [2:0] state;
localparam [2:0] S0=3'd0, S1=3'd1, S2=3'd2, S3=3'd3, S4=3'd4, S5=3'd5, S6=3'd6, S7=3'd7;
reg [31:0] counter; reg [31:0] counter_rotateLeft;

/********************************************************REGISTER ARRAY**********************************************************/
assign ld_measure = shiftDown_measure | rotateLeft_measure;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		for (i=0; i<num_qubit; i=i+1) 	    //each row
		begin
			for (j=0; j<num_qubit; j=j+1)	//each column
			begin
				measure_literals[i][j] <= 2'd0;
			end
			measure_phase[i] <= 1'd0;	
		end
	end
	else
	begin
		i=0;j=0;
		if(ld_measure)
		begin
			measure_literals <= measure_literals_select;	measure_phase <= measure_phase_select;
		end
		else //Remain unchanged
		begin
			measure_literals <= measure_literals; measure_phase <= measure_phase;
		end
	end
end

assign literals_out = measure_literals [num_qubit-1]; assign phase_out = measure_phase [num_qubit-1];

/****************************************MUX TO SELECT INPUT TO REGISTER ARRAY******************************************/

always@(*)
begin
	if(rotateLeft_measure)
	begin
		shiftDown_rotateLeft <= 1'd1;
	end
	else
	begin
		shiftDown_rotateLeft <= 1'd0;
	end
end

always@(*)
begin
	if(shiftDown_rotateLeft == 1'd0) //Shift down
	begin
		i=0;j=0;
		case(mux_measure)
			2'd0: //Rotate down (Contents are not updated)
			begin
				measure_phase_select [0] <= measure_phase[num_qubit-1]; 
				measure_literals_select [0] <= measure_literals[num_qubit-1];
				for (i=1; i<num_qubit; i=i+1) 		//For each row
				begin
					measure_phase_select [i] <= measure_phase[i-1]; 
					measure_literals_select [i] <= measure_literals[i-1];
				end
			end
			2'd1: //Shift down (Take input from external)
			begin
				measure_phase_select [0] <= phase_in; 
				measure_literals_select [0] <= literals_in;
				for (i=1; i<num_qubit; i=i+1) 		//For each row
				begin
					measure_phase_select [i] <= measure_phase[i-1]; 
					measure_literals_select [i] <= measure_literals[i-1];
				end
			end
			2'd2: //Shift down (Take Zn literal row) => Measurement (Randomized)
			begin
				measure_phase_select [0] <= phase_basis; 
				measure_literals_select [0] <= literals_basis;
				for (i=1; i<num_qubit; i=i+1) 		//For each row
				begin
					measure_phase_select [i] <= measure_phase[i-1]; 
					measure_literals_select [i] <= measure_literals[i-1];
				end
			end
			2'd3: //Shift down (Take row mult output) => Measurement (Randomized - more than one anticommuting row)
			begin
				measure_phase_select [0] <= phase_mult; 
				measure_literals_select [0] <= literals_mult;
				for (i=1; i<num_qubit; i=i+1) 		//For each row
				begin
					measure_phase_select [i] <= measure_phase[i-1]; 
					measure_literals_select [i] <= measure_literals[i-1];
				end
			end
			default: //No change
			begin
				measure_phase_select <= measure_phase; measure_literals_select <= measure_literals;
			end
		endcase
	end
	else //Rotate left
	begin
		//Phases remain unchanged
		measure_phase_select <= measure_phase;
		//Literals rotate left
		for (i=0; i<num_qubit; i=i+1) 		        //For each row
		begin
			measure_literals_select [i][num_qubit-1] <= measure_literals [i][0];
			for (j=0; j<num_qubit-1; j=j+1) 	    //For each column
			begin
				measure_literals_select [i][j] <= measure_literals [i][j+1];
			end
		end
	end
end

//Measurement (Randomized outcome): mux_buffer -> 2
always@(posedge rst_new or posedge clk)
begin
	if(rst_new)
	begin
		phase_basis <= 1'd0;
		for (i=0; i<num_qubit; i=i+1)
		begin
			literals_basis[i] <= 2'd0;
		end
	end
	else
	begin
		//Measured column has been aligned to the left
		//Zn literals => Z ... In
		literals_basis[0] <= 2'd1; //Default set to Zn literal row
		for (i=1; i<num_qubit; i=i+1)
		begin
			literals_basis[i] <= 2'd0;
		end
		phase_basis <= 1'd1; //FOR NOW HARD-SET IT TO ONE(-) 
	end
end

//Measurement (Randomized outcome - more than one anticommuting row): mux_buffer -> 3
row_mult_single rm_anticommuting(.literals_in1(measure_literals[num_qubit-1]), .phase_in1(measure_phase[num_qubit-1]), 
.literals_in2(literals_anticommute), .phase_in2(phase_anticommute), .literals_out(literals_mult), 
.phase_out(phase_mult));
defparam rm_anticommuting.num_qubit = num_qubit;

/*******************************************************COMMUTATIVITY CHECK*******************************************************/
//Store first anticommuting row
assign rst_anticommute = rst_new | rst_flag;
assign anticommute = (measure_literals[num_qubit-1][0] > 2'd1)? 1'd1:1'd0; //X or Y literal at the aligned position => anticommute

always@(posedge clk or posedge rst_anticommute)
begin
	if(rst_anticommute)
	begin
		flag_anticommute <= 1'd0; phase_anticommute <= 1'd0;
		for (i=0; i<num_qubit; i=i+1)
		begin
			literals_anticommute[i] <= 2'd0;
		end
	end
	else
	begin
		i=0;
		//For the case of measurement gate
		if (anticommute && flag_anticommute == 1'd0 && state == S2) 
		begin
			literals_anticommute <= measure_literals[num_qubit-1];
			phase_anticommute <= measure_phase[num_qubit-1];
			flag_anticommute <= 1'd1;
		end
	end
end

/*****************************************************************FSM*****************************************************************/

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		state <= S0; counter <= 0; counter_rotateLeft <= 0;
	end	
	else
	begin
		case(state)
			S0: //Take input from external
			begin
				counter_rotateLeft <= 0;
				if(valid_in) 
				begin			
					counter <= counter + 1;
				end
				else
				begin
					counter <= counter;
				end
				if(counter == num_qubit-1)
				begin
					counter <= 32'd0;
					if(qubit_pos==0) //Target qubit already aligned to the left
					begin
						state <= S2; 
					end
					else
					begin
						state <= S1; 
					end
				end
				else
				begin
					state <= S0; 
				end
			end
			S1: //Align target qubit to the left
			begin
				counter <= 1'd0;
				if(counter_rotateLeft == qubit_pos)
				begin
					state <= S2; counter_rotateLeft <= counter_rotateLeft;
				end
				else
				begin
					state <= S1; counter_rotateLeft <= counter_rotateLeft+1;
				end
			end
			S2: //Rotate down one round for commutativity check
			begin
				counter_rotateLeft <= counter_rotateLeft;
				if(counter==num_qubit-1)
				begin
					counter <= 0;
					if(counter_rotateLeft == 0)
					begin
						state <= S4;
					end
					else
					begin
						state <= S3;
					end
				end
				else
				begin
					counter <= counter + 1;
					state <= S2;
				end
			end
			S3: //Rotate left to ensure literals are back to order
			begin
				counter <= 0;
				if(counter_rotateLeft == num_qubit-1)
				begin
					state <= S4; counter_rotateLeft <= 0;
				end
				else
				begin
					state <= S3; counter_rotateLeft <= counter_rotateLeft+1;
				end
			end
			S4:
			begin
				counter_rotateLeft <= 0;
				if(counter==num_qubit-1)
				begin
					state <= S0; counter <= 0;
				end
				else
				begin
					state <= S4; counter <= counter + 1;
				end
			end
			default:
			begin
				state <= S0; counter <= 0; counter_rotateLeft <= 0;
			end
		endcase
	end
end
			
always@(*)
begin
	case(state)
		S0: //Take input from external
		begin
			valid_out <= 1'd0; shiftDown_measure <= 1'd0; rotateLeft_measure <= 1'd0; mux_measure <= 2'd0; rst_flag <= 1'd0;
			if(valid_in) 
			begin			
				shiftDown_measure <= 1'd1; mux_measure <= 2'd1; //Take input from external
			end
			if(counter == num_qubit-1 && qubit_pos==0)          //Target qubit already aligned to the left
			begin
				rst_flag <= 1'd1;
			end
		end
		S1: //Align target qubit to the left
		begin
			valid_out <= 1'd0; shiftDown_measure <= 1'd0; rotateLeft_measure <= 1'd0; mux_measure <= 2'd0; rst_flag <= 1'd0;
			if(counter_rotateLeft != qubit_pos)
			begin
				rotateLeft_measure <= 1'd1;
			end
			else
			begin
				rst_flag <= 1'd1;
			end
		end
		S2: //Rotate down one round for commutativity check
		begin
			valid_out <= 1'd0; rotateLeft_measure <= 1'd0; mux_measure <= 2'd0; rst_flag <= 1'd0;
			shiftDown_measure <= 1'd1; 
			if(anticommute)
			begin
				if(flag_anticommute)
				begin
					mux_measure <= 2'd3; //Replace with row mult with first anticommuting row
				end
				else
				begin
					mux_measure <= 2'd2; //Replace with Zn	
				end
			end
			else
			begin
				mux_measure <= 2'd0; //Rotate down
			end
		end
		S3: //Rotate left to ensure literals are back to order
		begin
			valid_out <= 1'd0; shiftDown_measure <= 1'd0; mux_measure <= 2'd0; rst_flag <= 1'd0;
			rotateLeft_measure <= 1'd1; 
		end
		S4:
		begin
			rotateLeft_measure <= 1'd0; rst_flag <= 1'd0;
			valid_out <= 1'd1; shiftDown_measure <= 1'd1; mux_measure <= 2'd0; 
		end
		default:
		begin
			valid_out <= 1'd0; shiftDown_measure <= 1'd0; rotateLeft_measure <= 1'd0; mux_measure <= 2'd0; rst_flag <= 1'd0;
		end
	endcase
end
			
endmodule 
