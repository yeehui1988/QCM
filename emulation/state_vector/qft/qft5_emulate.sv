module qft5_emulate #(parameter sample_size = 32, complexnum_bit = 24, fp_bit = 22, mul_h = 25'h2D413C)(
input clk, input rst,
input signed [(complexnum_bit-1):0] in_r[0:(sample_size-1)],
input signed [(complexnum_bit-1):0] in_i[0:(sample_size-1)],
output signed [(complexnum_bit-1):0] out_r[0:(sample_size-1)],
output signed [(complexnum_bit-1):0] out_i[0:(sample_size-1)]);

logic signed [(complexnum_bit-1):0] reg_r_in [0:(sample_size-1)];
logic signed [(complexnum_bit-1):0] reg_r_out [0:(sample_size-1)];
logic signed [(complexnum_bit-1):0] reg_i_in [0:(sample_size-1)];
logic signed [(complexnum_bit-1):0] reg_i_out [0:(sample_size-1)];
logic LD [0:(sample_size-1)];

/****************************************Storage registers****************************************/
int j, k;
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		for (k = 0; k < sample_size; k = k + 1) 
		begin
			reg_r_out[k] <= 'd0;	reg_i_out[k] <= 'd0;
		end
	end
	else
	begin
		for (k = 0; k < sample_size; k = k + 1) 
		begin
			if (LD[k])	//Control signals from CU
			begin
				reg_r_out[k] <= reg_r_in[k];	reg_i_out[k] <= reg_i_in[k];
			end
		end
	end
end

/***********************************************ALU***********************************************/
//first half ADD_MULTIPLY; second half SUBTRACT_MULTIPLY
logic signed [(complexnum_bit-1):0] alu_r_in1 [0:(sample_size-1)];	logic signed [(complexnum_bit-1):0] alu_r_in2 [0:(sample_size-1)];
logic signed [(complexnum_bit-1):0] alu_r_out [0:(sample_size-1)];
logic signed [(complexnum_bit-1):0] alu_i_in1 [0:(sample_size-1)];	logic signed [(complexnum_bit-1):0] alu_i_in2 [0:(sample_size-1)];
logic signed [(complexnum_bit-1):0] alu_i_out [0:(sample_size-1)];

genvar i;
generate
for (i=0; i<(sample_size/2); i=i+1)
begin: alu1
	//Real: Add & Multiply
	alu_add alu_add_r (.in1(alu_r_in1[i]), .in2(alu_r_in2[i]), .in3(mul_h), .out(alu_r_out[i]));
	defparam alu_add_r.sample_size = sample_size;	defparam alu_add_r.complexnum_bit = complexnum_bit; defparam alu_add_r.fp_bit = fp_bit;
	//Real: Subtract & Multiply
	alu_sub alu_sub_r (.in1(alu_r_in1[i+(sample_size/2)]), .in2(alu_r_in2[i+(sample_size/2)]), .in3(mul_h), .out(alu_r_out[i+(sample_size/2)]));
	defparam alu_sub_r.sample_size = sample_size;	defparam alu_sub_r.complexnum_bit = complexnum_bit; defparam alu_sub_r.fp_bit = fp_bit;
	//Imaginary: Add & Multiply
	alu_add alu_add_i (.in1(alu_i_in1[i]), .in2(alu_i_in2[i]), .in3(mul_h), .out(alu_i_out[i]));
	defparam alu_add_i.sample_size = sample_size;	defparam alu_add_i.complexnum_bit = complexnum_bit; defparam alu_add_i.fp_bit = fp_bit;
	//Imaginary: Subtract & Multiply
	alu_sub alu_sub_i (.in1(alu_i_in1[i+(sample_size/2)]), .in2(alu_i_in2[i+(sample_size/2)]), .in3(mul_h), .out(alu_i_out[i+(sample_size/2)]));
	defparam alu_sub_i.sample_size = sample_size;	defparam alu_sub_i.complexnum_bit = complexnum_bit; defparam alu_sub_i.fp_bit = fp_bit;
end: alu1
endgenerate

//ALU for complex number multiplication: Rotation gates R3, R4, etc
//QFT2 doesn't require complex mul alu since R2 gate only performs mul with i
logic signed [(complexnum_bit-1):0] alu_in_real [0:7];
logic signed [(complexnum_bit-1):0] alu_in_imag [0:7];
logic signed [(complexnum_bit-1):0] alu_const_real [0:7];
logic signed [(complexnum_bit-1):0] alu_const_imag [0:7];
logic signed [(complexnum_bit-1):0] alu_out_real [0:7];
logic signed [(complexnum_bit-1):0] alu_out_imag [0:7];

genvar l;
generate
for (l=0; l<8; l=l+1)
begin: alu2
	alu_mul_complex alu_complex (.in_real(alu_in_real[l]), .in_imag(alu_in_imag[l]), .const_real(alu_const_real[l]), .const_imag(alu_const_imag[l]), .out_real(alu_out_real[l]), .out_imag(alu_out_imag[l]));
	defparam alu_complex.sample_size = sample_size;	defparam alu_complex.complexnum_bit = complexnum_bit; defparam alu_complex.fp_bit = fp_bit;
end: alu2
endgenerate

/*******************************************Multiplexing*******************************************/
//Select inputs for ALUs

//ALU0
assign alu_r_in1[0] = reg_r_out[0];	assign alu_i_in1[0] = reg_i_out[0];
logic [2:0] sel_alu0_2;
always_comb
begin
case (sel_alu0_2)
	0:		begin	alu_r_in2[0] <= reg_r_out[16]; alu_i_in2[0] <= reg_i_out[16];	end
	1:		begin	alu_r_in2[0] <= reg_r_out[8]; alu_i_in2[0] <= reg_i_out[8];	end
	2:		begin	alu_r_in2[0] <= reg_r_out[4]; alu_i_in2[0] <= reg_i_out[4];	end
	3:		begin	alu_r_in2[0] <= reg_r_out[2]; alu_i_in2[0] <= reg_i_out[2];	end
	4:		begin	alu_r_in2[0] <= reg_r_out[1]; alu_i_in2[0] <= reg_i_out[1];	end
	default:	begin	alu_r_in2[0] <= 'd0; alu_i_in2[0] <= 'd0;	end
endcase
end

//ALU1
logic sel_alu1_1;
always_comb
begin
case (sel_alu1_1)
	0:		begin	alu_r_in1[1] <= reg_r_out[1]; alu_i_in1[1] <= reg_i_out[1];	end
	1:		begin	alu_r_in1[1] <= reg_r_out[2]; alu_i_in1[1] <= reg_i_out[2];	end
	default:	begin	alu_r_in1[1] <= 'd0; alu_i_in1[1] <= 'd0;	end
endcase
end
logic [1:0] sel_alu1_2;
always_comb
begin
case (sel_alu1_2)
	0:		begin	alu_r_in2[1] <= reg_r_out[17]; alu_i_in2[1] <= reg_i_out[17];	end
	1:		begin	alu_r_in2[1] <= reg_r_out[9]; alu_i_in2[1] <= reg_i_out[9];	end
	2:		begin	alu_r_in2[1] <= reg_r_out[5]; alu_i_in2[1] <= reg_i_out[5];	end
	3:		begin	alu_r_in2[1] <= reg_r_out[3]; alu_i_in2[1] <= reg_i_out[3];	end
	default:	begin	alu_r_in2[1] <= 'd0; alu_i_in2[1] <= 'd0;	end
endcase
end

//ALU2
logic sel_alu2_1;
always_comb
begin
case (sel_alu2_1)
	0:		begin	alu_r_in1[2] <= reg_r_out[2]; alu_i_in1[2] <= reg_i_out[2];	end
	1:		begin	alu_r_in1[2] <= reg_r_out[4]; alu_i_in1[2] <= reg_i_out[4];	end
	default:	begin	alu_r_in1[2] <= 'd0; alu_i_in1[2] <= 'd0;	end
endcase
end
logic [1:0] sel_alu2_2;
always_comb
begin
case (sel_alu2_2)
	0:		begin	alu_r_in2[2] <= reg_r_out[18]; alu_i_in2[2] <= reg_i_out[18];	end
	1:		begin	alu_r_in2[2] <= reg_r_out[10]; alu_i_in2[2] <= reg_i_out[10];	end
	2:		begin	alu_r_in2[2] <= reg_r_out[6]; alu_i_in2[2] <= reg_i_out[6];	end
	3:		begin	alu_r_in2[2] <= reg_r_out[5]; alu_i_in2[2] <= reg_i_out[5];	end
	default:	begin	alu_r_in2[2] <= 'd0; alu_i_in2[2] <= 'd0;	end
endcase
end

//ALU3
logic [1:0] sel_alu3_1;
always_comb
begin
case (sel_alu3_1)
	0:		begin	alu_r_in1[3] <= reg_r_out[3]; alu_i_in1[3] <= reg_i_out[3];	end
	1:		begin	alu_r_in1[3] <= reg_r_out[5]; alu_i_in1[3] <= reg_i_out[5];	end
	2:		begin	alu_r_in1[3] <= reg_r_out[6]; alu_i_in1[3] <= reg_i_out[6];	end
	default:	begin	alu_r_in1[3] <= 'd0; alu_i_in1[3] <= 'd0;	end
endcase
end
logic [1:0] sel_alu3_2;
always_comb
begin
case (sel_alu3_2)
	0:		begin	alu_r_in2[3] <= reg_r_out[19]; alu_i_in2[3] <= reg_i_out[19];	end
	1:		begin	alu_r_in2[3] <= reg_r_out[11]; alu_i_in2[3] <= reg_i_out[11];	end
	2:		begin	alu_r_in2[3] <= reg_r_out[7]; alu_i_in2[3] <= reg_i_out[7];	end
	default:	begin	alu_r_in2[3] <= 'd0; alu_i_in2[3] <= 'd0;	end
endcase
end

//ALU4
logic sel_alu4_1;
always_comb
begin
case (sel_alu4_1)
	0:		begin	alu_r_in1[4] <= reg_r_out[4]; alu_i_in1[4] <= reg_i_out[4];	end
	1:		begin	alu_r_in1[4] <= reg_r_out[8]; alu_i_in1[4] <= reg_i_out[8];	end
	default:	begin	alu_r_in1[4] <= 'd0; alu_i_in1[4] <= 'd0;	end
endcase
end
logic [1:0] sel_alu4_2;
always_comb
begin
case (sel_alu4_2)
	0:		begin	alu_r_in2[4] <= reg_r_out[20]; alu_i_in2[4] <= reg_i_out[20];	end
	1:		begin	alu_r_in2[4] <= reg_r_out[12]; alu_i_in2[4] <= reg_i_out[12];	end
	2:		begin	alu_r_in2[4] <= reg_r_out[10]; alu_i_in2[4] <= reg_i_out[10];	end
	3:		begin	alu_r_in2[4] <= reg_r_out[9]; alu_i_in2[4] <= reg_i_out[9];	end
	default:	begin	alu_r_in2[4] <= 'd0; alu_i_in2[4] <= 'd0;	end
endcase
end

//ALU5
logic [1:0] sel_alu5_1;
always_comb
begin
case (sel_alu5_1)
	0:		begin	alu_r_in1[5] <= reg_r_out[5]; alu_i_in1[5] <= reg_i_out[5];	end
	1:		begin	alu_r_in1[5] <= reg_r_out[9]; alu_i_in1[5] <= reg_i_out[9];	end
	2:		begin	alu_r_in1[5] <= reg_r_out[10]; alu_i_in1[5] <= reg_i_out[10];	end
	default:	begin	alu_r_in1[5] <= 'd0; alu_i_in1[5] <= 'd0;	end
endcase
end
logic [1:0] sel_alu5_2;
always_comb
begin
case (sel_alu5_2)
	0:		begin	alu_r_in2[5] <= reg_r_out[21]; alu_i_in2[5] <= reg_i_out[21];	end
	1:		begin	alu_r_in2[5] <= reg_r_out[13]; alu_i_in2[5] <= reg_i_out[13];	end
	2:		begin	alu_r_in2[5] <= reg_r_out[11]; alu_i_in2[5] <= reg_i_out[11];	end
	default:	begin	alu_r_in2[5] <= 'd0; alu_i_in2[5] <= 'd0;	end
endcase
end

//ALU6
logic [1:0] sel_alu6_1;
always_comb
begin
case (sel_alu6_1)
	0:		begin	alu_r_in1[6] <= reg_r_out[6]; alu_i_in1[6] <= reg_i_out[6];	end
	1:		begin	alu_r_in1[6] <= reg_r_out[10]; alu_i_in1[6] <= reg_i_out[10];	end
	2:		begin	alu_r_in1[6] <= reg_r_out[12]; alu_i_in1[6] <= reg_i_out[12];	end
	default:	begin	alu_r_in1[6] <= 'd0; alu_i_in1[6] <= 'd0;	end
endcase
end
logic [1:0] sel_alu6_2;
always_comb
begin
case (sel_alu6_2)
	0:		begin	alu_r_in2[6] <= reg_r_out[22]; alu_i_in2[6] <= reg_i_out[22];	end
	1:		begin	alu_r_in2[6] <= reg_r_out[14]; alu_i_in2[6] <= reg_i_out[14];	end
	2:		begin	alu_r_in2[6] <= reg_r_out[13]; alu_i_in2[6] <= reg_i_out[13];	end
	default:	begin	alu_r_in2[6] <= 'd0; alu_i_in2[6] <= 'd0;	end
endcase
end

//ALU7
logic [1:0] sel_alu7_1;
always_comb
begin
case (sel_alu7_1)
	0:		begin	alu_r_in1[7] <= reg_r_out[7]; alu_i_in1[7] <= reg_i_out[7];	end
	1:		begin	alu_r_in1[7] <= reg_r_out[11]; alu_i_in1[7] <= reg_i_out[11];	end
	2:		begin	alu_r_in1[7] <= reg_r_out[13]; alu_i_in1[7] <= reg_i_out[13];	end
	3:		begin	alu_r_in1[7] <= reg_r_out[14]; alu_i_in1[7] <= reg_i_out[14];	end
	default:	begin	alu_r_in1[7] <= 'd0; alu_i_in1[7] <= 'd0;	end
endcase
end
logic sel_alu7_2;
always_comb
begin
case (sel_alu7_2)
	0:		begin	alu_r_in2[7] <= reg_r_out[23]; alu_i_in2[7] <= reg_i_out[23];	end
	1:		begin	alu_r_in2[7] <= reg_r_out[15]; alu_i_in2[7] <= reg_i_out[15];	end
	default:	begin	alu_r_in2[7] <= 'd0; alu_i_in2[7] <= 'd0;	end
endcase
end

//ALU8
logic sel_alu8_1;
always_comb
begin
case (sel_alu8_1)
	0:		begin	alu_r_in1[8] <= reg_r_out[8]; alu_i_in1[8] <= reg_i_out[8];	end
	1:		begin	alu_r_in1[8] <= reg_r_out[16]; alu_i_in1[8] <= reg_i_out[16];	end
	default:	begin	alu_r_in1[8] <= 'd0; alu_i_in1[8] <= 'd0;	end
endcase
end
logic [1:0] sel_alu8_2;
always_comb
begin
case (sel_alu8_2)
	0:		begin	alu_r_in2[8] <= reg_r_out[24]; alu_i_in2[8] <= reg_i_out[24];	end
	1:		begin	alu_r_in2[8] <= reg_r_out[20]; alu_i_in2[8] <= reg_i_out[20];	end
	2:		begin	alu_r_in2[8] <= reg_r_out[18]; alu_i_in2[8] <= reg_i_out[18];	end
	3:		begin	alu_r_in2[8] <= reg_r_out[17]; alu_i_in2[8] <= reg_i_out[17];	end
	default:	begin	alu_r_in2[8] <= 'd0; alu_i_in2[8] <= 'd0;	end
endcase
end

//ALU9
logic [1:0] sel_alu9_1;
always_comb
begin
case (sel_alu9_1)
	0:		begin	alu_r_in1[9] <= reg_r_out[9]; alu_i_in1[9] <= reg_i_out[9];	end
	1:		begin	alu_r_in1[9] <= reg_r_out[17]; alu_i_in1[9] <= reg_i_out[17];	end
	2:		begin	alu_r_in1[9] <= reg_r_out[18]; alu_i_in1[9] <= reg_i_out[18];	end
	default:	begin	alu_r_in1[9] <= 'd0; alu_i_in1[9] <= 'd0;	end
endcase
end
logic [1:0] sel_alu9_2;
always_comb
begin
case (sel_alu9_2)
	0:		begin	alu_r_in2[9] <= reg_r_out[25]; alu_i_in2[9] <= reg_i_out[25];	end
	1:		begin	alu_r_in2[9] <= reg_r_out[21]; alu_i_in2[9] <= reg_i_out[21];	end
	2:		begin	alu_r_in2[9] <= reg_r_out[19]; alu_i_in2[9] <= reg_i_out[19];	end
	default:	begin	alu_r_in2[9] <= 'd0; alu_i_in2[9] <= 'd0;	end
endcase
end

//ALU10
logic [1:0] sel_alu10_1;
always_comb
begin
case (sel_alu10_1)
	0:		begin	alu_r_in1[10] <= reg_r_out[10]; alu_i_in1[10] <= reg_i_out[10];	end
	1:		begin	alu_r_in1[10] <= reg_r_out[18]; alu_i_in1[10] <= reg_i_out[18];	end
	2:		begin	alu_r_in1[10] <= reg_r_out[20]; alu_i_in1[10] <= reg_i_out[20];	end
	default:	begin	alu_r_in1[10] <= 'd0; alu_i_in1[10] <= 'd0;	end
endcase
end
logic [1:0] sel_alu10_2;
always_comb
begin
case (sel_alu10_2)
	0:		begin	alu_r_in2[10] <= reg_r_out[26]; alu_i_in2[10] <= reg_i_out[26];	end
	1:		begin	alu_r_in2[10] <= reg_r_out[22]; alu_i_in2[10] <= reg_i_out[22];	end
	2:		begin	alu_r_in2[10] <= reg_r_out[21]; alu_i_in2[10] <= reg_i_out[21];	end
	default:	begin	alu_r_in2[10] <= 'd0; alu_i_in2[10] <= 'd0;	end
endcase
end

//ALU11
logic [1:0] sel_alu11_1;
always_comb
begin
case (sel_alu11_1)
	0:		begin	alu_r_in1[11] <= reg_r_out[11]; alu_i_in1[11] <= reg_i_out[11];	end
	1:		begin	alu_r_in1[11] <= reg_r_out[19]; alu_i_in1[11] <= reg_i_out[19];	end
	2:		begin	alu_r_in1[11] <= reg_r_out[21]; alu_i_in1[11] <= reg_i_out[21];	end
	3:		begin	alu_r_in1[11] <= reg_r_out[22]; alu_i_in1[11] <= reg_i_out[22];	end
	default:	begin	alu_r_in1[11] <= 'd0; alu_i_in1[11] <= 'd0;	end
endcase
end
logic sel_alu11_2;
always_comb
begin
case (sel_alu11_2)
	0:		begin	alu_r_in2[11] <= reg_r_out[27]; alu_i_in2[11] <= reg_i_out[27];	end
	1:		begin	alu_r_in2[11] <= reg_r_out[23]; alu_i_in2[11] <= reg_i_out[23];	end
	default:	begin	alu_r_in2[11] <= 'd0; alu_i_in2[11] <= 'd0;	end
endcase
end

//ALU12
logic [1:0] sel_alu12_1;
always_comb
begin
case (sel_alu12_1)
	0:		begin	alu_r_in1[12] <= reg_r_out[12]; alu_i_in1[12] <= reg_i_out[12];	end
	1:		begin	alu_r_in1[12] <= reg_r_out[20]; alu_i_in1[12] <= reg_i_out[20];	end
	2:		begin	alu_r_in1[12] <= reg_r_out[24]; alu_i_in1[12] <= reg_i_out[24];	end
	default:	begin	alu_r_in1[12] <= 'd0; alu_i_in1[12] <= 'd0;	end
endcase
end
logic [1:0] sel_alu12_2;
always_comb
begin
case (sel_alu12_2)
	0:		begin	alu_r_in2[12] <= reg_r_out[28]; alu_i_in2[12] <= reg_i_out[28];	end
	1:		begin	alu_r_in2[12] <= reg_r_out[26]; alu_i_in2[12] <= reg_i_out[26];	end
	2:		begin	alu_r_in2[12] <= reg_r_out[25]; alu_i_in2[12] <= reg_i_out[25];	end
	default:	begin	alu_r_in2[12] <= 'd0; alu_i_in2[12] <= 'd0;	end
endcase
end

//ALU13
logic [1:0] sel_alu13_1;
always_comb
begin
case (sel_alu13_1)
	0:		begin	alu_r_in1[13] <= reg_r_out[13]; alu_i_in1[13] <= reg_i_out[13];	end
	1:		begin	alu_r_in1[13] <= reg_r_out[21]; alu_i_in1[13] <= reg_i_out[21];	end
	2:		begin	alu_r_in1[13] <= reg_r_out[25]; alu_i_in1[13] <= reg_i_out[25];	end
	3:		begin	alu_r_in1[13] <= reg_r_out[26]; alu_i_in1[13] <= reg_i_out[26];	end
	default:	begin	alu_r_in1[13] <= 'd0; alu_i_in1[13] <= 'd0;	end
endcase
end
logic sel_alu13_2;
always_comb
begin
case (sel_alu13_2)
	0:		begin	alu_r_in2[13] <= reg_r_out[29]; alu_i_in2[13] <= reg_i_out[29];	end
	1:		begin	alu_r_in2[13] <= reg_r_out[27]; alu_i_in2[13] <= reg_i_out[27];	end
	default:	begin	alu_r_in2[13] <= 'd0; alu_i_in2[13] <= 'd0;	end
endcase
end

//ALU14
logic [1:0] sel_alu14_1;
always_comb
begin
case (sel_alu14_1)
	0:		begin	alu_r_in1[14] <= reg_r_out[14]; alu_i_in1[14] <= reg_i_out[14];	end
	1:		begin	alu_r_in1[14] <= reg_r_out[22]; alu_i_in1[14] <= reg_i_out[22];	end
	2:		begin	alu_r_in1[14] <= reg_r_out[26]; alu_i_in1[14] <= reg_i_out[26];	end
	3:		begin	alu_r_in1[14] <= reg_r_out[28]; alu_i_in1[14] <= reg_i_out[28];	end
	default:	begin	alu_r_in1[14] <= 'd0; alu_i_in1[14] <= 'd0;	end
endcase
end
logic sel_alu14_2;
always_comb
begin
case (sel_alu14_2)
	0:		begin	alu_r_in2[14] <= reg_r_out[30]; alu_i_in2[14] <= reg_i_out[30];	end
	1:		begin	alu_r_in2[14] <= reg_r_out[29]; alu_i_in2[14] <= reg_i_out[29];	end
	default:	begin	alu_r_in2[14] <= 'd0; alu_i_in2[14] <= 'd0;	end
endcase
end

//ALU15
logic [2:0] sel_alu15_1;
always_comb
begin
case (sel_alu15_1)
	0:		begin	alu_r_in1[15] <= reg_r_out[15]; alu_i_in1[15] <= reg_i_out[15];	end
	1:		begin	alu_r_in1[15] <= reg_r_out[23]; alu_i_in1[15] <= reg_i_out[23];	end
	2:		begin	alu_r_in1[15] <= reg_r_out[27]; alu_i_in1[15] <= reg_i_out[27];	end
	3:		begin	alu_r_in1[15] <= reg_r_out[29]; alu_i_in1[15] <= reg_i_out[29];	end
	4:		begin	alu_r_in1[15] <= reg_r_out[30]; alu_i_in1[15] <= reg_i_out[30];	end
	default:	begin	alu_r_in1[15] <= 'd0; alu_i_in1[15] <= 'd0;	end
endcase
end
assign alu_r_in2[15] = reg_r_out[31];	assign alu_i_in2[15] = reg_i_out[31];

//ALU16
assign alu_r_in1[16] = alu_r_in1[0];	assign alu_i_in1[16] = alu_i_in1[0];
assign alu_r_in2[16] = alu_r_in2[0];	assign alu_i_in2[16] = alu_i_in2[0];

//ALU17
assign alu_r_in1[17] = alu_r_in1[1];	assign alu_i_in1[17] = alu_i_in1[1];
assign alu_r_in2[17] = alu_r_in2[1];	assign alu_i_in2[17] = alu_i_in2[1];

//ALU18
assign alu_r_in1[18] = alu_r_in1[2];	assign alu_i_in1[18] = alu_i_in1[2];
assign alu_r_in2[18] = alu_r_in2[2];	assign alu_i_in2[18] = alu_i_in2[2];

//ALU19
assign alu_r_in1[19] = alu_r_in1[3];	assign alu_i_in1[19] = alu_i_in1[3];
assign alu_r_in2[19] = alu_r_in2[3];	assign alu_i_in2[19] = alu_i_in2[3];

//ALU20
assign alu_r_in1[20] = alu_r_in1[4];	assign alu_i_in1[20] = alu_i_in1[4];
assign alu_r_in2[20] = alu_r_in2[4];	assign alu_i_in2[20] = alu_i_in2[4];

//ALU21
assign alu_r_in1[21] = alu_r_in1[5];	assign alu_i_in1[21] = alu_i_in1[5];
assign alu_r_in2[21] = alu_r_in2[5];	assign alu_i_in2[21] = alu_i_in2[5];

//ALU22
assign alu_r_in1[22] = alu_r_in1[6];	assign alu_i_in1[22] = alu_i_in1[6];
assign alu_r_in2[22] = alu_r_in2[6];	assign alu_i_in2[22] = alu_i_in2[6];

//ALU23
assign alu_r_in1[23] = alu_r_in1[7];	assign alu_i_in1[23] = alu_i_in1[7];
assign alu_r_in2[23] = alu_r_in2[7];	assign alu_i_in2[23] = alu_i_in2[7];

//ALU24
assign alu_r_in1[24] = alu_r_in1[8];	assign alu_i_in1[24] = alu_i_in1[8];
assign alu_r_in2[24] = alu_r_in2[8];	assign alu_i_in2[24] = alu_i_in2[8];

//ALU25
assign alu_r_in1[25] = alu_r_in1[9];	assign alu_i_in1[25] = alu_i_in1[9];
assign alu_r_in2[25] = alu_r_in2[9];	assign alu_i_in2[25] = alu_i_in2[9];

//ALU26
assign alu_r_in1[26] = alu_r_in1[10];	assign alu_i_in1[26] = alu_i_in1[10];
assign alu_r_in2[26] = alu_r_in2[10];	assign alu_i_in2[26] = alu_i_in2[10];

//ALU27
assign alu_r_in1[27] = alu_r_in1[11];	assign alu_i_in1[27] = alu_i_in1[11];
assign alu_r_in2[27] = alu_r_in2[11];	assign alu_i_in2[27] = alu_i_in2[11];

//ALU28
assign alu_r_in1[28] = alu_r_in1[12];	assign alu_i_in1[28] = alu_i_in1[12];
assign alu_r_in2[28] = alu_r_in2[12];	assign alu_i_in2[28] = alu_i_in2[12];

//ALU29
assign alu_r_in1[29] = alu_r_in1[13];	assign alu_i_in1[29] = alu_i_in1[13];
assign alu_r_in2[29] = alu_r_in2[13];	assign alu_i_in2[29] = alu_i_in2[13];

//ALU30
assign alu_r_in1[30] = alu_r_in1[14];	assign alu_i_in1[30] = alu_i_in1[14];
assign alu_r_in2[30] = alu_r_in2[14];	assign alu_i_in2[30] = alu_i_in2[14];

//ALU31
assign alu_r_in1[31] = alu_r_in1[15];	assign alu_i_in1[31] = alu_i_in1[15];
assign alu_r_in2[31] = alu_r_in2[15];	assign alu_i_in2[31] = alu_i_in2[15];

//ALU_COMP0
logic [2:0] sel_alu_comp0;
always_comb
begin
case (sel_alu_comp0)
	0:		begin	alu_in_real[0] <= reg_r_out[20]; alu_in_imag[0] <= reg_i_out[20];	end
	1:		begin	alu_in_real[0] <= reg_r_out[18]; alu_in_imag[0] <= reg_i_out[18];	end
	2:		begin	alu_in_real[0] <= reg_r_out[17]; alu_in_imag[0] <= reg_i_out[17];	end
	3:		begin	alu_in_real[0] <= reg_r_out[10]; alu_in_imag[0] <= reg_i_out[10];	end
	4:		begin	alu_in_real[0] <= reg_r_out[9]; alu_in_imag[0] <= reg_i_out[9];	end
	5:		begin	alu_in_real[0] <= reg_r_out[5]; alu_in_imag[0] <= reg_i_out[5];	end
	default:	begin	alu_in_real[0] <= 'd0; alu_in_imag[0] <= 'd0;	end
endcase
end

//ALU_COMP1
logic [1:0] sel_alu_comp1;
always_comb
begin
case (sel_alu_comp1)
	0:		begin	alu_in_real[1] <= reg_r_out[21]; alu_in_imag[1] <= reg_i_out[21];	end
	1:		begin	alu_in_real[1] <= reg_r_out[19]; alu_in_imag[1] <= reg_i_out[19];	end
	2:		begin	alu_in_real[1] <= reg_r_out[11]; alu_in_imag[1] <= reg_i_out[11];	end
	3:		begin	alu_in_real[1] <= reg_r_out[7]; alu_in_imag[1] <= reg_i_out[7];	end
	default:	begin	alu_in_real[1] <= 'd0; alu_in_imag[1] <= 'd0;	end
endcase
end

//ALU_COMP2
logic [1:0] sel_alu_comp2;
always_comb
begin
case (sel_alu_comp2)
	0:		begin	alu_in_real[2] <= reg_r_out[22]; alu_in_imag[2] <= reg_i_out[22];	end
	1:		begin	alu_in_real[2] <= reg_r_out[21]; alu_in_imag[2] <= reg_i_out[21];	end
	2:		begin	alu_in_real[2] <= reg_r_out[14]; alu_in_imag[2] <= reg_i_out[14];	end
	3:		begin	alu_in_real[2] <= reg_r_out[13]; alu_in_imag[2] <= reg_i_out[13];	end
	default:	begin	alu_in_real[2] <= 'd0; alu_in_imag[2] <= 'd0;	end
endcase
end

//ALU_COMP3
logic sel_alu_comp3;
always_comb
begin
case (sel_alu_comp3)
	0:		begin	alu_in_real[3] <= reg_r_out[23]; alu_in_imag[3] <= reg_i_out[23];	end
	1:		begin	alu_in_real[3] <= reg_r_out[15]; alu_in_imag[3] <= reg_i_out[15];	end
	default:	begin	alu_in_real[3] <= 'd0; alu_in_imag[3] <= 'd0;	end
endcase
end

//ALU_COMP4
logic [1:0] sel_alu_comp4;
always_comb
begin
case (sel_alu_comp4)
	0:		begin	alu_in_real[4] <= reg_r_out[28]; alu_in_imag[4] <= reg_i_out[28];	end
	1:		begin	alu_in_real[4] <= reg_r_out[26]; alu_in_imag[4] <= reg_i_out[26];	end
	2:		begin	alu_in_real[4] <= reg_r_out[25]; alu_in_imag[4] <= reg_i_out[25];	end
	3:		begin	alu_in_real[4] <= reg_r_out[21]; alu_in_imag[4] <= reg_i_out[21];	end
	default:	begin	alu_in_real[4] <= 'd0; alu_in_imag[4] <= 'd0;	end
endcase
end

//ALU_COMP5
logic [1:0] sel_alu_comp5;
always_comb
begin
case (sel_alu_comp5)
	0:		begin	alu_in_real[5] <= reg_r_out[29]; alu_in_imag[5] <= reg_i_out[29];	end
	1:		begin	alu_in_real[5] <= reg_r_out[27]; alu_in_imag[5] <= reg_i_out[27];	end
	2:		begin	alu_in_real[5] <= reg_r_out[23]; alu_in_imag[5] <= reg_i_out[23];	end
	default:	begin	alu_in_real[5] <= 'd0; alu_in_imag[5] <= 'd0;	end
endcase
end

//ALU_COMP6
logic sel_alu_comp6;
always_comb
begin
case (sel_alu_comp6)
	0:		begin	alu_in_real[6] <= reg_r_out[30]; alu_in_imag[6] <= reg_i_out[30];	end
	1:		begin	alu_in_real[6] <= reg_r_out[29]; alu_in_imag[6] <= reg_i_out[29];	end
	default:	begin	alu_in_real[6] <= 'd0; alu_in_imag[6] <= 'd0;	end
endcase
end

//ALU_COMP7
assign alu_in_real[7] = reg_r_out[31];	assign alu_in_imag[7] = reg_i_out[31];

//ALU_COMP_CONST
logic [1:0] sel_alu_const;
always_comb
begin
case (sel_alu_const)
	0:		begin	alu_const_real[0] <= 24'h2d413c; alu_const_imag[0] <= 24'h2d413c;	end
	1:		begin	alu_const_real[0] <= 24'h3b20d7; alu_const_imag[0] <= 24'h187de2;	end
	2:		begin	alu_const_real[0] <= 24'h3ec52f; alu_const_imag[0] <= 24'hc7c5c;	end
	default:	begin	alu_const_real[0] <= 'd0; alu_const_imag[0] <= 'd0;	end
endcase
end
assign alu_const_real[1] = alu_const_real[0];	assign alu_const_imag[1] = alu_const_imag[0];
assign alu_const_real[2] = alu_const_real[0];	assign alu_const_imag[2] = alu_const_imag[0];
assign alu_const_real[3] = alu_const_real[0];	assign alu_const_imag[3] = alu_const_imag[0];
assign alu_const_real[4] = alu_const_real[0];	assign alu_const_imag[4] = alu_const_imag[0];
assign alu_const_real[5] = alu_const_real[0];	assign alu_const_imag[5] = alu_const_imag[0];
assign alu_const_real[6] = alu_const_real[0];	assign alu_const_imag[6] = alu_const_imag[0];
assign alu_const_real[7] = alu_const_real[0];	assign alu_const_imag[7] = alu_const_imag[0];

//Select inputs for REGs

//REG0
logic sel_reg0;
always_comb
begin
case (sel_reg0)
	0:		begin	reg_r_in[0] <= in_r[0]; 	reg_i_in[0] <= in_i[0];	end
	1:		begin	reg_r_in[0] <= alu_r_out[0]; 	reg_i_in[0] <= alu_i_out[0];	end
	default:	begin	reg_r_in[0] <= 'd0; reg_i_in[0] <= 'd0;	end
endcase
end

//REG1
logic [1:0] sel_reg1;
always_comb
begin
case (sel_reg1)
	0:		begin	reg_r_in[1] <= in_r[1]; 	reg_i_in[1] <= in_i[1];	end
	1:		begin	reg_r_in[1] <= alu_r_out[1]; 	reg_i_in[1] <= alu_i_out[1];	end
	2:		begin	reg_r_in[1] <= alu_r_out[16]; 	reg_i_in[1] <= alu_i_out[16];	end
	3:		begin	reg_r_in[1] <= reg_r_out[16]; 	reg_i_in[1] <= reg_i_out[16];	end
	default:	begin	reg_r_in[1] <= 'd0; reg_i_in[1] <= 'd0;	end
endcase
end

//REG2
logic [2:0] sel_reg2;
always_comb
begin
case (sel_reg2)
	0:		begin	reg_r_in[2] <= in_r[2]; 	reg_i_in[2] <= in_i[2];	end
	1:		begin	reg_r_in[2] <= alu_r_out[2]; 	reg_i_in[2] <= alu_i_out[2];	end
	2:		begin	reg_r_in[2] <= alu_r_out[16]; 	reg_i_in[2] <= alu_i_out[16];	end
	3:		begin	reg_r_in[2] <= alu_r_out[1]; 	reg_i_in[2] <= alu_i_out[1];	end
	4:		begin	reg_r_in[2] <= reg_r_out[8]; 	reg_i_in[2] <= reg_i_out[8];	end
	default:	begin	reg_r_in[2] <= 'd0; reg_i_in[2] <= 'd0;	end
endcase
end

//REG3
logic [2:0] sel_reg3;
always_comb
begin
case (sel_reg3)
	0:		begin	reg_r_in[3] <= in_r[3]; 	reg_i_in[3] <= in_i[3];	end
	1:		begin	reg_r_in[3] <= alu_r_out[3]; 	reg_i_in[3] <= alu_i_out[3];	end
	2:		begin	reg_r_in[3] <= alu_r_out[17]; 	reg_i_in[3] <= alu_i_out[17];	end
	3:		begin	reg_r_in[3] <= -reg_i_out[3]; 	reg_i_in[3] <= reg_r_out[3];	end
	4:		begin	reg_r_in[3] <= reg_r_out[24]; 	reg_i_in[3] <= reg_i_out[24];	end
	default:	begin	reg_r_in[3] <= 'd0; reg_i_in[3] <= 'd0;	end
endcase
end

//REG4
logic [1:0] sel_reg4;
always_comb
begin
case (sel_reg4)
	0:		begin	reg_r_in[4] <= in_r[4]; 	reg_i_in[4] <= in_i[4];	end
	1:		begin	reg_r_in[4] <= alu_r_out[4]; 	reg_i_in[4] <= alu_i_out[4];	end
	2:		begin	reg_r_in[4] <= alu_r_out[16]; 	reg_i_in[4] <= alu_i_out[16];	end
	3:		begin	reg_r_in[4] <= alu_r_out[2]; 	reg_i_in[4] <= alu_i_out[2];	end
	default:	begin	reg_r_in[4] <= 'd0; reg_i_in[4] <= 'd0;	end
endcase
end

//REG5
logic [2:0] sel_reg5;
always_comb
begin
case (sel_reg5)
	0:		begin	reg_r_in[5] <= in_r[5]; 	reg_i_in[5] <= in_i[5];	end
	1:		begin	reg_r_in[5] <= alu_r_out[5]; 	reg_i_in[5] <= alu_i_out[5];	end
	2:		begin	reg_r_in[5] <= alu_r_out[17]; 	reg_i_in[5] <= alu_i_out[17];	end
	3:		begin	reg_r_in[5] <= alu_out_real[0]; 	reg_i_in[5] <= alu_out_imag[0];	end
	4:		begin	reg_r_in[5] <= alu_r_out[3]; 	reg_i_in[5] <= alu_i_out[3];	end
	5:		begin	reg_r_in[5] <= alu_r_out[18]; 	reg_i_in[5] <= alu_i_out[18];	end
	6:		begin	reg_r_in[5] <= reg_r_out[20]; 	reg_i_in[5] <= reg_i_out[20];	end
	default:	begin	reg_r_in[5] <= 'd0; reg_i_in[5] <= 'd0;	end
endcase
end

//REG6
logic [2:0] sel_reg6;
always_comb
begin
case (sel_reg6)
	0:		begin	reg_r_in[6] <= in_r[6]; 	reg_i_in[6] <= in_i[6];	end
	1:		begin	reg_r_in[6] <= alu_r_out[6]; 	reg_i_in[6] <= alu_i_out[6];	end
	2:		begin	reg_r_in[6] <= alu_r_out[18]; 	reg_i_in[6] <= alu_i_out[18];	end
	3:		begin	reg_r_in[6] <= -reg_i_out[6]; 	reg_i_in[6] <= reg_r_out[6];	end
	4:		begin	reg_r_in[6] <= alu_r_out[3]; 	reg_i_in[6] <= alu_i_out[3];	end
	5:		begin	reg_r_in[6] <= reg_r_out[12]; 	reg_i_in[6] <= reg_i_out[12];	end
	default:	begin	reg_r_in[6] <= 'd0; reg_i_in[6] <= 'd0;	end
endcase
end

//REG7
logic [2:0] sel_reg7;
always_comb
begin
case (sel_reg7)
	0:		begin	reg_r_in[7] <= in_r[7]; 	reg_i_in[7] <= in_i[7];	end
	1:		begin	reg_r_in[7] <= alu_r_out[7]; 	reg_i_in[7] <= alu_i_out[7];	end
	2:		begin	reg_r_in[7] <= alu_r_out[19]; 	reg_i_in[7] <= alu_i_out[19];	end
	3:		begin	reg_r_in[7] <= -reg_i_out[7]; 	reg_i_in[7] <= reg_r_out[7];	end
	4:		begin	reg_r_in[7] <= alu_out_real[1]; 	reg_i_in[7] <= alu_out_imag[1];	end
	5:		begin	reg_r_in[7] <= reg_r_out[28]; 	reg_i_in[7] <= reg_i_out[28];	end
	default:	begin	reg_r_in[7] <= 'd0; reg_i_in[7] <= 'd0;	end
endcase
end

//REG8
logic [2:0] sel_reg8;
always_comb
begin
case (sel_reg8)
	0:		begin	reg_r_in[8] <= in_r[8]; 	reg_i_in[8] <= in_i[8];	end
	1:		begin	reg_r_in[8] <= alu_r_out[8]; 	reg_i_in[8] <= alu_i_out[8];	end
	2:		begin	reg_r_in[8] <= alu_r_out[16]; 	reg_i_in[8] <= alu_i_out[16];	end
	3:		begin	reg_r_in[8] <= alu_r_out[4]; 	reg_i_in[8] <= alu_i_out[4];	end
	4:		begin	reg_r_in[8] <= reg_r_out[2]; 	reg_i_in[8] <= reg_i_out[2];	end
	default:	begin	reg_r_in[8] <= 'd0; reg_i_in[8] <= 'd0;	end
endcase
end

//REG9
logic [2:0] sel_reg9;
always_comb
begin
case (sel_reg9)
	0:		begin	reg_r_in[9] <= in_r[9]; 	reg_i_in[9] <= in_i[9];	end
	1:		begin	reg_r_in[9] <= alu_r_out[9]; 	reg_i_in[9] <= alu_i_out[9];	end
	2:		begin	reg_r_in[9] <= alu_r_out[17]; 	reg_i_in[9] <= alu_i_out[17];	end
	3:		begin	reg_r_in[9] <= alu_out_real[0]; 	reg_i_in[9] <= alu_out_imag[0];	end
	4:		begin	reg_r_in[9] <= alu_r_out[5]; 	reg_i_in[9] <= alu_i_out[5];	end
	5:		begin	reg_r_in[9] <= alu_r_out[20]; 	reg_i_in[9] <= alu_i_out[20];	end
	6:		begin	reg_r_in[9] <= reg_r_out[18]; 	reg_i_in[9] <= reg_i_out[18];	end
	default:	begin	reg_r_in[9] <= 'd0; reg_i_in[9] <= 'd0;	end
endcase
end

//REG10
logic [2:0] sel_reg10;
always_comb
begin
case (sel_reg10)
	0:		begin	reg_r_in[10] <= in_r[10]; 	reg_i_in[10] <= in_i[10];	end
	1:		begin	reg_r_in[10] <= alu_r_out[10]; 	reg_i_in[10] <= alu_i_out[10];	end
	2:		begin	reg_r_in[10] <= alu_r_out[18]; 	reg_i_in[10] <= alu_i_out[18];	end
	3:		begin	reg_r_in[10] <= alu_out_real[0]; 	reg_i_in[10] <= alu_out_imag[0];	end
	4:		begin	reg_r_in[10] <= alu_r_out[6]; 	reg_i_in[10] <= alu_i_out[6];	end
	5:		begin	reg_r_in[10] <= alu_r_out[20]; 	reg_i_in[10] <= alu_i_out[20];	end
	6:		begin	reg_r_in[10] <= alu_r_out[5]; 	reg_i_in[10] <= alu_i_out[5];	end
	default:	begin	reg_r_in[10] <= 'd0; reg_i_in[10] <= 'd0;	end
endcase
end

//REG11
logic [2:0] sel_reg11;
always_comb
begin
case (sel_reg11)
	0:		begin	reg_r_in[11] <= in_r[11]; 	reg_i_in[11] <= in_i[11];	end
	1:		begin	reg_r_in[11] <= alu_r_out[11]; 	reg_i_in[11] <= alu_i_out[11];	end
	2:		begin	reg_r_in[11] <= alu_r_out[19]; 	reg_i_in[11] <= alu_i_out[19];	end
	3:		begin	reg_r_in[11] <= alu_out_real[1]; 	reg_i_in[11] <= alu_out_imag[1];	end
	4:		begin	reg_r_in[11] <= alu_r_out[7]; 	reg_i_in[11] <= alu_i_out[7];	end
	5:		begin	reg_r_in[11] <= alu_r_out[21]; 	reg_i_in[11] <= alu_i_out[21];	end
	6:		begin	reg_r_in[11] <= -reg_i_out[11]; 	reg_i_in[11] <= reg_r_out[11];	end
	7:		begin	reg_r_in[11] <= reg_r_out[26]; 	reg_i_in[11] <= reg_i_out[26];	end
	default:	begin	reg_r_in[11] <= 'd0; reg_i_in[11] <= 'd0;	end
endcase
end

//REG12
logic [2:0] sel_reg12;
always_comb
begin
case (sel_reg12)
	0:		begin	reg_r_in[12] <= in_r[12]; 	reg_i_in[12] <= in_i[12];	end
	1:		begin	reg_r_in[12] <= alu_r_out[12]; 	reg_i_in[12] <= alu_i_out[12];	end
	2:		begin	reg_r_in[12] <= alu_r_out[20]; 	reg_i_in[12] <= alu_i_out[20];	end
	3:		begin	reg_r_in[12] <= -reg_i_out[12]; 	reg_i_in[12] <= reg_r_out[12];	end
	4:		begin	reg_r_in[12] <= alu_r_out[6]; 	reg_i_in[12] <= alu_i_out[6];	end
	5:		begin	reg_r_in[12] <= reg_r_out[6]; 	reg_i_in[12] <= reg_i_out[6];	end
	default:	begin	reg_r_in[12] <= 'd0; reg_i_in[12] <= 'd0;	end
endcase
end

//REG13
logic [2:0] sel_reg13;
always_comb
begin
case (sel_reg13)
	0:		begin	reg_r_in[13] <= in_r[13]; 	reg_i_in[13] <= in_i[13];	end
	1:		begin	reg_r_in[13] <= alu_r_out[13]; 	reg_i_in[13] <= alu_i_out[13];	end
	2:		begin	reg_r_in[13] <= alu_r_out[21]; 	reg_i_in[13] <= alu_i_out[21];	end
	3:		begin	reg_r_in[13] <= -reg_i_out[13]; 	reg_i_in[13] <= reg_r_out[13];	end
	4:		begin	reg_r_in[13] <= alu_out_real[2]; 	reg_i_in[13] <= alu_out_imag[2];	end
	5:		begin	reg_r_in[13] <= alu_r_out[7]; 	reg_i_in[13] <= alu_i_out[7];	end
	6:		begin	reg_r_in[13] <= alu_r_out[22]; 	reg_i_in[13] <= alu_i_out[22];	end
	7:		begin	reg_r_in[13] <= reg_r_out[22]; 	reg_i_in[13] <= reg_i_out[22];	end
	default:	begin	reg_r_in[13] <= 'd0; reg_i_in[13] <= 'd0;	end
endcase
end

//REG14
logic [2:0] sel_reg14;
always_comb
begin
case (sel_reg14)
	0:		begin	reg_r_in[14] <= in_r[14]; 	reg_i_in[14] <= in_i[14];	end
	1:		begin	reg_r_in[14] <= alu_r_out[14]; 	reg_i_in[14] <= alu_i_out[14];	end
	2:		begin	reg_r_in[14] <= alu_r_out[22]; 	reg_i_in[14] <= alu_i_out[22];	end
	3:		begin	reg_r_in[14] <= -reg_i_out[14]; 	reg_i_in[14] <= reg_r_out[14];	end
	4:		begin	reg_r_in[14] <= alu_out_real[2]; 	reg_i_in[14] <= alu_out_imag[2];	end
	5:		begin	reg_r_in[14] <= alu_r_out[7]; 	reg_i_in[14] <= alu_i_out[7];	end
	default:	begin	reg_r_in[14] <= 'd0; reg_i_in[14] <= 'd0;	end
endcase
end

//REG15
logic [2:0] sel_reg15;
always_comb
begin
case (sel_reg15)
	0:		begin	reg_r_in[15] <= in_r[15]; 	reg_i_in[15] <= in_i[15];	end
	1:		begin	reg_r_in[15] <= alu_r_out[15]; 	reg_i_in[15] <= alu_i_out[15];	end
	2:		begin	reg_r_in[15] <= alu_r_out[23]; 	reg_i_in[15] <= alu_i_out[23];	end
	3:		begin	reg_r_in[15] <= -reg_i_out[15]; 	reg_i_in[15] <= reg_r_out[15];	end
	4:		begin	reg_r_in[15] <= alu_out_real[3]; 	reg_i_in[15] <= alu_out_imag[3];	end
	5:		begin	reg_r_in[15] <= reg_r_out[30]; 	reg_i_in[15] <= reg_i_out[30];	end
	default:	begin	reg_r_in[15] <= 'd0; reg_i_in[15] <= 'd0;	end
endcase
end

//REG16
logic [1:0] sel_reg16;
always_comb
begin
case (sel_reg16)
	0:		begin	reg_r_in[16] <= in_r[16]; 	reg_i_in[16] <= in_i[16];	end
	1:		begin	reg_r_in[16] <= alu_r_out[16]; 	reg_i_in[16] <= alu_i_out[16];	end
	2:		begin	reg_r_in[16] <= alu_r_out[8]; 	reg_i_in[16] <= alu_i_out[8];	end
	3:		begin	reg_r_in[16] <= reg_r_out[1]; 	reg_i_in[16] <= reg_i_out[1];	end
	default:	begin	reg_r_in[16] <= 'd0; reg_i_in[16] <= 'd0;	end
endcase
end

//REG17
logic [2:0] sel_reg17;
always_comb
begin
case (sel_reg17)
	0:		begin	reg_r_in[17] <= in_r[17]; 	reg_i_in[17] <= in_i[17];	end
	1:		begin	reg_r_in[17] <= alu_r_out[17]; 	reg_i_in[17] <= alu_i_out[17];	end
	2:		begin	reg_r_in[17] <= alu_out_real[0]; 	reg_i_in[17] <= alu_out_imag[0];	end
	3:		begin	reg_r_in[17] <= alu_r_out[9]; 	reg_i_in[17] <= alu_i_out[9];	end
	4:		begin	reg_r_in[17] <= alu_r_out[24]; 	reg_i_in[17] <= alu_i_out[24];	end
	default:	begin	reg_r_in[17] <= 'd0; reg_i_in[17] <= 'd0;	end
endcase
end

//REG18
logic [2:0] sel_reg18;
always_comb
begin
case (sel_reg18)
	0:		begin	reg_r_in[18] <= in_r[18]; 	reg_i_in[18] <= in_i[18];	end
	1:		begin	reg_r_in[18] <= alu_r_out[18]; 	reg_i_in[18] <= alu_i_out[18];	end
	2:		begin	reg_r_in[18] <= alu_out_real[0]; 	reg_i_in[18] <= alu_out_imag[0];	end
	3:		begin	reg_r_in[18] <= alu_r_out[10]; 	reg_i_in[18] <= alu_i_out[10];	end
	4:		begin	reg_r_in[18] <= alu_r_out[24]; 	reg_i_in[18] <= alu_i_out[24];	end
	5:		begin	reg_r_in[18] <= alu_r_out[9]; 	reg_i_in[18] <= alu_i_out[9];	end
	6:		begin	reg_r_in[18] <= reg_r_out[9]; 	reg_i_in[18] <= reg_i_out[9];	end
	default:	begin	reg_r_in[18] <= 'd0; reg_i_in[18] <= 'd0;	end
endcase
end

//REG19
logic [2:0] sel_reg19;
always_comb
begin
case (sel_reg19)
	0:		begin	reg_r_in[19] <= in_r[19]; 	reg_i_in[19] <= in_i[19];	end
	1:		begin	reg_r_in[19] <= alu_r_out[19]; 	reg_i_in[19] <= alu_i_out[19];	end
	2:		begin	reg_r_in[19] <= alu_out_real[1]; 	reg_i_in[19] <= alu_out_imag[1];	end
	3:		begin	reg_r_in[19] <= alu_r_out[11]; 	reg_i_in[19] <= alu_i_out[11];	end
	4:		begin	reg_r_in[19] <= alu_r_out[25]; 	reg_i_in[19] <= alu_i_out[25];	end
	5:		begin	reg_r_in[19] <= -reg_i_out[19]; 	reg_i_in[19] <= reg_r_out[19];	end
	6:		begin	reg_r_in[19] <= reg_r_out[25]; 	reg_i_in[19] <= reg_i_out[25];	end
	default:	begin	reg_r_in[19] <= 'd0; reg_i_in[19] <= 'd0;	end
endcase
end

//REG20
logic [2:0] sel_reg20;
always_comb
begin
case (sel_reg20)
	0:		begin	reg_r_in[20] <= in_r[20]; 	reg_i_in[20] <= in_i[20];	end
	1:		begin	reg_r_in[20] <= alu_r_out[20]; 	reg_i_in[20] <= alu_i_out[20];	end
	2:		begin	reg_r_in[20] <= alu_out_real[0]; 	reg_i_in[20] <= alu_out_imag[0];	end
	3:		begin	reg_r_in[20] <= alu_r_out[12]; 	reg_i_in[20] <= alu_i_out[12];	end
	4:		begin	reg_r_in[20] <= alu_r_out[24]; 	reg_i_in[20] <= alu_i_out[24];	end
	5:		begin	reg_r_in[20] <= alu_r_out[10]; 	reg_i_in[20] <= alu_i_out[10];	end
	6:		begin	reg_r_in[20] <= reg_r_out[5]; 	reg_i_in[20] <= reg_i_out[5];	end
	default:	begin	reg_r_in[20] <= 'd0; reg_i_in[20] <= 'd0;	end
endcase
end

//REG21
logic [3:0] sel_reg21;
always_comb
begin
case (sel_reg21)
	0:		begin	reg_r_in[21] <= in_r[21]; 	reg_i_in[21] <= in_i[21];	end
	1:		begin	reg_r_in[21] <= alu_r_out[21]; 	reg_i_in[21] <= alu_i_out[21];	end
	2:		begin	reg_r_in[21] <= alu_out_real[1]; 	reg_i_in[21] <= alu_out_imag[1];	end
	3:		begin	reg_r_in[21] <= alu_out_real[2]; 	reg_i_in[21] <= alu_out_imag[2];	end
	4:		begin	reg_r_in[21] <= alu_r_out[13]; 	reg_i_in[21] <= alu_i_out[13];	end
	5:		begin	reg_r_in[21] <= alu_r_out[25]; 	reg_i_in[21] <= alu_i_out[25];	end
	6:		begin	reg_r_in[21] <= alu_out_real[4]; 	reg_i_in[21] <= alu_out_imag[4];	end
	7:		begin	reg_r_in[21] <= alu_r_out[11]; 	reg_i_in[21] <= alu_i_out[11];	end
	8:		begin	reg_r_in[21] <= alu_r_out[26]; 	reg_i_in[21] <= alu_i_out[26];	end
	default:	begin	reg_r_in[21] <= 'd0; reg_i_in[21] <= 'd0;	end
endcase
end

//REG22
logic [2:0] sel_reg22;
always_comb
begin
case (sel_reg22)
	0:		begin	reg_r_in[22] <= in_r[22]; 	reg_i_in[22] <= in_i[22];	end
	1:		begin	reg_r_in[22] <= alu_r_out[22]; 	reg_i_in[22] <= alu_i_out[22];	end
	2:		begin	reg_r_in[22] <= alu_out_real[2]; 	reg_i_in[22] <= alu_out_imag[2];	end
	3:		begin	reg_r_in[22] <= alu_r_out[14]; 	reg_i_in[22] <= alu_i_out[14];	end
	4:		begin	reg_r_in[22] <= alu_r_out[26]; 	reg_i_in[22] <= alu_i_out[26];	end
	5:		begin	reg_r_in[22] <= -reg_i_out[22]; 	reg_i_in[22] <= reg_r_out[22];	end
	6:		begin	reg_r_in[22] <= alu_r_out[11]; 	reg_i_in[22] <= alu_i_out[11];	end
	7:		begin	reg_r_in[22] <= reg_r_out[13]; 	reg_i_in[22] <= reg_i_out[13];	end
	default:	begin	reg_r_in[22] <= 'd0; reg_i_in[22] <= 'd0;	end
endcase
end

//REG23
logic [2:0] sel_reg23;
always_comb
begin
case (sel_reg23)
	0:		begin	reg_r_in[23] <= in_r[23]; 	reg_i_in[23] <= in_i[23];	end
	1:		begin	reg_r_in[23] <= alu_r_out[23]; 	reg_i_in[23] <= alu_i_out[23];	end
	2:		begin	reg_r_in[23] <= alu_out_real[3]; 	reg_i_in[23] <= alu_out_imag[3];	end
	3:		begin	reg_r_in[23] <= alu_r_out[15]; 	reg_i_in[23] <= alu_i_out[15];	end
	4:		begin	reg_r_in[23] <= alu_r_out[27]; 	reg_i_in[23] <= alu_i_out[27];	end
	5:		begin	reg_r_in[23] <= -reg_i_out[23]; 	reg_i_in[23] <= reg_r_out[23];	end
	6:		begin	reg_r_in[23] <= alu_out_real[5]; 	reg_i_in[23] <= alu_out_imag[5];	end
	7:		begin	reg_r_in[23] <= reg_r_out[29]; 	reg_i_in[23] <= reg_i_out[29];	end
	default:	begin	reg_r_in[23] <= 'd0; reg_i_in[23] <= 'd0;	end
endcase
end

//REG24
logic [2:0] sel_reg24;
always_comb
begin
case (sel_reg24)
	0:		begin	reg_r_in[24] <= in_r[24]; 	reg_i_in[24] <= in_i[24];	end
	1:		begin	reg_r_in[24] <= alu_r_out[24]; 	reg_i_in[24] <= alu_i_out[24];	end
	2:		begin	reg_r_in[24] <= -reg_i_out[24]; 	reg_i_in[24] <= reg_r_out[24];	end
	3:		begin	reg_r_in[24] <= alu_r_out[12]; 	reg_i_in[24] <= alu_i_out[12];	end
	4:		begin	reg_r_in[24] <= reg_r_out[3]; 	reg_i_in[24] <= reg_i_out[3];	end
	default:	begin	reg_r_in[24] <= 'd0; reg_i_in[24] <= 'd0;	end
endcase
end

//REG25
logic [2:0] sel_reg25;
always_comb
begin
case (sel_reg25)
	0:		begin	reg_r_in[25] <= in_r[25]; 	reg_i_in[25] <= in_i[25];	end
	1:		begin	reg_r_in[25] <= alu_r_out[25]; 	reg_i_in[25] <= alu_i_out[25];	end
	2:		begin	reg_r_in[25] <= -reg_i_out[25]; 	reg_i_in[25] <= reg_r_out[25];	end
	3:		begin	reg_r_in[25] <= alu_out_real[4]; 	reg_i_in[25] <= alu_out_imag[4];	end
	4:		begin	reg_r_in[25] <= alu_r_out[13]; 	reg_i_in[25] <= alu_i_out[13];	end
	5:		begin	reg_r_in[25] <= alu_r_out[28]; 	reg_i_in[25] <= alu_i_out[28];	end
	6:		begin	reg_r_in[25] <= reg_r_out[19]; 	reg_i_in[25] <= reg_i_out[19];	end
	default:	begin	reg_r_in[25] <= 'd0; reg_i_in[25] <= 'd0;	end
endcase
end

//REG26
logic [2:0] sel_reg26;
always_comb
begin
case (sel_reg26)
	0:		begin	reg_r_in[26] <= in_r[26]; 	reg_i_in[26] <= in_i[26];	end
	1:		begin	reg_r_in[26] <= alu_r_out[26]; 	reg_i_in[26] <= alu_i_out[26];	end
	2:		begin	reg_r_in[26] <= -reg_i_out[26]; 	reg_i_in[26] <= reg_r_out[26];	end
	3:		begin	reg_r_in[26] <= alu_out_real[4]; 	reg_i_in[26] <= alu_out_imag[4];	end
	4:		begin	reg_r_in[26] <= alu_r_out[14]; 	reg_i_in[26] <= alu_i_out[14];	end
	5:		begin	reg_r_in[26] <= alu_r_out[28]; 	reg_i_in[26] <= alu_i_out[28];	end
	6:		begin	reg_r_in[26] <= alu_r_out[13]; 	reg_i_in[26] <= alu_i_out[13];	end
	7:		begin	reg_r_in[26] <= reg_r_out[11]; 	reg_i_in[26] <= reg_i_out[11];	end
	default:	begin	reg_r_in[26] <= 'd0; reg_i_in[26] <= 'd0;	end
endcase
end

//REG27
logic [2:0] sel_reg27;
always_comb
begin
case (sel_reg27)
	0:		begin	reg_r_in[27] <= in_r[27]; 	reg_i_in[27] <= in_i[27];	end
	1:		begin	reg_r_in[27] <= alu_r_out[27]; 	reg_i_in[27] <= alu_i_out[27];	end
	2:		begin	reg_r_in[27] <= -reg_i_out[27]; 	reg_i_in[27] <= reg_r_out[27];	end
	3:		begin	reg_r_in[27] <= alu_out_real[5]; 	reg_i_in[27] <= alu_out_imag[5];	end
	4:		begin	reg_r_in[27] <= alu_r_out[15]; 	reg_i_in[27] <= alu_i_out[15];	end
	5:		begin	reg_r_in[27] <= alu_r_out[29]; 	reg_i_in[27] <= alu_i_out[29];	end
	default:	begin	reg_r_in[27] <= 'd0; reg_i_in[27] <= 'd0;	end
endcase
end

//REG28
logic [2:0] sel_reg28;
always_comb
begin
case (sel_reg28)
	0:		begin	reg_r_in[28] <= in_r[28]; 	reg_i_in[28] <= in_i[28];	end
	1:		begin	reg_r_in[28] <= alu_r_out[28]; 	reg_i_in[28] <= alu_i_out[28];	end
	2:		begin	reg_r_in[28] <= -reg_i_out[28]; 	reg_i_in[28] <= reg_r_out[28];	end
	3:		begin	reg_r_in[28] <= alu_out_real[4]; 	reg_i_in[28] <= alu_out_imag[4];	end
	4:		begin	reg_r_in[28] <= alu_r_out[14]; 	reg_i_in[28] <= alu_i_out[14];	end
	5:		begin	reg_r_in[28] <= reg_r_out[7]; 	reg_i_in[28] <= reg_i_out[7];	end
	default:	begin	reg_r_in[28] <= 'd0; reg_i_in[28] <= 'd0;	end
endcase
end

//REG29
logic [2:0] sel_reg29;
always_comb
begin
case (sel_reg29)
	0:		begin	reg_r_in[29] <= in_r[29]; 	reg_i_in[29] <= in_i[29];	end
	1:		begin	reg_r_in[29] <= alu_r_out[29]; 	reg_i_in[29] <= alu_i_out[29];	end
	2:		begin	reg_r_in[29] <= -reg_i_out[29]; 	reg_i_in[29] <= reg_r_out[29];	end
	3:		begin	reg_r_in[29] <= alu_out_real[5]; 	reg_i_in[29] <= alu_out_imag[5];	end
	4:		begin	reg_r_in[29] <= alu_out_real[6]; 	reg_i_in[29] <= alu_out_imag[6];	end
	5:		begin	reg_r_in[29] <= alu_r_out[15]; 	reg_i_in[29] <= alu_i_out[15];	end
	6:		begin	reg_r_in[29] <= alu_r_out[30]; 	reg_i_in[29] <= alu_i_out[30];	end
	7:		begin	reg_r_in[29] <= reg_r_out[23]; 	reg_i_in[29] <= reg_i_out[23];	end
	default:	begin	reg_r_in[29] <= 'd0; reg_i_in[29] <= 'd0;	end
endcase
end

//REG30
logic [2:0] sel_reg30;
always_comb
begin
case (sel_reg30)
	0:		begin	reg_r_in[30] <= in_r[30]; 	reg_i_in[30] <= in_i[30];	end
	1:		begin	reg_r_in[30] <= alu_r_out[30]; 	reg_i_in[30] <= alu_i_out[30];	end
	2:		begin	reg_r_in[30] <= -reg_i_out[30]; 	reg_i_in[30] <= reg_r_out[30];	end
	3:		begin	reg_r_in[30] <= alu_out_real[6]; 	reg_i_in[30] <= alu_out_imag[6];	end
	4:		begin	reg_r_in[30] <= alu_r_out[15]; 	reg_i_in[30] <= alu_i_out[15];	end
	5:		begin	reg_r_in[30] <= reg_r_out[15]; 	reg_i_in[30] <= reg_i_out[15];	end
	default:	begin	reg_r_in[30] <= 'd0; reg_i_in[30] <= 'd0;	end
endcase
end

//REG31
logic [1:0] sel_reg31;
always_comb
begin
case (sel_reg31)
	0:		begin	reg_r_in[31] <= in_r[31]; 	reg_i_in[31] <= in_i[31];	end
	1:		begin	reg_r_in[31] <= alu_r_out[31]; 	reg_i_in[31] <= alu_i_out[31];	end
	2:		begin	reg_r_in[31] <= -reg_i_out[31]; 	reg_i_in[31] <= reg_r_out[31];	end
	3:		begin	reg_r_in[31] <= alu_out_real[7]; 	reg_i_in[31] <= alu_out_imag[7];	end
	default:	begin	reg_r_in[31] <= 'd0; reg_i_in[31] <= 'd0;	end
endcase
end

//CU FSM: Split always block
reg [4:0] state, next_state;
//For change of state
always@ (posedge clk or posedge rst)
begin
	if(rst)begin
		state <= 0;
	end
	else begin
		state <= next_state;
	end
end

always_comb
begin
	case(state)
	0: begin
		next_state<=1;
		//Registers
		sel_reg0<='d0;		LD[0]<='d1;
		sel_reg1<='d0;		LD[1]<='d1;
		sel_reg2<='d0;		LD[2]<='d1;
		sel_reg3<='d0;		LD[3]<='d1;
		sel_reg4<='d0;		LD[4]<='d1;
		sel_reg5<='d0;		LD[5]<='d1;
		sel_reg6<='d0;		LD[6]<='d1;
		sel_reg7<='d0;		LD[7]<='d1;
		sel_reg8<='d0;		LD[8]<='d1;
		sel_reg9<='d0;		LD[9]<='d1;
		sel_reg10<='d0;		LD[10]<='d1;
		sel_reg11<='d0;		LD[11]<='d1;
		sel_reg12<='d0;		LD[12]<='d1;
		sel_reg13<='d0;		LD[13]<='d1;
		sel_reg14<='d0;		LD[14]<='d1;
		sel_reg15<='d0;		LD[15]<='d1;
		sel_reg16<='d0;		LD[16]<='d1;
		sel_reg17<='d0;		LD[17]<='d1;
		sel_reg18<='d0;		LD[18]<='d1;
		sel_reg19<='d0;		LD[19]<='d1;
		sel_reg20<='d0;		LD[20]<='d1;
		sel_reg21<='d0;		LD[21]<='d1;
		sel_reg22<='d0;		LD[22]<='d1;
		sel_reg23<='d0;		LD[23]<='d1;
		sel_reg24<='d0;		LD[24]<='d1;
		sel_reg25<='d0;		LD[25]<='d1;
		sel_reg26<='d0;		LD[26]<='d1;
		sel_reg27<='d0;		LD[27]<='d1;
		sel_reg28<='d0;		LD[28]<='d1;
		sel_reg29<='d0;		LD[29]<='d1;
		sel_reg30<='d0;		LD[30]<='d1;
		sel_reg31<='d0;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	1: begin
		next_state<=2;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d1;		LD[1]<='d1;
		sel_reg2<='d1;		LD[2]<='d1;
		sel_reg3<='d1;		LD[3]<='d1;
		sel_reg4<='d1;		LD[4]<='d1;
		sel_reg5<='d1;		LD[5]<='d1;
		sel_reg6<='d1;		LD[6]<='d1;
		sel_reg7<='d1;		LD[7]<='d1;
		sel_reg8<='d1;		LD[8]<='d1;
		sel_reg9<='d1;		LD[9]<='d1;
		sel_reg10<='d1;		LD[10]<='d1;
		sel_reg11<='d1;		LD[11]<='d1;
		sel_reg12<='d1;		LD[12]<='d1;
		sel_reg13<='d1;		LD[13]<='d1;
		sel_reg14<='d1;		LD[14]<='d1;
		sel_reg15<='d1;		LD[15]<='d1;
		sel_reg16<='d1;		LD[16]<='d1;
		sel_reg17<='d1;		LD[17]<='d1;
		sel_reg18<='d1;		LD[18]<='d1;
		sel_reg19<='d1;		LD[19]<='d1;
		sel_reg20<='d1;		LD[20]<='d1;
		sel_reg21<='d1;		LD[21]<='d1;
		sel_reg22<='d1;		LD[22]<='d1;
		sel_reg23<='d1;		LD[23]<='d1;
		sel_reg24<='d1;		LD[24]<='d1;
		sel_reg25<='d1;		LD[25]<='d1;
		sel_reg26<='d1;		LD[26]<='d1;
		sel_reg27<='d1;		LD[27]<='d1;
		sel_reg28<='d1;		LD[28]<='d1;
		sel_reg29<='d1;		LD[29]<='d1;
		sel_reg30<='d1;		LD[30]<='d1;
		sel_reg31<='d1;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	2: begin
		next_state<=3;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d0;		LD[7]<='d0;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d0;		LD[11]<='d0;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d0;		LD[13]<='d0;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d0;		LD[15]<='d0;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d0;		LD[19]<='d0;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d0;		LD[21]<='d0;
		sel_reg22<='d0;		LD[22]<='d0;
		sel_reg23<='d0;		LD[23]<='d0;
		sel_reg24<='d2;		LD[24]<='d1;
		sel_reg25<='d2;		LD[25]<='d1;
		sel_reg26<='d2;		LD[26]<='d1;
		sel_reg27<='d2;		LD[27]<='d1;
		sel_reg28<='d2;		LD[28]<='d1;
		sel_reg29<='d2;		LD[29]<='d1;
		sel_reg30<='d2;		LD[30]<='d1;
		sel_reg31<='d2;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	3: begin
		next_state<=4;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d0;		LD[7]<='d0;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d0;		LD[11]<='d0;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d0;		LD[13]<='d0;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d0;		LD[15]<='d0;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d0;		LD[19]<='d0;
		sel_reg20<='d2;		LD[20]<='d1;
		sel_reg21<='d2;		LD[21]<='d1;
		sel_reg22<='d2;		LD[22]<='d1;
		sel_reg23<='d2;		LD[23]<='d1;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d0;		LD[25]<='d0;
		sel_reg26<='d0;		LD[26]<='d0;
		sel_reg27<='d0;		LD[27]<='d0;
		sel_reg28<='d3;		LD[28]<='d1;
		sel_reg29<='d3;		LD[29]<='d1;
		sel_reg30<='d3;		LD[30]<='d1;
		sel_reg31<='d3;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	4: begin
		next_state<=5;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d0;		LD[7]<='d0;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d0;		LD[11]<='d0;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d0;		LD[13]<='d0;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d0;		LD[15]<='d0;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d2;		LD[18]<='d1;
		sel_reg19<='d2;		LD[19]<='d1;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d0;		LD[21]<='d0;
		sel_reg22<='d2;		LD[22]<='d1;
		sel_reg23<='d2;		LD[23]<='d1;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d0;		LD[25]<='d0;
		sel_reg26<='d3;		LD[26]<='d1;
		sel_reg27<='d3;		LD[27]<='d1;
		sel_reg28<='d0;		LD[28]<='d0;
		sel_reg29<='d0;		LD[29]<='d0;
		sel_reg30<='d3;		LD[30]<='d1;
		sel_reg31<='d3;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d1;
		sel_alu_comp0<='d1;
		sel_alu_comp1<='d1;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d1;
		sel_alu_comp5<='d1;
		sel_alu_comp6<='d0;
	end
	5: begin
		next_state<=6;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d0;		LD[7]<='d0;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d0;		LD[11]<='d0;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d0;		LD[13]<='d0;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d0;		LD[15]<='d0;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d2;		LD[17]<='d1;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d2;		LD[19]<='d1;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d3;		LD[21]<='d1;
		sel_reg22<='d0;		LD[22]<='d0;
		sel_reg23<='d2;		LD[23]<='d1;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d3;		LD[25]<='d1;
		sel_reg26<='d0;		LD[26]<='d0;
		sel_reg27<='d3;		LD[27]<='d1;
		sel_reg28<='d0;		LD[28]<='d0;
		sel_reg29<='d4;		LD[29]<='d1;
		sel_reg30<='d0;		LD[30]<='d0;
		sel_reg31<='d3;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d2;
		sel_alu_comp0<='d2;
		sel_alu_comp1<='d1;
		sel_alu_comp2<='d1;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d2;
		sel_alu_comp5<='d1;
		sel_alu_comp6<='d1;
	end
	6: begin
		next_state<=7;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d1;		LD[1]<='d1;
		sel_reg2<='d1;		LD[2]<='d1;
		sel_reg3<='d1;		LD[3]<='d1;
		sel_reg4<='d1;		LD[4]<='d1;
		sel_reg5<='d1;		LD[5]<='d1;
		sel_reg6<='d1;		LD[6]<='d1;
		sel_reg7<='d1;		LD[7]<='d1;
		sel_reg8<='d2;		LD[8]<='d1;
		sel_reg9<='d2;		LD[9]<='d1;
		sel_reg10<='d2;		LD[10]<='d1;
		sel_reg11<='d2;		LD[11]<='d1;
		sel_reg12<='d2;		LD[12]<='d1;
		sel_reg13<='d2;		LD[13]<='d1;
		sel_reg14<='d2;		LD[14]<='d1;
		sel_reg15<='d2;		LD[15]<='d1;
		sel_reg16<='d2;		LD[16]<='d1;
		sel_reg17<='d3;		LD[17]<='d1;
		sel_reg18<='d3;		LD[18]<='d1;
		sel_reg19<='d3;		LD[19]<='d1;
		sel_reg20<='d3;		LD[20]<='d1;
		sel_reg21<='d4;		LD[21]<='d1;
		sel_reg22<='d3;		LD[22]<='d1;
		sel_reg23<='d3;		LD[23]<='d1;
		sel_reg24<='d1;		LD[24]<='d1;
		sel_reg25<='d1;		LD[25]<='d1;
		sel_reg26<='d1;		LD[26]<='d1;
		sel_reg27<='d1;		LD[27]<='d1;
		sel_reg28<='d1;		LD[28]<='d1;
		sel_reg29<='d1;		LD[29]<='d1;
		sel_reg30<='d1;		LD[30]<='d1;
		sel_reg31<='d1;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d1;
		sel_alu1_1<='d0;
		sel_alu1_2<='d1;
		sel_alu2_1<='d0;
		sel_alu2_2<='d1;
		sel_alu3_1<='d0;
		sel_alu3_2<='d1;
		sel_alu4_1<='d0;
		sel_alu4_2<='d1;
		sel_alu5_1<='d0;
		sel_alu5_2<='d1;
		sel_alu6_1<='d0;
		sel_alu6_2<='d1;
		sel_alu7_1<='d0;
		sel_alu7_2<='d1;
		sel_alu8_1<='d1;
		sel_alu8_2<='d0;
		sel_alu9_1<='d1;
		sel_alu9_2<='d0;
		sel_alu10_1<='d1;
		sel_alu10_2<='d0;
		sel_alu11_1<='d1;
		sel_alu11_2<='d0;
		sel_alu12_1<='d1;
		sel_alu12_2<='d0;
		sel_alu13_1<='d1;
		sel_alu13_2<='d0;
		sel_alu14_1<='d1;
		sel_alu14_2<='d0;
		sel_alu15_1<='d1;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	7: begin
		next_state<=8;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d0;		LD[7]<='d0;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d0;		LD[11]<='d0;
		sel_reg12<='d3;		LD[12]<='d1;
		sel_reg13<='d3;		LD[13]<='d1;
		sel_reg14<='d3;		LD[14]<='d1;
		sel_reg15<='d3;		LD[15]<='d1;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d0;		LD[19]<='d0;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d0;		LD[21]<='d0;
		sel_reg22<='d0;		LD[22]<='d0;
		sel_reg23<='d0;		LD[23]<='d0;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d0;		LD[25]<='d0;
		sel_reg26<='d0;		LD[26]<='d0;
		sel_reg27<='d0;		LD[27]<='d0;
		sel_reg28<='d2;		LD[28]<='d1;
		sel_reg29<='d2;		LD[29]<='d1;
		sel_reg30<='d2;		LD[30]<='d1;
		sel_reg31<='d2;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	8: begin
		next_state<=9;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d0;		LD[7]<='d0;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d3;		LD[10]<='d1;
		sel_reg11<='d3;		LD[11]<='d1;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d0;		LD[13]<='d0;
		sel_reg14<='d4;		LD[14]<='d1;
		sel_reg15<='d4;		LD[15]<='d1;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d0;		LD[19]<='d0;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d0;		LD[21]<='d0;
		sel_reg22<='d0;		LD[22]<='d0;
		sel_reg23<='d0;		LD[23]<='d0;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d0;		LD[25]<='d0;
		sel_reg26<='d3;		LD[26]<='d1;
		sel_reg27<='d3;		LD[27]<='d1;
		sel_reg28<='d0;		LD[28]<='d0;
		sel_reg29<='d0;		LD[29]<='d0;
		sel_reg30<='d3;		LD[30]<='d1;
		sel_reg31<='d3;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d3;
		sel_alu_comp1<='d2;
		sel_alu_comp2<='d2;
		sel_alu_comp3<='d1;
		sel_alu_comp4<='d1;
		sel_alu_comp5<='d1;
		sel_alu_comp6<='d0;
	end
	9: begin
		next_state<=10;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d0;		LD[7]<='d0;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d3;		LD[9]<='d1;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d3;		LD[11]<='d1;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d4;		LD[13]<='d1;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d4;		LD[15]<='d1;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d0;		LD[19]<='d0;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d0;		LD[21]<='d0;
		sel_reg22<='d0;		LD[22]<='d0;
		sel_reg23<='d0;		LD[23]<='d0;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d3;		LD[25]<='d1;
		sel_reg26<='d0;		LD[26]<='d0;
		sel_reg27<='d3;		LD[27]<='d1;
		sel_reg28<='d0;		LD[28]<='d0;
		sel_reg29<='d4;		LD[29]<='d1;
		sel_reg30<='d0;		LD[30]<='d0;
		sel_reg31<='d3;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d1;
		sel_alu_comp0<='d4;
		sel_alu_comp1<='d2;
		sel_alu_comp2<='d3;
		sel_alu_comp3<='d1;
		sel_alu_comp4<='d2;
		sel_alu_comp5<='d1;
		sel_alu_comp6<='d1;
	end
	10: begin
		next_state<=11;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d1;		LD[1]<='d1;
		sel_reg2<='d1;		LD[2]<='d1;
		sel_reg3<='d1;		LD[3]<='d1;
		sel_reg4<='d2;		LD[4]<='d1;
		sel_reg5<='d2;		LD[5]<='d1;
		sel_reg6<='d2;		LD[6]<='d1;
		sel_reg7<='d2;		LD[7]<='d1;
		sel_reg8<='d3;		LD[8]<='d1;
		sel_reg9<='d4;		LD[9]<='d1;
		sel_reg10<='d4;		LD[10]<='d1;
		sel_reg11<='d4;		LD[11]<='d1;
		sel_reg12<='d2;		LD[12]<='d1;
		sel_reg13<='d2;		LD[13]<='d1;
		sel_reg14<='d2;		LD[14]<='d1;
		sel_reg15<='d2;		LD[15]<='d1;
		sel_reg16<='d2;		LD[16]<='d1;
		sel_reg17<='d3;		LD[17]<='d1;
		sel_reg18<='d3;		LD[18]<='d1;
		sel_reg19<='d3;		LD[19]<='d1;
		sel_reg20<='d4;		LD[20]<='d1;
		sel_reg21<='d5;		LD[21]<='d1;
		sel_reg22<='d4;		LD[22]<='d1;
		sel_reg23<='d4;		LD[23]<='d1;
		sel_reg24<='d3;		LD[24]<='d1;
		sel_reg25<='d4;		LD[25]<='d1;
		sel_reg26<='d4;		LD[26]<='d1;
		sel_reg27<='d4;		LD[27]<='d1;
		sel_reg28<='d1;		LD[28]<='d1;
		sel_reg29<='d1;		LD[29]<='d1;
		sel_reg30<='d1;		LD[30]<='d1;
		sel_reg31<='d1;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d2;
		sel_alu1_1<='d0;
		sel_alu1_2<='d2;
		sel_alu2_1<='d0;
		sel_alu2_2<='d2;
		sel_alu3_1<='d0;
		sel_alu3_2<='d2;
		sel_alu4_1<='d1;
		sel_alu4_2<='d1;
		sel_alu5_1<='d1;
		sel_alu5_2<='d1;
		sel_alu6_1<='d1;
		sel_alu6_2<='d1;
		sel_alu7_1<='d1;
		sel_alu7_2<='d1;
		sel_alu8_1<='d1;
		sel_alu8_2<='d1;
		sel_alu9_1<='d1;
		sel_alu9_2<='d1;
		sel_alu10_1<='d1;
		sel_alu10_2<='d1;
		sel_alu11_1<='d1;
		sel_alu11_2<='d1;
		sel_alu12_1<='d2;
		sel_alu12_2<='d0;
		sel_alu13_1<='d2;
		sel_alu13_2<='d0;
		sel_alu14_1<='d2;
		sel_alu14_2<='d0;
		sel_alu15_1<='d2;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	11: begin
		next_state<=12;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d3;		LD[6]<='d1;
		sel_reg7<='d3;		LD[7]<='d1;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d0;		LD[11]<='d0;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d0;		LD[13]<='d0;
		sel_reg14<='d3;		LD[14]<='d1;
		sel_reg15<='d3;		LD[15]<='d1;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d0;		LD[19]<='d0;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d0;		LD[21]<='d0;
		sel_reg22<='d5;		LD[22]<='d1;
		sel_reg23<='d5;		LD[23]<='d1;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d0;		LD[25]<='d0;
		sel_reg26<='d0;		LD[26]<='d0;
		sel_reg27<='d0;		LD[27]<='d0;
		sel_reg28<='d0;		LD[28]<='d0;
		sel_reg29<='d0;		LD[29]<='d0;
		sel_reg30<='d2;		LD[30]<='d1;
		sel_reg31<='d2;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	12: begin
		next_state<=13;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d3;		LD[5]<='d1;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d4;		LD[7]<='d1;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d0;		LD[11]<='d0;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d4;		LD[13]<='d1;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d4;		LD[15]<='d1;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d0;		LD[19]<='d0;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d6;		LD[21]<='d1;
		sel_reg22<='d0;		LD[22]<='d0;
		sel_reg23<='d6;		LD[23]<='d1;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d0;		LD[25]<='d0;
		sel_reg26<='d0;		LD[26]<='d0;
		sel_reg27<='d0;		LD[27]<='d0;
		sel_reg28<='d0;		LD[28]<='d0;
		sel_reg29<='d4;		LD[29]<='d1;
		sel_reg30<='d0;		LD[30]<='d0;
		sel_reg31<='d3;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d5;
		sel_alu_comp1<='d3;
		sel_alu_comp2<='d3;
		sel_alu_comp3<='d1;
		sel_alu_comp4<='d3;
		sel_alu_comp5<='d2;
		sel_alu_comp6<='d1;
	end
	13: begin
		next_state<=14;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d1;		LD[1]<='d1;
		sel_reg2<='d2;		LD[2]<='d1;
		sel_reg3<='d2;		LD[3]<='d1;
		sel_reg4<='d3;		LD[4]<='d1;
		sel_reg5<='d4;		LD[5]<='d1;
		sel_reg6<='d2;		LD[6]<='d1;
		sel_reg7<='d2;		LD[7]<='d1;
		sel_reg8<='d3;		LD[8]<='d1;
		sel_reg9<='d4;		LD[9]<='d1;
		sel_reg10<='d5;		LD[10]<='d1;
		sel_reg11<='d5;		LD[11]<='d1;
		sel_reg12<='d4;		LD[12]<='d1;
		sel_reg13<='d5;		LD[13]<='d1;
		sel_reg14<='d2;		LD[14]<='d1;
		sel_reg15<='d2;		LD[15]<='d1;
		sel_reg16<='d2;		LD[16]<='d1;
		sel_reg17<='d3;		LD[17]<='d1;
		sel_reg18<='d4;		LD[18]<='d1;
		sel_reg19<='d4;		LD[19]<='d1;
		sel_reg20<='d5;		LD[20]<='d1;
		sel_reg21<='d7;		LD[21]<='d1;
		sel_reg22<='d4;		LD[22]<='d1;
		sel_reg23<='d4;		LD[23]<='d1;
		sel_reg24<='d3;		LD[24]<='d1;
		sel_reg25<='d4;		LD[25]<='d1;
		sel_reg26<='d5;		LD[26]<='d1;
		sel_reg27<='d5;		LD[27]<='d1;
		sel_reg28<='d4;		LD[28]<='d1;
		sel_reg29<='d5;		LD[29]<='d1;
		sel_reg30<='d1;		LD[30]<='d1;
		sel_reg31<='d1;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d3;
		sel_alu1_1<='d0;
		sel_alu1_2<='d3;
		sel_alu2_1<='d1;
		sel_alu2_2<='d2;
		sel_alu3_1<='d1;
		sel_alu3_2<='d2;
		sel_alu4_1<='d1;
		sel_alu4_2<='d2;
		sel_alu5_1<='d1;
		sel_alu5_2<='d2;
		sel_alu6_1<='d2;
		sel_alu6_2<='d1;
		sel_alu7_1<='d2;
		sel_alu7_2<='d1;
		sel_alu8_1<='d1;
		sel_alu8_2<='d2;
		sel_alu9_1<='d1;
		sel_alu9_2<='d2;
		sel_alu10_1<='d2;
		sel_alu10_2<='d1;
		sel_alu11_1<='d2;
		sel_alu11_2<='d1;
		sel_alu12_1<='d2;
		sel_alu12_2<='d1;
		sel_alu13_1<='d2;
		sel_alu13_2<='d1;
		sel_alu14_1<='d3;
		sel_alu14_2<='d0;
		sel_alu15_1<='d3;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	14: begin
		next_state<=15;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d3;		LD[3]<='d1;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d3;		LD[7]<='d1;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d6;		LD[11]<='d1;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d0;		LD[13]<='d0;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d3;		LD[15]<='d1;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d5;		LD[19]<='d1;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d0;		LD[21]<='d0;
		sel_reg22<='d0;		LD[22]<='d0;
		sel_reg23<='d5;		LD[23]<='d1;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d0;		LD[25]<='d0;
		sel_reg26<='d0;		LD[26]<='d0;
		sel_reg27<='d2;		LD[27]<='d1;
		sel_reg28<='d0;		LD[28]<='d0;
		sel_reg29<='d0;		LD[29]<='d0;
		sel_reg30<='d0;		LD[30]<='d0;
		sel_reg31<='d2;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	15: begin
		next_state<=16;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d2;		LD[1]<='d1;
		sel_reg2<='d3;		LD[2]<='d1;
		sel_reg3<='d2;		LD[3]<='d1;
		sel_reg4<='d3;		LD[4]<='d1;
		sel_reg5<='d5;		LD[5]<='d1;
		sel_reg6<='d4;		LD[6]<='d1;
		sel_reg7<='d2;		LD[7]<='d1;
		sel_reg8<='d3;		LD[8]<='d1;
		sel_reg9<='d5;		LD[9]<='d1;
		sel_reg10<='d6;		LD[10]<='d1;
		sel_reg11<='d5;		LD[11]<='d1;
		sel_reg12<='d4;		LD[12]<='d1;
		sel_reg13<='d6;		LD[13]<='d1;
		sel_reg14<='d5;		LD[14]<='d1;
		sel_reg15<='d2;		LD[15]<='d1;
		sel_reg16<='d2;		LD[16]<='d1;
		sel_reg17<='d4;		LD[17]<='d1;
		sel_reg18<='d5;		LD[18]<='d1;
		sel_reg19<='d4;		LD[19]<='d1;
		sel_reg20<='d5;		LD[20]<='d1;
		sel_reg21<='d8;		LD[21]<='d1;
		sel_reg22<='d6;		LD[22]<='d1;
		sel_reg23<='d4;		LD[23]<='d1;
		sel_reg24<='d3;		LD[24]<='d1;
		sel_reg25<='d5;		LD[25]<='d1;
		sel_reg26<='d6;		LD[26]<='d1;
		sel_reg27<='d5;		LD[27]<='d1;
		sel_reg28<='d4;		LD[28]<='d1;
		sel_reg29<='d6;		LD[29]<='d1;
		sel_reg30<='d4;		LD[30]<='d1;
		sel_reg31<='d1;		LD[31]<='d1;
		//ALUs
		sel_alu0_2<='d4;
		sel_alu1_1<='d1;
		sel_alu1_2<='d3;
		sel_alu2_1<='d1;
		sel_alu2_2<='d3;
		sel_alu3_1<='d2;
		sel_alu3_2<='d2;
		sel_alu4_1<='d1;
		sel_alu4_2<='d3;
		sel_alu5_1<='d2;
		sel_alu5_2<='d2;
		sel_alu6_1<='d2;
		sel_alu6_2<='d2;
		sel_alu7_1<='d3;
		sel_alu7_2<='d1;
		sel_alu8_1<='d1;
		sel_alu8_2<='d3;
		sel_alu9_1<='d2;
		sel_alu9_2<='d2;
		sel_alu10_1<='d2;
		sel_alu10_2<='d2;
		sel_alu11_1<='d3;
		sel_alu11_2<='d1;
		sel_alu12_1<='d2;
		sel_alu12_2<='d2;
		sel_alu13_1<='d3;
		sel_alu13_2<='d1;
		sel_alu14_1<='d3;
		sel_alu14_2<='d1;
		sel_alu15_1<='d4;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	16: begin
		next_state<=17;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d3;		LD[1]<='d1;
		sel_reg2<='d4;		LD[2]<='d1;
		sel_reg3<='d4;		LD[3]<='d1;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d6;		LD[5]<='d1;
		sel_reg6<='d5;		LD[6]<='d1;
		sel_reg7<='d5;		LD[7]<='d1;
		sel_reg8<='d4;		LD[8]<='d1;
		sel_reg9<='d6;		LD[9]<='d1;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d7;		LD[11]<='d1;
		sel_reg12<='d5;		LD[12]<='d1;
		sel_reg13<='d7;		LD[13]<='d1;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d5;		LD[15]<='d1;
		sel_reg16<='d3;		LD[16]<='d1;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d6;		LD[18]<='d1;
		sel_reg19<='d6;		LD[19]<='d1;
		sel_reg20<='d6;		LD[20]<='d1;
		sel_reg21<='d0;		LD[21]<='d0;
		sel_reg22<='d7;		LD[22]<='d1;
		sel_reg23<='d7;		LD[23]<='d1;
		sel_reg24<='d4;		LD[24]<='d1;
		sel_reg25<='d6;		LD[25]<='d1;
		sel_reg26<='d7;		LD[26]<='d1;
		sel_reg27<='d0;		LD[27]<='d0;
		sel_reg28<='d5;		LD[28]<='d1;
		sel_reg29<='d7;		LD[29]<='d1;
		sel_reg30<='d5;		LD[30]<='d1;
		sel_reg31<='d0;		LD[31]<='d0;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	default: begin
		next_state<=17;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		sel_reg4<='d0;		LD[4]<='d0;
		sel_reg5<='d0;		LD[5]<='d0;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d0;		LD[7]<='d0;
		sel_reg8<='d0;		LD[8]<='d0;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d0;		LD[10]<='d0;
		sel_reg11<='d0;		LD[11]<='d0;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d0;		LD[13]<='d0;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d0;		LD[15]<='d0;
		sel_reg16<='d0;		LD[16]<='d0;
		sel_reg17<='d0;		LD[17]<='d0;
		sel_reg18<='d0;		LD[18]<='d0;
		sel_reg19<='d0;		LD[19]<='d0;
		sel_reg20<='d0;		LD[20]<='d0;
		sel_reg21<='d0;		LD[21]<='d0;
		sel_reg22<='d0;		LD[22]<='d0;
		sel_reg23<='d0;		LD[23]<='d0;
		sel_reg24<='d0;		LD[24]<='d0;
		sel_reg25<='d0;		LD[25]<='d0;
		sel_reg26<='d0;		LD[26]<='d0;
		sel_reg27<='d0;		LD[27]<='d0;
		sel_reg28<='d0;		LD[28]<='d0;
		sel_reg29<='d0;		LD[29]<='d0;
		sel_reg30<='d0;		LD[30]<='d0;
		sel_reg31<='d0;		LD[31]<='d0;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		sel_alu3_2<='d0;
		sel_alu4_1<='d0;
		sel_alu4_2<='d0;
		sel_alu5_1<='d0;
		sel_alu5_2<='d0;
		sel_alu6_1<='d0;
		sel_alu6_2<='d0;
		sel_alu7_1<='d0;
		sel_alu7_2<='d0;
		sel_alu8_1<='d0;
		sel_alu8_2<='d0;
		sel_alu9_1<='d0;
		sel_alu9_2<='d0;
		sel_alu10_1<='d0;
		sel_alu10_2<='d0;
		sel_alu11_1<='d0;
		sel_alu11_2<='d0;
		sel_alu12_1<='d0;
		sel_alu12_2<='d0;
		sel_alu13_1<='d0;
		sel_alu13_2<='d0;
		sel_alu14_1<='d0;
		sel_alu14_2<='d0;
		sel_alu15_1<='d0;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
		sel_alu_comp3<='d0;
		sel_alu_comp4<='d0;
		sel_alu_comp5<='d0;
		sel_alu_comp6<='d0;
	end
	endcase
end

//Output
assign out_r = reg_r_out;	assign out_i = reg_i_out;
endmodule
