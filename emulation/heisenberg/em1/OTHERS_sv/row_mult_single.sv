//Row multiplication for stabilizer frame with single phase vector set
//For current version, the imaginary factor(s) on phase is not considered
//How to accumulate the imaginary factor of all the literal products??
module row_mult_single #(parameter num_qubit = 4)(
input [1:0] literals_in1 [0:num_qubit-1],
input phase_in1,
input [1:0] literals_in2 [0:num_qubit-1],
input phase_in2,
output reg [1:0] literals_out [0:num_qubit-1],
output reg phase_out
);

integer i;

//Accumulate the imaginary factor of the literal multiplication product
reg [1:0] imag_factor[0:num_qubit-1];
always@(*)
begin
	for (i=0; i<num_qubit; i=i+1) 
	begin
		//For XY, YZ, ZX: i
		if((literals_in1[i] == 2'd2 && literals_in2[i] == 2'd3) || (literals_in1[i] == 2'd3 && literals_in2[i] == 2'd1) || 
		(literals_in1[i] == 2'd1 && literals_in2[i] == 2'd2))
		begin
			imag_factor[i] <= 2'd1; 
		end
		//For XZ, YX, ZY: -i
		else if((literals_in1[i] == 2'd2 && literals_in2[i] == 2'd1) || (literals_in1[i] == 2'd3 && literals_in2[i] == 2'd2) 
		|| (literals_in1[i] == 2'd1 && literals_in2[i] == 2'd3))
		begin
			imag_factor[i] <= 2'd3; 
		end
		else
		begin
			imag_factor[i] <= 2'd0; 
		end
	end
end

//assign sum = imag_factor[0] + imag_factor[1] + imag_factor[2];
genvar k;
wire [31:0] sum;
wire [31:0] temp[0:num_qubit-1];

generate
for (k=0; k<num_qubit; k=k+1) 
begin:summation
	if (k == 0)
		assign temp[k] = imag_factor[k]; 				
   else if (k == num_qubit-1)
      assign sum = temp[k-1] + imag_factor[k]; 		    
   else
      assign temp[k] = temp[k-1] + imag_factor[k];	    
end:summation
endgenerate

reg toggle_phase;
always@(*)
begin
	/***********************Final factor -i is ignored, only -ve is taken into consideration************************/
	if(sum % 4 == 32'd2)
	begin
		toggle_phase <= 1'd1;
	end
	else
	begin
		toggle_phase <= 1'd0;
	end
end

//Phase update for multiplication
wire phase_out_pre;
assign phase_out_pre = phase_in1 ^ phase_in2;

always@(*)
begin
	if(toggle_phase==1'd1)
	begin
		if(phase_out_pre==1'd1)
		begin
			phase_out <= 1'd0;
		end
		else
		begin
			phase_out <= 1'd1;
		end
	end
	else
	begin
		phase_out <= phase_out_pre;
	end
end

//Literal update for multiplication
always@(*)
begin
	for (i=0; i<num_qubit; i=i+1) 
	begin
		literals_out[i] <= literals_in1[i] ^ literals_in2[i];
	end
end

endmodule
