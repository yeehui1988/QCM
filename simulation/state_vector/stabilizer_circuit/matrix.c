void matrix_print (COMPLEX_MATRIX a)
{
	unsigned int i,j;
	for(i=0;i<a.rows;i++)
	{
		for(j=0;j<a.cols;j++)
			printf("%10f + %8fi\t", a.t[(i*a.cols) + j].r, a.t[(i*a.cols) + j].i);
		printf("\n");
	}
	return;
}

void matrix_print_real (COMPLEX_MATRIX a)
{
	unsigned int i,j;
	for(i=0;i<a.rows;i++)
	{
		for(j=0;j<a.cols;j++)
			printf("%10f\t", a.t[(i*a.cols) + j].r);
		printf("\n");
	}
	return;
}

void matrix_magnitude (COMPLEX_MATRIX a, float *mag)
{
	unsigned int i;
	float sum=0,temp;
	
	//Compute magnitude
	for(i=0;i<(a.rows*a.cols);i++)
	{
		complex_modulus_square(a.t[i], &temp);
		sum += temp;
	}
	*mag = sqrt(sum);
//	matrix_magnitude (sig, &mag);
//	printf("Magnitude of Input Samples: %f\n\n", mag);	

	return;
}

void matrix_normalize (COMPLEX_MATRIX a, COMPLEX_MATRIX *b, float *mag)
{
	unsigned int i;
	float temp;
	
	//Compute magnitude
	matrix_magnitude (a, &temp);
	//Normalize the matrix by dividing the magnitude
	b->rows = a.rows;
	b->cols = a.cols;
	b->t =(COMPLEX_NUM*) malloc ((b->rows*b->cols) * sizeof(COMPLEX_NUM)); if(b->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}
	for(i=0;i<(a.rows*a.cols);i++)
	{
		b->t[i].r = a.t[i].r / temp;
		b->t[i].i = a.t[i].i / temp;
	}	
	*mag = temp;
	return;
}

void matrix_copy (COMPLEX_MATRIX a, COMPLEX_MATRIX *b)
{
	unsigned int i,j;
	b->rows = a.rows;
	b->cols = a.cols;
	b->t =(COMPLEX_NUM*) malloc ((b->rows*b->cols) * sizeof(COMPLEX_NUM)); if(b->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}
	for(i=0;i<b->cols*b->rows;i++)
	{
		b->t[i].r = a.t[i].r;
		b->t[i].i = a.t[i].i;
	}
	return;
}

void matrix_free (COMPLEX_MATRIX *a)
{
	//Check if the pointer a->t has been malloc. Hence during the matrix initialization, rows and cols must preset to 0.
	if(a->rows==0 || a->cols==0)	 
	{return;}
	else
	{free(a->t); a->rows=0; a->cols=0;}
	return;
}

void create_identity_matrix (COMPLEX_MATRIX* a, unsigned int size) //identity matrix is square matrix
{
	unsigned int i,j;
	a->rows = size;
	a->cols = size;
	a->t =(COMPLEX_NUM*) malloc ((a->rows*a->cols) * sizeof(COMPLEX_NUM)); if(a->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}

	for(i=0;i<a->rows;i++)
		for(j=0;j<a->cols;j++)
		{
			if(i==j)
			{
				a->t[(i*a->cols) + j].r = 1;
				a->t[(i*a->cols) + j].i = 0;
			}
			else
			{
				a->t[(i*a->cols) + j].r = 0;
				a->t[(i*a->cols) + j].i = 0;
			}
		}
	return;
}

void matrix_scalar_mul (COMPLEX_MATRIX a, COMPLEX_NUM scalar, COMPLEX_MATRIX* b)
{
	unsigned int i,j;
	b->rows = a.rows;
	b->cols = a.cols;
	b->t =(COMPLEX_NUM*) malloc ((b->rows*b->cols) * sizeof(COMPLEX_NUM)); if(b->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}

	for(i=0;i<a.rows;i++)
		for(j=0;j<a.cols;j++)
			complex_mul(a.t[(i*a.cols) + j], scalar, &b->t[(i*a.cols) + j]);
	return;
}

void matrix_inverse (COMPLEX_MATRIX a, COMPLEX_MATRIX* b) //inverse or negative
{
	unsigned int i,j;
	b->rows = a.rows;
	b->cols = a.cols;
	b->t =(COMPLEX_NUM*) malloc ((b->rows*b->cols) * sizeof(COMPLEX_NUM)); if(b->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}
	for(i=0;i<a.rows;i++)
		for(j=0;j<a.cols;j++)
		{
			b->t[(i*a.cols) + j].r = a.t[(i*a.cols) + j].r * -1;
			b->t[(i*a.cols) + j].i = a.t[(i*a.cols) + j].i * -1;
		}
	return;
}

void matrix_transpose (COMPLEX_MATRIX a, COMPLEX_MATRIX* b)
{
	unsigned int i,j;
	b->rows = a.cols;
	b->cols = a.rows;

	b->t =(COMPLEX_NUM*) malloc ((b->rows*b->cols) * sizeof(COMPLEX_NUM)); if(b->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}

	for(i=0;i<a.rows;i++)
		for(j=0;j<a.cols;j++)
			b->t[(j*b->cols) + i] = a.t[(i*a.cols) + j];
	return;
}

void matrix_adjoint (COMPLEX_MATRIX a, COMPLEX_MATRIX* b)	//Matrix adjoint = transpose conjugate
{
	unsigned int i,j;
	COMPLEX_MATRIX temp;
	temp.cols = 0; temp.rows = 0;
	matrix_transpose(a,&temp);	

	b->rows = temp.rows;
	b->cols = temp.cols;
	b->t =(COMPLEX_NUM*) malloc ((b->rows*b->cols) * sizeof(COMPLEX_NUM)); if(b->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}
	
	for(i=0;i<b->rows;i++)
		for(j=0;j<b->cols;j++)
			complex_conjugate(temp.t[(i*b->cols) + j], &b->t[(i*b->cols) + j]);
	//Free matrix
	matrix_free (&temp);
	return;
}

void matrix_add (COMPLEX_MATRIX a, COMPLEX_MATRIX b , COMPLEX_MATRIX* c)
{
	if((a.rows != b.rows) || (a.cols != b.cols))
	{
		printf("--Error!: Different matrix dimensions. Matrix addition failed.--\n");
		return;
	}
	
	unsigned int i,j;
	c->rows = a.rows;
	c->cols = a.cols;
	c->t =(COMPLEX_NUM*) malloc ((c->rows*c->cols) * sizeof(COMPLEX_NUM)); if(c->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}
	for(i=0;i<a.rows;i++)
		for(j=0;j<a.cols;j++)
		{
			c->t[(i*a.cols) + j].r = a.t[(i*a.cols) + j].r + b.t[(i*a.cols) + j].r;
			c->t[(i*a.cols) + j].i = a.t[(i*a.cols) + j].i + b.t[(i*a.cols) + j].i;
		}
	return;
}

void matrix_sub (COMPLEX_MATRIX a, COMPLEX_MATRIX b , COMPLEX_MATRIX* c)
{
	if((a.rows != b.rows) || (a.cols != b.cols))
	{
		printf("--Error!: Different matrix dimensions. Matrix subtraction failed.--\n");
		return;
	}
	
	unsigned int i,j;
	c->rows = a.rows;
	c->cols = a.cols;
	c->t =(COMPLEX_NUM*) malloc ((c->rows*c->cols) * sizeof(COMPLEX_NUM)); if(c->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}
	for(i=0;i<a.rows;i++)
		for(j=0;j<a.cols;j++)
		{
			c->t[(i*a.cols) + j].r = a.t[(i*a.cols) + j].r - b.t[(i*a.cols) + j].r;
			c->t[(i*a.cols) + j].i = a.t[(i*a.cols) + j].i - b.t[(i*a.cols) + j].i;
		}
	return;
}

void matrix_mul (COMPLEX_MATRIX a, COMPLEX_MATRIX b , COMPLEX_MATRIX* c)
{
	if(a.cols != b.rows)
	{
		printf("--Error!: Different matrix dimensions. Matrix multiplication failed.--\n");
		return;
	}
	c->rows = a.rows;	//Resulted number of rows is the same as the first matrix 
	c->cols = b.cols;	//Resulted number of columns is the same as the second matrix

	unsigned int i,j,k,l;
	COMPLEX_NUM sum,temp;
	c->t =(COMPLEX_NUM*) malloc ((c->rows*c->cols) * sizeof(COMPLEX_NUM)); if(c->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}

	//Matrix multiplication: multiply row by column
	for(i=0;i<c->rows;i++)
	{
		for(j=0;j<c->cols;j++)
		{
			sum.r = 0;
			sum.i = 0;
			for(k=0;k<a.cols;k++)
			{
				complex_mul(a.t[(i*a.cols) + k], b.t[(k*b.cols) + j], &temp);
				sum.r += temp.r;
				sum.i += temp.i;
			}
			c->t[(i*c->cols) + j].r = sum.r;
			c->t[(i*c->cols) + j].i = sum.i;
		}
	}
	return;
}

void check_matrices_match (const COMPLEX_MATRIX a, const COMPLEX_MATRIX b) //Hermitian: adjoint matrix equal to original matrix
{
	if(a.rows != b.rows || a.cols != b.cols)
	{printf("\t--Unmatch Matrices--\n"); return;}

	unsigned int i,j;
	for(i=0;i<a.rows;i++)
		for(j=0;j<a.cols;j++)
		{
			if((a.t[(i*a.cols) + j].r - b.t[(i*a.cols) + j].r) > 0.0001 || (a.t[(i*a.cols) + j].i - b.t[(i*a.cols) + j].i) > 0.0001)
			{printf("\t--Unmatch Matrices--\n"); return;}
		}	
	printf("\t--Match Matrices--\n"); return;
}

unsigned int check_hermitian (COMPLEX_MATRIX a) //Hermitian: adjoint matrix equal to original matrix
{
	COMPLEX_MATRIX temp;
	temp.cols = 0; temp.rows = 0;
	unsigned int i,j;
	matrix_adjoint (a, &temp);
	
	for(i=0;i<a.rows;i++)
		for(j=0;j<a.cols;j++)	
		{
			if((a.t[(i*a.cols) + j].r == temp.t[(i*a.cols) + j].r) && (a.t[(i*a.cols) + j].i == temp.t[(i*a.cols) + j].i))
				continue;
			else
				{matrix_free (&temp);return 0;}
		}
	matrix_free (&temp);
	return 1;
}

unsigned int check_unitary (COMPLEX_MATRIX a)	//Unitary: multiplication of adjoint and original matrix results in identity matrix
{
	COMPLEX_MATRIX b,temp;
	b.cols = 0; b.rows = 0; temp.cols = 0; temp.rows = 0;
	unsigned int i,j;
	matrix_adjoint (a, &b);
	matrix_mul (a, b , &temp);
	for(i=0;i<a.rows;i++)
		for(j=0;j<a.cols;j++)
		{
			if(i==j)	
			{
				if((round(temp.t[(i*a.cols) + j].r)==1) && (round(temp.t[(i*a.cols) + j].i)==0))
					continue;
				else
					{matrix_free (&temp);matrix_free (&b);return 0;}
			}
			else
			{
				if((round(temp.t[(i*a.cols) + j].r)==0) && (round(temp.t[(i*a.cols) + j].i)==0))
					continue;
				else
					{matrix_free (&temp);matrix_free (&b);return 0;}
			}			
		}
	matrix_free (&temp);matrix_free (&b);
	return 1;
}

void tensor_product (COMPLEX_MATRIX a, COMPLEX_MATRIX b , COMPLEX_MATRIX* c)
{
	unsigned int i,j,k,l,index;
	c->rows = a.rows * b.rows;
	c->cols = a.cols * b.cols;
	c->t =(COMPLEX_NUM*) malloc ((c->rows*c->cols) * sizeof(COMPLEX_NUM)); if(c->t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}

	for(i=0;i<a.rows;i++)
		for(j=0;j<a.cols;j++)
			for(k=0;k<b.rows;k++)
				for(l=0;l<b.cols;l++)
				{
					index = ((i*b.rows + k) * (a.cols*b.cols)) + (j*b.cols + l);
					complex_mul(a.t[(i*a.cols) + j], b.t[(k*b.cols) + l], &c->t[index]);
				}
	return;
}
