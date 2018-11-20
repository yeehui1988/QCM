module commutativity_literal #(parameter num_qubit = 3, max_vector = 2**num_qubit)(
input clk, input rst, input rst_flag,
input [1:0] literals_in [0:num_qubit-1], input phase_in [0:max_vector-1], //from external module
input [2:0] mux_shift_in, 
input [1:0] literals_shift_out [0:num_qubit-1], input phase_shift_out [0:max_vector-1],
output reg [1:0] literals_shift_in [0:num_qubit-1], output reg phase_shift_in [0:max_vector-1], 
output reg flag_anticommute, output anticommute,
output reg [1:0] literals_anticommute [0:num_qubit-1], output reg phase_anticommute [0:max_vector-1],
//For Toffoli Update:
input flag_nonstabilizer_update [0:max_vector-1]
);

integer i;

/****************************************MUX TO SELECT INPUT TO REGISTER ARRAY******************************************/
//0: No changes. 
wire [1:0] literals_shift_in_remain [0:num_qubit-1]; wire phase_shift_in_remain [0:max_vector-1]; 
//1: Zn...I (assume horizontal rotation has been performed to align cofactor column to the left), modify phase
reg [1:0] literals_shift_in_basis [0:num_qubit-1]; reg phase_shift_in_basis [0:max_vector-1]; 
//2: Mult output of first anticommuting & the other(s) if applicable
wire [1:0] literals_shift_in_mult [0:num_qubit-1]; wire phase_shift_in_mult [0:max_vector-1]; 
//3: Input for external module (from cofactor module itself or canonical module)
wire [1:0] literals_shift_in_external [0:num_qubit-1]; wire phase_shift_in_external [0:max_vector-1]; 
//4: For Toffoli gate update (Update flagged phase)
reg phase_shift_in_toffoli [0:max_vector-1]; reg phase_shift_in_toggle [0:max_vector-1];

always@(*)
begin
	case (mux_shift_in)
		3'd0:
		begin
			literals_shift_in <= literals_shift_in_remain;
			phase_shift_in <= phase_shift_in_remain;
		end
		3'd1:
		begin
			literals_shift_in <= literals_shift_in_basis;
			phase_shift_in <= phase_shift_in_basis;
		end
		3'd2:
		begin
			literals_shift_in <= literals_shift_in_mult;
			phase_shift_in <= phase_shift_in_mult;
		end
		3'd3:
		begin
			literals_shift_in <= literals_shift_in_external;
			phase_shift_in <= phase_shift_in_external;
		end
		3'd4: //Toffoli gate update
		begin
			literals_shift_in <= literals_shift_in_remain;
			phase_shift_in <= phase_shift_in_toffoli;
		end
		default:
		begin
			literals_shift_in <= literals_shift_in_remain;
			phase_shift_in <= phase_shift_in_remain;
		end
	endcase
end

//For 0: Take output from register array. Remain unchanged
assign literals_shift_in_remain = literals_shift_out; assign phase_shift_in_remain = phase_shift_out;

//For 1: Zn literal row for replacement on flag anticommuting row
//Phase vector update will be manage by a separate module
always@(*)
begin
	//Cofactor column has been aligned to the left
	//Zn literals => Z ... In
	literals_shift_in_basis[0] <= 2'd1; //Default set to Zn literal row
	for (i=1; i<num_qubit; i=i+1)
	begin
		literals_shift_in_basis[i] <= 2'd0;
	end
	phase_shift_in_basis <= phase_shift_out;
end

//For 2: Row mult to eliminate anticommuting row (if more than one exist)
row_mult_multiple rm_cofactor(.literals_in1(literals_shift_out), .phase_in1(phase_shift_out), 
.literals_in2(literals_anticommute), .phase_in2(phase_anticommute), .literals_out(literals_shift_in_mult), 
.phase_out(phase_shift_in_mult));
defparam rm_cofactor.num_qubit = num_qubit; defparam rm_cofactor.max_vector = max_vector;

//For 3: Input for external module (from cofactor module itself or canonical module)
assign literals_shift_in_external = literals_in; assign phase_shift_in_external = phase_in; 

//For 4: Toffoli gate, toggle flagged phase
always@(*)
begin
	for (i=0; i<max_vector; i=i+1)
	begin
		if(phase_shift_out[i])
		begin
			phase_shift_in_toggle[i] <= 1'd0;
		end
		else
		begin
			phase_shift_in_toggle[i] <= 1'd1;
		end
	end
end

always@(*)
begin
	for (i=0; i<max_vector; i=i+1)
	begin
		if(flag_nonstabilizer_update[i])
		begin
			phase_shift_in_toffoli[i] <= phase_shift_in_toggle[i];  //Toggle
		end
		else
		begin
			phase_shift_in_toffoli[i] <= phase_shift_out[i];		//Remain unchanged
		end
	end
end

/*************************************REGISTER TO STORE FIRST ANTICOMMUTING ROW************************************/
//To be used to make other anticommuting row (if any) by row multiplication
//Phase vector to be used as reference for storing basis index for amplitude extraction (randomized outcome)
wire rst_anticommute;

assign rst_anticommute = rst | rst_flag;
assign anticommute = (literals_shift_out[0] > 2'd1)? 1'd1:1'd0; //X or Y literal at the aligned position => anticommute

always@(posedge clk or posedge rst_anticommute)
begin
	if(rst_anticommute)
	begin
		for (i=0; i<num_qubit; i=i+1)
		begin
			literals_anticommute[i] <= 2'd0;
		end
		for (i=0; i<max_vector; i=i+1)
		begin
			phase_anticommute [i] <= 1'd0;
		end
		flag_anticommute <= 1'd0;
	end
	else
	begin
		i=0;
		if (anticommute && flag_anticommute == 1'd0) 
		begin
			literals_anticommute <= literals_shift_out;
			phase_anticommute <= phase_shift_out;
			flag_anticommute <= 1'd1;
		end
	end
end

endmodule
