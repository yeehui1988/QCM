#ifndef __CONFIG_H

#define __CONFIG_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define PI 3.14159265


typedef struct
{
	float r;	//real number
  	float i;	//imaginary number
} COMPLEX_NUM;

typedef struct
{
	float m;	//modulus
  	float a;	//angle
} COMPLEX_POLAR;

typedef struct
{
	unsigned int rows;	//matrix number of rows
  	unsigned int cols;	//matrix number of columns
	COMPLEX_NUM *t;
} COMPLEX_MATRIX;

#include "complex.c"
#include "matrix.c"
#include "gate.c"
#include "print_sv.c"

#endif
