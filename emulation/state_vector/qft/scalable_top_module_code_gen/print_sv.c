#define	fp_bit	22      //Number of bit for fixed point representation (Current version is hard-set. Can be modified to be parameterizable)

typedef struct
{
  	unsigned short* index1;	//registers index for ALU operation
	unsigned short* index2;	//registers index for ALU operation
	unsigned short count1;	//number of elements for multiplexing
	unsigned short count2;	//number of elements for multiplexing
} ALU_CONTROL;

typedef struct
{
  	unsigned short* index;	//registers index for ALU operation
	unsigned short count;	//number of elements for multiplexing
	unsigned int* const_real;	//constant number for multiplication
	unsigned int* const_imag;	//constant number for multiplication
	unsigned short const_count;	//number of elements for multiplexing	
} ALU_COMP_CONTROL;

typedef struct
{	
	unsigned short* type;	//0: external input; 1: ALU output; 2: REG output; 3: NEG output (out_r=-in_i, out_i=in_r);  4: ALU_COMP output;
  	unsigned short* index;	//registers index for ALU operation
	unsigned short count;	//number of elements for multiplexing
} REG_CONTROL;

typedef struct
{
	unsigned short* reg_mux;		//selector for registers inputs
	unsigned char* reg_ld;			//enable for registers
  	unsigned short* alu_mux1;		//selector for ALUs (add/subtract with multiplication) input1
  	unsigned short* alu_mux2;		//selector for ALUs (add/subtract with multiplication) input2
	unsigned short* alu_comp_mux;		//selector for ALUs (add/subtract with multiplication) inputs
	unsigned short* alu_comp_const_mux;	//selector for ALUs (add/subtract with multiplication) inputs
} FSM_CONTROL;

unsigned int float2fix (float in)
{
	float convert;
	convert = pow(2,fp_bit);
	return (unsigned int) (in * convert);
}

int check_if_exist (unsigned short* index, unsigned short count, unsigned short query)
{
	int i;
	for(i=0;i<count;i++)
	{
		if(index[i]==query)
			return i;
	}
	return -1;	//Not found in existing list
}

int check_if_reg_exist (unsigned short* index, unsigned short* type, unsigned short count, unsigned short query, unsigned short query_type)
{
	int i;
	for(i=0;i<count;i++)
	{
		if(index[i]==query && type[i]==query_type)
			return i;
	}
	return -1;	//Not found in existing list
}

int check_if_const_exist (unsigned int* const_real, unsigned int* const_imag, unsigned short count, unsigned int query_real, unsigned int query_imag)
{
	int i;
	for(i=0;i<count;i++)
	{
		if(const_real[i]==query_real && const_imag[i]==query_imag)
			return i;
	}
	return -1;	//Not found in existing list
}

unsigned short calc_num_control_bit(unsigned short input)
{
	unsigned short bit;
	if(input == 0)
		bit=0;
	else
	{
		bit = 1;
		while (pow(2,bit) < input)
			bit++;
	}
	return bit;
}

void print_header (unsigned int QUBIT, unsigned int sample_size)
{
	FILE *output;
	output=fopen("./qft_emulate.sv","w");
	fprintf(output,"module qft%u_emulate #(parameter sample_size = %u, complexnum_bit = 24, fp_bit = 22, mul_h = 25'h2D413C)(\n", QUBIT, sample_size);
	fprintf(output,"input clk, input rst,\n");
	fprintf(output,"input signed [(complexnum_bit-1):0] in_r[0:(sample_size-1)],\n");
	fprintf(output,"input signed [(complexnum_bit-1):0] in_i[0:(sample_size-1)],\n");
	fprintf(output,"output signed [(complexnum_bit-1):0] out_r[0:(sample_size-1)],\n");
	fprintf(output,"output signed [(complexnum_bit-1):0] out_i[0:(sample_size-1)]);\n");
	fprintf(output,"\nlogic signed [(complexnum_bit-1):0] reg_r_in [0:(sample_size-1)];\n");
	fprintf(output,"logic signed [(complexnum_bit-1):0] reg_r_out [0:(sample_size-1)];\n");
	fprintf(output,"logic signed [(complexnum_bit-1):0] reg_i_in [0:(sample_size-1)];\n");
	fprintf(output,"logic signed [(complexnum_bit-1):0] reg_i_out [0:(sample_size-1)];\n");
	fprintf(output,"logic LD [0:(sample_size-1)];\n");

	fprintf(output,"\n/****************************************Storage registers****************************************/\n");
	fprintf(output,"int j, k;\n");
	fprintf(output,"always@(posedge clk or posedge rst)\n");
	fprintf(output,"begin\n");
	fprintf(output,"\tif(rst)\n\tbegin\n");
	fprintf(output,"\t\tfor (k = 0; k < sample_size; k = k + 1) \n");
	fprintf(output,"\t\tbegin\n");
	fprintf(output,"\t\t\treg_r_out[k] <= 'd0;\treg_i_out[k] <= 'd0;\n");
	fprintf(output,"\t\tend\n");
	fprintf(output,"\tend\n\telse\n\tbegin\n");
	fprintf(output,"\t\tfor (k = 0; k < sample_size; k = k + 1) \n");
	fprintf(output,"\t\tbegin\n");
	fprintf(output,"\t\t\tif (LD[k])\t//Control signals from CU\n");
	fprintf(output,"\t\t\tbegin\n\t\t\t\treg_r_out[k] <= reg_r_in[k];\treg_i_out[k] <= reg_i_in[k];\n");
	fprintf(output,"\t\t\tend\n\t\tend\n\tend\nend\n");

	fprintf(output,"\n/***********************************************ALU***********************************************/\n");
	fprintf(output,"//first half ADD_MULTIPLY; second half SUBTRACT_MULTIPLY\n");
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_r_in1 [0:(sample_size-1)];\tlogic signed [(complexnum_bit-1):0] alu_r_in2 [0:(sample_size-1)];\n");
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_r_out [0:(sample_size-1)];\n");
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_i_in1 [0:(sample_size-1)];\tlogic signed [(complexnum_bit-1):0] alu_i_in2 [0:(sample_size-1)];\n");
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_i_out [0:(sample_size-1)];\n");
	fprintf(output,"\ngenvar i;\ngenerate\n");
	fprintf(output,"for (i=0; i<(sample_size/2); i=i+1)\n");
	fprintf(output,"begin: alu1\n");
	fprintf(output,"\t//Real: Add & Multiply\n");
	fprintf(output,"\talu_add alu_add_r (.in1(alu_r_in1[i]), .in2(alu_r_in2[i]), .in3(mul_h), .out(alu_r_out[i]));\n");
	fprintf(output,"\tdefparam alu_add_r.sample_size = sample_size;\tdefparam alu_add_r.complexnum_bit = complexnum_bit; defparam alu_add_r.fp_bit = fp_bit;\n");
	fprintf(output,"\t//Real: Subtract & Multiply\n");
	fprintf(output,"\talu_sub alu_sub_r (.in1(alu_r_in1[i+(sample_size/2)]), .in2(alu_r_in2[i+(sample_size/2)]), .in3(mul_h), .out(alu_r_out[i+(sample_size/2)]));\n");
	fprintf(output,"\tdefparam alu_sub_r.sample_size = sample_size;	defparam alu_sub_r.complexnum_bit = complexnum_bit; defparam alu_sub_r.fp_bit = fp_bit;\n");
	fprintf(output,"\t//Imaginary: Add & Multiply\n");
	fprintf(output,"\talu_add alu_add_i (.in1(alu_i_in1[i]), .in2(alu_i_in2[i]), .in3(mul_h), .out(alu_i_out[i]));\n");
	fprintf(output,"\tdefparam alu_add_i.sample_size = sample_size;\tdefparam alu_add_i.complexnum_bit = complexnum_bit; defparam alu_add_i.fp_bit = fp_bit;\n");
	fprintf(output,"\t//Imaginary: Subtract & Multiply\n");
	fprintf(output,"\talu_sub alu_sub_i (.in1(alu_i_in1[i+(sample_size/2)]), .in2(alu_i_in2[i+(sample_size/2)]), .in3(mul_h), .out(alu_i_out[i+(sample_size/2)]));\n");
	fprintf(output,"\tdefparam alu_sub_i.sample_size = sample_size;	defparam alu_sub_i.complexnum_bit = complexnum_bit; defparam alu_sub_i.fp_bit = fp_bit;\n");
	fprintf(output,"end: alu1\n");
	fprintf(output,"endgenerate\n");

	unsigned int num_complex_mul = (QUBIT>2)? pow(2, (QUBIT-2)) : 0;
if(num_complex_mul!=0)
{
	fprintf(output,"\n//ALU for complex number multiplication: Rotation gates R3, R4, etc\n");
	fprintf(output,"//QFT2 doesn't require complex mul alu since R2 gate only performs mul with i\n");
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_in_real [0:%u];\n",num_complex_mul-1);
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_in_imag [0:%u];\n",num_complex_mul-1);
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_const_real [0:%u];\n",num_complex_mul-1);
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_const_imag [0:%u];\n",num_complex_mul-1);
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_out_real [0:%u];\n",num_complex_mul-1);
	fprintf(output,"logic signed [(complexnum_bit-1):0] alu_out_imag [0:%u];\n",num_complex_mul-1);
	fprintf(output,"\ngenvar l;\n");
	fprintf(output,"generate\n");
	fprintf(output,"for (l=0; l<%u; l=l+1)\n",num_complex_mul);
	fprintf(output,"begin: alu2\n");
	fprintf(output,"\talu_mul_complex alu_complex (.in_real(alu_in_real[l]), .in_imag(alu_in_imag[l]), .const_real(alu_const_real[l]), .const_imag(alu_const_imag[l]), .out_real(alu_out_real[l]), .out_imag(alu_out_imag[l]));\n");
	fprintf(output,"\tdefparam alu_complex.sample_size = sample_size;	defparam alu_complex.complexnum_bit = complexnum_bit; defparam alu_complex.fp_bit = fp_bit;\n");
	fprintf(output,"end: alu2\n");
	fprintf(output,"endgenerate\n");
}
	fclose(output);
	return;
}

void print_control(ALU_CONTROL* alu, ALU_COMP_CONTROL* alu_comp, REG_CONTROL* reg, FSM_CONTROL* fsm, COMPLEX_MATRIX* U, unsigned int sample_size, unsigned int num_unitary, unsigned int num_alu_comp)
{
	unsigned short i,j;
	FILE *output;
	output=fopen("./qft_emulate.sv","a");

	fprintf(output,"\n/*******************************************Multiplexing*******************************************/\n");
	fprintf(output,"//Select inputs for ALUs\n");

	//ALU: Add Multiply
	unsigned short bit;
	for(i=0; i<(sample_size/2); i++)
	{
		fprintf(output,"\n//ALU%u\n",i);
		bit = calc_num_control_bit(alu[i].count1);
		if(alu[i].count1==1)
		{
			fprintf(output,"assign alu_r_in1[%u] = reg_r_out[%u];", i, alu[i].index1[0]);
			fprintf(output,"\tassign alu_i_in1[%u] = reg_i_out[%u];\n", i, alu[i].index1[0]);
		}
		else if(alu[i].count1>1)
		{
			if(alu[i].count1==2)
				fprintf(output,"logic sel_alu%u_1;\n", i);
			else
				fprintf(output,"logic [%u:0] sel_alu%u_1;\n", bit-1, i);
	
			fprintf(output,"always_comb\n");
			fprintf(output,"begin\n");
			fprintf(output,"case (sel_alu%u_1)\n",i);
			for(j=0;j<alu[i].count1;j++)
				fprintf(output,"\t%u:\t\tbegin\talu_r_in1[%u] <= reg_r_out[%u]; alu_i_in1[%u] <= reg_i_out[%u];\tend\n",j,i,alu[i].index1[j], i,alu[i].index1[j]);	
			fprintf(output,"\tdefault:\tbegin\talu_r_in1[%u] <= 'd0; alu_i_in1[%u] <= 'd0;\tend\n", i, i);
			fprintf(output,"endcase\n");
			fprintf(output,"end\n");
		}
		else
			printf("ERROR: No input to ALU_IN1\n");

		bit = calc_num_control_bit(alu[i].count2);
		if(alu[i].count2==1)
		{
			fprintf(output,"assign alu_r_in2[%u] = reg_r_out[%u];", i, alu[i].index2[0]);
			fprintf(output,"\tassign alu_i_in2[%u] = reg_i_out[%u];\n", i, alu[i].index2[0]);
		}
		else if(alu[i].count2>1)
		{
			if(alu[i].count2==2)
				fprintf(output,"logic sel_alu%u_2;\n", i);
			else
				fprintf(output,"logic [%u:0] sel_alu%u_2;\n", bit-1, i);
	
			fprintf(output,"always_comb\n");
			fprintf(output,"begin\n");
			fprintf(output,"case (sel_alu%u_2)\n",i);
			for(j=0;j<alu[i].count2;j++)
				fprintf(output,"\t%u:\t\tbegin\talu_r_in2[%u] <= reg_r_out[%u]; alu_i_in2[%u] <= reg_i_out[%u];\tend\n",j,i,alu[i].index2[j], i,alu[i].index2[j]);	
			fprintf(output,"\tdefault:\tbegin\talu_r_in2[%u] <= 'd0; alu_i_in2[%u] <= 'd0;\tend\n", i, i);
			fprintf(output,"endcase\n");
			fprintf(output,"end\n");
		}
		else
			printf("ERROR: No input to ALU_IN2\n");
	} 

	//ALU: Sub Multiply
	for(i=0; i<(sample_size/2); i++)
	{
		fprintf(output,"\n//ALU%u\n",i+sample_size/2);
		fprintf(output,"assign alu_r_in1[%u] = alu_r_in1[%u];\tassign alu_i_in1[%u] = alu_i_in1[%u];\n", i+(sample_size/2),i,i+(sample_size/2),i); 
		fprintf(output,"assign alu_r_in2[%u] = alu_r_in2[%u];\tassign alu_i_in2[%u] = alu_i_in2[%u];\n", i+(sample_size/2),i,i+(sample_size/2),i);
	}
	
	
//For 2-qubit and less no alu_comp is required
if(num_alu_comp!=0)
{	
	//ALU: Complex Multiply
	for(i=0; i<num_alu_comp; i++)
	{
		fprintf(output,"\n//ALU_COMP%u\n",i);

		bit = calc_num_control_bit(alu_comp[i].count);
		if(alu_comp[i].count==1)
		{
			fprintf(output,"assign alu_in_real[%u] = reg_r_out[%u];", i, alu_comp[i].index[0]);
			fprintf(output,"\tassign alu_in_imag[%u] = reg_i_out[%u];\n", i, alu_comp[i].index[0]);	
		}
		else if(alu_comp[i].count>1)
		{
			if(alu_comp[i].count==2)
				fprintf(output,"logic sel_alu_comp%u;\n", i);
			else
				fprintf(output,"logic [%u:0] sel_alu_comp%u;\n", bit-1, i);
	
			fprintf(output,"always_comb\n");
			fprintf(output,"begin\n");
			fprintf(output,"case (sel_alu_comp%u)\n",i);
			for(j=0;j<alu_comp[i].count;j++)
				fprintf(output,"\t%u:\t\tbegin\talu_in_real[%u] <= reg_r_out[%u]; alu_in_imag[%u] <= reg_i_out[%u];\tend\n",j,i,alu_comp[i].index[j], i,alu_comp[i].index[j]);	
			fprintf(output,"\tdefault:\tbegin\talu_in_real[%u] <= 'd0; alu_in_imag[%u] <= 'd0;\tend\n", i, i);
			fprintf(output,"endcase\n");
			fprintf(output,"end\n");
		}
		else
			printf("ERROR: No input to ALU_COMP\n");	
	}

	//For complex constant number selection
	fprintf(output,"\n//ALU_COMP_CONST\n");
	bit = calc_num_control_bit(alu_comp[0].const_count);
	if(alu_comp[0].const_count==1)
	{
		fprintf(output,"assign alu_const_real[0] = 24'h%x;", alu_comp[0].const_real[0]);
		fprintf(output,"\tassign alu_const_imag[0] = 24'h%x;\n", alu_comp[0].const_imag[0]); 	
	}
	else if(alu_comp[0].const_count>1)
	{
		if(alu_comp[0].const_count==2)
			fprintf(output,"logic sel_alu_const;\n");
		else
			fprintf(output,"logic [%u:0] sel_alu_const;\n", bit-1);
		fprintf(output,"always_comb\n");
		fprintf(output,"begin\n");
		fprintf(output,"case (sel_alu_const)\n");
		for(j=0;j<alu_comp[0].const_count;j++)
			fprintf(output,"\t%u:\t\tbegin\talu_const_real[0] <= 24'h%x; alu_const_imag[0] <= 24'h%x;\tend\n",j,alu_comp[0].const_real[j], alu_comp[0].const_imag[j]);	
		fprintf(output,"\tdefault:\tbegin\talu_const_real[0] <= 'd0; alu_const_imag[0] <= 'd0;\tend\n");
		fprintf(output,"endcase\n");
		fprintf(output,"end\n");
	}
	else
		printf("ERROR: No input to ALU_CONST\n");
	for(i=1; i<num_alu_comp; i++)
	{
		fprintf(output,"assign alu_const_real[%u] = alu_const_real[0];\t",i);
		fprintf(output,"assign alu_const_imag[%u] = alu_const_imag[0];\n",i);
	}
}
	//Registers
	fprintf(output,"\n//Select inputs for REGs\n");
	for(i=0; i<sample_size; i++)
	{
		fprintf(output,"\n//REG%u\n",i);
		bit = calc_num_control_bit(reg[i].count);
		if(reg[i].count==1)
		{
			fprintf(output,"assign reg_r_in[%u] = ",i);
			if(reg[i].type[0] == 0)
				fprintf(output,"in_r");
			else if(reg[i].type[0] == 1)
				fprintf(output,"alu_r_out");
			else if(reg[i].type[0] == 2)
				fprintf(output,"reg_r_out");
			else if(reg[i].type[0] == 3)
				fprintf(output,"-reg_i_out");
			else
				fprintf(output,"alu_out_real");
			fprintf(output,"[%u];", reg[i].index[0]);

			fprintf(output,"assign reg_i_in[%u] = ",i);
			if(reg[i].type[0] == 0)
				fprintf(output,"in_i");
			else if(reg[i].type[0] == 1)
				fprintf(output,"alu_i_out");
			else if(reg[i].type[0] == 2)
				fprintf(output,"reg_i_out");
			else if(reg[i].type[0] == 3)
				fprintf(output,"reg_r_out");
			else
				fprintf(output,"alu_out_imag");
			fprintf(output,"[%u];\n", reg[i].index[0]);	
		}
		else if(reg[i].count>1)
		{
			if(reg[i].count==2)
				fprintf(output,"logic sel_reg%u;\n", i);
			else
				fprintf(output,"logic [%u:0] sel_reg%u;\n", bit-1, i);

			fprintf(output,"always_comb\n");
			fprintf(output,"begin\n");
			fprintf(output,"case (sel_reg%u)\n",i);

			for(j=0;j<reg[i].count;j++)
			{
				fprintf(output,"\t%u:\t\tbegin\treg_r_in[%u] <= ",j ,i);
				if(reg[i].type[j] == 0)
					fprintf(output,"in_r");
				else if(reg[i].type[j] == 1)
					fprintf(output,"alu_r_out");
				else if(reg[i].type[j] == 2)
					fprintf(output,"reg_r_out");
				else if(reg[i].type[j] == 3)
					fprintf(output,"-reg_i_out");
				else
					fprintf(output,"alu_out_real");
				fprintf(output,"[%u]; \t", reg[i].index[j]);

				fprintf(output,"reg_i_in[%u] <= ",i);
				if(reg[i].type[j] == 0)
					fprintf(output,"in_i");
				else if(reg[i].type[j] == 1)
					fprintf(output,"alu_i_out");
				else if(reg[i].type[j] == 2)
					fprintf(output,"reg_i_out");
				else if(reg[i].type[j] == 3)
					fprintf(output,"reg_r_out");
				else
					fprintf(output,"alu_out_imag");
				fprintf(output,"[%u];\tend\n", reg[i].index[j]);
			}
			fprintf(output,"\tdefault:\tbegin\treg_r_in[%u] <= 'd0; reg_i_in[%u] <= 'd0;\tend\n", i, i);
			fprintf(output,"endcase\n");
			fprintf(output,"end\n");

		}
		else
		printf("ERROR: No input to REG\n");
	}

	fprintf(output,"\n//CU FSM: Split always block\n");

	bit = calc_num_control_bit(num_unitary+1+1);	//add one additional state for no operation state after computation

	fprintf(output,"reg [%u:0] state, next_state;\n", bit-1);

	fprintf(output,"//For change of state\n");
	fprintf(output,"always@ (posedge clk or posedge rst)\n");
	fprintf(output,"begin\n");
	fprintf(output,"\tif(rst)begin\n");
	fprintf(output,"\t\tstate <= 0;\n");
	fprintf(output,"\tend\n");
	fprintf(output,"\telse begin\n");
	fprintf(output,"\t\tstate <= next_state;\n");
	fprintf(output,"\tend\n");
	fprintf(output,"end\n");

	fprintf(output,"\nalways_comb\n");
	fprintf(output,"begin\n");
	fprintf(output,"\tcase(state)\n");
	for(i=0;i<(num_unitary+1);i++)
	{
		fprintf(output,"\t%u: begin\n",i);
		fprintf(output,"\t\tnext_state<=%u;\n",i+1);
		fprintf(output,"\t\t//Registers\n");
		for(j=0;j<sample_size;j++)
		{
			if(reg[j].count > 1)
				fprintf(output,"\t\tsel_reg%u<='d%u;", j, fsm[i].reg_mux[j]);
			fprintf(output,"\t\tLD[%u]<='d%u;\n", j, fsm[i].reg_ld[j]);
		}
//		fprintf(output,"\n");
		fprintf(output,"\t\t//ALUs\n");
		for(j=0;j<(sample_size/2);j++)
		{
			if(alu[j].count1 > 1)
				fprintf(output,"\t\tsel_alu%u_1<='d%u;\n", j, fsm[i].alu_mux1[j]);
			if(alu[j].count2 > 1)
				fprintf(output,"\t\tsel_alu%u_2<='d%u;\n", j, fsm[i].alu_mux2[j]);
		}
//		fprintf(output,"\n");
if(num_alu_comp!=0)
{
		fprintf(output,"\t\t//ALU_COMPs\n");
		if(alu_comp[0].const_count > 1)
			fprintf(output,"\t\tsel_alu_const<='d%u;\n", fsm[i].alu_comp_const_mux[0]); //can be shared, since same constant to be used
		for(j=0;j<num_alu_comp;j++)
		{
			if(alu_comp[j].count > 1)
				fprintf(output,"\t\tsel_alu_comp%u<='d%u;\n", j, fsm[i].alu_comp_mux[j]);
		}
}
//		fprintf(output,"\n");
		fprintf(output,"\tend\n");
	}
	//Default state
	fprintf(output,"\tdefault: begin\n");
	fprintf(output,"\t\tnext_state<=%u;\n",i);
	fprintf(output,"\t\t//Registers\n");
	for(j=0;j<sample_size;j++)
	{
		if(reg[j].count > 1)
			fprintf(output,"\t\tsel_reg%u<='d0;", j);
		fprintf(output,"\t\tLD[%u]<='d0;\n", j);
	}
//	fprintf(output,"\n");
	fprintf(output,"\t\t//ALUs\n");
	for(j=0;j<(sample_size/2);j++)
	{
		if(alu[j].count1 > 1)
			fprintf(output,"\t\tsel_alu%u_1<='d0;\n", j);
		if(alu[j].count2 > 1)
			fprintf(output,"\t\tsel_alu%u_2<='d0;\n", j);
	}
//	fprintf(output,"\n");
if(num_alu_comp!=0)
{
	fprintf(output,"\t\t//ALU_COMPs\n");
	if(alu_comp[0].const_count > 1)
		fprintf(output,"\t\tsel_alu_const<='d0;\n"); //can be shared, since same constant to be used
	for(j=0;j<num_alu_comp;j++)
	{
		if(alu_comp[j].count > 1)
			fprintf(output,"\t\tsel_alu_comp%u<='d0;\n", j);
	}
}
//	fprintf(output,"\n");
	fprintf(output,"\tend\n");
	fprintf(output,"\tendcase\n");
	fprintf(output,"end\n");
	
	fprintf(output,"\n//Output\n");
	fprintf(output,"assign out_r = reg_r_out;\tassign out_i = reg_i_out;\n");
	fprintf(output,"endmodule\n");

	fclose(output);		

}

void print_out (unsigned int sample_size, unsigned int U_index, ALU_CONTROL* alu, ALU_COMP_CONTROL* alu_comp, REG_CONTROL* reg, FSM_CONTROL* fsm, unsigned int num_alu_comp)
{
	unsigned int i,j;
	
	printf("\t--Print Out--\n");
	printf("--REG--\n");
	for(i=0;i<sample_size;i++)
	{
		printf("REG%u:\t",i);
		for(j=0;j<reg[i].count;j++)
		{
			//0: external input; 1: ALU output; 2: REG output; 3: NEG output (out_r=-in_i, out_i=in_r);  4: ALU_COMP output;
			if(reg[i].type[j]==0)
				printf("in");
			else if (reg[i].type[j]==1)
				printf("OUT");
			else if (reg[i].type[j]==2)
				printf("IN");
			else if (reg[i].type[j]==3)
				printf("NEG");	
			else
				printf("OUT_C");
			printf("%u\t", reg[i].index[j]);
		}
		printf("\n");
	}
	printf("\n--ALU--\n");
	for(i=0;i<(sample_size/2);i++)
	{
		printf("-ALU%u-\n",i);
		printf("Index1: ");
		for(j=0;j<alu[i].count1;j++)
			printf("IN%u\t", alu[i].index1[j]);
		printf("\n");
		printf("Index2: ");
		for(j=0;j<alu[i].count2;j++)
			printf("IN%u\t", alu[i].index2[j]);
		printf("\n");
	}

	printf("\n--ALU_COMP--\n");	//DOUBLE CHECK THIS!
	for(i=0;i<num_alu_comp;i++)
	{
		printf("-ALU_COMP%u-\n",i);
		printf("Index:\t\t");
		for(j=0;j<alu_comp[i].count;j++)
			printf("IN%u\t", alu_comp[i].index[j]);
		printf("\n");
		printf("CONST_REAL:\t");
		for(j=0;j<alu_comp[i].const_count;j++)
			printf("%x\t", alu_comp[i].const_real[j]);
		printf("\n");
		printf("CONST_IMAG:\t");
		for(j=0;j<alu_comp[i].const_count;j++)
			printf("%x\t", alu_comp[i].const_imag[j]);
		printf("\n");
	}

	printf("\n--FSM--");
	for(i=0;i<=U_index;i++)
	{
		printf("\n-State%u-\n", i);
		printf("REG_MUX:\t");
		for(j=0;j<sample_size;j++)
			printf("%u\t",fsm[i].reg_mux[j]);	
		printf("\n");
		printf("REG_LD:\t\t");
		for(j=0;j<sample_size;j++)
			printf("%u\t",fsm[i].reg_ld[j]);	
		printf("\n");
		printf("ALU_MUX1:\t");
		for(j=0;j<(sample_size/2);j++)
			printf("%u\t",fsm[i].alu_mux1[j]);	
		printf("\n");
		printf("ALU_MUX2:\t");
		for(j=0;j<(sample_size/2);j++)
			printf("%u\t",fsm[i].alu_mux2[j]);	
		printf("\n");
		printf("ALU_COMP_MUX:\t");
		for(j=0;j<num_alu_comp;j++)
			printf("%u\t",fsm[i].alu_comp_mux[j]);	
		printf("\n");
		printf("ALU_COMP_C_MUX:\t");
		for(j=0;j<num_alu_comp;j++)
			printf("%u\t",fsm[i].alu_comp_const_mux[j]);	
		printf("\n");
	}
	return;
}

void generate_qft_control (ALU_CONTROL* alu, ALU_COMP_CONTROL* alu_comp, REG_CONTROL* reg, FSM_CONTROL* fsm, COMPLEX_MATRIX* U, unsigned int sample_size, unsigned int num_unitary)
{
	unsigned short track, track_comp, track_add, track_sub, track_index1;
	unsigned int fixed_real, fixed_imag, U_index, i, j;
	int exist;

//QFT unitary transformations	
for(U_index=1; U_index<=num_unitary; U_index++)
{
	printf("-Generate U%u control-\n", U_index);
	track_add=0; track_sub=0; track_comp=0;
	for(i=0;i<U[U_index-1].rows;i++)
	{
		track = 0;
		for(j=0;j<U[U_index-1].cols;j++)
		{
			//Case 1: Use Hadamard ALU, mul_h is preset
			if(U[U_index-1].t[i*U[U_index-1].cols+j].r!=0 && U[U_index-1].t[i*U[U_index-1].cols+j].r!=1 && U[U_index-1].t[i*U[U_index-1].cols+j].i==0)			
			{
				if(U[U_index-1].t[i*U[U_index-1].cols + j].r > 0)
				{
					if(track==0)	//first element of ALU
					{
						track_index1 = j;
						track++;
					}
					else		//second element of ALU (ADD_MUL type)
					{
						//For first index
						exist = check_if_exist (alu[track_add].index1, alu[track_add].count1, track_index1);
						//if exist in alu_mux
						if(exist>=0)
						{
//							printf("ADD1: Exist\n");
							fsm[U_index].alu_mux1[track_add] = exist;
						}
						else
						{
//							printf("ADD1: NEW\n");
							//if new for alu_mux
							alu[track_add].index1[alu[track_add].count1] = track_index1;
							fsm[U_index].alu_mux1[track_add] = alu[track_add].count1;
							alu[track_add].count1++;
						}
						//For second index
						exist = check_if_exist (alu[track_add].index2, alu[track_add].count2, j);
						//if exist in alu_mux
						if(exist>=0)
						{
//							printf("ADD2: Exist\n");
							fsm[U_index].alu_mux2[track_add] = exist;
						}
						else
						{
//							printf("ADD2: NEW\n");
							//if new for alu_mux
							alu[track_add].index2[alu[track_add].count2] = j;
							fsm[U_index].alu_mux2[track_add] = alu[track_add].count2;
							alu[track_add].count2++;
						}
						//Add register detail
						exist = check_if_reg_exist (reg[i].index, reg[i].type, reg[i].count, track_add, 1);
						if(exist>=0)
						{
//							printf("REG_INPUT: Exist\n");
							fsm[U_index].reg_mux[i] = exist;
						}
						else
						{
//							printf("REG_INPUT NEW\n");
							//if new for alu_mux
							reg[i].index[reg[i].count] = track_add;	
							reg[i].type[reg[i].count] = 1;
							fsm[U_index].reg_mux[i] = reg[i].count;
							reg[i].count++;
						}
						fsm[U_index].reg_ld[i] = 1;						
						track_add++;
					}				
				}
				else	//SUB_MUL type: second element of ALU
				{
					//For first index
					exist = check_if_exist (alu[track_sub].index1, alu[track_sub].count1, track_index1);
					//if exist in alu_mux
					if(exist>=0)
					{
//						printf("SUB1: Exist\n");
						fsm[U_index].alu_mux1[track_sub] = exist;
					}
					else
					{
						//if new for alu_mux: SHOULD NOT HAPPEN
//						printf("SUB1: NEW - ERROR!\n");
					}
					//For second index						
					exist = check_if_exist (alu[track_sub].index2, alu[track_sub].count2, j);
					//if exist in alu_mux
					if(exist>=0)
					{
//						printf("SUB2: Exist\n");
						fsm[U_index].alu_mux2[track_sub] = exist;
					}
					else
					{
						//if new for alu_mux: SHOULD NOT HAPPEN
//						printf("SUB2: NEW - ERROR\n");
					}
					//Add register detail
					exist = check_if_reg_exist (reg[i].index, reg[i].type, reg[i].count, track_sub+(sample_size/2), 1);
					if(exist>=0)
					{
//						printf("REG_INPUT: Exist\n");
						fsm[U_index].reg_mux[i] = exist;
					}
					else
					{
//						printf("REG_INPUT NEW\n");
						//if new for alu_mux
						reg[i].index[reg[i].count] = track_sub + (sample_size/2);
						reg[i].type[reg[i].count] = 1;
						fsm[U_index].reg_mux[i] = reg[i].count;
						reg[i].count++;
					}
					fsm[U_index].reg_ld[i] = 1;
					track_sub++;
				}
			}
			//Case 2: R2 Gate using NEG operation
			else if (round(U[U_index-1].t[i*U[U_index-1].cols+j].r)==0 && U[U_index-1].t[i*U[U_index-1].cols+j].i==1)
//			else if (U[U_index-1].t[i*U[U_index-1].cols+j].i==1)
			{
				exist = check_if_reg_exist (reg[i].index, reg[i].type, reg[i].count, i, 3);
				if(exist>=0)
				{fsm[U_index].reg_mux[i] = exist;}
				else
				{
					//if new for alu_mux
					reg[i].index[reg[i].count] = i;
					reg[i].type[reg[i].count] = 3;
					fsm[U_index].reg_mux[i] = reg[i].count;
					reg[i].count++;
				}
				fsm[U_index].reg_ld[i] = 1;
			}
			//Case 3: Rn Gate using complex multiplication
			else if (U[U_index-1].t[i*U[U_index-1].cols+j].r!=0 && U[U_index-1].t[i*U[U_index-1].cols+j].i!=0)
			{
				//Input for ALU_COMP
				exist = check_if_exist (alu_comp[track_comp].index, alu_comp[track_comp].count, i);
				if(exist>=0)
					fsm[U_index].alu_comp_mux[track_comp] = exist;	
				else
				{
					alu_comp[track_comp].index[alu_comp[track_comp].count] = i;
					fsm[U_index].alu_comp_mux[track_comp] = alu_comp[track_comp].count;
					alu_comp[track_comp].count++;
				}
				fixed_real = float2fix (U[U_index-1].t[i*U[U_index-1].cols+j].r);
				fixed_imag = float2fix (U[U_index-1].t[i*U[U_index-1].cols+j].i);
				//Complex number constant for ALU_COMP
				exist = check_if_const_exist (alu_comp[track_comp].const_real, alu_comp[track_comp].const_imag, alu_comp[track_comp].const_count, fixed_real, fixed_imag);
				if(exist>=0)
					fsm[U_index].alu_comp_const_mux[track_comp] = exist;
				else
				{
					alu_comp[track_comp].const_real[alu_comp[track_comp].const_count] = fixed_real;
					alu_comp[track_comp].const_imag[alu_comp[track_comp].const_count] = fixed_imag;

					fsm[U_index].alu_comp_const_mux[track_comp] = alu_comp[track_comp].const_count;
					alu_comp[track_comp].const_count++;
				}
				//Add register detail
				exist = check_if_reg_exist (reg[i].index, reg[i].type, reg[i].count, track_comp, 4);
				if(exist>=0)
				{fsm[U_index].reg_mux[i] = exist;}
				else
				{
					//if new for alu_mux
					reg[i].index[reg[i].count] = track_comp;
					reg[i].type[reg[i].count] = 4;
					fsm[U_index].reg_mux[i] = reg[i].count;
					reg[i].count++;
				}
				fsm[U_index].reg_ld[i] = 1;
				track_comp++;
			}
			//Case 4: SWAP output
			else if (U[U_index-1].t[i*U[U_index-1].cols+j].r==1 && round(U[U_index-1].t[i*U[U_index-1].cols+j].i)==0 && i!=j)
			{
				reg[i].index[reg[i].count] = j;
				reg[i].type[reg[i].count] = 2;
				fsm[U_index].reg_mux[i] = reg[i].count;
				reg[i].count++;
				fsm[U_index].reg_ld[i] = 1;
			}
			else
			{}	
		}
	}
}	

}

void print_CUDU (unsigned int QUBIT, COMPLEX_MATRIX* U, unsigned int num_unitary)
{
	unsigned int sample_size = pow(2, QUBIT);	
	
	printf("\t--Generate SystemVerilog Code--\n");
	print_header (QUBIT, sample_size);

	/*******************************************Generate Control Code*******************************************/
	//Based on QFT unitary transformation characteristics specifically

	/////////////////////////////////////////////INITIALIZATION/////////////////////////////////////////////////
	//For unitary with one Hadamard gate (1 addition operation only), same number as the number of QUBIT
	unsigned short i,j;
	ALU_CONTROL* alu = (ALU_CONTROL*) malloc ((sample_size/2) * sizeof(ALU_CONTROL)); if(alu==NULL){printf("--Error!: Malloc ALU control struct.--\n");return;}
	for(i=0;i<(sample_size/2);i++)
	{
		alu[i].index1 = (unsigned short*) malloc (QUBIT * sizeof(unsigned short)); if(alu[i].index1==NULL){printf("--Error!: Malloc ALU control index.--\n");return;}
		alu[i].index2 = (unsigned short*) malloc (QUBIT * sizeof(unsigned short)); if(alu[i].index2==NULL){printf("--Error!: Malloc ALU control index.--\n");return;}	
		alu[i].count1 = 0;
		alu[i].count2 = 0;
	}
	//For unitary with controlled-rotation gate (complex number multiplication)
	unsigned int num_alu_comp = (QUBIT>2)? pow(2, (QUBIT-2)) : 0;
	ALU_COMP_CONTROL* alu_comp; 
if(num_alu_comp!=0)	
{
	alu_comp = (ALU_COMP_CONTROL*) malloc (num_alu_comp * sizeof(ALU_COMP_CONTROL)); if(alu_comp==NULL){printf("--Error!: Malloc ALU comp control struct.--\n");return;}
	for(i=0;i<num_alu_comp;i++)
	{
		alu_comp[i].index = (unsigned short*) malloc (num_unitary * sizeof(unsigned short)); if(alu_comp[i].index==NULL){printf("--Error!: Malloc ALU control index.--\n");return;}
		alu_comp[i].const_real = (int*) malloc (num_unitary * sizeof(int)); if(alu_comp[i].const_real==NULL){printf("--Error!: Malloc ALU control const_real.--\n");return;}	
		alu_comp[i].const_imag = (int*) malloc (num_unitary * sizeof(int)); if(alu_comp[i].const_imag==NULL){printf("--Error!: Malloc ALU control const_imag.--\n");return;}	
		alu_comp[i].count = 0; alu_comp[i].const_count = 0;
	}
}

	
	//For shared registers in serial architecture
	REG_CONTROL* reg = (REG_CONTROL*) malloc (sample_size * sizeof(REG_CONTROL)); if(reg==NULL){printf("--Error!: Malloc REG control struct.--\n");return;}
	for(i=0;i<sample_size;i++)
	{
		reg[i].index = (unsigned short*) malloc ((num_unitary+1) * sizeof(unsigned short)); if(reg[i].index==NULL){printf("--Error!: Malloc REG control index.--\n");return;}
		reg[i].type = (unsigned short*) malloc ((num_unitary+1) * sizeof(unsigned short)); if(reg[i].type==NULL){printf("--Error!: Malloc REG control type.--\n");return;}	
		reg[i].count = 0;
	}
	//For FSM control of each unitary transformation state
	//num_state = num_unitary + 1 (initial state to load external output)
	FSM_CONTROL* fsm = (FSM_CONTROL*) malloc ((num_unitary+1) * sizeof(FSM_CONTROL)); if(fsm==NULL){printf("--Error!: Malloc FSM control struct.--\n");return;}
	for(i=0;i<(num_unitary+1);i++)
	{
		//Approximately allocate QUBIT*2 as max number of mux control bit
		fsm[i].reg_mux = (unsigned short*) malloc (sample_size * sizeof(unsigned short)); if(fsm[i].reg_mux==NULL){printf("--Error!: Malloc FSM control index.--\n");return;}
		fsm[i].reg_ld = (unsigned char*) malloc (sample_size * sizeof(unsigned char)); if(fsm[i].reg_ld==NULL){printf("--Error!: Malloc FSM control reg_ld.--\n");return;}	

		fsm[i].alu_mux1 = (unsigned short*) malloc ((sample_size/2) * sizeof(unsigned short)); if(fsm[i].alu_mux1==NULL){printf("--Error!: Malloc FSM control alu_mux.--\n");return;}
		fsm[i].alu_mux2 = (unsigned short*) malloc ((sample_size/2) * sizeof(unsigned short)); if(fsm[i].alu_mux2==NULL){printf("--Error!: Malloc FSM control alu_mux.--\n");return;}
		fsm[i].alu_comp_mux = (unsigned short*) malloc (num_alu_comp * sizeof(unsigned short)); if(fsm[i].alu_comp_mux==NULL){printf("--Error!: Malloc FSM control alu_comp_mux.--\n");return;}
		fsm[i].alu_comp_const_mux = (unsigned short*) malloc (num_alu_comp * sizeof(unsigned short)); if(fsm[i].alu_comp_mux==NULL){printf("--Error!: Malloc FSM control alu_comp_mux.--\n");return;}	
	}	
	
	/////////////////////////////////////////////UNITARY TRANSFORMATION/////////////////////////////////////////////////
	//0: external input; 1: ALU output; 2: REG output; 3: NEG output; 4: ALU_COMP output;
	//U0: Load external inputs
	unsigned int U_index = 0;
	printf("-Generate U%u control-\n", U_index);
	for(i=0;i<sample_size;i++)
	{
		reg[i].index[reg[i].count] = i;
		reg[i].type[reg[i].count] = 0;
		fsm[U_index].reg_mux[i] = reg[i].count;
		fsm[U_index].reg_ld[i] = 1;
		//fsm[U_index].alu_mux & fsm[U_index].alu_comp_mux default set to 0
		reg[i].count++;
	}
	//Unitary transformations for QFT computation
	generate_qft_control(alu, alu_comp, reg, fsm, U, sample_size, num_unitary);	
	printf("\n");
	
	print_out (sample_size, num_unitary, alu, alu_comp, reg, fsm, num_alu_comp);
	
	//Print control code into SystemVerilog syntax
	print_control(alu, alu_comp, reg, fsm, U, sample_size, num_unitary, num_alu_comp);
	
	return;
}
