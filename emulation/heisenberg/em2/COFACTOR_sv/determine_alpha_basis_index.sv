module determine_alpha_basis_index #(parameter num_qubit = 4, max_vector = 2**num_qubit)(
input clk, input rst,
//For literals_P & phase_P:
//Share between cofactor and global phase modules. 
input [1:0] literals_P_in [0:max_vector-1][0:num_qubit-1], input valid_P, 
//Anticommute literals & phase has been aligned with cofactor column to the left
input [1:0] literals_anticommute [0:num_qubit-1], input phase_anticommute [0:2**num_qubit-1], input valid_flag_anticommute, input flag_anticommute,
input [31:0] reg_cofactor_pos, //input ld_cofactor_info, 
input [num_qubit-1:0] read_alpha_address, 
output [1:0] alpha1_out_r, output [1:0] alpha1_out_i, output [1:0] alpha2_out_r, output [1:0] alpha2_out_i,
//For basis index:
input valid_index_readout, input valid_second_round, input ld_rotateLeft_basis, 
output reg basis_index [0:max_vector-1][0:num_qubit-1],
//Move amplitude cofactor module to more top level
output reg determine_amplitude, output reg [1:0] literals_Q [0:max_vector-1][0:num_qubit-1], output reg phase_Q [0:max_vector-1],
input done_amplitude, input ld_rotateLeft, input ld_PQ_list1_amp, input [1:0] amplitude_r_Q_out, input [1:0] amplitude_i_Q_out,
input write_alpha_enable, input [num_qubit-1:0] write_alpha_address,
//For beta:
input [1:0] literals_out [0:num_qubit-1], input phase_out [0:2**num_qubit-1], input update_flag_basis, input ld_prodQ, input rotateLeft_Q_beta, 
input rotateLeft_flag_basis,
//For nonstabilizer:
input flag_cofactor [0:num_qubit-1], input rotateLeft_P_nonstabilizer, input valid_P_nonstabilizer, output reg flag_nonstabilizer_update [0:max_vector-1],
input rotateLeft_flag_nonstabilizer_update, input phaseShift_toffoli,
//For stabilizer:
output basis_index_in [0:num_qubit-1], 
output ld_basis, //for basis index list 2
input write_amplitude1_enable, input [7:0] write_amplitude1,
input rotateLeft_stabilizer_basis, input basis_stabilizer [0:num_qubit-1], output basis_index_leftmost [0:num_qubit-1],
input [num_qubit-1:0] read_ram_alpha_stabilizer_address, input read_ram_alpha_stabilizer_en, output [7:0] read_alpha_out,
//For stabilizer beta: Determine productQ 
input [1:0] literals_out_stabilizer [0:num_qubit-1], input phase_out_stabilizer [0:2**num_qubit-1], input valid_P_stabilizer,
input ld_prodQ_stabilizer, input rotateLeft_Q_flag_basis_stabilizer
);

integer i, j;

reg [1:0] literals_P [0:max_vector-1][0:num_qubit-1]; 
wire [1:0] literals_P_anticommute [0:max_vector-1][0:num_qubit-1]; wire phase_P_anticommute [0:max_vector-1];
wire [1:0] literals_prodQ_cofactor [0:max_vector-1][0:num_qubit-1]; wire phase_prodQ_cofactor [0:max_vector-1];
wire [1:0] literals_prodQ_stabilizer [0:max_vector-1][0:num_qubit-1]; wire phase_prodQ_stabilizer [0:max_vector-1];

reg [1:0] select_literals_P [0:max_vector-1][0:num_qubit-1]; reg [1:0] mux_P; wire ld_P, ld_P1, ld_P2;
reg [1:0] select_literals_Q [0:max_vector-1][0:num_qubit-1]; reg select_phase_Q [0:max_vector-1]; reg [2:0] mux_Q; wire ld_Q, ld_Q1, ld_Q2; 
//Create duplication list to avoild parallel access error 
reg PQ_list [0:max_vector-1]; wire ld_PQ_list; reg select_PQ_list [0:max_vector-1]; reg mux_PQ_list; wire ld_PQ_list1;
reg PQ_list_basis [0:max_vector-1]; wire ld_PQ_list_basis; reg select_PQ_list_basis [0:max_vector-1]; reg mux_PQ_list_basis; wire ld_PQ_list1_basis;
reg [7:0] write_alpha; //wire [7:0] read_alpha_out;
reg basis_list1 [0:num_qubit-1]; reg basis_list2 [0:num_qubit-1]; reg basis_fifo [0:num_qubit-1]; 
reg select_basis_index [0:max_vector-1][0:num_qubit-1]; reg [2:0] mux_basis_index; 

//For beta:
reg flag_basis [0:max_vector-1][0:num_qubit-1]; 

//For nonstabilizer update:
reg select_nonstabilizer;
reg literals_P_msb [0:max_vector-1][0:num_qubit-1]; //only take the MSB of P

//For basis index list 2:
assign basis_index_in = select_basis_index[max_vector-1];

always@(*)
begin
	for (i=0;i<max_vector;i=i+1)
	begin
		for (j=0;j<num_qubit;j=j+1)
		begin
			literals_P_msb[i][j] <= literals_P[i][j][1];
		end
	end
end


always@(*)
begin
	select_nonstabilizer = 1'd1;
	for (i=0;i<num_qubit;i=i+1)
	begin
		if(flag_cofactor[i]==1'd1 && literals_P_msb[0][i]==1'd0)
		begin
			select_nonstabilizer = select_nonstabilizer & 1'd0;
		end
		else
		begin
			select_nonstabilizer = select_nonstabilizer & 1'd1;
		end
	end
end		

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0;i<max_vector;i=i+1)
		begin
			flag_nonstabilizer_update [i] <= 1'd0; 
		end
	end
	else
	begin	
		if(rotateLeft_P_nonstabilizer)
		begin
			flag_nonstabilizer_update [max_vector-1] <= select_nonstabilizer;
			for (i=0;i<max_vector-1;i=i+1)
			begin
				flag_nonstabilizer_update [i] <= flag_nonstabilizer_update [i+1]; 
			end
		end
		else if(rotateLeft_flag_nonstabilizer_update)
		begin
			flag_nonstabilizer_update [max_vector-1] <= flag_nonstabilizer_update [0];
			for (i=0;i<max_vector-1;i=i+1)
			begin
				flag_nonstabilizer_update [i] <= flag_nonstabilizer_update [i+1]; 
			end
		end
		else
		begin
			flag_nonstabilizer_update <= flag_nonstabilizer_update;
		end
	end
end

/*******************************************REGISTER TO STORE P & Q & PQ LIST & BASIS INDEX*******************************************/

//mux_P: 0: Load from external; 1: Rotate left (individual literals); 
always@(*)
begin
	case (mux_P)
		2'd0: //0: Load from external
		begin
			i=0;j=0;
			select_literals_P <= literals_P_in;
		end
		2'd1: //1: Rotate left (individual literals)
		begin
			for (i=0; i<max_vector; i=i+1)      //Each phase pair
			begin
				select_literals_P [i][num_qubit-1] <= literals_P [i][0];    //[pair_index][literal_index]
				for (j=0; j<num_qubit-1; j=j+1) //Each literal in each phase pair
				begin
					select_literals_P [i][j] <= literals_P [i][j+1];        //[pair_index][literal_index]
				end
			end
		end
		2'd2: //2: Rotate left (individual P)
		begin
			j=0;
			select_literals_P [max_vector-1] <= literals_P [0];
			for (i=0; i<max_vector-1; i=i+1)    //Each phase pair
			begin
				select_literals_P [i] <= literals_P [i+1];
			end
		end
		default: //Remain unchanged
		begin
			select_literals_P <= literals_P;
		end
	endcase 
end

//mux_Q: 0: Load from P x anticommute (for alpha); 1: Rotate left (individual literals); 
always@(*)
begin
	case (mux_Q)
		3'd0: //0: Load from P x anticommute
		begin
			i=0;j=0;
			select_literals_Q <= literals_P_anticommute; select_phase_Q <= phase_P_anticommute;
		end
		3'd1: //1: Rotate left (individual literals)
		begin
			select_phase_Q <= phase_Q; //Phase remains unchanged
			for (i=0; i<max_vector; i=i+1) //Each phase pair
			begin
				select_literals_Q [i][num_qubit-1] <= literals_Q [i][0];    //[pair_index][literal_index]
				for (j=0; j<num_qubit-1; j=j+1)	//Each literal in each phase pair
				begin
					select_literals_Q [i][j] <= literals_Q [i][j+1];        //[pair_index][literal_index]
				end
			end
		end
		3'd2: //2: Rotate left (individual Q)
		begin
			select_literals_Q [max_vector-1] <= literals_Q [0]; j=0;
			select_phase_Q [max_vector-1] <= phase_Q [0];
			for (i=0; i<max_vector-1; i=i+1) //Each phase pair
			begin
				select_literals_Q [i] <= literals_Q [i+1];
				select_phase_Q [i] <= phase_Q [i+1];
			end
		end
		3'd3: //Load P into Q when valid P (for alpha case it will be overwritten by the correct content later)
		begin
			select_literals_Q <= literals_P_in; j=0;
			for (i=0; i<max_vector; i=i+1) //Each phase pair
			begin
				select_phase_Q[i] <= 1'd0;
			end
		end
		3'd4: //Update Q with product of Q and literals out
		begin
			j=0;
			for (i=0; i<max_vector; i=i+1) //Each phase pair
			begin
				if(flag_basis[i][0]) //Flagged
				begin
					select_literals_Q[i] <= literals_prodQ_cofactor[i]; select_phase_Q [i] <= phase_prodQ_cofactor[i];
				end
				else
				begin
					select_phase_Q[i] <= phase_Q[i]; select_literals_Q[i] <= literals_Q[i];
				end
			end
		end
		3'd5: //Update Q with product of Q and literals out (stabilizer beta operation)
		begin
			j=0;
			for (i=0; i<max_vector; i=i+1) //Each phase pair
			begin
				if(flag_basis[i][0]) //Flagged
				begin
					select_literals_Q[i] <= literals_prodQ_stabilizer[i]; select_phase_Q [i] <= phase_prodQ_stabilizer[i];
				end
				else
				begin
					select_phase_Q[i] <= phase_Q[i]; select_literals_Q[i] <= literals_Q[i];
				end
			end
		end
		default: //Remain unchanged
		begin
			i=0;j=0;
			select_literals_Q <= literals_Q; select_phase_Q <= phase_Q; //Remain unchanged
		end
	endcase 
end

//mux_PQ_list: 0: Based on P[cofactor_qubit] & anticommuting phase, determine P or Q go to list 1 & 2, respectively; 1: Rotate left individual
always@(*)
begin
	case(mux_PQ_list)
		1'd0: //Load
		begin
			for (i=0; i<max_vector; i=i+1)
			begin
				if(literals_P[i][0][1] == 1'd0)	    //P[cofactor_qubit] == I
				begin
					if(phase_anticommute[i]==1'd0)	//anticommuting_phase == 0 (+)
					begin
						select_PQ_list[i] <= 1'd0;
					end
					else 							//anticommuting_phase == 1 (-)
					begin
						select_PQ_list[i] <= 1'd1;
					end
				end
				else 						        //P[cofactor_qubit] == X
				begin
					if(phase_anticommute[i]==1'd0)	//anticommuting_phase == 0 (+)
					begin
						select_PQ_list[i] <= 1'd1;
					end
					else 							//anticommuting_phase == 1 (-)
					begin
						select_PQ_list[i] <= 1'd0;
					end
				end
			end
		end
		1'd1: //Rotate left
		begin
			select_PQ_list[max_vector-1] <= PQ_list[0];
			for (i=0; i<max_vector-1; i=i+1)
			begin
				select_PQ_list[i] <= PQ_list[i+1];
			end
		end
	endcase
end

always@(*)
begin
	case(mux_PQ_list_basis)
		1'd0: //Load
		begin
			for (i=0; i<max_vector; i=i+1)
			begin
				if(literals_P[i][0][1] == 1'd0)	    //P[cofactor_qubit] == I
				begin
					if(phase_anticommute[i]==1'd0)	//anticommuting_phase == 0 (+)
					begin
						select_PQ_list_basis[i] <= 1'd0;
					end
					else 							//anticommuting_phase == 1 (-)
					begin
						select_PQ_list_basis[i] <= 1'd1;
					end
				end
				else 						        //P[cofactor_qubit] == X
				begin
					if(phase_anticommute[i]==1'd0)	//anticommuting_phase == 0 (+)
					begin
						select_PQ_list_basis[i] <= 1'd1;
					end
					else 							//anticommuting_phase == 1 (-)
					begin
						select_PQ_list_basis[i] <= 1'd0;
					end
				end
			end
		end
		1'd1: //Rotate left
		begin
			select_PQ_list_basis[max_vector-1] <= PQ_list_basis[0];
			for (i=0; i<max_vector-1; i=i+1)
			begin
				select_PQ_list_basis[i] <= PQ_list_basis[i+1];
			end
		end
	endcase
end

reg basis_toffoli [0:num_qubit-1];
always@(*)
begin	
	if(select_nonstabilizer)
	begin
		for (i=0; i<num_qubit; i=i+1)
		begin
			if(i==reg_cofactor_pos)
			begin
				if(basis_index[0][i]==1'd0)
				begin
					basis_toffoli[i] <= 1'd1;
				end
				else
				begin
					basis_toffoli[i] <= 1'd0;
				end
			end
			else
			begin
				basis_toffoli[i] <= basis_index[0][i];
			end
		end
	end
	else
	begin
		basis_toffoli <= basis_index[0]; i=0;
	end
end

//mux_basis_index:
assign basis_index_leftmost = basis_index[0];

always@(*)
begin
	case(mux_basis_index)
		3'd0: //Rotate left: Unchanged
		begin
			select_basis_index[max_vector-1] <= basis_index[0];
			for (i=0; i<max_vector-1; i=i+1)
			begin
				select_basis_index[i] <= basis_index[i+1];
			end
		end
		3'd1: //Rotate left: Append from P or Q
		begin
			select_basis_index[max_vector-1] <= basis_list1; //basis from P or Q
			for (i=0; i<max_vector-1; i=i+1)
			begin
				select_basis_index[i] <= basis_index[i+1];
			end
		end
		3'd2: //Rotate left: Append from FIFO basis_index (correspond to new phase vector)
		begin
			select_basis_index[max_vector-1] <= basis_fifo;
			for (i=0; i<max_vector-1; i=i+1)
			begin
				select_basis_index[i] <= basis_index[i+1];
			end
		end
		3'd3: //Rotate left & update basis index after toffoli operation
		begin
			select_basis_index[max_vector-1] <= basis_toffoli;
			for (i=0; i<max_vector-1; i=i+1)
			begin
				select_basis_index[i] <= basis_index[i+1];
			end
		end		
		3'd4:
		begin
			select_basis_index[max_vector-1] <= basis_stabilizer;
			for (i=0; i<max_vector-1; i=i+1)
			begin
				select_basis_index[i] <= basis_index[i+1];
			end
		end		
		default:
		begin
			select_basis_index[max_vector-1] <= basis_index[0];
			for (i=0; i<max_vector-1; i=i+1)
			begin
				select_basis_index[i] <= basis_index[i+1];
			end
		end
	endcase
end

assign ld_P = valid_P | ld_P1 | ld_P2 | valid_P_nonstabilizer; 
assign ld_Q = valid_flag_anticommute | ld_Q1 | ld_Q2 | valid_P | ld_prodQ | valid_P_stabilizer | ld_prodQ_stabilizer | rotateLeft_Q_flag_basis_stabilizer; 

assign ld_PQ_list = valid_flag_anticommute | ld_PQ_list1_amp;
assign ld_PQ_list_basis = valid_flag_anticommute | ld_rotateLeft_basis;

assign ld_P2 = ld_rotateLeft_basis  | rotateLeft_P_nonstabilizer; 
assign ld_Q2 = ld_rotateLeft_basis; 
assign ld_basis = ld_rotateLeft_basis | rotateLeft_P_nonstabilizer | rotateLeft_stabilizer_basis;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0; i<max_vector; i=i+1)
		begin
			PQ_list[i] = 1'd0; PQ_list_basis[i] = 1'd0; phase_Q[i] = 1'd0;
			for (j=0; j<num_qubit; j=j+1)	//each vector pair
			begin
				literals_P [i][j] <= 2'd0; 
				literals_Q [i][j] <= 2'd0; 
				basis_index[i][j] <= 1'd0;
			end
		end
	end
	else
	begin
		i=0; j=0;
		if(ld_P)
		begin
			literals_P <= select_literals_P; 
		end
		if(ld_Q)
		begin
			literals_Q <= select_literals_Q; phase_Q <= select_phase_Q;
		end
		if(ld_PQ_list)	//For alpha operation
		begin
			PQ_list <= select_PQ_list;
		end
		if(ld_PQ_list_basis)	//For basis index determination
		begin
			PQ_list_basis <= select_PQ_list_basis;
		end
		if(ld_basis)
		begin
			basis_index <= select_basis_index;
		end
	end
end

/******************************************************ROW MULT P & ANTICOMMUTE****************************************************/
genvar k;
generate
for (k=0; k<max_vector; k=k+1)
begin: gen_Q_alpha
row_mult_single rm_P_anticommute (.literals_in1(literals_P[k]), .phase_in1(1'd0), .literals_in2(literals_anticommute), .phase_in2(phase_anticommute[k]), 
.literals_out(literals_P_anticommute[k]), .phase_out(phase_P_anticommute[k]));
defparam rm_P_anticommute.num_qubit = num_qubit; 
end: gen_Q_alpha
endgenerate

/****************************************************ROW MULT Q & LITERALS OUT****************************************************/
generate
for (k=0; k<max_vector; k=k+1)
begin: gen_prodQ_cofactor
row_mult_single rm_prodQ_cofactor (.literals_in1(literals_Q[k]), .phase_in1(phase_Q[k]), .literals_in2(literals_out), .phase_in2(phase_out[k]), 
.literals_out(literals_prodQ_cofactor[k]), .phase_out(phase_prodQ_cofactor[k]));
defparam rm_prodQ_cofactor.num_qubit = num_qubit; 
end: gen_prodQ_cofactor
endgenerate

generate
for (k=0; k<max_vector; k=k+1)
begin: gen_prodQ_stabilizer
row_mult_single rm_prodQ_cofactor (.literals_in1(literals_Q[k]), .phase_in1(phase_Q[k]), .literals_in2(literals_out_stabilizer), .phase_in2(phase_out_stabilizer[k]), 
.literals_out(literals_prodQ_stabilizer[k]), .phase_out(phase_prodQ_stabilizer[k]));
defparam rm_prodQ_cofactor.num_qubit = num_qubit; 
end: gen_prodQ_stabilizer
endgenerate

/*******************************************************RAM FOR ALPHA STORAGE*******************************************************/
wire write_ram_alpha_enable; reg [7:0] write_ram_alpha;
assign write_ram_alpha_enable = write_alpha_enable | write_amplitude1_enable;
always@(*)
begin
	if(write_amplitude1_enable)
	begin
		write_ram_alpha <= write_amplitude1;
	end
	else
	begin
		write_ram_alpha <= write_alpha;
	end
end

reg [num_qubit-1:0] read_alpha_address_selected;

always@(*)
begin
	if(read_ram_alpha_stabilizer_en)
	begin
		read_alpha_address_selected <= read_ram_alpha_stabilizer_address;
	end
	else
	begin
		read_alpha_address_selected <= read_alpha_address;
	end
end

ram_alpha_control alpha_control (.clk(clk), .write_address(write_alpha_address), .write_enable(write_ram_alpha_enable), .write_alpha(write_ram_alpha), 
.read_address(read_alpha_address_selected), .read_alpha(read_alpha_out)); 
defparam alpha_control.num_qubit = num_qubit;

assign {alpha1_out_r, alpha1_out_i, alpha2_out_r, alpha2_out_i} = read_alpha_out;

//Store alpha into memory with correct sequence of list 1 & 2 accordingly
always@(*)
begin
	if(PQ_list[0]==1'd0) //P -> list1; Q -> list2
	begin
		write_alpha <= {2'd1, 2'd0, amplitude_r_Q_out, amplitude_i_Q_out};
	end
	else
	begin
		write_alpha <= {amplitude_r_Q_out, amplitude_i_Q_out, 2'd1, 2'd0};
	end
end

/**********************************************************FSM FOR CONTROL***********************************************************/
reg [2:0] state;
localparam S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4, S5 = 3'd5, S6 = 3'd6, S7 = 3'd7;
reg [31:0] counter;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state <= S0; counter <= 32'd0;
	end
	else
	begin
		case(state)
			S0: //Idle: Waiting state
			begin
				counter <= 32'd0; determine_amplitude <= 1'd0;
				if(valid_P)
				begin
					state <= S1;
				end
				else
				begin
					state <= S0;
				end
			end
			S1: //Align P with cofactor column to the left
			begin
				determine_amplitude <= 1'd0;
				if(reg_cofactor_pos==counter) //Aligned. 
				begin
					state <= S2; counter <= counter; 
				end
				else //Rotate left individual literal in each P
				begin
					state <= S1; counter <= counter + 32'd1;  
				end
			end
			S2:  //Continue further operation to determine alpha and basis index if randomized outcome is obtained
			begin
				counter <= counter; determine_amplitude <= 1'd0;
				if(valid_flag_anticommute == 1'd1) 
				begin
					if(flag_anticommute == 1'd0) 	//Deterministic outcome
					begin
						state <= S0;
					end
					else 							//Randomized outcome
					begin
						state <= S3;
						determine_amplitude <= 1'd1;
					end
				end
				else
				begin
					state <= S2;
				end
			end
			S3: //Wait until amplitude determination is completed
			begin
				determine_amplitude <= 1'd0; counter <= counter;
				if(done_amplitude)
				begin
					if(reg_cofactor_pos == 32'd0)
					begin
						state <= S5; 
						counter <= 32'd0;
					end
					else
					begin
						state <= S4;
					end
				end
				else
				begin
					state <= S3;
				end
			end
			S4: //Align P & Q back to orignal qubit sequence
			begin
				determine_amplitude <= 1'd0; 
				if(counter==num_qubit-1)
				begin
					state <= S5; counter <= 32'd0;
				end
				else
				begin
					state <= S4; counter <= counter + 32'd1;
				end
			end
			S5:	//Skip one valid P for beta operation
			begin
				counter <= 32'd0; determine_amplitude <= 1'd0; 
				if(valid_P)
				begin
					state <= S0; 
				end
				else
				begin
					state <= S5; 
				end
			end
			default:
			begin
				state <= S0; determine_amplitude <= 1'd0; counter <= 32'd0;
			end
		endcase
	end
end

reg rotateLeft_P, rotateLeft_Q;
assign ld_P1 = rotateLeft_P; 
assign ld_Q1 = ld_rotateLeft | rotateLeft_Q | rotateLeft_Q_beta  | rotateLeft_Q_flag_basis_stabilizer;

always@(*)
begin
	case(state)
		S0: //Idle: Waiting state
		begin
			rotateLeft_P <= 1'd0; rotateLeft_Q <= 1'd0; 
		end
		S1: //Align P with cofactor column to the left. Q is product of aligned P & anticommute row
		begin
			rotateLeft_P <= 1'd0; rotateLeft_Q <= 1'd0; 
			if(reg_cofactor_pos!=counter)
			begin
				rotateLeft_P <= 1'd1; 
			end
		end
		S2: //Continue further operation to determine alpha and basis index if randomized outcome is obtained
		begin
			rotateLeft_P <= 1'd0; rotateLeft_Q <= 1'd0; 
		end
		S3: //Rotate left signal is triggered from amplitude_cofactor module to determine amplitude
		begin
			rotateLeft_P <= 1'd0; rotateLeft_Q <= 1'd0;
		end
		S4:
		begin
			rotateLeft_P <= 1'd1; rotateLeft_Q <= 1'd1; 
		end
		S5:
		begin
			rotateLeft_P <= 1'd0; rotateLeft_Q <= 1'd0;
		end
		default:
		begin
			rotateLeft_P <= 1'd0; rotateLeft_Q <= 1'd0;
		end
	endcase
end


always@(*)
begin
	//For P:
	if(ld_P1)
	begin
		mux_P <= 2'd1; 
	end
	else if(ld_P2)
	begin
		mux_P <= 2'd2;
	end
	else
	begin
		mux_P <= 2'd0;
	end
	//For Q:
	if(ld_Q1)
	begin
		mux_Q <= 3'd1;
	end
	else if(ld_Q2)
	begin
		mux_Q <= 3'd2;
	end
	else if(valid_P | valid_P_stabilizer)
	begin
		mux_Q <= 3'd3;
	end
	else if(ld_prodQ)
	begin
		mux_Q <= 3'd4;
	end
	else if(ld_prodQ_stabilizer)
	begin
		mux_Q <= 3'd5;
	end
	else
	begin
		mux_Q <= 3'd0;
	end	
	if(ld_PQ_list1_amp)
	begin
		mux_PQ_list <= 1'd1;
	end
	else
	begin
		mux_PQ_list <= 1'd0;
	end
	if(ld_rotateLeft_basis)
	begin
		mux_PQ_list_basis <= 1'd1;
	end
	else
	begin
		mux_PQ_list_basis <= 1'd0;
	end
end

/********************************************************DETERMINE BASIS INDEX*********************************************************/

wire add_basis_valid, empty, read_new_basis; 
assign add_basis_valid = (valid_second_round==1'd1 & valid_index_readout==1'd0)? 1'd1: 1'd0;
assign read_new_basis = (empty==1'd0 && ld_rotateLeft_basis==1'd1 && valid_second_round==1'd0)? 1'd1: 1'd0; 

//Use a duplicated PQ_list to avoid parallel access by alpha update operation
always@(*)
begin
	if (PQ_list_basis[0]==1'd0) //P -> list1 (basis_index registers); Q -> list2
	begin
		for(i=0;i<num_qubit;i=i+1)
		begin
			basis_list1[i] <= literals_P[0][i][1];
			basis_list2[i] <= literals_Q[0][i][1];
		end
	end
	else						//Q -> list1 (basis_index registers); P -> list2
	begin
		for(i=0;i<num_qubit;i=i+1)
		begin
			basis_list1[i] <= literals_Q[0][i][1];
			basis_list2[i] <= literals_P[0][i][1];
		end
	end
end

always@(*)
begin
	if(ld_rotateLeft_basis)
	begin
		if(valid_second_round) 	//Select basis from P or Q
		begin
				mux_basis_index <= 3'd1;
		end
		else 					//Append new basis (if available); else rotate by taking original data 
		begin
			if(empty == 1'd1)   //FIFO empty and not worst case
			begin
				mux_basis_index <= 3'd0;
			end
			else
			begin
				mux_basis_index <= 3'd2;
			end
		end
	end
	else if(rotateLeft_P_nonstabilizer)
	begin
		if(phaseShift_toffoli)  //Phase shift: rotate left unchanged
		begin
			mux_basis_index <= 3'd0;
		end
		else	//Toffoli: rotate left + toffoli update
		begin
			mux_basis_index <= 3'd3;
		end
	end
	else if(rotateLeft_stabilizer_basis) //Stabilizer Operation: Alpha stage basis index update (Hadamard & CNOT)
	begin
		mux_basis_index <= 3'd4;
	end
	else
	begin
		mux_basis_index <= 3'd0;
	end
end

reg [num_qubit-1:0] basis_fifo_in; wire [num_qubit-1:0] basis_fifo_out;
always@(*)
begin
	for(i=0;i<num_qubit;i=i+1)
	begin
		basis_fifo_in[i] <= basis_list2[num_qubit-1-i];
		basis_fifo[i] <= basis_fifo_out[num_qubit-1-i];
	end
end

fifo_alter fifo_basis (.clk(clk), .rst(rst), .wr_en(add_basis_valid), .rd_en(read_new_basis), .din(basis_fifo_in), .dout(basis_fifo_out), 
.empty(empty), .full());
defparam fifo_basis.data_width = num_qubit; defparam fifo_basis.fifo_bit = num_qubit-1; 

/***************************************************FOR COFACTOR BETA OPERATION*******************************************************/
//Store flag basis
reg select_flag_basis [0:max_vector-1][0:num_qubit-1];
reg mux_flag_basis;
wire ld_flag_basis;

assign ld_flag_basis = valid_P | rotateLeft_flag_basis | update_flag_basis | valid_P_stabilizer | ld_prodQ_stabilizer | rotateLeft_Q_flag_basis_stabilizer;

always@(*)
begin
	i=0;j=0;
	if(valid_P | valid_P_stabilizer)	//Load P literals XOR basis index as initial flag basis (sync with valid P)
	begin
		for (i=0;i<max_vector;i=i+1)
		begin
			for (j=0;j<num_qubit;j=j+1)
			begin
				select_flag_basis[i][j] <= literals_P_in[i][j][1] ^ basis_index[i][j];
			end
		end
	end
	else if(rotateLeft_flag_basis | rotateLeft_Q_flag_basis_stabilizer)
	begin
		for (i=0; i<max_vector; i=i+1) //Each phase pair
		begin
			select_flag_basis [i][num_qubit-1] <= flag_basis [i][0];    //[pair_index][literal_index]
			for (j=0; j<num_qubit-1; j=j+1)	//Each literal in each phase pair
			begin
				select_flag_basis [i][j] <= flag_basis [i][j+1];        //[pair_index][literal_index]
			end
		end
	end
	else if (update_flag_basis) //Update with flag basis XOR literals out as productQ is updated 
	begin
		j=0;
		for (i=0;i<max_vector;i=i+1)
		begin
			if (flag_basis[i][0]) //Update if flagged
			begin
				for (j=0;j<num_qubit;j=j+1)
				begin
					select_flag_basis[i][j] <= flag_basis[i][j] ^ literals_out[j][1];
				end
			end
			else //No changes
			begin
				select_flag_basis[i] <= flag_basis[i];
			end
		end
	end
	
	else if(ld_prodQ_stabilizer)
	begin
		j=0;
		for (i=0;i<max_vector;i=i+1)
		begin
			if (flag_basis[i][0]) //Update if flagged
			begin
				for (j=0;j<num_qubit;j=j+1)
				begin
					select_flag_basis[i][j] <= flag_basis[i][j] ^ literals_out_stabilizer[j][1];
				end
			end
			else //No changes
			begin
				select_flag_basis[i] <= flag_basis[i];
			end
		end
	end
	else
	begin
		select_flag_basis <= flag_basis;
	end
end

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (i=0;i<max_vector;i=i+1)
		begin
			for (j=0;j<num_qubit;j=j+1)
			begin
				flag_basis [i][j] <= 1'd0;
			end
		end
	end
	else
	begin
		i=0; j=0;
		if(ld_flag_basis)
		begin
			flag_basis <= select_flag_basis;
		end
	end
end

endmodule 
