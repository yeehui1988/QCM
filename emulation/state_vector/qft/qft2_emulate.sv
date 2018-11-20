module qft2_emulate #(parameter sample_size = 4, complexnum_bit = 24, fp_bit = 22, mul_h = 25'h2D413C)(
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

/*******************************************Multiplexing*******************************************/
//Select inputs for ALUs

//ALU0
assign alu_r_in1[0] = reg_r_out[0];	assign alu_i_in1[0] = reg_i_out[0];
logic sel_alu0_2;
always_comb
begin
case (sel_alu0_2)
	0:		begin	alu_r_in2[0] <= reg_r_out[2]; alu_i_in2[0] <= reg_i_out[2];	end
	1:		begin	alu_r_in2[0] <= reg_r_out[1]; alu_i_in2[0] <= reg_i_out[1];	end
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
assign alu_r_in2[1] = reg_r_out[3];	assign alu_i_in2[1] = reg_i_out[3];

//ALU2
assign alu_r_in1[2] = alu_r_in1[0];	assign alu_i_in1[2] = alu_i_in1[0];
assign alu_r_in2[2] = alu_r_in2[0];	assign alu_i_in2[2] = alu_i_in2[0];

//ALU3
assign alu_r_in1[3] = alu_r_in1[1];	assign alu_i_in1[3] = alu_i_in1[1];
assign alu_r_in2[3] = alu_r_in2[1];	assign alu_i_in2[3] = alu_i_in2[1];

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
	2:		begin	reg_r_in[1] <= alu_r_out[2]; 	reg_i_in[1] <= alu_i_out[2];	end
	3:		begin	reg_r_in[1] <= reg_r_out[2]; 	reg_i_in[1] <= reg_i_out[2];	end
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
	2:		begin	reg_r_in[2] <= alu_r_out[1]; 	reg_i_in[2] <= alu_i_out[1];	end
	3:		begin	reg_r_in[2] <= reg_r_out[1]; 	reg_i_in[2] <= reg_i_out[1];	end
	default:	begin	reg_r_in[2] <= 'd0; reg_i_in[2] <= 'd0;	end
endcase
end

//REG3
logic [1:0] sel_reg3;
always_comb
begin
case (sel_reg3)
	0:		begin	reg_r_in[3] <= in_r[3]; 	reg_i_in[3] <= in_i[3];	end
	1:		begin	reg_r_in[3] <= alu_r_out[3]; 	reg_i_in[3] <= alu_i_out[3];	end
	2:		begin	reg_r_in[3] <= -reg_i_out[3]; 	reg_i_in[3] <= reg_r_out[3];	end
	default:	begin	reg_r_in[3] <= 'd0; reg_i_in[3] <= 'd0;	end
endcase
end

//CU FSM: Split always block
reg [2:0] state, next_state;
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
		//ALUs
		sel_alu0_2<='d28263;
		sel_alu1_1<='d12379;
	end
	1: begin
		next_state<=2;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d1;		LD[1]<='d1;
		sel_reg2<='d1;		LD[2]<='d1;
		sel_reg3<='d1;		LD[3]<='d1;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
	end
	2: begin
		next_state<=3;
		//Registers
		sel_reg0<='d23856;		LD[0]<='d59;
		sel_reg1<='d29216;		LD[1]<='d10;
		sel_reg2<='d26469;		LD[2]<='d108;
		sel_reg3<='d2;		LD[3]<='d1;
		//ALUs
		sel_alu0_2<='d10794;
		sel_alu1_1<='d10794;
	end
	3: begin
		next_state<=4;
		//Registers
		sel_reg0<='d1;		LD[0]<='d1;
		sel_reg1<='d2;		LD[1]<='d1;
		sel_reg2<='d2;		LD[2]<='d1;
		sel_reg3<='d1;		LD[3]<='d1;
		//ALUs
		sel_alu0_2<='d1;
		sel_alu1_1<='d1;
	end
	4: begin
		next_state<=5;
		//Registers
		sel_reg0<='d8299;		LD[0]<='d41;
		sel_reg1<='d3;		LD[1]<='d1;
		sel_reg2<='d3;		LD[2]<='d1;
		sel_reg3<='d8235;		LD[3]<='d47;
		//ALUs
		sel_alu0_2<='d23406;
		sel_alu1_1<='d28265;
	end
	default: begin
		next_state<=5;
		//Registers
		sel_reg0<='d0;		LD[0]<='d0;
		sel_reg1<='d0;		LD[1]<='d0;
		sel_reg2<='d0;		LD[2]<='d0;
		sel_reg3<='d0;		LD[3]<='d0;
		//ALUs
		sel_alu0_2<='d0;
		sel_alu1_1<='d0;
	end
	endcase
end

//Output
assign out_r = reg_r_out;	assign out_i = reg_i_out;
endmodule
