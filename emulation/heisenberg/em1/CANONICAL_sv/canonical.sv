module canonical #(parameter num_qubit = 4)(
input clk,
input rst,
input start, 
input [1:0] literals_in [0:num_qubit-1],
input phase_in,
input valid_in, //data in should be valid at continuous clock cycle
output [1:0] literals_out [0:num_qubit-1],
output phase_out,
output flag_out,
output reg [1:0] literals_P [0:num_qubit-1], output reg phase_P, output reg valid_P, output reg [31:0] counter_P,
//ADDED FOR VERIFICATION
output [1:0] trans_literal_retain_outX [0:num_qubit-1][0:num_qubit-1],
output trans_phase_retain_outX[0:num_qubit-1], output trans_flag_retain_outX[0:num_qubit-1],
output [1:0] trans_literal_retain_outZ [0:num_qubit-1][0:num_qubit-1],
output trans_phase_retain_outZ [0:num_qubit-1], output trans_flag_retain_outZ [0:num_qubit-1],
output [1:0] storage_literal_outX [0:num_qubit-1][0:num_qubit-1],
output storage_phase_outX[0:num_qubit-1], output storage_flag_outX[0:num_qubit-1],
output [1:0] storage_literal_outZ [0:num_qubit-1][0:num_qubit-1],
output storage_phase_outZ[0:num_qubit-1], output storage_flag_outZ[0:num_qubit-1]
);


wire rst_new;
assign rst_new = rst | start;

/********************************************VARIABLE INSTANTIATION********************************************/
//For X-block
logic [1:0] literals_trans_inX [0:num_qubit-1][0:num_qubit-1]; //[row][column]
logic phase_trans_inX [0:num_qubit-1]; 
logic flag_trans_inX [0:num_qubit-1];
logic [1:0] literals_trans_outX [0:num_qubit-1][0:num_qubit-1];
logic phase_trans_outX [0:num_qubit-1]; 
logic flag_trans_outX [0:num_qubit-1]; 
//For Z-block
logic [1:0] literals_trans_inZ [0:num_qubit-1][0:num_qubit-1]; //[row][column]
logic phase_trans_inZ [0:num_qubit-1]; 
logic flag_trans_inZ [0:num_qubit-1];
logic [1:0] literals_trans_outZ [0:num_qubit-1][0:num_qubit-1];
logic phase_trans_outZ [0:num_qubit-1]; 
logic flag_trans_outZ [0:num_qubit-1]; 

//Others
wire ld_trans, ld_store, second_stage;
wire [0:num_qubit-1] second_CRX;
wire [0:num_qubit-1] second_CRZ;
integer i;
genvar j;

/************************************************FOR INPUT TO X-BLOCK*******************************************/
//Select literal inputs for n valid cycles after start to ensure all rows in stabilizer matrix are loaded 
//Then select pure I literal row as input to push literal rows down while maintaining correct operation
//Finite State machine to control input selection to X-block

localparam  S0=1'd0, S1=1'd1;
reg state; 
reg [31:0] counter;
reg sel_in;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		state <= S0;
		counter <= 32'd0;
	end
	else
	begin
		case(state)
			S0:
			begin
				if(valid_in)  
				begin
					counter <= counter + 32'd1;
					state <= S1;
				end
				else
				begin
					counter <= 32'd0;
					state <= S0;
				end
			end
			S1:
			begin
				if(counter == (num_qubit-1)) 
				begin
					counter <= 32'd0;
					state <= S0;
				end
				else 
				begin
					state <= S1;
					if(valid_in)
						counter <= counter + 32'd1;
					else
						counter <= counter;
				end
			end
		endcase
	end
end

//Generate control signal based on Mealy model
always@(*)
begin
	case(state)
		S0:
		begin
			if(valid_in)
			begin
				sel_in <= 1'd1;
			end
			else
			begin
				sel_in <= 1'd0;
			end
		end
		S1:
		begin
			sel_in <= 1'd1;
		end
	endcase
end


//Multiplexer for input selection => 0: Set all to zero; 1: Take input from external
always@(*)
begin
	//Default set to all I
	if(sel_in == 1'd0)
	begin 
		for (i=0; i<num_qubit; i=i+1) 
		begin
			literals_trans_inX[0][i] <= 2'd0;
		end
		phase_trans_inX[0] <= 1'd0;
		flag_trans_inX[0] <= 1'd0;
	end
	//Get literals row from input
	else
	begin
		i=0;
		literals_trans_inX[0] <= literals_in;
		phase_trans_inX[0] <= phase_in;
		flag_trans_inX[0] <= 1'd1;
	end
end

//For submodule instantiation for DU of X-block
generate
for (j=0; j<num_qubit; j=j+1)
begin: du_X
canonical_modular #(num_qubit, j, 0)
modularX (.clk(clk), .rst_new(rst_new), .ld_trans(ld_trans), .ld_store(ld_store), 
.second_CR(second_CRX[j]), .literals_trans_in(literals_trans_inX[j]), .phase_trans_in(phase_trans_inX[j]), 
.trans_literal_retain_out(trans_literal_retain_outX[j]), .trans_phase_retain_out(trans_phase_retain_outX[j]), 
.literals_trans_out(literals_trans_outX[j]), .phase_trans_out(phase_trans_outX[j]), .flag_out(flag_trans_outX[j]), 
.flag_in(flag_trans_inX[j]), .flag_retain_out(trans_flag_retain_outX[j]), 
.store_literal_output(storage_literal_outX[j]), .store_phase_output(storage_phase_outX[j]), 
.store_flag_output(storage_flag_outX[j]), .second_stage(second_stage));
//defparam modularX.num_qubit = num_qubit; defparam modularX.pivot_position = j; defparam modularX.block_type = 0; 
end: du_X
endgenerate

//For connecting between row(s): Part 1
generate
for (j=1; j<num_qubit; j=j+1) //Do it explicitly for the first row
begin: du_X_connect
	assign literals_trans_inX[j] = literals_trans_outX[j-1];
	assign phase_trans_inX[j] = phase_trans_outX[j-1];
	assign flag_trans_inX[j] = flag_trans_outX[j-1];
end: du_X_connect
endgenerate

/******************************************************FOR Z-BLOCK*************************************************/
//For submodule instantiation for DU of X-block
generate
for (j=0; j<num_qubit; j=j+1)
begin: du_Z
canonical_modular #(num_qubit, j, 1) modularZ 
(.clk(clk), .rst_new(rst_new), .ld_trans(ld_trans), .ld_store(ld_store), 
.second_CR(second_CRZ[j]), .literals_trans_in(literals_trans_inZ[j]), .phase_trans_in(phase_trans_inZ[j]), 
.trans_literal_retain_out(trans_literal_retain_outZ[j]), .trans_phase_retain_out(trans_phase_retain_outZ[j]), 
.literals_trans_out(literals_trans_outZ[j]), .phase_trans_out(phase_trans_outZ[j]), .flag_in(flag_trans_inZ[j]), 
.flag_out(flag_trans_outZ[j]), .flag_retain_out(trans_flag_retain_outZ[j]),
.store_literal_output(storage_literal_outZ[j]), .store_phase_output(storage_phase_outZ[j]), 
.store_flag_output(storage_flag_outZ[j]), .second_stage(second_stage));
//defparam modularZ.num_qubit = num_qubit; defparam modularZ.pivot_position = j; defparam modularZ.block_type = 1; 
end: du_Z
endgenerate 

//For connecting between row(s): Part 1
generate
for (j=1; j<num_qubit; j=j+1) //Do it explicitly for the first row
begin: du_Z_connect
	assign literals_trans_inZ[j] = literals_trans_outZ[j-1];
	assign phase_trans_inZ[j] = phase_trans_outZ[j-1];
	assign flag_trans_inZ[j] = flag_trans_outZ[j-1];
end: du_Z_connect
endgenerate
assign literals_trans_inZ[0] = literals_trans_outX[num_qubit-1];
assign phase_trans_inZ[0] = phase_trans_outX[num_qubit-1];
assign flag_trans_inZ[0] = flag_trans_outX[num_qubit-1];

//Connect last row Z-block to output - Take from transition registers
assign literals_out = literals_trans_outZ[num_qubit-1];
assign phase_out = phase_trans_outZ[num_qubit-1]; 
assign flag_out = flag_trans_outZ[num_qubit-1]; 

/*********************************************CONTROL UNIT********************************************************/
//ADD THE VALID IN SIGNAL FOR CONTROL
canonical_control #(num_qubit) control(
.clk(clk), .rst_new(rst_new), .valid_in(valid_in), .ld_trans(ld_trans), .ld_store(ld_store), 
.second_CR({second_CRX,second_CRZ}), .second_stage(second_stage)); //), .done(done));
//defparam control.num_qubit = num_qubit;

/****************************************GENERATE P BASED ON -Z ROW**********************************************/
//reg [31:0] counter_P;
reg [31:0] counter_valid;
reg stateP;

//Make sure second_stage trigger is short pulse
reg reg_second_stage; wire second_stage_trigger;
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		reg_second_stage <= 1'd0;
	end
	else
	begin
		reg_second_stage <= second_stage;
	end
end

assign second_stage_trigger = (second_stage==1'd1 & reg_second_stage==1'd0)? 1'd1:1'd0;

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		stateP <= S0; counter_P <= 32'd0; counter_valid <= 32'd0; 
		for (i=0; i<num_qubit; i=i+1) 
		begin
			literals_P[i] <= 2'd0;
		end
		phase_P <= 1'd0; valid_P <= 1'd0;
	end
	else
	begin
		phase_P <= 1'd0;
		case(stateP)
			S0:
			begin
				counter_P <= 32'd0; counter_valid <= 32'd0;  valid_P <= 1'd0;
				literals_P <= literals_P;
				if(second_stage_trigger)
				begin
					stateP <= S1; counter_P <= counter_P + 32'd1;
					for (i=0; i<num_qubit; i=i+1) 
					begin
						literals_P[i] <= 2'd0;
					end
				end
				else
				begin
					stateP <= S0;
				end
			end
			S1:
			begin
				 literals_P <= literals_P; counter_P <= counter_P + 32'd1;
				//Keep track of the total number of valid literal rows
				if(flag_out)
					counter_valid <= counter_valid + 32'd1; 
				else
					counter_valid <= counter_valid;
				if(counter_valid == num_qubit)
				begin
					valid_P <= 1'd1;
					stateP <= S0;
				end
				else
				begin
					valid_P <= 1'd0;
					stateP <= S1;
				end
				//Flag in P on -Z row
				if(flag_out & phase_out & counter_P > (3*num_qubit-1))
				begin
					literals_P[counter_P-(3*num_qubit)][1] <= 1'd1;
				end
			end
		endcase
	end
end

endmodule
