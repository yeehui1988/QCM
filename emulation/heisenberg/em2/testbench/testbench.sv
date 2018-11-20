`timescale 1ns/1ns 

module testbench ();

//Parameterizable
parameter num_qubit = 3, complex_bit = 24, fp_bit = 22, phase_lookup = 5, total_gate = 36; 

//Input:
reg clk, rst, final_gate, valid_in, valid_P_in;
reg [2:0] gate_type; reg [phase_lookup-1:0] phase_shift_index; reg [31:0] qubit_pos; reg [31:0] qubit_pos2; reg [31:0] qubit_pos3; 
reg [1:0] literals_in [0:num_qubit-1]; reg phase_in [0:2**num_qubit-1]; reg [1:0] literals_P_in [0:2**num_qubit-1][0:num_qubit-1]; 
reg [num_qubit-1:0] read_amplitude_verification_address;
//Output:
wire update_gate_info, valid_out, ram_amplitude_busy;
wire [1:0] literals_out[0:num_qubit-1]; wire phase_out [0:2**num_qubit-1]; wire [31:0] counter_valid_vector;  
wire [complex_bit-1:0] ram_amplitude_out_r; wire [complex_bit-1:0] ram_amplitude_out_i; 
reg valid_amplitude_verification, valid_out_nonstabilizer, valid_out_stabilizer;

top top_test (.clk(clk), .rst(rst), .gate_type(gate_type), .phase_shift_index(phase_shift_index), .qubit_pos(qubit_pos), .qubit_pos2(qubit_pos2),
.qubit_pos3(qubit_pos3), .update_gate_info(update_gate_info), .final_gate(final_gate), .literals_in(literals_in), .phase_in(phase_in), .valid_in(valid_in), 
.literals_P_in(literals_P_in), .valid_P_in(valid_P_in), .literals_out(literals_out), .phase_out(phase_out), .valid_out(valid_out),
.counter_valid_vector(counter_valid_vector), .read_amplitude_verification_address(read_amplitude_verification_address), .ram_amplitude_out_r(ram_amplitude_out_r),
.ram_amplitude_out_i(ram_amplitude_out_i), .ram_amplitude_busy(ram_amplitude_busy),
.valid_out_stabilizer(valid_out_stabilizer), .valid_out_nonstabilizer(valid_out_nonstabilizer)); 

defparam top_test.num_qubit = num_qubit; defparam top_test.complex_bit = complex_bit; defparam top_test.fp_bit = fp_bit; defparam top_test.phase_lookup = phase_lookup;

initial
begin
	clk = 1'b1;
	forever
	#5				//period=10ns (100MHz)
	clk = ~clk;
end

//For 3-qubit	
initial
begin
	//Reset
	rst = 1'd1;  
	valid_in = 1'd0; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd0;  literals_in [2] = 2'd0; 
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; 	
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0;
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0;
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0;
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0;
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0;
	#3 //Idle
	rst = 1'd0;  
	valid_in = 1'd0; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd0;  literals_in [2] = 2'd0; 
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; 	
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0;
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0;
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0;
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0;
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0;
	#18 //Input: First row: +ZII 
	rst = 1'd0;  
	valid_in = 1'd1; 
	literals_in [0] = 2'd1; literals_in [1] = 2'd0;  literals_in [2] = 2'd0; 
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; 	
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0;
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0;
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0;
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0;
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0;	
	#10 //Input: Second row: +IZI 
	rst = 1'd0;  
	valid_in = 1'd1; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd1;  literals_in [2] = 2'd0; 
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; 	
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0;
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0;
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0;
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0;
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0;
	#10 //Input: Third row: +IIZ
	rst = 1'd0;  
	valid_in = 1'd1; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd0;  literals_in [2] = 2'd1; 
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	valid_P_in = 1'd1; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; 	
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0;
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0;
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0;
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0;
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0;
	#10 //Idle
	rst = 1'd0;  
	valid_in = 1'd0; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd0;  literals_in [2] = 2'd0; 
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; 	
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0;
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0;
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0;
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0;
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0;
	#20000
	$stop;
end


/*
//For 4-qubit
initial
begin
	//Reset
	rst = 1'd1;  
	valid_in = 1'd0; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd0;  literals_in [2] = 2'd0;  literals_in [3] = 2'd0;
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	phase_in [8] = 1'd0; phase_in [9] = 1'd0; phase_in [10] = 1'd0; phase_in [11] = 1'd0; 
	phase_in [12] = 1'd0; phase_in [13] = 1'd0; phase_in [14] = 1'd0; phase_in [15] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; literals_P_in [0][3] = 2'd0; 
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; literals_P_in [1][3] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; literals_P_in [2][3] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0; literals_P_in [3][3] = 2'd0; 
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0; literals_P_in [4][3] = 2'd0; 
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0; literals_P_in [5][3] = 2'd0; 
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0; literals_P_in [6][3] = 2'd0; 
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0; literals_P_in [7][3] = 2'd0; 
	literals_P_in [8][0] = 2'd0; literals_P_in [8][1] = 2'd0; literals_P_in [8][2] = 2'd0; literals_P_in [8][3] = 2'd0; 
	literals_P_in [9][0] = 2'd0; literals_P_in [9][1] = 2'd0; literals_P_in [9][2] = 2'd0; literals_P_in [9][3] = 2'd0; 
	literals_P_in [10][0] = 2'd0; literals_P_in [10][1] = 2'd0; literals_P_in [10][2] = 2'd0; literals_P_in [10][3] = 2'd0; 
	literals_P_in [11][0] = 2'd0; literals_P_in [11][1] = 2'd0; literals_P_in [11][2] = 2'd0; literals_P_in [11][3] = 2'd0; 
	literals_P_in [12][0] = 2'd0; literals_P_in [12][1] = 2'd0; literals_P_in [12][2] = 2'd0; literals_P_in [12][3] = 2'd0; 
	literals_P_in [13][0] = 2'd0; literals_P_in [13][1] = 2'd0; literals_P_in [13][2] = 2'd0; literals_P_in [13][3] = 2'd0; 
	literals_P_in [14][0] = 2'd0; literals_P_in [14][1] = 2'd0; literals_P_in [14][2] = 2'd0; literals_P_in [14][3] = 2'd0; 
	literals_P_in [15][0] = 2'd0; literals_P_in [15][1] = 2'd0; literals_P_in [15][2] = 2'd0; literals_P_in [15][3] = 2'd0; 
	#3 //Idle
	rst = 1'd0;  
	valid_in = 1'd0; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd0;  literals_in [2] = 2'd0;  literals_in [3] = 2'd0;
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	phase_in [8] = 1'd0; phase_in [9] = 1'd0; phase_in [10] = 1'd0; phase_in [11] = 1'd0; 
	phase_in [12] = 1'd0; phase_in [13] = 1'd0; phase_in [14] = 1'd0; phase_in [15] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; literals_P_in [0][3] = 2'd0; 
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; literals_P_in [1][3] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; literals_P_in [2][3] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0; literals_P_in [3][3] = 2'd0; 
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0; literals_P_in [4][3] = 2'd0; 
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0; literals_P_in [5][3] = 2'd0; 
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0; literals_P_in [6][3] = 2'd0; 
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0; literals_P_in [7][3] = 2'd0; 
	literals_P_in [8][0] = 2'd0; literals_P_in [8][1] = 2'd0; literals_P_in [8][2] = 2'd0; literals_P_in [8][3] = 2'd0; 
	literals_P_in [9][0] = 2'd0; literals_P_in [9][1] = 2'd0; literals_P_in [9][2] = 2'd0; literals_P_in [9][3] = 2'd0; 
	literals_P_in [10][0] = 2'd0; literals_P_in [10][1] = 2'd0; literals_P_in [10][2] = 2'd0; literals_P_in [10][3] = 2'd0; 
	literals_P_in [11][0] = 2'd0; literals_P_in [11][1] = 2'd0; literals_P_in [11][2] = 2'd0; literals_P_in [11][3] = 2'd0; 
	literals_P_in [12][0] = 2'd0; literals_P_in [12][1] = 2'd0; literals_P_in [12][2] = 2'd0; literals_P_in [12][3] = 2'd0; 
	literals_P_in [13][0] = 2'd0; literals_P_in [13][1] = 2'd0; literals_P_in [13][2] = 2'd0; literals_P_in [13][3] = 2'd0; 
	literals_P_in [14][0] = 2'd0; literals_P_in [14][1] = 2'd0; literals_P_in [14][2] = 2'd0; literals_P_in [14][3] = 2'd0; 
	literals_P_in [15][0] = 2'd0; literals_P_in [15][1] = 2'd0; literals_P_in [15][2] = 2'd0; literals_P_in [15][3] = 2'd0;
	#18 //Input: First row: +ZIII 
	rst = 1'd0;  
	valid_in = 1'd1; 
	literals_in [0] = 2'd1; literals_in [1] = 2'd0;  literals_in [2] = 2'd0; literals_in [3] = 2'd0;
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	phase_in [8] = 1'd0; phase_in [9] = 1'd0; phase_in [10] = 1'd0; phase_in [11] = 1'd0; 
	phase_in [12] = 1'd0; phase_in [13] = 1'd0; phase_in [14] = 1'd0; phase_in [15] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; literals_P_in [0][3] = 2'd0; 
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; literals_P_in [1][3] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; literals_P_in [2][3] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0; literals_P_in [3][3] = 2'd0; 
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0; literals_P_in [4][3] = 2'd0; 
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0; literals_P_in [5][3] = 2'd0; 
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0; literals_P_in [6][3] = 2'd0; 
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0; literals_P_in [7][3] = 2'd0; 
	literals_P_in [8][0] = 2'd0; literals_P_in [8][1] = 2'd0; literals_P_in [8][2] = 2'd0; literals_P_in [8][3] = 2'd0; 
	literals_P_in [9][0] = 2'd0; literals_P_in [9][1] = 2'd0; literals_P_in [9][2] = 2'd0; literals_P_in [9][3] = 2'd0; 
	literals_P_in [10][0] = 2'd0; literals_P_in [10][1] = 2'd0; literals_P_in [10][2] = 2'd0; literals_P_in [10][3] = 2'd0; 
	literals_P_in [11][0] = 2'd0; literals_P_in [11][1] = 2'd0; literals_P_in [11][2] = 2'd0; literals_P_in [11][3] = 2'd0; 
	literals_P_in [12][0] = 2'd0; literals_P_in [12][1] = 2'd0; literals_P_in [12][2] = 2'd0; literals_P_in [12][3] = 2'd0; 
	literals_P_in [13][0] = 2'd0; literals_P_in [13][1] = 2'd0; literals_P_in [13][2] = 2'd0; literals_P_in [13][3] = 2'd0; 
	literals_P_in [14][0] = 2'd0; literals_P_in [14][1] = 2'd0; literals_P_in [14][2] = 2'd0; literals_P_in [14][3] = 2'd0; 
	literals_P_in [15][0] = 2'd0; literals_P_in [15][1] = 2'd0; literals_P_in [15][2] = 2'd0; literals_P_in [15][3] = 2'd0;
	#10 //Input: Second row: +IZII 
	rst = 1'd0;  
	valid_in = 1'd1; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd1;  literals_in [2] = 2'd0; literals_in [3] = 2'd0;
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	phase_in [8] = 1'd0; phase_in [9] = 1'd0; phase_in [10] = 1'd0; phase_in [11] = 1'd0; 
	phase_in [12] = 1'd0; phase_in [13] = 1'd0; phase_in [14] = 1'd0; phase_in [15] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; literals_P_in [0][3] = 2'd0; 
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; literals_P_in [1][3] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; literals_P_in [2][3] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0; literals_P_in [3][3] = 2'd0; 
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0; literals_P_in [4][3] = 2'd0; 
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0; literals_P_in [5][3] = 2'd0; 
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0; literals_P_in [6][3] = 2'd0; 
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0; literals_P_in [7][3] = 2'd0; 
	literals_P_in [8][0] = 2'd0; literals_P_in [8][1] = 2'd0; literals_P_in [8][2] = 2'd0; literals_P_in [8][3] = 2'd0; 
	literals_P_in [9][0] = 2'd0; literals_P_in [9][1] = 2'd0; literals_P_in [9][2] = 2'd0; literals_P_in [9][3] = 2'd0; 
	literals_P_in [10][0] = 2'd0; literals_P_in [10][1] = 2'd0; literals_P_in [10][2] = 2'd0; literals_P_in [10][3] = 2'd0; 
	literals_P_in [11][0] = 2'd0; literals_P_in [11][1] = 2'd0; literals_P_in [11][2] = 2'd0; literals_P_in [11][3] = 2'd0; 
	literals_P_in [12][0] = 2'd0; literals_P_in [12][1] = 2'd0; literals_P_in [12][2] = 2'd0; literals_P_in [12][3] = 2'd0; 
	literals_P_in [13][0] = 2'd0; literals_P_in [13][1] = 2'd0; literals_P_in [13][2] = 2'd0; literals_P_in [13][3] = 2'd0; 
	literals_P_in [14][0] = 2'd0; literals_P_in [14][1] = 2'd0; literals_P_in [14][2] = 2'd0; literals_P_in [14][3] = 2'd0; 
	literals_P_in [15][0] = 2'd0; literals_P_in [15][1] = 2'd0; literals_P_in [15][2] = 2'd0; literals_P_in [15][3] = 2'd0;
	#10 //Input: Third row: +IIZI
	rst = 1'd0;  
	valid_in = 1'd1; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd0;  literals_in [2] = 2'd1; literals_in [3] = 2'd0;
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	phase_in [8] = 1'd0; phase_in [9] = 1'd0; phase_in [10] = 1'd0; phase_in [11] = 1'd0; 
	phase_in [12] = 1'd0; phase_in [13] = 1'd0; phase_in [14] = 1'd0; phase_in [15] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; literals_P_in [0][3] = 2'd0; 
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; literals_P_in [1][3] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; literals_P_in [2][3] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0; literals_P_in [3][3] = 2'd0; 
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0; literals_P_in [4][3] = 2'd0; 
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0; literals_P_in [5][3] = 2'd0; 
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0; literals_P_in [6][3] = 2'd0; 
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0; literals_P_in [7][3] = 2'd0; 
	literals_P_in [8][0] = 2'd0; literals_P_in [8][1] = 2'd0; literals_P_in [8][2] = 2'd0; literals_P_in [8][3] = 2'd0; 
	literals_P_in [9][0] = 2'd0; literals_P_in [9][1] = 2'd0; literals_P_in [9][2] = 2'd0; literals_P_in [9][3] = 2'd0; 
	literals_P_in [10][0] = 2'd0; literals_P_in [10][1] = 2'd0; literals_P_in [10][2] = 2'd0; literals_P_in [10][3] = 2'd0; 
	literals_P_in [11][0] = 2'd0; literals_P_in [11][1] = 2'd0; literals_P_in [11][2] = 2'd0; literals_P_in [11][3] = 2'd0; 
	literals_P_in [12][0] = 2'd0; literals_P_in [12][1] = 2'd0; literals_P_in [12][2] = 2'd0; literals_P_in [12][3] = 2'd0; 
	literals_P_in [13][0] = 2'd0; literals_P_in [13][1] = 2'd0; literals_P_in [13][2] = 2'd0; literals_P_in [13][3] = 2'd0; 
	literals_P_in [14][0] = 2'd0; literals_P_in [14][1] = 2'd0; literals_P_in [14][2] = 2'd0; literals_P_in [14][3] = 2'd0; 
	literals_P_in [15][0] = 2'd0; literals_P_in [15][1] = 2'd0; literals_P_in [15][2] = 2'd0; literals_P_in [15][3] = 2'd0;
	#10 //Input: Forth row: +IIIZ
	rst = 1'd0;  
	valid_in = 1'd1; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd0;  literals_in [2] = 2'd0; literals_in [3] = 2'd1;
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	phase_in [8] = 1'd0; phase_in [9] = 1'd0; phase_in [10] = 1'd0; phase_in [11] = 1'd0; 
	phase_in [12] = 1'd0; phase_in [13] = 1'd0; phase_in [14] = 1'd0; phase_in [15] = 1'd0;
	valid_P_in = 1'd1; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; literals_P_in [0][3] = 2'd0; 
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; literals_P_in [1][3] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; literals_P_in [2][3] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0; literals_P_in [3][3] = 2'd0; 
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0; literals_P_in [4][3] = 2'd0; 
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0; literals_P_in [5][3] = 2'd0; 
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0; literals_P_in [6][3] = 2'd0; 
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0; literals_P_in [7][3] = 2'd0; 
	literals_P_in [8][0] = 2'd0; literals_P_in [8][1] = 2'd0; literals_P_in [8][2] = 2'd0; literals_P_in [8][3] = 2'd0; 
	literals_P_in [9][0] = 2'd0; literals_P_in [9][1] = 2'd0; literals_P_in [9][2] = 2'd0; literals_P_in [9][3] = 2'd0; 
	literals_P_in [10][0] = 2'd0; literals_P_in [10][1] = 2'd0; literals_P_in [10][2] = 2'd0; literals_P_in [10][3] = 2'd0; 
	literals_P_in [11][0] = 2'd0; literals_P_in [11][1] = 2'd0; literals_P_in [11][2] = 2'd0; literals_P_in [11][3] = 2'd0; 
	literals_P_in [12][0] = 2'd0; literals_P_in [12][1] = 2'd0; literals_P_in [12][2] = 2'd0; literals_P_in [12][3] = 2'd0; 
	literals_P_in [13][0] = 2'd0; literals_P_in [13][1] = 2'd0; literals_P_in [13][2] = 2'd0; literals_P_in [13][3] = 2'd0; 
	literals_P_in [14][0] = 2'd0; literals_P_in [14][1] = 2'd0; literals_P_in [14][2] = 2'd0; literals_P_in [14][3] = 2'd0; 
	literals_P_in [15][0] = 2'd0; literals_P_in [15][1] = 2'd0; literals_P_in [15][2] = 2'd0; literals_P_in [15][3] = 2'd0;
	#10 //Idle
	rst = 1'd0;  
	valid_in = 1'd0; 
	literals_in [0] = 2'd0; literals_in [1] = 2'd0;  literals_in [2] = 2'd0;  literals_in [3] = 2'd0;
	phase_in [0] = 1'd0; phase_in [1] = 1'd0; phase_in [2] = 1'd0; phase_in [3] = 1'd0; 
	phase_in [4] = 1'd0; phase_in [5] = 1'd0; phase_in [6] = 1'd0; phase_in [7] = 1'd0;
	phase_in [8] = 1'd0; phase_in [9] = 1'd0; phase_in [10] = 1'd0; phase_in [11] = 1'd0; 
	phase_in [12] = 1'd0; phase_in [13] = 1'd0; phase_in [14] = 1'd0; phase_in [15] = 1'd0;
	valid_P_in = 1'd0; 
	literals_P_in [0][0] = 2'd0; literals_P_in [0][1] = 2'd0; literals_P_in [0][2] = 2'd0; literals_P_in [0][3] = 2'd0; 
	literals_P_in [1][0] = 2'd0; literals_P_in [1][1] = 2'd0; literals_P_in [1][2] = 2'd0; literals_P_in [1][3] = 2'd0; 
	literals_P_in [2][0] = 2'd0; literals_P_in [2][1] = 2'd0; literals_P_in [2][2] = 2'd0; literals_P_in [2][3] = 2'd0; 
	literals_P_in [3][0] = 2'd0; literals_P_in [3][1] = 2'd0; literals_P_in [3][2] = 2'd0; literals_P_in [3][3] = 2'd0; 
	literals_P_in [4][0] = 2'd0; literals_P_in [4][1] = 2'd0; literals_P_in [4][2] = 2'd0; literals_P_in [4][3] = 2'd0; 
	literals_P_in [5][0] = 2'd0; literals_P_in [5][1] = 2'd0; literals_P_in [5][2] = 2'd0; literals_P_in [5][3] = 2'd0; 
	literals_P_in [6][0] = 2'd0; literals_P_in [6][1] = 2'd0; literals_P_in [6][2] = 2'd0; literals_P_in [6][3] = 2'd0; 
	literals_P_in [7][0] = 2'd0; literals_P_in [7][1] = 2'd0; literals_P_in [7][2] = 2'd0; literals_P_in [7][3] = 2'd0; 
	literals_P_in [8][0] = 2'd0; literals_P_in [8][1] = 2'd0; literals_P_in [8][2] = 2'd0; literals_P_in [8][3] = 2'd0; 
	literals_P_in [9][0] = 2'd0; literals_P_in [9][1] = 2'd0; literals_P_in [9][2] = 2'd0; literals_P_in [9][3] = 2'd0; 
	literals_P_in [10][0] = 2'd0; literals_P_in [10][1] = 2'd0; literals_P_in [10][2] = 2'd0; literals_P_in [10][3] = 2'd0; 
	literals_P_in [11][0] = 2'd0; literals_P_in [11][1] = 2'd0; literals_P_in [11][2] = 2'd0; literals_P_in [11][3] = 2'd0; 
	literals_P_in [12][0] = 2'd0; literals_P_in [12][1] = 2'd0; literals_P_in [12][2] = 2'd0; literals_P_in [12][3] = 2'd0; 
	literals_P_in [13][0] = 2'd0; literals_P_in [13][1] = 2'd0; literals_P_in [13][2] = 2'd0; literals_P_in [13][3] = 2'd0; 
	literals_P_in [14][0] = 2'd0; literals_P_in [14][1] = 2'd0; literals_P_in [14][2] = 2'd0; literals_P_in [14][3] = 2'd0; 
	literals_P_in [15][0] = 2'd0; literals_P_in [15][1] = 2'd0; literals_P_in [15][2] = 2'd0; literals_P_in [15][3] = 2'd0;
	#30000
	$stop;
end
*/

/************************************************************GATE INFO*********************************************************/

wire [2:0] type_info [0:total_gate-1]; wire [phase_lookup-1:0] phase_shift_info [0:total_gate-1];
wire [31:0] pos_info [0:total_gate-1]; wire [31:0] pos2_info [0:total_gate-1]; wire [31:0] pos3_info [0:total_gate-1];

/*******************************************************3-QUBIT VERIFICATION******************************************************/
/*
//Nonstabilizer gates: 3-qubit
//GATE0 : Controlled Phase Shift(3) 0, 1
assign type_info[0] = 3'd4;  assign pos_info[0] = 32'd0;  assign pos2_info[0] = 32'd1;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd3;  
//GATE1 : Toffoli 1, 2, 0
assign type_info[1] = 3'd5;  assign pos_info[1] = 32'd1;  assign pos2_info[1] = 32'd2;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : Controlled Phase Shift(3): 1, 2
assign type_info[2] = 3'd4;  assign pos_info[2] = 32'd1;  assign pos2_info[2] = 32'd2;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd3;  
//GATE3 : Toffoli 0, 2, 1
assign type_info[3] = 3'd5;  assign pos_info[3] = 32'd0;  assign pos2_info[3] = 32'd2;  assign pos3_info[3] = 32'd1;  assign phase_shift_info[3] = 5'd0;  
*/

/*
//Randomized stabilizer gates: 3-qubit (3-qubit)
//GATE0 : CNOT 0,2
assign type_info[0] = 3'd2;  assign pos_info[0] = 32'd0;  assign pos2_info[0] = 32'd2;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd0;  
//GATE1 : H 2
assign type_info[1] = 3'd0;  assign pos_info[1] = 32'd2;  assign pos2_info[1] = 32'd0;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : P 2
assign type_info[2] = 3'd1;  assign pos_info[2] = 32'd2;  assign pos2_info[2] = 32'd0;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd0;  
//GATE3 : H 2
assign type_info[3] = 3'd0;  assign pos_info[3] = 32'd2;  assign pos2_info[3] = 32'd0;  assign pos3_info[3] = 32'd0;  assign phase_shift_info[3] = 5'd0;   
//GATE4 : H 2
assign type_info[4] = 3'd0;  assign pos_info[4] = 32'd2;  assign pos2_info[4] = 32'd0;  assign pos3_info[4] = 32'd0;  assign phase_shift_info[4] = 5'd0;  
//GATE5 : CNOT 1,0
assign type_info[5] = 3'd2;  assign pos_info[5] = 32'd1;  assign pos2_info[5] = 32'd0;  assign pos3_info[5] = 32'd0;  assign phase_shift_info[5] = 5'd0;  
//GATE6 : P 1 
assign type_info[6] = 3'd1;  assign pos_info[6] = 32'd1;  assign pos2_info[6] = 32'd0;  assign pos3_info[6] = 32'd0;  assign phase_shift_info[6] = 5'd0;   
//GATE7 : P 2
assign type_info[7] = 3'd1;  assign pos_info[7] = 32'd2;  assign pos2_info[7] = 32'd0;  assign pos3_info[7] = 32'd0;  assign phase_shift_info[7] = 5'd0;  
//GATE8 : H 0 
assign type_info[8] = 3'd0;  assign pos_info[8] = 32'd0;  assign pos2_info[8] = 32'd0;  assign pos3_info[8] = 32'd0;  assign phase_shift_info[8] = 5'd0;   
//GATE9 : P 1
assign type_info[9] = 3'd1;  assign pos_info[9] = 32'd1;  assign pos2_info[9] = 32'd0;  assign pos3_info[9] = 32'd0;  assign phase_shift_info[9] = 5'd0;  
//GATE10: CNOT 1,0
assign type_info[10] = 3'd2; assign pos_info[10] = 32'd1; assign pos2_info[10] = 32'd0; assign pos3_info[10] = 32'd0; assign phase_shift_info[10] = 5'd0;  
//GATE11: H 2
assign type_info[11] = 3'd0; assign pos_info[11] = 32'd2; assign pos2_info[11] = 32'd0; assign pos3_info[11] = 32'd0; assign phase_shift_info[11] = 5'd0;  
//GATE12: H 1 
assign type_info[12] = 3'd0; assign pos_info[12] = 32'd1; assign pos2_info[12] = 32'd0; assign pos3_info[12] = 32'd0; assign phase_shift_info[12] = 5'd0;  
//GATE13: P 0
assign type_info[13] = 3'd1; assign pos_info[13] = 32'd0; assign pos2_info[13] = 32'd0; assign pos3_info[13] = 32'd0; assign phase_shift_info[13] = 5'd0;  
//GATE14: CNOT 2,1
assign type_info[14] = 3'd2; assign pos_info[14] = 32'd2; assign pos2_info[14] = 32'd1; assign pos3_info[14] = 32'd0; assign phase_shift_info[14] = 5'd0;  
//GATE15: H 0
assign type_info[15] = 3'd0; assign pos_info[15] = 32'd0; assign pos2_info[15] = 32'd0; assign pos3_info[15] = 32'd0; assign phase_shift_info[15] = 5'd0;  
//GATE16: CNOT 0,2
assign type_info[16] = 3'd2; assign pos_info[16] = 32'd0; assign pos2_info[16] = 32'd2; assign pos3_info[16] = 32'd0; assign phase_shift_info[16] = 5'd0;  
//GATE17: H 1
assign type_info[17] = 3'd0; assign pos_info[17] = 32'd1; assign pos2_info[17] = 32'd0; assign pos3_info[17] = 32'd0; assign phase_shift_info[17] = 5'd0;  
//GATE18: CNOT 2,1
assign type_info[18] = 3'd2; assign pos_info[18] = 32'd2; assign pos2_info[18] = 32'd1; assign pos3_info[18] = 32'd0; assign phase_shift_info[18] = 5'd0;  
//GATE19: P 0
assign type_info[19] = 3'd1; assign pos_info[19] = 32'd0; assign pos2_info[19] = 32'd0; assign pos3_info[19] = 32'd0; assign phase_shift_info[19] = 5'd0;  
//GATE20: H 1
assign type_info[20] = 3'd0; assign pos_info[20] = 32'd1; assign pos2_info[20] = 32'd0; assign pos3_info[20] = 32'd0; assign phase_shift_info[20] = 5'd0;  
//GATE21: P 0
assign type_info[21] = 3'd1; assign pos_info[21] = 32'd0; assign pos2_info[21] = 32'd0; assign pos3_info[21] = 32'd0; assign phase_shift_info[21] = 5'd0;  
//GATE22: CNOT 0,1
assign type_info[22] = 3'd2; assign pos_info[22] = 32'd0; assign pos2_info[22] = 32'd1; assign pos3_info[22] = 32'd0; assign phase_shift_info[22] = 5'd0;  
//GATE23: H 0
assign type_info[23] = 3'd0; assign pos_info[23] = 32'd0; assign pos2_info[23] = 32'd0; assign pos3_info[23] = 32'd0; assign phase_shift_info[23] = 5'd0;  
//GATE24: H 1
assign type_info[24] = 3'd0; assign pos_info[24] = 32'd1; assign pos2_info[24] = 32'd0; assign pos3_info[24] = 32'd0; assign phase_shift_info[24] = 5'd0;  
//GATE25: CNOT 1,2
assign type_info[25] = 3'd2; assign pos_info[25] = 32'd1; assign pos2_info[25] = 32'd2; assign pos3_info[25] = 32'd0; assign phase_shift_info[25] = 5'd0;  
//GATE26: H 1
assign type_info[26] = 3'd0; assign pos_info[26] = 32'd1; assign pos2_info[26] = 32'd0; assign pos3_info[26] = 32'd0; assign phase_shift_info[26] = 5'd0;  
//GATE27: H 2
assign type_info[27] = 3'd0; assign pos_info[27] = 32'd2; assign pos2_info[27] = 32'd0; assign pos3_info[27] = 32'd0; assign phase_shift_info[27] = 5'd0;  
//GATE28: H 0
assign type_info[28] = 3'd0; assign pos_info[28] = 32'd0; assign pos2_info[28] = 32'd0; assign pos3_info[28] = 32'd0; assign phase_shift_info[28] = 5'd0;  
//GATE29: P 0
assign type_info[29] = 3'd1; assign pos_info[29] = 32'd0; assign pos2_info[29] = 32'd0; assign pos3_info[29] = 32'd0; assign phase_shift_info[29] = 5'd0;  
*/

/*
//Randomized stabilizer gates: 3-qubit (3_5)
//GATE0 : P_0
assign type_info[0] = 3'd1;  assign pos_info[0] = 32'd0;  assign pos2_info[0] = 32'd0;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd0;  
//GATE1 : P_0
assign type_info[1] = 3'd1;  assign pos_info[1] = 32'd0;  assign pos2_info[1] = 32'd0;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : CNOT_0,2
assign type_info[2] = 3'd2;  assign pos_info[2] = 32'd0;  assign pos2_info[2] = 32'd2;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd0;  
//GATE3 : P_0
assign type_info[3] = 3'd1;  assign pos_info[3] = 32'd0;  assign pos2_info[3] = 32'd0;  assign pos3_info[3] = 32'd0;  assign phase_shift_info[3] = 5'd0;   
//GATE4 : P_1
assign type_info[4] = 3'd1;  assign pos_info[4] = 32'd1;  assign pos2_info[4] = 32'd0;  assign pos3_info[4] = 32'd0;  assign phase_shift_info[4] = 5'd0;  
//GATE5 : CNOT_0,1
assign type_info[5] = 3'd2;  assign pos_info[5] = 32'd0;  assign pos2_info[5] = 32'd1;  assign pos3_info[5] = 32'd0;  assign phase_shift_info[5] = 5'd0;  
//GATE6 : H_2
assign type_info[6] = 3'd0;  assign pos_info[6] = 32'd2;  assign pos2_info[6] = 32'd0;  assign pos3_info[6] = 32'd0;  assign phase_shift_info[6] = 5'd0;   
//GATE7 : P_0
assign type_info[7] = 3'd1;  assign pos_info[7] = 32'd0;  assign pos2_info[7] = 32'd0;  assign pos3_info[7] = 32'd0;  assign phase_shift_info[7] = 5'd0;  
//GATE8 : H_2
assign type_info[8] = 3'd0;  assign pos_info[8] = 32'd2;  assign pos2_info[8] = 32'd0;  assign pos3_info[8] = 32'd0;  assign phase_shift_info[8] = 5'd0;   
//GATE9 : P_0
assign type_info[9] = 3'd1;  assign pos_info[9] = 32'd0;  assign pos2_info[9] = 32'd0;  assign pos3_info[9] = 32'd0;  assign phase_shift_info[9] = 5'd0;  
//GATE10: CNOT_2,1
assign type_info[10] = 3'd2; assign pos_info[10] = 32'd2; assign pos2_info[10] = 32'd1; assign pos3_info[10] = 32'd0; assign phase_shift_info[10] = 5'd0; 
//GATE11: H_0
assign type_info[11] = 3'd0; assign pos_info[11] = 32'd0; assign pos2_info[11] = 32'd0; assign pos3_info[11] = 32'd0; assign phase_shift_info[11] = 5'd0;  
//GATE12: CNOT_1,2
assign type_info[12] = 3'd2; assign pos_info[12] = 32'd1; assign pos2_info[12] = 32'd2; assign pos3_info[12] = 32'd0; assign phase_shift_info[12] = 5'd0;  
//GATE13: CNOT_2,1
assign type_info[13] = 3'd2; assign pos_info[13] = 32'd2; assign pos2_info[13] = 32'd1; assign pos3_info[13] = 32'd0; assign phase_shift_info[13] = 5'd0;  
//GATE14: P_0
assign type_info[14] = 3'd1; assign pos_info[14] = 32'd0; assign pos2_info[14] = 32'd0; assign pos3_info[14] = 32'd0; assign phase_shift_info[14] = 5'd0;  
//GATE15: CNOT_0,1
assign type_info[15] = 3'd2; assign pos_info[15] = 32'd0; assign pos2_info[15] = 32'd1; assign pos3_info[15] = 32'd0; assign phase_shift_info[15] = 5'd0;  
//GATE16: H_2
assign type_info[16] = 3'd0; assign pos_info[16] = 32'd2; assign pos2_info[16] = 32'd0; assign pos3_info[16] = 32'd0; assign phase_shift_info[16] = 5'd0;  
//GATE17: P_2
assign type_info[17] = 3'd1; assign pos_info[17] = 32'd2; assign pos2_info[17] = 32'd0; assign pos3_info[17] = 32'd0; assign phase_shift_info[17] = 5'd0;  
//GATE18: H_2
assign type_info[18] = 3'd0; assign pos_info[18] = 32'd2; assign pos2_info[18] = 32'd0; assign pos3_info[18] = 32'd0; assign phase_shift_info[18] = 5'd0;  
//GATE19: CNOT_2,0
assign type_info[19] = 3'd2; assign pos_info[19] = 32'd2; assign pos2_info[19] = 32'd0; assign pos3_info[19] = 32'd0; assign phase_shift_info[19] = 5'd0;  
//GATE20: H_2
assign type_info[20] = 3'd0; assign pos_info[20] = 32'd2; assign pos2_info[20] = 32'd0; assign pos3_info[20] = 32'd0; assign phase_shift_info[20] = 5'd0; 
//GATE21: CNOT_1,0
assign type_info[21] = 3'd2; assign pos_info[21] = 32'd1; assign pos2_info[21] = 32'd0; assign pos3_info[21] = 32'd0; assign phase_shift_info[21] = 5'd0;  
//GATE22: CNOT_2,1
assign type_info[22] = 3'd2; assign pos_info[22] = 32'd2; assign pos2_info[22] = 32'd1; assign pos3_info[22] = 32'd0; assign phase_shift_info[22] = 5'd0;  
//GATE23: CNOT_1,2
assign type_info[23] = 3'd2; assign pos_info[23] = 32'd1; assign pos2_info[23] = 32'd2; assign pos3_info[23] = 32'd0; assign phase_shift_info[23] = 5'd0;  
//GATE24: CNOT_2,1
assign type_info[24] = 3'd2; assign pos_info[24] = 32'd2; assign pos2_info[24] = 32'd1; assign pos3_info[24] = 32'd0; assign phase_shift_info[24] = 5'd0;  
//GATE25: H_2
assign type_info[25] = 3'd0; assign pos_info[25] = 32'd2; assign pos2_info[25] = 32'd0; assign pos3_info[25] = 32'd0; assign phase_shift_info[25] = 5'd0; 
//GATE26: CNOT_0,1
assign type_info[26] = 3'd2; assign pos_info[26] = 32'd0; assign pos2_info[26] = 32'd1; assign pos3_info[26] = 32'd0; assign phase_shift_info[26] = 5'd0;  
//GATE27: H_2
assign type_info[27] = 3'd0; assign pos_info[27] = 32'd2; assign pos2_info[27] = 32'd0; assign pos3_info[27] = 32'd0; assign phase_shift_info[27] = 5'd0;  
//GATE28: CNOT_1,0
assign type_info[28] = 3'd2; assign pos_info[28] = 32'd1; assign pos2_info[28] = 32'd0; assign pos3_info[28] = 32'd0; assign phase_shift_info[28] = 5'd0;  
//GATE29: H_0
assign type_info[29] = 3'd0; assign pos_info[29] = 32'd0; assign pos2_info[29] = 32'd0; assign pos3_info[29] = 32'd0; assign phase_shift_info[29] = 5'd0; 
*/


//Randomized stabilizer gates: 3-qubit (3_7)
//GATE0 : P_2
assign type_info[0] = 3'd1;  assign pos_info[0] = 32'd2;  assign pos2_info[0] = 32'd0;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd0;  
//GATE1 : CNOT_0,2
assign type_info[1] = 3'd2;  assign pos_info[1] = 32'd0;  assign pos2_info[1] = 32'd2;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : P_1
assign type_info[2] = 3'd1;  assign pos_info[2] = 32'd1;  assign pos2_info[2] = 32'd0;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd0;  
//GATE3 : CNOT_2,1
assign type_info[3] = 3'd2;  assign pos_info[3] = 32'd2;  assign pos2_info[3] = 32'd1;  assign pos3_info[3] = 32'd0;  assign phase_shift_info[3] = 5'd0;   
//GATE4 : P_2
assign type_info[4] = 3'd1;  assign pos_info[4] = 32'd2;  assign pos2_info[4] = 32'd0;  assign pos3_info[4] = 32'd0;  assign phase_shift_info[4] = 5'd0; 
//GATE5 : H_1
assign type_info[5] = 3'd0;  assign pos_info[5] = 32'd1;  assign pos2_info[5] = 32'd0;  assign pos3_info[5] = 32'd0;  assign phase_shift_info[5] = 5'd0;  
//GATE6 : CNOT_1,2
assign type_info[6] = 3'd2;  assign pos_info[6] = 32'd1;  assign pos2_info[6] = 32'd2;  assign pos3_info[6] = 32'd0;  assign phase_shift_info[6] = 5'd0;   
//GATE7 : CNOT_0,1
assign type_info[7] = 3'd2;  assign pos_info[7] = 32'd0;  assign pos2_info[7] = 32'd1;  assign pos3_info[7] = 32'd0;  assign phase_shift_info[7] = 5'd0;  
//GATE8 : H_2
assign type_info[8] = 3'd0;  assign pos_info[8] = 32'd2;  assign pos2_info[8] = 32'd0;  assign pos3_info[8] = 32'd0;  assign phase_shift_info[8] = 5'd0;   
//GATE9 : CNOT_0,2
assign type_info[9] = 3'd2;  assign pos_info[9] = 32'd0;  assign pos2_info[9] = 32'd2;  assign pos3_info[9] = 32'd0;  assign phase_shift_info[9] = 5'd0; 
//GATE10: P_2
assign type_info[10] = 3'd1; assign pos_info[10] = 32'd2; assign pos2_info[10] = 32'd0; assign pos3_info[10] = 32'd0; assign phase_shift_info[10] = 5'd0; 
//GATE11: P_0
assign type_info[11] = 3'd1; assign pos_info[11] = 32'd0; assign pos2_info[11] = 32'd0; assign pos3_info[11] = 32'd0; assign phase_shift_info[11] = 5'd0;  
//GATE12: CNOT_0,1
assign type_info[12] = 3'd2; assign pos_info[12] = 32'd0; assign pos2_info[12] = 32'd1; assign pos3_info[12] = 32'd0; assign phase_shift_info[12] = 5'd0;  
//GATE13: P_2
assign type_info[13] = 3'd1; assign pos_info[13] = 32'd2; assign pos2_info[13] = 32'd0; assign pos3_info[13] = 32'd0; assign phase_shift_info[13] = 5'd0;  
//GATE14: P_1
assign type_info[14] = 3'd1; assign pos_info[14] = 32'd1; assign pos2_info[14] = 32'd0; assign pos3_info[14] = 32'd0; assign phase_shift_info[14] = 5'd0;  
//GATE15: CNOT_2,0
assign type_info[15] = 3'd2; assign pos_info[15] = 32'd2; assign pos2_info[15] = 32'd0; assign pos3_info[15] = 32'd0; assign phase_shift_info[15] = 5'd0;  
//GATE16: H_0
assign type_info[16] = 3'd0; assign pos_info[16] = 32'd0; assign pos2_info[16] = 32'd0; assign pos3_info[16] = 32'd0; assign phase_shift_info[16] = 5'd0;  
//GATE17: P_0
assign type_info[17] = 3'd1; assign pos_info[17] = 32'd0; assign pos2_info[17] = 32'd0; assign pos3_info[17] = 32'd0; assign phase_shift_info[17] = 5'd0;  
//GATE18: H_0
assign type_info[18] = 3'd0; assign pos_info[18] = 32'd0; assign pos2_info[18] = 32'd0; assign pos3_info[18] = 32'd0; assign phase_shift_info[18] = 5'd0;  
//GATE19: P_1
assign type_info[19] = 3'd1; assign pos_info[19] = 32'd1; assign pos2_info[19] = 32'd0; assign pos3_info[19] = 32'd0; assign phase_shift_info[19] = 5'd0;
//GATE20: CNOT_0,1
assign type_info[20] = 3'd2; assign pos_info[20] = 32'd0; assign pos2_info[20] = 32'd1; assign pos3_info[20] = 32'd0; assign phase_shift_info[20] = 5'd0; 
//GATE21: P_1
assign type_info[21] = 3'd1; assign pos_info[21] = 32'd1; assign pos2_info[21] = 32'd0; assign pos3_info[21] = 32'd0; assign phase_shift_info[21] = 5'd0;  
//GATE22: CNOT_2,0
assign type_info[22] = 3'd2; assign pos_info[22] = 32'd2; assign pos2_info[22] = 32'd0; assign pos3_info[22] = 32'd0; assign phase_shift_info[22] = 5'd0;  
//GATE23: H_2
assign type_info[23] = 3'd0; assign pos_info[23] = 32'd2; assign pos2_info[23] = 32'd0; assign pos3_info[23] = 32'd0; assign phase_shift_info[23] = 5'd0;  
//GATE24: P_1
assign type_info[24] = 3'd1; assign pos_info[24] = 32'd1; assign pos2_info[24] = 32'd0; assign pos3_info[24] = 32'd0; assign phase_shift_info[24] = 5'd0;
//GATE25: H_0
assign type_info[25] = 3'd0; assign pos_info[25] = 32'd0; assign pos2_info[25] = 32'd0; assign pos3_info[25] = 32'd0; assign phase_shift_info[25] = 5'd0; 
//GATE26: CNOT_2,0
assign type_info[26] = 3'd2; assign pos_info[26] = 32'd2; assign pos2_info[26] = 32'd0; assign pos3_info[26] = 32'd0; assign phase_shift_info[26] = 5'd0;  
//GATE27: H_0
assign type_info[27] = 3'd0; assign pos_info[27] = 32'd0; assign pos2_info[27] = 32'd0; assign pos3_info[27] = 32'd0; assign phase_shift_info[27] = 5'd0;  
//GATE28: H_1
assign type_info[28] = 3'd0; assign pos_info[28] = 32'd1; assign pos2_info[28] = 32'd0; assign pos3_info[28] = 32'd0; assign phase_shift_info[28] = 5'd0;  
//GATE29: H_1
assign type_info[29] = 3'd0; assign pos_info[29] = 32'd1; assign pos2_info[29] = 32'd0; assign pos3_info[29] = 32'd0; assign phase_shift_info[29] = 5'd0; 


//QFT: 3-qubit
//GATE30: H 0
assign type_info[30] = 3'd0; assign pos_info[30] = 32'd0; assign pos2_info[30] = 32'd0; assign pos3_info[30] = 32'd0; assign phase_shift_info[30] = 5'd0; 
//GATE31: Controlled Phase-Shift(2) 1, 0
assign type_info[31] = 3'd4; assign pos_info[31] = 32'd1; assign pos2_info[31] = 32'd0; assign pos3_info[31] = 32'd0; assign phase_shift_info[31] = 5'd2;  
//GATE32: Controlled Phase-Shift(3) 2, 0
assign type_info[32] = 3'd4; assign pos_info[32] = 32'd2; assign pos2_info[32] = 32'd0; assign pos3_info[32] = 32'd0; assign phase_shift_info[32] = 5'd3;  
//GATE33: H 1
assign type_info[33] = 3'd0; assign pos_info[33] = 32'd1; assign pos2_info[33] = 32'd0; assign pos3_info[33] = 32'd0; assign phase_shift_info[33] = 5'd0; 
//GATE34: Controlled Phase-Shift(2) 2, 1
assign type_info[34] = 3'd4; assign pos_info[34] = 32'd2; assign pos2_info[34] = 32'd1; assign pos3_info[34] = 32'd0; assign phase_shift_info[34] = 5'd2;  
//GATE35: H 2
assign type_info[35] = 3'd0; assign pos_info[35] = 32'd2; assign pos2_info[35] = 32'd0; assign pos3_info[35] = 32'd0; assign phase_shift_info[35] = 5'd0;  


/******************************************************4-QUBIT VERIFICATION*******************************************************/
/*
//Randomized stabilizer gates: 4-qubit (4_2)
//GATE0 : H_1
assign type_info[0] = 3'd0;  assign pos_info[0] = 32'd1;  assign pos2_info[0] = 32'd0;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd0;  
//GATE1 : CNOT_3,1
assign type_info[1] = 3'd2;  assign pos_info[1] = 32'd3;  assign pos2_info[1] = 32'd1;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : P_1
assign type_info[2] = 3'd1;  assign pos_info[2] = 32'd1;  assign pos2_info[2] = 32'd0;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd0;  
//GATE3 : CNOT_1,0
assign type_info[3] = 3'd2;  assign pos_info[3] = 32'd1;  assign pos2_info[3] = 32'd0;  assign pos3_info[3] = 32'd0;  assign phase_shift_info[3] = 5'd0;   
//GATE4 : P_0
assign type_info[4] = 3'd1;  assign pos_info[4] = 32'd0;  assign pos2_info[4] = 32'd0;  assign pos3_info[4] = 32'd0;  assign phase_shift_info[4] = 5'd0; 
//GATE5 : CNOT_3,0
assign type_info[5] = 3'd2;  assign pos_info[5] = 32'd3;  assign pos2_info[5] = 32'd0;  assign pos3_info[5] = 32'd0;  assign phase_shift_info[5] = 5'd0;  
//GATE6 : CNOT_1,3
assign type_info[6] = 3'd2;  assign pos_info[6] = 32'd1;  assign pos2_info[6] = 32'd3;  assign pos3_info[6] = 32'd0;  assign phase_shift_info[6] = 5'd0;   
//GATE7 : P_0
assign type_info[7] = 3'd1;  assign pos_info[7] = 32'd0;  assign pos2_info[7] = 32'd0;  assign pos3_info[7] = 32'd0;  assign phase_shift_info[7] = 5'd0;  
//GATE8 : P_2
assign type_info[8] = 3'd1;  assign pos_info[8] = 32'd2;  assign pos2_info[8] = 32'd0;  assign pos3_info[8] = 32'd0;  assign phase_shift_info[8] = 5'd0;   
//GATE9 : CNOT_1,2
assign type_info[9] = 3'd2;  assign pos_info[9] = 32'd1;  assign pos2_info[9] = 32'd2;  assign pos3_info[9] = 32'd0;  assign phase_shift_info[9] = 5'd0;  
//GATE10: P_1
assign type_info[10] = 3'd1; assign pos_info[10] = 32'd1; assign pos2_info[10] = 32'd0; assign pos3_info[10] = 32'd0; assign phase_shift_info[10] = 5'd0;  
//GATE11: P_2
assign type_info[11] = 3'd1; assign pos_info[11] = 32'd2; assign pos2_info[11] = 32'd0; assign pos3_info[11] = 32'd0; assign phase_shift_info[11] = 5'd0;  
//GATE12: P_3
assign type_info[12] = 3'd1; assign pos_info[12] = 32'd3; assign pos2_info[12] = 32'd0; assign pos3_info[12] = 32'd0; assign phase_shift_info[12] = 5'd0;  
//GATE13: H_0
assign type_info[13] = 3'd0; assign pos_info[13] = 32'd0; assign pos2_info[13] = 32'd0; assign pos3_info[13] = 32'd0; assign phase_shift_info[13] = 5'd0;  
//GATE14: P_3
assign type_info[14] = 3'd1; assign pos_info[14] = 32'd3; assign pos2_info[14] = 32'd0; assign pos3_info[14] = 32'd0; assign phase_shift_info[14] = 5'd0;  
//GATE15: CNOT_1,2
assign type_info[15] = 3'd2; assign pos_info[15] = 32'd1; assign pos2_info[15] = 32'd2; assign pos3_info[15] = 32'd0; assign phase_shift_info[15] = 5'd0;  
//GATE16: CNOT_2,3
assign type_info[16] = 3'd2; assign pos_info[16] = 32'd2; assign pos2_info[16] = 32'd3; assign pos3_info[16] = 32'd0; assign phase_shift_info[16] = 5'd0;  
//GATE17: H_0
assign type_info[17] = 3'd0; assign pos_info[17] = 32'd0; assign pos2_info[17] = 32'd0; assign pos3_info[17] = 32'd0; assign phase_shift_info[17] = 5'd0;  
//GATE18: CNOT_1,3
assign type_info[18] = 3'd2; assign pos_info[18] = 32'd1; assign pos2_info[18] = 32'd3; assign pos3_info[18] = 32'd0; assign phase_shift_info[18] = 5'd0;  
//GATE19: CNOT_1,2
assign type_info[19] = 3'd2; assign pos_info[19] = 32'd1; assign pos2_info[19] = 32'd2; assign pos3_info[19] = 32'd0; assign phase_shift_info[19] = 5'd0;  
//GATE20: CNOT_2,3
assign type_info[20] = 3'd2; assign pos_info[20] = 32'd2; assign pos2_info[20] = 32'd3; assign pos3_info[20] = 32'd0; assign phase_shift_info[20] = 5'd0;  
//GATE21: P_2
assign type_info[21] = 3'd1; assign pos_info[21] = 32'd2; assign pos2_info[21] = 32'd0; assign pos3_info[21] = 32'd0; assign phase_shift_info[21] = 5'd0;  
//GATE22: P_3
assign type_info[22] = 3'd1; assign pos_info[22] = 32'd3; assign pos2_info[22] = 32'd0; assign pos3_info[22] = 32'd0; assign phase_shift_info[22] = 5'd0;  
//GATE23: H_2
assign type_info[23] = 3'd0; assign pos_info[23] = 32'd2; assign pos2_info[23] = 32'd0; assign pos3_info[23] = 32'd0; assign phase_shift_info[23] = 5'd0;  
//GATE24: CNOT_2,3
assign type_info[24] = 3'd2; assign pos_info[24] = 32'd2; assign pos2_info[24] = 32'd3; assign pos3_info[24] = 32'd0; assign phase_shift_info[24] = 5'd0;  
//GATE25: H_3
assign type_info[25] = 3'd0; assign pos_info[25] = 32'd3; assign pos2_info[25] = 32'd0; assign pos3_info[25] = 32'd0; assign phase_shift_info[25] = 5'd0;  
//GATE26: CNOT_1,0
assign type_info[26] = 3'd2; assign pos_info[26] = 32'd1; assign pos2_info[26] = 32'd0; assign pos3_info[26] = 32'd0; assign phase_shift_info[26] = 5'd0;  
//GATE27: H_1
assign type_info[27] = 3'd0; assign pos_info[27] = 32'd1; assign pos2_info[27] = 32'd0; assign pos3_info[27] = 32'd0; assign phase_shift_info[27] = 5'd0;  
//GATE28: H_2
assign type_info[28] = 3'd0; assign pos_info[28] = 32'd2; assign pos2_info[28] = 32'd0; assign pos3_info[28] = 32'd0; assign phase_shift_info[28] = 5'd0;  
//GATE29: H_3
assign type_info[29] = 3'd0; assign pos_info[29] = 32'd3; assign pos2_info[29] = 32'd0; assign pos3_info[29] = 32'd0; assign phase_shift_info[29] = 5'd0;  
*/

/*
//Randomized stabilizer gates: 4-qubit (4_3)
//GATE0 : P_0
assign type_info[0] = 3'd1;  assign pos_info[0] = 32'd0;  assign pos2_info[0] = 32'd0;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd0;  
//GATE1 : P_1
assign type_info[1] = 3'd1;  assign pos_info[1] = 32'd1;  assign pos2_info[1] = 32'd0;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : CNOT_2,0
assign type_info[2] = 3'd2;  assign pos_info[2] = 32'd2;  assign pos2_info[2] = 32'd0;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd0;  
//GATE3 : CNOT_1,0
assign type_info[3] = 3'd2;  assign pos_info[3] = 32'd1;  assign pos2_info[3] = 32'd0;  assign pos3_info[3] = 32'd0;  assign phase_shift_info[3] = 5'd0;   
//GATE4 : CNOT_1,2
assign type_info[4] = 3'd2;  assign pos_info[4] = 32'd1;  assign pos2_info[4] = 32'd2;  assign pos3_info[4] = 32'd0;  assign phase_shift_info[4] = 5'd0; 
//GATE5 : P_2
assign type_info[5] = 3'd1;  assign pos_info[5] = 32'd2;  assign pos2_info[5] = 32'd0;  assign pos3_info[5] = 32'd0;  assign phase_shift_info[5] = 5'd0;  
//GATE6 : P_3
assign type_info[6] = 3'd1;  assign pos_info[6] = 32'd3;  assign pos2_info[6] = 32'd0;  assign pos3_info[6] = 32'd0;  assign phase_shift_info[6] = 5'd0;   
//GATE7 : H_1
assign type_info[7] = 3'd0;  assign pos_info[7] = 32'd1;  assign pos2_info[7] = 32'd0;  assign pos3_info[7] = 32'd0;  assign phase_shift_info[7] = 5'd0;  
//GATE8 : CNOT_3,2
assign type_info[8] = 3'd2;  assign pos_info[8] = 32'd3;  assign pos2_info[8] = 32'd2;  assign pos3_info[8] = 32'd0;  assign phase_shift_info[8] = 5'd0;   
//GATE9 : H_3
assign type_info[9] = 3'd0;  assign pos_info[9] = 32'd3;  assign pos2_info[9] = 32'd0;  assign pos3_info[9] = 32'd0;  assign phase_shift_info[9] = 5'd0;  
//GATE10: CNOT_0,2
assign type_info[10] = 3'd2; assign pos_info[10] = 32'd0; assign pos2_info[10] = 32'd2; assign pos3_info[10] = 32'd0; assign phase_shift_info[10] = 5'd0;  
//GATE11: P_2
assign type_info[11] = 3'd1; assign pos_info[11] = 32'd2; assign pos2_info[11] = 32'd0; assign pos3_info[11] = 32'd0; assign phase_shift_info[11] = 5'd0;  
//GATE12: P_1
assign type_info[12] = 3'd1; assign pos_info[12] = 32'd1; assign pos2_info[12] = 32'd0; assign pos3_info[12] = 32'd0; assign phase_shift_info[12] = 5'd0;  
//GATE13: H_1
assign type_info[13] = 3'd0; assign pos_info[13] = 32'd1; assign pos2_info[13] = 32'd0; assign pos3_info[13] = 32'd0; assign phase_shift_info[13] = 5'd0;  
//GATE14: P_1
assign type_info[14] = 3'd1; assign pos_info[14] = 32'd1; assign pos2_info[14] = 32'd0; assign pos3_info[14] = 32'd0; assign phase_shift_info[14] = 5'd0; 
//GATE15: P_0
assign type_info[15] = 3'd1; assign pos_info[15] = 32'd0; assign pos2_info[15] = 32'd0; assign pos3_info[15] = 32'd0; assign phase_shift_info[15] = 5'd0;  
//GATE16: CNOT_1,2
assign type_info[16] = 3'd2; assign pos_info[16] = 32'd1; assign pos2_info[16] = 32'd2; assign pos3_info[16] = 32'd0; assign phase_shift_info[16] = 5'd0;  
//GATE17: H_3
assign type_info[17] = 3'd0; assign pos_info[17] = 32'd3; assign pos2_info[17] = 32'd0; assign pos3_info[17] = 32'd0; assign phase_shift_info[17] = 5'd0;  
//GATE18: P_2
assign type_info[18] = 3'd1; assign pos_info[18] = 32'd2; assign pos2_info[18] = 32'd0; assign pos3_info[18] = 32'd0; assign phase_shift_info[18] = 5'd0;  
//GATE19: P_3
assign type_info[19] = 3'd1; assign pos_info[19] = 32'd3; assign pos2_info[19] = 32'd0; assign pos3_info[19] = 32'd0; assign phase_shift_info[19] = 5'd0;  
//GATE20: CNOT_1,0
assign type_info[20] = 3'd2; assign pos_info[20] = 32'd1; assign pos2_info[20] = 32'd0; assign pos3_info[20] = 32'd0; assign phase_shift_info[20] = 5'd0;  
//GATE21: CNOT_2,0
assign type_info[21] = 3'd2; assign pos_info[21] = 32'd2; assign pos2_info[21] = 32'd0; assign pos3_info[21] = 32'd0; assign phase_shift_info[21] = 5'd0;  
//GATE22: CNOT_3,2
assign type_info[22] = 3'd2; assign pos_info[22] = 32'd3; assign pos2_info[22] = 32'd2; assign pos3_info[22] = 32'd0; assign phase_shift_info[22] = 5'd0;  
//GATE23: CNOT_2,1
assign type_info[23] = 3'd2; assign pos_info[23] = 32'd2; assign pos2_info[23] = 32'd1; assign pos3_info[23] = 32'd0; assign phase_shift_info[23] = 5'd0;  
//GATE24: P_0
assign type_info[24] = 3'd1; assign pos_info[24] = 32'd0; assign pos2_info[24] = 32'd0; assign pos3_info[24] = 32'd0; assign phase_shift_info[24] = 5'd0;
//GATE25: H_3
assign type_info[25] = 3'd0; assign pos_info[25] = 32'd3; assign pos2_info[25] = 32'd0; assign pos3_info[25] = 32'd0; assign phase_shift_info[25] = 5'd0;  
//GATE26: P_1
assign type_info[26] = 3'd1; assign pos_info[26] = 32'd1; assign pos2_info[26] = 32'd0; assign pos3_info[26] = 32'd0; assign phase_shift_info[26] = 5'd0;  
//GATE27: CNOT_1,2
assign type_info[27] = 3'd2; assign pos_info[27] = 32'd1; assign pos2_info[27] = 32'd2; assign pos3_info[27] = 32'd0; assign phase_shift_info[27] = 5'd0;  
//GATE28: H_3
assign type_info[28] = 3'd0; assign pos_info[28] = 32'd3; assign pos2_info[28] = 32'd0; assign pos3_info[28] = 32'd0; assign phase_shift_info[28] = 5'd0;  
//GATE29: P_1
assign type_info[29] = 3'd1; assign pos_info[29] = 32'd1; assign pos2_info[29] = 32'd0; assign pos3_info[29] = 32'd0; assign phase_shift_info[29] = 5'd0; 
*/

/*
//Randomized stabilizer gates: 4-qubit (4_5)
//GATE0 : CNOT_3,1
assign type_info[0] = 3'd2;  assign pos_info[0] = 32'd3;  assign pos2_info[0] = 32'd1;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd0;  
//GATE1 : CNOT_2,3
assign type_info[1] = 3'd2;  assign pos_info[1] = 32'd2;  assign pos2_info[1] = 32'd3;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : P_1
assign type_info[2] = 3'd1;  assign pos_info[2] = 32'd1;  assign pos2_info[2] = 32'd0;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd0;  
//GATE3 : H_0
assign type_info[3] = 3'd0;  assign pos_info[3] = 32'd0;  assign pos2_info[3] = 32'd0;  assign pos3_info[3] = 32'd0;  assign phase_shift_info[3] = 5'd0;   
//GATE4 : H_1
assign type_info[4] = 3'd0;  assign pos_info[4] = 32'd1;  assign pos2_info[4] = 32'd0;  assign pos3_info[4] = 32'd0;  assign phase_shift_info[4] = 5'd0; 
//GATE5 : P_2
assign type_info[5] = 3'd1;  assign pos_info[5] = 32'd2;  assign pos2_info[5] = 32'd0;  assign pos3_info[5] = 32'd0;  assign phase_shift_info[5] = 5'd0;  
//GATE6 : P_2
assign type_info[6] = 3'd1;  assign pos_info[6] = 32'd2;  assign pos2_info[6] = 32'd0;  assign pos3_info[6] = 32'd0;  assign phase_shift_info[6] = 5'd0;   
//GATE7 : H_3
assign type_info[7] = 3'd0;  assign pos_info[7] = 32'd3;  assign pos2_info[7] = 32'd0;  assign pos3_info[7] = 32'd0;  assign phase_shift_info[7] = 5'd0;  
//GATE8 : H_1
assign type_info[8] = 3'd0;  assign pos_info[8] = 32'd1;  assign pos2_info[8] = 32'd0;  assign pos3_info[8] = 32'd0;  assign phase_shift_info[8] = 5'd0;   
//GATE9 : P_3
assign type_info[9] = 3'd1;  assign pos_info[9] = 32'd3;  assign pos2_info[9] = 32'd0;  assign pos3_info[9] = 32'd0;  assign phase_shift_info[9] = 5'd0;  
//GATE10: P_0
assign type_info[10] = 3'd1; assign pos_info[10] = 32'd0; assign pos2_info[10] = 32'd0; assign pos3_info[10] = 32'd0; assign phase_shift_info[10] = 5'd0;  
//GATE11: P_2
assign type_info[11] = 3'd1; assign pos_info[11] = 32'd2; assign pos2_info[11] = 32'd0; assign pos3_info[11] = 32'd0; assign phase_shift_info[11] = 5'd0;  
//GATE12: H_2
assign type_info[12] = 3'd0; assign pos_info[12] = 32'd2; assign pos2_info[12] = 32'd0; assign pos3_info[12] = 32'd0; assign phase_shift_info[12] = 5'd0;  
//GATE13: P_2
assign type_info[13] = 3'd1; assign pos_info[13] = 32'd2; assign pos2_info[13] = 32'd0; assign pos3_info[13] = 32'd0; assign phase_shift_info[13] = 5'd0;  
//GATE14: P_2
assign type_info[14] = 3'd1; assign pos_info[14] = 32'd2; assign pos2_info[14] = 32'd0; assign pos3_info[14] = 32'd0; assign phase_shift_info[14] = 5'd0;  
//GATE15: P_1
assign type_info[15] = 3'd1; assign pos_info[15] = 32'd1; assign pos2_info[15] = 32'd0; assign pos3_info[15] = 32'd0; assign phase_shift_info[15] = 5'd0;  
//GATE16: H_2
assign type_info[16] = 3'd0; assign pos_info[16] = 32'd2; assign pos2_info[16] = 32'd0; assign pos3_info[16] = 32'd0; assign phase_shift_info[16] = 5'd0;  
//GATE17: H_2
assign type_info[17] = 3'd0; assign pos_info[17] = 32'd2; assign pos2_info[17] = 32'd0; assign pos3_info[17] = 32'd0; assign phase_shift_info[17] = 5'd0;  
//GATE18: CNOT_2,0
assign type_info[18] = 3'd2; assign pos_info[18] = 32'd2; assign pos2_info[18] = 32'd0; assign pos3_info[18] = 32'd0; assign phase_shift_info[18] = 5'd0;  
//GATE19: CNOT_3,2
assign type_info[19] = 3'd2; assign pos_info[19] = 32'd3; assign pos2_info[19] = 32'd2; assign pos3_info[19] = 32'd0; assign phase_shift_info[19] = 5'd0;  
//GATE20: CNOT_2,3
assign type_info[20] = 3'd2; assign pos_info[20] = 32'd2; assign pos2_info[20] = 32'd3; assign pos3_info[20] = 32'd0; assign phase_shift_info[20] = 5'd0;  
//GATE21: CNOT_0,3
assign type_info[21] = 3'd2; assign pos_info[21] = 32'd0; assign pos2_info[21] = 32'd3; assign pos3_info[21] = 32'd0; assign phase_shift_info[21] = 5'd0;  
//GATE22: P_1
assign type_info[22] = 3'd1; assign pos_info[22] = 32'd1; assign pos2_info[22] = 32'd0; assign pos3_info[22] = 32'd0; assign phase_shift_info[22] = 5'd0;  
//GATE23: P_2
assign type_info[23] = 3'd1; assign pos_info[23] = 32'd2; assign pos2_info[23] = 32'd0; assign pos3_info[23] = 32'd0; assign phase_shift_info[23] = 5'd0;  
//GATE24: H_3
assign type_info[24] = 3'd0; assign pos_info[24] = 32'd3; assign pos2_info[24] = 32'd0; assign pos3_info[24] = 32'd0; assign phase_shift_info[24] = 5'd0;  
//GATE25: H_3
assign type_info[25] = 3'd0; assign pos_info[25] = 32'd3; assign pos2_info[25] = 32'd0; assign pos3_info[25] = 32'd0; assign phase_shift_info[25] = 5'd0;  
//GATE26: H_0
assign type_info[26] = 3'd0; assign pos_info[26] = 32'd0; assign pos2_info[26] = 32'd0; assign pos3_info[26] = 32'd0; assign phase_shift_info[26] = 5'd0;  
//GATE27: P_3
assign type_info[27] = 3'd1; assign pos_info[27] = 32'd3; assign pos2_info[27] = 32'd0; assign pos3_info[27] = 32'd0; assign phase_shift_info[27] = 5'd0;  
//GATE28: P_1
assign type_info[28] = 3'd1; assign pos_info[28] = 32'd1; assign pos2_info[28] = 32'd0; assign pos3_info[28] = 32'd0; assign phase_shift_info[28] = 5'd0;  
//GATE29: P_1
assign type_info[29] = 3'd1; assign pos_info[29] = 32'd1; assign pos2_info[29] = 32'd0; assign pos3_info[29] = 32'd0; assign phase_shift_info[29] = 5'd0;  
*/

/*
//QFT: 4-qubit
//GATE30: H_0
assign type_info[30] = 3'd0; assign pos_info[30] = 32'd0; assign pos2_info[30] = 32'd0; assign pos3_info[30] = 32'd0; assign phase_shift_info[30] = 5'd0; 
//GATE31: Controlled Phase-Shift(2) 1, 0
assign type_info[31] = 3'd4; assign pos_info[31] = 32'd1; assign pos2_info[31] = 32'd0; assign pos3_info[31] = 32'd0; assign phase_shift_info[31] = 5'd2; 
//GATE32: Controlled Phase-Shift(3) 2, 0
assign type_info[32] = 3'd4; assign pos_info[32] = 32'd2; assign pos2_info[32] = 32'd0; assign pos3_info[32] = 32'd0; assign phase_shift_info[32] = 5'd3; 
//GATE33: Controlled Phase-Shift(4) 3, 0
assign type_info[33] = 3'd4; assign pos_info[33] = 32'd3; assign pos2_info[33] = 32'd0; assign pos3_info[33] = 32'd0; assign phase_shift_info[33] = 5'd4; 
//GATE34: H_1
assign type_info[34] = 3'd0; assign pos_info[34] = 32'd1; assign pos2_info[34] = 32'd0; assign pos3_info[34] = 32'd0; assign phase_shift_info[34] = 5'd0; 
//GATE35: Controlled Phase-Shift(2) 2, 1
assign type_info[35] = 3'd4; assign pos_info[35] = 32'd2; assign pos2_info[35] = 32'd1; assign pos3_info[35] = 32'd0; assign phase_shift_info[35] = 5'd2; 
//GATE36: Controlled Phase-Shift(3) 3, 1
assign type_info[36] = 3'd4; assign pos_info[36] = 32'd3; assign pos2_info[36] = 32'd1; assign pos3_info[36] = 32'd0; assign phase_shift_info[36] = 5'd3; 
//GATE37: H_2
assign type_info[37] = 3'd0; assign pos_info[37] = 32'd2; assign pos2_info[37] = 32'd0; assign pos3_info[37] = 32'd0; assign phase_shift_info[37] = 5'd0;  
//GATE38: Controlled Phase-Shift(2) 3, 2
assign type_info[38] = 3'd4; assign pos_info[38] = 32'd3; assign pos2_info[38] = 32'd2; assign pos3_info[38] = 32'd0; assign phase_shift_info[38] = 5'd2;  
//GATE39: H_3
assign type_info[39] = 3'd0; assign pos_info[39] = 32'd3; assign pos2_info[39] = 32'd0; assign pos3_info[39] = 32'd0; assign phase_shift_info[39] = 5'd0; 
*/

/*
//Randomized stabilizer & nonstabilizer gates: 4-qubit_1
//GATE0 : H_1
assign type_info[0] = 3'd0;  assign pos_info[0] = 32'd1;  assign pos2_info[0] = 32'd0;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd0;  
//GATE1 : H_0
assign type_info[1] = 3'd0;  assign pos_info[1] = 32'd0;  assign pos2_info[1] = 32'd0;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : CNOT_2,0
assign type_info[2] = 3'd2;  assign pos_info[2] = 32'd2;  assign pos2_info[2] = 32'd0;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd0;  
//GATE3 : P_3
assign type_info[3] = 3'd1;  assign pos_info[3] = 32'd3;  assign pos2_info[3] = 32'd0;  assign pos3_info[3] = 32'd0;  assign phase_shift_info[3] = 5'd0;   
//GATE4 : CNOT_2,0
assign type_info[4] = 3'd2;  assign pos_info[4] = 32'd2;  assign pos2_info[4] = 32'd0;  assign pos3_info[4] = 32'd0;  assign phase_shift_info[4] = 5'd0; 
//GATE5 : CNOT_3,1
assign type_info[5] = 3'd2;  assign pos_info[5] = 32'd3;  assign pos2_info[5] = 32'd1;  assign pos3_info[5] = 32'd0;  assign phase_shift_info[5] = 5'd0;  
//GATE6 : P_2
assign type_info[6] = 3'd1;  assign pos_info[6] = 32'd2;  assign pos2_info[6] = 32'd0;  assign pos3_info[6] = 32'd0;  assign phase_shift_info[6] = 5'd0;   
//GATE7 : P_1
assign type_info[7] = 3'd1;  assign pos_info[7] = 32'd1;  assign pos2_info[7] = 32'd0;  assign pos3_info[7] = 32'd0;  assign phase_shift_info[7] = 5'd0;  
//GATE8 : TOF_3,2,1
assign type_info[8] = 3'd5;  assign pos_info[8] = 32'd3;  assign pos2_info[8] = 32'd2;  assign pos3_info[8] = 32'd1;  assign phase_shift_info[8] = 5'd0; 
//GATE9 : CNOT_2,3
assign type_info[9] = 3'd2;  assign pos_info[9] = 32'd2;  assign pos2_info[9] = 32'd3;  assign pos3_info[9] = 32'd0;  assign phase_shift_info[9] = 5'd0;  
//GATE10: CNOT_2,1
assign type_info[10] = 3'd2; assign pos_info[10] = 32'd2; assign pos2_info[10] = 32'd1; assign pos3_info[10] = 32'd0; assign phase_shift_info[10] = 5'd0; 
//GATE11: TOF_3,0,2
assign type_info[11] = 3'd5; assign pos_info[11] = 32'd3; assign pos2_info[11] = 32'd0; assign pos3_info[11] = 32'd2; assign phase_shift_info[11] = 5'd0;  
//GATE12: H_0
assign type_info[12] = 3'd0; assign pos_info[12] = 32'd0; assign pos2_info[12] = 32'd0; assign pos3_info[12] = 32'd0; assign phase_shift_info[12] = 5'd0;  
//GATE13: CNOT_0,1
assign type_info[13] = 3'd2; assign pos_info[13] = 32'd0; assign pos2_info[13] = 32'd1; assign pos3_info[13] = 32'd0; assign phase_shift_info[13] = 5'd0;  
//GATE14: CPS_3,1(3)
assign type_info[14] = 3'd4; assign pos_info[14] = 32'd3; assign pos2_info[14] = 32'd1; assign pos3_info[14] = 32'd0; assign phase_shift_info[14] = 5'd3;
//GATE15: CNOT_0,2
assign type_info[15] = 3'd2; assign pos_info[15] = 32'd0; assign pos2_info[15] = 32'd2; assign pos3_info[15] = 32'd0; assign phase_shift_info[15] = 5'd0;  
//GATE16: CPS_0,1(3)
assign type_info[16] = 3'd4; assign pos_info[16] = 32'd0; assign pos2_info[16] = 32'd1; assign pos3_info[16] = 32'd0; assign phase_shift_info[16] = 5'd3;  
//GATE17: P_0
assign type_info[17] = 3'd1; assign pos_info[17] = 32'd0; assign pos2_info[17] = 32'd0; assign pos3_info[17] = 32'd0; assign phase_shift_info[17] = 5'd0;  
//GATE18: CNOT_1,2
assign type_info[18] = 3'd2; assign pos_info[18] = 32'd1; assign pos2_info[18] = 32'd2; assign pos3_info[18] = 32'd0; assign phase_shift_info[18] = 5'd0;  
//GATE19: TOF_2,1,3
assign type_info[19] = 3'd5; assign pos_info[19] = 32'd2; assign pos2_info[19] = 32'd1; assign pos3_info[19] = 32'd3; assign phase_shift_info[19] = 5'd0; 
//GATE20: CPS_2,0(2)
assign type_info[20] = 3'd4; assign pos_info[20] = 32'd2; assign pos2_info[20] = 32'd0; assign pos3_info[20] = 32'd0; assign phase_shift_info[20] = 5'd2;  
//GATE21: H_2
assign type_info[21] = 3'd0; assign pos_info[21] = 32'd2; assign pos2_info[21] = 32'd0; assign pos3_info[21] = 32'd0; assign phase_shift_info[21] = 5'd0;  
//GATE22: CNOT_1,3
assign type_info[22] = 3'd2; assign pos_info[22] = 32'd1; assign pos2_info[22] = 32'd3; assign pos3_info[22] = 32'd0; assign phase_shift_info[22] = 5'd0;  
//GATE23: CPS_0,1(3)
assign type_info[23] = 3'd4; assign pos_info[23] = 32'd0; assign pos2_info[23] = 32'd1; assign pos3_info[23] = 32'd0; assign phase_shift_info[23] = 5'd3;  
//GATE24: P_0
assign type_info[24] = 3'd1; assign pos_info[24] = 32'd0; assign pos2_info[24] = 32'd0; assign pos3_info[24] = 32'd0; assign phase_shift_info[24] = 5'd0; 
//GATE25: H_1
assign type_info[25] = 3'd0; assign pos_info[25] = 32'd1; assign pos2_info[25] = 32'd0; assign pos3_info[25] = 32'd0; assign phase_shift_info[25] = 5'd0;  
//GATE26: TOF_1,0,2
assign type_info[26] = 3'd5; assign pos_info[26] = 32'd1; assign pos2_info[26] = 32'd0; assign pos3_info[26] = 32'd2; assign phase_shift_info[26] = 5'd0;  
//GATE27: CNOT_3,0
assign type_info[27] = 3'd2; assign pos_info[27] = 32'd3; assign pos2_info[27] = 32'd0; assign pos3_info[27] = 32'd0; assign phase_shift_info[27] = 5'd0;  
//GATE28: H_0
assign type_info[28] = 3'd0; assign pos_info[28] = 32'd0; assign pos2_info[28] = 32'd0; assign pos3_info[28] = 32'd0; assign phase_shift_info[28] = 5'd0;  
//GATE29: CPS_2,3(2)
assign type_info[29] = 3'd4; assign pos_info[29] = 32'd2; assign pos2_info[29] = 32'd3; assign pos3_info[29] = 32'd0; assign phase_shift_info[29] = 5'd2;  
*/

/*
//Randomized stabilizer & nonstabilizer gates: 4-qubit_2
//GATE0 : H_2
assign type_info[0] = 3'd0;  assign pos_info[0] = 32'd2;  assign pos2_info[0] = 32'd0;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd0;  
//GATE1 : CNOT_0,3
assign type_info[1] = 3'd2;  assign pos_info[1] = 32'd0;  assign pos2_info[1] = 32'd3;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : P_0
assign type_info[2] = 3'd1;  assign pos_info[2] = 32'd0;  assign pos2_info[2] = 32'd0;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd0;  
//GATE3 : CNOT_0,2
assign type_info[3] = 3'd2;  assign pos_info[3] = 32'd0;  assign pos2_info[3] = 32'd2;  assign pos3_info[3] = 32'd0;  assign phase_shift_info[3] = 5'd0;   
//GATE4 : CNOT_0,3
assign type_info[4] = 3'd2;  assign pos_info[4] = 32'd0;  assign pos2_info[4] = 32'd3;  assign pos3_info[4] = 32'd0;  assign phase_shift_info[4] = 5'd0; 
//GATE5 : P_3
assign type_info[5] = 3'd1;  assign pos_info[5] = 32'd3;  assign pos2_info[5] = 32'd0;  assign pos3_info[5] = 32'd0;  assign phase_shift_info[5] = 5'd0;  
//GATE6 : P_0
assign type_info[6] = 3'd1;  assign pos_info[6] = 32'd0;  assign pos2_info[6] = 32'd0;  assign pos3_info[6] = 32'd0;  assign phase_shift_info[6] = 5'd0;   
//GATE7 : CPS_2,0(2)
assign type_info[7] = 3'd4;  assign pos_info[7] = 32'd2;  assign pos2_info[7] = 32'd0;  assign pos3_info[7] = 32'd0;  assign phase_shift_info[7] = 5'd2;  
//GATE8 : H_1
assign type_info[8] = 3'd0;  assign pos_info[8] = 32'd1;  assign pos2_info[8] = 32'd0;  assign pos3_info[8] = 32'd0;  assign phase_shift_info[8] = 5'd0; 
//GATE9 : CPS_0,3(3)
assign type_info[9] = 3'd4;  assign pos_info[9] = 32'd0;  assign pos2_info[9] = 32'd3;  assign pos3_info[9] = 32'd0;  assign phase_shift_info[9] = 5'd3;  
//GATE10: P_1
assign type_info[10] = 3'd1; assign pos_info[10] = 32'd1; assign pos2_info[10] = 32'd0; assign pos3_info[10] = 32'd0; assign phase_shift_info[10] = 5'd0; 
//GATE11: TOF_1,2,3
assign type_info[11] = 3'd5; assign pos_info[11] = 32'd1; assign pos2_info[11] = 32'd2; assign pos3_info[11] = 32'd3; assign phase_shift_info[11] = 5'd0;  
//GATE12: TOF_3,1,0
assign type_info[12] = 3'd5; assign pos_info[12] = 32'd3; assign pos2_info[12] = 32'd1; assign pos3_info[12] = 32'd0; assign phase_shift_info[12] = 5'd0;  
//GATE13: CPS_3,1(3)
assign type_info[13] = 3'd4; assign pos_info[13] = 32'd3; assign pos2_info[13] = 32'd1; assign pos3_info[13] = 32'd0; assign phase_shift_info[13] = 5'd3;  
//GATE14: CPS_3,1(3)
assign type_info[14] = 3'd4; assign pos_info[14] = 32'd3; assign pos2_info[14] = 32'd1; assign pos3_info[14] = 32'd0; assign phase_shift_info[14] = 5'd3;
//GATE15: CNOT_0,2
assign type_info[15] = 3'd2; assign pos_info[15] = 32'd0; assign pos2_info[15] = 32'd2; assign pos3_info[15] = 32'd0; assign phase_shift_info[15] = 5'd0;  
//GATE16: H_0
assign type_info[16] = 3'd0; assign pos_info[16] = 32'd0; assign pos2_info[16] = 32'd0; assign pos3_info[16] = 32'd0; assign phase_shift_info[16] = 5'd0;  
//GATE17: P_1
assign type_info[17] = 3'd1; assign pos_info[17] = 32'd1; assign pos2_info[17] = 32'd0; assign pos3_info[17] = 32'd0; assign phase_shift_info[17] = 5'd0;  
//GATE18: TOF_3,0,2
assign type_info[18] = 3'd5; assign pos_info[18] = 32'd3; assign pos2_info[18] = 32'd0; assign pos3_info[18] = 32'd2; assign phase_shift_info[18] = 5'd0;  
//GATE19: TOF_2,3,0
assign type_info[19] = 3'd5; assign pos_info[19] = 32'd2; assign pos2_info[19] = 32'd3; assign pos3_info[19] = 32'd0; assign phase_shift_info[19] = 5'd0; 
//GATE20: CNOT_0,1
assign type_info[20] = 3'd2; assign pos_info[20] = 32'd0; assign pos2_info[20] = 32'd1; assign pos3_info[20] = 32'd0; assign phase_shift_info[20] = 5'd0;  
//GATE21: P_2
assign type_info[21] = 3'd1; assign pos_info[21] = 32'd2; assign pos2_info[21] = 32'd0; assign pos3_info[21] = 32'd0; assign phase_shift_info[21] = 5'd0;  
//GATE22: CPS_3,1(3)
assign type_info[22] = 3'd4; assign pos_info[22] = 32'd3; assign pos2_info[22] = 32'd1; assign pos3_info[22] = 32'd0; assign phase_shift_info[22] = 5'd3;  
//GATE23: P_3
assign type_info[23] = 3'd1; assign pos_info[23] = 32'd3; assign pos2_info[23] = 32'd0; assign pos3_info[23] = 32'd0; assign phase_shift_info[23] = 5'd0;  
//GATE24: CPS_0,1(3)
assign type_info[24] = 3'd4; assign pos_info[24] = 32'd0; assign pos2_info[24] = 32'd1; assign pos3_info[24] = 32'd0; assign phase_shift_info[24] = 5'd3; 
//GATE25: CNOT_0,2
assign type_info[25] = 3'd2; assign pos_info[25] = 32'd0; assign pos2_info[25] = 32'd2; assign pos3_info[25] = 32'd0; assign phase_shift_info[25] = 5'd0;  
//GATE26: CNOT_0,3
assign type_info[26] = 3'd2; assign pos_info[26] = 32'd0; assign pos2_info[26] = 32'd3; assign pos3_info[26] = 32'd0; assign phase_shift_info[26] = 5'd0;  
//GATE27: CPS_2,0(2)
assign type_info[27] = 3'd4; assign pos_info[27] = 32'd2; assign pos2_info[27] = 32'd0; assign pos3_info[27] = 32'd0; assign phase_shift_info[27] = 5'd2;  
//GATE28: TOF_3,2,0
assign type_info[28] = 3'd5; assign pos_info[28] = 32'd3; assign pos2_info[28] = 32'd2; assign pos3_info[28] = 32'd0; assign phase_shift_info[28] = 5'd0;  
//GATE29: P_0
assign type_info[29] = 3'd1; assign pos_info[29] = 32'd0; assign pos2_info[29] = 32'd0; assign pos3_info[29] = 32'd0; assign phase_shift_info[29] = 5'd0; 
*/

/*
//Randomized stabilizer & nonstabilizer gates: 4-qubit_3
//GATE0 : CNOT_3,0
assign type_info[0] = 3'd2;  assign pos_info[0] = 32'd3;  assign pos2_info[0] = 32'd0;  assign pos3_info[0] = 32'd0;  assign phase_shift_info[0] = 5'd0;  
//GATE1 : P_3
assign type_info[1] = 3'd1;  assign pos_info[1] = 32'd3;  assign pos2_info[1] = 32'd0;  assign pos3_info[1] = 32'd0;  assign phase_shift_info[1] = 5'd0;   
//GATE2 : P_2
assign type_info[2] = 3'd1;  assign pos_info[2] = 32'd2;  assign pos2_info[2] = 32'd0;  assign pos3_info[2] = 32'd0;  assign phase_shift_info[2] = 5'd0;  
//GATE3 : TOF_3,0,1
assign type_info[3] = 3'd5;  assign pos_info[3] = 32'd3;  assign pos2_info[3] = 32'd0;  assign pos3_info[3] = 32'd1;  assign phase_shift_info[3] = 5'd0;   
//GATE4 : P_2
assign type_info[4] = 3'd1;  assign pos_info[4] = 32'd2;  assign pos2_info[4] = 32'd0;  assign pos3_info[4] = 32'd0;  assign phase_shift_info[4] = 5'd0; 
//GATE5 : CNOT_3,2
assign type_info[5] = 3'd2;  assign pos_info[5] = 32'd3;  assign pos2_info[5] = 32'd2;  assign pos3_info[5] = 32'd0;  assign phase_shift_info[5] = 5'd0;  
//GATE6 : H_0
assign type_info[6] = 3'd0;  assign pos_info[6] = 32'd0;  assign pos2_info[6] = 32'd0;  assign pos3_info[6] = 32'd0;  assign phase_shift_info[6] = 5'd0;   
//GATE7 : H_1
assign type_info[7] = 3'd0;  assign pos_info[7] = 32'd1;  assign pos2_info[7] = 32'd0;  assign pos3_info[7] = 32'd0;  assign phase_shift_info[7] = 5'd0;  
//GATE8 : P_1
assign type_info[8] = 3'd1;  assign pos_info[8] = 32'd1;  assign pos2_info[8] = 32'd0;  assign pos3_info[8] = 32'd0;  assign phase_shift_info[8] = 5'd0; 
//GATE9 : TOF_0,1,3
assign type_info[9] = 3'd5;  assign pos_info[9] = 32'd0;  assign pos2_info[9] = 32'd1;  assign pos3_info[9] = 32'd3;  assign phase_shift_info[9] = 5'd0;  
//GATE10: CPS_3,0(3)
assign type_info[10] = 3'd4; assign pos_info[10] = 32'd3; assign pos2_info[10] = 32'd0; assign pos3_info[10] = 32'd0; assign phase_shift_info[10] = 5'd3; 
//GATE11: TOF_3,1,0
assign type_info[11] = 3'd5; assign pos_info[11] = 32'd3; assign pos2_info[11] = 32'd1; assign pos3_info[11] = 32'd0; assign phase_shift_info[11] = 5'd0;  
//GATE12: P_1
assign type_info[12] = 3'd1; assign pos_info[12] = 32'd1; assign pos2_info[12] = 32'd0; assign pos3_info[12] = 32'd0; assign phase_shift_info[12] = 5'd0;  
//GATE13: P_1
assign type_info[13] = 3'd1; assign pos_info[13] = 32'd1; assign pos2_info[13] = 32'd0; assign pos3_info[13] = 32'd0; assign phase_shift_info[13] = 5'd0;  
//GATE14: CPS_1,0(3)
assign type_info[14] = 3'd4; assign pos_info[14] = 32'd1; assign pos2_info[14] = 32'd0; assign pos3_info[14] = 32'd0; assign phase_shift_info[14] = 5'd3;
//GATE15: TOF_3,1,2
assign type_info[15] = 3'd5; assign pos_info[15] = 32'd3; assign pos2_info[15] = 32'd1; assign pos3_info[15] = 32'd2; assign phase_shift_info[15] = 5'd0;  
//GATE16: H_1
assign type_info[16] = 3'd0; assign pos_info[16] = 32'd1; assign pos2_info[16] = 32'd0; assign pos3_info[16] = 32'd0; assign phase_shift_info[16] = 5'd0;  
//GATE17: TOF_1,2,3
assign type_info[17] = 3'd5; assign pos_info[17] = 32'd1; assign pos2_info[17] = 32'd2; assign pos3_info[17] = 32'd3; assign phase_shift_info[17] = 5'd0;  
//GATE18: CPS_1,3(2)
assign type_info[18] = 3'd4; assign pos_info[18] = 32'd1; assign pos2_info[18] = 32'd3; assign pos3_info[18] = 32'd0; assign phase_shift_info[18] = 5'd2;  
//GATE19: CPS_3,2(3)
assign type_info[19] = 3'd4; assign pos_info[19] = 32'd3; assign pos2_info[19] = 32'd2; assign pos3_info[19] = 32'd0; assign phase_shift_info[19] = 5'd3; 
//GATE20: CNOT_3,1
assign type_info[20] = 3'd2; assign pos_info[20] = 32'd3; assign pos2_info[20] = 32'd1; assign pos3_info[20] = 32'd0; assign phase_shift_info[20] = 5'd0;  
//GATE21: CNOT_0,1
assign type_info[21] = 3'd2; assign pos_info[21] = 32'd0; assign pos2_info[21] = 32'd1; assign pos3_info[21] = 32'd0; assign phase_shift_info[21] = 5'd0;  
//GATE22: TOF_2,3,1
assign type_info[22] = 3'd5; assign pos_info[22] = 32'd2; assign pos2_info[22] = 32'd3; assign pos3_info[22] = 32'd1; assign phase_shift_info[22] = 5'd0;  
//GATE23: H_0
assign type_info[23] = 3'd0; assign pos_info[23] = 32'd0; assign pos2_info[23] = 32'd0; assign pos3_info[23] = 32'd0; assign phase_shift_info[23] = 5'd0;  
//GATE24: TOF_1,2,0
assign type_info[24] = 3'd5; assign pos_info[24] = 32'd1; assign pos2_info[24] = 32'd2; assign pos3_info[24] = 32'd0; assign phase_shift_info[24] = 5'd0; 
//GATE25: CNOT_0,1
assign type_info[25] = 3'd2; assign pos_info[25] = 32'd0; assign pos2_info[25] = 32'd1; assign pos3_info[25] = 32'd0; assign phase_shift_info[25] = 5'd0;  
//GATE26: P_3
assign type_info[26] = 3'd1; assign pos_info[26] = 32'd3; assign pos2_info[26] = 32'd0; assign pos3_info[26] = 32'd0; assign phase_shift_info[26] = 5'd0;  
//GATE27: TOF_1,3,2
assign type_info[27] = 3'd5; assign pos_info[27] = 32'd1; assign pos2_info[27] = 32'd3; assign pos3_info[27] = 32'd2; assign phase_shift_info[27] = 5'd0;  
//GATE28: TOF_1,3,0
assign type_info[28] = 3'd5; assign pos_info[28] = 32'd1; assign pos2_info[28] = 32'd3; assign pos3_info[28] = 32'd0; assign phase_shift_info[28] = 5'd0;  
//GATE29: TOF_3,2,0
assign type_info[29] = 3'd5; assign pos_info[29] = 32'd3; assign pos2_info[29] = 32'd2; assign pos3_info[29] = 32'd0; assign phase_shift_info[29] = 5'd0; 
*/

/*****************************************************************FSM****************************************************************/
localparam [1:0] S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;
reg [1:0] state; reg [31:0] counter_gate; reg [31:0] counter;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		gate_type <= type_info[0]; qubit_pos <= pos_info[0]; qubit_pos2 <= pos2_info[0]; qubit_pos3 <= pos3_info[0]; phase_shift_index <= phase_shift_info[0];
		counter_gate <= 32'd1; counter <= 32'd0; state <= S0;
	end
	else
	begin
		case(state)
			S0: //Update gate info one-by-one
			begin
				if(update_gate_info & counter_gate < total_gate)
				begin
					gate_type <= type_info[counter_gate]; qubit_pos <= pos_info[counter_gate]; qubit_pos2 <= pos2_info[counter_gate]; qubit_pos3 <= pos3_info[counter_gate];
					phase_shift_index <= phase_shift_info[counter_gate];
					counter_gate <= counter_gate + 32'd1; counter <= 32'd0;
				end
				else
				begin
					gate_type <= gate_type; qubit_pos <= qubit_pos; qubit_pos2 <= qubit_pos2; qubit_pos3 <= qubit_pos3; phase_shift_index <= phase_shift_index;
					counter_gate <= counter_gate; counter <= 32'd0;
				end
				if(counter_gate == total_gate)
				begin
					state <= S1;
				end
				else
				begin
					state <= S0;
				end
			end
			S1: //Wait for valid out after final gate operation is completed
			begin
				gate_type <= gate_type; qubit_pos <= qubit_pos; qubit_pos2 <= qubit_pos2; qubit_pos3 <= qubit_pos3; phase_shift_index <= phase_shift_index;
				counter_gate <= counter_gate; counter <= counter;
				if(valid_out)
				begin
					counter <= counter+1;
				end
				if(counter == num_qubit)
				begin
					state <= S2; counter <= 0;
				end
				else
				begin
					state <= S1;
				end
			end
			S2: //Make sure final global phase update is completed
			begin
				gate_type <= gate_type; qubit_pos <= qubit_pos; qubit_pos2 <= qubit_pos2; qubit_pos3 <= qubit_pos3; phase_shift_index <= phase_shift_index;
				counter_gate <= counter_gate; counter <= 0;
				if(ram_amplitude_busy==1'd0)
				begin
					state <= S3;
				end
				else
				begin
					state <= S2;
				end
			end
			S3: //Read global phase from RAM
			begin
				gate_type <= gate_type; qubit_pos <= qubit_pos; qubit_pos2 <= qubit_pos2; qubit_pos3 <= qubit_pos3; phase_shift_index <= phase_shift_index;
				counter_gate <= counter_gate; counter <= counter+1;
				if(counter == counter_valid_vector-1)
				begin
					state <= S0; counter <= 0;
				end
				else
				begin
					state <= S3;
				end
			end
			default:
			begin
				gate_type <= type_info[0]; qubit_pos <= pos_info[0]; qubit_pos2 <= pos2_info[0]; qubit_pos3 <= pos3_info[0]; phase_shift_index <= phase_shift_info[0];
				counter_gate <= 32'd1; counter <= 0;
			end
		endcase
	end
end

reg [31:0] counter_final; reg [31:0] counter_overall_gate; wire valid_amplitude_verification_pre;
assign valid_amplitude_verification_pre = (state==S3);

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		counter_final <= 0; counter_overall_gate <= 0; valid_amplitude_verification <= 1'd0;
	end
	else
	begin
		valid_amplitude_verification <= valid_amplitude_verification_pre;
		counter_overall_gate <= counter_overall_gate;
		if(valid_out_stabilizer || valid_out_nonstabilizer)
		begin
			counter_final <= counter_final + 1;
		end
		else
		begin
			counter_final <= counter_final;
		end
		if(counter_final==num_qubit)
		begin
			counter_final <= 0;
			counter_overall_gate <= counter_overall_gate + 1;
		end
	end
end

assign final_gate = (counter_overall_gate == total_gate-1);
assign read_amplitude_verification_address = valid_amplitude_verification ? counter[num_qubit-1:0]: {num_qubit{1'd0}};

endmodule 
