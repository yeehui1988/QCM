void complex_print(COMPLEX_NUM a)
{
	printf("%f + %fi\n",a.r,a.i);	
	return;
}

void complex_add(COMPLEX_NUM a, COMPLEX_NUM b, COMPLEX_NUM *c)
{
	c->r = a.r + b.r;
	c->i = a.i + b.i;
	return;
}

void complex_sub(COMPLEX_NUM a, COMPLEX_NUM b, COMPLEX_NUM *c)
{
	c->r = a.r - b.r;
	c->i = a.i - b.i;
	return;
}

void complex_mul(COMPLEX_NUM a, COMPLEX_NUM b, COMPLEX_NUM *c)
{
	c->r = (a.r * b.r) - (a.i * b.i);
	c->i = (a.i * b.r) + (b.i * a.r) ;
	return;
}

void complex_div(COMPLEX_NUM a, COMPLEX_NUM b, COMPLEX_NUM *c)
{
	float temp;
	temp = (b.r * b.r) + (b.i * b.i);
	if(temp == 0)
		c->r = 0;
	else
		c->r = ((a.r * b.r) + (a.i * b.i)) / temp;
	if(temp == 0)
		c->i = 0;
	else
		c->i = ((b.r * a.i) - (a.r * b.i)) / temp;
	return;
}

void complex_scalar_div(COMPLEX_NUM a, float b, COMPLEX_NUM *c)
{
	c->r = a.r / b;
	c->i = a.i / b;
	return;
}

void complex_modulus(COMPLEX_NUM a, float *b)
{
	*b = sqrt((a.r*a.r) + (a.i*a.i));
	return;
}

void complex_modulus_square(COMPLEX_NUM a, float *b)
{
	*b = (a.r*a.r) + (a.i*a.i);
	return;
}

void complex_conjugate(COMPLEX_NUM a, COMPLEX_NUM *b)
{
	b->r = a.r;
	b->i = -a.i;
	return;
}

void cartesian2polar (COMPLEX_NUM a, COMPLEX_POLAR *b)
{
	complex_modulus(a,&b->m);

	float temp;
	temp = atan(a.i / a.r);
	if(temp<0)			
		b->a = temp + (2*PI);
	else
		b->a = temp;
	return;
}

void polar2cartesian (COMPLEX_POLAR a, COMPLEX_NUM *b)
{
	b->r = a.m * cos(a.a); 
	b->i = a.m * sin(a.a);
	return;
}

void polar_print(COMPLEX_POLAR a)
{
	printf("Complex number (Polar): (%f , %f)\n",a.m,a.a);	
	return;
}

void polar_mul(COMPLEX_POLAR a, COMPLEX_POLAR b, COMPLEX_POLAR *c)	
{
	c->m = a.m * b.m;
	
	float temp;			
	temp = a.a + b.a;
	if(temp > (2*PI))
		c->a = temp - (2*PI);
	else
		c->a = temp;
}

void polar_div(COMPLEX_POLAR a, COMPLEX_POLAR b, COMPLEX_POLAR *c)	
{
	c->m = a.m / b.m;
	
	float temp;			
	temp = a.a - b.a;
	if(temp < 0)
		c->a = temp + (2*PI);
	else
		c->a = temp;	
	return;
}
