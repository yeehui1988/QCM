module qft4_emulate #(parameter sample_size = 16, complexnum_bit = 24, fp_bit = 22, mul_h = 25'h2D413C)(
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
logic signed [(complexnum_bit-1):0] alu_in_real [0:3];
logic signed [(complexnum_bit-1):0] alu_in_imag [0:3];
logic signed [(complexnum_bit-1):0] alu_const_real [0:3];
logic signed [(complexnum_bit-1):0] alu_const_imag [0:3];
logic signed [(complexnum_bit-1):0] alu_out_real [0:3];
logic signed [(complexnum_bit-1):0] alu_out_imag [0:3];

genvar l;
generate
for (l=0; l<4; l=l+1)
begin: alu2
	alu_mul_complex alu_complex (.in_real(alu_in_real[l]), .in_imag(alu_in_imag[l]), .const_real(alu_const_real[l]), .const_imag(alu_const_imag[l]), .out_real(alu_out_real[l]), .out_imag(alu_out_imag[l]));
	defparam alu_complex.sample_size = sample_size;	defparam alu_complex.complexnum_bit = complexnum_bit; defparam alu_complex.fp_bit = fp_bit;
end: alu2
endgenerate

/*******************************************Multiplexing*******************************************/
//Select inputs for ALUs

//ALU0
assign alu_r_in1[0] = reg_r_out[0];	assign alu_i_in1[0] = reg_i_out[0];
logic [1:0] sel_alu0_2;
always_comb
begin
case (sel_alu0_2)
	0:		begin	alu_r_in2[0] <= reg_r_out[8]; alu_i_in2[0] <= reg_i_out[8];	end
	1:		begin	alu_r_in2[0] <= reg_r_out[4]; alu_i_in2[0] <= reg_i_out[4];	end
	2:		begin	alu_r_in2[0] <= reg_r_out[2]; alu_i_in2[0] <= reg_i_out[2];	end
	3:		begin	alu_r_in2[0] <= reg_r_out[1]; alu_i_in2[0] <= reg_i_out[1];	end
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
	0:		begin	alu_r_in2[1] <= reg_r_out[9]; alu_i_in2[1] <= reg_i_out[9];	end
	1:		begin	alu_r_in2[1] <= reg_r_out[5]; alu_i_in2[1] <= reg_i_out[5];	end
	2:		begin	alu_r_in2[1] <= reg_r_out[3]; alu_i_in2[1] <= reg_i_out[3];	end
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
	0:		begin	alu_r_in2[2] <= reg_r_out[10]; alu_i_in2[2] <= reg_i_out[10];	end
	1:		begin	alu_r_in2[2] <= reg_r_out[6]; alu_i_in2[2] <= reg_i_out[6];	end
	2:		begin	alu_r_in2[2] <= reg_r_out[5]; alu_i_in2[2] <= reg_i_out[5];	end
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
logic sel_alu3_2;
always_comb
begin
case (sel_alu3_2)
	0:		begin	alu_r_in2[3] <= reg_r_out[11]; alu_i_in2[3] <= reg_i_out[11];	end
	1:		begin	alu_r_in2[3] <= reg_r_out[7]; alu_i_in2[3] <= reg_i_out[7];	end
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
	0:		begin	alu_r_in2[4] <= reg_r_out[12]; alu_i_in2[4] <= reg_i_out[12];	end
	1:		begin	alu_r_in2[4] <= reg_r_out[10]; alu_i_in2[4] <= reg_i_out[10];	end
	2:		begin	alu_r_in2[4] <= reg_r_out[9]; alu_i_in2[4] <= reg_i_out[9];	end
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
logic sel_alu5_2;
always_comb
begin
case (sel_alu5_2)
	0:		begin	alu_r_in2[5] <= reg_r_out[13]; alu_i_in2[5] <= reg_i_out[13];	end
	1:		begin	alu_r_in2[5] <= reg_r_out[11]; alu_i_in2[5] <= reg_i_out[11];	end
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
logic sel_alu6_2;
always_comb
begin
case (sel_alu6_2)
	0:		begin	alu_r_in2[6] <= reg_r_out[14]; alu_i_in2[6] <= reg_i_out[14];	end
	1:		begin	alu_r_in2[6] <= reg_r_out[13]; alu_i_in2[6] <= reg_i_out[13];	end
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
assign alu_r_in2[7] = reg_r_out[15];	assign alu_i_in2[7] = reg_i_out[15];

//ALU8
assign alu_r_in1[8] = alu_r_in1[0];	assign alu_i_in1[8] = alu_i_in1[0];
assign alu_r_in2[8] = alu_r_in2[0];	assign alu_i_in2[8] = alu_i_in2[0];

//ALU9
assign alu_r_in1[9] = alu_r_in1[1];	assign alu_i_in1[9] = alu_i_in1[1];
assign alu_r_in2[9] = alu_r_in2[1];	assign alu_i_in2[9] = alu_i_in2[1];

//ALU10
assign alu_r_in1[10] = alu_r_in1[2];	assign alu_i_in1[10] = alu_i_in1[2];
assign alu_r_in2[10] = alu_r_in2[2];	assign alu_i_in2[10] = alu_i_in2[2];

//ALU11
assign alu_r_in1[11] = alu_r_in1[3];	assign alu_i_in1[11] = alu_i_in1[3];
assign alu_r_in2[11] = alu_r_in2[3];	assign alu_i_in2[11] = alu_i_in2[3];

//ALU12
assign alu_r_in1[12] = alu_r_in1[4];	assign alu_i_in1[12] = alu_i_in1[4];
assign alu_r_in2[12] = alu_r_in2[4];	assign alu_i_in2[12] = alu_i_in2[4];

//ALU13
assign alu_r_in1[13] = alu_r_in1[5];	assign alu_i_in1[13] = alu_i_in1[5];
assign alu_r_in2[13] = alu_r_in2[5];	assign alu_i_in2[13] = alu_i_in2[5];

//ALU14
assign alu_r_in1[14] = alu_r_in1[6];	assign alu_i_in1[14] = alu_i_in1[6];
assign alu_r_in2[14] = alu_r_in2[6];	assign alu_i_in2[14] = alu_i_in2[6];

//ALU15
assign alu_r_in1[15] = alu_r_in1[7];	assign alu_i_in1[15] = alu_i_in1[7];
assign alu_r_in2[15] = alu_r_in2[7];	assign alu_i_in2[15] = alu_i_in2[7];

//ALU_COMP0
logic [1:0] sel_alu_comp0;
always_comb
begin
case (sel_alu_comp0)
	0:		begin	alu_in_real[0] <= reg_r_out[10]; alu_in_imag[0] <= reg_i_out[10];	end
	1:		begin	alu_in_real[0] <= reg_r_out[9]; alu_in_imag[0] <= reg_i_out[9];	end
	2:		begin	alu_in_real[0] <= reg_r_out[5]; alu_in_imag[0] <= reg_i_out[5];	end
	default:	begin	alu_in_real[0] <= 'd0; alu_in_imag[0] <= 'd0;	end
endcase
end

//ALU_COMP1
logic sel_alu_comp1;
always_comb
begin
case (sel_alu_comp1)
	0:		begin	alu_in_real[1] <= reg_r_out[11]; alu_in_imag[1] <= reg_i_out[11];	end
	1:		begin	alu_in_real[1] <= reg_r_out[7]; alu_in_imag[1] <= reg_i_out[7];	end
	default:	begin	alu_in_real[1] <= 'd0; alu_in_imag[1] <= 'd0;	end
endcase
end

//ALU_COMP2
logic sel_alu_comp2;
always_comb
begin
case (sel_alu_comp2)
	0:		begin	alu_in_real[2] <= reg_r_out[14]; alu_in_imag[2] <= reg_i_out[14];	end
	1:		begin	alu_in_real[2] <= reg_r_out[13]; alu_in_imag[2] <= reg_i_out[13];	end
	default:	begin	alu_in_real[2] <= 'd0; alu_in_imag[2] <= 'd0;	end
endcase
end

//ALU_COMP3
assign alu_in_real[3] = reg_r_out[15];	assign alu_in_imag[3] = reg_i_out[15];

//ALU_COMP_CONST
logic sel_alu_const;
always_comb
begin
case (sel_alu_const)
	0:		begin	alu_const_real[0] <= 24'h2d413c; alu_const_imag[0] <= 24'h2d413c;	end
	1:		begin	alu_const_real[0] <= 24'h3b20d7; alu_const_imag[0] <= 24'h187de2;	end
	default:	begin	alu_const_real[0] <= 'd0; alu_const_imag[0] <= 'd0;	end
endcase
end
assign alu_const_real[1] = alu_const_real[0];	assign alu_const_imag[1] = alu_const_imag[0];
assign alu_const_real[2] = alu_const_real[0];	assign alu_const_imag[2] = alu_const_imag[0];
assign alu_const_real[3] = alu_const_real[0];	assign alu_const_imag[3] = alu_const_imag[0];

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
	2:		begin	reg_r_in[1] <= alu_r_out[8]; 	reg_i_in[1] <= alu_i_out[8];	end
	3:		begin	reg_r_in[1] <= reg_r_out[8]; 	reg_i_in[1] <= reg_i_out[8];	end
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
	2:		begin	reg_r_in[2] <= alu_r_out[8]; 	reg_i_in[2] <= alu_i_out[8];	end
	3:		begin	reg_r_in[2] <= alu_r_out[1]; 	reg_i_in[2] <= alu_i_out[1];	end
	4:		begin	reg_r_in[2] <= reg_r_out[4]; 	reg_i_in[2] <= reg_i_out[4];	end
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
	2:		begin	reg_r_in[3] <= alu_r_out[9]; 	reg_i_in[3] <= alu_i_out[9];	end
	3:		begin	reg_r_in[3] <= -reg_i_out[3]; 	reg_i_in[3] <= reg_r_out[3];	end
	4:		begin	reg_r_in[3] <= reg_r_out[12]; 	reg_i_in[3] <= reg_i_out[12];	end
	default:	begin	reg_r_in[3] <= 'd0; reg_i_in[3] <= 'd0;	end
endcase
end

//REG4
logic [2:0] sel_reg4;
always_comb
begin
case (sel_reg4)
	0:		begin	reg_r_in[4] <= in_r[4]; 	reg_i_in[4] <= in_i[4];	end
	1:		begin	reg_r_in[4] <= alu_r_out[4]; 	reg_i_in[4] <= alu_i_out[4];	end
	2:		begin	reg_r_in[4] <= alu_r_out[8]; 	reg_i_in[4] <= alu_i_out[8];	end
	3:		begin	reg_r_in[4] <= alu_r_out[2]; 	reg_i_in[4] <= alu_i_out[2];	end
	4:		begin	reg_r_in[4] <= reg_r_out[2]; 	reg_i_in[4] <= reg_i_out[2];	end
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
	2:		begin	reg_r_in[5] <= alu_r_out[9]; 	reg_i_in[5] <= alu_i_out[9];	end
	3:		begin	reg_r_in[5] <= alu_out_real[0]; 	reg_i_in[5] <= alu_out_imag[0];	end
	4:		begin	reg_r_in[5] <= alu_r_out[3]; 	reg_i_in[5] <= alu_i_out[3];	end
	5:		begin	reg_r_in[5] <= alu_r_out[10]; 	reg_i_in[5] <= alu_i_out[10];	end
	6:		begin	reg_r_in[5] <= reg_r_out[10]; 	reg_i_in[5] <= reg_i_out[10];	end
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
	2:		begin	reg_r_in[6] <= alu_r_out[10]; 	reg_i_in[6] <= alu_i_out[10];	end
	3:		begin	reg_r_in[6] <= -reg_i_out[6]; 	reg_i_in[6] <= reg_r_out[6];	end
	4:		begin	reg_r_in[6] <= alu_r_out[3]; 	reg_i_in[6] <= alu_i_out[3];	end
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
	2:		begin	reg_r_in[7] <= alu_r_out[11]; 	reg_i_in[7] <= alu_i_out[11];	end
	3:		begin	reg_r_in[7] <= -reg_i_out[7]; 	reg_i_in[7] <= reg_r_out[7];	end
	4:		begin	reg_r_in[7] <= alu_out_real[1]; 	reg_i_in[7] <= alu_out_imag[1];	end
	5:		begin	reg_r_in[7] <= reg_r_out[14]; 	reg_i_in[7] <= reg_i_out[14];	end
	default:	begin	reg_r_in[7] <= 'd0; reg_i_in[7] <= 'd0;	end
endcase
end

//REG8
logic [1:0] sel_reg8;
always_comb
begin
case (sel_reg8)
	0:		begin	reg_r_in[8] <= in_r[8]; 	reg_i_in[8] <= in_i[8];	end
	1:		begin	reg_r_in[8] <= alu_r_out[8]; 	reg_i_in[8] <= alu_i_out[8];	end
	2:		begin	reg_r_in[8] <= alu_r_out[4]; 	reg_i_in[8] <= alu_i_out[4];	end
	3:		begin	reg_r_in[8] <= reg_r_out[1]; 	reg_i_in[8] <= reg_i_out[1];	end
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
	2:		begin	reg_r_in[9] <= alu_out_real[0]; 	reg_i_in[9] <= alu_out_imag[0];	end
	3:		begin	reg_r_in[9] <= alu_r_out[5]; 	reg_i_in[9] <= alu_i_out[5];	end
	4:		begin	reg_r_in[9] <= alu_r_out[12]; 	reg_i_in[9] <= alu_i_out[12];	end
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
	2:		begin	reg_r_in[10] <= alu_out_real[0]; 	reg_i_in[10] <= alu_out_imag[0];	end
	3:		begin	reg_r_in[10] <= alu_r_out[6]; 	reg_i_in[10] <= alu_i_out[6];	end
	4:		begin	reg_r_in[10] <= alu_r_out[12]; 	reg_i_in[10] <= alu_i_out[12];	end
	5:		begin	reg_r_in[10] <= alu_r_out[5]; 	reg_i_in[10] <= alu_i_out[5];	end
	6:		begin	reg_r_in[10] <= reg_r_out[5]; 	reg_i_in[10] <= reg_i_out[5];	end
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
	2:		begin	reg_r_in[11] <= alu_out_real[1]; 	reg_i_in[11] <= alu_out_imag[1];	end
	3:		begin	reg_r_in[11] <= alu_r_out[7]; 	reg_i_in[11] <= alu_i_out[7];	end
	4:		begin	reg_r_in[11] <= alu_r_out[13]; 	reg_i_in[11] <= alu_i_out[13];	end
	5:		begin	reg_r_in[11] <= -reg_i_out[11]; 	reg_i_in[11] <= reg_r_out[11];	end
	6:		begin	reg_r_in[11] <= reg_r_out[13]; 	reg_i_in[11] <= reg_i_out[13];	end
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
	2:		begin	reg_r_in[12] <= -reg_i_out[12]; 	reg_i_in[12] <= reg_r_out[12];	end
	3:		begin	reg_r_in[12] <= alu_r_out[6]; 	reg_i_in[12] <= alu_i_out[6];	end
	4:		begin	reg_r_in[12] <= reg_r_out[3]; 	reg_i_in[12] <= reg_i_out[3];	end
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
	2:		begin	reg_r_in[13] <= -reg_i_out[13]; 	reg_i_in[13] <= reg_r_out[13];	end
	3:		begin	reg_r_in[13] <= alu_out_real[2]; 	reg_i_in[13] <= alu_out_imag[2];	end
	4:		begin	reg_r_in[13] <= alu_r_out[7]; 	reg_i_in[13] <= alu_i_out[7];	end
	5:		begin	reg_r_in[13] <= alu_r_out[14]; 	reg_i_in[13] <= alu_i_out[14];	end
	6:		begin	reg_r_in[13] <= reg_r_out[11]; 	reg_i_in[13] <= reg_i_out[11];	end
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
	2:		begin	reg_r_in[14] <= -reg_i_out[14]; 	reg_i_in[14] <= reg_r_out[14];	end
	3:		begin	reg_r_in[14] <= alu_out_real[2]; 	reg_i_in[14] <= alu_out_imag[2];	end
	4:		begin	reg_r_in[14] <= alu_r_out[7]; 	reg_i_in[14] <= alu_i_out[7];	end
	5:		begin	reg_r_in[14] <= reg_r_out[7]; 	reg_i_in[14] <= reg_i_out[7];	end
	default:	begin	reg_r_in[14] <= 'd0; reg_i_in[14] <= 'd0;	end
endcase
end

//REG15
logic [1:0] sel_reg15;
always_comb
begin
case (sel_reg15)
	0:		begin	reg_r_in[15] <= in_r[15]; 	reg_i_in[15] <= in_i[15];	end
	1:		begin	reg_r_in[15] <= alu_r_out[15]; 	reg_i_in[15] <= alu_i_out[15];	end
	2:		begin	reg_r_in[15] <= -reg_i_out[15]; 	reg_i_in[15] <= reg_r_out[15];	end
	3:		begin	reg_r_in[15] <= alu_out_real[3]; 	reg_i_in[15] <= alu_out_imag[3];	end
	default:	begin	reg_r_in[15] <= 'd0; reg_i_in[15] <= 'd0;	end
endcase
end

//CU FSM: Split always block
reg [3:0] state, next_state;
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
		//ALUs
		sel_alu0_2<='d26479;
		sel_alu1_1<='d29793;
		sel_alu1_2<='d25449;
		sel_alu2_1<='d8293;
		sel_alu2_2<='d29472;
		sel_alu3_1<='d28271;
		sel_alu3_2<='d26473;
		sel_alu4_1<='d31084;
		sel_alu4_2<='d25966;
		sel_alu5_1<='d28704;
		sel_alu5_2<='d8292;
		sel_alu6_1<='d29285;
		sel_alu6_2<='d10331;
		sel_alu7_1<='d28518;
		//ALU_COMPs
		sel_alu_const<='d25701;
		sel_alu_comp0<='d23856;
		sel_alu_comp1<='d24864;
		sel_alu_comp2<='d30060;
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
		//ALU_COMPs
		sel_alu_const<='d8300;
		sel_alu_comp0<='d28515;
		sel_alu_comp1<='d28781;
		sel_alu_comp2<='d25964;
	end
	2: begin
		next_state<=3;
		//Registers
		sel_reg0<='d28021;		LD[0]<='d114;
		sel_reg1<='d25183;		LD[1]<='d97;
		sel_reg2<='d29801;		LD[2]<='d116;
		sel_reg3<='d12589;		LD[3]<='d101;
		sel_reg4<='d14889;		LD[4]<='d10;
		sel_reg5<='d23856;		LD[5]<='d102;
		sel_reg6<='d24864;		LD[6]<='d111;
		sel_reg7<='d30060;		LD[7]<='d114;
		sel_reg8<='d28511;		LD[8]<='d32;
		sel_reg9<='d29813;		LD[9]<='d40;
		sel_reg10<='d26975;		LD[10]<='d108;
		sel_reg11<='d24941;		LD[11]<='d61;
		sel_reg12<='d2;		LD[12]<='d1;
		sel_reg13<='d2;		LD[13]<='d1;
		sel_reg14<='d2;		LD[14]<='d1;
		sel_reg15<='d2;		LD[15]<='d1;
		//ALUs
		sel_alu0_2<='d25964;
		sel_alu1_1<='d27745;
		sel_alu1_2<='d8312;
		sel_alu2_1<='d12917;
		sel_alu2_2<='d11816;
		sel_alu3_1<='d2314;
		sel_alu3_2<='d28265;
		sel_alu4_1<='d27745;
		sel_alu4_2<='d29279;
		sel_alu5_1<='d24437;
		sel_alu5_2<='d24933;
		sel_alu6_1<='d30061;
		sel_alu6_2<='d10348;
		sel_alu7_1<='d24428;
		//ALU_COMPs
		sel_alu_const<='d25970;
		sel_alu_comp0<='d28265;
		sel_alu_comp1<='d26975;
		sel_alu_comp2<='d24941;
	end
	3: begin
		next_state<=4;
		//Registers
		sel_reg0<='d28009;		LD[0]<='d108;
		sel_reg1<='d26465;		LD[1]<='d93;
		sel_reg2<='d24872;		LD[2]<='d41;
		sel_reg3<='d30060;		LD[3]<='d44;
		sel_reg4<='d25439;		LD[4]<='d32;
		sel_reg5<='d28271;		LD[5]<='d46;
		sel_reg6<='d29811;		LD[6]<='d111;
		sel_reg7<='d26975;		LD[7]<='d117;
		sel_reg8<='d24941;		LD[8]<='d116;
		sel_reg9<='d23399;		LD[9]<='d95;
		sel_reg10<='d2;		LD[10]<='d1;
		sel_reg11<='d2;		LD[11]<='d1;
		sel_reg12<='d11808;		LD[12]<='d97;
		sel_reg13<='d30063;		LD[13]<='d103;
		sel_reg14<='d3;		LD[14]<='d1;
		sel_reg15<='d3;		LD[15]<='d1;
		//ALUs
		sel_alu0_2<='d31337;
		sel_alu1_1<='d25609;
		sel_alu1_2<='d8293;
		sel_alu2_1<='d26213;
		sel_alu2_2<='d8253;
		sel_alu3_1<='d24944;
		sel_alu3_2<='d24947;
		sel_alu4_1<='d24946;
		sel_alu4_2<='d28781;
		sel_alu5_1<='d8301;
		sel_alu5_2<='d25964;
		sel_alu6_1<='d27745;
		sel_alu6_2<='d29535;
		sel_alu7_1<='d24437;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
	end
	4: begin
		next_state<=5;
		//Registers
		sel_reg0<='d25183;		LD[0]<='d0;
		sel_reg1<='d29801;		LD[1]<='d0;
		sel_reg2<='d15648;		LD[2]<='d0;
		sel_reg3<='d26144;		LD[3]<='d0;
		sel_reg4<='d24432;		LD[4]<='d0;
		sel_reg5<='d26978;		LD[5]<='d0;
		sel_reg6<='d15220;		LD[6]<='d0;
		sel_reg7<='d25866;		LD[7]<='d0;
		sel_reg8<='d25710;		LD[8]<='d0;
		sel_reg9<='d2;		LD[9]<='d1;
		sel_reg10<='d27745;		LD[10]<='d0;
		sel_reg11<='d2;		LD[11]<='d1;
		sel_reg12<='d25866;		LD[12]<='d0;
		sel_reg13<='d3;		LD[13]<='d1;
		sel_reg14<='d25959;		LD[14]<='d0;
		sel_reg15<='d3;		LD[15]<='d1;
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
		//ALU_COMPs
		sel_alu_const<='d1;
		sel_alu_comp0<='d1;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d1;
	end
	5: begin
		next_state<=6;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d1;		LD[1]<='d1;
		sel_reg2<='d1;		LD[2]<='d1;
		sel_reg3<='d1;		LD[3]<='d1;
		sel_reg4<='d2;		LD[4]<='d1;
		sel_reg5<='d2;		LD[5]<='d1;
		sel_reg6<='d2;		LD[6]<='d1;
		sel_reg7<='d2;		LD[7]<='d1;
		sel_reg8<='d2;		LD[8]<='d1;
		sel_reg9<='d3;		LD[9]<='d1;
		sel_reg10<='d3;		LD[10]<='d1;
		sel_reg11<='d3;		LD[11]<='d1;
		sel_reg12<='d1;		LD[12]<='d1;
		sel_reg13<='d1;		LD[13]<='d1;
		sel_reg14<='d1;		LD[14]<='d1;
		sel_reg15<='d1;		LD[15]<='d1;
		//ALUs
		sel_alu0_2<='d1;
		sel_alu1_1<='d0;
		sel_alu1_2<='d1;
		sel_alu2_1<='d0;
		sel_alu2_2<='d1;
		sel_alu3_1<='d0;
		sel_alu3_2<='d1;
		sel_alu4_1<='d1;
		sel_alu4_2<='d0;
		sel_alu5_1<='d1;
		sel_alu5_2<='d0;
		sel_alu6_1<='d1;
		sel_alu6_2<='d0;
		sel_alu7_1<='d1;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
	end
	6: begin
		next_state<=7;
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
		sel_reg14<='d2;		LD[14]<='d1;
		sel_reg15<='d2;		LD[15]<='d1;
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
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
	end
	7: begin
		next_state<=8;
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
		sel_reg13<='d3;		LD[13]<='d1;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d3;		LD[15]<='d1;
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
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d2;
		sel_alu_comp1<='d1;
		sel_alu_comp2<='d1;
	end
	8: begin
		next_state<=9;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d1;		LD[1]<='d1;
		sel_reg2<='d2;		LD[2]<='d1;
		sel_reg3<='d2;		LD[3]<='d1;
		sel_reg4<='d3;		LD[4]<='d1;
		sel_reg5<='d4;		LD[5]<='d1;
		sel_reg6<='d2;		LD[6]<='d1;
		sel_reg7<='d2;		LD[7]<='d1;
		sel_reg8<='d2;		LD[8]<='d1;
		sel_reg9<='d3;		LD[9]<='d1;
		sel_reg10<='d4;		LD[10]<='d1;
		sel_reg11<='d4;		LD[11]<='d1;
		sel_reg12<='d3;		LD[12]<='d1;
		sel_reg13<='d4;		LD[13]<='d1;
		sel_reg14<='d1;		LD[14]<='d1;
		sel_reg15<='d1;		LD[15]<='d1;
		//ALUs
		sel_alu0_2<='d2;
		sel_alu1_1<='d0;
		sel_alu1_2<='d2;
		sel_alu2_1<='d1;
		sel_alu2_2<='d1;
		sel_alu3_1<='d1;
		sel_alu3_2<='d1;
		sel_alu4_1<='d1;
		sel_alu4_2<='d1;
		sel_alu5_1<='d1;
		sel_alu5_2<='d1;
		sel_alu6_1<='d2;
		sel_alu6_2<='d0;
		sel_alu7_1<='d2;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
	end
	9: begin
		next_state<=10;
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
		sel_reg11<='d5;		LD[11]<='d1;
		sel_reg12<='d0;		LD[12]<='d0;
		sel_reg13<='d0;		LD[13]<='d0;
		sel_reg14<='d0;		LD[14]<='d0;
		sel_reg15<='d2;		LD[15]<='d1;
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
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
	end
	10: begin
		next_state<=11;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d2;		LD[1]<='d1;
		sel_reg2<='d3;		LD[2]<='d1;
		sel_reg3<='d2;		LD[3]<='d1;
		sel_reg4<='d3;		LD[4]<='d1;
		sel_reg5<='d5;		LD[5]<='d1;
		sel_reg6<='d4;		LD[6]<='d1;
		sel_reg7<='d2;		LD[7]<='d1;
		sel_reg8<='d2;		LD[8]<='d1;
		sel_reg9<='d4;		LD[9]<='d1;
		sel_reg10<='d5;		LD[10]<='d1;
		sel_reg11<='d4;		LD[11]<='d1;
		sel_reg12<='d3;		LD[12]<='d1;
		sel_reg13<='d5;		LD[13]<='d1;
		sel_reg14<='d4;		LD[14]<='d1;
		sel_reg15<='d1;		LD[15]<='d1;
		//ALUs
		sel_alu0_2<='d3;
		sel_alu1_1<='d1;
		sel_alu1_2<='d2;
		sel_alu2_1<='d1;
		sel_alu2_2<='d2;
		sel_alu3_1<='d2;
		sel_alu3_2<='d1;
		sel_alu4_1<='d1;
		sel_alu4_2<='d2;
		sel_alu5_1<='d2;
		sel_alu5_2<='d1;
		sel_alu6_1<='d2;
		sel_alu6_2<='d1;
		sel_alu7_1<='d3;
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
	end
	11: begin
		next_state<=12;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d3;		LD[1]<='d1;
		sel_reg2<='d4;		LD[2]<='d1;
		sel_reg3<='d4;		LD[3]<='d1;
		sel_reg4<='d4;		LD[4]<='d1;
		sel_reg5<='d6;		LD[5]<='d1;
		sel_reg6<='d0;		LD[6]<='d0;
		sel_reg7<='d5;		LD[7]<='d1;
		sel_reg8<='d3;		LD[8]<='d1;
		sel_reg9<='d0;		LD[9]<='d0;
		sel_reg10<='d6;		LD[10]<='d1;
		sel_reg11<='d6;		LD[11]<='d1;
		sel_reg12<='d4;		LD[12]<='d1;
		sel_reg13<='d6;		LD[13]<='d1;
		sel_reg14<='d5;		LD[14]<='d1;
		sel_reg15<='d0;		LD[15]<='d0;
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
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
	end
	default: begin
		next_state<=12;
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
		//ALU_COMPs
		sel_alu_const<='d0;
		sel_alu_comp0<='d0;
		sel_alu_comp1<='d0;
		sel_alu_comp2<='d0;
	end
	endcase
end

//Output
assign out_r = reg_r_out;	assign out_i = reg_i_out;
endmodule
