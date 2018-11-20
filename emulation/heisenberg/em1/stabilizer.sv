module stabilizer #(parameter num_qubit = 3, total_gate = 30)(
//Input:
input clk, input rst, input start, 
input [1:0] gate_type, //0: Hadamard; 1: Phase; 2: CNOT, 3: Measurement
input [31:0] qubit_pos, input [31:0] qubit_pos2, 
//Output:
output [1:0] literals_out[0:num_qubit-1], output phase_out, output valid_out, output done_readout,
output signed [31:0] global_phase_r, output signed [31:0] global_phase_i, output [31:0] count_H,  
output reg update_gate_info
);

wire [1:0] literals_out_canonical [0:num_qubit-1]; wire phase_out_canonical, valid_out_canonical; 
wire gp_ready, literal_phase_readout;
wire [1:0] literals_P [0:num_qubit-1]; wire phase_P, valid_P, valid_P_buffer;
wire [1:0] literals_out_cba [0:num_qubit-1]; wire phase_out_cba, valid_out_cba;
wire [1:0] literals_out_buffer [0:num_qubit-1]; wire phase_out_buffer, valid_out_buffer;
wire [1:0] literals_out_measure [0:num_qubit-1]; wire phase_out_measure, valid_out_measure;
wire [1:0] literals_out_select [0:num_qubit-1]; wire phase_out_select, valid_out_select;
reg [1:0] literals_in_canonical [0:num_qubit-1]; reg phase_in_canonical, valid_in_canonical;
reg [1:0] literals_in_cba [0:num_qubit-1]; reg phase_in_cba, valid_in_cba;
reg [1:0] literals_in_measure [0:num_qubit-1]; reg phase_in_measure, valid_in_measure;
reg flag_anticommute; wire flag_anticommute_pre, ld_flag_anticommute; 
wire rst_new; assign rst_new = rst | start;


/*******************************************INPUT TO CONJUGATION-BY-ACTON*****************************************/
//literal_basis OR literals_out_buffer
select_in #(num_qubit)  select (.clk(clk), .rst_new(rst_new), 
.literals_out(literals_out_select), .phase_out(phase_out_select), .valid_out(valid_out_select));

always@(*)
begin
	if(valid_out_select)
	begin
		if(gate_type==2'd3)
		begin
			valid_in_measure <= valid_out_select; valid_in_cba <= 1'd0; 
		end
		else
		begin
			valid_in_cba <= valid_out_select; valid_in_measure <= 1'd0;
		end
		literals_in_cba <= literals_out_select; phase_in_cba <= phase_out_select; 
		literals_in_measure <= literals_out_select; phase_in_measure <= phase_out_select; 
	end
	else
	begin
		if(gate_type==2'd3) //Measurement
		begin
			valid_in_measure <= valid_out_buffer;	valid_in_cba <= 1'd0;
		end
		else
		begin
			valid_in_cba <= valid_out_buffer; valid_in_measure <= 1'd0;
		end	
		literals_in_cba <= literals_out_buffer; phase_in_cba <= phase_out_buffer; 
		literals_in_measure <= literals_out_buffer; phase_in_measure <= phase_out_buffer; 
	end
end


/********************************************CONJUGATION-BY-ACTION************************************************/
conjugation_by_action #(num_qubit) cba_top(.clk(clk), .rst(rst), .start(start), 
.gate_type(gate_type), .qubit_pos(qubit_pos), .qubit_pos2(qubit_pos2), 
.literals_in(literals_in_cba), .phase_in(phase_in_cba), .valid_in(valid_in_cba), 
.literals_out(literals_out_cba), .phase_out(phase_out_cba), .valid_out(valid_out_cba));


/********************************************CANONICAL FORM REDUCTION********************************************/
always@(*)
begin
	if(valid_out_measure)
	begin
		literals_in_canonical <= literals_out_measure; phase_in_canonical <= phase_out_measure; 
		valid_in_canonical <= valid_out_measure;
	end
	else
	begin
		literals_in_canonical <= literals_out_cba; phase_in_canonical <= phase_out_cba; valid_in_canonical <= valid_out_cba;
	end
end

canonical #(num_qubit) canonical_top (.clk(clk), .rst(rst), .start(start), 
.literals_in(literals_in_canonical), .phase_in(phase_in_canonical), .valid_in(valid_in_canonical), 
.literals_out(literals_out_canonical), .phase_out(phase_out_canonical), .flag_out(valid_out_canonical), 
.literals_P(literals_P), .phase_P(phase_P), .valid_P(valid_P),
//Debug signals:
.counter_P(), .trans_literal_retain_outX(), .trans_phase_retain_outX(), .trans_flag_retain_outX(), 
.trans_literal_retain_outZ(), .trans_phase_retain_outZ(), .trans_flag_retain_outZ(), .storage_literal_outX(), 
.storage_phase_outX(), .storage_flag_outX(), .storage_literal_outZ(), .storage_phase_outZ(), .storage_flag_outZ());


/********************************************GLOBAL PHASE MAINTENANCE********************************************/
global_phase #(num_qubit) global_phase_top
(.clk(clk), .rst(rst), .start(start), .literal_phase_readout(literal_phase_readout),
.gate_type(gate_type), .qubit_pos(qubit_pos), .qubit_pos2(qubit_pos2),//??
.literals_P(literals_P), .phase_P(phase_P), .valid_P(valid_P_buffer), .done_readout(done_readout), .gp_ready(gp_ready),
.literals_in(literals_out_buffer), .phase_in(phase_out_buffer), .valid_in(valid_out_buffer), 
.literals_out(literals_out), .phase_out(phase_out), .valid_out(valid_out), 
.global_phase_r(global_phase_r), .global_phase_i(global_phase_i), .count_H(count_H),
//For measurement:
.flag_anticommute(flag_anticommute),
//Debug signals:
.alpha_r(), .alpha_i(), .beta_r(), .beta_i(), .state_CU(), .reg_gate_type(), .reg2_gate_type(), .basis_index(), 
.basis_index2());


/******************************************************BUFFER******************************************************/
buffer_mux #(num_qubit, total_gate) buffer
(.clk(clk), .rst_new(rst_new), .gp_ready(gp_ready), .literals_in(literals_out_canonical), 
.phase_in(phase_out_canonical), .valid_in(valid_out_canonical), .valid_P(valid_P), .literals_out(literals_out_buffer), 
.phase_out(phase_out_buffer), .valid_out(valid_out_buffer), .valid_P_out(valid_P_buffer), 
.literal_phase_readout(literal_phase_readout), .ld_flag_anticommute(ld_flag_anticommute));


/******************************************************MEASUREMENT******************************************************/
always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		flag_anticommute <= 1'd0;
	end
	else
	begin
		if(ld_flag_anticommute)
		begin
			flag_anticommute <= flag_anticommute_pre;
		end
		else
		begin
			flag_anticommute <= flag_anticommute;
		end
	end
end

measurement measure (.clk(clk), .rst_new(rst_new), .qubit_pos(qubit_pos), .literals_in(literals_in_measure),
.phase_in(phase_in_measure), .valid_in(valid_in_measure), .literals_out(literals_out_measure), .phase_out(phase_out_measure), 
.valid_out(valid_out_measure), .flag_anticommute(flag_anticommute_pre));
defparam measure.num_qubit = num_qubit;


/*************************************************GATE INFO UPDATE***********************************************/
//First gate should be set from testbench together with start signal!!!
reg stateInfo;
localparam  SInfo0=1'd0, SInfo1=1'd1;
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		stateInfo <= SInfo0; update_gate_info <= 1'd0;
	end
	else
	begin
		case(stateInfo)
			SInfo0:
			begin
				if(valid_out_canonical)
				begin
					stateInfo <= SInfo1; update_gate_info <= 1'd1;
				end
				else
				begin
					stateInfo <= SInfo0; update_gate_info <= 1'd0;
				end
			end
			SInfo1:
			begin
				update_gate_info <= 1'd0;
				if(valid_out_buffer)
				begin
					stateInfo <= SInfo0; 
				end
				else
				begin
					stateInfo <= SInfo1;
				end
			end
		endcase
	end
end

endmodule
