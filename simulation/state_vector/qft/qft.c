#include "config.h"
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
	wi.t =(COMPLEX_NUM*) malloc ((wi.rows*wi.cols) * sizeof(COMPLEX_NUM)); 
	if(wi.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	for (i=0; i<N; i++)
	{
		index_temp = index_exp * (i);
		wi.t[i].r = cos(index_temp);
		wi.t[i].i = sin(index_temp);	
	}
	
	//Fourier Matrix Construction
	for (i=0; i<Fw->cols; i++)
		for (j=0; j<Fw->rows; j++)
		{
			temp = i*j;	temp %= N;
			Fw->t[i*Fw->rows + j].r = wi.t[temp].r;
			Fw->t[i*Fw->rows + j].i = wi.t[temp].i;
		}
	matrix_free (&wi);
	return 0;
}

int main ()
{
	printf("\t~Modelling of %u-qubit QFT~\n", QUBIT);

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
	COMPLEX_MATRIX* R = (COMPLEX_MATRIX*) malloc ((QUBIT-1) * sizeof(COMPLEX_MATRIX)); 
	if(R==NULL){printf("--Error!: Malloc control phase-shift failed.--\n");return 1;}	

	for (i=0;i<(QUBIT-1);i++)
	{
		printf("R%u:\n",i+2);
		R[i].rows = 0;	R[i].cols = 0;		//R[0] represent R2 phase shift gate and so on
		rad_angle = 2*PI / pow(2, i+2);
		quantum_rotation(identity4, rad_angle, &R[i]);
		matrix_print(R[i]);
		printf("\n");
	}

	//For extended controlled phase-shift gate (tensor product with identity matrix)	
	if(QUBIT>2)
	{
		unsigned int num_iswap = QUBIT-2; 	
		COMPLEX_MATRIX* iswap = (COMPLEX_MATRIX*) malloc (num_iswap * sizeof(COMPLEX_MATRIX)); 
		if(iswap==NULL){printf("--Error!: Malloc iswap failed.--\n");return 1;}

		tensor_product (identity, swap, &iswap[0]);	
		
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
	printf("Number of Unitary Transformation for %u-qubit QFT: %u\n", QUBIT, num_unitary);

	COMPLEX_MATRIX* U = (COMPLEX_MATRIX*) malloc (num_unitary * sizeof(COMPLEX_MATRIX)); 
	if(U==NULL){printf("--Error!: Malloc unitary matrices failed.--\n");return 1;}

	for (i=0;i<num_unitary;i++)
		{U[i].rows = 0; U[i].cols = 0;}

	//Derive unitary matrix of each unitary transformation of QFT circuit	
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
				while(U[count].rows < N)
					tensor_product (U[count], identity, &U[count]);
				count++;
			}
			else
			{
				matrix_copy (R[j-1], &U[count]);
				for(k=0;k<i;k++)	
					tensor_product (identity, U[count], &U[count]);
				while(U[count].rows < N)
					tensor_product (U[count], identity, &U[count]);
				count++;
			}
		}
	}
	
	//Swap sequence of output as required in QFT circuit (last unitary transformation)
	U[count].rows = N;	U[count].cols = N;
	U[count].t =(COMPLEX_NUM*) malloc ((U[count].rows*U[count].cols) * sizeof(COMPLEX_NUM)); 
	if(U[count].t==NULL){printf("--Error!: Malloc multi-swap matrix failed.--\n");return 1;}
	multi_swap (&U[count], QUBIT, N);
		
/*
    //Unitary transformation printout
	for(k=0; k<num_unitary; k++)
	{
		printf("\nUnitary Matrix: U%u\n",k+1);
		matrix_print(U[k]);
	}
*/ 
	
	//Product of unitary transformation matrices
	printf("\nProduct of Unitary Transformation Matrices (Corrected factor):\n");
	COMPLEX_MATRIX U_product; U_product.rows = N;	U_product.cols = N;
	matrix_copy(U[0], &U_product);
	
	for (i=1;i<num_unitary;i++)
		{matrix_mul (U[i], U_product, &U_product);}

	//Factor Correction (due to 1/sqrt(2) constant in each Hadarmard gate)
	//sqrt(2) ^ (total number Hadamards in QFT circuit -- equivalent to total number of qubit)
	COMPLEX_NUM factor;
	float sqrt2 = sqrt(2);
	factor.r = pow(sqrt2, QUBIT); factor.i = 0;	
	//complex_print(factor);

	matrix_scalar_mul (U_product, factor, &U_product);

	matrix_print(U_product);

	//Golden reference Fourier matrix
	printf("\nGolden Reference Fourier Matrix:\n");
	COMPLEX_MATRIX Fw; Fw.rows = N; Fw.cols = N;
	Fw.t =(COMPLEX_NUM*) malloc ((Fw.rows*Fw.cols) * sizeof(COMPLEX_NUM)); 
	if(Fw.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	create_qft_matrix (&Fw);
	matrix_print(Fw);

	//Check if derived unitary transfomation product matrix matches with golden reference Fourier matrix
	unsigned short match = 1;
	for(i=0;i<(N*N);i++)
	{
		if((abs(U_product.t[i].r - Fw.t[i].r)>0.00001) || (abs(U_product.t[i].i - Fw.t[i].i)>0.00001))	//Tolerance for slight differences
			match = 0; 
	}
	
	if(match)
		printf("\nFourier Matrix Match!\n");
	else
		printf("\nFourier Matrix Unmatch!\n");


	//Applying QFT on normalized discrete signal samples
	float mag;
	COMPLEX_MATRIX sig; sig.rows = N; sig.cols = 1;
	sig.t =(COMPLEX_NUM*) malloc ((sig.rows*sig.cols) * sizeof(COMPLEX_NUM)); 
	if(sig.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Read discrete signal from txt file. Assume imaginary parts are all zero.
	FILE *input;
	input=fopen("sig.txt","r");
	for(i=0;i<N;i++)
	{
		fscanf(input,"%f",&sig.t[i].r);
		sig.t[i].i = 0;
	}
	fclose(input);
	
	printf("\nNormalized Input Samples:\n");
	matrix_normalize (sig, &sig, &mag);
	matrix_print(sig);

	//Apply QFT
	printf("\nQFT Output Samples:\n");
	matrix_mul (U_product, sig, &sig);
	matrix_print(sig);

/*	
	printf("\nQFT Transformation by Each Unitary Transformation:\n");
	for(k=0; k<num_unitary; k++)
	{
		printf("\nApply U%u\n",k+1);
		matrix_mul (U[k], sig, &sig);
		matrix_print(sig);
	}
	printf("\nCorrected factor:\n");
	matrix_scalar_mul (sig, factor, &sig);
	matrix_print(sig);
*/

	printf("\nQFT Output Samples (Normalized Factor Corrected):\n");
	COMPLEX_NUM factor_norm;
	factor_norm.r = mag; factor_norm.i = 0;
	matrix_scalar_mul (sig, factor_norm, &sig);
	matrix_print(sig);		

	return 0;
}

