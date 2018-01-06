unsigned int quantum_hadamard(COMPLEX_MATRIX* q_hadamard)
{
	float over_root2; unsigned int i;
	q_hadamard->rows = 2; q_hadamard->cols = 2;
	q_hadamard->t =(COMPLEX_NUM*) malloc ((q_hadamard->rows*q_hadamard->cols) * sizeof(COMPLEX_NUM)); if(q_hadamard->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	over_root2 = 1 / sqrt(2.0);
	//Preset all to 0
	for(i=0;i<(q_hadamard->rows*q_hadamard->cols);i++)
	{q_hadamard->t[i].r = 0; q_hadamard->t[i].i = 0;}
	
	q_hadamard->t[0].r = over_root2;
	q_hadamard->t[1].r = over_root2;
	q_hadamard->t[2].r = over_root2;
	q_hadamard->t[3].r = -over_root2;
	return 0;
}

//Without the 1/sqrt(2) constant
unsigned int quantum_hadamard2(COMPLEX_MATRIX* q_hadamard)
{
 	unsigned int i;
	q_hadamard->rows = 2; q_hadamard->cols = 2;
	q_hadamard->t =(COMPLEX_NUM*) malloc ((q_hadamard->rows*q_hadamard->cols) * sizeof(COMPLEX_NUM)); if(q_hadamard->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	//Preset all to 0
	for(i=0;i<(q_hadamard->rows*q_hadamard->cols);i++)
	{q_hadamard->t[i].r = 1; q_hadamard->t[i].i = 0;}
	
	q_hadamard->t[3].r = -1;
	return 0;
}

unsigned int quantum_not(COMPLEX_MATRIX* q_not)
{
	unsigned int i;
	q_not->rows = 2;	q_not->cols = 2;
	q_not->t =(COMPLEX_NUM*) malloc ((q_not->rows*q_not->cols) * sizeof(COMPLEX_NUM)); if(q_not->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	//Preset all to 0
	for(i=0;i<(q_not->rows*q_not->cols);i++)
	{q_not->t[i].r = 0; q_not->t[i].i = 0;}

	q_not->t[1].r = 1;
	q_not->t[2].r = 1;
	return 0;
}

unsigned int quantum_cnot(COMPLEX_MATRIX* q_cnot)
{
	unsigned int i;
	q_cnot->rows = 4; q_cnot->cols = 4;
	q_cnot->t =(COMPLEX_NUM*) malloc ((q_cnot->rows*q_cnot->cols) * sizeof(COMPLEX_NUM)); if(q_cnot->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	//Preset all to 0
	for(i=0;i<(q_cnot->rows*q_cnot->cols);i++)
	{q_cnot->t[i].r = 0; q_cnot->t[i].i = 0;}

	q_cnot->t[0].r = 1; 	//|	1	0	0	0 	|
	q_cnot->t[5].r = 1; 	//|	0	1	0	0 	|
	q_cnot->t[11].r = 1; 	//|	0	0	0	1 	|
	q_cnot->t[14].r = 1; 	//|	0	0	1	0 	|
	return 0;
}

unsigned int quantum_toffoli(COMPLEX_MATRIX* q_toffoli)
{
	unsigned int i;
	q_toffoli->rows = 8; q_toffoli->cols = 8;
	q_toffoli->t =(COMPLEX_NUM*) malloc ((q_toffoli->rows*q_toffoli->cols) * sizeof(COMPLEX_NUM)); if(q_toffoli->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	//Preset all to 0
	for(i=0;i<(q_toffoli->rows*q_toffoli->cols);i++)
	{q_toffoli->t[i].r = 0; q_toffoli->t[i].i = 0;}

	//Set necessary elements to 1
	q_toffoli->t[0].r = 1;			//|	1	0	0	0	0	0	0	0 	|
	q_toffoli->t[9].r = 1;			//|	0	1	0	0 	0	0	0	0 	|
	q_toffoli->t[18].r = 1;			//|	0	0	1	0 	0	0	0	0 	|
	q_toffoli->t[27].r = 1;			//|	0	0	0	1 	0	0	0	0 	|
	q_toffoli->t[36].r = 1;			//|	0	0	0	0 	1	0	0	0 	|	
	q_toffoli->t[45].r = 1;			//|	0	0	0	0 	0	1	0	0 	|
	q_toffoli->t[55].r = 1;			//|	0	0	0	0 	0	0	0	1 	|
	q_toffoli->t[62].r = 1;			//|	0	0	0	0 	0	0	1	0 	|
	
	return 0;
}

unsigned int quantum_fredkin(COMPLEX_MATRIX* q_fredkin)
{
	unsigned int i;
	q_fredkin->rows = 8; q_fredkin->cols = 8;
	q_fredkin->t =(COMPLEX_NUM*) malloc ((q_fredkin->rows*q_fredkin->cols) * sizeof(COMPLEX_NUM)); if(q_fredkin->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	//Preset all to 0
	for(i=0;i<(q_fredkin->rows*q_fredkin->cols);i++)
	{q_fredkin->t[i].r = 0; q_fredkin->t[i].i = 0;}

	//Set necessary elements to 1
	q_fredkin->t[0].r = 1;			//|	1	0	0	0	0	0	0	0 	|
	q_fredkin->t[9].r = 1;			//|	0	1	0	0 	0	0	0	0 	|
	q_fredkin->t[18].r = 1;			//|	0	0	1	0 	0	0	0	0 	|
	q_fredkin->t[27].r = 1;			//|	0	0	0	1 	0	0	0	0 	|
	q_fredkin->t[36].r = 1;			//|	0	0	0	0 	1	0	0	0 	|	
	q_fredkin->t[46].r = 1;			//|	0	0	0	0 	0	0	1	0 	|
	q_fredkin->t[53].r = 1;			//|	0	0	0	0 	0	1	0	0 	|
	q_fredkin->t[63].r = 1;			//|	0	0	0	0 	0	0	0	1 	|
	
	return 0;
}

//1-qubit phase shift gate (complex angle): 
unsigned int quantum_rotat(COMPLEX_MATRIX* q_ps, float rad_angle)
{
	unsigned int i;
	q_ps->rows = 2; q_ps->cols = 2;
	q_ps->t =(COMPLEX_NUM*) malloc ((q_ps->rows*q_ps->cols) * sizeof(COMPLEX_NUM)); if(q_ps->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	for(i=0;i<(q_ps->rows*q_ps->cols);i++)
	{q_ps->t[i].r = 0; q_ps->t[i].i = 0;}

	q_ps->t[0].r = 1; 						//| 1	     0 		|
	q_ps->t[3].r = cos(rad_angle); q_ps->t[3].i = sin(rad_angle);	//| 0	e^(i*theta) 	|

	return 0;
}

//Controlled phase shift gate (complex angle): Apply phase shifting if control input is |1>
unsigned int quantum_rotation(COMPLEX_MATRIX* q_ps, float rad_angle)
{
	q_ps->rows = 4; q_ps->cols = 4;
	q_ps->t =(COMPLEX_NUM*) malloc ((q_ps->rows*q_ps->cols) * sizeof(COMPLEX_NUM)); if(q_ps->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Preset all to 0
	unsigned int i;
	for(i=0;i<(q_ps->rows*q_ps->cols);i++)
	{q_ps->t[i].r = 0; q_ps->t[i].i = 0;}
	
	q_ps->t[0].r = 1; 							//| 1	0 	0	   0		|
	q_ps->t[5].r = 1; 							//| 0	1 	0	   0		|
	q_ps->t[10].r = 1; 							//| 0	0 	1	   0		|
	q_ps->t[15].r = cos(rad_angle); q_ps->t[15].i = sin(rad_angle);		//| 0	0   	0     e^(i*theta) 	|

	return 0;
}

unsigned int quantum_swap(COMPLEX_MATRIX* q_swap)
{
	q_swap->rows = 4; q_swap->cols = 4;
	q_swap->t =(COMPLEX_NUM*) malloc ((q_swap->rows*q_swap->cols) * sizeof(COMPLEX_NUM)); if(q_swap->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Preset all to 0
	unsigned int i;
	for(i=0;i<(q_swap->rows*q_swap->cols);i++)
	{q_swap->t[i].r = 0; q_swap->t[i].i = 0;}

	q_swap->t[0].r = 1; 		//| 1	0   0	0 |
	q_swap->t[6].r = 1; 		//| 0	0   1	0 |
	q_swap->t[9].r = 1; 		//| 0	1   0	0 |
	q_swap->t[15].r = 1; 		//| 0	0   0	1 |

	return 0;
}

unsigned int quantum_multi_swap (COMPLEX_MATRIX* U, unsigned int bit) 
{
	unsigned int i, j, a, track, temp, N;
	N=pow(2,bit);
	unsigned char* b = (unsigned char*) malloc ((bit) * sizeof(unsigned char)); if(b==NULL){printf("--Error!: Malloc multi-swap bit failed.--\n");return 1;}

	U->rows = N; U->cols = N;
	U->t =(COMPLEX_NUM*) malloc ((U->rows*U->cols) * sizeof(COMPLEX_NUM)); if(U->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	for(i=0;i<(U->rows * U->cols);i++)
	{U->t[i].r = 0; U->t[i].i = 0;}
	
	for (i=0;i<N;i++)
	{
		a=0; track = i;
		for(j=0;j<bit;j++)
		{
			temp = pow (2, (bit-1-j));
			b[j]= track / temp;			//convert to binary
			if(b[j])
			{
				track -= temp;	
				a += pow(2,j);			//inverse the binary
			}
		}
		U->t[a + (i*N)].r = 1; 
	}
	free(b);
	return 0;
}

unsigned int identity_matrix (COMPLEX_MATRIX* a, unsigned int bit) //identity matrix is square matrix
{
	unsigned int i,j,size;
	size=pow(2,bit);
	a->rows = size;	a->cols = size;
	a->t =(COMPLEX_NUM*) malloc ((a->rows*a->cols) * sizeof(COMPLEX_NUM)); if(a->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return 1;}

	for(i=0;i<a->rows;i++)
		for(j=0;j<a->cols;j++)
		{
			if(i==j)
			{a->t[(i*a->cols) + j].r = 1; a->t[(i*a->cols) + j].i = 0;}
			else
			{a->t[(i*a->cols) + j].r = 0; a->t[(i*a->cols) + j].i = 0;}
		}
	return 0;
}

unsigned int quantum_pauli_X (COMPLEX_MATRIX* p_X)
{
	unsigned int i;
	p_X->rows = 2; p_X->cols = 2;
	p_X->t =(COMPLEX_NUM*) malloc ((p_X->rows*p_X->cols) * sizeof(COMPLEX_NUM)); if(p_X->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Preset all to 0
	for(i=0;i<(p_X->rows*p_X->cols);i++)
	{p_X->t[i].r = 0; p_X->t[i].i = 0;}
	
	p_X->t[1].r = 1;
	p_X->t[2].r = 1;
	
	return 0;
}

unsigned int quantum_pauli_Y (COMPLEX_MATRIX* p_Y)
{
	unsigned int i;
	p_Y->rows = 2; p_Y->cols = 2;
	p_Y->t =(COMPLEX_NUM*) malloc ((p_Y->rows*p_Y->cols) * sizeof(COMPLEX_NUM)); if(p_Y->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Preset all to 0
	for(i=0;i<(p_Y->rows*p_Y->cols);i++)
	{p_Y->t[i].r = 0; p_Y->t[i].i = 0;}
	
	p_Y->t[1].i = -1;
	p_Y->t[2].i = 1;
	
	return 0;
}

unsigned int quantum_pauli_Z (COMPLEX_MATRIX* p_Z)
{
	unsigned int i;
	p_Z->rows = 2; p_Z->cols = 2;
	p_Z->t =(COMPLEX_NUM*) malloc ((p_Z->rows*p_Z->cols) * sizeof(COMPLEX_NUM)); if(p_Z->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Preset all to 0
	for(i=0;i<(p_Z->rows*p_Z->cols);i++)
	{p_Z->t[i].r = 0; p_Z->t[i].i = 0;}
	
	p_Z->t[0].r = 1;
	p_Z->t[3].r = -1;
	
	return 0;
}

unsigned int quantum_P (COMPLEX_MATRIX* q_P) //Phase gate
{
	unsigned int i;
	q_P->rows = 2; q_P->cols = 2;
	q_P->t =(COMPLEX_NUM*) malloc ((q_P->rows*q_P->cols) * sizeof(COMPLEX_NUM)); if(q_P->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Preset all to 0
	for(i=0;i<(q_P->rows*q_P->cols);i++)
	{q_P->t[i].r = 0; q_P->t[i].i = 0;}
	
	q_P->t[0].r = 1;
	q_P->t[3].i = 1;
	return 0;
}	
