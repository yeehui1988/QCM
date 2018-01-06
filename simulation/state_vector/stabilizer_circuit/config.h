#ifndef __CONFIG_H

#define __CONFIG_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define PI 3.14159265


typedef struct
{
	float r;	//real number
  	float i;	//imaginary number
} COMPLEX_NUM;

typedef struct
{
	unsigned int rows;	//matrix number of rows
  	unsigned int cols;	//matrix number of columns
	COMPLEX_NUM *t;
} COMPLEX_MATRIX;

typedef struct
{
	float m;	//modulus
  	float a;	//angle
} COMPLEX_POLAR;

typedef struct
{
	unsigned int num_qubit;		//number of qubit
	unsigned short type;		//'0' consist of X, Z, I only; '1' contains Y
  	unsigned short *phase;		//phase vector of each row
	unsigned short *literal;	//pauli literals in stabilizer matrix 
} STABILIZER_MATRIX;

//Row in stabilizer matrix with single phase
typedef struct
{
  	unsigned short phase;		//phase vector of each row
	unsigned short *literal;	//pauli literals in stabilizer matrix 
} STABILIZER_ROW;

//Stabilizer frame - Single phase approach
typedef struct
{
  	unsigned short **phase;		//phase vectors 
	COMPLEX_NUM *amplitude;		//amplitude vectors 
	unsigned short **literal;	//pauli literals in stabilizer matrix 
	unsigned int pair_count;	//counter to keep track of the number of phase and complex vector pairs
} SINGLE_FRAME;

typedef struct
{
	unsigned int size;		//number of gates (allocate max size: n*n)
	unsigned short *type;		//gate type=> 0: Hadamard	1: Phase	2: CNOT		3: CPHASE (Controlled-Z) 
	unsigned short *pos;		//qubit position for gate application (allocate max size: 2)
} BASIS_CIRCUIT;

//Linked list for storing frames for multi-frame approach
//Somehow it doesn't allow typedef
struct FRAME {
	float c;
	STABILIZER_ROW *stab_row;
  	struct FRAME *next;
};

#include "complex.c"
#include "matrix.c"
#include "gate.c"

#endif
