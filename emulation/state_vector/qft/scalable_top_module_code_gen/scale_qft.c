#include "config.h"

//Parameterizable number of qubits for QFT
#define QUBIT 3 

unsigned short create_qft_matrix (COMPLEX_MATRIX *Fw)
{
	unsigned short i,j,temp, N;
	float index_exp, index_temp;
	N = pow(2, QUBIT);
	index_exp = (2*PI) / (float) N;

	//Pre-computation for fourier matrix construction
	COMPLEX_MATRIX wi;
	wi.rows = N;	wi.cols = 1;
	wi.t =(COMPLEX_NUM*) malloc ((wi.rows*wi.cols) * sizeof(COMPLEX_NUM)); if(wi.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	for (i=0; i<N; i++)
	{
		index_temp = index_exp * (i);
		wi.t[i].r = cos(index_temp);
		wi.t[i].i = sin(index_temp);	
	}
//	matrix_print(wi);
	
	//Fourier Matrix Construction
	for (i=0; i<Fw->cols; i++)
		for (j=0; j<Fw->rows; j++)
		{
			temp = i*j;	temp %= N;
			Fw->t[i*Fw->rows + j].r = wi.t[temp].r;
			Fw->t[i*Fw->rows + j].i = wi.t[temp].i;
		}
	matrix_free (&wi);
}

int main ()
{
	printf("\t~Scalable QFT~\n");
	printf("--%u-qubit QFT--\n", QUBIT);
	printf("Quantum Gates (Matrices) Initialization:\n");
	float rad_angle; unsigned int i, j, k, N, num_unitary;
	COMPLEX_MATRIX temp1; temp1.cols = 0; temp1.rows = 0;
	COMPLEX_MATRIX temp2; temp2.cols = 0; temp2.rows = 0;
	N = pow(2, QUBIT);
	
	printf("\n-Create identity matrix-\n");
	COMPLEX_MATRIX identity; identity.rows = 0; identity.cols = 0;
	create_identity_matrix (&identity, 2);
	matrix_print(identity);
	
	COMPLEX_MATRIX identity4; identity4.rows = 0; identity4.cols = 0;
	create_identity_matrix (&identity4, 4);
	
	printf("\n-Create Hadamard Gate: H-\n");
	COMPLEX_MATRIX H; H.rows = 0; H.cols = 0;
	quantum_hadamard(identity, &H);
	matrix_print(H);
	
	printf("\n-Create 2-qubit SWAP-\n");
	COMPLEX_MATRIX swap; swap.rows = 0; swap.cols = 0;
	quantum_swap(identity4, &swap);
	matrix_print(swap);
	
	printf("\n-Create Controlled Phase-Shift Gate(s):-\n");
	COMPLEX_MATRIX* R = (COMPLEX_MATRIX*) malloc ((QUBIT-1) * sizeof(COMPLEX_MATRIX)); if(R==NULL){printf("--Error!: Malloc control phase-shift failed.--\n");return 1;}	
	for (i=0;i<(QUBIT-1);i++)
	{
		printf("R%u:\n",i+2);
		R[i].rows = 0;	R[i].cols = 0;		//R[0] represent R2 phase shift gate and so on
		rad_angle = 2*PI / pow(2, i+2);
		quantum_rotation(identity4, rad_angle, &R[i]);
		matrix_print(R[i]);
		printf("\n");
	}

	//For extended rotation gate	
	if(QUBIT>2)
	{
		//iswap
		unsigned int num_iswap = QUBIT-2; 	//Temp for derivations of iswap for expanded controlled phase-shift gate 

		COMPLEX_MATRIX* iswap = (COMPLEX_MATRIX*) malloc (num_iswap * sizeof(COMPLEX_MATRIX)); if(iswap==NULL){printf("--Error!: Malloc iswap failed.--\n");return 1;}
		tensor_product (identity, swap, &iswap[0]);			//I (x) SWAP
		for (i=1;i<num_iswap;i++)
		{tensor_product (identity, iswap[i-1], &iswap[i]);} //I ((x) n) (x) SWAP

		for (i=1;i<(QUBIT-1);i++)
			for(j=0;j<i;j++)
			{
				tensor_product (R[i], identity, &R[i]);
				matrix_mul (R[i], iswap[j], &R[i]);
				matrix_mul (iswap[j], R[i], &R[i]);
			}
	}

	//Unitary Transformations
	//Compute number of unitary transformations
	num_unitary = 1;	//swap gate
	for(i=0; i<QUBIT; i++)
	{num_unitary += (i+1);}
//	printf("Number of Unitary Transformation for %u-qubit QFT: %u\n", QUBIT, num_unitary);

	COMPLEX_MATRIX* U = (COMPLEX_MATRIX*) malloc (num_unitary * sizeof(COMPLEX_MATRIX)); if(U==NULL){printf("--Error!: Malloc unitary matrices failed.--\n");return 1;}
	for (i=0;i<num_unitary;i++)
	{U[i].rows = 0; U[i].cols = 0;}
	
	unsigned int count=0;
	for (i=0;i<QUBIT;i++)
	{
		for (j=0;j<(QUBIT-i);j++)
		{
			if(j==0)
			{
				matrix_copy (H, &U[count]);
				for(k=0;k<i;k++)	
					tensor_product (identity, U[count], &U[count]);
				//ADD IDENTITY AT BOTTOM
				while(U[count].rows < N)
					tensor_product (U[count], identity, &U[count]);
				count++;
			}
			else
			{
				matrix_copy (R[j-1], &U[count]);
				for(k=0;k<i;k++)	
					tensor_product (identity, U[count], &U[count]);
				//ADD IDENTITY AT BOTTOM
				while(U[count].rows < N)
					tensor_product (U[count], identity, &U[count]);
				count++;
			}
		}
	}
	
	//Swap sequence of output as required in QFT circuit
	U[count].rows = N;	U[count].cols = N;
	U[count].t =(COMPLEX_NUM*) malloc ((U[count].rows*U[count].cols) * sizeof(COMPLEX_NUM)); if(U[count].t==NULL){printf("--Error!: Malloc multi-swap matrix failed.--\n");return 1;}
	multi_swap (&U[count], QUBIT, N);
	
	//Unitary transformation printout
	for(k=0; k<num_unitary; k++)
	{
		printf("U%u Code:\n",k+1);
		for(i=0;i<U[k].rows;i++)
		{
			printf("out[%u] : ",i);
			for(j=0;j<U[k].cols;j++)
			{
				if(U[k].t[i*U[k].cols + j].r !=0 || U[k].t[i*U[k].cols + j].i !=0)
					printf("in[%u] %f + %fi; \t",j, U[k].t[i*U[k].cols + j].r, U[k].t[i*U[k].cols + j].i);
			}
			printf("\n");
		}
		printf("\n");
	}

	//Generate SystemVerilog file	
	print_CUDU (QUBIT, U, num_unitary);

	//Free malloc
	matrix_free (&identity); matrix_free (&identity4); matrix_free (&H); matrix_free (&swap); 
	for (i=0;i<(QUBIT-1);i++)
		matrix_free(&R[i]);
	free(R);
	
	return 0;
}
