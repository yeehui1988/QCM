unsigned int quantum_not(COMPLEX_MATRIX a, COMPLEX_MATRIX* out)
{
	if(a.rows!=2){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_not;
	q_not.rows = 2;
	q_not.cols = 2;
	q_not.t =(COMPLEX_NUM*) malloc ((q_not.rows*q_not.cols) * sizeof(COMPLEX_NUM)); if(q_not.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	q_not.t[0].r = 0; q_not.t[0].i = 0;	//| 0	1 |
	q_not.t[1].r = 1; q_not.t[1].i = 0;	//| 1	0 |
	q_not.t[2].r = 1; q_not.t[2].i = 0;
	q_not.t[3].r = 0; q_not.t[3].i = 0;
	
	matrix_mul (q_not, a, & *out);
	matrix_free (&q_not);
	return 0;
}


unsigned int quantum_hadamard(COMPLEX_MATRIX a, COMPLEX_MATRIX* out)
{
	if(a.rows!=2){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_hadamard;
	float over_root2;
	q_hadamard.rows = 2;
	q_hadamard.cols = 2;
	q_hadamard.t =(COMPLEX_NUM*) malloc ((q_hadamard.rows*q_hadamard.cols) * sizeof(COMPLEX_NUM)); if(q_hadamard.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	over_root2 = 1 / sqrt(2.0);
	q_hadamard.t[0].r = over_root2; q_hadamard.t[0].i = 0;	//| 	1/sqrt(2)	1/sqrt(2) 	|
	q_hadamard.t[1].r = over_root2; q_hadamard.t[1].i = 0;	//| 	1/sqrt(2)	-1/sqrt(2)	|
	q_hadamard.t[2].r = over_root2; q_hadamard.t[2].i = 0;
	q_hadamard.t[3].r = -over_root2; q_hadamard.t[3].i = 0;
	matrix_mul (q_hadamard, a, & *out);
	matrix_free (&q_hadamard);
	return 0;
}

unsigned int quantum_hadamard2(COMPLEX_MATRIX a, COMPLEX_MATRIX* out) //without normalization factor
{
	if(a.rows!=2){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_hadamard;
	float over_root2;
	q_hadamard.rows = 2;
	q_hadamard.cols = 2;
	q_hadamard.t =(COMPLEX_NUM*) malloc ((q_hadamard.rows*q_hadamard.cols) * sizeof(COMPLEX_NUM)); if(q_hadamard.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	q_hadamard.t[0].r = 1; q_hadamard.t[0].i = 0;	//| 	1/sqrt(2)	1/sqrt(2) 	|
	q_hadamard.t[1].r = 1; q_hadamard.t[1].i = 0;	//| 	1/sqrt(2)	-1/sqrt(2)	|
	q_hadamard.t[2].r = 1; q_hadamard.t[2].i = 0;
	q_hadamard.t[3].r = -1; q_hadamard.t[3].i = 0;
	matrix_mul (q_hadamard, a, & *out);
	matrix_free (&q_hadamard);
	return 0;
}

unsigned int quantum_cnot(COMPLEX_MATRIX a, COMPLEX_MATRIX* out)
{
	if(a.rows!=4){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_cnot;
    unsigned int i;
	q_cnot.rows = 4;
	q_cnot.cols = 4;
	q_cnot.t =(COMPLEX_NUM*) malloc ((q_cnot.rows*q_cnot.cols) * sizeof(COMPLEX_NUM)); if(q_cnot.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}


    //Preset all to 0
	for(i=0;i<(q_cnot.rows*q_cnot.cols);i++)
	{
		q_cnot.t[i].r = 0; q_cnot.t[i].i = 0;
	}

	//Set necessary elements to 1
    q_cnot.t[0].r = 1;      //|	1	0	0	0 	| 
    q_cnot.t[5].r = 1;      //|	0	1	0	0 	|          
    q_cnot.t[11].r = 1;     //|	0	0	0	1 	|
    q_cnot.t[14].r = 1;     //|	0	0	1	0 	|
	
	matrix_mul (q_cnot, a, & *out);
	matrix_free (&q_cnot);
	return 0;
}

unsigned int quantum_toffoli(COMPLEX_MATRIX a, COMPLEX_MATRIX* out)
{
	if(a.rows!=8){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_toffoli;
	unsigned int i;
	q_toffoli.rows = 8;
	q_toffoli.cols = 8;
	q_toffoli.t =(COMPLEX_NUM*) malloc ((q_toffoli.rows*q_toffoli.cols) * sizeof(COMPLEX_NUM)); if(q_toffoli.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	//Preset all to 0
	for(i=0;i<(q_toffoli.rows*q_toffoli.cols);i++)
	{
		q_toffoli.t[i].r = 0; q_toffoli.t[i].i = 0;
	}

	//Set necessary elements to 1
	q_toffoli.t[0].r = 1;			//|	1	0	0	0	0	0	0	0 	|
	q_toffoli.t[9].r = 1;			//|	0	1	0	0 	0	0	0	0 	|
	q_toffoli.t[18].r = 1;			//|	0	0	1	0 	0	0	0	0 	|
	q_toffoli.t[27].r = 1;			//|	0	0	0	1 	0	0	0	0 	|
	q_toffoli.t[36].r = 1;			//|	0	0	0	0 	1	0	0	0 	|	
	q_toffoli.t[45].r = 1;			//|	0	0	0	0 	0	1	0	0 	|
	q_toffoli.t[55].r = 1;			//|	0	0	0	0 	0	0	0	1 	|
	q_toffoli.t[62].r = 1;			//|	0	0	0	0 	0	0	1	0 	|
	
	matrix_mul (q_toffoli, a, & *out);
	matrix_free (&q_toffoli);
	return 0;
}

unsigned int quantum_fredkin(COMPLEX_MATRIX a, COMPLEX_MATRIX* out)
{
	if(a.rows!=8){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_fredkin;
	unsigned int i;
	q_fredkin.rows = 8;
	q_fredkin.cols = 8;
	q_fredkin.t =(COMPLEX_NUM*) malloc ((q_fredkin.rows*q_fredkin.cols) * sizeof(COMPLEX_NUM)); if(q_fredkin.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	//Preset all to 0
	for(i=0;i<(q_fredkin.rows*q_fredkin.cols);i++)
	{
		q_fredkin.t[i].r = 0; q_fredkin.t[i].i = 0;
	}

	//Set necessary elements to 1
	q_fredkin.t[0].r = 1;			//|	1	0	0	0	0	0	0	0 	|
	q_fredkin.t[9].r = 1;			//|	0	1	0	0 	0	0	0	0 	|
	q_fredkin.t[18].r = 1;			//|	0	0	1	0 	0	0	0	0 	|
	q_fredkin.t[27].r = 1;			//|	0	0	0	1 	0	0	0	0 	|
	q_fredkin.t[36].r = 1;			//|	0	0	0	0 	1	0	0	0 	|	
	q_fredkin.t[46].r = 1;			//|	0	0	0	0 	0	0	1	0 	|
	q_fredkin.t[53].r = 1;			//|	0	0	0	0 	0	1	0	0 	|
	q_fredkin.t[63].r = 1;			//|	0	0	0	0 	0	0	0	1 	|
	
	matrix_mul (q_fredkin, a, & *out);
	matrix_free (&q_fredkin);
	return 0;
}

//1-qubit phase shift gate (complex angle): 
unsigned int quantum_rotat(COMPLEX_MATRIX a, float rad_angle, COMPLEX_MATRIX* out)
{
	if(a.rows!=2){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_ps;
	q_ps.rows = 2;
	q_ps.cols = 2;
	q_ps.t =(COMPLEX_NUM*) malloc ((q_ps.rows*q_ps.cols) * sizeof(COMPLEX_NUM)); if(q_ps.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	q_ps.t[0].r = 1; q_ps.t[0].i = 0;	//| 1	     0 		|
	q_ps.t[1].r = 0; q_ps.t[1].i = 0;	//| 0	e^(i*theta) |
	q_ps.t[2].r = 0; q_ps.t[2].i = 0;
	q_ps.t[3].r = cos(rad_angle); q_ps.t[3].i = sin(rad_angle);
	
	matrix_mul (q_ps, a, & *out);
	matrix_free (&q_ps);
	return 0;
}

//Controlled phase shift gate (complex angle): Apply phase shifting if control input is |1>
unsigned int quantum_rotation(COMPLEX_MATRIX a, float rad_angle, COMPLEX_MATRIX* out)
{
	if(a.rows!=4){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_ps;
	q_ps.rows = 4;
	q_ps.cols = 4;
	q_ps.t =(COMPLEX_NUM*) malloc ((q_ps.rows*q_ps.cols) * sizeof(COMPLEX_NUM)); if(q_ps.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Preset all to 0
	unsigned int i;
	for(i=0;i<(q_ps.rows*q_ps.cols);i++)
	{
		q_ps.t[i].r = 0; q_ps.t[i].i = 0;
	}
	
	q_ps.t[0].r = 1; 							                        //| 1	0 	0	        0		|
	q_ps.t[5].r = 1; 							                        //| 0	1 	0	        0		|
	q_ps.t[10].r = 1; 							                        //| 0	0 	1	        0		|
	q_ps.t[15].r = cos(rad_angle); q_ps.t[15].i = sin(rad_angle);		//| 0	0  	0     e^(i*theta) 	|
	
	matrix_mul (q_ps, a, & *out);
	matrix_free (&q_ps);
	return 0;
}

unsigned int quantum_r3(COMPLEX_MATRIX a, float rad_angle, COMPLEX_MATRIX* out) //For HW fixed point verification
{
	if(a.rows!=4){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_ps;
	q_ps.rows = 4;
	q_ps.cols = 4;
	q_ps.t =(COMPLEX_NUM*) malloc ((q_ps.rows*q_ps.cols) * sizeof(COMPLEX_NUM)); if(q_ps.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Preset all to 0
	unsigned int i;
	for(i=0;i<(q_ps.rows*q_ps.cols);i++)
	{
		q_ps.t[i].r = 0; q_ps.t[i].i = 0;
	}
	
	q_ps.t[0].r = 1; 							                        //| 1	0 	0	        0		|
	q_ps.t[5].r = 1; 							                        //| 0	1 	0	        0		|
	q_ps.t[10].r = 1; 							                        //| 0	0 	1	        0		|
	q_ps.t[15].r = 0.707092; q_ps.t[15].i = 0.707092;			        //| 0	0   0     e^(i*theta) 	|
	
	matrix_mul (q_ps, a, & *out);
	matrix_free (&q_ps);
	return 0;
}

unsigned int quantum_swap(COMPLEX_MATRIX a, COMPLEX_MATRIX* out)
{
	if(a.rows!=4){printf("--Error!: Unmatch vector dimension to apply gate.--\n");return 1;}
	COMPLEX_MATRIX q_swap;
	q_swap.rows = 4;
	q_swap.cols = 4;
	q_swap.t =(COMPLEX_NUM*) malloc ((q_swap.rows*q_swap.cols) * sizeof(COMPLEX_NUM)); if(q_swap.t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}
	
	//Preset all to 0
	unsigned int i;
	for(i=0;i<(q_swap.rows*q_swap.cols);i++)
	{
		q_swap.t[i].r = 0; q_swap.t[i].i = 0;
	}

	q_swap.t[0].r = 1; 		//| 1	0   0	0 |
	q_swap.t[6].r = 1; 		//| 0	0   1	0 |
	q_swap.t[9].r = 1; 		//| 0	1   0	0 |
	q_swap.t[15].r = 1; 	//| 0	0   0	1 |
	
	
	matrix_mul (q_swap, a, & *out);
	matrix_free (&q_swap);
	return 0;
}

void multi_swap (COMPLEX_MATRIX* U, unsigned int bit, unsigned int n) 
{
	unsigned int i, j, a, track, temp;
	unsigned char* b = (unsigned char*) malloc ((bit) * sizeof(unsigned char)); if(b==NULL){printf("--Error!: Malloc multi-swap bit failed.--\n");return;}
	
	for(i=0;i<(U->rows * U->cols);i++)
	{U->t[i].r = 0; U->t[i].i = 0;}
	
	for (i=0;i<n;i++)
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
		U->t[a + (i*n)].r = 1; 
	}
	free(b);
}
