#include "config.h"

void print_gate (BASIS_CIRCUIT c)
{
	unsigned int i;

	printf("\nGate Sequence: %hu gate(s)\n", c.size);
	for (i=0; i<c.size; i++)
	{
		if (c.type[i]==0)
			printf("-H_%hu-\t",c.pos[i*2]);
		else if (c.type[i]==1)
			printf("-P_%hu-\t",c.pos[i*2]);
		else if (c.type[i]==2)
			printf("-CNOT_%hu,%hu-\t",c.pos[i*2], c.pos[i*2+1]);
		else if (c.type[i]==3)
		{
			printf("-MEASURE_%hu-\t",c.pos[i*2]);
		}
	}
	printf("\n");	

	return;
}

void apply_H (COMPLEX_MATRIX* vector, unsigned int pos, unsigned int num_qubit)
{
	unsigned int i;
	COMPLEX_MATRIX identity; identity.rows = 0; identity.cols = 0;
	create_identity_matrix (&identity, 2);
	COMPLEX_MATRIX H; H.rows = 0; H.cols = 0;
	quantum_hadamard (&H);
	COMPLEX_MATRIX U; U.rows = 0; U.cols = 0;

	printf("\nApply Hadamard Gate on Qubit %u", pos);

	if(pos==0)
		matrix_copy (H,&U);
	else
		matrix_copy (identity,&U);

	for (i=1;i<num_qubit;i++)
	{
		if(i==pos)
			tensor_product (U, H, &U);
		else
			tensor_product (U, identity, &U);
	}

	matrix_mul (U, *vector, &*vector);
	return;
}

void apply_P (COMPLEX_MATRIX* vector, unsigned int pos, unsigned int num_qubit)
{
	unsigned int i;
	COMPLEX_MATRIX identity; identity.rows = 0; identity.cols = 0;
	create_identity_matrix (&identity, 2);
	COMPLEX_MATRIX P; P.rows = 0; P.cols = 0;
	quantum_P (&P);
	COMPLEX_MATRIX U; U.rows = 0; U.cols = 0;

	printf("\nApply Phase Gate on Qubit %u", pos);

	if(pos==0)
		matrix_copy (P,&U);
	else
		matrix_copy (identity,&U);

	for (i=1;i<num_qubit;i++)
	{
		if(i==pos)
			tensor_product (U, P, &U);
		else
			tensor_product (U, identity, &U);
	}

	matrix_mul (U, *vector, &*vector);
	return;
}

void dec_to_bin (unsigned int decimal, unsigned short* binary, unsigned int num_bit)
{
	unsigned int i;
	for(i=0;i<num_bit;i++)
		binary[i] = 0;

	i=0;
	while(decimal != 0)
	{
         	binary[num_bit-1-i]= decimal % 2;
         	decimal = decimal / 2;
		i++;
    	}
}

void bin_to_dec (unsigned short* binary, unsigned int num_bit, unsigned int *decimal)
{
	unsigned int i;
	i=0;
	*decimal=0;

	for (i=0;i<num_bit;i++)
	{
		if(binary[i]==1)
			*decimal += pow(2, num_bit-1-i);
	}

	return;
}

void apply_CNOT (COMPLEX_MATRIX* vector, unsigned int pos1, unsigned int pos2, unsigned int num_qubit)
{
	unsigned int i,j;
	unsigned int total_state = pow(2,num_qubit);
	unsigned short *flag;
	flag = (unsigned short*) malloc (total_state * sizeof(unsigned short)); if (flag==NULL) {printf("--Error!: Malloc flag failed.--\n");return;}
	for (i=0;i<total_state;i++)
		flag[i]=0;
	unsigned short *binary;
	binary = (unsigned short*) malloc (num_qubit * sizeof(unsigned short)); if (binary==NULL) {printf("--Error!: Malloc binary failed.--\n");return;}
	
	printf("\nApply CNOT Gate on Control Qubit %u & Target Qubit %u", pos1,pos2);
	COMPLEX_NUM temp;
	unsigned int target_swap;
	//printf("\n");
	for(i=0;i<total_state;i++)
	{
		dec_to_bin (i,binary,num_qubit);
/*
		printf("Binary:");
		for (j=0;j<num_qubit;j++)
			printf("%hu",binary[j]);
		printf("\n");
		printf("i: %u\n",i);
*/
		if(binary[pos1] == 1 && flag[i]==0)	//Control qubit
		{
			temp.r = vector->t[i].r; temp.i = vector->t[i].i; 
			flag[i]=1;
			if(binary[pos2]==1) binary[pos2]=0; else binary[pos2]=1;
			bin_to_dec(binary,num_qubit,&target_swap);
			flag[target_swap]=1;
			vector->t[i].r = vector->t[target_swap].r; vector->t[i].i = vector->t[target_swap].i; 
			vector->t[target_swap].r = temp.r; vector->t[target_swap].i = temp.i;
			//printf("\nSWAP %u & %u\n", i, target_swap);
		}

	}
}

int main ()
{
	printf("\t\t--Stabilizer Circuit: Modelling of Arbitrary Sequence of Stabilizer Gates--\n");
	unsigned int num_qubit,i; 
	char temp_c;
	BASIS_CIRCUIT gate_sequence;

	//Read gate sequence information (defined in input txt file)
	FILE *INPUT;
	INPUT = fopen("randqc_3qubit.txt", "r");
	fscanf(INPUT, "%u", &num_qubit);
	fscanf(INPUT, "%u", &gate_sequence.size);
	printf("Number of Qubit: %u \tNumber of Gate: %u\n", num_qubit, gate_sequence.size);		

	//Memory allocation for storing gate sequence
	gate_sequence.type = (unsigned short*) malloc ((gate_sequence.size) * sizeof(unsigned short)); if(gate_sequence.type==NULL){printf("--Error!: Malloc gate sequence failed.--\n");return 1;}
	gate_sequence.pos = (unsigned short*) malloc ((gate_sequence.size*2) * sizeof(unsigned short)); if(gate_sequence.pos==NULL){printf("--Error!: Malloc gate sequence failed.--\n");return 1;}

	//Read & store gate sequence in quantum circuit
	for (i=0;i<gate_sequence.size;i++)
	{
		//To discard redudant input such as next line from file
		do
		{fscanf(INPUT, "%c", &temp_c);}while((temp_c=='\r')||(temp_c=='\n'));
		//Gate Type(s): 0 = Hadamard; 1 = Phase; 2 = CNOT; 3 = CPHASE (Controlled-Z)
		//For this case consider 3 = Measurement gate as stabilizer-based simulation support this 4 types of gates
		if ((temp_c=='h')||(temp_c=='H'))
		{
			gate_sequence.type[i] = 0;
			fscanf(INPUT, "%hu", &gate_sequence.pos[2*i]); gate_sequence.pos[2*i+1]=0;
			//printf("sequence %u: Gate H\tPosition %hu\n", i,gate_sequence.pos[2*i]);
		}
		else if ((temp_c=='p')||(temp_c=='P'))
		{
			gate_sequence.type[i] = 1;
			fscanf(INPUT, "%hu", &gate_sequence.pos[2*i]); gate_sequence.pos[2*i+1]=0;
			//printf("sequence %u: Gate P\tPosition %hu\n", i,gate_sequence.pos[2*i]);
		}
		else if ((temp_c=='c')||(temp_c=='C'))
		{
			gate_sequence.type[i] = 2;
			fscanf(INPUT, "%hu", &gate_sequence.pos[2*i]); fscanf(INPUT, "%hu", &gate_sequence.pos[2*i+1]);
			//printf("sequence %u: Gate CNOT\tPosition %hu %hu\n", i,gate_sequence.pos[2*i],gate_sequence.pos[2*i+1]);
		}
		else if ((temp_c=='m')||(temp_c=='M'))
		{
			gate_sequence.type[i] = 3;
			fscanf(INPUT, "%hu", &gate_sequence.pos[2*i]); gate_sequence.pos[2*i+1]=0;
			//printf("sequence %u: Gate M\tPosition %hu\n", i,gate_sequence.pos[2*i]);
		}	 
	}
	fclose(INPUT);
	print_gate(gate_sequence);

	//Initialize state vector with |0...0> basis state
	COMPLEX_MATRIX vector;
	unsigned int total_state = pow(2,num_qubit);
	vector.rows = pow(2,num_qubit); vector.cols = 1;
	vector.t =(COMPLEX_NUM*) malloc ((vector.rows) * sizeof(COMPLEX_NUM)); if(vector.t==NULL){printf("--Error!: Malloc state vector failed.--\n");return 1;}
	for (i=0;i<vector.rows;i++)
	{vector.t[i].r=0;vector.t[i].i=0;}
	vector.t[0].r=1;
	//vector.t[total_state-1].r=1;
	printf("\nInitial State Vector:\n");
	matrix_print(vector);

	//State vector approach of stabilizer circuit simulation
	for (i=0;i<gate_sequence.size;i++)
	{
		if (gate_sequence.type[i]==0)		//Hadamard Gate
		{apply_H(&vector, gate_sequence.pos[2*i], num_qubit);}
		else if (gate_sequence.type[i]==1)	//Phase Gate
		{apply_P(&vector, gate_sequence.pos[2*i], num_qubit);}
		else if (gate_sequence.type[i]==2)	//CNOT Gate
		{apply_CNOT(&vector, gate_sequence.pos[2*i], gate_sequence.pos[2*i+1], num_qubit);}
		//else if (gate_sequence.type[i]==3)	//Measurement Gate: To-be constructed
		//{apply_M(&vector, gate_sequence.pos[2*i], num_qubit);}
		printf("\nIntermediate State Vector: Gate Sequence %u\n",i);
		matrix_print(vector);
	}

	
	return 0;
}


