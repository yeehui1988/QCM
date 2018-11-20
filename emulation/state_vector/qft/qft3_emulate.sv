module qft3_emulate #(parameter sample_size = 8, complexnum_bit = 24, fp_bit = 22, mul_h = 25'h2D413C)(
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
logic signed [(complexnum_bit-1):0] alu_in_real [0:1];
logic signed [(complexnum_bit-1):0] alu_in_imag [0:1];
logic signed [(complexnum_bit-1):0] alu_const_real [0:1];
logic signed [(complexnum_bit-1):0] alu_const_imag [0:1];
logic signed [(complexnum_bit-1):0] alu_out_real [0:1];
logic signed [(complexnum_bit-1):0] alu_out_imag [0:1];

genvar l;
generate
for (l=0; l<2; l=l+1)
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
	0:		begin	alu_r_in2[0] <= reg_r_out[4]; alu_i_in2[0] <= reg_i_out[4];	end
	1:		begin	alu_r_in2[0] <= reg_r_out[2]; alu_i_in2[0] <= reg_i_out[2];	end
	2:		begin	alu_r_in2[0] <= reg_r_out[1]; alu_i_in2[0] <= reg_i_out[1];	end
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
logic sel_alu1_2;
always_comb
begin
case (sel_alu1_2)
	0:		begin	alu_r_in2[1] <= reg_r_out[5]; alu_i_in2[1] <= reg_i_out[5];	end
	1:		begin	alu_r_in2[1] <= reg_r_out[3]; alu_i_in2[1] <= reg_i_out[3];	end
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
logic sel_alu2_2;
always_comb
begin
case (sel_alu2_2)
	0:		begin	alu_r_in2[2] <= reg_r_out[6]; alu_i_in2[2] <= reg_i_out[6];	end
	1:		begin	alu_r_in2[2] <= reg_r_out[5]; alu_i_in2[2] <= reg_i_out[5];	end
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
assign alu_r_in2[3] = reg_r_out[7];	assign alu_i_in2[3] = reg_i_out[7];

//ALU4
assign alu_r_in1[4] = alu_r_in1[0];	assign alu_i_in1[4] = alu_i_in1[0];
assign alu_r_in2[4] = alu_r_in2[0];	assign alu_i_in2[4] = alu_i_in2[0];

//ALU5
assign alu_r_in1[5] = alu_r_in1[1];	assign alu_i_in1[5] = alu_i_in1[1];
assign alu_r_in2[5] = alu_r_in2[1];	assign alu_i_in2[5] = alu_i_in2[1];

//ALU6
assign alu_r_in1[6] = alu_r_in1[2];	assign alu_i_in1[6] = alu_i_in1[2];
assign alu_r_in2[6] = alu_r_in2[2];	assign alu_i_in2[6] = alu_i_in2[2];

//ALU7
assign alu_r_in1[7] = alu_r_in1[3];	assign alu_i_in1[7] = alu_i_in1[3];
assign alu_r_in2[7] = alu_r_in2[3];	assign alu_i_in2[7] = alu_i_in2[3];

//ALU_COMP0
assign alu_in_real[0] = reg_r_out[5];	assign alu_in_imag[0] = reg_i_out[5];

//ALU_COMP1
assign alu_in_real[1] = reg_r_out[7];	assign alu_in_imag[1] = reg_i_out[7];

//ALU_COMP_CONST
assign alu_const_real[0] = 24'h2d413c;	assign alu_const_imag[0] = 24'h2d413c;
assign alu_const_real[1] = alu_const_real[0];	assign alu_const_imag[1] = alu_const_imag[0];

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
	2:		begin	reg_r_in[1] <= alu_r_out[4]; 	reg_i_in[1] <= alu_i_out[4];	end
	3:		begin	reg_r_in[1] <= reg_r_out[4]; 	reg_i_in[1] <= reg_i_out[4];	end
	default:	begin	reg_r_in[1] <= 'd0; reg_i_in[1] <= 'd0;	end
endcase
end

//REG2
logic [1:0] sel_reg2;
always_comb
begin
case (sel_reg2)
	0:		begin	reg_r_in[2] <= in_r[2]; 	reg_i_in[2] <= in_i[2];	end
	1:		begin	reg_r_in[2] <= alu_r_out[2]; 	reg_i_in[2] <= alu_i_out[2];	end
	2:		begin	reg_r_in[2] <= alu_r_out[4]; 	reg_i_in[2] <= alu_i_out[4];	end
	3:		begin	reg_r_in[2] <= alu_r_out[1]; 	reg_i_in[2] <= alu_i_out[1];	end
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
	2:		begin	reg_r_in[3] <= alu_r_out[5]; 	reg_i_in[3] <= alu_i_out[5];	end
	3:		begin	reg_r_in[3] <= -reg_i_out[3]; 	reg_i_in[3] <= reg_r_out[3];	end
	4:		begin	reg_r_in[3] <= reg_r_out[6]; 	reg_i_in[3] <= reg_i_out[6];	end
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
	2:		begin	reg_r_in[4] <= alu_r_out[2]; 	reg_i_in[4] <= alu_i_out[2];	end
	3:		begin	reg_r_in[4] <= reg_r_out[1]; 	reg_i_in[4] <= reg_i_out[1];	end
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
	2:		begin	reg_r_in[5] <= alu_out_real[0]; 	reg_i_in[5] <= alu_out_imag[0];	end
	3:		begin	reg_r_in[5] <= alu_r_out[3]; 	reg_i_in[5] <= alu_i_out[3];	end
	4:		begin	reg_r_in[5] <= alu_r_out[6]; 	reg_i_in[5] <= alu_i_out[6];	end
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
	2:		begin	reg_r_in[6] <= -reg_i_out[6]; 	reg_i_in[6] <= reg_r_out[6];	end
	3:		begin	reg_r_in[6] <= alu_r_out[3]; 	reg_i_in[6] <= alu_i_out[3];	end
	4:		begin	reg_r_in[6] <= reg_r_out[3]; 	reg_i_in[6] <= reg_i_out[3];	end
	default:	begin	reg_r_in[6] <= 'd0; reg_i_in[6] <= 'd0;	end
endcase
end

//REG7
logic [1:0] sel_reg7;
always_comb
begin
case (sel_reg7)
	0:		begin	reg_r_in[7] <= in_r[7]; 	reg_i_in[7] <= in_i[7];	end
	1:		begin	reg_r_in[7] <= alu_r_out[7]; 	reg_i_in[7] <= alu_i_out[7];	end
	2:		begin	reg_r_in[7] <= -reg_i_out[7]; 	reg_i_in[7] <= reg_r_out[7];	end
	3:		begin	reg_r_in[7] <= alu_out_real[1]; 	reg_i_in[7] <= alu_out_imag[1];	end
	default:	begin	reg_r_in[7] <= 'd0; reg_i_in[7] <= 'd0;	end
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
		//ALUs
		sel_alu0_2<='d26975;
		sel_alu1_1<='d8292;
		sel_alu1_2<='d12654;
		sel_alu2_1<='d10331;
		sel_alu2_2<='d23328;
		sel_alu3_1<='d28515;
		//ALU_COMPs
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
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		//ALU_COMPs
	end
	2: begin
		next_state<=3;
		//Registers
		sel_reg0<='d12589;		LD[0]<='d98;
		sel_reg1<='d23849;		LD[1]<='d105;
		sel_reg2<='d2619;		LD[2]<='d116;
		sel_reg3<='d28524;		LD[3]<='d45;
		sel_reg4<='d26983;		LD[4]<='d49;
		sel_reg5<='d8291;		LD[5]<='d41;
		sel_reg6<='d2;		LD[6]<='d1;
		sel_reg7<='d2;		LD[7]<='d1;
		//ALUs
		sel_alu0_2<='d10272;
		sel_alu1_1<='d11621;
		sel_alu1_2<='d15721;
		sel_alu2_1<='d10545;
		sel_alu2_2<='d15152;
		sel_alu3_1<='d15197;
		//ALU_COMPs
	end
	3: begin
		next_state<=4;
		//Registers
		sel_reg0<='d24437;		LD[0]<='d32;
		sel_reg1<='d24434;		LD[1]<='d46;
		sel_reg2<='d28265;		LD[2]<='d105;
		sel_reg3<='d23345;		LD[3]<='d110;
		sel_reg4<='d23913;		LD[4]<='d51;
		sel_reg5<='d2;		LD[5]<='d1;
		sel_reg6<='d11808;		LD[6]<='d109;
		sel_reg7<='d3;		LD[7]<='d1;
		//ALUs
		sel_alu0_2<='d25978;
		sel_alu1_1<='d2314;
		sel_alu1_2<='d15648;
		sel_alu2_1<='d25956;
		sel_alu2_2<='d29472;
		sel_alu3_1<='d28774;
		//ALU_COMPs
	end
	4: begin
		next_state<=5;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d1;		LD[1]<='d1;
		sel_reg2<='d2;		LD[2]<='d1;
		sel_reg3<='d2;		LD[3]<='d1;
		sel_reg4<='d2;		LD[4]<='d1;
		sel_reg5<='d3;		LD[5]<='d1;
		sel_reg6<='d1;		LD[6]<='d1;
		sel_reg7<='d1;		LD[7]<='d1;
		//ALUs
		sel_alu0_2<='d1;
		sel_alu1_1<='d0;
		sel_alu1_2<='d1;
		sel_alu2_1<='d1;
		sel_alu2_2<='d0;
		sel_alu3_1<='d1;
		//ALU_COMPs
	end
	5: begin
		next_state<=6;
		//Registers
		sel_reg0<='d30060;		LD[0]<='d122;
		sel_reg1<='d29535;		LD[1]<='d101;
		sel_reg2<='d25205;		LD[2]<='d59;
		sel_reg3<='d3;		LD[3]<='d1;
		sel_reg4<='d29486;		LD[4]<='d100;
		sel_reg5<='d28001;		LD[5]<='d101;
		sel_reg6<='d27760;		LD[6]<='d102;
		sel_reg7<='d2;		LD[7]<='d1;
		//ALUs
		sel_alu0_2<='d24864;
		sel_alu1_1<='d26978;
		sel_alu1_2<='d30060;
		sel_alu2_1<='d8308;
		sel_alu2_2<='d29535;
		sel_alu3_1<='d8253;
		//ALU_COMPs
	end
	6: begin
		next_state<=7;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d2;		LD[1]<='d1;
		sel_reg2<='d3;		LD[2]<='d1;
		sel_reg3<='d2;		LD[3]<='d1;
		sel_reg4<='d2;		LD[4]<='d1;
		sel_reg5<='d4;		LD[5]<='d1;
		sel_reg6<='d3;		LD[6]<='d1;
		sel_reg7<='d1;		LD[7]<='d1;
		//ALUs
		sel_alu0_2<='d2;
		sel_alu1_1<='d1;
		sel_alu1_2<='d1;
		sel_alu2_1<='d1;
		sel_alu2_2<='d1;
		sel_alu3_1<='d2;
		//ALU_COMPs
	end
	7: begin
		next_state<=8;
		//Registers
		sel_reg0<='d18735;		LD[0]<='d9;
		sel_reg1<='d3;		LD[1]<='d1;
		sel_reg2<='d26983;		LD[2]<='d108;
		sel_reg3<='d4;		LD[3]<='d1;
		sel_reg4<='d3;		LD[4]<='d1;
		sel_reg5<='d8250;		LD[5]<='d115;
		sel_reg6<='d4;		LD[6]<='d1;
		sel_reg7<='d29794;		LD[7]<='d98;
		//ALUs
		sel_alu0_2<='d26975;
		sel_alu1_1<='d26971;
		sel_alu1_2<='d26975;
		sel_alu2_1<='d10283;
		sel_alu2_2<='d12910;
		sel_alu3_1<='d24947;
		//ALU_COMPs
	end
	default: begin
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
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
		sel_alu1_2<='d0;
		sel_alu2_1<='d0;
		sel_alu2_2<='d0;
		sel_alu3_1<='d0;
		//ALU_COMPs
	end
	endcase
end

//Output
assign out_r = reg_r_out;	assign out_i = reg_i_out;
endmodule
